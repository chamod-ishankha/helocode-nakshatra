# Selling in Play Console (KAN-35)

What changes in Play Console now that the app has in-app purchases, in
dependency order. Each step is blocked by the one above it, which is why the
order matters more than the list.

Checked in beside [play-data-safety.md](play-data-safety.md) and
[play-listing.md](play-listing.md) so console work and code stay in one place.

---

## 1. The payments profile — this is "the agreement"

**Play Console → Setup → Payments profile.**

Selling anything requires a Google payments merchant profile linked to the
developer account. Creating it is where the payments terms are accepted, and
where tax information and a bank account go. It is a separate agreement from
the Developer Distribution Agreement, which does **not** need re-accepting
just because the app gained purchases.

Until this profile exists the Monetise section is read-only: no product can be
created, priced or activated.

> **Confirm Sri Lanka is a supported merchant country first.** Google publishes
> the list of countries where a developer can register as a merchant, and it is
> shorter than the list of countries where apps can be *sold*. Check it before
> planning around this step — if registration is not available, everything
> below is blocked and the answer is a different payment route, not a retry.

Tax categories are set per product later, not here.

---

## 2. Upload a build that contains Play Billing

**This is the blocker behind the "no one-time products" message.**

Play Console reads the permissions of the **uploaded** artifact, not the
source. `com.android.vending.BILLING` is added automatically by the Play
Billing library, which arrives with `purchases_flutter` — but the build now on
the closed track predates it:

| | |
|---|---|
| `1.0.1+2` uploaded | 9 September 2026 (`f8377ea`) |
| RevenueCat added | 10 September 2026 (`a1ea129`) |

So the console is right and the code is fine. Upload a newer build and the
message clears. `tool/release.ps1` computes the versionCode; the uploaded one
is `10001002`, so the next must exceed it.

Verify before uploading:

```
aapt2 dump xmltree <apk> --file AndroidManifest.xml | grep BILLING
```

---

## 3. Create the products

**Monetise → Products → In-app products** and **→ Subscriptions.**

The ids are typed by hand and **cannot be renamed once created**. They must
match `lib/core/purchases/products.dart` exactly — a mismatch is not a compile
error, it is a paywall row that silently never appears.

### One-time products

| Product ID | Grants | Intended price |
|---|---|---|
| `remove_ads` | no ads, anywhere | LKR 750 |
| `birth_chart_pdf` | the PDF report | LKR 1,500 |

### Subscriptions

| Product ID | Base plan | Grants | Intended price |
|---|---|---|---|
| `pro_monthly` | monthly, auto-renewing | Pro | LKR 490 |
| `pro_yearly` | yearly, auto-renewing | Pro | LKR 3,900 |

Prices are set in Play, never in the app — the app only ever displays what the
store returns, in the user's own currency. See the comment at the top of
`products.dart` for why.

### Product icons

Each product needs one: **32-bit PNG, 1:1, 512–1080 px a side, no text, no
branding.** They are in `assets/store/products/`, named for the product id, and
rebuilt with:

```
python tool/build_product_icons.py
```

They are drawn rather than photographed so each one is accurate to what is
being sold: an ad banner struck through, a sheet carrying the chart grid, and
an open padlock for Pro — badged with a crescent for the monthly term and a sun
for the yearly one, since Play requires the two to differ and in an almanac a
month is one cycle of the moon and a year is one of the sun.

No app logo. The eight-pointed star would be branding, which the rule forbids;
the palette is the app's, which it does not.

### `compatibility_report`

Declared in code as **not sellable**: nothing in the app gates on what it
grants, so buying it would take money and change nothing. Either leave it out
of Play entirely, or create it and leave it **inactive**. Do not activate it
until the compatibility report screen exists — `products_test.dart` fails if
that flag and the feature ever disagree.

---

## 4. Give RevenueCat access to Play

The step most easily forgotten, and purchases validate unreliably without it.

1. **Play Console → Setup → API access** — link a Google Cloud project and
   create a service account.
2. Grant it the **View financial data** and **Manage orders and subscriptions**
   permissions on this app.
3. Download the service account JSON and upload it to the RevenueCat dashboard
   under the Play app's configuration.

RevenueCat validates receipts server-side against Play. Without the credential
it cannot confirm a purchase, and entitlements arrive late or not at all.

**The JSON is a real secret** — unlike the ad unit ids, it does not ship in the
APK and must never be committed. It belongs where the keystore lives.

---

## 5. Put the production SDK key in `env/prod.json`

`REVENUECAT_PUBLIC_SDK_KEY` is **empty in prod today**. Dev holds a sandbox
`test_` key, and `RevenueCatGateway.configure` deliberately refuses a `test_`
key in a prod build — the SDK crashes on one in production.

So a production build with no key sells nothing, quietly. Take the Play-backed
key (it starts `goog_`) from the RevenueCat dashboard.

---

## 6. Re-answer the content rating questionnaire

**App content → Content rating.**

It asks whether the app lets users buy digital goods. That was **No** and is
now **Yes**. A changed answer means re-submitting the questionnaire; Play
issues a new rating certificate. The full set of answers is in
[play-listing.md](play-listing.md#content-rating-questionnaire-iarc).

Expected outcome is unchanged: **Everyone / PEGI 3**.

---

## 7. Update Data Safety

**App content → Data safety.** Five answers change; two of them are because of
purchases. The list and the reasoning are at the top of
[play-data-safety.md](play-data-safety.md).

---

## Already satisfied — do not rebuild these

**A way to cancel.** Play requires an app selling subscriptions to point at
where they can be managed. *Settings → Manage subscription* opens Google's own
subscription centre, and it only appears while a subscription is running
(`pro_tiles.dart`). Deliberately not deep-linked to a product: the generic page
works whichever tier is held, and a link built from the wrong sku lands on an
error.

**Restore purchases.** *Settings → Restore purchases*, and purchases follow the
signed-in account since KAN-64.

**A price the app can honour.** No price is ever written into the app; the
paywall shows a loading state until the store answers, and shows nothing rather
than a number it cannot honour.

---

## Order of play

```
payments profile  ──►  upload a build with BILLING  ──►  create products
                                                              │
                            RevenueCat API access  ◄───────────┤
                            prod SDK key in env    ◄───────────┘
                                     │
                     content rating + data safety  ──►  submit
```

Content rating and Data Safety can be done at any point, but both must be
correct before the next production submission.
