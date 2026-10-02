#import "PushwooshGeozonesPlugin.h"
#import <PushwooshGeozones/PWGeozonesManager.h>

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
      [[PWGeozonesManager sharedManager] startLocationTracking];
      result(nil);
  } else if ([@"stopLocationTracking" isEqualToString:call.method]) {
      [[PWGeozonesManager sharedManager] stopLocationTracking];
      result(nil);
  } else {
      result(FlutterMethodNotImplemented);
  }
}

@end
