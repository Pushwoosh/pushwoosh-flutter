#import "PushwooshPlugin.h"
#import "../Library/Pushwoosh.h"
#import "../Library/PWGDPRManager.h"
#import "../Library/PWInAppManager.h"
#import "../Library/PushNotificationManager.h"

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
@property (nonatomic) DeepLinkStreamHandler *openHandler;
@property (nonatomic) NSString *cachedDeepLink;

@end

@implementation PushwooshPlugin

- (BOOL)application:(UIApplication *)application
        openURL:(NSURL *)url
        options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    NSString *urlString = [url absoluteString];
    if (self.openHandler != nil) {
        [self.openHandler sendDeepLink:urlString];
    } else {
        self.cachedDeepLink = urlString;
    }
    return YES;
}
    
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    PushwooshPlugin* instance = [[PushwooshPlugin alloc] init];
    
    [PushNotificationManager pushManager].delegate = instance;
    
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"pushwoosh" binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel *receiveEventChannel = [FlutterEventChannel eventChannelWithName:@"pushwoosh/receive" binaryMessenger:[registrar messenger]];
    instance.receiveHandler = [PushwooshStreamHandler new];
    [receiveEventChannel setStreamHandler:instance.receiveHandler];
    
    FlutterEventChannel *acceptEventChannel = [FlutterEventChannel eventChannelWithName:@"pushwoosh/accept" binaryMessenger:[registrar messenger]];
    instance.acceptHandler = [PushwooshStreamHandler new];
    [acceptEventChannel setStreamHandler:instance.acceptHandler];
    
    FlutterEventChannel *openEventChannel = [FlutterEventChannel eventChannelWithName:@"pushwoosh/deeplink" binaryMessenger:[registrar messenger]];
    instance.openHandler = [DeepLinkStreamHandler new];
    [openEventChannel setStreamHandler:instance.openHandler];
    
    if (instance.cachedDeepLink != nil) {
        [instance.openHandler sendDeepLink:instance.cachedDeepLink];
        instance.cachedDeepLink = nil;
    }
    
    [registrar addApplicationDelegate:instance];
}

#pragma mark - FlutterPlugin

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        NSString *appID = [call.arguments objectForKey:@"app_id"];
        
        [PushNotificationManager initializeWithAppCode:appID appName:nil];
        
        if (@available(iOS 10, *)) {
            [UNUserNotificationCenter currentNotificationCenter].delegate = [PushNotificationManager pushManager].notificationCenterDelegate;
        }
        
        [[PushNotificationManager pushManager] sendAppOpen];
        
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
    } else if([@"setLanguage" isEqualToString:call.method]) {
        NSString *language = [call.arguments objectForKey:@"language"];
        [[PushNotificationManager pushManager] setLanguage:language];
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
    } else if ([@"setMultiNotificationMode" isEqualToString:call.method]) {
        //Stub, method is not available for iOS
    } else if ([@"enableHuaweiNotifications" isEqualToString:call.method]) {
        //Stub, method is not available for iOS
    } else if ([@"addToApplicationIconBadgeNumber" isEqualToString:call.method]) {
        NSInteger badge = [[call.arguments objectForKey:@"badges"] integerValue];
        [UIApplication sharedApplication].applicationIconBadgeNumber += badge;
    } else if ([@"setApplicationIconBadgeNumber" isEqualToString:call.method]) {
        NSInteger badge = [[call.arguments objectForKey:@"badges"] integerValue];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];
    } else if ([@"getApplicationIconBadgeNumber" isEqualToString:call.method]) {
        NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber;
        result([NSNumber numberWithInteger:badge]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - PushNotificationDelegate

- (void)onDidRegisterForRemoteNotificationsWithDeviceToken:(NSString *)token {
    if (_registerResult) {
        _registerResult(token);
    }
}

- (void)onDidFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (_registerResult) {
        _registerResult(error.flutterError);
    }
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
    NSDictionary *_startPushNotification;
}

- (void)sendPushNotification:(NSDictionary *)pushNotification onStart:(BOOL)onStart {
    if (!_eventSink) {
        //flutter app is not initialized yet, so save push notification, we send it to listener later
        _startPushNotification = pushNotification;
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
    
    if (_startPushNotification) {
        [self sendPushNotification:_startPushNotification onStart:YES];
        _startPushNotification = nil;
    }
    
    return nil;
}

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end

@implementation DeepLinkStreamHandler {
    FlutterEventSink _eventSink;
    NSString *_cachedDeepLink;
}
    
- (void)sendDeepLink:(NSString *)deepLink {
    if (!_eventSink) {
        //flutter app is not initialized yet, caching deep link to send it later
        _cachedDeepLink = deepLink;
        return;
    }
    
    _eventSink(deepLink);
}
    
- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    
    if (_cachedDeepLink) {
        [self sendDeepLink:_cachedDeepLink];
        _cachedDeepLink = nil;
    }
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
