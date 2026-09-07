#!/usr/bin/env bash
#
# Build a signed release bundle on this machine.
#
# Does what the Release workflow does, minus the parts that only make sense on
# a runner: no secrets are restored (yours are already on disk) and nothing is
# uploaded. Run it from Git Bash:
#
# From PowerShell or cmd use tool/release.ps1 instead - `bash` on Windows
# usually resolves to WSL, not Git Bash, which would build inside Linux where
# Flutter and the Android SDK are not set up.
#
#     ./tool/release.sh                 # signed AAB for Play
#     ./tool/release.sh --apk           # ...and an installable APK
#     ./tool/release.sh --set-version 1.1.0   # start a new minor at +1
#     ./tool/release.sh --no-bump             # rebuild what pubspec says
#     ./tool/release.sh --clean         # after changing Gradle or flavors
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

SET_VERSION=""
NO_BUMP=0
WANT_APK=0
CLEAN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --set-version)  SET_VERSION="${2:?--set-version needs a value}"; shift 2 ;;
    --no-bump)      NO_BUMP=1; shift ;;
    --apk)          WANT_APK=1; shift ;;
    --clean)        CLEAN=1; shift ;;
    -h|--help)      awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "$0"; exit 0 ;;
    *)              echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33mWARNING: %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- preflight
#
# Every one of these produces a confusing failure much later if it is missing,
# so they are checked up front where the message can name the fix.

say "Checking the things a release needs"

[ -f android/key.properties ] \
  || die "android/key.properties is missing, so the bundle would be signed with debug keys and Play would reject it. See android/key.properties.example."

STORE_FILE=$(grep '^storeFile=' android/key.properties | cut -d= -f2-)
[ -f "android/$STORE_FILE" ] \
  || die "The keystore android/$STORE_FILE named by key.properties does not exist."

[ -f android/app/google-services.json ] \
  || die "android/app/google-services.json is missing. The google-services Gradle plugin hard-fails without it. Download it from Firebase Console > Project settings."

[ -f env/prod.json ] \
  || die "env/prod.json is missing. Copy env/example.json and fill it in."

# Not fatal: the prod flavor falls back to Google's test app id. But a release
# built that way earns nothing, and that is worth saying loudly here rather
# than discovering it after upload.
[ -f android/admob.properties ] \
  || warn "android/admob.properties not found - this build will use Google's TEST AdMob app id and earn nothing. See KAN-56."

if grep -q 'ca-app-pub-3940256099942544' env/prod.json; then
  warn "env/prod.json still holds Google's TEST ad unit ids - this build will serve test ads. See KAN-56."
fi

echo "  key.properties, keystore, google-services.json, env/prod.json all present"

# ------------------------------------------------------------------ version
#
# The version lives in pubspec.yaml and this script advances it, so the number
# on a bundle is never invented at build time and never depends on the clock.
#
# The build number runs 1..9 and then rolls into the patch: 1.0.1+9 is
# followed by 1.0.2+1.
#
# ## Why versionCode is not simply the build number
#
# Play requires a strictly increasing integer and permanently refuses anything
# it has already seen. Earlier builds went out with codes derived from the
# clock - the last was 1410854 - so a bundle offering versionCode 1 would be
# rejected outright.
#
# The code is therefore derived from the whole version:
#
#   major * 10000000 + minor * 100000 + patch * 1000 + build
#
# 1.0.1+1 becomes 10001001, which clears the old codes with room to spare,
# rises in step with the version, and stays far below Play's ceiling of
# 2100000000 until major version 99.

version_code() { # major minor patch build
  echo $(( $1 * 10000000 + $2 * 100000 + $3 * 1000 + $4 ))
}

CURRENT=$(grep '^version:' pubspec.yaml | sed -E 's/^version:[[:space:]]*//' | tr -d ' \r')
if ! echo "$CURRENT" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$'; then
  die "pubspec version '$CURRENT' is not major.minor.patch+build."
fi

MAJOR=$(echo "$CURRENT" | cut -d. -f1)
MINOR=$(echo "$CURRENT" | cut -d. -f2)
PATCH=$(echo "$CURRENT" | cut -d. -f3 | cut -d+ -f1)
BUILD=$(echo "$CURRENT" | cut -d+ -f2)

if [ -n "$SET_VERSION" ]; then
  if ! echo "$SET_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    die "--set-version wants major.minor.patch, got '$SET_VERSION'."
  fi
  MAJOR=$(echo "$SET_VERSION" | cut -d. -f1)
  MINOR=$(echo "$SET_VERSION" | cut -d. -f2)
  PATCH=$(echo "$SET_VERSION" | cut -d. -f3)
  BUILD=1
elif [ "$NO_BUMP" = "1" ]; then
  : # rebuild whatever pubspec already says
else
  BUILD=$(( BUILD + 1 ))
  if [ "$BUILD" -gt 9 ]; then
    PATCH=$(( PATCH + 1 ))
    BUILD=1
  fi
fi

NAME="$MAJOR.$MINOR.$PATCH"
NEW_VERSION="$NAME+$BUILD"
CODE=$(version_code "$MAJOR" "$MINOR" "$PATCH" "$BUILD")

[ "$CODE" -lt 2100000000 ] || die "versionCode $CODE is above Play's ceiling."

# Written back before the build, so the file and the bundle always agree even
# if the build then fails.
if [ "$NEW_VERSION" != "$CURRENT" ]; then
  sed -i -E "s/^version:.*/version: $NEW_VERSION/" pubspec.yaml
  echo "  pubspec $CURRENT -> $NEW_VERSION"
fi

say "Building $NEW_VERSION (versionCode $CODE)"

# -------------------------------------------------------------------- build

if [ "$CLEAN" = "1" ]; then
  say "flutter clean"
  flutter clean
fi

flutter pub get

BUILD_ARGS=(
  --release
  --flavor prod
  --target lib/main_prod.dart
  --dart-define-from-file=env/prod.json
  --build-name="$NAME"
  --build-number="$CODE"
)

say "Building the app bundle"
flutter build appbundle "${BUILD_ARGS[@]}"

AAB="build/app/outputs/bundle/prodRelease/app-prod-release.aab"
[ -f "$AAB" ] || die "The build reported success but $AAB does not exist."

# ------------------------------------------------------------------- verify
#
# A bundle signed with debug keys is accepted by Gradle and rejected by Play,
# after the upload and the wait. Cheaper to catch here.

say "Verifying the signature"
OWNER=$(keytool -printcert -jarfile "$AAB" 2>/dev/null | grep -m1 "Owner:" || true)
echo "  ${OWNER:-<no certificate found>}"

case "$OWNER" in
  *"Android Debug"*) die "Signed with DEBUG keys. Play will reject this." ;;
  "")                die "No certificate found in the bundle - it is unsigned." ;;
esac

if [ "$WANT_APK" = "1" ]; then
  say "Building an installable APK"
  flutter build apk "${BUILD_ARGS[@]}"
  APK="build/app/outputs/flutter-apk/app-prod-release.apk"
  # Signed with the UPLOAD key, not Play's App Signing key. Anything that
  # depends on the signing certificate - Google sign-in above all - behaves
  # differently here than in the build Play serves. Use Play's internal app
  # sharing to test that path.
  warn "This APK is signed with your upload key, so it is NOT byte-identical to what Play serves. Google sign-in in particular validates the signing certificate, and Play re-signs with its own key."
fi

say "Done"
printf '  version      %s\n' "$NEW_VERSION"
printf '  versionCode  %s\n' "$CODE"
printf '  bundle       %s (%s)\n' "$AAB" "$(du -h "$AAB" | cut -f1)"
[ "$WANT_APK" = "1" ] && printf '  apk          %s\n' "${APK:-}"
printf '\nUpload the .aab at Play Console > Test and release > Internal testing.\n'
