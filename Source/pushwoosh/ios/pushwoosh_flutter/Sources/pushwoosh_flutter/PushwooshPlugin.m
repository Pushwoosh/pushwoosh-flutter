#import "PushwooshPlugin.h"
#import <PushwooshFramework/PushwooshFramework.h>
#import <PushwooshCore/PWInAppManager.h>
#import <PushwooshFramework/PushNotificationManager.h>
#import <PushwooshFramework/PushwooshFramework-Swift.h>
#import <PushwooshLiveActivities/PushwooshLiveActivities.h>
#import "FlutterJavaScriptInterface.h"

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


@interface PushwooshPlugin () <PushNotificationDelegate, FlutterStreamHandler>

@property (nonatomic) FlutterResult registerResult;
@property (nonatomic) PushwooshStreamHandler *receiveHandler;
@property (nonatomic) PushwooshStreamHandler *acceptHandler;
@property (nonatomic) DeepLinkStreamHandler *openHandler;
@property (nonatomic) FlutterEventSink jsInterfaceEventSink;
@property (nonatomic) NSMutableDictionary<NSString *, FlutterJavaScriptInterface *> *jsInterfaces;
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
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[PushNotificationManager pushManager] handlePushReceived:userInfo];
    [self.receiveHandler sendPushNotification:userInfo onStart:[self isApplicationNotActive]];
    UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultNoData;
    if (userInfo && userInfo[@"data"]) {
        // Nothing constrains the root `data` on the wire, so it need not be a collection.
        id data = userInfo[@"data"];
        if ([data respondsToSelector:@selector(count)] && [data count] > 0) fetchResult = UIBackgroundFetchResultNewData;
    }
    if (completionHandler) completionHandler(fetchResult);
    return YES;
}

- (void)forwardDeepLink:(NSString *)urlString {
    if (self.openHandler != nil) {
        [self.openHandler sendDeepLink:urlString];
    } else {
        self.cachedDeepLink = urlString;
    }
}

- (BOOL)application:(UIApplication *)application
        openURL:(NSURL *)url
        options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    [self forwardDeepLink:[url absoluteString]];
    return YES;
}

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)

#pragma mark - FlutterSceneLifeCycleDelegate

// On scene-based apps a URL that launches the app cold is delivered here, not in
// scene:openURLContexts:. Forward it but return NO so the scene connection still
// reaches other plugins.
- (BOOL)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    [self forwardDeepLinkFromURLContexts:connectionOptions.URLContexts];
    return NO;
}

- (BOOL)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    return [self forwardDeepLinkFromURLContexts:URLContexts];
}

- (BOOL)forwardDeepLinkFromURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    BOOL handled = NO;
    for (UIOpenURLContext *context in URLContexts) {
        [self forwardDeepLink:[context.URL absoluteString]];
        handled = YES;
    }
    return handled;
}

#endif

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

    FlutterEventChannel *jsInterfaceEventChannel = [FlutterEventChannel eventChannelWithName:@"pushwoosh/jsinterface" binaryMessenger:[registrar messenger]];
    [jsInterfaceEventChannel setStreamHandler:instance];
    
    instance.jsInterfaces = [[NSMutableDictionary alloc] init];

    if (instance.cachedDeepLink != nil) {
        [instance.openHandler sendDeepLink:instance.cachedDeepLink];
        instance.cachedDeepLink = nil;
    }

    [registrar addApplicationDelegate:instance];

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
    if ([registrar respondsToSelector:@selector(addSceneDelegate:)]) {
        [registrar addSceneDelegate:instance];
    }
#endif
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
    SEL selector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    Method originalMethod = class_getInstanceMethod(delegateClass, selector);
    if (originalMethod == NULL) {
        // AppDelegate (and its hierarchy) does not implement the method.
        // Install our replacement directly on the AppDelegate class so Flutter's
        // plugin forwarder (FlutterPluginAppLifeCycleDelegate) and UIKit can find it.
        class_addMethod(delegateClass, selector, (IMP)_replacement_didReceiveRemoteNotification, "v@:@@@?");
        pw_original_didReceiveRemoteNotification_Imp = NULL;
    // Skipped for a class that already carries our replacement: storing it as the original is a call to itself.
    } else if (method_getImplementation(originalMethod) != (IMP)_replacement_didReceiveRemoteNotification) {
        pw_original_didReceiveRemoteNotification_Imp = method_setImplementation(originalMethod, (IMP)_replacement_didReceiveRemoteNotification);
    }
    // Arms the guard above: unassigned, it never fires and every registration swizzles this class again.
    appDelegateClass = delegateClass;
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

    if (pw_original_didReceiveRemoteNotification_Imp != NULL) {
        ((void(*)(id, SEL, UIApplication *, NSDictionary *, void(^)(UIBackgroundFetchResult)))pw_original_didReceiveRemoteNotification_Imp)(
            self, _cmd, application, userInfo, safeCompletionHandler
        );
    }

    [[PushNotificationManager pushManager] handlePushReceived:userInfo];

    // Determine the appropriate fetch result based on userInfo content
    UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultNoData;

    if (userInfo) {
        if (userInfo[@"data"]) {
            // Nothing constrains the root `data` on the wire, so it need not be a collection.
            id data = userInfo[@"data"];
            if ([data respondsToSelector:@selector(count)] && [data count] > 0) {
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
        NSString *baseUrl = [call.arguments objectForKey:@"base_url"];

        // Trim once so both calls below see the exact same app code — stray
        // whitespace otherwise makes the second call look like a different
        // code and drops the endpoint the first call just set.
        if ([appID isKindOfClass:[NSString class]]) {
            appID = [appID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        } else {
            // A Dart null arrives as NSNull, not nil, and would kill the app on -length below.
            appID = nil;
        }

        // initializeWithAppCode: keeps the endpoint of the app code it is given, so it runs second.
        if (appID.length > 0 && [baseUrl isKindOfClass:[NSString class]]) {
            [PushwooshConfig setAppCode:appID baseUrl:baseUrl];
        }

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
    } else if ([@"setAppCode" isEqualToString:call.method]) {
        NSString *appCode = [call.arguments objectForKey:@"appCode"];
        NSString *baseUrl = [call.arguments objectForKey:@"baseUrl"];
        [PushwooshConfig setAppCode:appCode
                            baseUrl:([baseUrl isKindOfClass:[NSString class]] ? baseUrl : nil)];
        result(nil);
    } else if ([@"getAppCode" isEqualToString:call.method]) {
        // Android normalizes its native "" (unset) answer to nil; mirror that here
        // so Dart sees one contract on both platforms.
        NSString *appCode = [PushwooshConfig getAppCode];
        result(appCode.length > 0 ? appCode : nil);
    } else if ([@"presentInApp" isEqualToString:call.method]) {
        // The module handles threading and image prefetch itself, and turns a config it
        // cannot parse into a logged no-op — so result(nil) means "handed over", not "shown".
        if (![call.arguments isKindOfClass:[NSDictionary class]]) {
            result([FlutterError errorWithCode:@"presentInApp"
                                       message:@"config must be a map"
                                       details:nil]);
            return;
        }
        [[Pushwoosh inApp] present:call.arguments];
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
    } else if ([@"addJavascriptInterface" isEqualToString:call.method]) {
        [self handleAddJavascriptInterface:call result:result];
    } else if ([@"removeJavascriptInterface" isEqualToString:call.method]) {
        [self handleRemoveJavascriptInterface:call result:result];
    } else if ([@"sendJavaScriptResponse" isEqualToString:call.method]) {
        [self handleSendJavaScriptResponse:call result:result];
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
    // A non-string `p` would be stored and then messaged with isEqualToString: on the next push.
    NSString *currentHash = [content.userInfo[@"p"] isKindOfClass:[NSString class]] ? content.userInfo[@"p"] : nil;
    BOOL isNeedToImplementInPlugin = [[PushwooshPlugin getPluginImplementationInfoPlistKey] boolValue];

    if (isPushwooshMessage && isNeedToImplementInPlugin && ![[self lastPushwooshHash] isEqualToString:currentHash]) {
        [self setLastPushwooshHash:currentHash];

        if ([PushNotificationManager pushManager].showPushnotificationAlert) {
            completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionAlert);
        } else {
            [[PushNotificationManager pushManager] handlePushReceived:content.userInfo];
        }
        
        [_receiveHandler sendPushNotification:content.userInfo onStart:[self isApplicationNotActive]];
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
            [_acceptHandler sendPushNotification:userInfo onStart:[self isApplicationNotActive]];
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

/// Only the native `handlePushAccepted:onStart:` call is left on this: there `onStart` decides
/// whether the SDK records the push as the one that launched the app, which is not the same
/// question as "was the app on the foreground". It answers NO for every push, because the plugin
/// never sees a `launchOptions` dictionary to pass in - it does not implement
/// `application:didFinishLaunchingWithOptions:` at all. Left as it was: what reaches Dart no longer
/// depends on it, and changing what the native SDK records is a separate change.
- (BOOL)isOnStart:(NSDictionary *)userInfo {
    NSDictionary *pushStartDictionary = [self startPushInfoFromInfoDictionary:userInfo];
    return pushStartDictionary != nil;
}

+ (BOOL)isNotActiveApplicationState:(UIApplicationState)state {
    return state != UIApplicationStateActive;
}

/// The state Dart is told about. Read on the delegate callbacks' own thread, which UIKit runs on the
/// main queue - the same read the native SDK does in `PWPushNotificationsManager.isAppInBackground`.
- (BOOL)isApplicationNotActive {
    return [PushwooshPlugin isNotActiveApplicationState:[UIApplication sharedApplication].applicationState];
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

#pragma mark - JavaScript Interface Methods

- (void)handleAddJavascriptInterface:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *interfaceName = call.arguments[@"interfaceName"];
    NSArray<NSString *> *methodNames = call.arguments[@"methodNames"];
    
    if (!interfaceName || !methodNames) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS"
                                   message:@"interfaceName and methodNames are required"
                                   details:nil]);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    FlutterJavaScriptInterface *interface = [[FlutterJavaScriptInterface alloc] 
                                            initWithName:interfaceName 
                                             methodNames:methodNames
                                             callHandler:^(NSDictionary *callData) {
        [weakSelf sendJavaScriptInterfaceCall:callData];
    }];
    
    self.jsInterfaces[interfaceName] = interface;
    
    [[PWInAppManager sharedManager] addJavascriptInterface:interface withName:interfaceName];
    
    result(nil);
}

- (void)handleRemoveJavascriptInterface:(FlutterMethodCall *)call result:(FlutterResult)result {
    // This is an Android-only feature. On iOS, JavaScript interfaces are managed
    // differently through WKWebView and are automatically cleaned up when the
    // WebView is dismissed. This stub exists for API compatibility.
    
    NSString *interfaceName = call.arguments[@"interfaceName"];
    
    if (!interfaceName) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS"
                                   message:@"interfaceName is required"
                                   details:nil]);
        return;
    }
    
    // Remove from internal tracking for consistency
    [self.jsInterfaces removeObjectForKey:interfaceName];
    
    result(nil);
}

- (void)handleSendJavaScriptResponse:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *callbackId = call.arguments[@"callbackId"];
    BOOL success = [call.arguments[@"success"] boolValue];
    id data = call.arguments[@"data"];
    NSString *error = call.arguments[@"error"];
    
    if (!callbackId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS"
                                   message:@"callbackId is required"
                                   details:nil]);
        return;
    }
    
    [FlutterJavaScriptInterface sendResponse:callbackId 
                                     success:success 
                                        data:data 
                                       error:error];
    
    result(nil);
}

- (void)sendJavaScriptInterfaceCall:(NSDictionary *)callData {
    if (self.jsInterfaceEventSink) {
        self.jsInterfaceEventSink(callData);
    }
}

#pragma mark - FlutterStreamHandler (for JavaScript Interface)

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    self.jsInterfaceEventSink = eventSink;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    self.jsInterfaceEventSink = nil;
    return nil;
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
    
    // nothing constrains `aps` on the wire, so it need not be a dictionary
    id aps = pushNotification[@"aps"];
    NSDictionary *pushDict = [aps isKindOfClass:[NSDictionary class]] ? aps : nil;
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

    messageDict[@"payload"] = [self payloadWithApplicationState:pushNotification onStart:onStart];

    _eventSink(messageDict);
}

/// Android reads its payload from the push bundle, into which the native SDK writes the state the
/// app was in when the push arrived - `foreground` and its inverse `onStart`
/// (PushBundleDataProvider.setForeground). On iOS the payload is the APNs dictionary off the wire
/// and carries no such keys, so Dart code reading `payload['foreground']` found nothing here. Both
/// keys are added, so the key exists on both platforms.
///
/// The sampling moment still differs, and the Dart docs say so: these keys carry the state at
/// delivery, while Android's come from arrival time and can therefore disagree with its own
/// `fromBackground` on the accept path. `fromBackground` is the signal to branch on.
- (NSDictionary *)payloadWithApplicationState:(NSDictionary *)pushNotification onStart:(BOOL)onStart {
    if (![pushNotification isKindOfClass:[NSDictionary class]]) {
        return pushNotification;
    }

    /// Both boxed from a BOOL lvalue, never from the `!` expression directly: `!` yields an `int` in
    /// C, so `@(!onStart)` would box an NSNumber that the Flutter codec sends to Dart as the number
    /// 1 instead of `true` - and `payload['foreground'] == true` would be false on iOS only.
    BOOL foreground = !onStart;
    NSMutableDictionary *payload = [pushNotification mutableCopy];
    payload[@"foreground"] = @(foreground);
    payload[@"onStart"] = @(onStart);
    return payload;
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
