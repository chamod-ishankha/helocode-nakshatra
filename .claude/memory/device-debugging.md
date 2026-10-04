# Debugging on a real device

Wrong assumptions here have cost time more than once.

- **`AppLogger` output never reaches `adb logcat`.** It uses `dart:developer`'s
  `log()`, which goes to the Dart VM service — visible through `flutter logs`
  or DevTools only. To diagnose something over adb, temporarily use
  `debugPrint`, which lands in logcat as `I flutter :`. Remove it afterwards.
  Third-party SDKs *do* log to logcat: `[Purchases]`, `BillingClient`,
  `UserMessagingPlatform` and `Ads` are all readable there, and a RevenueCat
  problem is usually diagnosable without touching the app.
- **`adb shell pm clear` wipes the saved birth profile**, forcing onboarding to
  be redone by hand. To reset only ad or unlock state, delete the individual
  SharedPreferences key.
- **Restoring prefs without redoing onboarding:** `run-as` cannot read
  `/sdcard` (SELinux `runas_app` context), so pushing a file there and copying
  it in fails. Pipe it instead:

  ```
  adb shell "run-as io.helocode.nakshatra.dev sh -c 'echo <base64> | base64 -d > shared_prefs/FlutterSharedPreferences.xml'"
  ```

  Keys are prefixed `flutter.`; the profile is at `flutter.birth_profile_v1`.
- **Driving the UI:** chain it in one shell call —
  `adb shell 'sleep N; input tap X Y; ...'` — then `adb exec-out screencap -p >
  file.png`. Allow about 20 seconds after launching a debug build, and the ads
  SDK finishes a second or two later again.
- **`adb pull` truncates large files here.** Pulling a 24 MB APK stopped at
  4 MB, twice. `adb exec-out cat <path> > file` is reliable; verify with
  `adb shell stat -c%s` or a checksum before trusting what came back.
- **Git Bash mangles paths.** All adb and Gradle paths need
  `MSYS_NO_PATHCONV=1`, `$PWD` becomes `/c/...` and breaks `file://` URLs, and
  `adb pull` to a Windows path turns into `/c/Program Files/Git/...` — run that
  from PowerShell. Foreground `sleep` is blocked in Bash here; use
  `Start-Sleep`.
- **Test device ids are per device *and* per install.** They live in
  `ADMOB_TEST_DEVICE_IDS` in the gitignored env files, so they cannot be
  recovered from the repo. Re-read the id from logcat after a clean reinstall:
  `Use RequestConfiguration.Builder().setTestDeviceIds(...)`. Now that live ad
  units ship, this is what stops the owner's own taps counting as invalid
  traffic — and that ban is account-level.

## Billing cannot be tested from a dev build

The dev flavour installs as `io.helocode.nakshatra.dev`. Google Play only
returns products to the package it publishes, so a dev build shows a paywall
with **no prices and nothing buyable** — expected, not a bug. Anything touching
real purchases has to go through a Play-signed build on a track.
