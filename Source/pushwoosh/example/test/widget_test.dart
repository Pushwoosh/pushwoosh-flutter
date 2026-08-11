// Widget tests for the Pushwoosh demo app.
//
// The app talks to the native SDK over platform channels, so every test mocks
// them through TestDefaultBinaryMessengerBinding. Pushwoosh.initialize() lives
// in main() and is never called here: these tests pump MyApp directly.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pushwoosh_example/deep_link_screen.dart';
import 'package:pushwoosh_example/main.dart';

/// The plugin's MethodChannel.
const MethodChannel _pushwooshChannel = MethodChannel('pushwoosh');

/// An EventChannel activates its stream by sending a `listen` MethodCall on a
/// channel with the same name, so mocking these two as MethodChannels is what
/// keeps the widget tree from tripping a MissingPluginException.
const MethodChannel _deepLinkChannel = MethodChannel('pushwoosh/deeplink');
const MethodChannel _jsInterfaceChannel = MethodChannel('pushwoosh/jsinterface');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// What the mocked native side answers for getPushToken /
  /// registerForPushNotifications. Reassigned per test.
  String? mockPushToken;

  /// Every MethodCall the app sent to the mocked 'pushwoosh' channel.
  final List<MethodCall> nativeCalls = <MethodCall>[];

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    mockPushToken = null;
    nativeCalls.clear();

    messenger().setMockMethodCallHandler(_pushwooshChannel, (MethodCall call) async {
      nativeCalls.add(call);
      switch (call.method) {
        case 'getPushToken':
        case 'registerForPushNotifications':
          return mockPushToken;
        default:
          return null;
      }
    });
    messenger().setMockMethodCallHandler(_deepLinkChannel, (MethodCall call) async => null);
    messenger().setMockMethodCallHandler(_jsInterfaceChannel, (MethodCall call) async => null);
  });

  tearDown(() {
    messenger().setMockMethodCallHandler(_pushwooshChannel, null);
    messenger().setMockMethodCallHandler(_deepLinkChannel, null);
    messenger().setMockMethodCallHandler(_jsInterfaceChannel, null);
  });

  /// Pumps the app and drains the two-second delay inside
  /// `_setupJavaScriptInterface()`. Leaving that timer pending fails the test
  /// with "A Timer is still pending even after the widget tree was disposed".
  Future<void> bootApp(WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  /// The registration switch lives on the second tab; TabBarView does not build
  /// the pages you cannot see, so the switch must be brought on screen first.
  Future<void> openSettingsTab(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
  }

  /// The Switch sitting in the same Row as [label] — not "some Switch
  /// somewhere in the tree".
  Finder switchInRowWith(String label) => find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
        matching: find.byType(Switch),
      );

  testWidgets('a deep link from the platform opens the deep link screen',
      (WidgetTester tester) async {
    const String link = 'pwdemo://demo?id=1';

    await bootApp(tester);

    // Exactly what the plugin's EventChannel delivers when the native side
    // forwards an ACTION_VIEW intent.
    await messenger().handlePlatformMessage(
      'pushwoosh/deeplink',
      const StandardMethodCodec().encodeSuccessEnvelope(link),
      (ByteData? _) {},
    );
    await tester.pumpAndSettle();

    expect(find.byType(DeepLinkScreen), findsOneWidget);
    expect(find.text(link), findsOneWidget);
  });

  testWidgets('switch is seeded ON from a push token stored by the SDK',
      (WidgetTester tester) async {
    mockPushToken = 'stub-push-token';

    await bootApp(tester);
    await openSettingsTab(tester);

    expect(find.text('UNREGISTER FOR PUSH NOTIFICATIONS'), findsOneWidget);
    expect(
      tester.widget<Switch>(switchInRowWith('UNREGISTER FOR PUSH NOTIFICATIONS')).value,
      isTrue,
    );
    expect(
      nativeCalls.map((MethodCall call) => call.method),
      contains('getPushToken'),
    );
  });

  testWidgets('switch stays OFF when the SDK has no push token',
      (WidgetTester tester) async {
    mockPushToken = null;

    await bootApp(tester);
    await openSettingsTab(tester);

    expect(find.text('REGISTER FOR PUSH NOTIFICATIONS'), findsOneWidget);
    expect(
      tester.widget<Switch>(switchInRowWith('REGISTER FOR PUSH NOTIFICATIONS')).value,
      isFalse,
    );
  });

  testWidgets(
      'switch turns ON only after registration returns a token, not on tap',
      (WidgetTester tester) async {
    mockPushToken = null;

    await bootApp(tester);
    await openSettingsTab(tester);

    // Hold the native call open so the switch can be inspected mid-flight,
    // before the awaited registerForPushNotifications() call resolves.
    final Completer<String?> registerCompleter = Completer<String?>();
    messenger().setMockMethodCallHandler(_pushwooshChannel, (MethodCall call) async {
      nativeCalls.add(call);
      if (call.method == 'registerForPushNotifications') {
        return registerCompleter.future;
      }
      return mockPushToken;
    });

    await tester.tap(switchInRowWith('REGISTER FOR PUSH NOTIFICATIONS'));
    await tester.pump();

    // Still OFF: the tap fired the call, but nothing has come back yet. A
    // synchronous/eager write of notificationsEnabled would show UNREGISTER
    // here already — that is exactly the regression this test guards.
    expect(find.text('REGISTER FOR PUSH NOTIFICATIONS'), findsOneWidget);
    expect(
      tester.widget<Switch>(switchInRowWith('REGISTER FOR PUSH NOTIFICATIONS')).value,
      isFalse,
    );

    registerCompleter.complete('fresh-push-token');
    await tester.pumpAndSettle();

    expect(
      nativeCalls.map((MethodCall call) => call.method),
      contains('registerForPushNotifications'),
    );
    expect(find.text('UNREGISTER FOR PUSH NOTIFICATIONS'), findsOneWidget);
    expect(
      tester.widget<Switch>(switchInRowWith('UNREGISTER FOR PUSH NOTIFICATIONS')).value,
      isTrue,
    );
  });

  testWidgets(
      'switch ignores a second tap while a registration call is in flight',
      (WidgetTester tester) async {
    mockPushToken = null;

    await bootApp(tester);
    await openSettingsTab(tester);

    // Hold the native call open so a second tap can land while the first is
    // still pending.
    final Completer<String?> registerCompleter = Completer<String?>();
    messenger().setMockMethodCallHandler(_pushwooshChannel, (MethodCall call) async {
      nativeCalls.add(call);
      if (call.method == 'registerForPushNotifications') {
        return registerCompleter.future;
      }
      return mockPushToken;
    });

    await tester.tap(switchInRowWith('REGISTER FOR PUSH NOTIFICATIONS'));
    await tester.pump();
    // The switch should now be disabled for the duration of the call; this
    // second tap must not fire a second native call.
    await tester.tap(switchInRowWith('REGISTER FOR PUSH NOTIFICATIONS'));
    await tester.pump();

    expect(
      nativeCalls
          .where((MethodCall call) => call.method == 'registerForPushNotifications')
          .length,
      1,
    );

    registerCompleter.complete('fresh-push-token');
    await tester.pumpAndSettle();
  });

  testWidgets('switch stays OFF and reports the error when registration fails',
      (WidgetTester tester) async {
    messenger().setMockMethodCallHandler(_pushwooshChannel, (MethodCall call) async {
      nativeCalls.add(call);
      if (call.method == 'registerForPushNotifications') {
        throw PlatformException(code: 'PW_ERROR', message: 'registration failed');
      }
      return null; // getPushToken and everything else
    });

    await bootApp(tester);
    await openSettingsTab(tester);

    await tester.tap(switchInRowWith('REGISTER FOR PUSH NOTIFICATIONS'));
    await tester.pumpAndSettle();

    expect(find.text('ERROR'), findsOneWidget);
    expect(find.text('registration failed'), findsOneWidget);
    expect(find.text('REGISTER FOR PUSH NOTIFICATIONS'), findsOneWidget);
    expect(
      tester.widget<Switch>(switchInRowWith('REGISTER FOR PUSH NOTIFICATIONS')).value,
      isFalse,
    );
  });

  testWidgets('GET PUSH TOKEN says NOT REGISTERED instead of crashing',
      (WidgetTester tester) async {
    mockPushToken = null;

    await bootApp(tester);

    // The button sits low in the Actions tab's ListView.
    await tester.ensureVisible(find.text('GET PUSH TOKEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GET PUSH TOKEN'));
    await tester.pumpAndSettle();

    expect(find.text('Push Token'), findsOneWidget);
    expect(find.text('NOT REGISTERED'), findsOneWidget);
  });
}
