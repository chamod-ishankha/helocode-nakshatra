# Play Store screenshots

Captured from the **prod flavour, profile build** on a Galaxy S23 (SM-S911B),
1080 × 2340, on 11 September 2026. One folder per store listing.

**Upload `framed/`.** `en/`, `si/` and `ta/` hold the raw captures; `framed/`
holds the same shots on a branded background with a heading and a subtitle,
at 1080 × 1920. Build them with:

```
python tool/build_store_screenshots.py
```

Framing does two jobs. It reads better in a listing, and it fixes a real
problem: a raw capture off this device is 9:19.5, taller than the 16:9-to-9:16
window Play documents. The framed canvas is exactly 9:16, so the ratio
question goes away without stretching a single pixel.

Headings come from the app's own ARB strings — `chartTitle`, `dashaTitle` and
so on — so the store and the app say the same words rather than two
translations of one idea. Subtitles live in `tool/store_captions.json`.

Upload in filename order. Play shows the first two above the fold, so the
daily reason to open the app comes first and the birth chart second.

| # | Screen | en | si | ta |
|---|---|---|---|---|
| 01 | Home — rāhu kālaya and the full pañcāṅga | ✓ | ✓ | ✓ |
| 02 | Birth chart, South Indian | ✓ | ✓ | ✓ |
| 03 | Vimśottarī daśā, running period expanded | ✓ | ✓ | ✓ |
| 04 | Compatibility — the twelve porondam scored | ✓ | ✓ | ✓ |
| 05 | Daily reading | ✓ | ✓ | ✓ |
| 06 | Nekath calendar | ✓ | ✓ | ✓ |
| 07 | Settings — language, chart style, reminders | ✓ | ✓ | ✓ |
| 08 | Planetary positions table | ✓ | — | — |

Twenty-two files. English has one extra; the positions table is the same
numbers in every language and the first seven already carry the point.

## How they were captured, and why it matters

Three things spoil a set, and all three are invisible until the shots are
already taken:

1. **A debug build paints `DEBUG` across the app bar** in every frame. These
   are `--profile`.
2. **The chart screen puts the profile name in the app bar**, so a test
   profile ships a screenshot titled "Test Account 1". The profile here is
   Sanduni Perera, 14 April 1995, Colombo, born 10:00.
3. **The home screen carries a banner ad.** Built with every `ADMOB_*` key
   blank, so `AdUnits.isConfigured` is false and no ad is ever requested —
   which also keeps an unregistered device off live inventory.

```
flutter build apk --profile --flavor prod --dart-define-from-file=env/screenshots.json
```

`env/screenshots.json` is gitignored like the other env files: every AdMob id
empty, RevenueCat carried over from dev.

The phone was put in light mode (`adb shell cmd uimode night no`). The app's
palette is light-first and a mixed set looks careless.

## Before uploading

**The framed set is 9:16 and needs no ratio check.** The raw ones are 9:19.5;
upload those only if you would rather ship plain captures, and confirm the
ratio at upload if you do.

**The Sinhala and Tamil daśā shots start mid-list.** The English one opens on
the running-period card, which is the better frame; those two were scrolled a
little too far when captured. Worth re-taking if you want the three listings
to match exactly.

**The compatibility partner is not saved.** It is session state, so the shot
was re-entered for each language. The Tamil partner has no name — the
breakdown frame does not show it, but do not swap in a top-of-screen Tamil
frame without checking.

## Recapturing

Reuse the build command above, then walk: home → chart → daśā → back →
compatibility → daily reading → calendar → settings. Switch language in
Settings between sets; the profile survives, the partner does not.
