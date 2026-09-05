// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nakshatra';

  @override
  String get continueLabel => 'Continue';

  @override
  String get today => 'Today';

  @override
  String get todayLower => 'today';

  @override
  String get tomorrowLower => 'tomorrow';

  @override
  String inDays(int days) {
    return 'in $days days';
  }

  @override
  String get entertainmentOnly => 'For entertainment purposes only.';

  @override
  String get onboardingChooseLanguage => 'Choose your language';

  @override
  String get onboardingNameQuestion => 'What is your name?';

  @override
  String get onboardingNameLabel => 'Name';

  @override
  String get onboardingNameHelp =>
      'Used only to label your chart. It stays on this device.';

  @override
  String get onboardingDateQuestion => 'When were you born?';

  @override
  String get onboardingDateLabel => 'Date of birth';

  @override
  String get onboardingDateHelp =>
      'The date decides your rāśi and every planetary position.';

  @override
  String get onboardingDatePickerTitle => 'Select date of birth';

  @override
  String get onboardingTimeQuestion => 'What time were you born?';

  @override
  String get onboardingTimeLabel => 'Time of birth';

  @override
  String get onboardingTimeHelp =>
      'The ascendant changes roughly every two hours, so this matters more than the date for house placements.';

  @override
  String get onboardingTimePickerTitle => 'Select time of birth';

  @override
  String get onboardingTimeUnknown => 'We will use sunrise (6:00 AM)';

  @override
  String get onboardingTimeUnknownHelp =>
      'Your rāśi, nakṣatra and planetary positions will still be accurate. The ascendant and house placements will be approximate, and the app will mark them as such.';

  @override
  String get onboardingPlaceQuestion => 'Where were you born?';

  @override
  String get onboardingPlaceSearch => 'Search town or district';

  @override
  String get onboardingPlaceHelp =>
      'Coordinates set the ascendant. Search in Sinhala, Tamil or English.';

  @override
  String get onboardingPlaceNoMatch => 'No matching place';

  @override
  String onboardingPlaceLoadFailed(String error) {
    return 'Could not load places: $error';
  }

  @override
  String get onboardingSeeChart => 'See my chart';

  @override
  String get homeRahuKalaya => 'Rāhu kālaya';

  @override
  String get homeRahuShort => 'Rāhu';

  @override
  String get homeAvoidImportant => 'avoid starting anything important';

  @override
  String homeRunningUntil(String time) {
    return 'until $time';
  }

  @override
  String get homeOtherInauspicious => 'Other inauspicious periods';

  @override
  String get homeClearTimes => 'Clear times today';

  @override
  String get homeClearTimesHelp =>
      'Daylight not claimed by any inauspicious period.';

  @override
  String get homeStillToCome => 'Still to come';

  @override
  String get homeComingUp => 'Coming up';

  @override
  String get homeSunrise => 'Sunrise';

  @override
  String get homeSunset => 'Sunset';

  @override
  String get homeMoonrise => 'Moonrise';

  @override
  String homeFullMoonAt(String time) {
    return 'Full moon at $time';
  }

  @override
  String get homeBirthChart => 'Birth chart';

  @override
  String get homeAccount => 'Account';

  @override
  String get homeComingSoon => 'Daily horoscope and your current daśā period.';

  @override
  String get homeFestivalsExcluded =>
      'Deepavali and Eid are not listed: their dates follow regional convention and moon sighting rather than calculation, and a confidently wrong religious date would be worse than none.';

  @override
  String get panchangaTithi => 'Tithi';

  @override
  String get panchangaVara => 'Vāra';

  @override
  String get panchangaNakshatra => 'Nakṣatra';

  @override
  String get panchangaYoga => 'Yoga';

  @override
  String get panchangaKarana => 'Karana';

  @override
  String get chartTitle => 'Chart';

  @override
  String get chartStartOver => 'Start over';

  @override
  String get chartCalculationFailed => 'Could not calculate the chart';

  @override
  String get chartLagna => 'Lagna (ascendant)';

  @override
  String get chartMoonSign => 'Moon sign (rāśi)';

  @override
  String get chartBirthNakshatra => 'Birth nakṣatra';

  @override
  String chartAyanamsa(String degrees) {
    return 'Ayanāṃśa (Lahiri): $degrees°';
  }

  @override
  String get chartPositions => 'Planetary positions';

  @override
  String get chartColumnGraha => 'Graha';

  @override
  String get chartColumnRasi => 'Rāśi';

  @override
  String get chartColumnDegree => 'Degree';

  @override
  String get chartColumnNakshatra => 'Nakṣatra';

  @override
  String get chartColumnPada => 'Pada';

  @override
  String get chartColumnHouse => 'House';

  @override
  String get chartApproximate =>
      'Birth time unknown — sunrise was assumed. Planetary positions are accurate; the lagna and houses are approximate.';

  @override
  String get accountTitle => 'Account';

  @override
  String accountSavedToEmail(String email) {
    return 'Saved to $email';
  }

  @override
  String get accountSavedToEmailHelp =>
      'Sign in with this email on a new phone and your birth details come back.';

  @override
  String get accountPhoneOnly => 'Saved to this phone only';

  @override
  String get accountPhoneOnlyHelp =>
      'Your birth details are backed up, but the backup belongs to this installation. Clearing app data or moving to a new phone loses it for good.';

  @override
  String get accountUnavailable => 'Backup unavailable';

  @override
  String get accountUnavailableHelp =>
      'No connection to the backup service. Everything else works.';

  @override
  String get accountOfflineNotice =>
      'Accounts need a connection. Try again once you are online — nothing else in the app is waiting on it.';

  @override
  String get accountKeepSafe => 'Keep your chart safe';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountCreate => 'Create account';

  @override
  String get accountContinueWithGoogle => 'Continue with Google';

  @override
  String get accountOr => 'or';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountEnterEmail => 'Enter your email';

  @override
  String get accountEnterPassword => 'Enter a password';

  @override
  String get accountInvalidEmail => 'That does not look like an email address';

  @override
  String get accountPasswordTooShort => 'Use at least 6 characters';

  @override
  String get accountToggleToSignIn => 'Already have an account? Sign in';

  @override
  String get accountToggleToCreate => 'No account yet? Create one';

  @override
  String get accountNoVerification =>
      'We do not send a confirmation email, so you can start straight away. That also means a mistyped address cannot be recovered — use one you really own.';

  @override
  String get accountSignedOutHelp =>
      'Signing out leaves your chart on this phone. It goes back to being backed up anonymously until you sign in again.';

  @override
  String get accountFooter =>
      'Your chart, nekath and the almanac are worked out on this phone and keep working with no account and no connection. An account only decides whether your birth details survive losing the phone.';

  @override
  String get accountCreatedToast => 'Account created. Your chart is safe.';

  @override
  String get accountSignedInToast => 'Signed in.';

  @override
  String get accountSignedInGoogleToast => 'Signed in with Google.';

  @override
  String get accountSignedOutToast => 'Signed out.';

  @override
  String get accountConflictTitle => 'Two charts';

  @override
  String accountConflictBody(String name) {
    return 'This account already holds $name, which is different from the chart on this phone. Only one can be kept.';
  }

  @override
  String get accountConflictUnnamed => 'an unnamed profile';

  @override
  String get accountConflictKeepPhone => 'Keep this phone’s';

  @override
  String get accountConflictKeepAccount => 'Keep the account’s';

  @override
  String get authErrorEmailTaken =>
      'That email already has an account. Sign in to it instead.';

  @override
  String get authErrorInvalidEmail =>
      'That does not look like an email address.';

  @override
  String get authErrorWeakPassword => 'Use at least 6 characters.';

  @override
  String get authErrorWrongPassword => 'Wrong email or password.';

  @override
  String get authErrorUserNotFound => 'No account for that email.';

  @override
  String get authErrorUserDisabled => 'That account has been disabled.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Try again in a few minutes.';

  @override
  String get authErrorNoConnection =>
      'No connection. Your chart still works offline.';

  @override
  String get authErrorNotEnabled =>
      'Email sign-in is not enabled for this app yet.';

  @override
  String get authErrorGoogleUnavailable =>
      'Google sign-in is not set up for this app yet.';

  @override
  String get authErrorGoogleInterrupted =>
      'Google sign-in was interrupted. Please try again.';

  @override
  String get authErrorGeneric => 'Could not complete that. Please try again.';

  @override
  String get authErrorNotSignedIn => 'Not signed in yet.';

  @override
  String get authErrorSyncUnavailable => 'Sync is unavailable.';

  @override
  String get authErrorCreateFailed => 'Could not create the account.';

  @override
  String get authErrorSignInFailed => 'Could not sign in.';

  @override
  String get authErrorSignOutFailed => 'Could not sign out.';

  @override
  String get authErrorGoogleFailed => 'Could not sign in with Google.';

  @override
  String get authErrorGoogleNoToken =>
      'Google did not return a usable sign-in.';

  @override
  String get routeNotFound => 'Page not found';

  @override
  String get routeGoHome => 'Go home';
}
