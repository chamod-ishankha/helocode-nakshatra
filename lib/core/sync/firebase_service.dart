import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

/// Firebase initialisation and anonymous sign-in.
///
/// ## Sync is an enhancement, never a dependency
///
/// Every failure here is swallowed and logged. If Firebase is unconfigured, the
/// device is offline, or sign-in fails, the app must still open, compute charts
/// and show the almanac — all of that is on-device and needs no network. A
/// user in a village with no signal gets the same nekath as one in Colombo.
///
/// That is why [isAvailable] exists and why nothing awaits sync before
/// rendering.
///
/// ## Anonymous accounts
///
/// Sign-in happens silently on first launch, with no screen and no prompt.
/// Onboarding is already the highest drop-off surface in the app, so an account
/// wall in front of it would cost installs for a benefit the user has not yet
/// felt.
///
/// The trade-off: an anonymous account belongs to the app install. Clearing app
/// data or moving to a new phone loses it. KAN-48 lets a user attach Google or
/// email credentials so the account survives.
abstract final class FirebaseService {
  static bool _available = false;
  static bool _attempted = false;
  static String? _lastError;

  /// Whether Firebase started and a user is signed in.
  ///
  /// False on a build with no `google-services.json`, which is the normal state
  /// for a fresh clone.
  static bool get isAvailable => _available;

  /// Why the last [initialize] failed, or null if it succeeded.
  ///
  /// Failures are deliberately swallowed so they cannot take the app down,
  /// which also makes them invisible. This keeps the cause reportable — tests
  /// assert against it, and it is the difference between "sync is off" and
  /// knowing the phone had no network.
  static String? get lastError => _lastError;

  static User? get currentUser =>
      _available ? FirebaseAuth.instance.currentUser : null;

  static String? get uid => currentUser?.uid;

  /// Starts Firebase and signs in anonymously.
  ///
  /// Safe to call more than once and never throws.
  static Future<void> initialize() async {
    if (_attempted) return;
    _attempted = true;

    try {
      await Firebase.initializeApp();
      final auth = FirebaseAuth.instance;

      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        AppLogger.info('Signed in anonymously');
      }

      _available = auth.currentUser != null;
      if (!_available) _lastError = 'signed in but currentUser was null';
      AppLogger.info('Firebase ready (uid ${auth.currentUser?.uid})');
    } on FirebaseException catch (e) {
      // The overwhelmingly common cause is a build without Firebase
      // configured, which is expected and not worth alarming about.
      AppLogger.warn('Firebase unavailable, continuing offline: ${e.code}');
      _lastError = '${e.code}: ${e.message}';
      _available = false;
    } on Object catch (e, s) {
      AppLogger.warn('Firebase init failed, continuing offline', e, s);
      _lastError = '${e.runtimeType}: $e';
      _available = false;
    }
  }

  /// Test seam — resets the memoised state.
  static void resetForTesting() {
    _available = false;
    _attempted = false;
    _lastError = null;
  }
}

final firebaseAvailableProvider = Provider<bool>(
  (ref) => FirebaseService.isAvailable,
);
