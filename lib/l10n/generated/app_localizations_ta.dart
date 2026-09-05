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
  String get homeComingSoon => 'தினசரி ராசிபலனும் உங்கள் தற்போதைய தசா காலமும்.';

  @override
  String get homeFestivalsExcluded =>
      'தீபாவளியும் ஈதும் இங்கு பட்டியலிடப்படவில்லை: அவற்றின் தேதிகள் கணக்கீட்டை விட வட்டார மரபு மற்றும் பிறை பார்த்தலைப் பொறுத்தே அமைகின்றன. தவறான ஒரு மத நாளை உறுதியாகக் காட்டுவதை விடக் காட்டாமல் இருப்பது நல்லது.';

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
  String chartAyanamsa(String degrees) {
    return 'அயனாம்சம் (லாஹிரி): $degrees°';
  }

  @override
  String get chartPositions => 'கிரக நிலைகள்';

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
}
