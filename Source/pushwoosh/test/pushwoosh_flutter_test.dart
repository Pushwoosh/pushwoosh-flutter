import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('pushwoosh');
  final List<MethodCall> log = <MethodCall>[];
  dynamic mockResult;

  setUp(() {
    log.clear();
    mockResult = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      return mockResult;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('setAppCode', () {
    test('sends the app code and the base url', () async {
      Pushwoosh.getInstance.setAppCode('AAAAA-BBBBB',
          baseUrl: 'https://custom.example.com/json/1.3/');
      await pumpEventQueue();

      expect(log, hasLength(1));
      expect(log.single.method, 'setAppCode');
      expect(log.single.arguments, <String, dynamic>{
        'appCode': 'AAAAA-BBBBB',
        'baseUrl': 'https://custom.example.com/json/1.3/',
      });
    });

    test('sends a null base url when none is given', () async {
      Pushwoosh.getInstance.setAppCode('AAAAA-BBBBB');
      await pumpEventQueue();

      expect(log.single.arguments, <String, dynamic>{
        'appCode': 'AAAAA-BBBBB',
        'baseUrl': null,
      });
    });

    test('accepts both http and https endpoints', () async {
      Pushwoosh.getInstance
          .setAppCode('AAAAA-BBBBB', baseUrl: 'https://custom.example.com/');
      Pushwoosh.getInstance
          .setAppCode('AAAAA-BBBBB', baseUrl: 'http://custom.example.com/');
      await pumpEventQueue();

      expect(log, hasLength(2));
    });

    test('rejects a blank app code without touching the channel', () {
      expect(() => Pushwoosh.getInstance.setAppCode(''), throwsArgumentError);
      expect(() => Pushwoosh.getInstance.setAppCode('   '), throwsArgumentError);
      expect(log, isEmpty);
    });

    test('rejects a blank base url without touching the channel', () {
      expect(() => Pushwoosh.getInstance.setAppCode('AAAAA-BBBBB', baseUrl: ''),
          throwsArgumentError);
      expect(
          () => Pushwoosh.getInstance.setAppCode('AAAAA-BBBBB', baseUrl: '   '),
          throwsArgumentError);
      expect(log, isEmpty);
    });

    test('rejects a base url with no scheme or a foreign one', () {
      expect(
          () => Pushwoosh.getInstance
              .setAppCode('AAAAA-BBBBB', baseUrl: 'api.example.com'),
          throwsArgumentError);
      expect(
          () => Pushwoosh.getInstance
              .setAppCode('AAAAA-BBBBB', baseUrl: 'ftp://api.example.com'),
          throwsArgumentError);
      expect(log, isEmpty);
    });

    /// The returned future is the only way a channel-level failure can reach the caller — a
    /// fire-and-forget call would turn this into an unhandled async error instead.
    test('forwards a channel failure to the caller', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'setAppCode', message: 'channel refused');
      });

      await expectLater(
          Pushwoosh.getInstance
              .setAppCode('AAAAA-BBBBB', baseUrl: 'https://api.example.com/'),
          throwsA(isA<PlatformException>()));
    });
  });

  group('getAppCode', () {
    test('returns whatever the channel returned', () async {
      mockResult = 'AAAAA-BBBBB';
      expect(await Pushwoosh.getInstance.getAppCode, 'AAAAA-BBBBB');
      expect(log.single.method, 'getAppCode');
      expect(log.single.arguments, isNull);
    });

    test('returns null when no app code is set', () async {
      mockResult = null;
      expect(await Pushwoosh.getInstance.getAppCode, isNull);
      expect(log.single.method, 'getAppCode');
      expect(log.single.arguments, isNull);
    });
  });

  group('initialize', () {
    test('forwards base_url to the channel', () async {
      Pushwoosh.initialize(<String, dynamic>{
        'app_id': 'AAAAA-BBBBB',
        'base_url': 'https://custom.example.com/json/1.3/',
      });
      await pumpEventQueue();

      expect(log.single.method, 'initialize');
      expect(log.single.arguments, <String, dynamic>{
        'app_id': 'AAAAA-BBBBB',
        'base_url': 'https://custom.example.com/json/1.3/',
      });
    });

    test('still works without base_url', () async {
      Pushwoosh.initialize(<String, dynamic>{'app_id': 'AAAAA-BBBBB'});
      await pumpEventQueue();

      expect(log.single.arguments, <String, dynamic>{'app_id': 'AAAAA-BBBBB'});
    });

    test('rejects a schemeless base_url without touching the channel', () {
      expect(
          () => Pushwoosh.initialize(<String, dynamic>{
                'app_id': 'AAAAA-BBBBB',
                'base_url': 'api.example.com',
              }),
          throwsArgumentError);
      expect(log, isEmpty);
    });

    test('rejects a blank base_url without touching the channel', () {
      expect(
          () => Pushwoosh.initialize(<String, dynamic>{
                'app_id': 'AAAAA-BBBBB',
                'base_url': '',
              }),
          throwsArgumentError);
      expect(log, isEmpty);
    });

    test('rejects a non-String base_url without touching the channel', () {
      expect(
          () => Pushwoosh.initialize(<String, dynamic>{
                'app_id': 'AAAAA-BBBBB',
                'base_url': 42,
              }),
          throwsArgumentError);
      expect(log, isEmpty);
    });
  });

  group('presentInApp', () {
    test('forwards the config to the channel untouched', () async {
      final Map<String, dynamic> config = <String, dynamic>{
        'displayType': 'modal',
        'inAppId': 'demo-modal',
        'modal': <String, dynamic>{
          'showClose': true,
          'title': <String, dynamic>{'text': 'Hi', 'color': '#FFFFFFFF'},
          'buttons': <dynamic>[
            <String, dynamic>{
              'text': <String, dynamic>{'text': 'Open'},
              'action': <String, dynamic>{'type': 'close'},
            },
          ],
        },
      };

      await Pushwoosh.getInstance.presentInApp(config);

      expect(log, hasLength(1));
      expect(log.single.method, 'presentInApp');
      expect(log.single.arguments, config);
    });

    test('rejects an empty config without touching the channel', () {
      expect(() => Pushwoosh.getInstance.presentInApp(<String, dynamic>{}),
          throwsArgumentError);
      expect(log, isEmpty);
    });

    test('rejects a config with no displayType without touching the channel',
        () {
      expect(
          () => Pushwoosh.getInstance.presentInApp(<String, dynamic>{
                'inAppId': 'demo-modal',
                'modal': <String, dynamic>{'showClose': true},
              }),
          throwsArgumentError);
      expect(log, isEmpty);
    });

    test('rejects a non-String displayType without touching the channel', () {
      expect(
          () => Pushwoosh.getInstance.presentInApp(<String, dynamic>{
                'displayType': 42,
              }),
          throwsArgumentError);
      expect(log, isEmpty);
    });

    test('rejects a blank displayType without touching the channel', () {
      expect(
          () => Pushwoosh.getInstance.presentInApp(<String, dynamic>{
                'displayType': '   ',
              }),
          throwsArgumentError);
      expect(log, isEmpty);
    });
  });
}
