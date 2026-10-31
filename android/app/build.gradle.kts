plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fileorganizer.file_organizer"
    compileSdk = 35
    ndkVersion = "26.1.10909125"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fileorganizer.file_organizer"
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

    signingConfigs {
        create("release") {
            keyAlias = "fileorganizer"
            keyPassword = "fileorganizer"
            storeFile = file("release.jks")
            storePassword = "fileorganizer"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    packaging {
        jniLibs {
            excludes += listOf("**/desktop.ini", "**/Thumbs.db", "**/*.ini")
        }
        resources {
            excludes += listOf("**/desktop.ini", "**/Thumbs.db", "**/*.ini")
        }
    }
}

tasks.matching { it.name.contains("strip", ignoreCase = true) }.configureEach {
    doFirst {
        fileTree(project.layout.buildDirectory).matching {
            include("**/desktop.ini")
            include("**/Thumbs.db")
        }.forEach { it.delete() }
    }
}

flutter {
    source = "../.."
}

tasks.withType<Copy> {
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}
