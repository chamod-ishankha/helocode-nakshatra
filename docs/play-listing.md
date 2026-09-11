# Play Store listing (KAN-39)

Everything to paste into **Play Console → Grow → Store presence → Main store
listing**, in all three languages, plus the keyword reasoning behind it and the
content rating answers.

Checked in rather than typed straight into the console so the copy can be
reviewed, corrected and versioned like anything else — and so a claim in the
listing and the code that has to back it up can change in the same commit.

Character counts in this file are **verified**, not estimated:
`tool/check_listing_lengths.py` reads the tables below and fails if anything is
over. Play truncates silently in some places and refuses to save in others, and
Sinhala is where it bites — a single letter with a vowel sign and a ZWJ is
several characters to Play's counter and one glyph to a reader.

## Limits

| Field | Limit | Notes |
|---|---|---|
| App name | 30 | Shown under the icon. Truncated hard on the device. |
| Short description | 80 | The line under the title in search results. |
| Full description | 4000 | Only the first ~3 lines show before "Read more". |

> **The title in the ticket does not fit.** KAN-39 specifies
> `Nakshatra: Nekath, Litha and Horoscope`, which is **38 characters** against a
> 30 limit. The titles below keep the name plus the two words people actually
> search for, and drop "Horoscope" — it is the least-searched of the three in
> Sri Lanka and the one the short description can carry instead.

---

## English (en-US — the default listing)

**App name**

```
Nakshatra: Nekath & Litha
```

**Short description**

```
Sri Lankan nekath, litha and your birth chart. Works offline, in 3 languages.
```

**Full description**

```
Nakshatra works out the nekath, the litha and your birth chart on your own phone. No account, no internet, no waiting.

TODAY'S NEKATH, EVERY MORNING
Rahu kalaya, yamaganda and gulika kalaya for where you are, with the clear hours between them marked out. Sunrise, sunset and moonrise. The full panchanga: vara, tithi, nakshatra, yoga and karana, each with the time it changes.

THE LITHA, A YEAR AT A TIME
Every poya day with its name and month. Sinhala and Tamil New Year with the exact ingress moment, and Thai Pongal. The auspicious times that belong to each.

YOUR BIRTH CHART
A rasi chart drawn South Indian or North Indian, whichever you grew up reading. Planetary positions to the degree, whole-sign houses, and your birth nakshatra with its pada. The navamsa (D9) beside it. Tap any house or graha for the detail behind it.

VIMSHOTTARI DASHA
The period running now and when it ends, over the full timeline of mahadasha and antardasha.

MARRIAGE COMPATIBILITY
Ashtakoota and the ten porondam, scored factor by factor rather than as one number. Kuja dosha, Nadi, Bhakoot and Rajju each checked and explained in plain words.

A DAILY READING
Written from today's transits against your own chart, not a column for everybody born in the same month.

REMINDERS, IF YOU WANT THEM
The morning nekath. The evening before a poya. Before Avurudu and Thai Pongal. When a new dasha begins in your chart. When Sani, Guru, Rahu or Ketu changes rasi. Each one is a separate switch, and all of them start off.

IN YOUR LANGUAGE
Sinhala, Tamil and English throughout — the graha and rasi names, the almanac vocabulary, the dates, and the readings themselves.

COMPUTED ON YOUR PHONE
Positions come from the Swiss Ephemeris: sidereal, Lahiri ayanamsa, whole-sign houses. Nothing is fetched from a server, so the almanac still works with no signal and your birth details never have to leave the device.

Nakshatra is for entertainment purposes only.
```

---

## Sinhala (si-LK)

> This is the listing that matters. Sri Lankan organic search for this app is
> overwhelmingly Sinhala, and the English listing exists mostly for people who
> already know the name.

**App name**

```
නක්ෂත්‍ර: නැකත් සහ ලිත
```

**Short description**

```
ශ්‍රී ලාංකික නැකත්, ලිත සහ ඔබේ කේන්දරය. අන්තර්ජාලය නොමැතිව ක්‍රියා කරයි.
```

**Full description**

```
නක්ෂත්‍ර මඟින් නැකත්, ලිත සහ ඔබේ කේන්දරය ඔබේ දුරකථනයේදීම ගණනය කරයි. ගිණුමක් නැත, අන්තර්ජාලය අවශ්‍ය නැත.

අද දවසේ නැකත්
ඔබ සිටින ස්ථානයට රාහු කාලය, යමගණ්ඩ සහ ගුලික කාලය. ඒවා අතර ඇති සුබ වේලාවන් වෙන්ව දක්වා ඇත. ඉර උදාව, ඉර බැසීම සහ සඳු උදාව. සම්පූර්ණ පංචාංගය — වාර, තිථි, නක්ෂත්‍ර, යෝග සහ කරණ — එක් එක් වෙනස් වන වේලාව සමඟ.

ලිත, වසරක් පුරා
සෑම පෝය දිනයක්ම එහි නම සහ මාසය සමඟ. සිංහල හා දෙමළ අලුත් අවුරුද්ද නිශ්චිත සංක්‍රාන්ති මොහොත සමඟ, සහ තෛපොංගල්. ඒවාට අදාළ නැකත් වේලාවන්.

ඔබේ කේන්දරය
දකුණු ඉන්දීය හෝ උතුරු ඉන්දීය ආකාරයට රාශි චක්‍රය. අංශක දක්වා ග්‍රහ පිහිටීම්, භාව, සහ ඔබේ ජන්ම නක්ෂත්‍රය එහි පාදය සමඟ. නවාංශ (D9) කේන්දරයද. ඕනෑම භාවයක් හෝ ග්‍රහයෙක් ස්පර්ශ කර විස්තර බලන්න.

විංශෝත්තරී දශාව
දැන් ගතවන දශාව, එය අවසන් වන දිනය, සහ මහාදශා හා අන්තර්දශා සම්පූර්ණ කාලරේඛාව.

විවාහ පොරොන්දම්
අෂ්ටකූට සහ පොරොන්දම් දහය, එකින් එක ලකුණු කර. කුජ දෝෂය, නාඩි, භකූට සහ රජ්ජු පැහැදිලිව විස්තර කර ඇත.

දෛනික පලාපල
ඔබේම කේන්දරයට එරෙහිව අද දවසේ ග්‍රහ ගමන් අනුව ලියා ඇත.

ඔබ කැමති නම් මතක් කිරීම්
උදෑසන නැකත. පෝය දිනයට පෙර සවස. අවුරුදු සහ තෛපොංගල් වලට පෙර. ඔබේ කේන්දරයේ නව දශාවක් ආරම්භ වන විට. ශනි, ගුරු, රාහු හෝ කේතු රාශිය වෙනස් වන විට. සෑම එකක්ම වෙනම ස්විචයකි, සියල්ලම මුලින් අක්‍රියයි.

ඔබේ භාෂාවෙන්
සිංහල, දෙමළ සහ ඉංග්‍රීසි — ග්‍රහ හා රාශි නම්, පංචාංග වචන, දින සහ පලාපල.

ඔබේ දුරකථනයේදීම ගණනය කරයි
ග්‍රහ පිහිටීම් ස්විස් එෆිමරිස් මඟින්: නිරයන, ලහිරි අයනාංශය, භාව ක්‍රමය. සේවාදායකයකින් කිසිවක් ලබා නොගනී, එබැවින් සංඥාවක් නොමැතිව වුවද ලිත ක්‍රියා කරයි.

නක්ෂත්‍ර විනෝදාස්වාදය සඳහා පමණි.
```

---

## Tamil (ta-IN)

**App name**

```
நக்ஷத்ரா: நேரம், பஞ்சாங்கம்
```

**Short description**

```
இலங்கை சுப நேரம், பஞ்சாங்கம், ஜாதகம். இணையம் இல்லாமல் வேலை செய்யும்.
```

**Full description**

```
நக்ஷத்ரா உங்கள் தொலைபேசியிலேயே சுப நேரம், பஞ்சாங்கம் மற்றும் உங்கள் ஜாதகத்தைக் கணக்கிடுகிறது. கணக்கு தேவையில்லை, இணையம் தேவையில்லை.

இன்றைய சுப நேரம்
நீங்கள் இருக்கும் இடத்திற்கான ராகு காலம், எமகண்டம் மற்றும் குளிகை காலம். இடையில் உள்ள நல்ல நேரங்கள் தனியாகக் காட்டப்படுகின்றன. சூரிய உதயம், அஸ்தமனம், சந்திர உதயம். முழு பஞ்சாங்கம் — வாரம், திதி, நட்சத்திரம், யோகம், கரணம் — ஒவ்வொன்றும் மாறும் நேரத்துடன்.

பஞ்சாங்கம், ஒரு வருடம் முழுவதும்
ஒவ்வொரு பௌர்ணமி நாளும் அதன் பெயருடன். சிங்கள தமிழ் புத்தாண்டு சரியான சங்கராந்தி நேரத்துடன், தைப்பொங்கல். அவற்றுக்குரிய சுப முகூர்த்தங்கள்.

உங்கள் ஜாதகம்
தென்னிந்திய அல்லது வட இந்திய முறையில் ராசிக் கட்டம். பாகை அளவில் கிரக நிலைகள், வீடுகள், உங்கள் ஜென்ம நட்சத்திரம் அதன் பாதத்துடன். நவாம்சம் (D9) கட்டமும். எந்த வீட்டையும் கிரகத்தையும் தொட்டு விவரம் பாருங்கள்.

விம்சோத்தரி தசை
இப்போது நடக்கும் தசை, அது முடியும் நாள், மற்றும் மகா தசை அந்தர் தசையின் முழு காலவரிசை.

திருமணப் பொருத்தம்
அஷ்டகூடம் மற்றும் பத்துப் பொருத்தங்கள், ஒவ்வொன்றாக மதிப்பிடப்பட்டு. செவ்வாய் தோஷம், நாடி, பகூடம், ரஜ்ஜு ஆகியவை தெளிவாக விளக்கப்பட்டுள்ளன.

தினசரி பலன்
உங்கள் சொந்த ஜாதகத்திற்கு எதிரான இன்றைய கோச்சாரத்திலிருந்து எழுதப்பட்டது.

நீங்கள் விரும்பினால் நினைவூட்டல்கள்
காலை சுப நேரம். பௌர்ணமிக்கு முந்தைய மாலை. புத்தாண்டு மற்றும் தைப்பொங்கலுக்கு முன். உங்கள் ஜாதகத்தில் புதிய தசை தொடங்கும்போது. சனி, குரு, ராகு அல்லது கேது ராசி மாறும்போது. ஒவ்வொன்றும் தனித் தனி சுவிட்ச், அனைத்தும் ஆரம்பத்தில் அணைக்கப்பட்டவை.

உங்கள் மொழியில்
சிங்களம், தமிழ், ஆங்கிலம் — கிரக ராசிப் பெயர்கள், பஞ்சாங்கச் சொற்கள், தேதிகள், பலன்கள்.

உங்கள் தொலைபேசியிலேயே கணக்கிடப்படுகிறது
கிரக நிலைகள் ஸ்விஸ் எபிமெரிஸிலிருந்து: நிரயன, லாஹிரி அயனாம்சம். எந்தத் தரவும் சேவையகத்திலிருந்து பெறப்படுவதில்லை, எனவே இணைப்பு இல்லாமலும் பஞ்சாங்கம் வேலை செய்யும்.

நக்ஷத்ரா பொழுதுபோக்கிற்கு மட்டுமே.
```

---

## Keywords

Play has no keyword field — it indexes the title, the short description and the
full description. So the words below have to *appear in the copy*, which is why
the descriptions read the way they do rather than being shorter.

Both transliterations are covered deliberately: people type what they hear, and
the same word reaches Play spelled several ways.

| Term | Script | Where it appears | Why |
|---|---|---|---|
| නැකත් / nekath | si, en | title, short, full | The single highest-intent term in the market. |
| ලිත / litha | si, en | title, short, full | What people call the almanac itself. |
| රාහු කාලය / rahu kalaya | si, en | full | Searched daily, not seasonally. |
| සුබ නැකත් | si | full | The "auspicious time" long-tail. |
| කේන්දරය / kendaraya | si | short, full | Birth chart, the second reason people install. |
| පොරොන්දම් / porondam | si, en | full | Marriage matching; high intent, low competition. |
| ලග්නය, පලාපල | si | full | Daily-horoscope long-tail. |
| පෝය, අවුරුදු නැකත් | si | full | Seasonal spikes twice a year. |
| பஞ்சாங்கம் / panchanga | ta, en | title, short, full | The Tamil equivalent of litha. |
| ராகு காலம் | ta | full | As above, Tamil-speaking north and east. |
| ஜாதகம் | ta | short, full | Birth chart. |
| பொருத்தம் | ta | full | Compatibility. |
| சுப முகூர்த்தம் | ta | full | Auspicious timing. |
| nakshatra, panchang, rasi palan | en | title, full | Reaches the Indian-diaspora spellings too. |

**Deliberately not chased:** "astrology", "horoscope" and "zodiac" on their own.
They are dominated globally by apps with budgets, and they bring installs from
people who want Western sun-sign content and will bounce. The long-tail Sinhala
and Tamil terms convert far better for a fraction of the competition.

## Category and declarations

| Field | Value |
|---|---|
| App category | Lifestyle |
| Tags | Astrology, Horoscopes (max 5; these two are the only accurate ones) |
| Contains ads | **Yes** — AdMob banner, interstitial and rewarded |
| In-app purchases | **Yes** — LKR 490 to LKR 3,900 range |
| Content rating | See below |
| Target audience | 18+ |
| Data safety | See [play-data-safety.md](play-data-safety.md) |

## Content rating questionnaire (IARC)

Answers for **App content → Content rating**. Category to select: **Reference,
News, or Educational**.

| Question | Answer |
|---|---|
| Violence, realistic or fantasy | No |
| Sexual content or nudity | No |
| Profanity or crude humour | No |
| Controlled substances | No |
| Gambling — simulated or real | No |
| Users can interact or share content | No |
| Shares user location with other users | No |
| Allows purchase of digital goods | **Yes** |
| Contains ads | **Yes** |
| Horror or fear themes | No |

Expected outcome: **Everyone / PEGI 3 / 3+**.

> **The misrepresentation rule is the one to be careful about.** Play's
> Misrepresentation policy covers fortune-telling and prediction. An app that
> presents astrological output as fact, or implies medical, legal or financial
> guidance, gets rejected or pulled. The listing therefore ends with the same
> line the app carries on every screen — *"for entertainment purposes only"* —
> and the copy above claims accurate *calculation* (which is true and testable)
> and never accurate *prediction*. Keep that distinction if you rewrite it.

## Graphics

Sizes are what Play accepts today; re-check at upload, the console is the
authority.

| Asset | Spec | Status |
|---|---|---|
| App icon | 512 × 512 PNG, 32-bit | **Done** — `assets/store/play_icon_512.png` |
| Feature graphic | 1024 × 500 PNG or JPEG, no alpha | **Done** — `assets/store/feature_graphic_1024x500.png`, built from `feature_graphic.html` by `tool/build_feature_graphic.py` |
| Phone screenshots | min 4, max 8 | **Done** — 22 files, three languages |
| Tablet screenshots | optional | Skip — no tablet layout is designed |

**Screenshots.** The M115F captures at 720 × 1560, which is 9:19.5 — taller than
the 16:9-to-9:16 window Play describes for phone screenshots. Either capture on
a 16:9 device, or letterbox these to 1080 × 1920. Do not stretch them; the
chart is a square grid and it will show.

### How to capture, and three things that spoil a shot

Found by taking a set on the M115F. Each one is invisible until the screenshots
are already taken.

1. **Build without the debug banner.** A debug build paints `DEBUG` across the
   top-right corner, over the app bar, in every single shot. Use a profile or
   release build: `flutter build apk --profile --flavor prod`.
2. **Rename the profile first.** The chart screen puts the profile name in the
   app bar, so a test profile ships a screenshot titled "Test Account 1".
   Use a plausible Sri Lankan name — it also makes the shot look like a real
   person's chart, which is the point.
3. **Capture as a purchaser, or with no ad ids.** The home screen carries a
   banner at the bottom. In a test build that reads "This is a 320x50 test ad",
   which is the worst thing that could be in a store screenshot, and with live
   ids it is a real ad in your own marketing. Buy Remove Ads on the capture
   device, or build with `ADMOB_*` blank so `AdUnits.isConfigured` is false and
   nothing renders.

### The set exists

All three languages are captured and filed under
[`assets/store/screenshots/`](../assets/store/screenshots/) — `en/` (8),
`si/` (7), `ta/` (7), twenty-two files, 1080 × 2340. Upload in filename
order; see the README in that folder for how they were taken and what to
check before uploading.

Shot list, in the order they should appear. The first two are what most people
ever see, so they carry the two reasons to install:

| # | Screen | Caption (en) | Caption (si) | Caption (ta) |
|---|---|---|---|---|
| 1 | Home, rāhu kālaya card | Today's nekath, before you start anything | අද දවසේ නැකත්, ඔබ යමක් පටන් ගැනීමට පෙර | இன்றைய சுப நேரம், நீங்கள் தொடங்கும் முன் |
| 2 | Chart, South Indian | Your birth chart, drawn how you read it | ඔබේ කේන්දරය, ඔබ කියවන ආකාරයට | உங்கள் ஜாதகம், நீங்கள் படிக்கும் முறையில் |
| 3 | Home, pañcāṅga card | The full panchanga, with the times it changes | සම්පූර්ණ පංචාංගය, වෙනස් වන වේලාවන් සමඟ | முழு பஞ்சாங்கம், மாறும் நேரங்களுடன் |
| 4 | Calendar, poya list | Every poya and festival, a year ahead | සෑම පෝයක්ම, වසරක් ඉදිරියට | ஒவ்வொரு பௌர்ணமியும், ஒரு வருடம் முன்னதாக |
| 5 | Daśā timeline | Which dasha is running, and until when | ගතවන දශාව සහ එය අවසන් වන දිනය | நடக்கும் தசை, எப்போது முடியும் |
| 6 | Compatibility result | Porondam scored factor by factor | පොරොන්දම් එකින් එක ලකුණු කර | பொருத்தம் ஒவ்வொன்றாக மதிப்பிடப்பட்டு |
| 7 | Horoscope | A reading from your own chart | ඔබේම කේන්දරයෙන් පලාපල | உங்கள் சொந்த ஜாதகத்திலிருந்து பலன் |
| 8 | Settings, language | Sinhala, Tamil and English throughout | සිංහල, දෙමළ සහ ඉංග්‍රීසි | சிங்களம், தமிழ், ஆங்கிலம் |

Capture each in its own language — a Sinhala listing showing English screenshots
is the commonest way a localised listing still reads as foreign.

## Still to do

- [x] ~~Feature graphic (1024 × 500)~~ — built as markup, because image
      generators cannot shape Sinhala or Tamil: one attempt misspelt the app's
      own name as நகஷ்திரார், and the next invented a page of English and a
      Ganesha icon. Edit the HTML and re-run the tool to change it.
- [x] ~~Capture the screenshots, three times~~ — 22 filed under
      `assets/store/screenshots/`
- [ ] Native pass over the Sinhala and Tamil **marketing** copy. The UI strings
      in this app were written to be plain and literal, which translates
      honestly. Marketing copy is not that — it has rhythm and idiom, and this
      is the one place where a slightly wooden sentence costs installs. Same
      reasoning as KAN-62.
- [ ] Enter the content rating questionnaire (console only)
- [ ] Confirm the phone screenshot aspect ratio against the console at upload
