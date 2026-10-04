plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.itantra.itantra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.itantra.itantra"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Vosk and ONNX Runtime ship native .so libraries per ABI; a universal
    // APK would bundle both architectures' copies even though a given phone
    // only uses one. Split into one APK per ABI by building with
    // `flutter build apk --release --split-per-abi` instead of configuring
    // `splits {}` directly here — the Flutter Gradle plugin injects its own
    // ndk.abiFilters default that conflicts with a hand-written splits
    // block. That produces armeabi-v7a/arm64-v8a/x86_64 APKs; only the
    // first two matter for real phones, x86_64 (emulators) is ignorable.
    // The bundled model assets aren't ABI-specific and stay the same size
    // in every split; this only trims the native-library portion.

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Shrink/obfuscate Dart-adjacent Java/Kotlin code and drop unused
            // resources — real size reduction on top of the release build's
            // AOT-compiled (smaller than debug JIT) Dart code. The bundled
            // ONNX/Vosk model assets dominate total size and are already
            // near-incompressible binary weights, so this mainly trims the
            // app/plugin code and resources, not the models themselves.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
