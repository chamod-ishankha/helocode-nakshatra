#!/usr/bin/env bash
#
# Build a signed release bundle on this machine.
#
# Does what the Release workflow does, minus the parts that only make sense on
# a runner: no secrets are restored (yours are already on disk) and nothing is
# uploaded. Run it from Git Bash:
#
#     ./tool/release.sh                 # signed AAB for Play
#     ./tool/release.sh --apk           # ...and an installable APK
#     ./tool/release.sh --build-number 12345
#     ./tool/release.sh --clean         # after changing Gradle or flavors
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

BUILD_NUMBER=""
WANT_APK=0
CLEAN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --build-number) BUILD_NUMBER="${2:?--build-number needs a value}"; shift 2 ;;
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
# versionName comes from pubspec. versionCode does NOT: Play permanently
# rejects a duplicate, and the +1 in pubspec never changes, so a hand-built
# bundle would be refused on the second upload.
#
# The default is minutes since 2024-01-01 - monotonic, needs no state file,
# unique to the minute, and small enough to stay far below Play's ceiling of
# 2100000000 for centuries.

NAME=$(grep '^version:' pubspec.yaml | sed -E 's/version:[[:space:]]*([^+]+)\+.*/\1/' | tr -d ' ')

if [ -z "$BUILD_NUMBER" ]; then
  BUILD_NUMBER=$(( ( $(date +%s) - 1704067200 ) / 60 ))
fi

[ "$BUILD_NUMBER" -gt 0 ] 2>/dev/null || die "Build number must be a positive integer, got '$BUILD_NUMBER'."
[ "$BUILD_NUMBER" -lt 2100000000 ] || die "Build number $BUILD_NUMBER is above Play's ceiling of 2100000000."

say "Building $NAME ($BUILD_NUMBER)"

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
  --build-number="$BUILD_NUMBER"
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
printf '  versionName  %s\n' "$NAME"
printf '  versionCode  %s\n' "$BUILD_NUMBER"
printf '  bundle       %s (%s)\n' "$AAB" "$(du -h "$AAB" | cut -f1)"
[ "$WANT_APK" = "1" ] && printf '  apk          %s\n' "${APK:-}"
printf '\nUpload the .aab at Play Console > Test and release > Internal testing.\n'
