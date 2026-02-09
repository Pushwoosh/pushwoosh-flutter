<h1 align="center">Pushwoosh Flutter Plugin</h1>

<p align="center">
  <a href="https://github.com/Pushwoosh/pushwoosh-flutter"><img src="https://img.shields.io/github/release/Pushwoosh/pushwoosh-flutter.svg?style=flat-square" alt="GitHub release"></a>
  <a href="https://pub.dev/packages/pushwoosh_flutter"><img src="https://img.shields.io/pub/v/pushwoosh_flutter.svg?style=flat-square" alt="pub"></a></p>

<p align="center">

<p align="center">
  Cross-platform push notifications, In-App messaging, and more for Flutter applications.
</p>

## Table of Contents

- [Documentation](#documentation)
- [Features](#features)
- [Installation](#installation)
- [AI-Assisted Integration](#ai-assisted-integration)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Support](#support)
- [License](#license)

## Documentation

- [Integration Guide](https://docs.pushwoosh.com/platform-docs/pushwoosh-sdk/cross-platform-frameworks/flutter/integrating-flutter-plugin) — step-by-step setup
- [API Reference](#api-reference) — full API documentation

## Features

- **Push Notifications** — register, receive, and handle push notifications on iOS and Android
- **In-App Messages** — trigger and display in-app messages based on events
- **Tags & Segmentation** — set and get user tags for targeted messaging
- **User Identification** — associate devices with user IDs for cross-device tracking
- **Message Inbox** — built-in UI for message inbox with customization options
- **Badge Management** — set, get, and increment app icon badge numbers
- **Live Activities** — iOS Live Activities support with default and custom setups
- **Geozones** — location-based push notifications via separate plugin
- **Deep Links** — handle deep link URLs from push notifications
- **Huawei Push** — HMS push notification support
- **Multi-channel** — email, SMS, and WhatsApp registration
- **JavaScript Interface** — bidirectional communication with In-App Message HTML

## Installation

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  pushwoosh_flutter: '^2.3.16'
```

### Optional plugins

```yaml
dependencies:
  pushwoosh_geozones: ^2.3.15   # Location-based push notifications
  pushwoosh_inbox: ^2.3.15      # Message Inbox UI
```

### iOS Setup

```bash
cd ios && pod install
```

### Android Setup

1. Configure Firebase project in [Firebase Console](https://console.firebase.google.com)
2. Place `google-services.json` into `android/app/` folder

## AI-Assisted Integration

Integrate the Pushwoosh Flutter plugin using AI coding assistants (Claude Code, Cursor, GitHub Copilot, etc.).

> **Requirement:** Your AI assistant must have access to [Context7](https://context7.com/) MCP server or web search capabilities.

### Quick Start Prompts

Choose the prompt that matches your task:

---

#### 1. Basic Plugin Integration

```
Integrate Pushwoosh Flutter plugin into my Flutter project.

Requirements:
- Install pushwoosh_flutter via pub
- Initialize Pushwoosh with my App ID in main()
- Register for push notifications and handle onPushReceived and onPushAccepted streams

Use Context7 MCP to fetch Pushwoosh Flutter plugin documentation.
```

---

#### 2. Tags and User Segmentation

```
Show me how to use Pushwoosh tags in a Flutter app for user segmentation.
I need to set tags, get tags, and set user ID for cross-device tracking.

Use Context7 MCP to fetch Pushwoosh Flutter plugin documentation for setTags and getTags.
```

---

#### 3. Message Inbox Integration

```
Integrate Pushwoosh Message Inbox into my Flutter app. Show me how to:
- Display the inbox UI with custom styling using PWInboxStyle
- Load messages programmatically
- Track unread message count

Use Context7 MCP to fetch Pushwoosh Flutter plugin documentation for presentInboxUI.
```

---

## Quick Start

### 1. Initialize the Plugin

```dart
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

void main() {
  runApp(MyApp());

  // Initialize Pushwoosh
  Pushwoosh.initialize({
    "app_id": "YOUR_PUSHWOOSH_APP_ID",
    "sender_id": "YOUR_FCM_SENDER_ID"
  });

  // Listen for push events
  Pushwoosh.getInstance.onPushReceived.listen((event) {
    print("Push received: ${event.pushwooshMessage.payload}");
  });

  Pushwoosh.getInstance.onPushAccepted.listen((event) {
    print("Push opened: ${event.pushwooshMessage.payload}");
  });

  // Register for push notifications
  Pushwoosh.getInstance.registerForPushNotifications();
}
```

### 2. Set User Tags

```dart
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

// Set tags
await Pushwoosh.getInstance.setTags({
  "username": "john_doe",
  "age": 25,
  "interests": ["sports", "tech"]
});

// Get tags
Map tags = await Pushwoosh.getInstance.getTags();
print("Tags: $tags");
```

### 3. Post Events for In-App Messages

```dart
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

Pushwoosh.getInstance.setUserId("user_12345");
await Pushwoosh.getInstance.postEvent("purchase_complete", {
  "productName": "Premium Plan",
  "amount": "9.99"
});
```

### 4. Message Inbox

```dart
import 'package:pushwoosh_inbox/pushwoosh_inbox.dart';

// Open inbox UI with custom styling
var style = PWInboxStyle();
style.dateFormat = "dd.MM.yyyy";
style.accentColor = "#3498db";
style.backgroundColor = "#ffffff";
style.titleColor = "#333333";
style.descriptionColor = "#666666";
style.listEmptyMessage = "No messages yet";
PushwooshInbox.presentInboxUI(style: style);

// Or load messages programmatically
List<InboxMessage> messages = await PushwooshInbox.loadMessages();
for (var msg in messages) {
  print("${msg.title}: ${msg.message}");
}

// Track unread count
int? unread = await PushwooshInbox.unreadMessagesCount();
print("Unread messages: $unread");
```

### 5. Geozones

```dart
import 'package:pushwoosh_geozones/pushwoosh_geozones.dart';

// Start location tracking
await PushwooshGeozones.startLocationTracking();

// Stop location tracking
PushwooshGeozones.stopLocationTracking();
```

### 6. Multi-channel Communication

```dart
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

// Register email
await Pushwoosh.getInstance.setEmail("user@example.com");

// Register multiple emails
await Pushwoosh.getInstance.setEmails(["user@example.com", "work@example.com"]);

// Set user ID and emails together
await Pushwoosh.getInstance.setUserEmails("user_123", ["user@example.com"]);

// Register SMS and WhatsApp
Pushwoosh.getInstance.registerSmsNumber("+1234567890");
Pushwoosh.getInstance.registerWhatsappNumber("+1234567890");
```

### 7. Live Activities (iOS)

```dart
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

// Default setup (call once at app start)
await Pushwoosh.getInstance.defaultSetup();

// Start a Live Activity
await Pushwoosh.getInstance.defaultStart(
  "delivery_123",
  {"driverName": "John"},        // attributes
  {"status": "On the way"}       // content
);

// Or start with a custom token
await Pushwoosh.getInstance.startLiveActivityWithToken(token, "delivery_123");

// Stop Live Activity
await Pushwoosh.getInstance.stopLiveActivity();
```

### 8. Deep Link Handling

```dart
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

Pushwoosh.getInstance.onDeepLinkOpened.listen((String deepLink) {
  print("Deep link opened: $deepLink");
  // Navigate to the appropriate screen
});
```

### 9. JavaScript Interface for In-App Messages

```dart
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

// Register JavaScript interface for In-App communication
await Pushwoosh.getInstance.addJavascriptInterface('flutter', {
  'onButtonTap': (Map<String, dynamic> args) {
    print("Button tapped with args: $args");
    return "OK";
  },
  'getUserData': (Map<String, dynamic> args) {
    return {"name": "John", "premium": true};
  }
});

// Remove interface when no longer needed
await Pushwoosh.getInstance.removeJavascriptInterface('flutter');
```

## API Reference

### Initialization & Registration

| Method | Description |
|--------|-------------|
| `Pushwoosh.initialize(params)` | Initialize the plugin. Call on every app launch |
| `registerForPushNotifications()` | Register for push notifications, returns push token |
| `unregisterForPushNotifications()` | Unregister from push notifications |
| `getPushToken` | Get the push token (Future) |
| `getHWID` | Get Pushwoosh Hardware ID (Future) |

### Tags & User Data

| Method | Description |
|--------|-------------|
| `setTags(tags)` | Set device tags |
| `getTags()` | Get device tags |
| `setUserId(userId)` | Set user identifier for cross-device tracking |
| `setLanguage(language)` | Set custom language for localized pushes |
| `setEmail(email)` | Register email for the user |
| `setEmails(emails)` | Register multiple emails |
| `setUserEmails(userId, emails)` | Set user ID and register emails |
| `registerSmsNumber(number)` | Register SMS number (E.164 format) |
| `registerWhatsappNumber(number)` | Register WhatsApp number (E.164 format) |

### Push Events (Streams)

| Stream | Description |
|--------|-------------|
| `onPushReceived` | Stream of `PushEvent` when notification is received |
| `onPushAccepted` | Stream of `PushEvent` when notification is opened |
| `onDeepLinkOpened` | Stream of `String` when a deep link is opened |

### In-App Messages & Events

| Method | Description |
|--------|-------------|
| `postEvent(event, attributes)` | Post event to trigger In-App Messages |
| `addJavascriptInterface(name, methods)` | Register JS interface for Rich Media communication |
| `removeJavascriptInterface(name)` | Remove a JavaScript interface |

### Badge Management

| Method | Description |
|--------|-------------|
| `setApplicationIconBadgeNumber(badge)` | Set badge number |
| `getApplicationIconBadgeNumber` | Get current badge number (Future) |
| `addToApplicationIconBadgeNumber(badge)` | Increment/decrement badge |

### Live Activities (iOS)

| Method | Description |
|--------|-------------|
| `defaultSetup()` | Setup default Live Activity handling |
| `defaultStart(activityId, attributes, content)` | Start a default Live Activity |
| `startLiveActivityWithToken(token, activityId)` | Start Live Activity with a token |
| `stopLiveActivity()` | Stop the current Live Activity |

### Communication Control

| Method | Description |
|--------|-------------|
| `startServerCommunication()` | Resume communication with Pushwoosh server |
| `stopServerCommunication()` | Pause communication with Pushwoosh server |
| `setShowForegroundAlert(value)` | Show/hide alerts when push received in foreground |

### Android-specific

| Method | Description |
|--------|-------------|
| `setMultiNotificationMode(on)` | Allow multiple notifications in notification center |
| `enableHuaweiNotifications()` | Enable Huawei HMS push support |

### Message Inbox (pushwoosh_inbox)

| Method | Description |
|--------|-------------|
| `PushwooshInbox.presentInboxUI(style?)` | Open inbox UI with optional style customization |
| `PushwooshInbox.loadMessages()` | Load inbox messages from server |
| `PushwooshInbox.loadCachedMessages()` | Load cached inbox messages |
| `PushwooshInbox.unreadMessagesCount()` | Get unread message count |
| `PushwooshInbox.messagesCount()` | Get total message count |
| `PushwooshInbox.messagesWithNoActionPerformedCount()` | Get messages with no action count |
| `PushwooshInbox.readMessage(code)` | Mark message as read |
| `PushwooshInbox.readMessages(codes)` | Mark multiple messages as read |
| `PushwooshInbox.deleteMessage(code)` | Delete a message |
| `PushwooshInbox.deleteMessages(codes)` | Delete multiple messages |
| `PushwooshInbox.performAction(code)` | Perform the action associated with a message |

### Geozones (pushwoosh_geozones)

| Method | Description |
|--------|-------------|
| `PushwooshGeozones.startLocationTracking()` | Start location-based push tracking |
| `PushwooshGeozones.stopLocationTracking()` | Stop location tracking |

## Support

- [Documentation](https://docs.pushwoosh.com/)
- [Support Portal](https://support.pushwoosh.com/)
- [Report Issues](https://github.com/Pushwoosh/pushwoosh-flutter/issues)

## License

Pushwoosh Flutter Plugin is available under the MIT license. See [LICENSE](LICENSE) for details.

---

Made with ❤️ by [Pushwoosh](https://www.pushwoosh.com/)
