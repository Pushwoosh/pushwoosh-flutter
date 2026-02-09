/// Pushwoosh Flutter Plugin
///
/// Cross-platform push notifications, In-App messaging, and more for Flutter applications.
///
/// ## Installation
///
/// Add to your `pubspec.yaml`:
///
/// ```yaml
/// dependencies:
///   pushwoosh_flutter: ^2.3.15
/// ```
///
/// ### Optional plugins
///
/// ```yaml
/// dependencies:
///   pushwoosh_geozones: ^2.3.15   # Location-based push notifications
///   pushwoosh_inbox: ^2.3.15      # Message Inbox UI
/// ```
///
/// ### iOS Setup
///
/// ```bash
/// cd ios && pod install
/// ```
///
/// ### Android Setup
///
/// 1. Configure Firebase project in Firebase Console
/// 2. Place `google-services.json` into `android/app/` folder
///
/// ## Quick Start
///
/// ```dart
/// import 'package:pushwoosh_flutter/pushwoosh_flutter.dart';
///
/// void main() {
///   runApp(MyApp());
///
///   Pushwoosh.initialize({
///     "app_id": "YOUR_PUSHWOOSH_APP_ID",
///     "sender_id": "YOUR_FCM_SENDER_ID"
///   });
///
///   Pushwoosh.getInstance.onPushReceived.listen((event) {
///     print("Push received: ${event.pushwooshMessage.payload}");
///   });
///
///   Pushwoosh.getInstance.onPushAccepted.listen((event) {
///     print("Push opened: ${event.pushwooshMessage.payload}");
///   });
///
///   Pushwoosh.getInstance.registerForPushNotifications();
/// }
/// ```
///
/// ## Common Use Cases
///
/// ### Set User Tags
///
/// ```dart
/// await Pushwoosh.getInstance.setTags({
///   "username": "john_doe",
///   "age": 25,
///   "interests": ["sports", "tech"]
/// });
///
/// Map tags = await Pushwoosh.getInstance.getTags();
/// ```
///
/// ### User Identification
///
/// ```dart
/// Pushwoosh.getInstance.setUserId("user_12345");
/// ```
///
/// ### Post Events for In-App Messages
///
/// ```dart
/// await Pushwoosh.getInstance.postEvent("purchase_complete", {
///   "productName": "Premium Plan",
///   "amount": "9.99"
/// });
/// ```
///
/// ### Deep Link Handling
///
/// ```dart
/// Pushwoosh.getInstance.onDeepLinkOpened.listen((String deepLink) {
///   print("Deep link opened: $deepLink");
/// });
/// ```
///
/// ### Multi-channel Communication
///
/// ```dart
/// await Pushwoosh.getInstance.setEmail("user@example.com");
/// await Pushwoosh.getInstance.setEmails(["user@example.com", "work@example.com"]);
/// Pushwoosh.getInstance.registerSmsNumber("+1234567890");
/// Pushwoosh.getInstance.registerWhatsappNumber("+1234567890");
/// ```
///
/// ### Badge Management
///
/// ```dart
/// Pushwoosh.getInstance.setApplicationIconBadgeNumber(5);
/// int badge = await Pushwoosh.getInstance.getApplicationIconBadgeNumber;
/// Pushwoosh.getInstance.addToApplicationIconBadgeNumber(1);
/// ```
///
/// ### Live Activities (iOS)
///
/// ```dart
/// await Pushwoosh.getInstance.defaultSetup();
/// await Pushwoosh.getInstance.defaultStart(
///   "delivery_123",
///   {"driverName": "John"},
///   {"status": "On the way"}
/// );
/// await Pushwoosh.getInstance.stopLiveActivity();
/// ```
///
/// ### JavaScript Interface for In-App Messages
///
/// ```dart
/// await Pushwoosh.getInstance.addJavascriptInterface('flutter', {
///   'onButtonTap': (Map<String, dynamic> args) {
///     print("Button tapped: $args");
///     return "OK";
///   },
///   'getUserData': (Map<String, dynamic> args) {
///     return {"name": "John", "premium": true};
///   }
/// });
/// ```
///
/// ## Configuration Parameters
///
/// | Parameter    | Description                                    |
/// |------------- |------------------------------------------------|
/// | `app_id`     | Your Pushwoosh Application ID (required)       |
/// | `sender_id`  | FCM/GCM Sender ID for Android (required)       |
///
/// ## Push Events
///
/// | Stream             | Type        | Description                               |
/// |--------------------|-------------|-------------------------------------------|
/// | `onPushReceived`   | `PushEvent` | Fires when push notification is received  |
/// | `onPushAccepted`   | `PushEvent` | Fires when push notification is opened    |
/// | `onDeepLinkOpened` | `String`    | Fires when a deep link URL is opened      |
///
/// ## Links
///
/// - Documentation: https://docs.pushwoosh.com/platform-docs/pushwoosh-sdk/cross-platform-frameworks/flutter/integrating-flutter-plugin
/// - GitHub: https://github.com/Pushwoosh/pushwoosh-flutter
/// - Support: https://support.pushwoosh.com/
library pushwoosh_flutter;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

typedef Future<dynamic> MessageHandler(Map<String, dynamic> message);

/// Pushwoosh class offers access to the singleton-instance responsible for registering the device with the Pushwoosh, receiving and processing push notifications
class Pushwoosh {
  static const MethodChannel _channel = const MethodChannel('pushwoosh');
  static const EventChannel _receiveChannel = const EventChannel('pushwoosh/receive');
  static const EventChannel _acceptChannel = const EventChannel('pushwoosh/accept');
  static const EventChannel _openChannel = const EventChannel('pushwoosh/deeplink');
  static const EventChannel _jsInterfaceChannel = const EventChannel('pushwoosh/jsinterface');

  static Pushwoosh _instance = new Pushwoosh();

  static final Map<String, Map<String, Function>> _registeredInterfaces = {};

  /// Returns the default (first initialized) instance of the Pushwoosh.
  static Pushwoosh get getInstance => _instance;

  Future<bool> get showForegroundAlert async => await _channel.invokeMethod("showForegroundAlert");

  /// Show push notifications alert when push notification is received while the app is running, default is `true`
  void setShowForegroundAlert(bool value) {
    _channel.invokeMethod("showForegroundAlert", value);
  }

  /// initialize Pushwoosh SDK.
  /// Example params: {"app_id": "application id", "sender_id": "GCM/FCM sender id"}
  static void initialize(Map params) {
    _channel.invokeMethod('initialize', params);
  }

  /// Registers device for push notifications
  Future<String?> registerForPushNotifications() async {
    String? token = await _channel.invokeMethod('registerForPushNotifications');
    return token;
  }

  /// Unregisters device from push notifications
  Future<String?> unregisterForPushNotifications() async {
    return await _channel.invokeMethod("unregisterForPushNotifications");
  }

  /// Get the [Stream] of received [PushwooshMessage].
  Stream<PushEvent> get onPushReceived =>
      _receiveChannel.receiveBroadcastStream().map((dynamic event) => _toPushwooshMessage(event.cast<dynamic, dynamic>()));

  /// Get the [Stream] of accepted [PushwooshMessage].
  Stream<PushEvent> get onPushAccepted =>
      _acceptChannel.receiveBroadcastStream().map((dynamic event) => _toPushwooshMessage(event.cast<dynamic, dynamic>()));

  /// Get the [Stream] of opened deep links
  Stream<String> get onDeepLinkOpened =>
      _openChannel.receiveBroadcastStream().cast<String>();

  PushEvent _toPushwooshMessage(Map<dynamic, dynamic> map) {
    var pushwooshMessage = new PushwooshMessage(map['title'], map['message'], map['payload'], map['customData']);
    return new PushEvent(pushwooshMessage, map['fromBackground']);
  }

  /// Pushwoosh HWID associated with current device
  Future<String> get getHWID async => await _channel.invokeMethod("getHWID");

  /// Push notification token or null if device is not registered yet.
  Future<String?> get getPushToken async => await _channel.invokeMethod("getPushToken");
  
  /// Set User indentifier. This could be Facebook ID, username or email, or any other user ID.
  /// This allows data and events to be matched across multiple user devices.
  void setUserId(String userId){
     _channel.invokeMethod("setUserId", {"userId" : userId});
  }

  /// Post events for In-App Messages. This can trigger In-App message HTML as specified in Pushwoosh Control Panel.
  /// [event] is string name of the event
  /// [attributes] is map contains additional event attributes
  Future<void> postEvent(String event, Map<String, dynamic> attributes) async {
    await _channel.invokeMethod("postEvent", [event, attributes]);
  }

  /// Associates device with given [tags]. If setTags request fails tags will be resent on the next application launch.
  Future<void> setTags(Map tags) async {
    await _channel.invokeMethod("setTags", {"tags" : tags});
  }

  /// Gets tags associated with current device
  Future<Map<dynamic, dynamic>> getTags() async {
    return await _channel.invokeMethod("getTags") ?? {};
  }

  /// Start Live Activity with ActivityId
  /// [token] live activity token
  /// [activityId] activity ID
  Future<void>  startLiveActivityWithToken(String token, String activityId) async {
    await _channel.invokeMethod("startLiveActivityWithToken", {"token" : token, "activityId" : activityId});
  }

  /// Stop Live Activity
  Future<void> stopLiveActivity() async {
    _channel.invokeMethod("stopLiveActivity");
  }

  /// Default setup Live Activity
  Future<void> defaultSetup() async {
    await _channel.invokeMethod("defaultSetup");
  }

  /// Default start Live Activity
  /// [activityId] activity ID
  /// [attributes] attributes 
  /// [content] content 
  Future<void> defaultStart(String activityId, Map<String, dynamic> attributes, Map<String, dynamic> content) async {
    await _channel.invokeMethod("defaultStart", {"activityId": activityId, "attributes": attributes, "content": content});
  }

	/// Allows multiple notifications to be displayed in notification center.
	/// By default SDK uses single notification mode where each notification overrides previously displayed notification.
	/// [on] enable multi/single notification mode
  void setMultiNotificationMode(bool on) {
    _channel.invokeMethod("setMultiNotificationMode", {"on" : on});
  }

  void requestProvisionalAuthOptions() {
    _channel.invokeMethod("requestProvisionalAuthOptions");
  }

  void setApplicationIconBadgeNumber(int badges) {
    _channel.invokeMethod("setApplicationIconBadgeNumber", {"badges": badges});
  }

  Future<int> get getApplicationIconBadgeNumber async => await _channel.invokeMethod("getApplicationIconBadgeNumber");

  void addToApplicationIconBadgeNumber(int badges) {
    _channel.invokeMethod("addToApplicationIconBadgeNumber",  {"badges": badges});
  }

  void enableHuaweiNotifications() {
    _channel.invokeMethod("enableHuaweiNotifications");
  }

  void setLanguage(String language) {
    _channel.invokeMethod("setLanguage", {"language" : language});
  }

  /// Register email associated to the current user.
  /// Email should be a string and cannot be null or empty.
  Future<void> setEmail(String email) async {
    await _channel.invokeMethod("setEmail", {"email": email});
  }

  /// Register list of emails associated to the current user.
  Future<void> setEmails(List<String> emails) async {
    await _channel.invokeMethod("setEmails", {"emails": emails});
  }

  /// Set user identifier and register emails associated to the user.
  /// userID can be Facebook ID or any other user ID.
  /// This allows data and events to be matched across multiple user devices.
  Future<void> setUserEmails(String userId, List<String> emails) async {
    await _channel.invokeMethod("setUserEmails", {
      "userId": userId,
      "emails": emails
    });
  }

  void registerSmsNumber(String number) {
    _channel.invokeMethod("registerSmsNumber", {"number": number});
  }

  void registerWhatsappNumber(String number) {
    _channel.invokeMethod("registerWhatsappNumber", {"number": number});
  }

  /// Starts server communication with Pushwoosh.
  ///
  /// Calls the native method `startServerCommunication` through MethodChannel.
  /// Typically used to resume communication with the server after it was paused.
  void startServerCommunication() {
    _channel.invokeMethod("startServerCommunication");
  }

  /// Stops server communication with Pushwoosh.
  ///
  /// Calls the native method `stopServerCommunication` through MethodChannel.
  /// Typically used to temporarily suspend communication with the server.
  void stopServerCommunication() {
    _channel.invokeMethod("stopServerCommunication");
  }

  Stream<Map<String, dynamic>> get onJavascriptInterfaceCall =>
      _jsInterfaceChannel.receiveBroadcastStream().map((event) => Map<String, dynamic>.from(event));

  /// Register a JavaScript interface with Flutter method handlers
  /// [interfaceName] - name that will be available in JavaScript as window.[interfaceName]
  /// [methods] - map of method names to their Flutter implementations
  Future<void> addJavascriptInterface(String interfaceName, Map<String, Function> methods) async {
    try {
      _registeredInterfaces[interfaceName] = methods;
      
      await _channel.invokeMethod("addJavascriptInterface", {
        "interfaceName": interfaceName,
        "methodNames": methods.keys.toList()
      });
      
      if (_registeredInterfaces.length == 1) {
        _startListeningToJavaScriptCalls();
      }
    } catch (e) {
      throw Exception("Failed to add JavaScript interface: $e");
    }
  }

  /// Remove a JavaScript interface
  /// [interfaceName] - name of the interface to remove
  Future<void> removeJavascriptInterface(String interfaceName) async {
    try {
      _registeredInterfaces.remove(interfaceName);
      await _channel.invokeMethod("removeJavascriptInterface", {
        "interfaceName": interfaceName
      });
    } catch (e) {
      throw Exception("Failed to remove JavaScript interface: $e");
    }
  }
  void _startListeningToJavaScriptCalls() {
    onJavascriptInterfaceCall.listen((callData) async {
      try {
        String interfaceName = callData['interfaceName']?.toString() ?? '';
        String methodName = callData['methodName']?.toString() ?? '';
        String callbackId = callData['callbackId']?.toString() ?? '';
        
        Map<String, dynamic> arguments = {};
        if (callData['arguments'] != null) {
          try {
            arguments = Map<String, dynamic>.from(callData['arguments'] as Map);
          } catch (e) {
          }
        }
        
        if (_registeredInterfaces.containsKey(interfaceName) &&
            _registeredInterfaces[interfaceName]!.containsKey(methodName)) {
          
          Function method = _registeredInterfaces[interfaceName]![methodName]!;
          
          try {
            dynamic result = await method(arguments);
            
            await _channel.invokeMethod("sendJavaScriptResponse", {
              "callbackId": callbackId,
              "success": true,
              "data": result
            });
          } catch (e) {
            await _channel.invokeMethod("sendJavaScriptResponse", {
              "callbackId": callbackId,
              "success": false,
              "error": e.toString()
            });
          }
        } else {
          await _channel.invokeMethod("sendJavaScriptResponse", {
            "callbackId": callbackId,
            "success": false,
            "error": "Method $methodName not found in interface $interfaceName"
          });
        }
      } catch (e) {
          print("Pushwoosh JS Interface: Failed to parse arguments. Error: $e");
      }
    });
  }
}

class PushEvent{
  final PushwooshMessage pushwooshMessage;
  final bool? fromBackground;

  PushEvent(this.pushwooshMessage, this.fromBackground);
}

class PushwooshMessage {
  final String? title;
  final String? message;
  final Map<dynamic, dynamic> payload;
  final Map<dynamic, dynamic>? customData;

  PushwooshMessage(this.title, this.message, this.payload, this.customData);
}