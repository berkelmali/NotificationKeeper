// Standalone QA app - not part of the Flutter build. Build it with the main
// project's Gradle wrapper:  ../../android/gradlew assembleDebug
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        // Same versions as android/settings.gradle.kts, so the build works from
        // the Gradle cache the main app has already populated.
        id("com.android.application") version "8.11.1"
        id("org.jetbrains.kotlin.android") version "2.1.0"
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "notification_simulator"
include(":app")
