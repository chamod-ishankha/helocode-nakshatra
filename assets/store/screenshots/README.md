# Play Store screenshots

Captured from a **dev-flavour profile build with Pro unlocked** on a Galaxy
S23 (SM-S911B), 1080 × 2340, on 8 October 2026, after the redesign (KAN-80).
One folder per store listing.

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

Four things spoil a set, and all four are invisible until the shots are
already taken:

1. **A debug build paints `DEBUG` across the app bar** in every frame. These
   are `--profile`.
2. **The chart screen puts the profile name in the app bar**, so a test
   profile ships a screenshot titled "Test Account 1". The profile here is
   Sanduni Perera, 14 April 1995, Colombo, born 10:00; the partner is Kasun
   Fernando, 2 September 1993, Kandy, 6:00 AM.
3. **The home screen carries a banner ad.** Built with every `ADMOB_*` key
   blank, so `AdUnits.isConfigured` is false and no ad is ever requested —
   which also keeps an unregistered device off live inventory.
4. **Daśā and porondam are Pro.** A free install shows their locks. The dev
   flavour honours `DEV_UNLOCK_PRO` (a prod build never does), so the set is
   what a Pro reader sees. Nothing else on these screens differs between the
   flavours in a profile build.

```
flutter build apk --profile --flavor dev --target lib/main_dev.dart \
  --dart-define-from-file=env/screenshots.json --dart-define=DEV_UNLOCK_PRO=true
```

`env/screenshots.json` is gitignored like the other env files: `env/prod.json`
with every AdMob id emptied, RevenueCat carried over.

The phone was put in light mode (`adb shell cmd uimode night no`) and its
Edge panel handle hidden (`settings put secure edge_enable 0`), both restored
afterwards. Samsung ignores Android's status-bar demo mode, so the clock and
battery are real. The three settings shots were retaken after the subtitle
font fix, by which time notification icons had appeared beside the clock;
that strip of the status bar was filled with its own background colour rather
than clearing the phone's notifications. Nothing inside the app was touched.

The More tab carries a small red dot: the account is anonymous, and the dot
is the app's quiet hint that the backup lives only on the phone. Signing in
would remove it, at the cost of backing the sample profile up to a real
Google account.

## Before uploading

**The framed set is 9:16 and needs no ratio check.** The raw ones are 9:19.5;
upload those only if you would rather ship plain captures, and confirm the
ratio at upload if you do.

The calendar shot is April 2027, not the capture month: it has the New Year
and a poya, where October 2026 has a poya alone.

## Recapturing

Reuse the build command above, then walk: home → chart → positions → daśā →
daily reading → calendar → settings → compatibility. Switch language in
Settings between sets; the profile and the partner both survive.

Each tab remembers the page it was on, so after switching language the Today
tab may reopen on the daily reading and the Chart tab on the daśā. Check
every frame against its file name before framing.
