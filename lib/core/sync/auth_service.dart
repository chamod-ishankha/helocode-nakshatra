import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  static bool _googleSupported = false;
  static bool _googleRuledOut = false;
  static String? _googleError;

  /// Whether to offer the Google button.
  ///
  /// This cannot be known for certain before the first attempt. The SDK's own
  /// `supportsAuthenticate` answers "can this platform do Google sign-in",
  /// which on Android is always yes — it says nothing about whether *this app*
  /// has an OAuth client. The client id lives in the `default_web_client_id`
  /// resource that the Google Services Gradle plugin generates only once the
  /// provider is enabled in the Firebase console and a SHA-1 is registered,
  /// and nothing exposes its absence to Dart.
  ///
  /// So this is optimistic until proven otherwise: the button shows, and the
  /// first configuration error rules it out for the rest of the session. That
  /// costs one failed tap on an unconfigured build, and none on a configured
  /// one — the alternative, a flag someone has to remember to flip, costs the
  /// feature silently going missing on a build that could have run it.
  static bool get googleAvailable => _googleSupported && !_googleRuledOut;

  /// Why Google sign-in is unavailable, for diagnostics.
  static String? get googleError => _googleError;

  /// Prepares the Google SDK. Called once at startup and never throws.
  static Future<void> initializeGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      _googleSupported = GoogleSignIn.instance.supportsAuthenticate();
      if (!_googleSupported) _googleError = 'platform cannot authenticate';
    } on Object catch (e) {
      _googleError = '$e';
      _googleSupported = false;
      AppLogger.info('Google sign-in unavailable: $e');
    }
  }

  /// Test seam — resets the memoised Google state.
  static void resetGoogleForTesting() {
    _googleSupported = false;
    _googleRuledOut = false;
    _googleError = null;
  }

  FirebaseAuth? get _auth =>
      FirebaseService.isAvailable ? FirebaseAuth.instance : null;

  AccountStatus get status => AccountStatus.of(_auth?.currentUser);

  /// Emits on every sign-in, sign-out and link.
  ///
  /// With no Firebase this emits nothing rather than a single "none". A
  /// `Stream.value` delivers on a microtask that can land in the middle of a
  /// build, which marks the provider scope dirty while it is building and
  /// throws — it took down the home screen on a build with sync unavailable.
  /// Emitting nothing leaves the provider without a value, and both readers
  /// already fall back to [AccountKind.none], so the displayed state is the
  /// same without the reentrant notification.
  Stream<AccountStatus> get changes =>
      _auth?.userChanges().map(AccountStatus.of) ??
      const Stream<AccountStatus>.empty();

  /// Attaches an email and password to the current anonymous account.
  ///
  /// The uid is unchanged on success, so the existing backup carries over
  /// untouched and nothing has to be migrated.
  Future<Result<AccountStatus>> linkEmail(String email, String password) async {
    final user = _auth?.currentUser;
    if (user == null) {
      return const Result.failure(
        AuthFailure('no current user', code: 'no-current-user'),
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
        AuthFailure('link failed', cause: e, code: 'unknown'),
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
        AuthFailure('firebase unavailable', code: 'no-firebase'),
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
        AuthFailure('sign-in failed', cause: e, code: 'unknown'),
      );
    }
  }

  /// Attaches a Google account to the current anonymous one.
  ///
  /// Same uid, same guarantees as [linkEmail]. `credential-already-in-use`
  /// means that Google account is already an account here, which the caller
  /// turns into [signInGoogle] rather than an error.
  Future<Result<AccountStatus>> linkGoogle() async {
    final user = _auth?.currentUser;
    if (user == null) {
      return const Result.failure(
        AuthFailure('no current user', code: 'no-current-user'),
      );
    }

    final credential = await _googleCredential();
    return switch (credential) {
      FailureResult(:final failure) => Result.failure(failure),
      Success(value: final c) => await _run(
        () async => AccountStatus.of((await user.linkWithCredential(c)).user),
        'Anonymous account linked to Google',
      ),
    };
  }

  /// Signs in with Google to an account that already exists.
  ///
  /// Carries the same uid-swap consequence as [signInEmail], so [onAbandon]
  /// has the same job: delete the anonymous backup before it becomes
  /// unreachable.
  Future<Result<AccountStatus>> signInGoogle({
    Future<void> Function()? onAbandon,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return const Result.failure(
        AuthFailure('firebase unavailable', code: 'no-firebase'),
      );
    }

    final credential = await _googleCredential();
    if (credential case FailureResult(:final failure)) {
      return Result.failure(failure);
    }

    final leaving = auth.currentUser;
    if (leaving != null && leaving.isAnonymous && onAbandon != null) {
      await onAbandon();
    }

    return _run(
      () async => AccountStatus.of(
        (await auth.signInWithCredential(
          (credential as Success<AuthCredential>).value,
        )).user,
      ),
      'Signed in with Google',
    );
  }

  /// Runs the Google chooser and converts the result into a Firebase
  /// credential.
  ///
  /// Cancelling is not a failure worth a message — the user closed a sheet
  /// they opened — so it comes back with its own code for the caller to
  /// swallow silently.
  Future<Result<AuthCredential>> _googleCredential() async {
    if (!googleAvailable) {
      return const Result.failure(
        AuthFailure('google not configured', code: 'google-unavailable'),
      );
    }

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        return const Result.failure(
          AuthFailure('no id token', code: 'google-no-id-token'),
        );
      }

      return Result.success(GoogleAuthProvider.credential(idToken: idToken));
    } on GoogleSignInException catch (e) {
      return Result.failure(_describeGoogle(e));
    } on Object catch (e, s) {
      AppLogger.warn('Google sign-in failed', e, s);
      return Result.failure(
        AuthFailure('google sign-in failed', cause: e, code: 'google-unknown'),
      );
    }
  }

  static AuthFailure _describeGoogle(GoogleSignInException e) {
    AppLogger.warn('Google sign-in error ${e.code}: ${e.description}');

    final code = switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'google-canceled',
      // The only definitive answer available: this build has no OAuth client.
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'google-unavailable',
      GoogleSignInExceptionCode.interrupted ||
      GoogleSignInExceptionCode.uiUnavailable => 'google-interrupted',
      _ => 'google-unknown',
    };

    // Remember an unconfigured build, so the button goes away rather than
    // failing a second time.
    if (code == 'google-unavailable') {
      _googleRuledOut = true;
      _googleError = e.description;
    }

    return AuthFailure(e.description ?? code, cause: e, code: code);
  }

  /// Shared tail for the Firebase half of both Google paths.
  Future<Result<AccountStatus>> _run(
    Future<AccountStatus> Function() action,
    String log,
  ) async {
    try {
      final status = await action();
      AppLogger.info(log);
      return Result.success(status);
    } on FirebaseAuthException catch (e) {
      return Result.failure(describe(e));
    } on Object catch (e, s) {
      AppLogger.warn('Google auth failed', e, s);
      return Result.failure(
        AuthFailure('google auth failed', cause: e, code: 'unknown'),
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
        AuthFailure('firebase unavailable', code: 'no-firebase'),
      );
    }

    try {
      // Without this the Google chooser silently reuses the last account, so
      // "sign out" would appear not to have worked.
      if (googleAvailable) {
        try {
          await GoogleSignIn.instance.signOut();
        } on Object catch (e) {
          AppLogger.warn('Google sign-out failed, continuing: $e');
        }
      }

      await auth.signOut();
      await auth.signInAnonymously();
      AppLogger.info('Signed out, back to an anonymous account');
      return Result.success(AccountStatus.of(auth.currentUser));
    } on FirebaseAuthException catch (e) {
      return Result.failure(describe(e));
    } on Object catch (e, s) {
      AppLogger.warn('Sign-out failed', e, s);
      return Result.failure(
        AuthFailure('sign-out failed', cause: e, code: 'unknown'),
      );
    }
  }

  /// Wraps a Firebase error, preserving its code.
  ///
  /// Deliberately does not produce a sentence for the user. The code is the
  /// contract; features/account/presentation/auth_messages.dart turns it into
  /// words, because only a widget knows what language to use. The message kept
  /// here is Firebase's own and exists for logs.
  static AuthFailure describe(FirebaseAuthException e) {
    AppLogger.warn('Auth error ${e.code}');
    return AuthFailure(e.message ?? e.code, cause: e, code: e.code);
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
