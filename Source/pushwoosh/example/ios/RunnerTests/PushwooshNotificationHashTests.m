//
//  PushwooshNotificationHashTests.m
//  RunnerTests
//
//  Created by Pushwoosh on 2026
//

#import <XCTest/XCTest.h>

#import <UserNotifications/UserNotifications.h>
#import <objc/runtime.h>

#import <PushwooshFramework/PushNotificationManager.h>
#import <pushwoosh_flutter/PushwooshPlugin.h>

@interface PushwooshPlugin (PushwooshNotificationHashTests)
+ (NSString *)getPluginImplementationInfoPlistKey;
@end

// UNNotification has no public initializer; this is the one the system itself uses.
@interface UNNotification (PushwooshNotificationHashTests)
+ (instancetype)notificationWithRequest:(UNNotificationRequest *)request date:(NSDate *)date;
@end

@interface PushwooshNotificationHashTests : XCTestCase
@end

@implementation PushwooshNotificationHashTests {
    Method _plistKeyMethod;
    IMP _originalPlistKeyImp;
    IMP _optedInPlistKeyImp;
    BOOL _originalShowAlert;
}

// The delegate method only reaches the hash comparison when the host app opted into plugin-side
// notification handling; the tests get there without touching the sample app's Info.plist.
- (void)setUp {
    [super setUp];

    // A missing selector must stop here: its "unrecognized selector" reads like the crash under guard.
    self.continueAfterFailure = NO;

    _plistKeyMethod = class_getClassMethod([PushwooshPlugin class], @selector(getPluginImplementationInfoPlistKey));
    XCTAssertTrue(_plistKeyMethod != NULL);
    _optedInPlistKeyImp = imp_implementationWithBlock(^id(id _self) {
        return @YES;
    });
    _originalPlistKeyImp = method_setImplementation(_plistKeyMethod, _optedInPlistKeyImp);

    _originalShowAlert = [PushNotificationManager pushManager].showPushnotificationAlert;
    [PushNotificationManager pushManager].showPushnotificationAlert = YES;
}

- (void)tearDown {
    method_setImplementation(_plistKeyMethod, _originalPlistKeyImp);
    imp_removeBlock(_optedInPlistKeyImp);
    [PushNotificationManager pushManager].showPushnotificationAlert = _originalShowAlert;

    [super tearDown];
}

- (UNNotification *)notificationWithHash:(id)hash pushwoosh:(BOOL)pushwoosh {
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = @"test";

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (pushwoosh) {
        userInfo[@"pw_msg"] = @1;
    }
    if (hash) {
        userInfo[@"p"] = hash;
    }
    content.userInfo = userInfo;

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[NSUUID UUID].UUIDString
                                                                         content:content
                                                                         trigger:nil];

    XCTAssertTrue([UNNotification respondsToSelector:@selector(notificationWithRequest:date:)]);
    UNNotification *notification = [UNNotification notificationWithRequest:request date:[NSDate date]];
    XCTAssertNotNil(notification);

    return notification;
}

// Returns whether the plugin decided to present the notification: the completion handler is only
// called from inside the branch that stores the hash, so it doubles as "this push was not
// deduplicated against the stored one".
- (BOOL)deliver:(UNNotification *)notification toPlugin:(id)plugin {
    __block BOOL presented = NO;

    [plugin userNotificationCenter:[UNUserNotificationCenter currentNotificationCenter]
          willPresentNotification:notification
            withCompletionHandler:^(UNNotificationPresentationOptions options) {
        presented = YES;
    }];

    return presented;
}

- (void)testNumberHashIsNotStoredAndTheSecondPushIsPresented {
    id plugin = [[PushwooshPlugin alloc] init];

    XCTAssertTrue([self deliver:[self notificationWithHash:@1234567890 pushwoosh:YES] toPlugin:plugin]);
    XCTAssertTrue([self deliver:[self notificationWithHash:@9876543210 pushwoosh:YES] toPlugin:plugin]);
}

- (void)testDictionaryHashIsNotStoredAndTheSecondPushIsPresented {
    id plugin = [[PushwooshPlugin alloc] init];
    id hash = @{ @"hash" : @"iKcQ2R8p1" };

    XCTAssertTrue([self deliver:[self notificationWithHash:hash pushwoosh:YES] toPlugin:plugin]);
    XCTAssertTrue([self deliver:[self notificationWithHash:hash pushwoosh:YES] toPlugin:plugin]);
}

- (void)testNumberHashFollowedByAStringHashIsPresented {
    id plugin = [[PushwooshPlugin alloc] init];

    XCTAssertTrue([self deliver:[self notificationWithHash:@1234567890 pushwoosh:YES] toPlugin:plugin]);
    XCTAssertTrue([self deliver:[self notificationWithHash:@"wY7Lm4Tz0" pushwoosh:YES] toPlugin:plugin]);
}

- (void)testDeduplicationStillWorksAfterANumberHash {
    id plugin = [[PushwooshPlugin alloc] init];

    XCTAssertTrue([self deliver:[self notificationWithHash:@1234567890 pushwoosh:YES] toPlugin:plugin]);
    XCTAssertTrue([self deliver:[self notificationWithHash:@"wY7Lm4Tz0" pushwoosh:YES] toPlugin:plugin]);
    XCTAssertFalse([self deliver:[self notificationWithHash:@"wY7Lm4Tz0" pushwoosh:YES] toPlugin:plugin]);
}

- (void)testRepeatedStringHashIsDeduplicated {
    id plugin = [[PushwooshPlugin alloc] init];

    XCTAssertTrue([self deliver:[self notificationWithHash:@"iKcQ2R8p1" pushwoosh:YES] toPlugin:plugin]);
    XCTAssertFalse([self deliver:[self notificationWithHash:@"iKcQ2R8p1" pushwoosh:YES] toPlugin:plugin]);
}

- (void)testDifferentStringHashesAreBothPresented {
    id plugin = [[PushwooshPlugin alloc] init];

    XCTAssertTrue([self deliver:[self notificationWithHash:@"iKcQ2R8p1" pushwoosh:YES] toPlugin:plugin]);
    XCTAssertTrue([self deliver:[self notificationWithHash:@"wY7Lm4Tz0" pushwoosh:YES] toPlugin:plugin]);
}

- (void)testNonPushwooshNotificationWithANumberHashIsIgnored {
    id plugin = [[PushwooshPlugin alloc] init];

    XCTAssertFalse([self deliver:[self notificationWithHash:@1234567890 pushwoosh:NO] toPlugin:plugin]);
    XCTAssertFalse([self deliver:[self notificationWithHash:@9876543210 pushwoosh:NO] toPlugin:plugin]);
}

- (void)testHostAppThatDidNotOptInIsNeverTouched {
    IMP optedOut = imp_implementationWithBlock(^id(id _self) {
        return nil;
    });
    method_setImplementation(_plistKeyMethod, optedOut);

    id plugin = [[PushwooshPlugin alloc] init];

    XCTAssertFalse([self deliver:[self notificationWithHash:@1234567890 pushwoosh:YES] toPlugin:plugin]);
    XCTAssertFalse([self deliver:[self notificationWithHash:@9876543210 pushwoosh:YES] toPlugin:plugin]);

    method_setImplementation(_plistKeyMethod, _optedInPlistKeyImp);
    imp_removeBlock(optedOut);
}

- (void)testNotificationWithoutAHashIsAlwaysPresented {
    id plugin = [[PushwooshPlugin alloc] init];

    XCTAssertTrue([self deliver:[self notificationWithHash:nil pushwoosh:YES] toPlugin:plugin]);
    XCTAssertTrue([self deliver:[self notificationWithHash:nil pushwoosh:YES] toPlugin:plugin]);
}

@end
