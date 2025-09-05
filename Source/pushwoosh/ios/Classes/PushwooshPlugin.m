#import "PushwooshPlugin.h"
#import <PushwooshFramework/PushwooshFramework.h>
#import <PushwooshFramework/PWGDPRManager.h>
#import <PushwooshFramework/PWInAppManager.h>
#import <PushwooshFramework/PushNotificationManager.h>
#import <PushwooshFramework/PushwooshFramework-Swift.h>
#import <PushwooshLiveActivities/PushwooshLiveActivities.h>

#import <UserNotifications/UserNotifications.h>
#import <objc/runtime.h>

#define kPushwooshPluginImplementationInfoPlistKey @"Pushwoosh_PLUGIN_NOTIFICATION_HANDLER"

static IMP pw_original_didReceiveRemoteNotification_Imp;

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
@property (nonatomic) NSString *lastPushwooshHash;

@end

@implementation PushwooshPlugin {
    API_AVAILABLE(ios(10))
    __weak id<UNUserNotificationCenterDelegate> _originalNotificationCenterDelegate;
    API_AVAILABLE(ios(10))
    struct {
        unsigned int willPresentNotification : 1;
        unsigned int didReceiveNotificationResponse : 1;
        unsigned int openSettingsForNotification : 1;
    } _originalNotificationCenterDelegateResponds;
}

+ (instancetype)sharedInstance {
    static PushwooshPlugin *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

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
    PushwooshPlugin* instance = [PushwooshPlugin sharedInstance];
    [PushwooshPlugin swizzleNotificationSettingsHandler];

    if (![PushwooshPlugin getPluginImplementationInfoPlistKey]) {
        [PushNotificationManager pushManager].delegate = instance;
    }

    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"pushwoosh" binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:channel];

    if (!instance.receiveHandler) {
        FlutterEventChannel *receiveEventChannel = [FlutterEventChannel eventChannelWithName:@"pushwoosh/receive" binaryMessenger:[registrar messenger]];
        instance.receiveHandler = [PushwooshStreamHandler new];
        [receiveEventChannel setStreamHandler:instance.receiveHandler];
    }

    if (!instance.acceptHandler) {
        FlutterEventChannel *acceptEventChannel = [FlutterEventChannel eventChannelWithName:@"pushwoosh/accept" binaryMessenger:[registrar messenger]];
        instance.acceptHandler = [PushwooshStreamHandler new];
        [acceptEventChannel setStreamHandler:instance.acceptHandler];
    }

    if (!instance.openHandler) {
        FlutterEventChannel *openEventChannel = [FlutterEventChannel eventChannelWithName:@"pushwoosh/deeplink" binaryMessenger:[registrar messenger]];
        instance.openHandler = [DeepLinkStreamHandler new];
        [openEventChannel setStreamHandler:instance.openHandler];
    }

    if (instance.cachedDeepLink != nil) {
        [instance.openHandler sendDeepLink:instance.cachedDeepLink];
        instance.cachedDeepLink = nil;
    }

    [registrar addApplicationDelegate:instance];
}

+ (void) swizzleNotificationSettingsHandler {
    if ([UIApplication sharedApplication].delegate == nil) {
        return;
    }
    
    static Class appDelegateClass = nil;
    
    //do not swizzle the same class twice
    id delegate = [UIApplication sharedApplication].delegate;
    if(appDelegateClass == [delegate class]) {
        return;
    }
        
    Class delegateClass = [delegate class];
    Method originalMethod = class_getInstanceMethod(delegateClass, @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:));
    pw_original_didReceiveRemoteNotification_Imp = method_setImplementation(originalMethod, (IMP)_replacement_didReceiveRemoteNotification);
}

void _replacement_didReceiveRemoteNotification(id self, SEL _cmd, UIApplication * application, NSDictionary * userInfo, void (^completionHandler)(UIBackgroundFetchResult)) {
    // Prevent duplicate calls to the completionHandler
    __block BOOL completionHandlerCalled = NO;

    // Define a safe completion handler to ensure it is called only once
    void (^safeCompletionHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult result) {
        if (!completionHandlerCalled) {
            completionHandlerCalled = YES;
            completionHandler(result);
        }
    };

    ((void(*)(id, SEL, UIApplication *, NSDictionary *, void(^)(UIBackgroundFetchResult)))pw_original_didReceiveRemoteNotification_Imp)(
        self, _cmd, application, userInfo, safeCompletionHandler
    );

    [[PushNotificationManager pushManager] handlePushReceived:userInfo];

    // Determine the appropriate fetch result based on userInfo content
    UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultNoData;

    if (userInfo) {
        if (userInfo[@"data"]) {
            NSDictionary *data = userInfo[@"data"];
            if (data && data.count > 0) {
                fetchResult = UIBackgroundFetchResultNewData;
            } else {
                fetchResult = UIBackgroundFetchResultNoData;
            }
        } else {
            fetchResult = UIBackgroundFetchResultNoData;
        }
    } else {
        fetchResult = UIBackgroundFetchResultFailed;
    }

    // Ensure the completion handler is called with the calculated fetch result
    safeCompletionHandler(fetchResult);
}

#pragma mark - FlutterPlugin

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        NSString *appID = [call.arguments objectForKey:@"app_id"];
        
        [PushNotificationManager initializeWithAppCode:appID appName:nil];
                
        if (@available(iOS 10, *)) {
            BOOL shouldReplaceDelegate = YES;
            UNUserNotificationCenter *notificationCenter =
            [UNUserNotificationCenter currentNotificationCenter];
            
            if (notificationCenter.delegate != nil) {
#if !TARGET_OS_OSX
                if ([notificationCenter.delegate conformsToProtocol:@protocol(FlutterAppLifeCycleProvider)]) {
                    shouldReplaceDelegate = NO;
                }
#endif
                if (shouldReplaceDelegate) {
                    _originalNotificationCenterDelegate = notificationCenter.delegate;
                    _originalNotificationCenterDelegateResponds.openSettingsForNotification =
                    (unsigned int)[_originalNotificationCenterDelegate
                                   respondsToSelector:@selector(userNotificationCenter:openSettingsForNotification:)];
                    _originalNotificationCenterDelegateResponds.willPresentNotification =
                    (unsigned int)[_originalNotificationCenterDelegate
                                   respondsToSelector:@selector(userNotificationCenter:
                                                                willPresentNotification:withCompletionHandler:)];
                    _originalNotificationCenterDelegateResponds.didReceiveNotificationResponse =
                    (unsigned int)[_originalNotificationCenterDelegate
                                   respondsToSelector:@selector(userNotificationCenter:
                                                                didReceiveNotificationResponse:withCompletionHandler:)];
                }
            }
            
            if (shouldReplaceDelegate) {
                __strong PushwooshPlugin<UNUserNotificationCenterDelegate> *strongSelf = self;
                notificationCenter.delegate = strongSelf;
            }
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
    } else if([@"setEmail" isEqualToString:call.method]) {
        NSString *email = [call.arguments objectForKey:@"email"];
        [[Pushwoosh sharedInstance] setEmail:email completion:^(NSError *error) {
            result(error.flutterError);
        }];
    } else if([@"setEmails" isEqualToString:call.method]) {
        NSArray *emails = [call.arguments objectForKey:@"emails"];
        [[Pushwoosh sharedInstance] setEmails:emails completion:^(NSError *error) {
            result(error.flutterError);
        }];
    } else if([@"setUserEmails" isEqualToString:call.method]) {
        NSString *userId = [call.arguments objectForKey:@"userId"];
        NSArray *emailsArray = [call.arguments objectForKey:@"emails"];
        [[Pushwoosh sharedInstance] setUser:userId emails:emailsArray completion:^(NSError *error) {
            result(error.flutterError);
        }];
    } else if([@"setTags" isEqualToString:call.method]) {
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
    } else if ([@"requestProvisionalAuthOptions" isEqualToString:call.method]) {
        if (@available(iOS 12.0, *)) {
            [Pushwoosh sharedInstance].additionalAuthorizationOptions = UNAuthorizationOptionProvisional;
        }
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
    } else if ([@"startLiveActivityWithToken" isEqualToString:call.method]) {
        NSString *token = [call.arguments objectForKey:@"token"];
        NSString *activityId = [call.arguments objectForKey:@"activityId"];
        [[Pushwoosh sharedInstance] startLiveActivityWithToken:token activityId:activityId completion:^(NSError * _Nullable error) {
            result(error.flutterError);
        }];
    } else if ([@"stopLiveActivity" isEqualToString:call.method]) {
        [[Pushwoosh sharedInstance] stopLiveActivityWithCompletion:^(NSError * _Nullable error) {
            result(error.flutterError);
        }];
    } else if ([@"registerSmsNumber" isEqualToString:call.method]) {
        NSString *number = [call.arguments objectForKey:@"number"];
        [[Pushwoosh sharedInstance] registerSmsNumber:number];
    } else if ([@"registerWhatsappNumber" isEqualToString:call.method]) {
        NSString *number = [call.arguments objectForKey:@"number"];
        [[Pushwoosh sharedInstance] registerWhatsappNumber:number];
    } else if ([@"defaultSetup" isEqualToString:call.method]) {
        if ([PushwooshPlugin isSystemVersionGreaterOrEqualTo:@"16.1"]) {
            [PushwooshLiveActivitiesImplementationSetup defaultSetup];
        }
    } else if ([@"defaultStart" isEqualToString:call.method]) {
        if ([PushwooshPlugin isSystemVersionGreaterOrEqualTo:@"16.1"]) {
            NSString *activityId = [call.arguments objectForKey:@"activityId"];
            NSDictionary<NSString *, id> *attributes = [call.arguments objectForKey:@"attributes"];
            NSDictionary<NSString *, id> *content = [call.arguments objectForKey:@"content"];

            [PushwooshLiveActivitiesImplementationSetup defaultStart:activityId attributes:attributes content:content];
        }
    } else if ([@"startServerCommunication" isEqualToString:call.method]) {
        [[Pushwoosh sharedInstance] startServerCommunication];
    } else if ([@"stopServerCommunication" isEqualToString:call.method]) {
        [[Pushwoosh sharedInstance] stopServerCommunication];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

+ (BOOL)isSystemVersionGreaterOrEqualTo:(NSString *)systemVersion {
    return ([[[UIDevice currentDevice] systemVersion] compare:systemVersion options:NSNumericSearch] != NSOrderedAscending);
}

#pragma mark - UNUserNotificationCenter Delegate Methods
#pragma mark -

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:
(void (^)(UNNotificationPresentationOptions options))completionHandler
API_AVAILABLE(ios(10.0)) {
    
    UNMutableNotificationContent *content = notification.request.content.mutableCopy;
    BOOL isPushwooshMessage = [PWMessage isPushwooshMessage:notification.request.content.userInfo];
    NSString *currentHash = content.userInfo[@"p"];
    BOOL isNeedToImplementInPlugin = [[PushwooshPlugin getPluginImplementationInfoPlistKey] boolValue];

    if (isPushwooshMessage && isNeedToImplementInPlugin && ![[self lastPushwooshHash] isEqualToString:currentHash]) {
        [self setLastPushwooshHash:currentHash];

        if ([PushNotificationManager pushManager].showPushnotificationAlert) {
            completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionAlert);
        } else {
            [[PushNotificationManager pushManager] handlePushReceived:content.userInfo];
        }
        
        [_receiveHandler sendPushNotification:content.userInfo onStart:[self isOnStart:content.userInfo]];
    }
        
    if (_originalNotificationCenterDelegate != nil &&
        _originalNotificationCenterDelegateResponds.willPresentNotification) {
        
        dispatch_block_t presentationBlock = ^{
            [self->_originalNotificationCenterDelegate userNotificationCenter:center
                                                willPresentNotification:notification
                                                  withCompletionHandler:completionHandler];
        };
        
        if (isPushwooshMessage) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.59 * NSEC_PER_SEC)), dispatch_get_main_queue(), presentationBlock);
        } else {
            presentationBlock();
        }
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler
API_AVAILABLE(ios(10.0)) {
    BOOL isNeedToImplementInPlugin = [[PushwooshPlugin getPluginImplementationInfoPlistKey] boolValue];

    dispatch_block_t handlePushAcceptanceBlock = ^{
        if (![response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
            if (![response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier] && [[PushNotificationManager pushManager].delegate respondsToSelector:@selector(onActionIdentifierReceived:withNotification:)]) {
                [[PushNotificationManager pushManager].delegate onActionIdentifierReceived:response.actionIdentifier withNotification:[self pushPayloadFromContent:response.notification.request.content]];
            }
        }
    };

    if ([self isRemoteNotification:response.notification] && [PWMessage isPushwooshMessage:response.notification.request.content.userInfo]) {
        NSDictionary *userInfo = response.notification.request.content.userInfo;
        
        if (isNeedToImplementInPlugin) {
            [[PushNotificationManager pushManager] handlePushAccepted:userInfo onStart:[self isOnStart:userInfo]];
            [_acceptHandler sendPushNotification:userInfo onStart:[self isOnStart:userInfo]];
        }
        
        handlePushAcceptanceBlock();
    }

    if (_originalNotificationCenterDelegate != nil &&
        _originalNotificationCenterDelegateResponds.didReceiveNotificationResponse) {
        [_originalNotificationCenterDelegate userNotificationCenter:center
                                     didReceiveNotificationResponse:response
                                              withCompletionHandler:completionHandler];
    } else {
        completionHandler();
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
   openSettingsForNotification:(nullable UNNotification *)notification
API_AVAILABLE(ios(10.0)) {
    if ([[PushNotificationManager pushManager].delegate respondsToSelector:@selector(pushManager:openSettingsForNotification:)]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wpartial-availability"
        [[PushNotificationManager pushManager].delegate pushManager:[PushNotificationManager pushManager] openSettingsForNotification:notification];
        #pragma clang diagnostic pop
    }

    if (_originalNotificationCenterDelegate != nil &&
        _originalNotificationCenterDelegateResponds.openSettingsForNotification) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
        [_originalNotificationCenterDelegate userNotificationCenter:center
                                        openSettingsForNotification:notification];
#pragma clang diagnostic pop
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

- (NSDictionary *)startPushInfoFromInfoDictionary:(NSDictionary *)userInfo {
    //try as launchOptions dictionary
    NSDictionary *pushDict = userInfo[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (pushDict == nil) {
        id notification = userInfo[UIApplicationLaunchOptionsLocalNotificationKey];
        
        if (notification && [notification isKindOfClass:[UILocalNotification class]]) {
            pushDict = [notification userInfo];
            
            if (pushDict[@"pw_push"] == nil) {
                pushDict = nil;
            }
        }
    }

    return pushDict;
}

- (BOOL)isOnStart:(NSDictionary *)userInfo {
    NSDictionary *pushStartDictionary = [self startPushInfoFromInfoDictionary:userInfo];
    return pushStartDictionary != nil;
}

- (NSDictionary *)pushPayloadFromContent:(UNNotificationContent *)content {
    return [[content.userInfo objectForKey:@"pw_push"] isKindOfClass:[NSDictionary class]] ? [content.userInfo objectForKey:@"pw_push"] : content.userInfo;
}

- (BOOL)isRemoteNotification:(UNNotification *)notification {
    return [notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]];
}

+ (NSString *)getPluginImplementationInfoPlistKey {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:kPushwooshPluginImplementationInfoPlistKey];
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
