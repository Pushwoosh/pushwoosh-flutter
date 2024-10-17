
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
 
## 2.2.2
### Updated
* Version of Pushwoosh iOS SDK to 6.3.2
* Version of Pushwoosh Android SDK to 6.4.0
 
## 2.2.3
### Fixed
* java.lang.NullPointerException while executing doInBackground()

### Updated
* Pushwoosh Android SDK to 6.4.1
* Pushwoosh iOS SDK to 6.3.3
 
## 2.2.4
### Updated

* Pushwoosh Android SDK version to 6.4.4
* Pushwoosh iOS SDK to 6.3.5
 
## 2.2.5
### Added
* API to communicate with Pushwoosh Inbox endpoints directly
### Updated
* Pushwoosh Android SDK to 6.5.2
* Pushwoosh iOS SDK to 6.4.2
 
## 2.2.6
###Added
* customData parameter to `InboxMessage` class
###Fixed
* iOS build issue in pushwoosh_inbox module
 
## 2.2.7
### Updated
* Pushwoosh Android SDK to 6.6.1
* Pushwoosh iOS SDK to 6.4.3
 
## 2.2.8
### Added
* `setApplicationIconBadgeNumber()`, `addToApplicationIconBadgeNumber()`, 
`getApplicationIconBadgeNumber()` methods
### Updated
* Pushwoosh iOS SDK to 6.4.5
* Pushwoosh Android SDK to 6.6.1
 
## 2.2.9
### Fixed

* Android compile issue introduced with the 2.2.8 release
 
## 2.2.10
### Changed
* `sendDate` parameter of `InboxMessage` now returns ISO8601-formatted string on both platforms
 
## 2.2.11
### Added
* Huawei platform support
* `setLanguage()` method for iOS and Android

### Updated
* Pushwoosh Android SDK to 6.6.5
* Pushwoosh iOS SDK to 6.4.8
 
## 2.1.12
### Changed
* Pushwoosh Android SDK updated to 6.6.7
* Pushwoosh iOS SDK updated to 6.4.8
 
## 2.1.13
###Changed
* Pushwoosh Android SDK version updated to 6.6.9
* Pushwoosh iOS SDK version updated to 6.4.10
 
## 2.2.12
## Changed
* Pushwoosh Android SDK updated to 6.6.9
* Pushwoosh iOS SDK updated to 6.4.10
 
## 2.2.13
### Changed

* Pushwoosh Android SDK version updated to 6.6.10
* Pushwoosh iOS SDK version updated to 6.4.12
 
## 2.2.14
### Changed
* the plugin now uses xcframework via Cocoapods instead of embedded static library

### Added
* iOS provisional pushes are supported now. To enable it, call `requestProvisionalAuthOptions()` method before calling `registerForPushNotifications()`. 

### Fixed
* `Undefined symbols for architecture arm64: "_OBJC_CLASS_"` crash when `use_frameworks!` is specified in Podfile.
 
## 2.2.14
### Changed
* the plugin now uses xcframework via Cocoapods instead of embedded static library

### Added
* iOS provisional pushes are supported now. To enable it, call `requestProvisionalAuthOptions()` method before calling `registerForPushNotifications()`. 

### Fixed
* `Undefined symbols for architecture arm64: "_OBJC_CLASS_"` crash when `use_frameworks!` is specified in Podfile.
 
## 2.2.14
### Changed
* the plugin now uses xcframework via Cocoapods instead of embedded static library

### Added
* iOS provisional pushes are supported now. To enable it, call `requestProvisionalAuthOptions()` method before calling `registerForPushNotifications()`. 

### Fixed
* `Undefined symbols for architecture arm64: "_OBJC_CLASS_"` crash when `use_frameworks!` is specified in Podfile.
 
## 2.2.14
### Changed
* the plugin now uses xcframework via Cocoapods instead of embedded static library

### Added
* iOS provisional pushes are supported now. To enable it, call `requestProvisionalAuthOptions()` method before calling `registerForPushNotifications()`. 

### Fixed
* `Undefined symbols for architecture arm64: "_OBJC_CLASS_"` crash when `use_frameworks!` is specified in Podfile.
 
## 2.2.15
### Fixed
* PushwooshInbox.loadMessages() not working on Android: Unhandled Exception: type 'String' is not a subtype of type 'Map<String, dynamic>?' #68

### Added
* Android 14 support

### Updated
* Pushwoosh Android SDK 6.6.16
* Pushwoosh iOS SDK updated to 6.5.1
 
## 2.2.16
### Changed

* Pushwoosh plugin's notification center delegate now calls implementations of delegate methods of 3rd-party push services.
 
## 2.2.17
### Updated

* Pushwoosh Android SDK 6.7.0
 
## 2.2.18
### Fixed

* Issue with duplicate notifications on iOS when the app is in the foreground.
 
## 2.2.19
### Fixed

* resolved the issue related to retrieving silent push notification.
 
## 2.2.20
### Added 

* `startLiveActivityWithToken`, `stopLiveActivity` methods added

### Fixed

* crash on iOS in setDelegate method

### Updated

* Pushwoosh iOS SDK 6.5.8
 
## 2.2.21
### Updated

* Pushwoosh iOS SDK 6.5.9
* Pushwoosh Android SDK 6.7.5
 
## 2.2.22
### Updated
* Pushwoosh Android SDK to 6.7.7
* Pushwoosh iOS SDK to 6.5.11

### Added
* All `Result.success()` calls are now wrapped in try-catch blocks
 
## 2.2.23
### Updated
* Pushwoosh Android SDK to 6.7.8
 
## 2.2.24
### Updated
* Pushwoosh Android SDK updated to 6.7.10
* Pushwoosh iOS SDK updated to 6.5.13

 
## 2.2.25
### Fixed

* No visible @interface for 'Pushwoosh' declares the selector `startLiveActivityWithToken:completion:`
 
## 2.2.26
### Updated
* Pushwoosh Android SDK updated to 6.7.12
 
## 2.2.26
### Updated
* Pushwoosh Android SDK updated to 6.7.12

## 2.2.27
### Fixed
* Resolved an issue on iOS 18 where push notifications were received twice.

## 2.2.28
### Fixed
* Fixed the push notification appearance animation, which was displaying incorrectly due to a bug with duplicate notifications.

### 2.2.29
### Improved
* Improved compatibility of the ```void setShowForegroundAlert(bool value)``` method with other push providers.
