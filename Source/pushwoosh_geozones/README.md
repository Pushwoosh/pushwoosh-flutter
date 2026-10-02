## Installation

Install the library from pub:

```yaml
dependencies:
pushwoosh_geozones: '^2.3.25'
```

Use the same version as `pushwoosh_flutter` and upgrade the two together. On Flutter 3.44+ the iOS part of
both is a Swift package; `pushwoosh_geozones` 2.3.24 or older next to a newer `pushwoosh_flutter` puts the native SDK
into the app twice and the build fails with `Multiple commands produce '.../PushwooshFramework.framework'`.
See iOS Setup in the [pushwoosh_flutter README](https://pub.dev/packages/pushwoosh_flutter).

## Usage
```dart
import 'package:pushwoosh_geozones/pushwoosh_geozones.dart';
...
PushwooshGeozones.startLocationTracking();
```
