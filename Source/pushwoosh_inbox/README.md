## Installation

Install the library from pub:

```yaml
dependencies:
pushwoosh_inbox: '^2.3.25'
```

Use the same version as `pushwoosh_flutter` and upgrade the two together. On Flutter 3.44+ the iOS part of
both is a Swift package; `pushwoosh_inbox` 2.3.24 or older next to a newer `pushwoosh_flutter` puts the native SDK
into the app twice and the build fails with `Multiple commands produce '.../PushwooshFramework.framework'`.
See iOS Setup in the [pushwoosh_flutter README](https://pub.dev/packages/pushwoosh_flutter).

## Usage

Present the Inbox with the SDK's default appearance:

```dart
import 'package:pushwoosh_inbox/pushwoosh_inbox.dart';
...
PushwooshInbox.presentInboxUI();
```

To customize the appearance, pass a `PWInboxStyle`. Every field is optional —
the ones you leave unset keep their default value. Images are Flutter asset
paths and must be declared in your `pubspec.yaml`:

```dart
PWInboxStyle style = PWInboxStyle();
style.barTitle = "Messages";
style.barBackgroundColor = "#3AD29F";
style.accentColor = "#6750A4";
style.listEmptyMessage = "No messages yet";
style.defaultImage = "assets/images/logo.png";
PushwooshInbox.presentInboxUI(style: style);
```
