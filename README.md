Pushwoosh Flutter Plugin
===================================================

[![GitHub release](https://img.shields.io/github/release/Pushwoosh/pushwoosh-flutter.svg)](https://github.com/Pushwoosh/pushwoosh-flutter/releases) 

[![Pub](https://img.shields.io/pub/v/pushwoosh.svg)](https://pub.dartlang.org/packages/pushwoosh)

![platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-yellowgreen.svg)

### Guide

https://www.pushwoosh.com/platform-docs/pushwoosh-sdk/cross-platform-frameworks/flutter


### Important 
### Migrating Pushwoosh Flutter Plugin to version 2.1.0 or higher

If you are facing errors building your Android application after updating Pushwoosh Flutter Plugin to version 2.1.0 or higher, please follow this guide
#### Build error:
```
In project 'app' a resolved Google Play services library dependency depends on another at an exact version (e.g. "[17.0.0, 18.0.99]", but isn't being resolved to that version. Behavior exhibited by the library will be unknown.
```

##### Solution:
Add this line to your **app/build.gradle** file
```
googleServices { disableVersionCheck = true }
```

#### Build error:
```
The minCompileSdk (30) specified in a dependency's AAR metadata (META-INF/com/android/build/gradle/aar-metadata.properties) is greater than this module's compileSdkVersion (android-29).
```
##### Solution:
Update **compileSdkVersion** in your **app/build.gradle** file
```
android {
    compileSdkVersion 30
    ...
```

#### Build error:
```
AAPT: error: unexpected element <queries> found in <manifest>.
```

##### Solution:
Update gradle plugin in your project. To do this, open **PROJECT_DIR/build.gradle** and update gradle plugin version to version 4 or higher:
```classpath 'com.android.tools.build:gradle:4.1.2'```

In **PROJECT_DIR/gradle/wrapper/gradle-wrapper.properties** update gradle wrapper version:
```distributionUrl=https\://services.gradle.org/distributions/gradle-6.1.1-all.zip```

#### After updating gradle plugin to version 4 or higher you may also face known build error https://issuetracker.google.com/issues/158753935?pli=1 
```
Transform's input file does not exist: /build/app/intermediates/flutter/debug/libs.jar.
```
##### Solution:
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
