# Signing, versions and the gitignored files

## Three keys exist, not two

The debug key, the **upload key** (`android/upload-keystore.jks`), and **Play's
own App Signing key**, which is what actually signs anything installed from
Play.

Google Sign-In matches package name plus signing SHA-1 server-side, so the
**Play App Signing fingerprint must be registered in Firebase** or Google
sign-in fails on Play builds only. Adding a fingerprint takes effect within
minutes — no rebuild, no new release.

On Android, Credential Manager reports a rejected signing certificate as a
**cancellation, not an error**. A broken config looks exactly like the user
backing out. See the `describeGoogle` streak logic and its tests.

## Gitignored, because the repo is public

`android/app/google-services.json`, `android/key.properties`,
`android/admob.properties`, `env/*.json`, the keystores.

`google-services.json` is mirrored into the GitHub secret
`GOOGLE_SERVICES_JSON_BASE64`, which both workflows decode. **Regenerating it
means updating that secret**, or CI silently keeps building with the old one:

```
base64 -w0 android/app/google-services.json
```

The release workflow rebuilds `key.properties` from secrets and deletes it
afterwards.

## Versions

**The version lives in `pubspec.yaml`.** `tool/release.ps1` advances it: build
number 1..9, then it rolls into the patch, so `1.0.1+9` is followed by
`1.0.2+1`.

**Commit the bump.** The script writes it and does not commit, and a clone
without it rebuilds a version Play has already seen. That has nearly bitten
once — a build went out as +5 while pubspec still said +4.

**versionCode is derived, not the build number.** Play refuses a code it has
seen, and early builds used clock-derived codes up to 1410854, so a raw `+1`
would be rejected. The formula, repeated in both scripts and the workflow:

```
major*10000000 + minor*100000 + patch*1000 + build     1.0.1+6 → 10001006
```

## On Windows, run `tool/release.ps1`

`bash` there resolves to **WSL**, not Git Bash, so `release.sh` from PowerShell
would build inside Linux where Flutter is not set up.

The script prints "upload at Internal testing" when it finishes. That line is
hardcoded; the track to use is whichever one is being released.

## The AD_ID declaration must be Yes

The ads SDK merges `com.google.android.gms.permission.AD_ID` into the manifest,
and from API 33 a target without it gets a zeroed identifier. Play blocks
releases where the declaration and the manifest disagree. Its purposes must
match the Data Safety form's Device-or-other-IDs purposes exactly: advertising,
and fraud prevention.

## Verify a bundle before uploading

Worth the two minutes — it has caught a build with no RevenueCat key, and
another with Google's test AdMob id instead of the live one. Unzip the `.aab`
and check, in `base/manifest/AndroidManifest.xml` and
`base/lib/*/libapp.so`: the versionCode, `com.android.vending.BILLING`, the
live AdMob app id, the absence of Google's test id, and the `goog_` key in
**every** ABI.
