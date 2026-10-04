# The astronomical engine

`lib/core/astro/`. Built and verified on hardware. These decisions are settled
— do not re-litigate them without a reason from the sky rather than the code.

- **Moshier ephemeris** (`SEFLG_MOSEPH`), not bundled `.se1` files. It is
  compiled into the native library, so nothing ships beside the APK. Accurate
  to about 1 arc-second over 1800–2400, against a 1 arc-minute gate — sixty
  times looser than needed. Only move to `SEFLG_SWIEPH` if a check against a
  printed litha actually fails.
- **Lahiri ayanamsa** and **whole-sign houses** (`Hsys.W`). Tropical would put
  users in the wrong rāśi, Placidus in the wrong houses. Both are the Sri
  Lankan and Indian convention.
- **Birth time goes through the IANA timezone database**, never a fixed offset.
  Sri Lanka left +05:30 between 1996 and 2006, so a hardcoded offset makes
  charts from that decade up to an hour wrong — about 15° of ascendant, half a
  rāśi. A test pins it.
- **Ketu is Rahu + 180°**, and Rahu is the **mean** node, per Vedic practice.

## A wrong timezone is the worst bug this app can have

It is not cosmetic. Hours out moves the lagna by whole signs, and every daśā
date and porondam verdict downstream is then confidently wrong with nothing on
screen to say so.

That is why `Place.timezone` is **required with no default**. It used to
default to `Asia/Colombo`, which was correct while every place was Sri Lankan
and catastrophic the moment one was not. Removing the default is what found all
seventeen call sites. A place whose zone cannot be resolved is dropped from the
data rather than guessed, and a test asserts every zone in the bundle resolves
in the tz database — an unknown one would throw on the chart screen, after
onboarding had already succeeded.

## Testing is split by necessity, not preference

`sweph` is an FFI plugin. Its native library exists only in a real Android
build and cannot load under `flutter test` (`Failed to load dynamic library`).

- Pure arithmetic → `test/`, runs in CI.
- Anything touching the ephemeris → `integration_test/`, needs a device:
  `flutter test integration_test/... -d <device> --flavor dev`.

Verified on **armeabi-v7a** as well as arm64 — 32-bit ARM was the likeliest
failure point and it works.

## The licence, settled

**AGPL-3.0-or-later.** The free Swiss Ephemeris edition was chosen, so the app
inherits it and the repository is public to satisfy the obligation.

The obligation is triggered by **distribution, not by where the source is
hosted**. Keeping it local does not avoid it, because shipping on Play conveys
the binary to users. Free + closed source + published on Play cannot all hold
with Swiss Ephemeris; the alternatives were an MIT engine, paying Astrodienst,
or not publishing.

**The AGPL does not stop the app earning money.** Ads and every paid tier are
fine. The only obligation is source availability. Do not repeat the common
misreading that AGPL means free of charge.

The terms of service had to be rewritten, because they forbade reverse
engineering and redistribution, which the AGPL grants. What remains covers
brand and ad-account identifiers, with an explicit "the AGPL wins" clause.

**Attribution is a licence condition, not a courtesy.** Swiss Ephemeris (AGPL)
and GeoNames place data (CC BY 4.0) must both reach users, which is why
Settings has a Licences screen — `Licensing.attributions` had existed from the
start and was displayed nowhere, so neither notice reached anybody.
