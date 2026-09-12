# Nakshatra — the money plan

How the app earns, placement by placement and product by product, as it
actually stands in the code today. Written to be argued with: the last section
is where the plan looks weakest.

Console procedure lives in [play-monetisation.md](play-monetisation.md); this
file is the plan, not the steps.

---

## What the app is

**Nakshatra** is a Sinhala, Tamil and English almanac and astrology app for
Sri Lanka — `io.helocode.nakshatra`, by HeloCode Labs.

It answers the questions a Sri Lankan household actually asks a printed *litha*
for. What is today's **rāhu kālaya**, and the other inauspicious periods. What
tithi, nakṣatra, yoga and karana are running, and until when. When is the next
poya. What does my **kēndaraya** look like, where are the grahas, which
**daśā** am I in, and how do two charts match on the ten **porondam**.

Three things make it what it is:

- **It computes, it does not look things up.** Positions come from the Swiss
  Ephemeris on the device, sidereal, Lahiri ayanamsa, whole-sign houses. There
  is no server with a table of answers.
- **It works with no network.** Every chart, every pañcāṅga, every birth place.
  A phone in aeroplane mode does everything except buy and sync.
- **It is written in the reader's language.** Not a translated English app —
  Sinhala and Tamil are first-class, down to the bundled Noto fonts, because
  Roboto draws Sinhala as empty boxes on a lot of Sri Lankan phones.

The audience is Sri Lanka first, the Tamil diaspora second, and everyone else
by accident. That single fact decides the whole plan below: **most users will
never pay, and the plan has to earn from them anyway.**

---

## The shape of it

Three ways in, deliberately layered:

```
free, always ──────► the daily almanac, the rāśi chart, the running daśā,
                     the porondam score, every past day

watch an ad ───────► the same locked things, for the rest of today
                     (resets at the user's own local midnight)

pay ───────────────► no ads at all, plus what ads cannot give:
                     several profiles, the PDF report
```

The middle row is the one that matters here and the one most apps skip. In this
market the majority of installs will never pay anything, and a plan that only
monetises buyers earns nothing from them. It is also the reason the "watch an
ad" button is never hidden behind the paid one — a user who will never pay is
still worth money, every day, if the path is in front of them.

---

## Ads — every placement

Four AdMob formats, four different jobs. Policy lives in `AdGate`; each
placement only runs it.

### 1. Banner — the daily screen, and nowhere else

| | |
|---|---|
| Screen | **Home** (the daily almanac) — `home_screen.dart:128` |
| Position | Bottom of the page, below the almanac content |
| Widget | `BannerAdSlot`, adaptive to the device width |
| Frequency | Always on, one per screen view |
| Hidden for | Anyone holding `removeAds` (Remove Ads **or** Pro) |

This is the only banner in the app. Chart, daśā, compatibility, horoscope and
settings carry none.

It sits on Home because Home is the screen people open daily and briefly — the
habit screen. A banner there is seen constantly and interrupts nothing. It
loads only after the SDK is ready, and renders nothing at all rather than
holding an empty gap if the fill never comes.

### 2. Interstitial — leaving a horoscope reading

| | |
|---|---|
| Screen | **Horoscope** — fires on exit, `horoscope_screen.dart:92` |
| Trigger | The user **scrolled to the end** of the reading *and* a reading was actually shown |
| Lands on | The screen they navigate *to*, not the one they leave |
| Preloaded | On screen entry, while they read |

The two conditions are the whole design. A full-screen ad after someone read a
complete reading is payment for something delivered; the same ad after someone
opened the screen and bounced is a toll on a door. `_readToEnd` allows eight
logical pixels of slack, because a fling settles just short of the bottom often
enough that an exact comparison never fires.

### 3. Rewarded interstitial — opening the chart

| | |
|---|---|
| Screen | **Chart**, once per launch on open — `chart_screen.dart:85` |
| Pays out | **navāṁśa (D9) chart** *and* the **third daśā level**, together |
| Confirmed by | A snackbar naming what was unlocked |
| Skipped for | Purchasers, and anyone who already holds both today |

The hybrid: full-screen and uninvited like an interstitial, but it pays. Held
to the *same* cooldown and the *same* stored timestamp as the plain
interstitial — two full-screen ads a minute apart are two interruptions however
the second is labelled.

The snackbar is not decoration. An unexplained full-screen ad is an
interruption; an ad that visibly unlocked two things on the screen behind it is
a trade.

### 4. Rewarded — the four things a user can unlock on purpose

User-initiated, from a blurred lock with two buttons: **buy Pro** or **watch an
ad**. Never rate-limited — the user asked for it.

| Unlock | Screen | What stays free |
|---|---|---|
| `compatibilityDetail` | **Compatibility** | The porondam **score** itself |
| `futureDay` | **Home** and **Horoscope** | Today and every **past** day |
| `navamsaChart` | **Chart** (D9 tab) | The **rāśi** chart |
| `dashaDetail` | **Daśā timeline** (3rd level) | Mahā and antara periods |

Every row is chosen so the free side is a whole feature, not a teaser. Locking
the porondam number would make the screen worthless rather than tempting;
locking the rāśi chart would lock the thing people installed the app for.

**All four reset at the user's own local midnight**, not UTC — the user's
midnight is the one they experience.

### The rules that cap all of it

| Rule | Value | Why |
|---|---|---|
| Session grace | **90 seconds** | No full-screen ad in the first minute and a half of a launch |
| Interstitial cooldown | **3 minutes** | Shared between interstitial and rewarded interstitial |
| Rewarded cooldown | none | The user asked for it |
| Any ad, for a purchaser | never loaded | Not hidden — never requested |

---

## The paywall

### Prices

Set in Play Console, never in the app. The app displays only what the store
returns, in the buyer's own currency — a hardcoded "LKR 750" shown to someone
whose account is charged USD is a price we quoted and did not honour.

**One-time**

| Product | Sri Lanka | Elsewhere | Grants |
|---|---|---|---|
| `birth_chart_pdf` | **LKR 1,500** | **USD 6.99** | The printable PDF report |
| `remove_ads` | **LKR 750** | **USD 2.99** | No ads, anywhere, forever |

**Subscriptions** — both grant the same Pro entitlement; they differ only in
billing period.

| Product | Sri Lanka | Elsewhere | Period |
|---|---|---|---|
| `pro_monthly` | **LKR 550** | **USD 2.99** | Monthly, auto-renewing |
| `pro_yearly` | **LKR 5,500** | **USD 29.99** | Yearly, auto-renewing |

Yearly is ten months' money for twelve months of Pro — a **17% saving in LKR**,
**16% in USD**. Consistent across both currencies, which is right.

`compatibility_report` exists in the product table but is **not sellable**:
nothing in the app gates on what it grants, so buying it would take money and
change nothing.

### What Pro actually opens

| Feature | Pro | Remove Ads | PDF | Rewarded ad |
|---|:--:|:--:|:--:|:--:|
| No ads, anywhere | ✅ | ✅ | — | — |
| navāṁśa (D9) chart | ✅ | — | — | ✅ daily |
| Full daśā timeline | ✅ | — | — | ✅ daily |
| Full porondam working | ✅ | — | — | ✅ daily |
| Future days | ✅ | — | — | ✅ daily |
| Charts for the whole family | ✅ | — | — | — |
| Printable PDF report | — | — | ✅ | — |

Note the last two rows carefully. **Multiple profiles is the only feature Pro
has that an ad cannot reach**, and **the PDF is not included in Pro at all**.

### Remote Config

Three keys, and they can only ever be *more* generous — `paywall_variant`,
`paywall_free_features`, `paywall_highlight_tier`. A stale or fat-fingered
value can give something away; it can never lock a user out of something the
app promised, and it can never touch a purchase. Anything a one-time product
exists to sell is off limits to it.

Variants are **keys, not copy** — Remote Config delivers a string in one
language, and shipping English to a Sinhala reader is not an experiment, it is
a regression. The copy stays in the ARB files.

### Measurement

`paywall_impression`, `paywall_tier_tapped`, `purchase_started`,
`purchase_purchased` / `purchase_<outcome>`, `paywall_dismissed`. Product id
and outcome only — never the price. The store's own reporting is authoritative
on revenue, and a second number here could disagree with the money.

---

## Where this plan is weak

The five things worth arguing about before the next price change.

### 1. Outside Sri Lanka, Remove Ads undercuts Pro monthly at the same price

`remove_ads` is **USD 2.99 once**. `pro_monthly` is **USD 2.99 every month**.

For any international user whose actual motive is "stop the ads" — and for most
users that is the motive — the one-time product strictly dominates. Same first
payment, never charged again. Pro has to win on multiple profiles alone, which
is a thin reason to pay twelve times as much a year.

In LKR the ladder is fine: 750 once versus 550 a month reads as a real choice.
It is only the USD column where the two collided. Widening that gap — Remove
Ads up, or monthly down — is the highest-leverage single change on this page.

### 2. Two of the four Play subscription benefits are free every day

The benefits entered against both subscriptions are: no ads, the navāṁśa chart,
the full daśā timeline, charts for the whole family.

The middle two are obtainable by **any** user, **every day**, for one rewarded
interstitial on the chart screen. A patient user gets both free forever.

That is a deliberate trade — it is how non-payers earn their keep — but it
means the store page is advertising as paid benefits two things the app hands
out daily. What Pro *uniquely* has is no-ads and multiple profiles. Either the
benefit copy should lead on those, or the daily reset on the chart unlocks
should get less generous.

### 3. The regional discount is not consistent across the ladder

At roughly 300 LKR to the dollar, what a Sri Lankan pays as a share of the
international price:

| Product | Share |
|---|---|
| `pro_monthly` | ~61% |
| `pro_yearly` | ~61% |
| `birth_chart_pdf` | ~72% |
| `remove_ads` | ~84% |

Subscriptions are discounted deeply and consistently; one-time products barely
are. Nothing forces these to match, but right now the difference looks like
drift rather than a decision. Pick a target share and apply it.

### 4. The PDF costs more than two months of Pro and is not in Pro

`birth_chart_pdf` at LKR 1,500 is nearly **three times** Remove Ads and
**2.7 times** a month of Pro — and a yearly subscriber who has paid LKR 5,500
still has to pay it. That will read as mean to the people who spent the most.

It may still be right — the ticket calls it the highest-margin single product
and it is genuinely a different thing — but "Pro does not include the report"
should be a sentence somewhere a buyer sees, not a surprise at the paywall.

### 5. One banner, on one screen

Home is the only screen with a banner. Chart, daśā, compatibility and horoscope
have none, and those are the screens people linger on.

This is restraint, not oversight, and restraint is defensible — but it is also
the largest untouched inventory in the app. If ad revenue needs to grow without
touching the paid ladder, a banner below the fold on the compatibility result
is the first candidate. **Not** beside the chart grid or the daśā rows: AdMob's
accidental-click rules bite hardest next to content a user taps on, and that
ban is account-level.

---

## Not to break

- **Prices never enter the code.** The paywall shows a loading state until the
  store answers, and shows nothing rather than a number it cannot honour.
- **A purchaser never requests an ad.** Not hidden after loading — never asked
  for.
- **Entitlements fail generous.** Wrongly withholding Pro from a paying
  customer on a bad connection costs a refund and a one-star review; wrongly
  extending it to a lapsed subscriber costs nothing and self-corrects.
- **The rewarded path stays visible beside the paid one**, on every lock.
