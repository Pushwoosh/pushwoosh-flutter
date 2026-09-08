#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
@interface PushwooshPlugin : NSObject<FlutterPlugin, FlutterSceneLifeCycleDelegate>
#else
@interface PushwooshPlugin : NSObject<FlutterPlugin>
#endif

/// Maps a `UIApplication` state to the "the app was not on the foreground" flag that reaches Dart
/// as `fromBackground` and as `payload['foreground']`. Split out from the live state read so the
/// mapping itself is testable - reading `UIApplication.applicationState` under XCTest only ever
/// yields the active case.
+ (BOOL)isNotActiveApplicationState:(UIApplicationState)state;

@end

@interface PushwooshStreamHandler: NSObject<FlutterStreamHandler>
- (void)sendPushNotification:(NSDictionary *)pushNotification onStart:(BOOL)onStart;
@end

@interface DeepLinkStreamHandler: NSObject<FlutterStreamHandler>
- (void)sendDeepLink:(NSString *)url;
@end
