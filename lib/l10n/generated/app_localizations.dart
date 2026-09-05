import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// App name. Not translated — it is the brand.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get appTitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @todayLower.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get todayLower;

  /// No description provided for @tomorrowLower.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get tomorrowLower;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String inDays(int days);

  /// Required disclaimer. Must appear on every screen showing astrological output.
  ///
  /// In en, this message translates to:
  /// **'For entertainment purposes only.'**
  String get entertainmentOnly;

  /// No description provided for @onboardingChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingChooseLanguage;

  /// No description provided for @onboardingNameQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is your name?'**
  String get onboardingNameQuestion;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get onboardingNameLabel;

  /// No description provided for @onboardingNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Used only to label your chart. It stays on this device.'**
  String get onboardingNameHelp;

  /// No description provided for @onboardingDateQuestion.
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get onboardingDateQuestion;

  /// No description provided for @onboardingDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get onboardingDateLabel;

  /// No description provided for @onboardingDateHelp.
  ///
  /// In en, this message translates to:
  /// **'The date decides your rāśi and every planetary position.'**
  String get onboardingDateHelp;

  /// No description provided for @onboardingDatePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get onboardingDatePickerTitle;

  /// No description provided for @onboardingTimeQuestion.
  ///
  /// In en, this message translates to:
  /// **'What time were you born?'**
  String get onboardingTimeQuestion;

  /// No description provided for @onboardingTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time of birth'**
  String get onboardingTimeLabel;

  /// No description provided for @onboardingTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'The ascendant changes roughly every two hours, so this matters more than the date for house placements.'**
  String get onboardingTimeHelp;

  /// No description provided for @onboardingTimePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select time of birth'**
  String get onboardingTimePickerTitle;

  /// No description provided for @onboardingTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'We will use sunrise (6:00 AM)'**
  String get onboardingTimeUnknown;

  /// No description provided for @onboardingTimeUnknownHelp.
  ///
  /// In en, this message translates to:
  /// **'Your rāśi, nakṣatra and planetary positions will still be accurate. The ascendant and house placements will be approximate, and the app will mark them as such.'**
  String get onboardingTimeUnknownHelp;

  /// No description provided for @onboardingPlaceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where were you born?'**
  String get onboardingPlaceQuestion;

  /// No description provided for @onboardingPlaceSearch.
  ///
  /// In en, this message translates to:
  /// **'Search town or district'**
  String get onboardingPlaceSearch;

  /// No description provided for @onboardingPlaceHelp.
  ///
  /// In en, this message translates to:
  /// **'Coordinates set the ascendant. Search in Sinhala, Tamil or English.'**
  String get onboardingPlaceHelp;

  /// No description provided for @onboardingPlaceNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching place'**
  String get onboardingPlaceNoMatch;

  /// No description provided for @onboardingPlaceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load places: {error}'**
  String onboardingPlaceLoadFailed(String error);

  /// No description provided for @onboardingSeeChart.
  ///
  /// In en, this message translates to:
  /// **'See my chart'**
  String get onboardingSeeChart;

  /// No description provided for @homeRahuKalaya.
  ///
  /// In en, this message translates to:
  /// **'Rāhu kālaya'**
  String get homeRahuKalaya;

  /// No description provided for @homeRahuShort.
  ///
  /// In en, this message translates to:
  /// **'Rāhu'**
  String get homeRahuShort;

  /// No description provided for @homeAvoidImportant.
  ///
  /// In en, this message translates to:
  /// **'avoid starting anything important'**
  String get homeAvoidImportant;

  /// No description provided for @homeRunningUntil.
  ///
  /// In en, this message translates to:
  /// **'until {time}'**
  String homeRunningUntil(String time);

  /// No description provided for @homeOtherInauspicious.
  ///
  /// In en, this message translates to:
  /// **'Other inauspicious periods'**
  String get homeOtherInauspicious;

  /// No description provided for @homeClearTimes.
  ///
  /// In en, this message translates to:
  /// **'Clear times today'**
  String get homeClearTimes;

  /// No description provided for @homeClearTimesHelp.
  ///
  /// In en, this message translates to:
  /// **'Daylight not claimed by any inauspicious period.'**
  String get homeClearTimesHelp;

  /// No description provided for @homeStillToCome.
  ///
  /// In en, this message translates to:
  /// **'Still to come'**
  String get homeStillToCome;

  /// No description provided for @homeComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get homeComingUp;

  /// No description provided for @homeSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get homeSunrise;

  /// No description provided for @homeSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get homeSunset;

  /// No description provided for @homeMoonrise.
  ///
  /// In en, this message translates to:
  /// **'Moonrise'**
  String get homeMoonrise;

  /// No description provided for @homeFullMoonAt.
  ///
  /// In en, this message translates to:
  /// **'Full moon at {time}'**
  String homeFullMoonAt(String time);

  /// No description provided for @homeBirthChart.
  ///
  /// In en, this message translates to:
  /// **'Birth chart'**
  String get homeBirthChart;

  /// No description provided for @homeAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get homeAccount;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Daily horoscope and your current daśā period.'**
  String get homeComingSoon;

  /// No description provided for @homeFestivalsExcluded.
  ///
  /// In en, this message translates to:
  /// **'Deepavali and Eid are not listed: their dates follow regional convention and moon sighting rather than calculation, and a confidently wrong religious date would be worse than none.'**
  String get homeFestivalsExcluded;

  /// No description provided for @panchangaTithi.
  ///
  /// In en, this message translates to:
  /// **'Tithi'**
  String get panchangaTithi;

  /// No description provided for @panchangaVara.
  ///
  /// In en, this message translates to:
  /// **'Vāra'**
  String get panchangaVara;

  /// No description provided for @panchangaNakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakṣatra'**
  String get panchangaNakshatra;

  /// No description provided for @panchangaYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get panchangaYoga;

  /// No description provided for @panchangaKarana.
  ///
  /// In en, this message translates to:
  /// **'Karana'**
  String get panchangaKarana;

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get chartTitle;

  /// No description provided for @chartStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get chartStartOver;

  /// No description provided for @chartCalculationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate the chart'**
  String get chartCalculationFailed;

  /// No description provided for @chartLagna.
  ///
  /// In en, this message translates to:
  /// **'Lagna (ascendant)'**
  String get chartLagna;

  /// No description provided for @chartMoonSign.
  ///
  /// In en, this message translates to:
  /// **'Moon sign (rāśi)'**
  String get chartMoonSign;

  /// No description provided for @chartBirthNakshatra.
  ///
  /// In en, this message translates to:
  /// **'Birth nakṣatra'**
  String get chartBirthNakshatra;

  /// No description provided for @chartAyanamsa.
  ///
  /// In en, this message translates to:
  /// **'Ayanāṃśa (Lahiri): {degrees}°'**
  String chartAyanamsa(String degrees);

  /// No description provided for @chartPositions.
  ///
  /// In en, this message translates to:
  /// **'Planetary positions'**
  String get chartPositions;

  /// No description provided for @chartColumnGraha.
  ///
  /// In en, this message translates to:
  /// **'Graha'**
  String get chartColumnGraha;

  /// No description provided for @chartColumnRasi.
  ///
  /// In en, this message translates to:
  /// **'Rāśi'**
  String get chartColumnRasi;

  /// No description provided for @chartColumnDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get chartColumnDegree;

  /// No description provided for @chartColumnNakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakṣatra'**
  String get chartColumnNakshatra;

  /// No description provided for @chartColumnPada.
  ///
  /// In en, this message translates to:
  /// **'Pada'**
  String get chartColumnPada;

  /// No description provided for @chartColumnHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get chartColumnHouse;

  /// No description provided for @chartApproximate.
  ///
  /// In en, this message translates to:
  /// **'Birth time unknown — sunrise was assumed. Planetary positions are accurate; the lagna and houses are approximate.'**
  String get chartApproximate;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountSavedToEmail.
  ///
  /// In en, this message translates to:
  /// **'Saved to {email}'**
  String accountSavedToEmail(String email);

  /// No description provided for @accountSavedToEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'Sign in with this email on a new phone and your birth details come back.'**
  String get accountSavedToEmailHelp;

  /// No description provided for @accountPhoneOnly.
  ///
  /// In en, this message translates to:
  /// **'Saved to this phone only'**
  String get accountPhoneOnly;

  /// No description provided for @accountPhoneOnlyHelp.
  ///
  /// In en, this message translates to:
  /// **'Your birth details are backed up, but the backup belongs to this installation. Clearing app data or moving to a new phone loses it for good.'**
  String get accountPhoneOnlyHelp;

  /// No description provided for @accountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Backup unavailable'**
  String get accountUnavailable;

  /// No description provided for @accountUnavailableHelp.
  ///
  /// In en, this message translates to:
  /// **'No connection to the backup service. Everything else works.'**
  String get accountUnavailableHelp;

  /// No description provided for @accountOfflineNotice.
  ///
  /// In en, this message translates to:
  /// **'Accounts need a connection. Try again once you are online — nothing else in the app is waiting on it.'**
  String get accountOfflineNotice;

  /// No description provided for @accountKeepSafe.
  ///
  /// In en, this message translates to:
  /// **'Keep your chart safe'**
  String get accountKeepSafe;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountCreate.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountCreate;

  /// No description provided for @accountContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get accountContinueWithGoogle;

  /// No description provided for @accountOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get accountOr;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// No description provided for @accountEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get accountEnterEmail;

  /// No description provided for @accountEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get accountEnterPassword;

  /// No description provided for @accountInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address'**
  String get accountInvalidEmail;

  /// No description provided for @accountPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get accountPasswordTooShort;

  /// No description provided for @accountToggleToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get accountToggleToSignIn;

  /// No description provided for @accountToggleToCreate.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Create one'**
  String get accountToggleToCreate;

  /// No description provided for @accountNoVerification.
  ///
  /// In en, this message translates to:
  /// **'We do not send a confirmation email, so you can start straight away. That also means a mistyped address cannot be recovered — use one you really own.'**
  String get accountNoVerification;

  /// No description provided for @accountSignedOutHelp.
  ///
  /// In en, this message translates to:
  /// **'Signing out leaves your chart on this phone. It goes back to being backed up anonymously until you sign in again.'**
  String get accountSignedOutHelp;

  /// No description provided for @accountFooter.
  ///
  /// In en, this message translates to:
  /// **'Your chart, nekath and the almanac are worked out on this phone and keep working with no account and no connection. An account only decides whether your birth details survive losing the phone.'**
  String get accountFooter;

  /// No description provided for @accountCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Account created. Your chart is safe.'**
  String get accountCreatedToast;

  /// No description provided for @accountSignedInToast.
  ///
  /// In en, this message translates to:
  /// **'Signed in.'**
  String get accountSignedInToast;

  /// No description provided for @accountSignedInGoogleToast.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google.'**
  String get accountSignedInGoogleToast;

  /// No description provided for @accountSignedOutToast.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get accountSignedOutToast;

  /// No description provided for @accountConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Two charts'**
  String get accountConflictTitle;

  /// No description provided for @accountConflictBody.
  ///
  /// In en, this message translates to:
  /// **'This account already holds {name}, which is different from the chart on this phone. Only one can be kept.'**
  String accountConflictBody(String name);

  /// No description provided for @accountConflictUnnamed.
  ///
  /// In en, this message translates to:
  /// **'an unnamed profile'**
  String get accountConflictUnnamed;

  /// No description provided for @accountConflictKeepPhone.
  ///
  /// In en, this message translates to:
  /// **'Keep this phone’s'**
  String get accountConflictKeepPhone;

  /// No description provided for @accountConflictKeepAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep the account’s'**
  String get accountConflictKeepAccount;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'That email already has an account. Sign in to it instead.'**
  String get authErrorEmailTaken;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account for that email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'That account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a few minutes.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Your chart still works offline.'**
  String get authErrorNoConnection;

  /// No description provided for @authErrorNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in is not enabled for this app yet.'**
  String get authErrorNotEnabled;

  /// No description provided for @authErrorGoogleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not set up for this app yet.'**
  String get authErrorGoogleUnavailable;

  /// No description provided for @authErrorGoogleInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was interrupted. Please try again.'**
  String get authErrorGoogleInterrupted;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not complete that. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in yet.'**
  String get authErrorNotSignedIn;

  /// No description provided for @authErrorSyncUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sync is unavailable.'**
  String get authErrorSyncUnavailable;

  /// No description provided for @authErrorCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the account.'**
  String get authErrorCreateFailed;

  /// No description provided for @authErrorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in.'**
  String get authErrorSignInFailed;

  /// No description provided for @authErrorSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out.'**
  String get authErrorSignOutFailed;

  /// No description provided for @authErrorGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with Google.'**
  String get authErrorGoogleFailed;

  /// No description provided for @authErrorGoogleNoToken.
  ///
  /// In en, this message translates to:
  /// **'Google did not return a usable sign-in.'**
  String get authErrorGoogleNoToken;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routeNotFound;

  /// No description provided for @routeGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get routeGoHome;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'si':
      return L10nSi();
    case 'ta':
      return L10nTa();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
