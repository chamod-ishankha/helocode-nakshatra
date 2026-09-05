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
  String get homeComingSoon => 'දෛනික ලග්න පලාපල සහ ඔබේ වත්මන් දශා කාලය.';

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
  String get routeNotFound => 'පිටුව හමු නොවීය';

  @override
  String get routeGoHome => 'මුල් පිටුවට';
}
