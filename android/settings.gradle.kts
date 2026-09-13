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
// Unity's raw export used to nest the real AAR-producing module one level
// deeper than the outer project (unityLibrary/unityLibrary/), which needed
// a projectDir remap here so Gradle wouldn't default to the outer wrapper
// (which has no `android {}` block and produces zero buildable variants).
// As of the 2026-09-10 Q4W8 export, the flutter_embed_unity transform now
// promotes unityLibrary/unityLibrary's contents up to be the module root
// itself, so android/unityLibrary IS the AAR-producing module — no remap
// needed. If a future export goes back to the old nested layout, restore
// the `project(":unityLibrary").projectDir = file("unityLibrary/unityLibrary")`
// line.
include(":unityLibrary")
