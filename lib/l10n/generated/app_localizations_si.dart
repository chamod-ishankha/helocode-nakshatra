// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class L10nSi extends L10n {
  L10nSi([String locale = 'si']) : super(locale);

  @override
  String get appTitle => 'නක්ෂත්‍ර';

  @override
  String get continueLabel => 'ඉදිරියට';

  @override
  String get today => 'අද';

  @override
  String get todayLower => 'අද';

  @override
  String get tomorrowLower => 'හෙට';

  @override
  String inDays(int days) {
    return 'දින $daysකින්';
  }

  @override
  String get entertainmentOnly => 'විනෝදාස්වාදය සඳහා පමණි.';

  @override
  String get onboardingChooseLanguage => 'ඔබේ භාෂාව තෝරන්න';

  @override
  String get onboardingNameQuestion => 'ඔබේ නම කුමක්ද?';

  @override
  String get onboardingNameLabel => 'නම';

  @override
  String get onboardingNameHelp =>
      'ඔබේ කේන්දරය නම් කිරීමට පමණක් යොදා ගැනේ. එය මෙම දුරකථනයේම රැඳේ.';

  @override
  String get onboardingDateQuestion => 'ඔබ උපන්නේ කවදාද?';

  @override
  String get onboardingDateLabel => 'උපන් දිනය';

  @override
  String get onboardingDateHelp =>
      'දිනය ඔබේ රාශිය සහ සෑම ග්‍රහ පිහිටීමක්ම තීරණය කරයි.';

  @override
  String get onboardingDatePickerTitle => 'උපන් දිනය තෝරන්න';

  @override
  String get onboardingTimeQuestion => 'ඔබ උපන්නේ කීයටද?';

  @override
  String get onboardingTimeLabel => 'උපන් වේලාව';

  @override
  String get onboardingTimeHelp =>
      'ලග්නය දළ වශයෙන් සෑම පැය දෙකකට වරක් වෙනස් වන බැවින්, භාව පිහිටීම සඳහා දිනයට වඩා මෙය වැදගත් වේ.';

  @override
  String get onboardingTimePickerTitle => 'උපන් වේලාව තෝරන්න';

  @override
  String get onboardingTimeUnknown => 'අපි හිරු උදාව (පෙ.ව. 6:00) භාවිත කරමු';

  @override
  String get onboardingTimeUnknownHelp =>
      'ඔබේ රාශිය, නක්ෂත්‍රය සහ ග්‍රහ පිහිටීම් නිවැරදිව පවතී. ලග්නය සහ භාව පිහිටීම් දළ වන අතර, යෙදුම එය එසේ බව සලකුණු කරයි.';

  @override
  String get onboardingPlaceQuestion => 'ඔබ උපන්නේ කොහේද?';

  @override
  String get onboardingPlaceSearch => 'නගරය හෝ දිස්ත්‍රික්කය සොයන්න';

  @override
  String get onboardingPlaceHelp =>
      'ඛණ්ඩාංක ලග්නය තීරණය කරයි. සිංහල, දෙමළ හෝ ඉංග්‍රීසි බසින් සොයන්න.';

  @override
  String get onboardingPlaceNoMatch => 'ගැළපෙන ස්ථානයක් නැත';

  @override
  String onboardingPlaceLoadFailed(String error) {
    return 'ස්ථාන පූරණය කළ නොහැකි විය: $error';
  }

  @override
  String get onboardingSeeChart => 'මගේ කේන්දරය බලන්න';

  @override
  String get homeRahuKalaya => 'රාහු කාලය';

  @override
  String get homeRahuShort => 'රාහු';

  @override
  String get homeAvoidImportant => 'වැදගත් කිසිවක් ආරම්භ කිරීමෙන් වළකින්න';

  @override
  String homeRunningUntil(String time) {
    return '$time දක්වා';
  }

  @override
  String get homeOtherInauspicious => 'අනෙකුත් අසුබ කාල';

  @override
  String get homeClearTimes => 'අද සුබ වේලාවන්';

  @override
  String get homeClearTimesHelp => 'කිසිදු අසුබ කාලයකට අයත් නොවන දහවල් වේලාව.';

  @override
  String get homeStillToCome => 'තව එළඹෙන්නට ඇත';

  @override
  String get homeComingUp => 'ඉදිරියේදී';

  @override
  String get homeSunrise => 'හිරු උදාව';

  @override
  String get homeSunset => 'හිරු බැසීම';

  @override
  String get homeMoonrise => 'සඳු උදාව';

  @override
  String homeFullMoonAt(String time) {
    return 'පුර පසළොස්වක $time ට';
  }

  @override
  String get homeBirthChart => 'කේන්දර සටහන';

  @override
  String get homeAccount => 'ගිණුම';

  @override
  String get homeFestivalsExcluded =>
      'දීපාවලි සහ ඊද් මෙහි ලැයිස්තුගත කර නැත: ඒවායේ දිනයන් ගණනය කිරීමට වඩා කලාපීය සම්ප්‍රදාය සහ සඳ දැකීම අනුව තීරණය වන අතර, විශ්වාසයෙන් වැරදි ආගමික දිනයක් දැක්වීමට වඩා නොදැක්වීම හොඳය.';

  @override
  String get panchangaTithi => 'තිථිය';

  @override
  String get panchangaVara => 'වාරය';

  @override
  String get panchangaNakshatra => 'නක්ෂත්‍රය';

  @override
  String get panchangaYoga => 'යෝගය';

  @override
  String get panchangaKarana => 'කරණය';

  @override
  String get chartTitle => 'කේන්දරය';

  @override
  String get chartStartOver => 'නැවත ආරම්භ කරන්න';

  @override
  String get chartCalculationFailed => 'කේන්දරය ගණනය කළ නොහැකි විය';

  @override
  String get chartLagna => 'ලග්නය';

  @override
  String get chartMoonSign => 'චන්ද්‍ර රාශිය';

  @override
  String get chartBirthNakshatra => 'උපන් නක්ෂත්‍රය';

  @override
  String chartAyanamsa(String degrees) {
    return 'අයනාංශය (ලාහිරි): $degrees°';
  }

  @override
  String get chartPositions => 'ග්‍රහ පිහිටීම්';

  @override
  String get chartColumnGraha => 'ග්‍රහයා';

  @override
  String get chartColumnRasi => 'රාශිය';

  @override
  String get chartColumnDegree => 'අංශකය';

  @override
  String get chartColumnNakshatra => 'නක්ෂත්‍රය';

  @override
  String get chartColumnPada => 'පාදය';

  @override
  String get chartColumnHouse => 'භාවය';

  @override
  String get chartApproximate =>
      'උපන් වේලාව නොදනී — හිරු උදාව උපකල්පනය කරන ලදී. ග්‍රහ පිහිටීම් නිවැරදිය; ලග්නය සහ භාව දළ වේ.';

  @override
  String get dashaTitle => 'දශා කාල';

  @override
  String get dashaRunningNow => 'දැන් ක්‍රියාත්මකයි';

  @override
  String get dashaSubPeriods => 'අන්තර් දශා';

  @override
  String dashaEnds(String date) {
    return '$date දින අවසන් වේ';
  }

  @override
  String get dashaBalanceNote =>
      'ඔබ උපදින විට ඔබේ පළමු දශාව දැනටමත් ආරම්භ වී තිබූ බැවින්, එය එහි සම්පූර්ණ දිගට වඩා කෙටියෙන් දැක්වේ.';

  @override
  String get dashaUnreliableTime =>
      'ඔබේ උපන් වේලාව නොදන්නා බැවින් හිරු උදාව උපකල්පනය කරන ලදී. චන්ද්‍රයා පැයකට අංශක භාගයක් පමණ ගමන් කරන අතර, එය මෙම දිනයන් වසර ගණනකින් වෙනස් කළ හැකි අතර පළමු දශාවේ අධිපති ග්‍රහයා පවා වෙනස් විය හැක. ඔබේ උපන් වේලාව දැනගන්නා තෙක් මෙය දළ මාර්ගෝපදේශයක් ලෙස සලකන්න.';

  @override
  String detailHouse(int n) {
    return '$n වන භාවය';
  }

  @override
  String get detailRetrograde => 'වක්‍ර';

  @override
  String get detailNoGraha => 'මෙම භාවයේ ග්‍රහයෙක් නැත.';

  @override
  String detailExaltedIn(String rasi, int degree) {
    return '$rasi රාශියේ අංශක $degree දී උච්ච';
  }

  @override
  String get dignityOwn => 'ස්වක්ෂේත්‍ර';

  @override
  String get dignityExalted => 'උච්ච';

  @override
  String get dignityDebilitated => 'නීච';

  @override
  String get dignityNodeNote =>
      'රාහු සහ කේතු කිසිදු රාශියක් අධිපති නොවන අතර ඔවුන් උච්ච වන්නේ කොහිද යන්න පිළිබඳ සම්ප්‍රදායන් අතර එකඟතාවක් නැත — එබැවින් මෙහි කිසිදු බලයක් දක්වා නැත.';

  @override
  String get chartShare => 'කේන්දරය බෙදාගන්න';

  @override
  String get chartShareFailed => 'රූපය සෑදිය නොහැකි විය.';

  @override
  String chartShareCaption(String name, String date, String place) {
    return '$name · $date · $place';
  }

  @override
  String get compatTitle => 'ගැළපීම';

  @override
  String get compatIntro =>
      'විවාහ ගැළපීම උපතේදී චන්ද්‍රයාගේ පිහිටීම අනුව කියවේ, එබැවින් දෙදෙනාගේම උපන් තොරතුරු අවශ්‍යයි.';

  @override
  String get compatYourDetails => 'ඔබ';

  @override
  String get compatPartnerDetails => 'සහකරු';

  @override
  String get compatPartnerName => 'සහකරුගේ නම';

  @override
  String get compatRoleQuestion => 'මනාලිය කවුද?';

  @override
  String get compatRoleYou => 'මම';

  @override
  String get compatRolePartner => 'මගේ සහකරු';

  @override
  String get compatRoleHelp =>
      'සමහර පොරොන්දම් මනාලියගෙන් මනාලයා දක්වා ගණන් කරන අතර, මාරු කළ විට වෙනස් පිළිතුරක් ලැබේ.';

  @override
  String get compatSystemPorondam => 'පොරොන්දම්';

  @override
  String get compatSystemAshtakoota => 'අෂ්ටකූට';

  @override
  String get compatCalculate => 'ගැළපීම බලන්න';

  @override
  String get compatChangePartner => 'සහකරු වෙනස් කරන්න';

  @override
  String get compatNeedPartner =>
      'ගැළපීම බැලීමට ඔබේ සහකරුගේ උපන් තොරතුරු ඇතුළත් කරන්න.';

  @override
  String compatScoreOutOf(String score, int max) {
    return '$max න් $score';
  }

  @override
  String compatMatchedOutOf(int matched, int judged) {
    return '$judged න් $matched ක් ගැළපේ';
  }

  @override
  String get compatPorondamIncomplete =>
      'මෙහි පොරොන්දම් දොළහක් විනිශ්චය කෙරේ. ලංකාවේ ලිත් විස්සක් ගණන් කළත්, ඉතිරි අට එක් ලිතකින් තවත් ලිතකට වෙනස්ව දැක්වෙන බැවින්, අනුමාන කිරීමට වඩා ඒවා ඉවත් කර ඇත.';

  @override
  String get compatCaveat =>
      'මෙය මඟ පෙන්වීමක් මිස තීන්දුවක් නොවේ. මිනිසුන් දෙදෙනෙක් එකිනෙකාට යහපත්ද යන්න කේන්දරයක් කිසිදා තීරණය කර නැත - විශ්වාසවන්ත ජ්‍යෝතිෂ්‍යවේදියෙකු සමඟද, එකිනෙකා සමඟද කතා කරන්න.';

  @override
  String get compatTimeUnknown =>
      'උපන් වේලාවක් නොමැති බැවින් හිරු උදාව උපකල්පනය කරන ලදී. චන්ද්‍රයා දිනකට නැකතක් පමණ ගමන් කරන බැවින්, එය යාබද නැකතට වැටී එකවර පොරොන්දම් කිහිපයක් වෙනස් කළ හැක. දෙදෙනාගේම වේලාවන් දැනගන්නා තෙක් මෙය දළ අදහසක් ලෙස සලකන්න.';

  @override
  String get compatKujaTitle => 'කුජ දෝෂය';

  @override
  String get compatKujaNeither => 'කිසිදු කේන්දරයක එය නැත.';

  @override
  String get compatKujaBoth =>
      'කේන්දර දෙකෙහිම එය ඇත, එය අහෝසි වන බව සලකනු ලැබේ.';

  @override
  String get compatKujaUnmatched =>
      'එක් කේන්දරයක එය ඇති අතර අනෙකෙහි නැත. සම්ප්‍රදාය අනතුරු අඟවන්නේ මෙයයි.';

  @override
  String get compatKujaSevere =>
      'එක් ස්ථානයකට වඩා වැඩි ගණනකින් නැවත නැවත දක්නට ලැබේ.';

  @override
  String get compatNadiDosha => 'නාඩි දෝෂය - මෙම ක්‍රමයේ බරපතළම විරෝධය.';

  @override
  String get compatBhakootDosha =>
      'භකූට දෝෂය - චන්ද්‍ර රාශි දෙක අසුබ දුරකින් පිහිටා ඇත.';

  @override
  String get verdictGood => 'ගැළපේ';

  @override
  String get verdictPartial => 'අඩක් ගැළපේ';

  @override
  String get verdictPoor => 'නොගැළපේ';

  @override
  String get factorVarna => 'වර්ණ';

  @override
  String get factorVarnaAbout => 'චන්ද්‍ර රාශි දෙකේ මූලද්‍රව්‍ය සංසන්දනය කරයි.';

  @override
  String get factorVashya => 'වශ්‍ය';

  @override
  String get factorVashyaAbout => 'රාශි දෙක පහසුවෙන් එකට පවතීද යන්න.';

  @override
  String get factorTara => 'තාරා';

  @override
  String get factorTaraAbout => 'උපන් නැකත් දෙක අතර දෙපැත්තටම ගණන් කරයි.';

  @override
  String get factorYoni => 'යෝනි';

  @override
  String get factorYoniAbout =>
      'සත්ත්ව යුගල හරහා කියවෙන ශාරීරික හා ස්වභාව ගැළපීම.';

  @override
  String get factorGrahaMaitri => 'ග්‍රහ මෙත්‍රී';

  @override
  String get factorGrahaMaitriAbout =>
      'චන්ද්‍ර රාශි දෙකේ අධිපති ග්‍රහයන් අතර මිත්‍රත්වය.';

  @override
  String get factorGana => 'ගණ';

  @override
  String get factorGanaAbout => 'ස්වභාවය - දේව, මනුෂ්‍ය හෝ රාක්ෂස.';

  @override
  String get factorBhakoot => 'භකූට';

  @override
  String get factorBhakootAbout =>
      'චන්ද්‍ර රාශි දෙක අතර දුර. සියල්ල හෝ කිසිවක් නැත.';

  @override
  String get factorNadi => 'නාඩි';

  @override
  String get factorNadiAbout =>
      'ශරීර ස්වභාවය. එකම නාඩිය බෙදාගැනීම බලවත්ම විරෝධයයි.';

  @override
  String get factorDina => 'දින';

  @override
  String get factorDinaAbout =>
      'මනාලියගේ නැකතේ සිට මනාලයාගේ නැකත දක්වා ගණන් කරයි.';

  @override
  String get factorMahendra => 'මහේන්ද්‍ර';

  @override
  String get factorMahendraAbout =>
      'දරුඵල හා යුවළගේ සුබසාධනය සම්බන්ධ බව සැලකේ.';

  @override
  String get factorStreeDeergha => 'ස්ත්‍රී දීර්ඝ';

  @override
  String get factorStreeDeerghaAbout =>
      'මනාලයාගේ නැකත මනාලියගේ නැකතට වඩා බෙහෙවින් ඉදිරියෙන් තිබිය යුතුය.';

  @override
  String get factorRasi => 'රාශි';

  @override
  String get factorRasiAbout =>
      'මනාලයාගේ චන්ද්‍ර රාශිය හත්වැන්න හෝ ඉන් ඔබ්බෙන් තිබිය යුතුය.';

  @override
  String get factorRasiadhipathi => 'රාශ්‍යාධිපති';

  @override
  String get factorRasiadhipathiAbout => 'චන්ද්‍ර රාශි දෙකේ අධිපතියෝ.';

  @override
  String get factorRajju => 'රජ්ජු';

  @override
  String get factorRajjuAbout =>
      'එකම අංගයට වැටීම මෙහි විරෝධයයි, වෙනස් වීම නොවේ.';

  @override
  String get factorVedha => 'වේධ';

  @override
  String get factorVedhaAbout => 'සමහර නැකත් යුගල එකිනෙක විදින බව සැලකේ.';

  @override
  String get settingsTitle => 'සැකසුම්';

  @override
  String get settingsSectionProfile => 'ඔබේ තොරතුරු';

  @override
  String get settingsEditProfile => 'උපන් තොරතුරු වෙනස් කරන්න';

  @override
  String get settingsEditProfileHint =>
      'මේවා වෙනස් කිරීමෙන් සෑම කේන්දරයක්ම හා පලාපලයක්ම නැවත ගණනය වේ.';

  @override
  String get settingsSectionAppearance => 'පෙනුම';

  @override
  String get settingsTheme => 'වර්ණ රටාව';

  @override
  String get themeSystem => 'දුරකථනයට අනුව';

  @override
  String get themeLight => 'ලා පැහැ';

  @override
  String get themeDark => 'අඳුරු';

  @override
  String get settingsThemeHint =>
      'දුරකථනයේ සැකසුම කුමක් වුවත්, එළිමහනේ කියවීමට ලා පැහැය පහසුය.';

  @override
  String get settingsChartStyle => 'කේන්දර ශෛලිය';

  @override
  String get settingsLanguage => 'භාෂාව';

  @override
  String get settingsSectionData => 'ඔබේ දත්ත';

  @override
  String get settingsDeleteData => 'මගේ තොරතුරු මකන්න';

  @override
  String get settingsDeleteHint =>
      'ඔබේ උපන් තොරතුරු මෙම දුරකථනයෙන් සහ අපගේ උපස්ථයෙන් ඉවත් කරයි.';

  @override
  String get settingsDeleteTitle => 'ඔබේ තොරතුරු මකන්නද?';

  @override
  String get settingsDeleteBody =>
      'ඔබේ උපන් තොරතුරු මෙම දුරකථනයෙන් සහ අපගේ උපස්ථයෙන් ඉවත් වන අතර, ඔබේ ගිණුමද මකා දැමේ. ඔබේ කේන්දර සහ පලාපල ද ඒ සමඟම යයි. මෙය නැවත හැරවිය නොහැක.';

  @override
  String get settingsDeleteConfirm => 'මකන්න';

  @override
  String get commonCancel => 'අවලංගු කරන්න';

  @override
  String get settingsDeleted => 'ඔබේ තොරතුරු මකා දමන ලදී.';

  @override
  String get settingsSectionAbout => 'යෙදුම ගැන';

  @override
  String get settingsPrivacy => 'රහස්‍යතා ප්‍රතිපත්තිය';

  @override
  String get settingsTerms => 'නියම';

  @override
  String settingsVersion(String version) {
    return 'අනුවාදය $version';
  }

  @override
  String get settingsLinkFailed => 'එම සබැඳිය විවෘත කළ නොහැකි විය.';

  @override
  String get calendarTitle => 'නැකත් දින දර්ශනය';

  @override
  String get calendarPoya => 'පොහොය';

  @override
  String get calendarFestival => 'උත්සවය';

  @override
  String get calendarBestDays => 'මෙම මාසයේ හොඳම දින';

  @override
  String get calendarPickActivity => 'ඔබ සැලසුම් කරන්නේ කුමක්ද?';

  @override
  String get calendarScan => 'හොඳ දින සොයන්න';

  @override
  String get calendarScanning => 'මෙම මාසයේ සෑම දිනයක්ම පරීක්ෂා කරමින්...';

  @override
  String get calendarNoGoodDays =>
      'ඒ සඳහා මෙම මාසයේ හොඳ දිනයක් නැත. ඊළඟ මාසය හෝ වෙනත් කාර්යයක් උත්සාහ කරන්න.';

  @override
  String get calendarDayDetail => 'පංචාංගය';

  @override
  String get calendarClearWindows => 'නිදහස් වේලාවන්';

  @override
  String calendarScoreLabel(int score) {
    return 'ලකුණු $score';
  }

  @override
  String get activityTravel => 'ගමන් යාම';

  @override
  String get activityWorkOrStudy => 'රැකියාව හෝ අධ්‍යාපනය ඇරඹීම';

  @override
  String get activityBusiness => 'ව්‍යාපාර හෝ ගිවිසුම්';

  @override
  String get activityMarriage => 'විවාහය';

  @override
  String get activityHouseEntry => 'නව නිවසකට පිවිසීම';

  @override
  String get activityVehicle => 'වාහනයක් ගැනීම';

  @override
  String get reasonNakshatraFavours => 'දිනයේ නැකත මෙයට උචිතයි';

  @override
  String get reasonNakshatraNeutral => 'දිනයේ නැකත මෙයට මධ්‍යස්ථයි';

  @override
  String get reasonNakshatraWarnsAgainst => 'දිනයේ නැකත මෙයට අහිතකරයි';

  @override
  String get reasonTithiRikta =>
      'රික්ත තිථියකි — ආරම්භ සඳහා සම්ප්‍රදායිකව වළක්වනු ලැබේ';

  @override
  String get reasonTithiFavourable => 'සුබ තිථියකි';

  @override
  String get reasonYogaInauspicious => 'අසුබ යෝගයකි';

  @override
  String get reasonKaranaVishti => 'විෂ්ටි කරණය, එය වළක්වනු ලැබේ';

  @override
  String get reasonVaraUnfavourable => 'මෙයට වාරය එතරම් සුදුසු නැත';

  @override
  String get reasonVaraFavourable => 'සුදුසු වාරයකි';

  @override
  String get reasonShortenedByChange =>
      'දිනය තුළ ලිත වෙනස් වන බැවින් කෙටි කර ඇත';

  @override
  String get authErrorRequiresRecentLogin =>
      'ඔබේ ආරක්ෂාව සඳහා, ගිණුම මකා දැමීමට පෙර නැවත පිවිසෙන්න.';

  @override
  String get settingsDeleteFailed =>
      'ඔබේ තොරතුරු මෙම දුරකථනයෙන් ඉවත් කරන ලදී, නමුත් උපස්ථයට සම්බන්ධ විය නොහැකි විය. ඔබ සබැඳි වූ පසු නැවත උත්සාහ කරන්න.';

  @override
  String get accountTitle => 'ගිණුම';

  @override
  String accountSavedToEmail(String email) {
    return '$email වෙත සුරකින ලදී';
  }

  @override
  String get accountSavedToEmailHelp =>
      'නව දුරකථනයක මෙම ඊමේල් ලිපිනයෙන් පිවිසුණු විට ඔබේ උපන් තොරතුරු නැවත ලැබේ.';

  @override
  String get accountPhoneOnly => 'මෙම දුරකථනයේ පමණක් සුරකින ලදී';

  @override
  String get accountPhoneOnlyHelp =>
      'ඔබේ උපන් තොරතුරු උපස්ථ කර ඇත, නමුත් එම උපස්ථය මෙම ස්ථාපනයට පමණක් අයත් වේ. යෙදුමේ දත්ත මකා දැමීම හෝ නව දුරකථනයකට මාරු වීම නිසා එය සදහටම නැති වේ.';

  @override
  String get accountUnavailable => 'උපස්ථය නොමැත';

  @override
  String get accountUnavailableHelp =>
      'උපස්ථ සේවාවට සම්බන්ධ විය නොහැක. අනෙක් සියල්ල ක්‍රියා කරයි.';

  @override
  String get accountOfflineNotice =>
      'ගිණුම් සඳහා අන්තර්ජාල සම්බන්ධතාවක් අවශ්‍යයි. ඔබ සබැඳි වූ පසු නැවත උත්සාහ කරන්න — යෙදුමේ වෙනත් කිසිවක් ඒ සඳහා බලා නොසිටී.';

  @override
  String get accountKeepSafe => 'ඔබේ කේන්දරය සුරක්ෂිතව තබා ගන්න';

  @override
  String get accountSignIn => 'පිවිසෙන්න';

  @override
  String get accountSignOut => 'පිටවෙන්න';

  @override
  String get accountCreate => 'ගිණුමක් සාදන්න';

  @override
  String get accountContinueWithGoogle => 'Google සමඟ ඉදිරියට';

  @override
  String get accountOr => 'නැතහොත්';

  @override
  String get accountEmail => 'ඊමේල්';

  @override
  String get accountPassword => 'මුරපදය';

  @override
  String get accountEnterEmail => 'ඔබේ ඊමේල් ලිපිනය ඇතුළත් කරන්න';

  @override
  String get accountEnterPassword => 'මුරපදයක් ඇතුළත් කරන්න';

  @override
  String get accountInvalidEmail => 'එය ඊමේල් ලිපිනයක් ලෙස නොපෙනේ';

  @override
  String get accountPasswordTooShort => 'අවම වශයෙන් අකුරු 6ක් භාවිත කරන්න';

  @override
  String get accountToggleToSignIn => 'දැනටමත් ගිණුමක් තිබේද? පිවිසෙන්න';

  @override
  String get accountToggleToCreate => 'තවම ගිණුමක් නැද්ද? එකක් සාදන්න';

  @override
  String get accountNoVerification =>
      'අපි තහවුරු කිරීමේ ඊමේල් යවන්නේ නැත, එබැවින් ඔබට වහාම ආරම්භ කළ හැක. එයින් අදහස් වන්නේ වැරදියට ටයිප් කළ ලිපිනයක් නැවත ලබා ගත නොහැකි බවයි — ඔබට සැබවින්ම අයත් එකක් භාවිත කරන්න.';

  @override
  String get accountSignedOutHelp =>
      'පිටවීමෙන් පසුත් ඔබේ කේන්දරය මෙම දුරකථනයේ පවතී. ඔබ නැවත පිවිසෙන තෙක් එය නැවත නිර්නාමිකව උපස්ථ වේ.';

  @override
  String get accountFooter =>
      'ඔබේ කේන්දරය, නැකත් සහ ලිත මෙම දුරකථනයේම ගණනය වන අතර ගිණුමක් හෝ සම්බන්ධතාවක් නොමැතිව ක්‍රියා කරයි. ගිණුමක් තීරණය කරන්නේ දුරකථනය නැති වූ විට ඔබේ උපන් තොරතුරු ඉතිරි වේද යන්න පමණි.';

  @override
  String get accountCreatedToast => 'ගිණුම සාදන ලදී. ඔබේ කේන්දරය සුරක්ෂිතයි.';

  @override
  String get accountSignedInToast => 'පිවිසුණි.';

  @override
  String get accountSignedInGoogleToast => 'Google සමඟ පිවිසුණි.';

  @override
  String get accountSignedOutToast => 'පිටවුණි.';

  @override
  String get accountConflictTitle => 'කේන්දර දෙකක්';

  @override
  String accountConflictBody(String name) {
    return 'මෙම ගිණුමේ දැනටමත් $name ඇත, එය මෙම දුරකථනයේ ඇති කේන්දරයට වඩා වෙනස් වේ. තබා ගත හැක්කේ එකක් පමණි.';
  }

  @override
  String get accountConflictUnnamed => 'නම් නොකළ පැතිකඩක්';

  @override
  String get accountConflictKeepPhone => 'දුරකථනයේ එක තබා ගන්න';

  @override
  String get accountConflictKeepAccount => 'ගිණුමේ එක තබා ගන්න';

  @override
  String get authErrorEmailTaken =>
      'එම ඊමේල් ලිපිනයට දැනටමත් ගිණුමක් ඇත. ඒ වෙනුවට එයට පිවිසෙන්න.';

  @override
  String get authErrorInvalidEmail => 'එය ඊමේල් ලිපිනයක් ලෙස නොපෙනේ.';

  @override
  String get authErrorWeakPassword => 'අවම වශයෙන් අකුරු 6ක් භාවිත කරන්න.';

  @override
  String get authErrorWrongPassword => 'ඊමේල් ලිපිනය හෝ මුරපදය වැරදියි.';

  @override
  String get authErrorUserNotFound => 'එම ඊමේල් ලිපිනයට ගිණුමක් නැත.';

  @override
  String get authErrorUserDisabled => 'එම ගිණුම අක්‍රිය කර ඇත.';

  @override
  String get authErrorTooManyRequests =>
      'උත්සාහ කිරීම් ඉතා වැඩියි. විනාඩි කිහිපයකින් නැවත උත්සාහ කරන්න.';

  @override
  String get authErrorNoConnection =>
      'සම්බන්ධතාවක් නැත. ඔබේ කේන්දරය තවමත් නොබැඳිව ක්‍රියා කරයි.';

  @override
  String get authErrorNotEnabled =>
      'මෙම යෙදුම සඳහා ඊමේල් පිවිසුම තවම සක්‍රිය කර නැත.';

  @override
  String get authErrorGoogleUnavailable =>
      'මෙම යෙදුම සඳහා Google පිවිසුම තවම සකසා නැත.';

  @override
  String get authErrorGoogleInterrupted =>
      'Google පිවිසුම බාධා විය. නැවත උත්සාහ කරන්න.';

  @override
  String get authErrorGeneric =>
      'එය සම්පූර්ණ කළ නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get authErrorNotSignedIn => 'තවම පිවිසී නැත.';

  @override
  String get authErrorSyncUnavailable => 'සමමුහුර්තකරණය නොමැත.';

  @override
  String get authErrorCreateFailed => 'ගිණුම සෑදිය නොහැකි විය.';

  @override
  String get authErrorSignInFailed => 'පිවිසිය නොහැකි විය.';

  @override
  String get authErrorSignOutFailed => 'පිටවිය නොහැකි විය.';

  @override
  String get authErrorGoogleFailed => 'Google සමඟ පිවිසිය නොහැකි විය.';

  @override
  String get authErrorGoogleNoToken =>
      'Google වෙතින් භාවිත කළ හැකි පිවිසුමක් ලැබුණේ නැත.';

  @override
  String get language => 'භාෂාව';

  @override
  String get routeNotFound => 'පිටුව හමු නොවීය';

  @override
  String get routeGoHome => 'මුල් පිටුවට';

  @override
  String get unlockWatch => 'කෙටි වීඩියෝවක් බලන්න';

  @override
  String get unlockLoading => 'වීඩියෝව පූරණය වෙමින්…';

  @override
  String get unlockFailed => 'වීඩියෝවක් නොලැබුණි. මොහොතකින් නැවත උත්සාහ කරන්න.';

  @override
  String get unlockLastsToday => 'අද දිනය අවසන් වන තුරු විවෘතව පවතී.';

  @override
  String get unlockCompatTitle => 'සම්පූර්ණ පොරොන්දම් විස්තරය';

  @override
  String get unlockCompatBody =>
      'සෑම සාධකයක්ම වෙන් වෙන් වශයෙන් ලකුණු කර ඇති ආකාරය බලන්න.';

  @override
  String get unlockFutureTitle => 'වෙනත් දිනවල නැකත්';

  @override
  String get unlockFutureBody =>
      'ඉදිරි ඕනෑම දිනක් බලන්න — සුබ මුහූර්ත, රාහු කාලය සහ සම්පූර්ණ පංචාංගය.';

  @override
  String get authErrorGoogleRepeated =>
      'Google පිවිසුම සම්පූර්ණ නොවීය. මෙය දිගටම සිදුවේ නම්, මෙම අනුවාදය සඳහා එය සකසා නොතිබිය හැක.';

  @override
  String get horoscopeTitle => 'දෛනික ලග්න පලාපල';

  @override
  String horoscopeForSign(String sign) {
    return '$sign ලග්නය සඳහා';
  }

  @override
  String get horoscopeUnavailable =>
      'ලග්න පලාපල සඳහා ඔබේ උපන් තොරතුරු අවශ්‍යයි. කේන්දරය සකසා අවසන් කරන්න.';

  @override
  String get horoscopeGeneral => 'අද දිනය';

  @override
  String get horoscopeCareer => 'රැකියාව';

  @override
  String get horoscopeMoney => 'මුදල්';

  @override
  String get horoscopeLove => 'සබඳතා';

  @override
  String get horoscopeHealth => 'සෞඛ්‍යය';

  @override
  String get horoscopeAdvice => 'උපදෙස්';

  @override
  String get horoscopeLuckyNumber => 'සුබ අංකය';

  @override
  String get horoscopeLuckyColour => 'සුබ වර්ණය';

  @override
  String get homeHoroscopeSubtitle =>
      'අද දින ග්‍රහ ගමන ඔබේ කේන්දරයට අනුව කියවා ඇත.';

  @override
  String get colourWhite => 'සුදු';

  @override
  String get colourRed => 'රතු';

  @override
  String get colourYellow => 'කහ';

  @override
  String get colourGreen => 'කොළ';

  @override
  String get colourBlue => 'නිල්';

  @override
  String get colourOrange => 'තැඹිලි';

  @override
  String get colourBrown => 'දුඹුරු';

  @override
  String get colourGold => 'රන්';

  @override
  String get colourSilver => 'රිදී';

  @override
  String get colourPurple => 'දම්';
}
