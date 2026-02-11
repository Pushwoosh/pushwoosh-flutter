---
name: pushwoosh-flutter-live-activities
description: Guide for integrating iOS Live Activities (Dynamic Island + Lock Screen) into Flutter apps using Pushwoosh SDK. Covers Widget Extension setup, ActivityAttributes, Flutter-to-Swift bridging, Pushwoosh API methods, and remote push updates.
---

# Pushwoosh Flutter SDK — iOS Live Activities Integration

This skill provides complete guidance for implementing iOS Live Activities (Dynamic Island + Lock Screen) in a Flutter project that uses the Pushwoosh Flutter SDK (`pushwoosh_flutter`).

## Prerequisites

- iOS 16.1+ deployment target
- Pushwoosh Flutter SDK v2.3.1+
- Xcode 14.1+
- `PushwooshXCFramework/PushwooshLiveActivities` pod (included by default since v2.3.16)

---

## Architecture Overview

```
Flutter (Dart)                    iOS (Swift)                   System
─────────────                    ───────────                   ──────
DynamicIslandManager  ──────►  LiveActivityManager  ──────►  ActivityKit
  (MethodChannel "PW")            (start/update/stop)         (Dynamic Island)

Pushwoosh Dart API    ──────►  PushwooshPlugin.m    ──────►  Pushwoosh SDK
  (defaultSetup/Start)            (MethodChannel              (Token registration
   startWithToken)                 "pushwoosh")                + Remote updates)
```

**Two approaches:**
1. **Custom Live Activity** — full control, custom UI via Widget Extension + MethodChannel bridge
2. **Default Pushwoosh Live Activity** — simpler, uses `defaultSetup()` / `defaultStart()`, managed by Pushwoosh

---

## Approach 1: Custom Live Activity (Full Control)

### Step 1: Enable Live Activities in Info.plist

In the **Runner** iOS app's `Info.plist`:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### Step 2: Create Widget Extension Target

1. In Xcode: **File → New → Target → Widget Extension**
2. Name it (e.g., `MyAppWidgetExtension`)
3. Set deployment target to **iOS 16.1**
4. Uncheck "Include Configuration App Intent" (not needed for Live Activities)

### Step 3: Define ActivityAttributes (Swift)

Create a shared Swift file accessible to both the main app and widget extension. Add to **both targets**.

```swift
import ActivityKit
import Foundation

struct MyActivityAttributes: ActivityAttributes {
    // Static data (set once at activity start, cannot be updated)
    var title: String

    // Dynamic data (updated via updateLiveActivity)
    public struct ContentState: Codable, Hashable {
        var value: Int
        var statusMessage: String
    }
}
```

### Step 4: Implement LiveActivityManager (Swift)

Create `LiveActivityManager.swift` in the Runner target:

```swift
import ActivityKit
import Flutter
import Foundation

@available(iOS 16.1, *)
class LiveActivityManager {
    private var currentActivity: Activity<MyActivityAttributes>? = nil

    func startLiveActivity(data: [String: Any]?, result: FlutterResult) {
        guard let info = data else {
            result(FlutterError(code: "INVALID_DATA", message: "Data is nil", details: nil))
            return
        }

        let attributes = MyActivityAttributes(
            title: info["title"] as? String ?? ""
        )
        let state = MyActivityAttributes.ContentState(
            value: info["value"] as? Int ?? 0,
            statusMessage: info["statusMessage"] as? String ?? ""
        )

        do {
            currentActivity = try Activity<MyActivityAttributes>.request(
                attributes: attributes,
                contentState: state,
                pushType: nil  // Use .token if you want push-based updates
            )
        } catch {
            result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    func updateLiveActivity(data: [String: Any]?, result: FlutterResult) {
        guard let info = data else {
            result(FlutterError(code: "INVALID_DATA", message: "Data is nil", details: nil))
            return
        }

        let updatedState = MyActivityAttributes.ContentState(
            value: info["value"] as? Int ?? 0,
            statusMessage: info["statusMessage"] as? String ?? ""
        )

        Task {
            await currentActivity?.update(using: updatedState)
        }
    }

    func stopLiveActivity(result: FlutterResult) {
        Task {
            await currentActivity?.end(using: nil, dismissalPolicy: .immediate)
        }
    }
}
```

### Step 5: Wire up AppDelegate (Swift)

In `AppDelegate.swift`, set up the MethodChannel bridge:

```swift
import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let liveActivityManager = LiveActivityManager()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "PW",  // Must match Dart side channelKey
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "startLiveActivity":
                self?.liveActivityManager.startLiveActivity(
                    data: call.arguments as? [String: Any], result: result)
            case "updateLiveActivity":
                self?.liveActivityManager.updateLiveActivity(
                    data: call.arguments as? [String: Any], result: result)
            case "stopLiveActivity":
                self?.liveActivityManager.stopLiveActivity(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### Step 6: Create Widget UI (SwiftUI)

In the Widget Extension target, create the Live Activity widget:

```swift
import SwiftUI
import WidgetKit
import ActivityKit

struct MyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyActivityAttributes.self) { context in
            // LOCK SCREEN / banner presentation
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(context.state.statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Text("\(context.state.value)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.yellow)
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.5))

        } dynamicIsland: { context in
            // DYNAMIC ISLAND presentation
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Text(context.attributes.title)
                            .font(.headline)
                        Text(context.state.statusMessage)
                            .font(.subheadline)
                        Text("\(context.state.value)")
                            .font(.title)
                            .bold()
                            .foregroundColor(.yellow)
                    }
                }
            } compactLeading: {
                // Compact left side
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            } compactTrailing: {
                // Compact right side
                Text("\(context.state.value)")
                    .foregroundColor(.yellow)
            } minimal: {
                // Minimal (when multiple activities)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
}
```

### Step 7: Flutter Dart Side — DynamicIslandManager

```dart
import 'dart:developer';
import 'package:flutter/services.dart';

class DynamicIslandManager {
  final String channelKey;
  late final MethodChannel _methodChannel;

  DynamicIslandManager({required this.channelKey}) {
    _methodChannel = MethodChannel(channelKey);
  }

  Future<void> startLiveActivity({required Map<String, dynamic> data}) async {
    try {
      await _methodChannel.invokeMethod('startLiveActivity', data);
    } catch (e, st) {
      log('startLiveActivity error: $e', stackTrace: st);
    }
  }

  Future<void> updateLiveActivity({required Map<String, dynamic> data}) async {
    try {
      await _methodChannel.invokeMethod('updateLiveActivity', data);
    } catch (e, st) {
      log('updateLiveActivity error: $e', stackTrace: st);
    }
  }

  Future<void> stopLiveActivity() async {
    try {
      await _methodChannel.invokeMethod('stopLiveActivity');
    } catch (e, st) {
      log('stopLiveActivity error: $e', stackTrace: st);
    }
  }
}
```

**Usage:**
```dart
final diManager = DynamicIslandManager(channelKey: 'PW');

// Start
await diManager.startLiveActivity(data: {
  'title': 'My Activity',
  'value': 0,
  'statusMessage': 'Starting...',
});

// Update
await diManager.updateLiveActivity(data: {
  'value': 42,
  'statusMessage': 'In progress...',
});

// Stop
await diManager.stopLiveActivity();
```

---

## Approach 2: Custom Pushwoosh Live Activity with `setup()`

Uses your own `ActivityAttributes` conforming to `PushwooshLiveActivityAttributes` protocol. Pushwoosh **automatically handles** pushToStart and pushToUpdate token management.

### Define Custom Attributes (Swift)

Your attributes must conform to `PushwooshLiveActivityAttributes`, and `ContentState` must conform to `PushwooshLiveActivityContentState`:

```swift
import ActivityKit
import PushwooshLiveActivities

struct MyCustomAttributes: PushwooshLiveActivityAttributes {
    public struct ContentState: PushwooshLiveActivityContentState {
        var value: Int
        var statusMessage: String
        var pushwoosh: PushwooshLiveActivityContentStateData?
    }

    var title: String
    var pushwoosh: PushwooshLiveActivityAttributeData
}
```

**Important:** Both `pushwoosh` properties are required by the protocol. They are used internally for token management.

### Register in AppDelegate (Swift)

Call `setup()` early in app lifecycle — it automatically listens for token updates:

```swift
import PushwooshFramework
import PushwooshLiveActivities

// In application(_:didFinishLaunchingWithOptions:)
if #available(iOS 16.1, *) {
    Pushwoosh.LiveActivities.setup(MyCustomAttributes.self)
}
```

### Start / Update / Stop from Flutter

Use `startLiveActivityWithToken()` to register your custom activity token with Pushwoosh, then manage the activity via MethodChannel bridge (same as Approach 1).

---

## Approach 3: Default Pushwoosh Live Activity

Uses built-in Pushwoosh `DefaultLiveActivityAttributes`. Simplest approach, but no custom UI.

### Setup

```dart
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

// During app initialization (after Pushwoosh.initialize)
await Pushwoosh.getInstance.defaultSetup();
```

`defaultSetup()` registers the device's push-to-start token with Pushwoosh servers. Call it once during app init.

### Start Locally

```dart
await Pushwoosh.getInstance.defaultStart(
  "my_activity_id",           // unique activity ID
  {"driverName": "John"},     // static attributes (cannot change)
  {"status": "On the way"},   // dynamic content state (can update)
);
```

### Start with Custom Token

```dart
await Pushwoosh.getInstance.startLiveActivityWithToken(
  token,        // Activity push token string
  activityId,   // Activity ID
);
```

### Stop

```dart
await Pushwoosh.getInstance.stopLiveActivity();
```

### Remote Update via Pushwoosh API

Send POST to `https://go.pushwoosh.com/json/1.3/createMessage`:

```json
{
  "request": {
    "application": "XXXXX-XXXXX",
    "auth": "YOUR_AUTH_API_TOKEN",
    "notifications": [
      {
        "content": "Update",
        "title": "Title",
        "live_activity": {
          "event": "update",
          "content-state": {
            "data": {"status": "Delivered"}
          },
          "attributes-type": "DefaultLiveActivityAttributes",
          "attributes": {
            "data": {"driverName": "John"}
          }
        },
        "devices": ["DEVICE_HWID"],
        "live_activity_id": "my_activity_id"
      }
    ]
  }
}
```

**Events:** `"start"`, `"update"`, `"end"`

---

## Pushwoosh Flutter SDK API Reference (Live Activities)

| Method | Where | Description |
|---|---|---|
| `Pushwoosh.LiveActivities.setup(MyAttributes.self)` | iOS (Swift) | Register custom ActivityAttributes with automatic token management |
| `defaultSetup()` | Dart / iOS | Register default push-to-start token with Pushwoosh |
| `defaultStart(activityId, attributes, content)` | Dart / iOS | Start default Live Activity |
| `startLiveActivityWithToken(token, activityId)` | Dart / iOS | Register custom activity token with Pushwoosh |
| `stopLiveActivity()` | Dart / iOS | Stop current Live Activity |

---

## iOS Version Check

The SDK checks iOS version before calling Live Activities APIs:

```objc
// From PushwooshPlugin.m
if ([PushwooshPlugin isSystemVersionGreaterOrEqualTo:@"16.1"]) {
    [PushwooshLiveActivitiesImplementationSetup defaultSetup];
}
```

Always guard Live Activity code with `@available(iOS 16.1, *)`.

---

## Common Issues

### Activity not appearing
- Verify `NSSupportsLiveActivities = YES` in Info.plist
- Check deployment target is iOS 16.1+
- Ensure `ActivityAttributes` struct is in **shared group** (both app and extension targets)
- Test on physical device (Simulator has limited support)

### MethodChannel not working
- Ensure channel name matches on both sides (`"PW"`)
- `setMethodCallHandler` must be called in `didFinishLaunchingWithOptions`
- Check Flutter controller is not nil

### Push updates not arriving
- Call `defaultSetup()` after `Pushwoosh.initialize()`
- Verify push certificate supports Live Activities
- Check `live_activity_id` matches between start and update calls

### Widget Extension build errors
- Add `ActivityAttributes` file to **both** targets (Runner + Widget Extension)
- Import `ActivityKit` in all files that use Activity types
- Pod dependency `PushwooshXCFramework/PushwooshLiveActivities` must be in Podfile

---

## Podspec Dependency

The Pushwoosh Flutter SDK podspec (`v2.3.16`) includes Live Activities by default:

```ruby
s.dependency 'PushwooshXCFramework', '7.0.22'
s.dependency 'PushwooshXCFramework/PushwooshLiveActivities'
```

No additional pod configuration needed.

---

## Files to Create/Modify Checklist

**Create:**
- [ ] `ActivityAttributes` struct (shared Swift file in both targets)
- [ ] `LiveActivityManager.swift` (Runner target)
- [ ] Widget Extension target with Live Activity widget (SwiftUI)
- [ ] `DynamicIslandManager` Dart class (Flutter side)

**Modify:**
- [ ] `Info.plist` — add `NSSupportsLiveActivities = YES`
- [ ] `AppDelegate.swift` — add MethodChannel handler for "PW"
- [ ] App initialization — call `Pushwoosh.getInstance.defaultSetup()`
