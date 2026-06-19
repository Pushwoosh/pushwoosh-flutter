#import <Flutter/Flutter.h>

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
@interface PushwooshPlugin : NSObject<FlutterPlugin, FlutterSceneLifeCycleDelegate>
@end
#else
@interface PushwooshPlugin : NSObject<FlutterPlugin>
@end
#endif

@interface PushwooshStreamHandler: NSObject<FlutterStreamHandler>
- (void)sendPushNotification:(NSDictionary *)pushNotification onStart:(BOOL)onStart;
@end

@interface DeepLinkStreamHandler: NSObject<FlutterStreamHandler>
- (void)sendDeepLink:(NSString *)url;
@end
