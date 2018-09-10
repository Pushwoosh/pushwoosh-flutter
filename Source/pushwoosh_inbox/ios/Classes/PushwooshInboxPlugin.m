#import "PushwooshInboxPlugin.h"
#import <PushwooshInboxUI/PushwooshInboxUI.h>

@implementation PushwooshInboxPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"pushwoosh_inbox"
            binaryMessenger:[registrar messenger]];
  PushwooshInboxPlugin* instance = [[PushwooshInboxPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
