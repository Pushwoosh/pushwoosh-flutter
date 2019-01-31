#import <Flutter/Flutter.h>

@interface PushwooshPlugin : NSObject<FlutterPlugin>
@end

@interface PushwooshStreamHandler: NSObject<FlutterStreamHandler>
- (void)sendPushNotification:(NSDictionary *)pushNotification onStart:(BOOL)onStart;
@end
