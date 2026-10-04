# Nakshatra

A Sinhala, Tamil and English almanac and astrology app for Sri Lanka —
`io.helocode.nakshatra`, published by HeloCode Labs. Built and maintained by
one person. **Live on Google Play since October 2026.**

It answers what a Sri Lankan household asks a printed *litha* for: today's
**rāhu kālaya** and the other inauspicious periods, the pañcāṅga running now,
the next poya, a **kēndaraya** with its **daśā**, and **porondam** matching
between two charts.

## Three things that decide everything else

- **It computes, it does not look up.** Swiss Ephemeris on the device,
  sidereal, Lahiri, whole-sign. There is no server holding answers.
- **It works with no network.** Every chart, every pañcāṅga, every birth place.
  That promise is in the store listing and the privacy policy, and it is why
  place data is bundled rather than fetched.
- **It is written in the reader's language.** Not a translated English app:
  Sinhala and Tamil are first-class, down to the bundled Noto fonts, because
  Roboto draws Sinhala as empty boxes on many Sri Lankan phones.

Audience is Sri Lanka first, the Tamil diaspora second, everyone else by
accident. That single fact decides the money model — see
[monetisation.md](monetisation.md).

## The name

*Nakshatra* is a bridge word: Sinhala *nekath* comes from Sanskrit
*nakṣatra*, Tamil has *natchathiram*, Hindi keeps *nakshatra*. One listing
reads as native in Colombo, Chennai and Delhi. The applicationId is permanent
and can never change after publication.

## Stack

Flutter (Android only — iOS is explicitly not planned), Riverpod 3, go_router,
Drift/SQLite, `sweph`, `google_mobile_ads`, `purchases_flutter` (RevenueCat),
Firebase on the free tier only ([firebase-spark.md](firebase-spark.md)),
`flutter_localizations` with ARB files.

**Riverpod 3 catches:** `StateProvider` is gone — use a `Notifier`. A provider
is paused when all its listeners are, so a `Provider` holding a `ref.listen`
that is only ever `read` never fires.

## Conventions

- **Commits** use the GitHub noreply identity for this account. Never the
  owner's employer address — personal HeloCode projects stay separate from it.
- **The repository is public**, at `chamod-ishankha/helocode-nakshatra`, and had
  to be: the free Swiss Ephemeris edition makes the app AGPL-3.0, and
  publishing on Play triggers the source obligation. This was resisted at first
  — astrology apps are heavily cloned — but the licence decided it. See
  [astro-engine.md](astro-engine.md).
- **Nothing secret in the repo.** `env/*.json`, `android/key.properties`,
  `android/admob.properties`, `android/app/google-services.json` and the
  keystores are all gitignored. Check before writing a key, an id or an address
  anywhere, including into these memory files.
- Work runs **ticket by ticket** from the owner's own Jira board — see
  [jira-workflow.md](jira-workflow.md).

## Where the written-down thinking lives

`docs/` is not an afterthought in this repo:

| File | Holds |
|---|---|
| `docs/monetisation-plan.md` | Every ad placement and price, and where the plan is weak |
| `docs/play-listing.md` | Listing copy in three languages, declarations, content rating |
| `docs/play-monetisation.md` | Console procedure for selling, in dependency order |
| `docs/play-data-safety.md` | What the app collects and what to declare |
| `docs/release-notes/` | One file per version, in Play's tagged format |
| `assets/data/places/README.md` | The bundled worldwide place data and its licence |

## What it took to get here

Roughly 14 weeks from decision to production, solo. The parts that cost the
most were not the astronomy: three scripts rendering correctly on cheap phones,
Play Console's declarations, and the purchase ladder.
