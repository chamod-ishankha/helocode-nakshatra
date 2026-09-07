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
.\tool\release.ps1 -SetVersion 1.1.0
.EXAMPLE
.\tool\release.ps1 -Clean
#>
[CmdletBinding()]
param(
    [string]$SetVersion = '',
    [switch]$NoBump,
    [switch]$Apk,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

function Say  { param($m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Warn { param($m) Write-Host "WARNING: $m" -ForegroundColor Yellow }
function Die  { param($m) Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }

# Native executables do not throw, so their exit codes are checked explicitly.
#
# They are also run with ErrorActionPreference relaxed. With it set to Stop,
# PowerShell 5.1 turns any line a native command writes to stderr into a
# terminating error as soon as the script's output is piped or redirected, so
# piping this script died on Gradle's harmless "no admob.properties" warning
# half way through a release build. The exit code says whether a build failed;
# stderr does not.
function Invoke-Native {
    param([string]$What, [scriptblock]$Command)

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Command } finally { $ErrorActionPreference = $previous }

    if ($LASTEXITCODE -ne 0) { Die "$What failed (exit $LASTEXITCODE)." }
}

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
# The version lives in pubspec.yaml and this script advances it, so the number
# on a bundle is never invented at build time and never depends on the clock.
#
# The build number runs 1..9 and then rolls into the patch: 1.0.1+9 is
# followed by 1.0.2+1.
#
# Play requires a strictly increasing integer for versionCode and permanently
# refuses anything it has already seen. Earlier builds went out with codes
# derived from the clock - the last was 1410854 - so a bundle offering
# versionCode 1 would be rejected outright. The code is therefore derived from
# the whole version:
#
#   major * 10000000 + minor * 100000 + patch * 1000 + build
#
# 1.0.1+1 becomes 10001001, which clears the old codes, rises in step with the
# version, and stays far below Play's ceiling of 2100000000 until major 99.

$pubspecPath = Join-Path (Get-Location) 'pubspec.yaml'
$pubspec = [IO.File]::ReadAllText($pubspecPath)

if ($pubspec -notmatch '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$') {
    Die 'pubspec version is not major.minor.patch+build.'
}
$major = [int]$Matches[1]
$minor = [int]$Matches[2]
$patch = [int]$Matches[3]
$build = [int]$Matches[4]
$current = "$major.$minor.$patch+$build"

if ($SetVersion) {
    if ($SetVersion -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
        Die "-SetVersion wants major.minor.patch, got '$SetVersion'."
    }
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $build = 1
}
elseif (-not $NoBump) {
    $build++
    if ($build -gt 9) {
        $patch++
        $build = 1
    }
}

$name = "$major.$minor.$patch"
$newVersion = "$name+$build"
$code = $major * 10000000 + $minor * 100000 + $patch * 1000 + $build

if ($code -ge 2100000000) { Die "versionCode $code is above Play's ceiling." }

# Written back before the build, so the file and the bundle always agree even
# if the build then fails.
if ($newVersion -ne $current) {
    $updated = [Regex]::Replace(
        $pubspec, '(?m)^version:.*$', "version: $newVersion")
    [IO.File]::WriteAllText(
        $pubspecPath, $updated, (New-Object Text.UTF8Encoding $false))
    Write-Host "  pubspec $current -> $newVersion"
}

Say "Building $newVersion (versionCode $code)"

# ---------------------------------------------------------------------- build

if ($Clean) {
    Say 'flutter clean'
    Invoke-Native 'flutter clean' { flutter clean }
}

Invoke-Native 'flutter pub get' { flutter pub get }

$buildArgs = @(
    '--release',
    '--flavor', 'prod',
    '--target', 'lib/main_prod.dart',
    '--dart-define-from-file=env/prod.json',
    "--build-name=$name",
    "--build-number=$code"
)

Say 'Building the app bundle'
Invoke-Native 'flutter build appbundle' { flutter build appbundle @buildArgs }

$aab = 'build/app/outputs/bundle/prodRelease/app-prod-release.aab'
if (-not (Test-Path $aab)) { Die "The build reported success but $aab does not exist." }

# --------------------------------------------------------------------- verify
#
# A debug-signed bundle is accepted by Gradle and rejected by Play, after the
# upload and the wait. Cheaper to catch here.

Say 'Verifying the signature'
$previousPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$certText = keytool -printcert -jarfile $aab | Out-String
$ErrorActionPreference = $previousPreference
$owner = ($certText -split "`r?`n" | Select-String -Pattern 'Owner:' | Select-Object -First 1)
if (-not $owner) { Die 'No certificate found in the bundle - it is unsigned.' }
Write-Host "  $($owner.ToString().Trim())"
if ($owner.ToString() -match 'Android Debug') { Die 'Signed with DEBUG keys. Play will reject this.' }

$apkPath = $null
if ($Apk) {
    Say 'Building an installable APK'
    Invoke-Native 'flutter build apk' { flutter build apk @buildArgs }
    $apkPath = 'build/app/outputs/flutter-apk/app-prod-release.apk'
    # Signed with the UPLOAD key, not Play's App Signing key. Anything that
    # validates the signing certificate - Google sign-in above all - behaves
    # differently here than in the build Play serves.
    Warn 'This APK is signed with your upload key, so it is NOT what Play serves. Google sign-in validates the signing certificate, and Play re-signs with its own key.'
}

Say 'Done'
Write-Host ("  version      {0}" -f $newVersion)
Write-Host ("  versionCode  {0}" -f $code)
Write-Host ("  bundle       {0} ({1:N1} MB)" -f $aab, ((Get-Item $aab).Length / 1MB))
if ($apkPath) { Write-Host ("  apk          {0}" -f $apkPath) }
Write-Host "`nUpload the .aab at Play Console > Test and release > Internal testing."

# Explicit: otherwise the script exits with whatever the last native command
# left in $LASTEXITCODE, which was 255 after a successful build.
exit 0
