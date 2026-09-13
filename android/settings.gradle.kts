pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

// flutter_embed_unity (Phase 3 AR Lab): the exported Unity Android library,
// linked into the app module's dependencies in app/build.gradle.kts.
//
// Unity's own export nests the real AAR-producing library module one level
// deeper than the outer project it generates (unityLibrary/unityLibrary/ —
// the one whose build.gradle actually does `apply plugin:
// 'com.android.library'` — vs. the outer unityLibrary/ wrapper, which is
// just Unity's standalone-Android-Studio-project plugin-management shell
// and has no `android {}` block of its own). Without this projectDir
// remap, Gradle defaults :unityLibrary's directory to the outer wrapper,
// which produces zero buildable variants ("No matching variant of project
// :unityLibrary was found... No variants exist"). Every fresh Unity
// Android export needs this same remap (it's a one-time settings.gradle.kts
// fix, not something re-export touches).
include(":unityLibrary")
project(":unityLibrary").projectDir = file("unityLibrary/unityLibrary")
