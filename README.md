Pushwoosh Flutter Plugin
===================================================

[![GitHub release](https://img.shields.io/github/release/Pushwoosh/pushwoosh-flutter.svg)](https://github.com/Pushwoosh/pushwoosh-flutter/releases)
[![Pub](https://img.shields.io/pub/v/pushwoosh_flutter.svg)](https://pub.dartlang.org/packages/pushwoosh_flutter)

![platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-yellowgreen.svg)

| [Guide](https://docs.pushwoosh.com/platform-docs/pushwoosh-sdk/cross-platform-frameworks/flutter) | [Pub.dev package](https://pub.dev/packages/pushwoosh_flutter) | [Documentation](docs/README.md) | [Sample](https://github.com/Pushwoosh/pushwoosh-flutter-sample) |
| --- | --- | --- | --- |

## Installation

1\. Install the library from pub:

```yaml
dependencies:
  pushwoosh_flutter: '^2.3.11'
```

2\. Configure Firebase Android project in [Firebase console](https://console.firebase.google.com).

3\. Place a `google-services.json` file into android/app folder in your project directory.

## Usage

```dart
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';
...
Pushwoosh.initialize({"app_id": "YOUR_APP_ID", "sender_id": "FCM_SENDER_ID"});
Pushwoosh.getInstance.onPushReceived.listen((event) {
...
});
Pushwoosh.getInstance.onPushAccepted.listen((event) {
...
});
Pushwoosh.getInstance.registerForPushNotifications();
```

&nbsp;

## Important

### Migrating from 'pushwoosh' package 2.2.13 or lower to 'pushwoosh_flutter' [2.2.14](https://github.com/Pushwoosh/pushwoosh-flutter/releases/tag/2.2.14) or higher

Since version 2.2.14, the package name has changed from 'pushwoosh' to 'pushwoosh_flutter'. Make sure to update your `pubspec.yaml` and change import lines to

`import 'package:pushwoosh_flutter/pushwoosh_flutter.dart'`

&nbsp;

### Migrating Pushwoosh Flutter Plugin to version 2.1.0 or higher

If you are facing errors building your Android application after updating  Pushwoosh Flutter Plugin to version 2.1.0 or higher, please follow the guide below for troubleshooting

#### Build error #1

```
In project 'app' a resolved Google Play services library dependency depends on another at an exact version (e.g. "[17.0.0, 18.0.99]", but isn't being resolved to that version. Behavior exhibited by the library will be unknown.
```

**Solution**

Add this line to your **app/build.gradle** file

```
googleServices { disableVersionCheck = true }
```

#### Build error #2

```
The minCompileSdk (30) specified in a dependency's AAR metadata (META-INF/com/android/build/gradle/aar-metadata.properties) is greater than this module's compileSdkVersion (android-29).
```

**Solution**

Update **compileSdkVersion** in your **app/build.gradle** file

```
android {
    compileSdkVersion 30
    ...
```

#### Build error #3

```
AAPT: error: unexpected element <queries> found in <manifest>.
```

**Solution**

Update gradle plugin in your project. To do this, open **PROJECT_DIR/build.gradle** and update gradle plugin version to version 4 or higher: `classpath 'com.android.tools.build:gradle:4.1.2'`

In **PROJECT_DIR/gradle/wrapper/gradle-wrapper.properties** update gradle wrapper version: `distributionUrl=https\://services.gradle.org/distributions/gradle-6.1.1-all.zip`

#### Build error #4 #

After updating gradle plugin to version 4 or higher you may also face known build error https://issuetracker.google.com/issues/158753935?pli=1

```
Transform's input file does not exist: /build/app/intermediates/flutter/debug/libs.jar.
```

**Solution**

Change this in your **app/build.gradle** file

```
    lintOptions {
        disable 'InvalidPackage'
    }
```

to this:

```
    lintOptions {
        checkReleaseBuilds false
    }
```
