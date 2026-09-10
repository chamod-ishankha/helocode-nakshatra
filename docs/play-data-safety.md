# Play Data Safety declaration

The answers to enter in **Play Console → App content → Data safety**.

This describes the build as it stands: `firebase_core`, `firebase_auth`,
`cloud_firestore`, `google_sign_in`, `google_mobile_ads`,
`firebase_crashlytics`, `firebase_analytics` and `purchases_flutter`, and
nothing else that touches the network. It is checked in so that a change to
what the app collects and a change to what we declare land in the same
commit — see [When this changes](#when-this-changes).

> **The console has not caught up with any of this.** Everything below is what
> the code does today; the form still describes the app as it was on
> 2026-09-07. Five answers have to change **before the next production
> submission**:
>
> - *App info and performance → Crash logs* — No to **Yes** (KAN-19)
> - *App info and performance → Diagnostics* — No to **Yes** (KAN-19)
> - *App activity → App interactions* — No to **Yes** (KAN-19)
> - *Financial info → Purchase history* — No to **Yes** (KAN-35)
> - *Device or other IDs* — Required to **Optional** (KAN-35)
>
> The build now in closed testing (1.0.1+2) contains **none** of this — it
> predates all of those commits — so nothing is being collected under a wrong
> declaration today. The declaration has to be fixed before the *next* build
> ships, not retrospectively.

Play Console can import these answers: **App content → Data safety → export the
CSV, fill the `Response value` column, re-import.** `tool/` has no generator for
it; the mapping is small enough to redo from the tables below.

Last verified against the release manifest on 2026-09-07, after KAN-34.
Crashlytics was added on 2026-09-09 (KAN-19) and adds no new permission —
it uses INTERNET and ACCESS_NETWORK_STATE, both already listed:

```
android.permission.INTERNET                     us
android.permission.ACCESS_NETWORK_STATE         Firebase, ads SDK
android.permission.USE_BIOMETRIC                google_sign_in
android.permission.USE_FINGERPRINT              google_sign_in
com.google.android.gms.permission.AD_ID         Google Mobile Ads SDK
android.permission.ACCESS_ADSERVICES_AD_ID      Google Mobile Ads SDK
android.permission.ACCESS_ADSERVICES_ATTRIBUTION Google Mobile Ads SDK
android.permission.ACCESS_ADSERVICES_TOPICS     Google Mobile Ads SDK
android.permission.FOREGROUND_SERVICE           Play services
android.permission.WAKE_LOCK                    Play services
com.google.android.providers.gsf.permission.READ_GSERVICES  Play services
```

Only `INTERNET` is ours. Everything else is merged in from an SDK's own library
manifest, which is why the list grows without anything in `AndroidManifest.xml`
changing — and why it has to be re-read rather than assumed.

The two biometric permissions arrive with `google_sign_in`, which depends on
Credential Manager — Android offers biometric unlock when picking a saved
credential. **The app never requests, receives or stores biometric data**, and
there is nothing to declare for them on the form.

`AD_ID` and the three `ACCESS_ADSERVICES_*` permissions arrive with the ads SDK
(KAN-34). They are why the **advertising ID declaration** under App content must
be answered **Yes**: the app targets API 36, and from API 33 a target without
that permission gets a zeroed identifier. Play blocks the release if the
declaration and the manifest disagree.

---

## 1. Data collection and security

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** — Cloud Firestore is TLS-only; the app opens no other connection |
| Do you provide a way for users to request that their data is deleted? | **Yes** |

**Deletion route to describe:** *Settings → Delete my details*. It clears
local storage and deletes the Firestore document in one action, and reports
which of the two failed if either does. This is the route the privacy policy
names, and Play does check that a stated route exists — so describe this one
and not "Start over" on the chart screen, which resets the profile without
touching the backup.

**Web deletion URL to enter:**
`https://chamod-ishankha.github.io/helocode-site/nakshatra/delete-account.html`

Play's account-deletion policy wants a route reachable without installing the
app, as well as the in-app one, and it is checked at review. The page is live.
It names the in-app route first, gives an email route for anyone who has
already uninstalled, and says plainly that an account created without signing
in cannot be matched to a person by anybody including us — which is the honest
answer and better than implying a lookup that cannot happen.

---

## 2. Data types

Four entries are collected. Everything else in the form is **No**.

### Personal info → Name

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** — it is stored |
| Required or optional | **Optional** — the app works with the field left blank |
| Purpose | **App functionality** |

### Personal info → Email address

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** |
| Required or optional | **Optional** — the app is fully usable on an anonymous account |
| Purpose | **App functionality**, **Account management** |

Only reaches us if the user chooses to sign in (KAN-48). An anonymous account
holds no address. Nothing is ever sent to it: sign-up is deliberately not
verified, so the address is a recovery handle and nothing else.

### Personal info → User IDs

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** |
| Required or optional | **Required** |
| Purpose | **App functionality**, **Account management** |

The anonymous Firebase Auth uid. It is generated by Firebase, not derived from
anything on the device, and it is what the backup is filed under.

RevenueCat holds an identifier for the same purpose. While the account is
anonymous it is one RevenueCat generated itself; once the user signs in to a
real account, KAN-64 attaches the purchase to the Firebase uid so it follows
them to a new phone. Either way it is an opaque identifier and nothing else —
no name, no address, and nothing derived from the device.

### Personal info → Other info

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** |
| Required or optional | **Required** |
| Purpose | **App functionality** |

Date of birth, time of birth and place of birth. Play has no dedicated type for
these; "Other info" is the category its own help text points at for date of
birth.

### Device or other IDs

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **Yes** |
| Processed ephemerally | **No** |
| Required or optional | **Required** |
| Collection purpose | **Advertising or marketing**, **Fraud prevention, security and compliance** |
| Sharing purpose | **Advertising or marketing**, **Fraud prevention, security and compliance** |

The Advertising ID, read by the Google Mobile Ads SDK (KAN-34). This is the one
entry that is genuinely **shared**: Google uses it for its own ad serving, which
is not the service-provider relationship Firebase has.

**Optional**, because Remove Ads has shipped (KAN-35). Buying it, or any Pro
tier, stops every placement — the gate refuses before an ad is requested, so
nothing is loaded and no identifier is read. That is what makes this optional
rather than required, and it is the honest answer now that there is a way out.

Where consent is required, *Settings → Ad privacy choices* reopens the UMP form
so the choice can be withdrawn (KAN-40).

> **Check Google's own list before submitting.** Google publishes the data
> safety answers expected of AdMob publishers, and it has changed more than
> once. Approximate location derived from IP, and app-interaction data, may
> belong here too — this file declares only the Advertising ID, which is the
> part that is certain. Confirm the rest against Google's current guidance
> rather than against this file.

### App activity → App interactions

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** |
| Required or optional | **Required** |
| Collection purpose | **Analytics** |

Screen views and the automatic session events Firebase Analytics records —
first open, session start, engagement time (KAN-19). Screen names come from the
route path, so this records *which* screens are used and never anything a user
typed into one. Birth details are not sent, and no event carries them.

**Prod only.** `FlavorConfig.enableAnalytics` is false for dev and staging and
`AnalyticsService` honours it, so a developer reinstalling a debug build does
not appear as a user. Verified on device: a dev build logs
`App measurement disabled by setAnalyticsCollectionEnabled(false)`.

> **Check Google's own list before submitting**, as with AdMob above. Google
> publishes the Data Safety answers expected for Firebase Analytics, and
> *approximate location derived from IP* is the entry that is argued about.
> This file declares App interactions, which is the part that is certain.

### App info and performance → Crash logs

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** |
| Required or optional | **Required** |
| Collection purpose | **Analytics** |

Stack traces, the exception, and the state of the app when it fell over, sent by
Firebase Crashlytics (KAN-19). Added because the app went into closed testing
with twelve people and no way to learn that it had crashed on any of them.

Required rather than optional: there is no in-app switch for it. If one is ever
added, this becomes optional.

Not shared. Google is a processor here in the same way it is for Auth — it runs
the service on our behalf and does not get the data for its own purposes. That
is the opposite of the Advertising ID entry above, which genuinely is shared.

### App info and performance → Diagnostics

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** |
| Required or optional | **Required** |
| Collection purpose | **Analytics** |

What Crashlytics attaches to a report so it can be read: device model, OS
version, free memory and disk, orientation, and how long the app had been
running. Declared separately from Crash logs because Play treats them as two
data types even though one SDK sends both.

The app adds one custom key of its own, the build flavor, so a crash from a
developer's phone can be told apart from a tester's.

### Financial info → Purchase history

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** |
| Required or optional | **Optional** — the whole app works without buying anything |
| Collection purpose | **App functionality** |

What the user has bought, and whether a subscription is still running. The
receipt is issued by Google Play and validated by RevenueCat, which is what
lets a purchase survive a reinstall and follow the user to a new phone (KAN-35).

**Not payment details.** Play Billing handles the card, and neither this app
nor RevenueCat ever sees a card number, an expiry or a billing address. That
distinction is why *Financial info → Payment info* stays **No** while this is
**Yes** — Play treats them as separate types and a reviewer will check.

Not shared. RevenueCat is a processor: it validates receipts on our behalf and
does not receive the data for its own purposes. Same relationship as Firebase,
and the opposite of the Advertising ID entry above.

---

## 3. What to answer No to, and why

Each of these is a question the form asks. The reasoning matters if a reviewer
queries it.

- **Location (approximate or precise)** — No. The app never reads device
  location and holds no location permission. Birth place is a city the user
  types on a form, and is declared above under Other info. Answering Yes here
  would put a Location badge on the listing for something the app cannot do.
- **App activity → In-app search history, Installed apps, Other
  user-generated content** — No. None are read. *App interactions* is now a
  **Yes** — see the entry above.
- **Financial info → Payment info, Credit score, Other financial info** — No.
  Play Billing processes the payment and the app never sees a card number, an
  expiry or a billing address. *Purchase history* is a **Yes** — see the entry
  above; it is a different type and the two are answered separately.
- **Contacts, Photos and videos, Messages, Calendar, Files and docs, Audio,
  Health and fitness, Web browsing** — No. None are requested or accessible.

### On "Shared"

Every entry above except the Advertising ID is **not shared**. Play's definition
excludes transfer to a service provider processing data on your behalf, which is
what Firebase is here. The Advertising ID is different: Google receives it for
its own ad serving, so it is declared as shared.

---

## When this changes

| If you add | What changes |
| --- | --- |
| **~~AdMob (KAN-34)~~** | Done — Device or other IDs is declared above, shared, for advertising. UMP consent ships with it. |
| **~~Remove Ads (KAN-35)~~** | Done — Device or other IDs is now optional, and Purchase history is declared under Financial info. |
| **~~Crashlytics (KAN-19)~~** | Done — Crash logs and Diagnostics are declared above. |
| **~~RevenueCat (KAN-35)~~** | Done — Purchase history under Financial info, and the identifier is covered under User IDs. |
| **~~A web deletion route~~** | Done — the URL is above. No Data Safety answer changes; it is entered under App content, Data deletion. |
| **~~Google / email sign-in (KAN-48)~~** | Done — Email address is declared above. |

Keep this in step with `nakshatra/privacy.html` in the `helocode-site` repo. The
two have to agree: the policy is the prose version of this table, and Play
compares them.

All three known drifts are fixed in the `helocode-site` repo and **committed
but deliberately not published** (`c674211`): the advertising choice now names
*Settings → Ad privacy choices*, the RevenueCat row says the purchase is filed
under the account once the user signs in, and the notification row lists all
five kinds.

**Publish that commit with the app release, not before.** Every one of the
three describes a build that has not shipped — the closed test is on 1.0.1+2,
which predates KAN-40, KAN-64, KAN-63 and KAN-65. A policy naming a settings
row that is not there yet is wrong in a newer and more specific way than the
text it replaces, and the store listing links to it from the day it changes.
