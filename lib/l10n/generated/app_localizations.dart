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

  /// No description provided for @onboardingTimeUnknownLabel.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know my birth time'**
  String get onboardingTimeUnknownLabel;

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

  /// No description provided for @homeWindowRunningNow.
  ///
  /// In en, this message translates to:
  /// **'{window} is running now, until {time}.'**
  String homeWindowRunningNow(String window, String time);

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

  /// No description provided for @chartNakshatraPada.
  ///
  /// In en, this message translates to:
  /// **'{nakshatra} — pada {pada}'**
  String chartNakshatraPada(String nakshatra, int pada);

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

  /// No description provided for @chartStyleSouthIndian.
  ///
  /// In en, this message translates to:
  /// **'South Indian'**
  String get chartStyleSouthIndian;

  /// No description provided for @chartStyleNorthIndian.
  ///
  /// In en, this message translates to:
  /// **'North Indian'**
  String get chartStyleNorthIndian;

  /// No description provided for @chartCentreCaption.
  ///
  /// In en, this message translates to:
  /// **'Rāśi chart'**
  String get chartCentreCaption;

  /// No description provided for @chartLagnaMark.
  ///
  /// In en, this message translates to:
  /// **'La'**
  String get chartLagnaMark;

  /// No description provided for @chartRetrogradeMark.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get chartRetrogradeMark;

  /// No description provided for @chartLagnaOf.
  ///
  /// In en, this message translates to:
  /// **'{rasi} lagna'**
  String chartLagnaOf(String rasi);

  /// No description provided for @chartApproximateShort.
  ///
  /// In en, this message translates to:
  /// **'approximate'**
  String get chartApproximateShort;

  /// No description provided for @dashaTitle.
  ///
  /// In en, this message translates to:
  /// **'Daśā periods'**
  String get dashaTitle;

  /// No description provided for @dashaRunningNow.
  ///
  /// In en, this message translates to:
  /// **'Running now'**
  String get dashaRunningNow;

  /// No description provided for @dashaSubPeriods.
  ///
  /// In en, this message translates to:
  /// **'Sub-periods'**
  String get dashaSubPeriods;

  /// No description provided for @dashaEnds.
  ///
  /// In en, this message translates to:
  /// **'ends {date}'**
  String dashaEnds(String date);

  /// No description provided for @dashaBalanceNote.
  ///
  /// In en, this message translates to:
  /// **'Your first period had already begun when you were born, so it is shown shorter than its full length.'**
  String get dashaBalanceNote;

  /// No description provided for @dashaUnreliableTime.
  ///
  /// In en, this message translates to:
  /// **'Your birth time is unknown, so sunrise was assumed. The Moon moves about half a degree an hour, which can shift these dates by years — and can even change which planet rules the first period. Treat this as a rough guide until you know your time of birth.'**
  String get dashaUnreliableTime;

  /// No description provided for @detailHouse.
  ///
  /// In en, this message translates to:
  /// **'House {n}'**
  String detailHouse(int n);

  /// No description provided for @detailRetrograde.
  ///
  /// In en, this message translates to:
  /// **'Retrograde'**
  String get detailRetrograde;

  /// No description provided for @detailNoGraha.
  ///
  /// In en, this message translates to:
  /// **'No graha sits in this house.'**
  String get detailNoGraha;

  /// No description provided for @detailExaltedIn.
  ///
  /// In en, this message translates to:
  /// **'Exalted in {rasi} at {degree}°'**
  String detailExaltedIn(String rasi, int degree);

  /// No description provided for @dignityOwn.
  ///
  /// In en, this message translates to:
  /// **'Own sign'**
  String get dignityOwn;

  /// No description provided for @dignityExalted.
  ///
  /// In en, this message translates to:
  /// **'Exalted'**
  String get dignityExalted;

  /// No description provided for @dignityDebilitated.
  ///
  /// In en, this message translates to:
  /// **'Debilitated'**
  String get dignityDebilitated;

  /// No description provided for @dignityNodeNote.
  ///
  /// In en, this message translates to:
  /// **'Rāhu and Ketu rule no sign, and traditions disagree on where they are exalted — so no dignity is claimed here.'**
  String get dignityNodeNote;

  /// No description provided for @chartShare.
  ///
  /// In en, this message translates to:
  /// **'Share chart'**
  String get chartShare;

  /// No description provided for @chartShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the image.'**
  String get chartShareFailed;

  /// No description provided for @chartShareCaption.
  ///
  /// In en, this message translates to:
  /// **'{name} · {date} · {place}'**
  String chartShareCaption(String name, String date, String place);

  /// No description provided for @compatTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get compatTitle;

  /// No description provided for @compatIntro.
  ///
  /// In en, this message translates to:
  /// **'Marriage matching is read from the Moon at birth, so both sets of birth details are needed.'**
  String get compatIntro;

  /// No description provided for @compatYourDetails.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get compatYourDetails;

  /// No description provided for @compatPartnerDetails.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get compatPartnerDetails;

  /// No description provided for @compatPartnerName.
  ///
  /// In en, this message translates to:
  /// **'Partner\'s name'**
  String get compatPartnerName;

  /// No description provided for @compatRoleQuestion.
  ///
  /// In en, this message translates to:
  /// **'Who is the bride?'**
  String get compatRoleQuestion;

  /// No description provided for @compatRoleYou.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get compatRoleYou;

  /// No description provided for @compatRolePartner.
  ///
  /// In en, this message translates to:
  /// **'My partner'**
  String get compatRolePartner;

  /// No description provided for @compatRoleHelp.
  ///
  /// In en, this message translates to:
  /// **'Several factors are counted from the bride to the groom and give a different answer if swapped. This is how the tradition states them.'**
  String get compatRoleHelp;

  /// No description provided for @compatSystemPorondam.
  ///
  /// In en, this message translates to:
  /// **'Porondam'**
  String get compatSystemPorondam;

  /// No description provided for @compatSystemAshtakoota.
  ///
  /// In en, this message translates to:
  /// **'Ashtakoota'**
  String get compatSystemAshtakoota;

  /// No description provided for @compatCalculate.
  ///
  /// In en, this message translates to:
  /// **'Check compatibility'**
  String get compatCalculate;

  /// No description provided for @compatChangePartner.
  ///
  /// In en, this message translates to:
  /// **'Change partner'**
  String get compatChangePartner;

  /// No description provided for @compatNeedPartner.
  ///
  /// In en, this message translates to:
  /// **'Enter your partner\'s birth details to see a match.'**
  String get compatNeedPartner;

  /// No description provided for @compatScoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'{score} of {max}'**
  String compatScoreOutOf(String score, int max);

  /// No description provided for @compatMatchedOutOf.
  ///
  /// In en, this message translates to:
  /// **'{matched} of {judged} matched'**
  String compatMatchedOutOf(int matched, int judged);

  /// No description provided for @compatPorondamIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Twelve porondam are judged here. Sri Lankan almanacs count twenty, but the remaining eight are stated differently from one almanac to the next, so they are left out rather than guessed at.'**
  String get compatPorondamIncomplete;

  /// No description provided for @compatCaveat.
  ///
  /// In en, this message translates to:
  /// **'This is guidance, not a ruling. A chart has never decided whether two people are good to each other - talk to a trusted astrologer, and to each other, before it decides anything for you.'**
  String get compatCaveat;

  /// No description provided for @compatTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'A birth time is missing, so sunrise was assumed. The Moon crosses about one star a day, which can put it in the neighbouring one and change several factors at once. Treat this as indicative until both times are known.'**
  String get compatTimeUnknown;

  /// No description provided for @compatKujaTitle.
  ///
  /// In en, this message translates to:
  /// **'Kuja dosha'**
  String get compatKujaTitle;

  /// No description provided for @compatKujaNeither.
  ///
  /// In en, this message translates to:
  /// **'Neither chart carries it.'**
  String get compatKujaNeither;

  /// No description provided for @compatKujaBoth.
  ///
  /// In en, this message translates to:
  /// **'Both charts carry it, which is held to cancel.'**
  String get compatKujaBoth;

  /// No description provided for @compatKujaUnmatched.
  ///
  /// In en, this message translates to:
  /// **'One chart carries it and the other does not. This is the case the tradition warns about.'**
  String get compatKujaUnmatched;

  /// No description provided for @compatKujaSevere.
  ///
  /// In en, this message translates to:
  /// **'Repeated from more than one reference point.'**
  String get compatKujaSevere;

  /// No description provided for @compatNadiDosha.
  ///
  /// In en, this message translates to:
  /// **'Nadi dosha - the heaviest single objection in this system.'**
  String get compatNadiDosha;

  /// No description provided for @compatBhakootDosha.
  ///
  /// In en, this message translates to:
  /// **'Bhakoot dosha - the Moon signs fall at an afflicted distance.'**
  String get compatBhakootDosha;

  /// No description provided for @verdictGood.
  ///
  /// In en, this message translates to:
  /// **'Met'**
  String get verdictGood;

  /// No description provided for @verdictPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly met'**
  String get verdictPartial;

  /// No description provided for @verdictPoor.
  ///
  /// In en, this message translates to:
  /// **'Not met'**
  String get verdictPoor;

  /// No description provided for @factorVarna.
  ///
  /// In en, this message translates to:
  /// **'Varna'**
  String get factorVarna;

  /// No description provided for @factorVarnaAbout.
  ///
  /// In en, this message translates to:
  /// **'Compares the elements of the two Moon signs.'**
  String get factorVarnaAbout;

  /// No description provided for @factorVashya.
  ///
  /// In en, this message translates to:
  /// **'Vashya'**
  String get factorVashya;

  /// No description provided for @factorVashyaAbout.
  ///
  /// In en, this message translates to:
  /// **'Whether the two signs are held to sit easily together.'**
  String get factorVashyaAbout;

  /// No description provided for @factorTara.
  ///
  /// In en, this message translates to:
  /// **'Tara'**
  String get factorTara;

  /// No description provided for @factorTaraAbout.
  ///
  /// In en, this message translates to:
  /// **'Counts between the two birth stars, each way round.'**
  String get factorTaraAbout;

  /// No description provided for @factorYoni.
  ///
  /// In en, this message translates to:
  /// **'Yoni'**
  String get factorYoni;

  /// No description provided for @factorYoniAbout.
  ///
  /// In en, this message translates to:
  /// **'Physical and temperamental fit, read through paired animals.'**
  String get factorYoniAbout;

  /// No description provided for @factorGrahaMaitri.
  ///
  /// In en, this message translates to:
  /// **'Graha maitri'**
  String get factorGrahaMaitri;

  /// No description provided for @factorGrahaMaitriAbout.
  ///
  /// In en, this message translates to:
  /// **'Friendship between the planets ruling the two Moon signs.'**
  String get factorGrahaMaitriAbout;

  /// No description provided for @factorGana.
  ///
  /// In en, this message translates to:
  /// **'Gana'**
  String get factorGana;

  /// No description provided for @factorGanaAbout.
  ///
  /// In en, this message translates to:
  /// **'Temperament - deva, manushya or rakshasa.'**
  String get factorGanaAbout;

  /// No description provided for @factorBhakoot.
  ///
  /// In en, this message translates to:
  /// **'Bhakoot'**
  String get factorBhakoot;

  /// No description provided for @factorBhakootAbout.
  ///
  /// In en, this message translates to:
  /// **'The distance between the two Moon signs. All or nothing.'**
  String get factorBhakootAbout;

  /// No description provided for @factorNadi.
  ///
  /// In en, this message translates to:
  /// **'Nadi'**
  String get factorNadi;

  /// No description provided for @factorNadiAbout.
  ///
  /// In en, this message translates to:
  /// **'Constitution. Sharing one is the strongest objection.'**
  String get factorNadiAbout;

  /// No description provided for @factorDina.
  ///
  /// In en, this message translates to:
  /// **'Dina'**
  String get factorDina;

  /// No description provided for @factorDinaAbout.
  ///
  /// In en, this message translates to:
  /// **'Counted from the bride\'s star to the groom\'s.'**
  String get factorDinaAbout;

  /// No description provided for @factorMahendra.
  ///
  /// In en, this message translates to:
  /// **'Mahendra'**
  String get factorMahendra;

  /// No description provided for @factorMahendraAbout.
  ///
  /// In en, this message translates to:
  /// **'Held to bear on children and the couple\'s welfare.'**
  String get factorMahendraAbout;

  /// No description provided for @factorStreeDeergha.
  ///
  /// In en, this message translates to:
  /// **'Stree deergha'**
  String get factorStreeDeergha;

  /// No description provided for @factorStreeDeerghaAbout.
  ///
  /// In en, this message translates to:
  /// **'Asks that the groom\'s star lie well ahead of the bride\'s.'**
  String get factorStreeDeerghaAbout;

  /// No description provided for @factorRasi.
  ///
  /// In en, this message translates to:
  /// **'Rasi'**
  String get factorRasi;

  /// No description provided for @factorRasiAbout.
  ///
  /// In en, this message translates to:
  /// **'Asks that the groom\'s Moon sign be seventh or beyond.'**
  String get factorRasiAbout;

  /// No description provided for @factorRasiadhipathi.
  ///
  /// In en, this message translates to:
  /// **'Rasiadhipathi'**
  String get factorRasiadhipathi;

  /// No description provided for @factorRasiadhipathiAbout.
  ///
  /// In en, this message translates to:
  /// **'The lords of the two Moon signs.'**
  String get factorRasiadhipathiAbout;

  /// No description provided for @factorRajju.
  ///
  /// In en, this message translates to:
  /// **'Rajju'**
  String get factorRajju;

  /// No description provided for @factorRajjuAbout.
  ///
  /// In en, this message translates to:
  /// **'Falling in the same limb is the objection here, not differing.'**
  String get factorRajjuAbout;

  /// No description provided for @factorVedha.
  ///
  /// In en, this message translates to:
  /// **'Vedha'**
  String get factorVedha;

  /// No description provided for @factorVedhaAbout.
  ///
  /// In en, this message translates to:
  /// **'Certain star pairs are held to pierce one another.'**
  String get factorVedhaAbout;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get settingsSectionProfile;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit birth details'**
  String get settingsEditProfile;

  /// No description provided for @settingsEditProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Changing these recalculates every chart and reading.'**
  String get settingsEditProfileHint;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow the phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsThemeHint.
  ///
  /// In en, this message translates to:
  /// **'Light is easier to read outdoors, whatever the phone is set to.'**
  String get settingsThemeHint;

  /// No description provided for @settingsChartStyle.
  ///
  /// In en, this message translates to:
  /// **'Chart style'**
  String get settingsChartStyle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsSectionData;

  /// No description provided for @settingsDeleteData.
  ///
  /// In en, this message translates to:
  /// **'Delete my details'**
  String get settingsDeleteData;

  /// No description provided for @settingsDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Removes your birth details from this phone and from our backup.'**
  String get settingsDeleteHint;

  /// No description provided for @settingsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your details?'**
  String get settingsDeleteTitle;

  /// No description provided for @settingsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your birth details will be removed from this phone and from our backup, and your account will be deleted. Your charts and readings go with them, and this cannot be undone.'**
  String get settingsDeleteBody;

  /// No description provided for @settingsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @settingsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your details have been deleted.'**
  String get settingsDeleted;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get settingsTerms;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open that link.'**
  String get settingsLinkFailed;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Nekath calendar'**
  String get calendarTitle;

  /// No description provided for @calendarPoya.
  ///
  /// In en, this message translates to:
  /// **'Poya'**
  String get calendarPoya;

  /// No description provided for @calendarFestival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get calendarFestival;

  /// No description provided for @calendarBestDays.
  ///
  /// In en, this message translates to:
  /// **'Best days this month'**
  String get calendarBestDays;

  /// No description provided for @calendarPickActivity.
  ///
  /// In en, this message translates to:
  /// **'What are you planning?'**
  String get calendarPickActivity;

  /// No description provided for @calendarScan.
  ///
  /// In en, this message translates to:
  /// **'Find good days'**
  String get calendarScan;

  /// No description provided for @calendarScanning.
  ///
  /// In en, this message translates to:
  /// **'Checking every day this month...'**
  String get calendarScanning;

  /// No description provided for @calendarNoGoodDays.
  ///
  /// In en, this message translates to:
  /// **'Nothing this month scores well for that. Try the next month, or a different activity.'**
  String get calendarNoGoodDays;

  /// No description provided for @calendarDayDetail.
  ///
  /// In en, this message translates to:
  /// **'Panchanga'**
  String get calendarDayDetail;

  /// No description provided for @calendarClearWindows.
  ///
  /// In en, this message translates to:
  /// **'Clear windows'**
  String get calendarClearWindows;

  /// No description provided for @calendarScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String calendarScoreLabel(int score);

  /// No description provided for @activityTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get activityTravel;

  /// No description provided for @activityWorkOrStudy.
  ///
  /// In en, this message translates to:
  /// **'Starting work or study'**
  String get activityWorkOrStudy;

  /// No description provided for @activityBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business or signing'**
  String get activityBusiness;

  /// No description provided for @activityMarriage.
  ///
  /// In en, this message translates to:
  /// **'Marriage'**
  String get activityMarriage;

  /// No description provided for @activityHouseEntry.
  ///
  /// In en, this message translates to:
  /// **'Moving into a house'**
  String get activityHouseEntry;

  /// No description provided for @activityVehicle.
  ///
  /// In en, this message translates to:
  /// **'Buying a vehicle'**
  String get activityVehicle;

  /// No description provided for @reasonNakshatraFavours.
  ///
  /// In en, this message translates to:
  /// **'The star of the day suits this'**
  String get reasonNakshatraFavours;

  /// No description provided for @reasonNakshatraNeutral.
  ///
  /// In en, this message translates to:
  /// **'The star of the day is neutral for this'**
  String get reasonNakshatraNeutral;

  /// No description provided for @reasonNakshatraWarnsAgainst.
  ///
  /// In en, this message translates to:
  /// **'The star of the day is warned against for this'**
  String get reasonNakshatraWarnsAgainst;

  /// No description provided for @reasonTithiRikta.
  ///
  /// In en, this message translates to:
  /// **'A rikta tithi — traditionally avoided for beginnings'**
  String get reasonTithiRikta;

  /// No description provided for @reasonTithiFavourable.
  ///
  /// In en, this message translates to:
  /// **'A favourable tithi'**
  String get reasonTithiFavourable;

  /// No description provided for @reasonYogaInauspicious.
  ///
  /// In en, this message translates to:
  /// **'An inauspicious yoga'**
  String get reasonYogaInauspicious;

  /// No description provided for @reasonKaranaVishti.
  ///
  /// In en, this message translates to:
  /// **'Vishti karana, which is avoided'**
  String get reasonKaranaVishti;

  /// No description provided for @reasonVaraUnfavourable.
  ///
  /// In en, this message translates to:
  /// **'The weekday is not the best for this'**
  String get reasonVaraUnfavourable;

  /// No description provided for @reasonVaraFavourable.
  ///
  /// In en, this message translates to:
  /// **'A suitable weekday'**
  String get reasonVaraFavourable;

  /// No description provided for @reasonShortenedByChange.
  ///
  /// In en, this message translates to:
  /// **'Shortened because the almanac changes during the day'**
  String get reasonShortenedByChange;

  /// No description provided for @authErrorRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'For your security, please sign in again before deleting your account.'**
  String get authErrorRequiresRecentLogin;

  /// No description provided for @settingsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Your details were removed from this phone, but the backup could not be reached. Try again once you are online.'**
  String get settingsDeleteFailed;

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

  /// Tooltip and menu label for the language switcher.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

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

  /// No description provided for @unlockWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video'**
  String get unlockWatch;

  /// No description provided for @unlockLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the video…'**
  String get unlockLoading;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'No video was available. Please try again in a moment.'**
  String get unlockFailed;

  /// No description provided for @unlockLastsToday.
  ///
  /// In en, this message translates to:
  /// **'Stays unlocked for the rest of today.'**
  String get unlockLastsToday;

  /// No description provided for @unlockCompatTitle.
  ///
  /// In en, this message translates to:
  /// **'Full compatibility breakdown'**
  String get unlockCompatTitle;

  /// No description provided for @unlockCompatBody.
  ///
  /// In en, this message translates to:
  /// **'See every factor scored one by one, and what each one judges.'**
  String get unlockCompatBody;

  /// No description provided for @unlockFutureTitle.
  ///
  /// In en, this message translates to:
  /// **'Nekath for other days'**
  String get unlockFutureTitle;

  /// No description provided for @unlockFutureBody.
  ///
  /// In en, this message translates to:
  /// **'Open any day ahead — auspicious times, rahu kalaya and the full panchanga.'**
  String get unlockFutureBody;

  /// No description provided for @authErrorGoogleRepeated.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in did not complete. If this keeps happening, it may not be set up for this version of the app.'**
  String get authErrorGoogleRepeated;

  /// No description provided for @horoscopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily horoscope'**
  String get horoscopeTitle;

  /// No description provided for @horoscopeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your horoscope needs your birth details. Finish setting up your chart to see it.'**
  String get horoscopeUnavailable;

  /// No description provided for @horoscopeGeneral.
  ///
  /// In en, this message translates to:
  /// **'The day'**
  String get horoscopeGeneral;

  /// No description provided for @horoscopeCareer.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get horoscopeCareer;

  /// No description provided for @horoscopeMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get horoscopeMoney;

  /// No description provided for @horoscopeLove.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get horoscopeLove;

  /// No description provided for @horoscopeHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get horoscopeHealth;

  /// No description provided for @horoscopeAdvice.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get horoscopeAdvice;

  /// No description provided for @horoscopeLuckyNumber.
  ///
  /// In en, this message translates to:
  /// **'Lucky number'**
  String get horoscopeLuckyNumber;

  /// No description provided for @horoscopeLuckyColour.
  ///
  /// In en, this message translates to:
  /// **'Lucky colour'**
  String get horoscopeLuckyColour;

  /// No description provided for @homeHoroscopeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read from today\'s transits against your chart.'**
  String get homeHoroscopeSubtitle;

  /// No description provided for @colourWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colourWhite;

  /// No description provided for @colourRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colourRed;

  /// No description provided for @colourYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colourYellow;

  /// No description provided for @colourGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colourGreen;

  /// No description provided for @colourBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colourBlue;

  /// No description provided for @colourOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colourOrange;

  /// No description provided for @colourBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colourBrown;

  /// No description provided for @colourGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get colourGold;

  /// No description provided for @colourSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get colourSilver;

  /// No description provided for @colourPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colourPurple;

  /// No description provided for @horoscopeByLagna.
  ///
  /// In en, this message translates to:
  /// **'Lagna'**
  String get horoscopeByLagna;

  /// No description provided for @horoscopeByRasi.
  ///
  /// In en, this message translates to:
  /// **'Moon sign'**
  String get horoscopeByRasi;

  /// No description provided for @horoscopeSameSign.
  ///
  /// In en, this message translates to:
  /// **'Your lagna and moon sign are the same.'**
  String get horoscopeSameSign;

  /// No description provided for @horoscopeLagnaApproximate.
  ///
  /// In en, this message translates to:
  /// **'Your birth time is unknown, so this lagna is approximate.'**
  String get horoscopeLagnaApproximate;

  /// How long an inauspicious window lasts.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String durationMinutes(int minutes);
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
