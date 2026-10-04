# How the app earns

The full plan, placement by placement and price by price, is
**`docs/monetisation-plan.md`** — read that before changing anything here. This
file is the short version plus the rules that must not be broken.

## Three ways in

```
free, always ──────► the daily almanac, the rāśi chart, the running daśā,
                     the porondam score, every past day
watch an ad ───────► the same locked things, for the rest of today
pay ───────────────► no ads at all, several profiles, the PDF report
```

The middle row is the one most apps skip and the one that matters most here.
Most installs in this market will never pay, and a plan that only monetises
buyers earns nothing from them. **The rewarded path is never hidden behind the
paid one.**

## Ads

| Format | Where | Trigger |
|---|---|---|
| Banner | Home, and the compatibility result | always / only once a match exists |
| Interstitial | leaving a horoscope | only if it was read to the end |
| Rewarded interstitial | opening the chart | pays out navāṁśa **and** the third daśā level |
| Rewarded | the four locks | the user asks for it |

Capped by a 90-second session grace and a 3-minute cooldown shared between both
full-screen formats. Rewarded unlocks reset at the user's **local** midnight.

**The placement rule, enforced by `test/core/ads/banner_placement_test.dart`:** a
banner is the last thing on its page, after the "for entertainment purposes
only" line, with nothing tappable between. Never beside the chart grid or the
daśā rows — AdMob's accidental-click ban is account-level and is not appealed
in practice.

## Purchases

Four products sell: `remove_ads`, `birth_chart_pdf`, `pro_monthly`,
`pro_yearly`. `compatibility_report` exists in the table but is **not
sellable**, because nothing gates on what it grants.

**Prices live in Play Console and in `docs/monetisation-plan.md`, never in
code** — not even in a comment, which went stale twice. The store returns a
formatted price in the buyer's own currency; the paywall shows a loading state
until it does, and shows nothing rather than a number it cannot honour.

Two rules the ladder has to keep:

- **Remove Ads must never cost the same as, or less than, one month of Pro, in
  any currency.** It did once, in USD, and the one-time product strictly
  dominated the subscription.
- **Pro does not include the PDF report.** Deliberate, and it surprises buyers;
  KAN-73 proposes a member price rather than folding it in.

## The trap that cost a release

Google Play has **no subscription without a base plan**, and RevenueCat
identifies one as `productId:basePlanId`. Matching a returned product on the
bare id therefore works for one-time products and silently drops every
subscription. That is exactly what happened: the paywall showed two one-time
products at real prices and no Pro at all, with the key, the store and billing
all healthy. `PurchaseProduct.byStoreId` splits on the first `:`. KAN-68.

## Honesty rules, all of them tested

- The yearly "save X%" badge is computed from the store's real prices, never
  written into copy.
- A free trial is claimed **only** when the store reports a zero price. A
  discounted first period is not a trial.
- Pro nudges: one a day at most, never in the first session, 14 days' quiet
  after being dismissed or tapped, never for a subscriber, no countdowns. The
  ad-count nudge quotes the device's real count and no price.
- The Pro value meter counts only while Pro is active, resets on the 1st, and
  hides a line rather than showing a zero.
- Remote Config can only ever be **more** generous. It can give something away;
  it can never add a gate or touch a purchase.

## What Pro uniquely has

No ads, and several saved charts. The navāṁśa, the full daśā, the compatibility
breakdown and future days are **all obtainable free, every day, by watching an
ad** — including two of the four benefits Play advertises for the subscription.
That is the deliberate trade with a low-ARPU market, and it is the open
question in KAN-70. Analytics are shipped; the decision waits for the numbers.
