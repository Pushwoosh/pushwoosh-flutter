# Pushwoosh Flutter demo

Demo app for the `pushwoosh_flutter` plugin: push registration, tags, events, inbox, geozones,
native in-app messages, Live Activities, runtime region switching and deep links.

## Run

```bash
flutter pub get
cd ios && pod install && cd ..     # iOS only
flutter run
```

The app code is set from Dart, in `lib/main.dart` (`_demoAppCode`), and one Pushwoosh
application serves both platforms. `Pushwoosh_APPID` is present in Info.plist but left blank,
which is why the SDK's integration check reports it as "set at runtime" - a blank value is
read as absent. Filling it in would also override the app code the notification service
extension reads from the App Group, so it is left as a template slot.

## Deep links

Both platforms register the `pwdemo` scheme — Android in `android/app/src/main/AndroidManifest.xml`,
iOS in `ios/Runner/Info.plist`. Send a push with `l=pwdemo://demo?id=1` and the app opens
`DeepLinkScreen` with the link on it.

An `https://` link does **not** reach the app: without the App Links / Universal Links verification
file served from that domain the system gives the link to the browser. Testing deep links with
`https://docs.pushwoosh.com/...` therefore proves nothing.

Full walkthrough: `.claude/skills/e2e/scenarios/deep-link-from-push.md`.

## Device API token

The demo does not ship one. Features that need it (for example sending a test push from the app)
expect `Pushwoosh_API_TOKEN` in `ios/Runner/Info.plist`, taken from Pushwoosh Control Panel →
API Access. Add it locally and keep it out of commits — this directory is published to pub.dev and
mirrored to GitHub.
