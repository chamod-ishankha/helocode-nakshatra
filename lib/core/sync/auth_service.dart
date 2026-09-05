import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/result.dart';
import '../logging/app_logger.dart';
import 'firebase_service.dart';

/// What kind of account the user currently has.
enum AccountKind {
  /// No Firebase user at all — Firebase is unconfigured, or the device has
  /// never been online.
  none,

  /// The automatic account from first launch. Backed up, but the backup dies
  /// with the install.
  anonymous,

  /// Carries a real credential, so the backup survives a new phone.
  permanent,
}

/// A snapshot of the signed-in account, for display.
class AccountStatus {
  const AccountStatus({required this.kind, this.email});

  final AccountKind kind;
  final String? email;

  /// Whether the backup can outlive this installation.
  bool get isRecoverable => kind == AccountKind.permanent;

  static AccountStatus of(User? user) {
    if (user == null) return const AccountStatus(kind: AccountKind.none);
    return AccountStatus(
      kind: user.isAnonymous ? AccountKind.anonymous : AccountKind.permanent,
      email: user.email,
    );
  }
}

/// Attaching a real identity to the anonymous account from KAN-47.
///
/// ## Linking, not replacing
///
/// [linkEmail] uses `linkWithCredential`, which keeps the same uid. The
/// Firestore document is filed under that uid, so linking moves nothing and
/// can lose nothing — the account simply gains a way to sign back in.
///
/// [signInEmail] is the other case. Signing in to an account that already
/// exists swaps the uid, so whatever this device had backed up under the old
/// one becomes unreachable. That is a real fork in the data, which is why it
/// is the caller's decision and not a silent overwrite.
///
/// ## No email verification
///
/// Deliberate, per the product decision on KAN-48. A real address can recover
/// the account; a made-up one cannot, and that account is simply gone. The
/// sign-up screen has to say so, because a user cannot discover it until the
/// day they need it.
class AuthService {
  const AuthService();

  FirebaseAuth? get _auth =>
      FirebaseService.isAvailable ? FirebaseAuth.instance : null;

  AccountStatus get status => AccountStatus.of(_auth?.currentUser);

  /// Emits on every sign-in, sign-out and link.
  Stream<AccountStatus> get changes =>
      _auth?.userChanges().map(AccountStatus.of) ??
      Stream.value(const AccountStatus(kind: AccountKind.none));

  /// Attaches an email and password to the current anonymous account.
  ///
  /// The uid is unchanged on success, so the existing backup carries over
  /// untouched and nothing has to be migrated.
  Future<Result<AccountStatus>> linkEmail(String email, String password) async {
    final user = _auth?.currentUser;
    if (user == null) {
      return const Result.failure(
        AuthFailure('Not signed in yet.', code: 'no-current-user'),
      );
    }

    try {
      final result = await user.linkWithCredential(
        EmailAuthProvider.credential(email: email.trim(), password: password),
      );
      AppLogger.info('Anonymous account linked to email');
      return Result.success(AccountStatus.of(result.user));
    } on FirebaseAuthException catch (e) {
      return Result.failure(describe(e));
    } on Object catch (e, s) {
      AppLogger.warn('Link failed', e, s);
      return Result.failure(
        AuthFailure('Could not create the account.', cause: e, code: 'unknown'),
      );
    }
  }

  /// Signs in to an account that already exists.
  ///
  /// This abandons the current anonymous account. Its backup would otherwise
  /// sit in Firestore forever with no way to reach it — an anonymous account
  /// cannot be signed back in to — so [onAbandon] runs first and is where that
  /// copy gets deleted. Local storage is the source of truth and is untouched
  /// either way.
  Future<Result<AccountStatus>> signInEmail(
    String email,
    String password, {
    Future<void> Function()? onAbandon,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return const Result.failure(
        AuthFailure('Sync is unavailable.', code: 'no-firebase'),
      );
    }

    try {
      final leaving = auth.currentUser;
      if (leaving != null && leaving.isAnonymous && onAbandon != null) {
        await onAbandon();
      }

      final result = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.info('Signed in to an existing account');
      return Result.success(AccountStatus.of(result.user));
    } on FirebaseAuthException catch (e) {
      return Result.failure(describe(e));
    } on Object catch (e, s) {
      AppLogger.warn('Sign-in failed', e, s);
      return Result.failure(
        AuthFailure('Could not sign in.', cause: e, code: 'unknown'),
      );
    }
  }

  /// Returns to a fresh anonymous account.
  ///
  /// Signing out does not stop the backup: an anonymous account is this app's
  /// normal state, and dropping to no account at all would silently disable
  /// something the user never asked to turn off. The profile on this phone is
  /// untouched and is backed up again under the new uid.
  Future<Result<AccountStatus>> signOut() async {
    final auth = _auth;
    if (auth == null) {
      return const Result.failure(
        AuthFailure('Sync is unavailable.', code: 'no-firebase'),
      );
    }

    try {
      await auth.signOut();
      await auth.signInAnonymously();
      AppLogger.info('Signed out, back to an anonymous account');
      return Result.success(AccountStatus.of(auth.currentUser));
    } on FirebaseAuthException catch (e) {
      return Result.failure(describe(e));
    } on Object catch (e, s) {
      AppLogger.warn('Sign-out failed', e, s);
      return Result.failure(
        AuthFailure('Could not sign out.', cause: e, code: 'unknown'),
      );
    }
  }

  /// Maps a Firebase error code to something a user can act on.
  ///
  /// The raw messages name credentials and providers, which reads as nonsense
  /// to someone who only wanted to keep their chart.
  static AuthFailure describe(FirebaseAuthException e) {
    final message = switch (e.code) {
      'email-already-in-use' ||
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        'That email already has an account. Sign in to it instead.',
      'invalid-email' => 'That does not look like an email address.',
      'weak-password' => 'Use at least 6 characters.',
      'wrong-password' || 'invalid-credential' => 'Wrong email or password.',
      'user-not-found' => 'No account for that email.',
      'user-disabled' => 'That account has been disabled.',
      'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
      'network-request-failed' =>
        'No connection. Your chart still works offline.',
      'operation-not-allowed' =>
        'Email sign-in is not enabled for this app yet.',
      _ => 'Could not complete that. Please try again.',
    };
    AppLogger.warn('Auth error ${e.code}');
    return AuthFailure(message, cause: e, code: e.code);
  }

  /// Whether [code] means the address is already taken, which is an offer to
  /// sign in rather than an error to apologise for.
  static bool isEmailTaken(String code) =>
      code == 'email-already-in-use' ||
      code == 'credential-already-in-use' ||
      code == 'account-exists-with-different-credential';
}

final authServiceProvider = Provider<AuthService>((ref) => const AuthService());

/// The live account state, so the UI updates the moment a link succeeds.
final accountStatusProvider = StreamProvider<AccountStatus>(
  (ref) => ref.watch(authServiceProvider).changes,
);
