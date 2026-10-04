# Where the app stands on Google Play

**Live in production since October 2026.** Updated 2026-10-04; check the
console before trusting any date below.

## How it got there

| | |
|---|---|
| Closed testing opened | 7 September 2026, 12 testers |
| 14-day clock | Google requires 12 testers opted in **continuously** for 14 days before a personal developer account can apply for production. Only **closed** testing counts; internal does not. A new build does **not** reset it — the clock counts testers staying opted in. |
| Production applied for | after the closed test completed, and approved |
| First production submission | **rejected** — see below |
| Live | October 2026 |

## The rejection worth remembering

The first production submission was refused under **Families Policy: Neutral
Age Screen**. Nothing in the app was wrong. Play applies the Families Policy to
any app whose **target audience includes under-13**, even alongside adults, and
that policy bans ad SDKs not approved for children unless there is a neutral
age screen. One child age band ticked in **App content → Target audience** was
enough, with AdMob in the app.

The fix was the declaration — 18 and over only — and the same bundle was
resubmitted with no code change. The full account, including why the onboarding
birth-date step is *not* an age screen (it opens pre-filled, which Play names
explicitly as not neutral), is in `docs/play-listing.md` under "Target
audience: the Families Policy trap". Tracked as KAN-79.

## Version arithmetic

`1.0.1+6`, versionCode **10001006**, is the production build. versionCode is
derived, never the build number — see [release-signing.md](release-signing.md)
for the formula and for why the bump must be committed.

## Live configuration

- **AdMob**: live app id and all four unit ids, in `env/prod.json` and
  `android/admob.properties`. Dev and staging use Google's test ids.
- **RevenueCat**: the Play-backed `goog_` key is in `env/prod.json`. A `test_`
  key is the Test Store and the SDK crashes on one in production — the gateway
  refuses it outright rather than shipping it.
- **Four products are on sale.** Prices in
  `docs/monetisation-plan.md`; never in code.

## Still open

- **KAN-70** — rewarded-ad analytics are shipped; the decision on whether to
  tighten the daily reset waits on the data.
- **KAN-72** — a free trial. Needs a decision on length and which plan.
- **KAN-73** — a Pro member price for the PDF report, via a second SKU.
- **KAN-78** — **19 draft Sinhala and Tamil strings** are live in the app,
  written by a model and not yet reviewed by a native writer. They were shipped
  so no English leaked onto a Sinhala or Tamil screen. They are drafts.
- **KAN-41** — the Sri Lankan device matrix was never run. Production is the
  first time the app meets phones nobody tested on; watch Crashlytics.
- **KAN-49 / KAN-54** — admin panel, on hold; KAN-54 is blocked outright by
  [firebase-spark.md](firebase-spark.md).

## Things that were true and are not

Kept because a stale memory is worse than none, and these were believed for
weeks after they stopped being true:

- *"Purchases are built but inert."* They work. The SDK key is live and four
  products sell.
- *"Only an en-US listing exists."* All three listings are live.
- *"1.0.1+2 is on the closed track."* Long superseded.
