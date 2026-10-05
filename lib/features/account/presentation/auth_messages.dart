import 'package:flutter/widgets.dart';

import '../../../core/error/result.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Turns an [AuthFailure] into words for the person holding the phone.
///
/// This lives in the presentation layer on purpose. [AuthFailure] carries a
/// code and a developer-facing message; only a widget has a [BuildContext],
/// and therefore a language. Keeping the translation here is what lets
/// AuthService stay free of localisation and stay unit-testable without a
/// widget tree.
/// Whether [failure] was the network rather than the account (KAN-95).
///
/// Asked separately from [authMessage] so the screen can show the offline
/// card — which says the rest of the app still works — instead of a red line
/// that reads as though everything is broken.
bool isNoConnection(Object? failure) =>
    failure is AuthFailure && failure.code == 'network-request-failed';

String authMessage(BuildContext context, AuthFailure failure) {
  final l = L10n.of(context);

  return switch (failure.code) {
    'email-already-in-use' ||
    'credential-already-in-use' ||
    'account-exists-with-different-credential' => l.authErrorEmailTaken,
    'invalid-email' => l.authErrorInvalidEmail,
    'weak-password' => l.authErrorWeakPassword,
    'wrong-password' || 'invalid-credential' => l.authErrorWrongPassword,
    'user-not-found' => l.authErrorUserNotFound,
    'user-disabled' => l.authErrorUserDisabled,
    'requires-recent-login' => l.authErrorRequiresRecentLogin,
    'too-many-requests' => l.authErrorTooManyRequests,
    'network-request-failed' => l.authErrorNoConnection,
    'operation-not-allowed' => l.authErrorNotEnabled,

    'google-canceled-repeated' => l.authErrorGoogleRepeated,
    'google-unavailable' => l.authErrorGoogleUnavailable,
    'google-interrupted' => l.authErrorGoogleInterrupted,
    'google-no-id-token' => l.authErrorGoogleNoToken,
    'google-unknown' => l.authErrorGoogleFailed,

    'no-current-user' => l.authErrorNotSignedIn,
    'no-firebase' => l.authErrorSyncUnavailable,

    // Anything the SDK adds later. A wrong-but-readable sentence beats a raw
    // Firebase code, which means nothing to someone who wanted to save a chart.
    _ => l.authErrorGeneric,
  };
}
