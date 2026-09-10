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
  String get onboardingTimeUnknownLabel => 'I don\'t know my birth time';

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
  String homeWindowRunningNow(String window, String time) {
    return '$window is running now, until $time.';
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
  String get homeFestivalsExcluded =>
      'Deepavali, Eid and Milad un-Nabi are not listed: their dates follow regional convention and moon sighting rather than calculation, and a confidently wrong religious date would be worse than none.';

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
  String chartNakshatraPada(String nakshatra, int pada) {
    return '$nakshatra — pada $pada';
  }

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
  String get chartStyleSouthIndian => 'South Indian';

  @override
  String get chartStyleNorthIndian => 'North Indian';

  @override
  String get chartCentreCaption => 'Rāśi chart';

  @override
  String get chartLagnaMark => 'La';

  @override
  String get chartRetrogradeMark => 'R';

  @override
  String chartLagnaOf(String rasi) {
    return '$rasi lagna';
  }

  @override
  String get chartApproximateShort => 'approximate';

  @override
  String get dashaTitle => 'Daśā periods';

  @override
  String get dashaRunningNow => 'Running now';

  @override
  String get dashaSubPeriods => 'Sub-periods';

  @override
  String dashaEnds(String date) {
    return 'ends $date';
  }

  @override
  String get dashaBalanceNote =>
      'Your first period had already begun when you were born, so it is shown shorter than its full length.';

  @override
  String get dashaUnreliableTime =>
      'Your birth time is unknown, so sunrise was assumed. The Moon moves about half a degree an hour, which can shift these dates by years — and can even change which planet rules the first period. Treat this as a rough guide until you know your time of birth.';

  @override
  String detailHouse(int n) {
    return 'House $n';
  }

  @override
  String get detailRetrograde => 'Retrograde';

  @override
  String get detailNoGraha => 'No graha sits in this house.';

  @override
  String detailExaltedIn(String rasi, int degree) {
    return 'Exalted in $rasi at $degree°';
  }

  @override
  String get dignityOwn => 'Own sign';

  @override
  String get dignityExalted => 'Exalted';

  @override
  String get dignityDebilitated => 'Debilitated';

  @override
  String get dignityNodeNote =>
      'Rāhu and Ketu rule no sign, and traditions disagree on where they are exalted — so no dignity is claimed here.';

  @override
  String get chartShare => 'Share chart';

  @override
  String get chartShareFailed => 'Could not create the image.';

  @override
  String chartShareCaption(String name, String date, String place) {
    return '$name · $date · $place';
  }

  @override
  String get compatTitle => 'Compatibility';

  @override
  String get compatIntro =>
      'Marriage matching is read from the Moon at birth, so both sets of birth details are needed.';

  @override
  String get compatYourDetails => 'You';

  @override
  String get compatPartnerDetails => 'Partner';

  @override
  String get compatPartnerName => 'Partner\'s name';

  @override
  String get compatRoleQuestion => 'Who is the bride?';

  @override
  String get compatRoleYou => 'Me';

  @override
  String get compatRolePartner => 'My partner';

  @override
  String get compatRoleHelp =>
      'Several factors are counted from the bride to the groom and give a different answer if swapped. This is how the tradition states them.';

  @override
  String get compatSystemPorondam => 'Porondam';

  @override
  String get compatSystemAshtakoota => 'Ashtakoota';

  @override
  String get compatCalculate => 'Check compatibility';

  @override
  String get compatChangePartner => 'Change partner';

  @override
  String get compatNeedPartner =>
      'Enter your partner\'s birth details to see a match.';

  @override
  String compatScoreOutOf(String score, int max) {
    return '$score of $max';
  }

  @override
  String compatMatchedOutOf(int matched, int judged) {
    return '$matched of $judged matched';
  }

  @override
  String get compatPorondamIncomplete =>
      'Twelve porondam are judged here. Sri Lankan almanacs count twenty, but the remaining eight are stated differently from one almanac to the next, so they are left out rather than guessed at.';

  @override
  String get compatCaveat =>
      'This is guidance, not a ruling. A chart has never decided whether two people are good to each other - talk to a trusted astrologer, and to each other, before it decides anything for you.';

  @override
  String get compatTimeUnknown =>
      'A birth time is missing, so sunrise was assumed. The Moon crosses about one star a day, which can put it in the neighbouring one and change several factors at once. Treat this as indicative until both times are known.';

  @override
  String get compatKujaTitle => 'Kuja dosha';

  @override
  String get compatKujaNeither => 'Neither chart carries it.';

  @override
  String get compatKujaBoth => 'Both charts carry it, which is held to cancel.';

  @override
  String get compatKujaUnmatched =>
      'One chart carries it and the other does not. This is the case the tradition warns about.';

  @override
  String get compatKujaSevere => 'Repeated from more than one reference point.';

  @override
  String get compatNadiDosha =>
      'Nadi dosha - the heaviest single objection in this system.';

  @override
  String get compatBhakootDosha =>
      'Bhakoot dosha - the Moon signs fall at an afflicted distance.';

  @override
  String get verdictGood => 'Met';

  @override
  String get verdictPartial => 'Partly met';

  @override
  String get verdictPoor => 'Not met';

  @override
  String get factorVarna => 'Varna';

  @override
  String get factorVarnaAbout => 'Compares the elements of the two Moon signs.';

  @override
  String get factorVashya => 'Vashya';

  @override
  String get factorVashyaAbout =>
      'Whether the two signs are held to sit easily together.';

  @override
  String get factorTara => 'Tara';

  @override
  String get factorTaraAbout =>
      'Counts between the two birth stars, each way round.';

  @override
  String get factorYoni => 'Yoni';

  @override
  String get factorYoniAbout =>
      'Physical and temperamental fit, read through paired animals.';

  @override
  String get factorGrahaMaitri => 'Graha maitri';

  @override
  String get factorGrahaMaitriAbout =>
      'Friendship between the planets ruling the two Moon signs.';

  @override
  String get factorGana => 'Gana';

  @override
  String get factorGanaAbout => 'Temperament - deva, manushya or rakshasa.';

  @override
  String get factorBhakoot => 'Bhakoot';

  @override
  String get factorBhakootAbout =>
      'The distance between the two Moon signs. All or nothing.';

  @override
  String get factorNadi => 'Nadi';

  @override
  String get factorNadiAbout =>
      'Constitution. Sharing one is the strongest objection.';

  @override
  String get factorDina => 'Dina';

  @override
  String get factorDinaAbout =>
      'Counted from the bride\'s star to the groom\'s.';

  @override
  String get factorMahendra => 'Mahendra';

  @override
  String get factorMahendraAbout =>
      'Held to bear on children and the couple\'s welfare.';

  @override
  String get factorStreeDeergha => 'Stree deergha';

  @override
  String get factorStreeDeerghaAbout =>
      'Asks that the groom\'s star lie well ahead of the bride\'s.';

  @override
  String get factorRasi => 'Rasi';

  @override
  String get factorRasiAbout =>
      'Asks that the groom\'s Moon sign be seventh or beyond.';

  @override
  String get factorRasiadhipathi => 'Rasiadhipathi';

  @override
  String get factorRasiadhipathiAbout => 'The lords of the two Moon signs.';

  @override
  String get factorRajju => 'Rajju';

  @override
  String get factorRajjuAbout =>
      'Falling in the same limb is the objection here, not differing.';

  @override
  String get factorVedha => 'Vedha';

  @override
  String get factorVedhaAbout =>
      'Certain star pairs are held to pierce one another.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionProfile => 'Your details';

  @override
  String get settingsEditProfile => 'Edit birth details';

  @override
  String get settingsEditProfileHint =>
      'Changing these recalculates every chart and reading.';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'Follow the phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsThemeHint =>
      'Light is easier to read outdoors, whatever the phone is set to.';

  @override
  String get settingsChartStyle => 'Chart style';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSectionReminders => 'Reminders';

  @override
  String get settingsDailyReminder => 'Morning nekath';

  @override
  String get settingsDailyReminderHint =>
      'The day\'s rāhu kālaya, before you start anything.';

  @override
  String get settingsReminderTime => 'Time';

  @override
  String get settingsPoyaReminder => 'Poya reminder';

  @override
  String get settingsPoyaReminderHint => 'The evening before a poya day.';

  @override
  String get settingsNotificationsBlocked =>
      'Notifications are turned off for Nakshatra in your phone\'s settings.';

  @override
  String get notificationDailyTitle => 'Today\'s nekath';

  @override
  String notificationDailyBody(String start, String end) {
    return 'Rāhu kālaya $start – $end';
  }

  @override
  String get notificationDailyBodyUnknown => 'Open for today\'s nekath.';

  @override
  String get notificationPoyaTitle => 'Poya tomorrow';

  @override
  String notificationPoyaBody(String poya) {
    return '$poya is tomorrow.';
  }

  @override
  String get settingsSectionData => 'Your data';

  @override
  String get settingsDeleteData => 'Delete my details';

  @override
  String get settingsDeleteHint =>
      'Removes your birth details from this phone and from our backup.';

  @override
  String get settingsDeleteTitle => 'Delete your details?';

  @override
  String get settingsDeleteBody =>
      'Your birth details will be removed from this phone and from our backup, and your account will be deleted. Your charts and readings go with them, and this cannot be undone.';

  @override
  String get settingsDeleteConfirm => 'Delete';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get settingsDeleted => 'Your details have been deleted.';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsLinkFailed => 'Could not open that link.';

  @override
  String get calendarTitle => 'Nekath calendar';

  @override
  String get calendarPoya => 'Poya';

  @override
  String get calendarFestival => 'Festival';

  @override
  String get calendarThisMonth => 'This month';

  @override
  String get calendarNoEvents => 'No poya or festival this month.';

  @override
  String get calendarAnnounced => 'Announced each year';

  @override
  String get calendarAnnouncedHelp =>
      'These are set by moon sighting or local custom, so they are not calculated here. Check the year\'s gazette.';

  @override
  String get calendarBestDays => 'Best days this month';

  @override
  String get calendarPickActivity => 'What are you planning?';

  @override
  String get calendarScan => 'Find good days';

  @override
  String get calendarScanning => 'Checking every day this month...';

  @override
  String get calendarNoGoodDays =>
      'Nothing this month scores well for that. Try the next month, or a different activity.';

  @override
  String get calendarDayDetail => 'Panchanga';

  @override
  String get calendarClearWindows => 'Clear windows';

  @override
  String calendarScoreLabel(int score) {
    return 'Score $score';
  }

  @override
  String get activityTravel => 'Travel';

  @override
  String get activityWorkOrStudy => 'Starting work or study';

  @override
  String get activityBusiness => 'Business or signing';

  @override
  String get activityMarriage => 'Marriage';

  @override
  String get activityHouseEntry => 'Moving into a house';

  @override
  String get activityVehicle => 'Buying a vehicle';

  @override
  String get reasonNakshatraFavours => 'The star of the day suits this';

  @override
  String get reasonNakshatraNeutral =>
      'The star of the day is neutral for this';

  @override
  String get reasonNakshatraWarnsAgainst =>
      'The star of the day is warned against for this';

  @override
  String get reasonTithiRikta =>
      'A rikta tithi — traditionally avoided for beginnings';

  @override
  String get reasonTithiFavourable => 'A favourable tithi';

  @override
  String get reasonYogaInauspicious => 'An inauspicious yoga';

  @override
  String get reasonKaranaVishti => 'Vishti karana, which is avoided';

  @override
  String get reasonVaraUnfavourable => 'The weekday is not the best for this';

  @override
  String get reasonVaraFavourable => 'A suitable weekday';

  @override
  String get reasonShortenedByChange =>
      'Shortened because the almanac changes during the day';

  @override
  String get authErrorRequiresRecentLogin =>
      'For your security, please sign in again before deleting your account.';

  @override
  String get settingsDeleteFailed =>
      'Your details were removed from this phone, but the backup could not be reached. Try again once you are online.';

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
  String get language => 'Language';

  @override
  String get routeNotFound => 'Page not found';

  @override
  String get routeGoHome => 'Go home';

  @override
  String get unlockWatch => 'Watch a short video';

  @override
  String get unlockLoading => 'Loading the video…';

  @override
  String get unlockFailed =>
      'No video was available. Please try again in a moment.';

  @override
  String get unlockLastsToday => 'Stays unlocked for the rest of today.';

  @override
  String get unlockCompatTitle => 'Full compatibility breakdown';

  @override
  String get unlockCompatBody =>
      'See every factor scored one by one, and what each one judges.';

  @override
  String get unlockFutureTitle => 'Nekath for other days';

  @override
  String get unlockFutureBody =>
      'Open any day ahead — auspicious times, rahu kalaya and the full panchanga.';

  @override
  String get authErrorGoogleRepeated =>
      'Google sign-in did not complete. If this keeps happening, it may not be set up for this version of the app.';

  @override
  String get horoscopeTitle => 'Daily horoscope';

  @override
  String get horoscopeUnavailable =>
      'Your horoscope needs your birth details. Finish setting up your chart to see it.';

  @override
  String get horoscopeGeneral => 'The day';

  @override
  String get horoscopeCareer => 'Work';

  @override
  String get horoscopeMoney => 'Money';

  @override
  String get horoscopeLove => 'Relationships';

  @override
  String get horoscopeHealth => 'Health';

  @override
  String get horoscopeAdvice => 'Advice';

  @override
  String get horoscopeLuckyNumber => 'Lucky number';

  @override
  String get horoscopeLuckyColour => 'Lucky colour';

  @override
  String get homeHoroscopeSubtitle =>
      'Read from today\'s transits against your chart.';

  @override
  String get colourWhite => 'White';

  @override
  String get colourRed => 'Red';

  @override
  String get colourYellow => 'Yellow';

  @override
  String get colourGreen => 'Green';

  @override
  String get colourBlue => 'Blue';

  @override
  String get colourOrange => 'Orange';

  @override
  String get colourBrown => 'Brown';

  @override
  String get colourGold => 'Gold';

  @override
  String get colourSilver => 'Silver';

  @override
  String get colourPurple => 'Purple';

  @override
  String get horoscopeByLagna => 'Lagna';

  @override
  String get horoscopeByRasi => 'Moon sign';

  @override
  String get horoscopeSameSign => 'Your lagna and moon sign are the same.';

  @override
  String get horoscopeLagnaApproximate =>
      'Your birth time is unknown, so this lagna is approximate.';

  @override
  String durationMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get purchaseSectionTitle => 'Nakshatra Pro';

  @override
  String get purchaseStatusFree => 'Free';

  @override
  String get purchaseStatusAdFree => 'Ads removed';

  @override
  String purchaseStatusProUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Pro until $dateString';
  }

  @override
  String get purchaseUpgrade => 'Go Pro';

  @override
  String get purchaseUpgradeHint =>
      'No ads, every divisional chart, and the full daśā timeline.';

  @override
  String get purchaseManage => 'Manage subscription';

  @override
  String get purchaseRestore => 'Restore purchases';

  @override
  String get purchaseRestoreHint =>
      'Already paid? Bring your purchases to this device.';

  @override
  String get purchaseRestored => 'Your purchases are back.';

  @override
  String get purchaseRestoreNothing => 'Nothing to restore on this account.';

  @override
  String get purchaseRestoreFailed =>
      'Could not reach the store. Check your connection and try again.';

  @override
  String get purchaseUnavailable =>
      'Purchases are not available in this build.';

  @override
  String get purchaseThanks => 'Thank you. Your purchase is active.';

  @override
  String get purchasePending =>
      'Payment is still processing. This will unlock on its own once it completes.';

  @override
  String get purchaseAlreadyOwned =>
      'You already own this. Try Restore purchases.';

  @override
  String get purchaseNotAllowed => 'Purchases are not allowed on this device.';

  @override
  String get purchaseProductUnavailable =>
      'This is not on sale yet. Please try again later.';

  @override
  String get purchaseFailed =>
      'Something went wrong. You have not been charged.';

  @override
  String get paywallHeadlineValue => 'Unlock the whole almanac';

  @override
  String get paywallHeadlineSupport => 'Keep Nakshatra going';

  @override
  String get paywallBodyValue =>
      'Every divisional chart, the full daśā timeline, and the detailed compatibility working — with no ads anywhere.';

  @override
  String get paywallBodySupport =>
      'Nakshatra is built by one person in Sri Lanka. Going Pro pays for the work — and removes every ad while it does.';

  @override
  String get paywallBestValue => 'Best value';

  @override
  String paywallSave(int percent) {
    return 'Save $percent%';
  }

  @override
  String get paywallPerMonth => 'per month';

  @override
  String get paywallPerYear => 'per year';

  @override
  String get paywallOneTime => 'one payment';

  @override
  String paywallFreeTrial(int days, String price) {
    return '$days days free, then $price';
  }

  @override
  String get paywallRemoveAdsTitle => 'Just remove the ads';

  @override
  String get paywallRemoveAdsBody =>
      'One payment. Everything else stays as it is.';

  @override
  String get paywallWatchTitle => 'Or watch a short video';

  @override
  String get paywallWatchBody =>
      'Free, and it opens this for the rest of today.';

  @override
  String get paywallPricesLoading => 'Loading prices…';

  @override
  String get paywallPricesUnavailable =>
      'Prices are not available right now. Please try again later.';

  @override
  String get paywallLegal =>
      'Subscriptions renew automatically until cancelled. Cancel any time in Google Play.';

  @override
  String get paywallFeatureNoAds => 'No ads, anywhere';

  @override
  String get paywallFeatureCharts => 'Every divisional chart';

  @override
  String get paywallFeatureDasha => 'The full daśā timeline';

  @override
  String get paywallFeatureCompat => 'The full compatibility working';

  @override
  String get paywallFeatureProfiles => 'Charts for the whole family';

  @override
  String get paywallFeatureTransits => 'Transit alerts';

  @override
  String get paywallReasonCompat => 'See the full compatibility working';

  @override
  String get paywallReasonFuture => 'Look further ahead';

  @override
  String get reportTitle => 'Birth Chart Report';

  @override
  String reportPreparedOn(String date) {
    return 'Prepared $date';
  }

  @override
  String reportBornOn(String date, String time) {
    return 'Born $date at $time';
  }

  @override
  String reportBornOnDateOnly(String date) {
    return 'Born $date';
  }

  @override
  String reportPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get reportSectionRasi => 'Rāśi chart (D1)';

  @override
  String get reportSectionNavamsa => 'Navāṁśa chart (D9)';

  @override
  String get reportNavamsaNote =>
      'The navāṁśa divides each rāśi into nine parts. It is read alongside the rāśi chart, not instead of it.';

  @override
  String get reportSectionDasha => 'Vimśottarī mahādaśā';

  @override
  String get reportSectionMethod => 'How this was calculated';

  @override
  String get reportMethodBody =>
      'Positions are sidereal, using the Lahiri ayanāṃśa and whole-sign houses, computed on your device from the Swiss Ephemeris.';

  @override
  String get reportGenerate => 'Birth chart report (PDF)';

  @override
  String get reportGenerateHint =>
      'A printable report in your language, to keep or to share.';

  @override
  String get reportPreparing => 'Preparing your report…';

  @override
  String get reportFailed =>
      'The report could not be created. Please try again.';

  @override
  String get reportShareText => 'My birth chart, from Nakshatra.';

  @override
  String get reportRegenerateNote =>
      'Yours to make again any time — this is a one-time purchase.';

  @override
  String get settingsFestivalReminder => 'Festival nekath';

  @override
  String get settingsFestivalReminderHint =>
      'The evening before Avurudu and Thai Pongal.';

  @override
  String get settingsDashaReminder => 'Daśā changes';

  @override
  String get settingsDashaReminderHint =>
      'When a new planetary period begins in your chart.';

  @override
  String get notificationFestivalTitle => 'Festival tomorrow';

  @override
  String notificationFestivalBody(Object festival) {
    return '$festival is tomorrow.';
  }

  @override
  String get notificationDashaTitle => 'A new daśā begins';

  @override
  String notificationDashaMahaBody(Object lord) {
    return 'Your $lord mahādaśā starts today.';
  }

  @override
  String notificationDashaAntaraBody(Object lord) {
    return 'Your $lord antardaśā starts today.';
  }
}
