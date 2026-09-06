<#
.SYNOPSIS
Build a signed release bundle on this machine.

.DESCRIPTION
The PowerShell twin of tool/release.sh, for running from PowerShell or cmd
without Git Bash. Does what the Release workflow does, minus the parts that
only make sense on a runner: nothing is restored from secrets, because those
files are already on disk, and nothing is uploaded.

Note that `bash` on Windows usually resolves to WSL, not Git Bash, so the .sh
version run from PowerShell would build inside Linux where Flutter and the
Android SDK are not set up. Use this script instead.

.EXAMPLE
.\tool\release.ps1
.EXAMPLE
.\tool\release.ps1 -Apk
.EXAMPLE
.\tool\release.ps1 -BuildNumber 1500000
.EXAMPLE
.\tool\release.ps1 -Clean
#>
[CmdletBinding()]
param(
    [int]$BuildNumber = 0,
    [switch]$Apk,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

function Say  { param($m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Warn { param($m) Write-Host "WARNING: $m" -ForegroundColor Yellow }
function Die  { param($m) Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }

# Native executables do not throw, so their exit codes must be checked.
function Assert-LastExit { param($what) if ($LASTEXITCODE -ne 0) { Die "$what failed (exit $LASTEXITCODE)." } }

Set-Location (Join-Path $PSScriptRoot '..')

# ------------------------------------------------------------------ preflight
#
# Each of these produces a confusing failure much later if missing, so they are
# checked here where the message can name the fix.

Say 'Checking the things a release needs'

if (-not (Test-Path 'android/key.properties')) {
    Die 'android/key.properties is missing, so the bundle would be signed with debug keys and Play would reject it. See android/key.properties.example.'
}

$storeLine = Select-String -Path 'android/key.properties' -Pattern '^storeFile=' | Select-Object -First 1
if (-not $storeLine) { Die 'key.properties has no storeFile entry.' }
$storeFile = $storeLine.Line -replace '^storeFile=', ''
if (-not (Test-Path (Join-Path 'android' $storeFile))) {
    Die "The keystore android/$storeFile named by key.properties does not exist."
}

if (-not (Test-Path 'android/app/google-services.json')) {
    Die 'android/app/google-services.json is missing. The google-services Gradle plugin hard-fails without it. Download it from Firebase Console > Project settings.'
}

if (-not (Test-Path 'env/prod.json')) {
    Die 'env/prod.json is missing. Copy env/example.json and fill it in.'
}

# Not fatal: the prod flavor falls back to Google's test app id. But a release
# built that way earns nothing, which is worth saying loudly here rather than
# discovering after upload.
if (-not (Test-Path 'android/admob.properties')) {
    Warn "android/admob.properties not found - this build will use Google's TEST AdMob app id and earn nothing. See KAN-56."
}
if (Select-String -Path 'env/prod.json' -Pattern 'ca-app-pub-3940256099942544' -Quiet) {
    Warn "env/prod.json still holds Google's TEST ad unit ids - this build will serve test ads. See KAN-56."
}

Write-Host '  key.properties, keystore, google-services.json, env/prod.json all present'

# -------------------------------------------------------------------- version
#
# versionName comes from pubspec. versionCode does NOT: Play permanently
# rejects a duplicate, and the +1 in pubspec never changes, so a hand-built
# bundle would be refused on its second upload.
#
# The default is minutes since 2024-01-01 - monotonic, needs no state file,
# unique to the minute, and far below Play's ceiling of 2100000000. The same
# formula as tool/release.sh and the Release workflow, so the three never
# produce codes that go backwards relative to each other.

$versionLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:' | Select-Object -First 1
if ($versionLine.Line -notmatch '^version:\s*([^+\s]+)') { Die 'Could not read version from pubspec.yaml.' }
$name = $Matches[1]

if ($BuildNumber -le 0) {
    $BuildNumber = [int64](([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - 1704067200) / 60)
}
if ($BuildNumber -ge 2100000000) { Die "Build number $BuildNumber is above Play's ceiling of 2100000000." }

Say "Building $name ($BuildNumber)"

# ---------------------------------------------------------------------- build

if ($Clean) {
    Say 'flutter clean'
    flutter clean
    Assert-LastExit 'flutter clean'
}

flutter pub get
Assert-LastExit 'flutter pub get'

$buildArgs = @(
    '--release',
    '--flavor', 'prod',
    '--target', 'lib/main_prod.dart',
    '--dart-define-from-file=env/prod.json',
    "--build-name=$name",
    "--build-number=$BuildNumber"
)

Say 'Building the app bundle'
flutter build appbundle @buildArgs
Assert-LastExit 'flutter build appbundle'

$aab = 'build/app/outputs/bundle/prodRelease/app-prod-release.aab'
if (-not (Test-Path $aab)) { Die "The build reported success but $aab does not exist." }

# --------------------------------------------------------------------- verify
#
# A debug-signed bundle is accepted by Gradle and rejected by Play, after the
# upload and the wait. Cheaper to catch here.

Say 'Verifying the signature'
$certText = keytool -printcert -jarfile $aab | Out-String
$owner = ($certText -split "`r?`n" | Select-String -Pattern 'Owner:' | Select-Object -First 1)
if (-not $owner) { Die 'No certificate found in the bundle - it is unsigned.' }
Write-Host "  $($owner.ToString().Trim())"
if ($owner.ToString() -match 'Android Debug') { Die 'Signed with DEBUG keys. Play will reject this.' }

$apkPath = $null
if ($Apk) {
    Say 'Building an installable APK'
    flutter build apk @buildArgs
    Assert-LastExit 'flutter build apk'
    $apkPath = 'build/app/outputs/flutter-apk/app-prod-release.apk'
    # Signed with the UPLOAD key, not Play's App Signing key. Anything that
    # validates the signing certificate - Google sign-in above all - behaves
    # differently here than in the build Play serves.
    Warn 'This APK is signed with your upload key, so it is NOT what Play serves. Google sign-in validates the signing certificate, and Play re-signs with its own key.'
}

Say 'Done'
Write-Host ("  versionName  {0}" -f $name)
Write-Host ("  versionCode  {0}" -f $BuildNumber)
Write-Host ("  bundle       {0} ({1:N1} MB)" -f $aab, ((Get-Item $aab).Length / 1MB))
if ($apkPath) { Write-Host ("  apk          {0}" -f $apkPath) }
Write-Host "`nUpload the .aab at Play Console > Test and release > Internal testing."

# Explicit: otherwise the script exits with whatever the last native command
# left in $LASTEXITCODE, which was 255 after a successful build.
exit 0
