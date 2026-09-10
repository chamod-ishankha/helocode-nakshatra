// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class L10nTa extends L10n {
  L10nTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'நட்சத்திரா';

  @override
  String get continueLabel => 'தொடரவும்';

  @override
  String get today => 'இன்று';

  @override
  String get todayLower => 'இன்று';

  @override
  String get tomorrowLower => 'நாளை';

  @override
  String inDays(int days) {
    return '$days நாட்களில்';
  }

  @override
  String get entertainmentOnly => 'பொழுதுபோக்கிற்காக மட்டுமே.';

  @override
  String get onboardingChooseLanguage => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get onboardingNameQuestion => 'உங்கள் பெயர் என்ன?';

  @override
  String get onboardingNameLabel => 'பெயர்';

  @override
  String get onboardingNameHelp =>
      'உங்கள் ஜாதகத்திற்குப் பெயரிட மட்டுமே பயன்படுகிறது. இது இந்த சாதனத்திலேயே இருக்கும்.';

  @override
  String get onboardingDateQuestion => 'நீங்கள் எப்போது பிறந்தீர்கள்?';

  @override
  String get onboardingDateLabel => 'பிறந்த தேதி';

  @override
  String get onboardingDateHelp =>
      'தேதி உங்கள் ராசியையும் ஒவ்வொரு கிரக நிலையையும் தீர்மானிக்கிறது.';

  @override
  String get onboardingDatePickerTitle => 'பிறந்த தேதியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get onboardingTimeQuestion => 'நீங்கள் எத்தனை மணிக்குப் பிறந்தீர்கள்?';

  @override
  String get onboardingTimeLabel => 'பிறந்த நேரம்';

  @override
  String get onboardingTimeHelp =>
      'லக்னம் ஏறக்குறைய ஒவ்வொரு இரண்டு மணி நேரத்திற்கும் மாறுகிறது, எனவே பாவ நிலைகளுக்கு இது தேதியை விட முக்கியமானது.';

  @override
  String get onboardingTimePickerTitle => 'பிறந்த நேரத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get onboardingTimeUnknownLabel =>
      'எனது பிறந்த நேரம் எனக்குத் தெரியாது';

  @override
  String get onboardingTimeUnknown =>
      'நாங்கள் சூரிய உதயத்தை (காலை 6:00) பயன்படுத்துவோம்';

  @override
  String get onboardingTimeUnknownHelp =>
      'உங்கள் ராசி, நட்சத்திரம் மற்றும் கிரக நிலைகள் இன்னும் சரியாகவே இருக்கும். லக்னமும் பாவ நிலைகளும் தோராயமானவை, செயலி அதைக் குறித்துக் காட்டும்.';

  @override
  String get onboardingPlaceQuestion => 'நீங்கள் எங்கு பிறந்தீர்கள்?';

  @override
  String get onboardingPlaceSearch => 'ஊர் அல்லது மாவட்டத்தைத் தேடுங்கள்';

  @override
  String get onboardingPlaceHelp =>
      'ஆள்கூறுகள் லக்னத்தை நிர்ணயிக்கின்றன. சிங்களம், தமிழ் அல்லது ஆங்கிலத்தில் தேடலாம்.';

  @override
  String get onboardingPlaceNoMatch => 'பொருந்தும் இடம் இல்லை';

  @override
  String onboardingPlaceLoadFailed(String error) {
    return 'இடங்களை ஏற்ற முடியவில்லை: $error';
  }

  @override
  String get onboardingSeeChart => 'எனது ஜாதகத்தைப் பார்க்க';

  @override
  String get homeRahuKalaya => 'ராகு காலம்';

  @override
  String get homeRahuShort => 'ராகு';

  @override
  String get homeAvoidImportant =>
      'முக்கியமான எதையும் தொடங்குவதைத் தவிர்க்கவும்';

  @override
  String homeRunningUntil(String time) {
    return '$time வரை';
  }

  @override
  String homeWindowRunningNow(String window, String time) {
    return '$window இப்போது நடப்பில், $time வரை.';
  }

  @override
  String get homeOtherInauspicious => 'பிற அசுப நேரங்கள்';

  @override
  String get homeClearTimes => 'இன்றைய நல்ல நேரங்கள்';

  @override
  String get homeClearTimesHelp =>
      'எந்த அசுப நேரத்திற்கும் உட்படாத பகல் நேரம்.';

  @override
  String get homeStillToCome => 'இன்னும் வரவிருப்பவை';

  @override
  String get homeComingUp => 'வரவிருப்பவை';

  @override
  String get homeSunrise => 'சூரிய உதயம்';

  @override
  String get homeSunset => 'சூரிய அஸ்தமனம்';

  @override
  String get homeMoonrise => 'சந்திர உதயம்';

  @override
  String homeFullMoonAt(String time) {
    return '$time மணிக்கு பௌர்ணமி';
  }

  @override
  String get homeBirthChart => 'ஜாதகம்';

  @override
  String get homeAccount => 'கணக்கு';

  @override
  String get homeFestivalsExcluded =>
      'தீபாவளி, ஈத் மற்றும் மிலாது உன்-நபி இங்கு பட்டியலிடப்படவில்லை: அவற்றின் தேதிகள் கணக்கீட்டை விட வட்டார மரபு மற்றும் பிறை பார்த்தலைப் பொறுத்தே அமைகின்றன. தவறான ஒரு மத நாளை உறுதியாகக் காட்டுவதை விடக் காட்டாமல் இருப்பது நல்லது.';

  @override
  String get panchangaTithi => 'திதி';

  @override
  String get panchangaVara => 'வாரம்';

  @override
  String get panchangaNakshatra => 'நட்சத்திரம்';

  @override
  String get panchangaYoga => 'யோகம்';

  @override
  String get panchangaKarana => 'கரணம்';

  @override
  String get chartTitle => 'ஜாதகம்';

  @override
  String get chartStartOver => 'மீண்டும் தொடங்கு';

  @override
  String get chartCalculationFailed => 'ஜாதகத்தைக் கணக்கிட முடியவில்லை';

  @override
  String get chartLagna => 'லக்னம்';

  @override
  String get chartMoonSign => 'சந்திர ராசி';

  @override
  String get chartBirthNakshatra => 'ஜென்ம நட்சத்திரம்';

  @override
  String chartNakshatraPada(String nakshatra, int pada) {
    return '$nakshatra — $pada பாதம்';
  }

  @override
  String chartAyanamsa(String degrees) {
    return 'அயனாம்சம் (லாஹிரி): $degrees°';
  }

  @override
  String get chartPositions => 'கிரக நிலைகள்';

  @override
  String get chartVargaRasi => 'ராசி (D1)';

  @override
  String get chartVargaNavamsa => 'நவாம்சம் (D9)';

  @override
  String get chartNavamsaApproximate =>
      'பிறந்த நேரத்தில் ஒவ்வொரு 13 நிமிடத்திற்கும் நவாம்சம் மாறும். சரியான நேரம் தெரியாவிட்டால் இந்தக் கட்டத்தை ஒரு தோராயமாகக் கருதுங்கள்.';

  @override
  String get chartColumnGraha => 'கிரகம்';

  @override
  String get chartColumnRasi => 'ராசி';

  @override
  String get chartColumnDegree => 'பாகை';

  @override
  String get chartColumnNakshatra => 'நட்சத்திரம்';

  @override
  String get chartColumnPada => 'பாதம்';

  @override
  String get chartColumnHouse => 'பாவம்';

  @override
  String get chartApproximate =>
      'பிறந்த நேரம் தெரியவில்லை — சூரிய உதயம் கருதப்பட்டது. கிரக நிலைகள் சரியானவை; லக்னமும் பாவங்களும் தோராயமானவை.';

  @override
  String get chartStyleSouthIndian => 'தென் இந்திய';

  @override
  String get chartStyleNorthIndian => 'வட இந்திய';

  @override
  String get chartCentreCaption => 'ராசி சக்கரம்';

  @override
  String get chartLagnaMark => 'லக்';

  @override
  String get chartRetrogradeMark => 'வ';

  @override
  String chartLagnaOf(String rasi) {
    return '$rasi லக்னம்';
  }

  @override
  String get chartApproximateShort => 'தோராயம்';

  @override
  String get dashaTitle => 'தசா காலங்கள்';

  @override
  String get dashaRunningNow => 'இப்போது நடப்பில்';

  @override
  String get dashaSubPeriods => 'அந்தர் தசை';

  @override
  String dashaEnds(String date) {
    return '$date இல் முடிகிறது';
  }

  @override
  String get dashaBalanceNote =>
      'நீங்கள் பிறக்கும்போதே உங்கள் முதல் தசை தொடங்கிவிட்டிருந்தது, எனவே அது அதன் முழு நீளத்தை விடக் குறைவாகக் காட்டப்படுகிறது.';

  @override
  String get dashaUnreliableTime =>
      'உங்கள் பிறந்த நேரம் தெரியாததால் சூரிய உதயம் கருதப்பட்டது. சந்திரன் மணிக்கு அரை பாகை அளவு நகர்கிறது, இது இந்தத் தேதிகளை பல ஆண்டுகள் மாற்றக்கூடும், முதல் தசையின் அதிபதி கிரகத்தையே கூட மாற்றக்கூடும். உங்கள் பிறந்த நேரம் தெரியும் வரை இதை ஒரு தோராயமான வழிகாட்டியாகக் கருதுங்கள்.';

  @override
  String detailHouse(int n) {
    return '$n ஆம் பாவம்';
  }

  @override
  String get detailRetrograde => 'வக்ரம்';

  @override
  String get detailNoGraha => 'இந்தப் பாவத்தில் கிரகம் எதுவும் இல்லை.';

  @override
  String detailExaltedIn(String rasi, int degree) {
    return '$rasi ராசியில் $degree° இல் உச்சம்';
  }

  @override
  String get dignityOwn => 'சொந்த வீடு';

  @override
  String get dignityExalted => 'உச்சம்';

  @override
  String get dignityDebilitated => 'நீசம்';

  @override
  String get dignityNodeNote =>
      'ராகுவும் கேதுவும் எந்த ராசிக்கும் அதிபதி அல்ல, அவை உச்சம் பெறும் ராசி குறித்து மரபுகள் ஒத்துப்போவதில்லை — எனவே இங்கு எந்த பலமும் கூறப்படவில்லை.';

  @override
  String get chartShare => 'ஜாதகத்தைப் பகிர்';

  @override
  String get chartShareFailed => 'படத்தை உருவாக்க முடியவில்லை.';

  @override
  String chartShareCaption(String name, String date, String place) {
    return '$name · $date · $place';
  }

  @override
  String get compatTitle => 'பொருத்தம்';

  @override
  String get compatIntro =>
      'திருமணப் பொருத்தம் பிறக்கும்போதைய சந்திரனிலிருந்து படிக்கப்படுகிறது, எனவே இருவரின் பிறப்பு விவரங்களும் தேவை.';

  @override
  String get compatYourDetails => 'நீங்கள்';

  @override
  String get compatPartnerDetails => 'துணைவர்';

  @override
  String get compatPartnerName => 'துணைவரின் பெயர்';

  @override
  String get compatRoleQuestion => 'மணமகள் யார்?';

  @override
  String get compatRoleYou => 'நான்';

  @override
  String get compatRolePartner => 'என் துணைவர்';

  @override
  String get compatRoleHelp =>
      'சில பொருத்தங்கள் மணமகளிலிருந்து மணமகன் வரை எண்ணப்படுகின்றன, இடம் மாறினால் வேறு விடை வரும். மரபு அவற்றை அவ்வாறே கூறுகிறது.';

  @override
  String get compatSystemPorondam => 'பொருத்தம்';

  @override
  String get compatSystemAshtakoota => 'அஷ்டகூடம்';

  @override
  String get compatCalculate => 'பொருத்தம் பார்க்க';

  @override
  String get compatChangePartner => 'துணைவரை மாற்று';

  @override
  String get compatNeedPartner =>
      'பொருத்தம் பார்க்க உங்கள் துணைவரின் பிறப்பு விவரங்களை உள்ளிடவும்.';

  @override
  String compatScoreOutOf(String score, int max) {
    return '$max இல் $score';
  }

  @override
  String compatMatchedOutOf(int matched, int judged) {
    return '$judged இல் $matched பொருந்துகிறது';
  }

  @override
  String get compatPorondamIncomplete =>
      'இங்கு பன்னிரண்டு பொருத்தங்கள் மதிப்பிடப்படுகின்றன. இலங்கை பஞ்சாங்கங்கள் இருபது எண்ணினாலும், மீதமுள்ள எட்டு ஒவ்வொரு பஞ்சாங்கத்திலும் வேறுபடுவதால், ஊகிப்பதை விட அவை விடப்பட்டுள்ளன.';

  @override
  String get compatCaveat =>
      'இது வழிகாட்டுதலே தவிர தீர்ப்பு அல்ல. இருவர் ஒருவருக்கொருவர் நல்லவர்களா என்பதை ஒரு ஜாதகம் ஒருபோதும் தீர்மானித்ததில்லை - நம்பகமான ஜோதிடரிடமும், ஒருவருடன் ஒருவரும் பேசுங்கள்.';

  @override
  String get compatTimeUnknown =>
      'பிறந்த நேரம் ஒன்று இல்லாததால் சூரிய உதயம் கருதப்பட்டது. சந்திரன் ஒரு நாளைக்கு ஏறத்தாழ ஒரு நட்சத்திரம் கடக்கிறது, எனவே அது அடுத்த நட்சத்திரத்தில் விழுந்து பல பொருத்தங்களை ஒரே நேரத்தில் மாற்றக்கூடும். இரு நேரங்களும் தெரியும் வரை இதை தோராயமாகக் கருதுங்கள்.';

  @override
  String get compatKujaTitle => 'செவ்வாய் தோஷம்';

  @override
  String get compatKujaNeither => 'இரு ஜாதகத்திலும் இல்லை.';

  @override
  String get compatKujaBoth =>
      'இரு ஜாதகத்திலும் உள்ளது, இது ரத்தாகும் என்று கருதப்படுகிறது.';

  @override
  String get compatKujaUnmatched =>
      'ஒரு ஜாதகத்தில் உள்ளது, மற்றொன்றில் இல்லை. மரபு எச்சரிப்பது இதைத்தான்.';

  @override
  String get compatKujaSevere =>
      'ஒன்றுக்கு மேற்பட்ட இடங்களிலிருந்து மீண்டும் வருகிறது.';

  @override
  String get compatNadiDosha =>
      'நாடி தோஷம் - இந்த முறையின் மிகக் கடுமையான ஆட்சேபம்.';

  @override
  String get compatBhakootDosha =>
      'பகூட தோஷம் - இரு சந்திர ராசிகளும் தீய தூரத்தில் உள்ளன.';

  @override
  String get verdictGood => 'பொருந்தும்';

  @override
  String get verdictPartial => 'ஓரளவு பொருந்தும்';

  @override
  String get verdictPoor => 'பொருந்தாது';

  @override
  String get factorVarna => 'வர்ணம்';

  @override
  String get factorVarnaAbout => 'இரு சந்திர ராசிகளின் பூதங்களை ஒப்பிடுகிறது.';

  @override
  String get factorVashya => 'வசியம்';

  @override
  String get factorVashyaAbout => 'இரு ராசிகளும் இணக்கமாக இருக்குமா என்பது.';

  @override
  String get factorTara => 'தாரை';

  @override
  String get factorTaraAbout =>
      'இரு ஜென்ம நட்சத்திரங்களுக்கு இடையே இருபுறம் எண்ணுகிறது.';

  @override
  String get factorYoni => 'யோனி';

  @override
  String get factorYoniAbout =>
      'விலங்கு ஜோடிகள் வழியாகப் படிக்கப்படும் உடல் மற்றும் குண இணக்கம்.';

  @override
  String get factorGrahaMaitri => 'கிரக மைத்ரி';

  @override
  String get factorGrahaMaitriAbout =>
      'இரு சந்திர ராசிகளின் அதிபதிகளுக்கிடையிலான நட்பு.';

  @override
  String get factorGana => 'கணம்';

  @override
  String get factorGanaAbout => 'குணம் - தேவ, மனுஷ்ய அல்லது ராட்சஸ.';

  @override
  String get factorBhakoot => 'பகூடம்';

  @override
  String get factorBhakootAbout =>
      'இரு சந்திர ராசிகளுக்கு இடையிலான தூரம். முழுவதும் அல்லது ஒன்றுமில்லை.';

  @override
  String get factorNadi => 'நாடி';

  @override
  String get factorNadiAbout =>
      'உடல் இயல்பு. ஒரே நாடி இருப்பது வலிமையான ஆட்சேபம்.';

  @override
  String get factorDina => 'தினம்';

  @override
  String get factorDinaAbout =>
      'மணமகளின் நட்சத்திரத்திலிருந்து மணமகனுடையது வரை எண்ணப்படுகிறது.';

  @override
  String get factorMahendra => 'மகேந்திரம்';

  @override
  String get factorMahendraAbout =>
      'குழந்தைப்பேறு மற்றும் தம்பதியரின் நலனுடன் தொடர்புடையது.';

  @override
  String get factorStreeDeergha => 'ஸ்திரீ தீர்க்கம்';

  @override
  String get factorStreeDeerghaAbout =>
      'மணமகனின் நட்சத்திரம் மணமகளுடையதை விட நன்கு முன்னால் இருக்க வேண்டும்.';

  @override
  String get factorRasi => 'ராசி';

  @override
  String get factorRasiAbout =>
      'மணமகனின் சந்திர ராசி ஏழாவது அல்லது அதற்கு அப்பால் இருக்க வேண்டும்.';

  @override
  String get factorRasiadhipathi => 'ராசியாதிபதி';

  @override
  String get factorRasiadhipathiAbout => 'இரு சந்திர ராசிகளின் அதிபதிகள்.';

  @override
  String get factorRajju => 'ரஜ்ஜு';

  @override
  String get factorRajjuAbout =>
      'ஒரே அங்கத்தில் விழுவதே ஆட்சேபம், வேறுபடுவது அல்ல.';

  @override
  String get factorVedha => 'வேதை';

  @override
  String get factorVedhaAbout =>
      'சில நட்சத்திர ஜோடிகள் ஒன்றையொன்று துளைப்பதாகக் கருதப்படுகிறது.';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get settingsSectionProfile => 'உங்கள் விவரங்கள்';

  @override
  String get settingsEditProfile => 'பிறப்பு விவரங்களை மாற்று';

  @override
  String get settingsEditProfileHint =>
      'இவற்றை மாற்றினால் ஒவ்வொரு ஜாதகமும் பலனும் மீண்டும் கணக்கிடப்படும்.';

  @override
  String get settingsSectionAppearance => 'தோற்றம்';

  @override
  String get settingsTheme => 'நிறத் தோற்றம்';

  @override
  String get themeSystem => 'தொலைபேசியைப் பின்பற்று';

  @override
  String get themeLight => 'வெளிர்';

  @override
  String get themeDark => 'இருள்';

  @override
  String get settingsThemeHint =>
      'தொலைபேசி அமைப்பு எதுவாக இருந்தாலும், வெளியில் படிக்க வெளிர் நிறம் எளிது.';

  @override
  String get settingsChartStyle => 'ஜாதக பாணி';

  @override
  String get settingsLanguage => 'மொழி';

  @override
  String get settingsSectionReminders => 'நினைவூட்டல்கள்';

  @override
  String get settingsDailyReminder => 'காலை நேரம்';

  @override
  String get settingsDailyReminderHint =>
      'நாளின் ராகு காலம், எதையும் தொடங்கும் முன்.';

  @override
  String get settingsReminderTime => 'நேரம்';

  @override
  String get settingsPoyaReminder => 'பௌர்ணமி நினைவூட்டல்';

  @override
  String get settingsPoyaReminderHint => 'பௌர்ணமி நாளுக்கு முந்தைய மாலை.';

  @override
  String get settingsNotificationsBlocked =>
      'உங்கள் தொலைபேசி அமைப்புகளில் Nakshatra-க்கான அறிவிப்புகள் அணைக்கப்பட்டுள்ளன.';

  @override
  String get notificationDailyTitle => 'இன்றைய நேரம்';

  @override
  String notificationDailyBody(String start, String end) {
    return 'ராகு காலம் $start – $end';
  }

  @override
  String get notificationDailyBodyUnknown =>
      'இன்றைய நேரத்தைப் பார்க்கத் திறக்கவும்.';

  @override
  String get notificationPoyaTitle => 'நாளை பௌர்ணமி';

  @override
  String notificationPoyaBody(String poya) {
    return 'நாளை $poya.';
  }

  @override
  String get settingsSectionData => 'உங்கள் தரவு';

  @override
  String get settingsDeleteData => 'என் விவரங்களை அழி';

  @override
  String get settingsDeleteHint =>
      'உங்கள் பிறப்பு விவரங்களை இந்தத் தொலைபேசியிலிருந்தும் எங்கள் காப்புப் பிரதியிலிருந்தும் நீக்கும்.';

  @override
  String get settingsDeleteTitle => 'உங்கள் விவரங்களை அழிக்கவா?';

  @override
  String get settingsDeleteBody =>
      'உங்கள் பிறப்பு விவரங்கள் இந்தத் தொலைபேசியிலிருந்தும் எங்கள் காப்புப் பிரதியிலிருந்தும் நீக்கப்படும், உங்கள் கணக்கும் அழிக்கப்படும். உங்கள் ஜாதகங்களும் பலன்களும் அவற்றுடன் போகும். இதை மீட்டெடுக்க முடியாது.';

  @override
  String get settingsDeleteConfirm => 'அழி';

  @override
  String get commonCancel => 'ரத்து செய்';

  @override
  String get settingsDeleted => 'உங்கள் விவரங்கள் அழிக்கப்பட்டன.';

  @override
  String get settingsSectionAbout => 'செயலி பற்றி';

  @override
  String get settingsPrivacy => 'தனியுரிமைக் கொள்கை';

  @override
  String get settingsTerms => 'விதிமுறைகள்';

  @override
  String settingsVersion(String version) {
    return 'பதிப்பு $version';
  }

  @override
  String get settingsLinkFailed => 'அந்த இணைப்பைத் திறக்க முடியவில்லை.';

  @override
  String get calendarTitle => 'நேரக் காட்டி';

  @override
  String get calendarPoya => 'பௌர்ணமி';

  @override
  String get calendarFestival => 'பண்டிகை';

  @override
  String get calendarThisMonth => 'இந்த மாதம்';

  @override
  String get calendarNoEvents => 'இந்த மாதம் பௌர்ணமியோ பண்டிகையோ இல்லை.';

  @override
  String get calendarAnnounced => 'ஆண்டுதோறும் அறிவிக்கப்படும்';

  @override
  String get calendarAnnouncedHelp =>
      'இவை பிறை பார்த்தல் அல்லது வழக்கத்தின்படி தீர்மானிக்கப்படுவதால் இங்கு கணக்கிடப்படவில்லை. அந்த ஆண்டின் வர்த்தமானியைப் பாருங்கள்.';

  @override
  String get calendarBestDays => 'இந்த மாதத்தின் சிறந்த நாட்கள்';

  @override
  String get calendarPickActivity => 'நீங்கள் என்ன திட்டமிடுகிறீர்கள்?';

  @override
  String get calendarScan => 'நல்ல நாட்களைத் தேடு';

  @override
  String get calendarScanning =>
      'இந்த மாதத்தின் ஒவ்வொரு நாளையும் பரிசோதிக்கிறது...';

  @override
  String get calendarNoGoodDays =>
      'அதற்கு இந்த மாதத்தில் நல்ல நாள் இல்லை. அடுத்த மாதத்தையோ வேறு செயலையோ முயற்சிக்கவும்.';

  @override
  String get calendarDayDetail => 'பஞ்சாங்கம்';

  @override
  String get calendarClearWindows => 'தெளிவான நேரங்கள்';

  @override
  String calendarScoreLabel(int score) {
    return 'மதிப்பெண் $score';
  }

  @override
  String get activityTravel => 'பயணம்';

  @override
  String get activityWorkOrStudy => 'வேலை அல்லது படிப்பைத் தொடங்குதல்';

  @override
  String get activityBusiness => 'வணிகம் அல்லது ஒப்பந்தம்';

  @override
  String get activityMarriage => 'திருமணம்';

  @override
  String get activityHouseEntry => 'புது வீட்டில் குடியேறுதல்';

  @override
  String get activityVehicle => 'வாகனம் வாங்குதல்';

  @override
  String get reasonNakshatraFavours => 'அன்றைய நட்சத்திரம் இதற்கு உகந்தது';

  @override
  String get reasonNakshatraNeutral => 'அன்றைய நட்சத்திரம் இதற்கு நடுநிலையானது';

  @override
  String get reasonNakshatraWarnsAgainst =>
      'அன்றைய நட்சத்திரம் இதற்கு உகந்ததல்ல';

  @override
  String get reasonTithiRikta =>
      'ரிக்த திதி — தொடக்கங்களுக்கு மரபுப்படி தவிர்க்கப்படுகிறது';

  @override
  String get reasonTithiFavourable => 'சுப திதி';

  @override
  String get reasonYogaInauspicious => 'அசுப யோகம்';

  @override
  String get reasonKaranaVishti => 'விஷ்டி கரணம், தவிர்க்கப்படுகிறது';

  @override
  String get reasonVaraUnfavourable => 'இதற்கு இந்த வாரம் சிறந்ததல்ல';

  @override
  String get reasonVaraFavourable => 'பொருத்தமான வாரம்';

  @override
  String get reasonShortenedByChange =>
      'நாளுக்குள் பஞ்சாங்கம் மாறுவதால் சுருக்கப்பட்டுள்ளது';

  @override
  String get authErrorRequiresRecentLogin =>
      'உங்கள் பாதுகாப்பிற்காக, கணக்கை அழிக்கும் முன் மீண்டும் உள்நுழையவும்.';

  @override
  String get settingsDeleteFailed =>
      'உங்கள் விவரங்கள் இந்தத் தொலைபேசியிலிருந்து நீக்கப்பட்டன, ஆனால் காப்புப் பிரதியை அணுக முடியவில்லை. இணையத்தில் இணைந்ததும் மீண்டும் முயற்சிக்கவும்.';

  @override
  String get accountTitle => 'கணக்கு';

  @override
  String accountSavedToEmail(String email) {
    return '$email இல் சேமிக்கப்பட்டது';
  }

  @override
  String get accountSavedToEmailHelp =>
      'புதிய தொலைபேசியில் இந்த மின்னஞ்சலைக் கொண்டு உள்நுழைந்தால் உங்கள் பிறப்பு விவரங்கள் திரும்பக் கிடைக்கும்.';

  @override
  String get accountPhoneOnly => 'இந்தத் தொலைபேசியில் மட்டும் சேமிக்கப்பட்டது';

  @override
  String get accountPhoneOnlyHelp =>
      'உங்கள் பிறப்பு விவரங்கள் காப்புப் பிரதி எடுக்கப்பட்டுள்ளன, ஆனால் அந்தக் காப்புப் பிரதி இந்த நிறுவலுக்கு மட்டுமே உரியது. செயலியின் தரவை அழித்தாலோ புதிய தொலைபேசிக்கு மாறினாலோ அது நிரந்தரமாக இழக்கப்படும்.';

  @override
  String get accountUnavailable => 'காப்புப் பிரதி கிடைக்கவில்லை';

  @override
  String get accountUnavailableHelp =>
      'காப்புப் பிரதி சேவையுடன் இணைப்பு இல்லை. மற்ற அனைத்தும் இயங்குகின்றன.';

  @override
  String get accountOfflineNotice =>
      'கணக்குகளுக்கு இணைய இணைப்பு தேவை. நீங்கள் இணையத்தில் இணைந்ததும் மீண்டும் முயற்சிக்கவும் — செயலியில் வேறு எதுவும் அதற்காகக் காத்திருக்கவில்லை.';

  @override
  String get accountKeepSafe => 'உங்கள் ஜாதகத்தைப் பாதுகாப்பாக வையுங்கள்';

  @override
  String get accountSignIn => 'உள்நுழை';

  @override
  String get accountSignOut => 'வெளியேறு';

  @override
  String get accountCreate => 'கணக்கை உருவாக்கு';

  @override
  String get accountContinueWithGoogle => 'Google உடன் தொடரவும்';

  @override
  String get accountOr => 'அல்லது';

  @override
  String get accountEmail => 'மின்னஞ்சல்';

  @override
  String get accountPassword => 'கடவுச்சொல்';

  @override
  String get accountEnterEmail => 'உங்கள் மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get accountEnterPassword => 'கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get accountInvalidEmail => 'அது மின்னஞ்சல் முகவரி போல் தெரியவில்லை';

  @override
  String get accountPasswordTooShort =>
      'குறைந்தது 6 எழுத்துகளைப் பயன்படுத்தவும்';

  @override
  String get accountToggleToSignIn => 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழையவும்';

  @override
  String get accountToggleToCreate => 'இன்னும் கணக்கு இல்லையா? உருவாக்கவும்';

  @override
  String get accountNoVerification =>
      'நாங்கள் உறுதிப்படுத்தல் மின்னஞ்சல் அனுப்புவதில்லை, எனவே உடனே தொடங்கலாம். அதாவது தவறாகத் தட்டச்சு செய்யப்பட்ட முகவரியை மீட்டெடுக்க முடியாது — உண்மையில் உங்களுக்குச் சொந்தமான ஒன்றைப் பயன்படுத்தவும்.';

  @override
  String get accountSignedOutHelp =>
      'வெளியேறினாலும் உங்கள் ஜாதகம் இந்தத் தொலைபேசியில் இருக்கும். நீங்கள் மீண்டும் உள்நுழையும் வரை அது அநாமதேயமாகக் காப்புப் பிரதி எடுக்கப்படும்.';

  @override
  String get accountFooter =>
      'உங்கள் ஜாதகம், நேரக் கணிப்புகள் மற்றும் பஞ்சாங்கம் இந்தத் தொலைபேசியிலேயே கணக்கிடப்படுகின்றன, கணக்கோ இணைப்போ இல்லாமல் இயங்கும். ஒரு கணக்கு தீர்மானிப்பது, தொலைபேசியை இழந்தால் உங்கள் பிறப்பு விவரங்கள் தப்பிப் பிழைக்குமா என்பதை மட்டுமே.';

  @override
  String get accountCreatedToast =>
      'கணக்கு உருவாக்கப்பட்டது. உங்கள் ஜாதகம் பாதுகாப்பாக உள்ளது.';

  @override
  String get accountSignedInToast => 'உள்நுழைந்தீர்கள்.';

  @override
  String get accountSignedInGoogleToast => 'Google உடன் உள்நுழைந்தீர்கள்.';

  @override
  String get accountSignedOutToast => 'வெளியேறினீர்கள்.';

  @override
  String get accountConflictTitle => 'இரண்டு ஜாதகங்கள்';

  @override
  String accountConflictBody(String name) {
    return 'இந்தக் கணக்கில் ஏற்கனவே $name உள்ளது, அது இந்தத் தொலைபேசியில் உள்ள ஜாதகத்திலிருந்து வேறுபட்டது. ஒன்றை மட்டுமே வைத்திருக்க முடியும்.';
  }

  @override
  String get accountConflictUnnamed => 'பெயரிடப்படாத ஒரு விவரம்';

  @override
  String get accountConflictKeepPhone => 'தொலைபேசியில் உள்ளதை வை';

  @override
  String get accountConflictKeepAccount => 'கணக்கில் உள்ளதை வை';

  @override
  String get authErrorEmailTaken =>
      'அந்த மின்னஞ்சலுக்கு ஏற்கனவே கணக்கு உள்ளது. அதற்குப் பதிலாக உள்நுழையவும்.';

  @override
  String get authErrorInvalidEmail => 'அது மின்னஞ்சல் முகவரி போல் தெரியவில்லை.';

  @override
  String get authErrorWeakPassword =>
      'குறைந்தது 6 எழுத்துகளைப் பயன்படுத்தவும்.';

  @override
  String get authErrorWrongPassword => 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறு.';

  @override
  String get authErrorUserNotFound => 'அந்த மின்னஞ்சலுக்குக் கணக்கு இல்லை.';

  @override
  String get authErrorUserDisabled => 'அந்தக் கணக்கு முடக்கப்பட்டுள்ளது.';

  @override
  String get authErrorTooManyRequests =>
      'மிக அதிக முயற்சிகள். சில நிமிடங்களில் மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authErrorNoConnection =>
      'இணைப்பு இல்லை. உங்கள் ஜாதகம் இணையம் இல்லாமலும் இயங்கும்.';

  @override
  String get authErrorNotEnabled =>
      'இந்தச் செயலிக்கு மின்னஞ்சல் உள்நுழைவு இன்னும் இயக்கப்படவில்லை.';

  @override
  String get authErrorGoogleUnavailable =>
      'இந்தச் செயலிக்கு Google உள்நுழைவு இன்னும் அமைக்கப்படவில்லை.';

  @override
  String get authErrorGoogleInterrupted =>
      'Google உள்நுழைவு தடைபட்டது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authErrorGeneric =>
      'அதை முடிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authErrorNotSignedIn => 'இன்னும் உள்நுழையவில்லை.';

  @override
  String get authErrorSyncUnavailable => 'ஒத்திசைவு கிடைக்கவில்லை.';

  @override
  String get authErrorCreateFailed => 'கணக்கை உருவாக்க முடியவில்லை.';

  @override
  String get authErrorSignInFailed => 'உள்நுழைய முடியவில்லை.';

  @override
  String get authErrorSignOutFailed => 'வெளியேற முடியவில்லை.';

  @override
  String get authErrorGoogleFailed => 'Google உடன் உள்நுழைய முடியவில்லை.';

  @override
  String get authErrorGoogleNoToken =>
      'Google இடமிருந்து பயன்படுத்தக்கூடிய உள்நுழைவு கிடைக்கவில்லை.';

  @override
  String get language => 'மொழி';

  @override
  String get routeNotFound => 'பக்கம் கிடைக்கவில்லை';

  @override
  String get routeGoHome => 'முகப்புக்குச் செல்';

  @override
  String get unlockWatch => 'குறும் காணொளியைப் பாருங்கள்';

  @override
  String get unlockLoading => 'காணொளி ஏற்றப்படுகிறது…';

  @override
  String get unlockFailed =>
      'காணொளி கிடைக்கவில்லை. சிறிது நேரத்தில் மீண்டும் முயலவும்.';

  @override
  String get unlockLastsToday => 'இன்று முழுவதும் திறந்தே இருக்கும்.';

  @override
  String get unlockCompatTitle => 'முழுமையான பொருத்த விவரம்';

  @override
  String get unlockCompatBody =>
      'ஒவ்வொரு காரணியும் தனித்தனியாக மதிப்பிடப்பட்ட விதத்தைப் பாருங்கள்.';

  @override
  String get unlockNavamsaTitle => 'நவாம்சக் கட்டம்';

  @override
  String get unlockNavamsaBody =>
      'D9 — திருமணத்திற்கும் ஒவ்வொரு கிரகத்தின் உண்மையான பலத்திற்கும் உங்கள் ராசிக் கட்டத்துடன் சேர்த்து படிக்கப்படுகிறது.';

  @override
  String get unlockDashaTitle => 'மூன்றாம் தசை நிலை';

  @override
  String get unlockDashaBody =>
      'ஒவ்வொரு அந்தர்தசையையும் அதன் பிரத்யந்தர்தசைக் காலங்களாகப் பிரித்துப் பார்க்கலாம்.';

  @override
  String get unlockFutureTitle => 'மற்ற நாட்களின் நேரம்';

  @override
  String get unlockFutureBody =>
      'வரும் எந்த நாளையும் திறக்கலாம் — நல்ல நேரங்கள், ராகு காலம் மற்றும் முழு பஞ்சாங்கம்.';

  @override
  String get authErrorGoogleRepeated =>
      'Google உள்நுழைவு நிறைவடையவில்லை. இது தொடர்ந்து நிகழ்ந்தால், இந்தப் பதிப்பிற்கு அது அமைக்கப்படாமல் இருக்கலாம்.';

  @override
  String get horoscopeTitle => 'தினசரி பலன்';

  @override
  String get horoscopeUnavailable =>
      'ராசி பலனுக்கு உங்கள் பிறப்பு விவரங்கள் தேவை. ஜாதகத்தை அமைத்து முடிக்கவும்.';

  @override
  String get horoscopeGeneral => 'இன்றைய நாள்';

  @override
  String get horoscopeCareer => 'வேலை';

  @override
  String get horoscopeMoney => 'பணம்';

  @override
  String get horoscopeLove => 'உறவுகள்';

  @override
  String get horoscopeHealth => 'உடல்நலம்';

  @override
  String get horoscopeAdvice => 'அறிவுரை';

  @override
  String get horoscopeLuckyNumber => 'அதிர்ஷ்ட எண்';

  @override
  String get horoscopeLuckyColour => 'அதிர்ஷ்ட நிறம்';

  @override
  String get homeHoroscopeSubtitle =>
      'இன்றைய கோள் நிலைகள் உங்கள் ஜாதகத்துடன் பார்க்கப்பட்டது.';

  @override
  String get colourWhite => 'வெள்ளை';

  @override
  String get colourRed => 'சிவப்பு';

  @override
  String get colourYellow => 'மஞ்சள்';

  @override
  String get colourGreen => 'பச்சை';

  @override
  String get colourBlue => 'நீலம்';

  @override
  String get colourOrange => 'ஆரஞ்சு';

  @override
  String get colourBrown => 'பழுப்பு';

  @override
  String get colourGold => 'தங்கம்';

  @override
  String get colourSilver => 'வெள்ளி';

  @override
  String get colourPurple => 'ஊதா';

  @override
  String get horoscopeByLagna => 'லக்னம்';

  @override
  String get horoscopeByRasi => 'ராசி';

  @override
  String get horoscopeSameSign => 'உங்கள் லக்னமும் ராசியும் ஒன்றே.';

  @override
  String get horoscopeLagnaApproximate =>
      'பிறந்த நேரம் தெரியாததால் இந்த லக்னம் தோராயமானது.';

  @override
  String durationMinutes(int minutes) {
    return '$minutes நிமிடங்கள்';
  }

  @override
  String get purchaseSectionTitle => 'Nakshatra Pro';

  @override
  String get purchaseStatusFree => 'இலவசம்';

  @override
  String get purchaseStatusAdFree => 'விளம்பரங்கள் நீக்கப்பட்டன';

  @override
  String purchaseStatusProUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString வரை Pro';
  }

  @override
  String get purchaseUpgrade => 'Pro ஆக மாறுங்கள்';

  @override
  String get purchaseUpgradeHint =>
      'விளம்பரங்கள் இல்லை, நவாம்சக் கட்டம், முழு தசை காலவரிசை.';

  @override
  String get purchaseManage => 'சந்தாவை நிர்வகி';

  @override
  String get purchaseRestore => 'கொள்முதல்களை மீட்டெடு';

  @override
  String get purchaseRestoreHint =>
      'ஏற்கனவே பணம் செலுத்திவிட்டீர்களா? உங்கள் கொள்முதல்களை இந்தச் சாதனத்திற்குக் கொண்டு வாருங்கள்.';

  @override
  String get purchaseRestored => 'உங்கள் கொள்முதல்கள் மீட்கப்பட்டன.';

  @override
  String get purchaseRestoreNothing =>
      'இந்தக் கணக்கில் மீட்டெடுக்க எதுவும் இல்லை.';

  @override
  String get purchaseRestoreFailed =>
      'கடையை அடைய முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get purchaseUnavailable =>
      'இந்தப் பதிப்பில் கொள்முதல்கள் கிடைக்கவில்லை.';

  @override
  String get purchaseThanks => 'நன்றி. உங்கள் கொள்முதல் செயலில் உள்ளது.';

  @override
  String get purchasePending =>
      'கட்டணம் இன்னும் செயலாக்கத்தில் உள்ளது. அது முடிந்ததும் தானாகவே திறக்கும்.';

  @override
  String get purchaseAlreadyOwned =>
      'இது ஏற்கனவே உங்களிடம் உள்ளது. “கொள்முதல்களை மீட்டெட” முயலவும்.';

  @override
  String get purchaseNotAllowed =>
      'இந்தச் சாதனத்தில் கொள்முதல்கள் அனுமதிக்கப்படவில்லை.';

  @override
  String get purchaseProductUnavailable =>
      'இது இன்னும் விற்பனைக்கு வரவில்லை. பின்னர் மீண்டும் முயலவும்.';

  @override
  String get purchaseFailed =>
      'ஏதேனும் தவறாகிவிட்டது. உங்களிடமிருந்து பணம் வசூலிக்கப்படவில்லை.';

  @override
  String get paywallHeadlineValue => 'முழு பஞ்சாங்கத்தையும் திறக்கவும்';

  @override
  String get paywallHeadlineSupport => 'Nakshatra தொடர்ந்து இயங்க உதவுங்கள்';

  @override
  String get paywallBodyValue =>
      'நவாம்சக் கட்டம், முழு தசை காலவரிசை, விரிவான பொருத்தக் கணிப்பு — எந்த விளம்பரமும் இல்லாமல்.';

  @override
  String get paywallBodySupport =>
      'Nakshatra இலங்கையில் ஒருவரால் உருவாக்கப்பட்டது. Pro ஆவது அந்த வேலைக்குப் பணம் தருகிறது — அத்துடன் அனைத்து விளம்பரங்களும் நீங்கும்.';

  @override
  String get paywallBestValue => 'சிறந்த மதிப்பு';

  @override
  String paywallSave(int percent) {
    return '$percent% சேமிக்கவும்';
  }

  @override
  String get paywallPerMonth => 'மாதத்திற்கு';

  @override
  String get paywallPerYear => 'வருடத்திற்கு';

  @override
  String get paywallOneTime => 'ஒரு முறை கட்டணம்';

  @override
  String paywallFreeTrial(int days, String price) {
    return '$days நாட்கள் இலவசம், பின்னர் $price';
  }

  @override
  String get paywallRemoveAdsTitle => 'விளம்பரங்களை மட்டும் நீக்கு';

  @override
  String get paywallRemoveAdsBody =>
      'ஒரு முறை கட்டணம். மற்ற அனைத்தும் அப்படியே இருக்கும்.';

  @override
  String get paywallWatchTitle => 'அல்லது ஒரு குறும் காணொளியைப் பாருங்கள்';

  @override
  String get paywallWatchBody =>
      'இலவசம், இன்றைய மீதி நேரத்திற்கு இது திறக்கும்.';

  @override
  String get paywallPricesLoading => 'விலைகள் ஏற்றப்படுகின்றன…';

  @override
  String get paywallPricesUnavailable =>
      'விலைகள் இப்போது கிடைக்கவில்லை. பின்னர் மீண்டும் முயலவும்.';

  @override
  String get paywallLegal =>
      'ரத்து செய்யும் வரை சந்தா தானாகவே புதுப்பிக்கப்படும். Google Play இல் எப்போது வேண்டுமானாலும் ரத்து செய்யலாம்.';

  @override
  String get paywallFeatureNoAds => 'எங்கும் விளம்பரங்கள் இல்லை';

  @override
  String get paywallFeatureCharts => 'நவாம்ச (D9) கட்டம்';

  @override
  String get paywallFeatureDasha => 'முழு தசை காலவரிசை';

  @override
  String get paywallFeatureCompat => 'முழு பொருத்தக் கணிப்பு';

  @override
  String get paywallFeatureProfiles => 'முழு குடும்பத்திற்கும் சாதகங்கள்';

  @override
  String get paywallReasonCompat => 'முழு பொருத்தக் கணிப்பையும் பாருங்கள்';

  @override
  String get paywallReasonFuture => 'மேலும் முன்னோக்கிப் பாருங்கள்';

  @override
  String get reportTitle => 'சாதக அறிக்கை';

  @override
  String reportPreparedOn(String date) {
    return 'தயாரிக்கப்பட்ட நாள் $date';
  }

  @override
  String reportBornOn(String date, String time) {
    return 'பிறந்த நாள் $date, நேரம் $time';
  }

  @override
  String reportBornOnDateOnly(String date) {
    return 'பிறந்த நாள் $date';
  }

  @override
  String reportPageOf(int page, int total) {
    return 'பக்கம் $page / $total';
  }

  @override
  String get reportSectionRasi => 'ராசி சக்கரம் (D1)';

  @override
  String get reportSectionNavamsa => 'நவாம்ச சக்கரம் (D9)';

  @override
  String get reportNavamsaNote =>
      'நவாம்சம் ஒவ்வொரு ராசியையும் ஒன்பது பகுதிகளாகப் பிரிக்கிறது. இது ராசி சக்கரத்திற்குப் பதிலாக அல்ல, அதனுடன் சேர்த்துப் படிக்கப்படுகிறது.';

  @override
  String get reportSectionDasha => 'விம்சோத்தரி மகாதசை';

  @override
  String get reportSectionMethod => 'இது எவ்வாறு கணிக்கப்பட்டது';

  @override
  String get reportMethodBody =>
      'கிரக நிலைகள் நிராயன முறையில், லஹிரி அயனாம்சம் மற்றும் முழு ராசி பாவ முறையைப் பயன்படுத்தி, உங்கள் சாதனத்திலேயே ஸ்விஸ் எபிமெரிஸ் மூலம் கணிக்கப்பட்டுள்ளன.';

  @override
  String get reportGenerate => 'சாதக அறிக்கை (PDF)';

  @override
  String get reportUnlock => 'இந்த அறிக்கையைத் திறக்கவும்';

  @override
  String get reportGenerateHint =>
      'அச்சிடக்கூடிய, உங்கள் மொழியிலான அறிக்கை — வைத்திருக்கவோ பகிரவோ.';

  @override
  String get reportPreparing => 'உங்கள் அறிக்கை தயாராகிறது…';

  @override
  String get reportFailed =>
      'அறிக்கையை உருவாக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get reportShareText => 'எனது சாதகம், Nakshatra வழியாக.';

  @override
  String get reportRegenerateNote =>
      'எப்போது வேண்டுமானாலும் மீண்டும் உருவாக்கலாம் — இது ஒரு முறை மட்டும் செலுத்தும் கொள்முதல்.';

  @override
  String get settingsFestivalReminder => 'பண்டிகை நேரங்கள்';

  @override
  String get settingsFestivalReminderHint =>
      'புத்தாண்டு மற்றும் தைப்பொங்கலுக்கு முந்தைய நாள் மாலை.';

  @override
  String get settingsDashaReminder => 'தசை மாற்றங்கள்';

  @override
  String get settingsDashaReminderHint =>
      'உங்கள் சாதகத்தில் புதிய கிரக தசை தொடங்கும் போது.';

  @override
  String get settingsTransitReminder => 'கிரக மாற்றம்';

  @override
  String get settingsTransitReminderHint =>
      'சனி, குரு, ராகு அல்லது கேது புதிய ராசிக்குள் நுழையும்போது.';

  @override
  String get notificationFestivalTitle => 'நாளை பண்டிகை';

  @override
  String notificationFestivalBody(Object festival) {
    return 'நாளை $festival.';
  }

  @override
  String get notificationDashaTitle => 'புதிய தசை தொடங்குகிறது';

  @override
  String notificationDashaMahaBody(Object lord) {
    return 'இன்று முதல் உங்கள் $lord மகாதசை தொடங்குகிறது.';
  }

  @override
  String notificationDashaAntaraBody(Object lord) {
    return 'இன்று முதல் உங்கள் $lord அந்தர்தசை தொடங்குகிறது.';
  }

  @override
  String notificationTransitTitle(String graha) {
    return '$graha ராசி மாற்றம்';
  }

  @override
  String notificationTransitBody(String graha, String rasi, int house) {
    return '$graha இன்று $rasi ராசிக்குள் நுழைகிறது — உங்கள் சந்திர ராசியிலிருந்து $houseஆம் வீடு.';
  }

  @override
  String notificationTransitSadeSati(String rasi) {
    return 'சனி இன்று $rasi ராசிக்குள் நுழைகிறது. உங்கள் ஏழரை சனி தொடங்குகிறது.';
  }

  @override
  String get profilesTitle => 'சேமித்த சாதகங்கள்';

  @override
  String get profilesSettingsHint =>
      'குடும்பத்தினரின் சாதகங்களுக்கு இடையே மாறவும்.';

  @override
  String get profilesAdd => 'மற்றொரு சாதகத்தைச் சேர்க்கவும்';

  @override
  String get profilesShowing => 'இப்போது காட்டப்படுகிறது';

  @override
  String get profilesRemove => 'நீக்கு';

  @override
  String profilesRemoveConfirm(Object name) {
    return '$name நீக்கவா?';
  }

  @override
  String get profilesRemoveBody =>
      'அவர்களின் பிறப்பு விவரங்கள் இந்தத் தொலைபேசியிலிருந்து நீக்கப்படும்.';

  @override
  String get profilesBackupNote =>
      'நீங்கள் காட்டும் சாதகம் மட்டுமே காப்புப் பிரதி எடுக்கப்படும். மற்றவை இந்தத் தொலைபேசியில் மட்டுமே.';

  @override
  String get profilesUnavailable =>
      'சேமித்த சாதகங்களுக்குத் தேவையான சேமிப்பை இந்தப் பதிப்பால் திறக்க முடியவில்லை.';

  @override
  String profilesBornOn(Object date) {
    return 'பிறந்த நாள் $date';
  }

  @override
  String get purchaseOwnedReport => 'சாதக அறிக்கை — உங்களுடையது';

  @override
  String get paywallNothingLeft =>
      'விற்பனையில் உள்ள அனைத்தும் ஏற்கனவே உங்களிடம் உள்ளன. நன்றி.';
}
