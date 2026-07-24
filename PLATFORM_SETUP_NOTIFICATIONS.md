# Notification platform setup (to-do reminders)

The uploaded project contained `lib/` + `pubspec.yaml` only, so the platform
folders could not be edited here. Apply the following to your real project
**once**, alongside the new `core/notifications/` code. Without these, local
notifications will either not fire from the background or not survive a
reboot on Android.

## Android — `android/app/src/main/AndroidManifest.xml`

Inside `<manifest>` (above `<application>`):

```xml
<!-- Android 13+ runtime notification permission (requested in-app on
     first use of a reminder, but must be declared). -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<!-- Fire at the exact remind_at minute on Android 12+. If the user
     revokes exact-alarm access in system settings, the app degrades to
     inexact scheduling automatically (see LocalReminderService). -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<!-- Re-register pending notifications after a reboot. -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

Inside `<application>`:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

## Android — `android/app/build.gradle.kts`

Your project uses the Kotlin DSL, not Groovy — here's the exact diff
against the file you pasted. Three changes: desugaring turned on inside
the existing `compileOptions` block, `minSdk` pinned to 21 (flutter_local_
notifications 17.x's floor — leaving `flutter.minSdkVersion` as-is is fine
only if your Flutter version already defaults to ≥21, which most current
versions do, but pinning explicitly removes the doubt), and one new
top-level `dependencies` block for the desugaring library (Kotlin DSL
uses `add(...)`, not the Groovy string-invocation form).

```kotlin
android {
    namespace = "com.tailored.business.tailored"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true   // ← added
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.tailored.business.tailored"
        minSdk = 21                              // ← was flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {                                   // ← new block, top-level
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

Everything else in your file (the `plugins {}` block, `namespace`,
`ndkVersion`, `kotlinOptions`, `buildTypes`) is untouched.

## iOS

Nothing to add for basic delivery: permission is requested at runtime (the
plugin is initialized with all `request*Permission: false`, and
`ensurePermissions()` asks only when the user first sets a reminder). No
Info.plist keys are required for local notifications.

## Verification checklist (on-device, not simulator for the exact timing)

1. `flutter pub get` resolves the three new packages against your Flutter
   version. These pins were chosen for the Dart **3.3** floor from
   documentation, not from a local resolution run — if `pub get` reports a
   conflict, say so and the pins get revisited before anything else.
2. Create a to-do due in ~5 minutes with a "0 minutes before" reminder →
   the OS permission prompt appears **then** (not at app launch) → kill
   the app → notification fires on time → tapping it opens the task.
3. Log out → any pending reminder notifications disappear (reconciler
   calls `cancelAll`).
4. Reboot the phone with a pending reminder → it still fires (boot
   receiver).
5. Android 12+: revoke "Alarms & reminders" in system settings → editing
   the to-do still succeeds and the reminder arrives, just not to-the-
   minute (inexact fallback).
