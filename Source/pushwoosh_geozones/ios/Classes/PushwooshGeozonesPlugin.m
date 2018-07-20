#import "PushwooshGeozonesPlugin.h"
#import <Pushwoosh/PushNotificationManager.h>

@implementation PushwooshGeozonesPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"pushwoosh_geozones"
            binaryMessenger:[registrar messenger]];
  PushwooshGeozonesPlugin* instance = [[PushwooshGeozonesPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"startLocationTracking" isEqualToString:call.method]) {
      [[PushNotificationManager pushManager] startLocationTracking];
      result(nil);
  } else if ([@"stopLocationTracking" isEqualToString:call.method]) {
      [[PushNotificationManager pushManager] stopLocationTracking];
      result(nil);
  } else {
      result(FlutterMethodNotImplemented);
  }
}

@end
