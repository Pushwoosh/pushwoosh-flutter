// Regression guard: a malformed `actionParams` degrades to null and the message
// still loads, instead of throwing out of loadMessages()/loadCachedMessages().
// Crash signatures and provenance: repro crash-flutter-dart-inbox-actionparams-jsondecode.
//
// Feeds the REAL pipeline: a real MethodChannel('pushwoosh_inbox') with a mocked
// native handler, and the message JSON built exactly the way the native plugins
// build it (android: actionParams as a raw String; ios: as a dictionary).
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushwoosh_inbox/pushwoosh_inbox.dart';

const MethodChannel _channel = MethodChannel('pushwoosh_inbox');

/// Mirrors android PushwooshInboxPlugin.toJson():
/// `.put("actionParams", message.getActionParams())` — the raw, unvalidated
/// String straight out of the inbox DB column (InboxDbHelper.java:442).
String androidMessageJson(String rawActionParams, {String? customData}) {
  final Map<String, dynamic> m = {
    'code': 'CODE-1',
    'title': 'title',
    'imageUrl': '',
    'message': 'message',
    'sendDate': '2026-08-13T10:00:00+0000',
    'messageType': 1,
    'bannerUrl': '',
    'isRead': false,
    'actionParams': rawActionParams, // raw string, no validation
    'isActionPerformed': false,
  };
  if (customData != null) m['customData'] = customData;
  return jsonEncode(m);
}

/// Mirrors ios PushwooshInboxPlugin.toJson(): actionParams goes in as a
/// DICTIONARY ([self dictionaryOrEmpty:message.actionParams]).
String iosMessageJson(Map<String, dynamic> actionParams) {
  return jsonEncode({
    'type': 1,
    'imageUrl': '',
    'code': 'CODE-1',
    'title': 'title',
    'message': 'message',
    'sendDate': '2026-08-13T10:00:00+0000',
    'isRead': false,
    'isActionPerformed': false,
    'actionParams': actionParams,
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

/// The message is delivered intact, only actionParams is dropped.
void expectActionParamsDropped(List<InboxMessage> messages, String label) {
  expect(messages, hasLength(1), reason: '$label: message was lost');
  expect(messages.single.actionParams, isNull,
      reason: '$label: expected actionParams to degrade to null');
  expect(messages.single.code, 'CODE-1', reason: '$label: code mangled');
  expect(messages.single.title, 'title', reason: '$label: title mangled');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('inbox actionParams jsonDecode (android string path)', () {
    // --- family 1: string is not valid JSON at all (was FormatException) ---

    test('mode 1: non-JSON garbage "hello"', () async {
      expectActionParamsDropped(
          await load([androidMessageJson('hello')]), 'android/hello');
    });

    test('mode 1: empty string ""', () async {
      expectActionParamsDropped(
          await load([androidMessageJson('')]), 'android/empty');
    });

    test('mode 1: truncated JSON object', () async {
      expectActionParamsDropped(
          await load([androidMessageJson('{"b":"https://x.com"')]),
          'android/truncated');
    });

    test('mode 1: html error page instead of params', () async {
      expectActionParamsDropped(
          await load([androidMessageJson('<html>oops</html>')]),
          'android/html');
    });

    // --- family 2: valid JSON, wrong shape (was TypeError on the field cast) ---

    test('mode 2: JSON array "[1,2]"', () async {
      expectActionParamsDropped(
          await load([androidMessageJson('[1,2]')]), 'android/array');
    });

    test('mode 2: JSON number "42"', () async {
      expectActionParamsDropped(
          await load([androidMessageJson('42')]), 'android/number');
    });

    test('mode 2: JSON string "\\"b\\""', () async {
      expectActionParamsDropped(
          await load([androidMessageJson('"b"')]), 'android/string');
    });

    test('mode 2: JSON bool "true"', () async {
      expectActionParamsDropped(
          await load([androidMessageJson('true')]), 'android/bool');
    });

    // --- blast radius and the second entry point ---

    test('blast radius: one bad message no longer kills the list', () async {
      final messages = await load([
        androidMessageJson('{"l":"https://a.com"}'),
        androidMessageJson('hello'),
        androidMessageJson('{"l":"https://b.com"}'),
      ]);
      expect(messages, hasLength(3),
          reason:
              'android/one-bad-of-three: the host must still get all three');
      expect(messages[0].actionParams, {'l': 'https://a.com'});
      expect(messages[1].actionParams, isNull);
      expect(messages[2].actionParams, {'l': 'https://b.com'});
    });

    test('same graceful path through loadCachedMessages()', () async {
      expectActionParamsDropped(
          await load([androidMessageJson('hello')], cached: true),
          'cached/hello');
    });

    // --- negative controls: unchanged behaviour on valid input ---

    test('control: valid JSON object string', () async {
      final messages =
          await load([androidMessageJson('{"l":"https://example.com"}')]);
      expect(messages, hasLength(1));
      expect(messages.single.actionParams, {'l': 'https://example.com'});
    });

    test('control: literal "null" (what a JSON null becomes)', () async {
      final messages =
          await load([androidMessageJson('null', customData: '{"a":1}')]);
      expect(messages, hasLength(1));
      expect(messages.single.actionParams, isNull);
      // pinned so an always-null guard cannot pass this control
      expect(messages.single.customData, {'a': 1});
    });

    test('control: actionParams key absent', () async {
      final noParams = jsonEncode({
        'code': 'CODE-1',
        'title': 'title',
        'message': 'message',
        'isRead': false,
        'isActionPerformed': false,
      });
      final messages = await load([noParams]);
      expect(messages, hasLength(1));
      expect(messages.single.actionParams, isNull);
    });

    test('control: ios shape — actionParams is a dictionary', () async {
      final messages = await load([
        iosMessageJson(<String, dynamic>{'l': 'https://example.com'})
      ]);
      expect(messages, hasLength(1));
      expect(messages.single.actionParams, {'l': 'https://example.com'});
    });

    // --- the two guarded slots are independent: each degrades on its own while
    // the other still parses.

    test('isolation: bad customData leaves actionParams parsed', () async {
      final messages = await load([
        androidMessageJson('{"u":"hello"}', customData: 'hello'),
      ]);
      expect(messages, hasLength(1));
      expect(messages.single.actionParams, {'u': 'hello'},
          reason: 'actionParams must survive a broken neighbour');
      expect(messages.single.customData, isNull);
    });

    test('isolation: bad actionParams leaves customData parsed', () async {
      final messages = await load([
        androidMessageJson('hello', customData: '{"a":1}'),
      ]);
      expect(messages, hasLength(1));
      expect(messages.single.actionParams, isNull);
      expect(messages.single.customData, {'a': 1},
          reason: 'customData must survive a broken neighbour');
    });
  });
}
