# Play Data Safety declaration

The answers to enter in **Play Console → App content → Data safety**.

This describes the build as it stands: `firebase_core`, `firebase_auth`,
`cloud_firestore`, `google_sign_in`, `google_mobile_ads`,
`firebase_crashlytics` and `firebase_analytics`, and nothing else that touches
the network. It is checked
in so that a change to what the app collects and a change to what we declare
land in the same commit. **If you add RevenueCat, this file is wrong until you
update it** — see [When this changes](#when-this-changes).

> **This changed on 2026-09-09 and the console has not caught up.** KAN-19
> added Crashlytics and Analytics, which makes three answers a Yes that are
> currently No:
>
> - *App info and performance → Crash logs*
> - *App info and performance → Diagnostics*
> - *App activity → App interactions*
>
> All three have to be set **before the next production submission**. Note that
> the build now in closed testing (1.0.1+2) contains **none** of this — it
> predates both commits — so nothing is being collected under a wrong
> declaration today. The declaration must be fixed before the *next* build
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

**Deletion route to describe:** "Start over" on the chart screen. It clears
local storage and deletes the Firestore document in one action. This is the
same route the privacy policy names, and Play does check that a stated route
exists.

> **Open obligation.** Now that KAN-48 lets a user create a real account, Play's
> account-deletion policy applies: it wants a **web** deletion route as well as
> the in-app one, reachable without installing the app. A page on the HeloCode
> site satisfies it. This is not yet built, and it is an app-content
> requirement rather than a Data Safety answer — but it is checked at review,
> so it blocks the first release that ships sign-in.

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

Required rather than optional, because a user cannot currently switch ads off.
That changes when Remove Ads ships (KAN-35) and should be revisited then.

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
- **Financial info** — No. Play Billing is not integrated yet, and when it is,
  Google processes payment details without the app seeing them.
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
| **Remove Ads (KAN-35)** | Device or other IDs becomes **optional** rather than required, since a purchaser can switch ads off. Purchase history appears under Financial info. |
| **~~Crashlytics (KAN-19)~~** | Done — Crash logs and Diagnostics are declared above. |
| **RevenueCat** | Purchase history under Financial info, and a purchase identifier under User IDs. |
| **~~Google / email sign-in (KAN-48)~~** | Done — Email address is declared above. |

Keep this in step with `nakshatra/privacy.html` in the `helocode-site` repo. The
two have to agree: the policy is the prose version of this table, and Play
compares them.
