#import "PushwooshPlugin.h"
#import "../Library/Pushwoosh.h"
#import "../Library/PWGDPRManager.h"

@interface NSError (FlutterError)

@property(readonly, nonatomic) FlutterError *flutterError;

@end

@implementation NSError (FlutterError)

- (FlutterError *)flutterError {
    return [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %d", (int)self.code]
                               message:self.domain
                               details:self.localizedDescription];
}

@end


@interface PushwooshPlugin () <PushNotificationDelegate>

@property (nonatomic) FlutterResult registerResult;
@property (nonatomic) PushwooshStreamHandler *receiveHandler;
@property (nonatomic) PushwooshStreamHandler *acceptHandler;

@end

@implementation PushwooshPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    PushwooshPlugin* instance = [[PushwooshPlugin alloc] init];
    
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"pushwoosh" binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel *receiveEventChannel = [FlutterEventChannel eventChannelWithName:@"pushwoosh/receive" binaryMessenger:[registrar messenger]];
    instance.receiveHandler = [PushwooshStreamHandler new];
    [receiveEventChannel setStreamHandler:instance.receiveHandler];
    
    FlutterEventChannel *acceptEventChannel = [FlutterEventChannel eventChannelWithName:@"pushwoosh/accept" binaryMessenger:[registrar messenger]];
    instance.acceptHandler = [PushwooshStreamHandler new];
    [acceptEventChannel setStreamHandler:instance.acceptHandler];
}

#pragma mark - FlutterPlugin

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        NSString *appID = [call.arguments objectForKey:@"app_id"];
        
        [PushNotificationManager initializeWithAppCode:appID appName:nil];
        
        if (@available(iOS 10, *)) {
            [UNUserNotificationCenter currentNotificationCenter].delegate = [PushNotificationManager pushManager].notificationCenterDelegate;
        }
        
        [PushNotificationManager pushManager].delegate = self;
        
        result(nil);
    } else if ([@"registerForPushNotifications" isEqualToString:call.method]) {
        _registerResult = result;
        
        [[PushNotificationManager pushManager] registerForPushNotifications];
    } else if ([@"unregisterForPushNotifications" isEqualToString:call.method]) {
        [[PushNotificationManager pushManager] unregisterForPushNotificationsWithCompletion:^(NSError *error) {
            result(error.flutterError);
        }];
    } else if ([@"showForegroundAlert" isEqualToString:call.method]) {
        NSNumber *value = call.arguments;
        
        if (value) { //setter
            [PushNotificationManager pushManager].showPushnotificationAlert = value.boolValue;
            result(nil);
        } else { //getter
            result(@([PushNotificationManager pushManager].showPushnotificationAlert));
        }
    } else if ([@"getHWID" isEqualToString:call.method]) {
        result([[PushNotificationManager pushManager] getHWID]);
    } else if ([@"getPushToken" isEqualToString:call.method]) {
        result([[PushNotificationManager pushManager] getPushToken]);
    } else if ([@"setUserId" isEqualToString:call.method]) {
        NSString *userID = [call.arguments objectForKey:@"userId"];
        [[PWInAppManager sharedManager] setUserId:userID];
        result(nil);
    } else if ([@"setTags" isEqualToString:call.method]) {
        NSDictionary *tags = [call.arguments objectForKey:@"tags"];
        
        [[PushNotificationManager pushManager] setTags:tags withCompletion:^(NSError *error) {
            result(error.flutterError);
        }];
    } else if ([@"getTags" isEqualToString:call.method]) {
        [[PushNotificationManager pushManager] loadTags:^(NSDictionary *tags) {
            result(tags);
        } error:^(NSError *error) {
            result(error.flutterError);
        }];
    } else if ([@"postEvent" isEqualToString:call.method]) {
        NSString *event = call.arguments[0];
        NSDictionary *attributes = call.arguments[1];
        
        [[PWInAppManager sharedManager] postEvent:event withAttributes:attributes completion:^(NSError *error) {
            result(error.flutterError);
        }];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - PushNotificationDelegate

- (void)onDidRegisterForRemoteNotificationsWithDeviceToken:(NSString *)token {
    _registerResult(token);
}

- (void)onDidFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    _registerResult(error.flutterError);
}

- (void)onPushReceived:(PushNotificationManager *)pushManager withNotification:(NSDictionary *)pushNotification onStart:(BOOL)onStart {
    [_receiveHandler sendPushNotification:pushNotification onStart:onStart];
}

- (void)onPushAccepted:(PushNotificationManager *)pushManager withNotification:(NSDictionary *)pushNotification onStart:(BOOL)onStart {
    [_acceptHandler sendPushNotification:pushNotification onStart:onStart];
}


@end

@implementation PushwooshStreamHandler {
    FlutterEventSink _eventSink;
}

- (void)sendPushNotification:(NSDictionary *)pushNotification onStart:(BOOL)onStart {
    if (!_eventSink) {
        return;
    }
    
    NSDictionary *pushDict = pushNotification[@"aps"];
    NSString *title = nil;
    NSString *message = nil;
    id alertMsg = pushDict[@"alert"];
    
    if ([alertMsg isKindOfClass:[NSDictionary class]]) {
        title = alertMsg[@"title"];
        message = alertMsg[@"body"];
    } else if ([alertMsg isKindOfClass:[NSString class]]) {
        message = alertMsg;
    }
    
    NSDictionary *customData = [[PushNotificationManager pushManager] getCustomPushDataAsNSDict:pushNotification];
    
    NSMutableDictionary *messageDict = [NSMutableDictionary new];
    
    if (title) {
        messageDict[@"title"] = title;
    }
    
    if (message) {
        messageDict[@"message"] = message;
    }
    
    if (customData) {
        messageDict[@"customData"] = customData;
    }
    
    messageDict[@"fromBackground"] = @(onStart);
    
    messageDict[@"payload"] = pushNotification;
    
    _eventSink(messageDict);
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end

@implementation UIApplication (InternalPushRuntime)

- (BOOL)pushwooshUseRuntimeMagic {
    return YES;
}

@end
