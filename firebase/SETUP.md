# Firebase setup

One-time steps that need your Google account, so they cannot be scripted here.
Everything stays on the **Spark (free)** plan.

The app runs fine without any of this — `FirebaseService.initialize()` fails
soft and `isAvailable` stays false. Sync is an enhancement, never a dependency.

## 1. Create the project

<https://console.firebase.google.com> → **Add project** → `nakshatra`

Google Analytics is optional here; it is wired separately in KAN-19.

## 2. Register the Android apps

Add **three** Android apps, one per flavor, so dev and staging traffic never
mixes with production data:

| Flavor | Package name |
| --- | --- |
| prod | `io.helocode.nakshatra` |
| dev | `io.helocode.nakshatra.dev` |
| staging | `io.helocode.nakshatra.staging` |

Download each `google-services.json`. Firebase merges all three into one file
if you register them under the same project — download it after adding all
three and place it at:

```
android/app/google-services.json
```

That path is **git-ignored** and must stay so.

## 3. Enable anonymous auth

**Authentication → Sign-in method → Anonymous → Enable**

Nothing else is needed for KAN-47. Google and Email/Password are enabled later
for KAN-48.

> Do **not** enable Phone sign-in. SMS verification is billed per message and
> would break the zero-cost constraint.

## 4. Create Firestore

**Firestore Database → Create database → Start in production mode**, region
`asia-south1` (Mumbai) — the closest to Sri Lanka, which keeps latency low.

Then **Rules**, and paste the contents of `firestore.rules` from this folder.

> The default "test mode" rules expire after 30 days and allow anyone to read
> every user's birth data until they do. Replace them before shipping.

## 5. Wire the Gradle plugin

`android/build.gradle.kts`, in `plugins`:

```kotlin
id("com.google.gms.google-services") version "4.4.2" apply false
```

`android/app/build.gradle.kts`, in `plugins`:

```kotlin
id("com.google.gms.google-services")
```

## Free-tier limits

Spark gives roughly 1 GiB of Firestore storage and 50,000 reads / 20,000 writes
per day. This app stores one small document per user and writes only when a
profile changes, so those limits are far beyond anything it will reach.

**Stay off Blaze.** Cloud Functions require it, and nothing here needs them.

## Before shipping any build with sync

The published privacy policy still says birth details never leave the device.
That is no longer true once this ships, so the policy and the Play Data Safety
form must be updated in the same release — see KAN-40. A Data Safety mismatch
can get an app pulled after launch.
