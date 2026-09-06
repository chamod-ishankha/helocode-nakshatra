import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing credentials, loaded from android/key.properties.
//
// That file is git-ignored and never committed: it holds the keystore
// passwords. See android/key.properties.example for the expected shape and
// KAN-46 for how to generate the keystore.
//
// When the file is absent — a fresh clone, or CI without the secret — the
// release build falls back to debug signing rather than failing. That keeps
// `flutter build --release` working for anyone, while producing an artifact
// that Play will correctly refuse, so an unsigned build cannot be mistaken
// for a shippable one.
// AdMob application id.
//
// This cannot come from --dart-define like the ad unit ids do: it has to be a
// meta-data entry in the manifest, which Gradle assembles before any Dart
// exists. It is not a secret — it ships in every APK and is visible to anyone
// who unzips one — but the real one is kept out of the public repo alongside
// the keystore, and dev and staging deliberately use Google's public test
// application id so a debug build can never touch live inventory.
val admobPropertiesFile = rootProject.file("admob.properties")
val admobProperties = Properties().apply {
    if (admobPropertiesFile.exists()) {
        admobPropertiesFile.inputStream().use { load(it) }
    }
}

/// Google's sample application id. Serves test ads and bills nobody.
val admobTestAppId = "ca-app-pub-3940256099942544~3347511713"

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists() &&
    keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "io.helocode.nakshatra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // PERMANENT. Bound to the Play Store listing on first publish and can
        // never be changed afterwards. Flavors append a suffix to this; prod
        // deliberately appends nothing, so prod ships exactly this id.
        applicationId = "io.helocode.nakshatra"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            // Never live inventory from a debug build.
            manifestPlaceholders["admobAppId"] = admobTestAppId
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Nakshatra Dev")
        }
        create("staging") {
            dimension = "env"
            // Never live inventory from a debug build.
            manifestPlaceholders["admobAppId"] = admobTestAppId
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Nakshatra Staging")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Nakshatra")

            // Falls back to the test id rather than failing the build, so a
            // fresh clone still compiles. A release built that way serves test
            // ads and earns nothing, which is the safe direction to fail.
            val realId = admobProperties.getProperty("admobAppId")
            if (realId == null) {
                // Written to stderr, not logger.warn: `flutter build` filters
                // Gradle's log output, so a warn() here is invisible during a
                // normal release build - which is exactly when it matters.
                System.err.println(
                    "WARNING: android/admob.properties not found - the prod " +
                        "build will use Google's TEST AdMob app id and earn " +
                        "nothing. See KAN-56."
                )
            }
            manifestPlaceholders["admobAppId"] = realId ?: admobTestAppId
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = keystoreProperties.getProperty("storeFile")
                    ?.let { rootProject.file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "WARNING: android/key.properties not found — signing the " +
                        "release build with DEBUG keys. This artifact cannot " +
                        "be uploaded to Play. See KAN-46."
                )
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
