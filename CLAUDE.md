# Nakshatra

A Sinhala, Tamil and English almanac and astrology app for Sri Lanka —
`io.helocode.nakshatra`, by HeloCode Labs. Flutter, Android only, built by one
person, **live on Google Play**.

## Read first

`.claude/memory/` holds what this repository cannot tell you itself: decisions
already settled, standing instructions from the owner, and traps that have
already cost a day. Start at **[.claude/memory/README.md](.claude/memory/README.md)**
and open what the task touches.

The ones worth knowing before touching anything:

- **[project.md](.claude/memory/project.md)** — what the app is and the three
  constraints that decide everything else.
- **[testing.md](.claude/memory/testing.md)** — test calculations and logic
  thoroughly; skip widget tests for things the owner can see on screen. This is
  an explicit instruction, not a style.
- **[firebase-spark.md](.claude/memory/firebase-spark.md)** — free tier only.
  No Cloud Functions, no Admin SDK. Check before proposing anything
  server-side.

## Non-negotiables

- **The repository is public.** No keys, tokens, device identifiers or personal
  addresses in it — including in docs and memory files. Secrets live in
  gitignored `env/*.json`, `android/key.properties`,
  `android/admob.properties` and `android/app/google-services.json`.
- **Prices never go in code.** The store returns them; the paywall shows a
  loading state until it does.
- **A wrong timezone is worse than a missing feature.** It moves the lagna by
  whole signs and nothing on screen says so.
- **Ads never sit beside a tappable control.** The AdMob ban for accidental
  clicks is account-level.
- **The app makes no predictive, medical, legal or financial claims.** Every
  screen carries "for entertainment purposes only", and Play's
  misrepresentation policy covers fortune-telling.

## Working here

- Work runs **ticket by ticket** from Jira project `KAN`; the board is
  forward-only. See [jira-workflow.md](.claude/memory/jira-workflow.md).
- **Comments carry the reasoning**, not a restatement of the code. Match the
  surrounding density — this codebase explains *why*, including what was
  rejected.
- **Prove a test can fail** by breaking the code on purpose, one change at a
  time.
- `flutter analyze` stays clean, and the suite is kept green.

## Commands

```bash
flutter test                       # ~795 tests, about 30 seconds
flutter analyze
flutter gen-l10n                   # after editing lib/l10n/*.arb
flutter run --flavor dev --target lib/main_dev.dart --dart-define-from-file=env/dev.json
```

```powershell
powershell -File tool/release.ps1  # bumps the build number, builds the AAB, verifies signing
```

Release builds are PowerShell-only on Windows: `bash` there resolves to WSL,
where Flutter is not installed.

## Layout

```
lib/core/astro/        ephemeris, pañcāṅga, daśā, compatibility
lib/core/ads/          ad gate, placements, rewarded unlocks
lib/core/purchases/    products, entitlements, paywall config, nudges
lib/features/          one folder per screen: data / domain / presentation
assets/data/places/    bundled worldwide birth places (generated)
docs/                  the plan, the listing, the console procedure
tool/                  generators and the release scripts
```
