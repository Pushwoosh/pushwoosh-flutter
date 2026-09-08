// Regression guard: a malformed `customData` degrades to null and the message
// still loads, instead of throwing out of loadMessages()/loadCachedMessages().
// Crash signatures and provenance: repro crash-flutter-dart-inbox-customdata-jsondecode.
//
// Feeds the REAL pipeline: a real MethodChannel('pushwoosh_inbox') with a mocked
// native handler, and the message JSON built exactly the way the native plugins
// build it (android: JSONObject.toString(), ios: NSJSONSerialization).
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushwoosh_inbox/pushwoosh_inbox.dart';

const MethodChannel _channel = MethodChannel('pushwoosh_inbox');

/// Mirrors android PushwooshInboxPlugin.toJson(): `u` is pulled out of actionParams
/// as a RAW STRING (Bundle.getString) and put into the message JSON as-is.
String androidMessageJson(String rawU) {
  final actionParams = jsonEncode({'u': rawU});
  return jsonEncode({
    'code': 'CODE-1',
    'title': 'title',
    'imageUrl': '',
    'message': 'message',
    'sendDate': '2026-08-12T10:00:00+0000',
    'messageType': 1,
    'bannerUrl': '',
    'isRead': false,
    'actionParams': actionParams,
    'isActionPerformed': false,
    'customData': rawU, // raw string, no validation on the native side
  });
}

/// Mirrors ios PushwooshInboxPlugin.toJson(): `u` is taken from actionParams with
/// valueForKey: and set into the dictionary AS THE OBJECT IT IS — NSString or NSDictionary.
String iosMessageJson(Object u) {
  return jsonEncode({
    'type': 1,
    'imageUrl': '',
    'code': 'CODE-1',
    'title': 'title',
    'message': 'message',
    'sendDate': '2026-08-12T10:00:00+0000',
    'isRead': false,
    'isActionPerformed': false,
    'actionParams': {'u': u},
    'customData': u, // object or string, no validation on the native side
  });
}

void mockNative(List<String> messageJsons) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (MethodCall call) async {
    if (call.method == 'loadMessages' || call.method == 'loadCachedMessages') {
      return messageJsons;
    }
    return null;
  });
}

/// The whole load must survive; returns the messages the host actually gets.
Future<List<InboxMessage>> load(List<String> messageJsons,
    {bool cached = false}) async {
  mockNative(messageJsons);
  return cached
      ? await PushwooshInbox.loadCachedMessages()
      : await PushwooshInbox.loadMessages();
}

/// The message is delivered intact, only customData is dropped.
void expectCustomDataDropped(List<InboxMessage> messages, String label) {
  expect(messages, hasLength(1), reason: '$label: message was lost');
  expect(messages.single.customData, isNull,
      reason: '$label: expected customData to degrade to null');
  expect(messages.single.code, 'CODE-1', reason: '$label: code mangled');
  expect(messages.single.title, 'title', reason: '$label: title mangled');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('inbox customData jsonDecode', () {
    test('mode 1: android, non-JSON custom data string "hello"', () async {
      expectCustomDataDropped(
          await load([androidMessageJson('hello')]), 'android/hello');
    });

    test('mode 1: android, "key=value"', () async {
      expectCustomDataDropped(
          await load([androidMessageJson('key=value')]), 'android/key=value');
    });

    test('mode 1: android, empty custom data ""', () async {
      expectCustomDataDropped(
          await load([androidMessageJson('')]), 'android/empty');
    });

    test('mode 2: ios, custom data object {"a":1}', () async {
      final messages = await load([
        iosMessageJson(<String, dynamic>{'a': 1})
      ]);
      expect(messages, hasLength(1), reason: 'ios/object: message was lost');
      expect(messages.single.customData, {'a': 1},
          reason: 'ios/object: a real object must pass through untouched');
    });

    test('mode 2: ios, custom data number 42', () async {
      expectCustomDataDropped(await load([iosMessageJson(42)]), 'ios/number');
    });

    test('mode 2: android, valid JSON array "[1,2]"', () async {
      expectCustomDataDropped(
          await load([androidMessageJson('[1,2]')]), 'android/array');
    });

    test('mode 2: android, valid JSON scalar "42"', () async {
      expectCustomDataDropped(
          await load([androidMessageJson('42')]), 'android/scalar');
    });

    test('blast radius: one bad message no longer kills the list', () async {
      final messages = await load([
        androidMessageJson('{"a":1}'),
        androidMessageJson('hello'),
        androidMessageJson('{"b":2}'),
      ]);
      expect(messages, hasLength(3),
          reason:
              'android/one-bad-of-three: the host must still get all three');
      expect(messages[0].customData, {'a': 1});
      expect(messages[1].customData, isNull);
      expect(messages[2].customData, {'b': 2});
    });

    test('same graceful path through loadCachedMessages()', () async {
      expectCustomDataDropped(
          await load([androidMessageJson('hello')], cached: true),
          'cached/hello');
    });

    // Negative controls: unchanged behaviour on valid input.
    test('control: valid JSON object custom data string', () async {
      final messages = await load([androidMessageJson('{"a":1}')]);
      expect(messages, hasLength(1));
      expect(messages.single.customData, {'a': 1});
    });

    test('control: no customData key at all', () async {
      final noCustomData = jsonEncode({
        'code': 'CODE-1',
        'title': 'title',
        'message': 'message',
        'isRead': false,
        'actionParams': '{}',
        'isActionPerformed': false,
      });
      final messages = await load([noCustomData]);
      expect(messages, hasLength(1));
      expect(messages.single.customData, isNull);
    });
  });
}
