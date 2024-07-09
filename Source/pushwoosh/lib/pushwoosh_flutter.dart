import 'dart:async';

import 'package:flutter/services.dart';

typedef Future<dynamic> MessageHandler(Map<String, dynamic> message);

/// Pushwoosh class offers access to the singleton-instance responsible for registering the device with the Pushwoosh, receiving and processing push notifications
class Pushwoosh {
  static const MethodChannel _channel = const MethodChannel('pushwoosh');
  static const EventChannel _receiveChannel = const EventChannel('pushwoosh/receive');
  static const EventChannel _acceptChannel = const EventChannel('pushwoosh/accept');
  static const EventChannel _openChannel = const EventChannel('pushwoosh/deeplink');

  static Pushwoosh _instance = new Pushwoosh();

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