import 'dart:async';

import 'package:flutter/services.dart';

/// Implementation of the Pushwoosh Geozones API for Flutter.
class PushwooshGeozones {
  static const MethodChannel _channel = const MethodChannel('pushwoosh_geozones');

  /// Start location tracking
  static Future<void> startLocationTracking() async {
    await _channel.invokeMethod("startLocationTracking");
  }
  
  /// Stop location tracking
  static void stopLocationTracking() {
    _channel.invokeMethod("stopLocationTracking");
  }

}
