
## 1.9.0
### Updated
* Android SDK version updated to 5.9.0
* iOS SDK version updated to 5.9.0

### Added
* Message inbox support
 
## 1.9.1
### Added
* pushwoosh_inbox README

### Fixed
* removed duplicates from changelog
 
## 1.11.0
### Updated
* Android SDK version updated to 5.11.0
* iOS SDK version updated to 5.11.0
* startLocationTracking is async now
* compatibility with flutter v0.10.0+
 
## 1.12.0
### Fixed
* Flutter plugin updated to build with Swift libraries 

### Updated
* Android SDK version updated to 5.12.1
* iOS SDK version updated to 5.12.1
 
## 1.12.1
### Fixed
* Crash on iOS 9
 
## 1.13.0
### Fixed
* Fixed an issue with Flutter app crashes on push receiving while the app is terminated
* Sample upgraded to Android X, gradle plugin version updated to 3.2.1
 
## 1.14.0
### Fixed
* Zip Path Traversal Vulnerability

### Updated
* Android SDK version updated to 5.14.3
* iOS SDK version updated to 5.13.1
 
## 1.14.1
### Fixed
* An issue with Android app crashes on launch

### Updated
* Android SDK version updated to 5.14.4
 
## 1.17.0
### Fixed
* An issue with opPushAccepted and onPushReceived callbacks not working when Flutter apps are opened by tap on a push notification
 
## 1.17.1
### Fixed
* Flutter Android cannot receive push when app is on foreground
 
## 1.18.0
### Added
* setMultiNotificationMode function for android
 
## 1.19.0
### iOS
* Replaced UIWebView with WKWebView in iOS

### Android
* Fixed ANRs caused by push messages being processed in the main thread in Android
* Fixed incorrect inbox URL opening behaviour
* Fixed background processing that caused extra battery consumption

### Updated
* Android SDK version updated to 5.19.5
* iOS SDK version updated to 5.19.3
 
## 1.19.1
### Updated
* Android SDK version updated to 5.21.4
* iOS SDK version updated to 5.21.0
 
## 1.20.0
### Added
* Deep links support 

### Fixed
* Missing setUserId method in Android

### Updated
* Android SDK version updated to 5.22.0
* iOS SDK version updated to 5.22.0
 
## 1.20.1
### Updated
* iOS SDK updated to 5.23.0
* Android SDK updated to 5.22.2
 
## 2.0.0
### Updated
* iOS SDK updated to 6.1.1
* Android SDK updated to 6.2.3
### Fixed
* setMultiNotificationMode() crashes on iOS
* message.customData always returning null on Android
 
## 2.0.1
### Updated
* Android SDK updated to 6.2.4
 
## 2.0.2
### Changes
* Removed the method that collected the list of installed packages to comply with the newest Play Store policy
* Android SDK updated to 6.2.7
 
## 2.0.3
### Fixed
* Crashes in registration callbacks when using the plugin with 3rd-party push providers
 
## 2.1.0
### Updated
 * iOS SDK updated to 6.2.5
 * Android SDK updated to 6.3.3
 
## 2.2.0
### Changed
* Migrated Android plugins to the V2 embedding 
* Migrated to null safety

### Updated
 * iOS SDK updated to 6.3.1
 * Android SDK updated to 6.3.5
 
## 2.2.1
### Fixed
* Null safety migration
 
