# Firebase: free tier only

A standing instruction from the owner: *"i want only to use free services in
the firebase also."* The app runs on the **Spark plan** — anonymous, email and
Google auth, Firestore, and nothing that needs Blaze.

**Check this before proposing anything server-side.** When a design seems to
need a trusted server, the answer here is usually a Firestore security rule,
not a function.

## What it rules out

**Cloud Functions, and therefore the Firebase Admin SDK.** Anything needing
privileged server-side access has nowhere to live. That has already decided
three things:

- **Admin rights cannot use custom claims**, because setting one needs the
  Admin SDK. They are an `admins/{uid}` document checked in security rules
  instead. A client-side `isAdmin` flag would be decoration — anyone can pull
  the config out of the bundle and call Firestore directly.
- **Account deletion cannot be completed from the client.** Firebase refuses
  `user.delete()` when the sign-in is old, and for a returning user it always
  is. An anonymous account has no credential to re-authenticate with at all. So
  the app deletes the Firestore data — which is what the privacy policy
  promises — and abandons the stale auth record. Empty records accumulate;
  clearing them (KAN-54) needs the Admin SDK and is therefore blocked.
- **Receipt validation cannot be done in-house**, which is why RevenueCat is
  load-bearing rather than a convenience.

Also avoid **phone-number auth**: SMS is billed per message.

## Remote Config now needs Blaze too

In this console, as of September 2026. The app is built so it does not matter:
`RemoteConfigService` has a compiled-in default for every value, `initialize()`
swallows every failure, and it is not awaited before the first frame. Leaving
it disabled is the recommendation — it only buys paywall A/B tests, which are
worth nothing before there is traffic.

## The real cost of moving to Blaze

Not the service that prompts it. **On Spark, Firestore stops at the free
limit; on Blaze it keeps serving and bills.** Budget alerts only notify — there
is no hard spending cap. For a solo developer that asymmetry is the whole
argument.
