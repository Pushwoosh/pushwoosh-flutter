//
//  PushwooshRemoteNotificationDataTests.m
//  RunnerTests
//
//  Created by Pushwoosh on 2026
//

#import <XCTest/XCTest.h>

#import <UIKit/UIKit.h>

#import <pushwoosh_flutter/PushwooshPlugin.h>

// The swizzle replacement is a plain C function in PushwooshPlugin.m. In a stock Flutter app it is
// the site that actually runs: neither AppDelegate nor FlutterAppDelegate declares the selector, so
// the plugin adds this function to the delegate class and the original IMP stays NULL.
extern void _replacement_didReceiveRemoteNotification(id self,
                                                      SEL _cmd,
                                                      UIApplication *application,
                                                      NSDictionary *userInfo,
                                                      void (^completionHandler)(UIBackgroundFetchResult));

// UIApplicationDelegate and FlutterApplicationLifeCycleDelegate declare this selector with
// different return types, so the call site needs one unambiguous declaration to pick.
@interface PushwooshPlugin (PushwooshRemoteNotificationDataTests)
- (BOOL)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
@end

// Sentinel for "the site never called the completion handler" — UIBackgroundFetchResult has no such
// value, and UIKit kills the app when the handler is skipped.
static const NSInteger PWFetchResultNotReported = -1;

@interface PushwooshRemoteNotificationDataTests : XCTestCase
@end

@implementation PushwooshRemoteNotificationDataTests

- (void)setUp {
    [super setUp];

    // An "unrecognized selector" from the test's own scaffolding reads like the crash under guard.
    self.continueAfterFailure = NO;
}

// `p` without `pw_msg`: the crash needs neither, and a payload that is not ours keeps the native
// SDK out of the picture. Measured in the runbook as condition 5.
- (NSDictionary *)payloadWithData:(id)data {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"aps"] = @{ @"content-available" : @1 };
    userInfo[@"p"] = @"dataStr01";
    if (data != nil) {
        userInfo[@"data"] = data;
    }
    return userInfo;
}

- (NSInteger)deliverToSwizzleReplacement:(NSDictionary *)userInfo {
    __block NSInteger reported = PWFetchResultNotReported;
    __block NSUInteger calls = 0;

    // The app delegate is the receiver in production: the plugin installs this function on its class.
    _replacement_didReceiveRemoteNotification([UIApplication sharedApplication].delegate,
                                              @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:),
                                              [UIApplication sharedApplication],
                                              userInfo,
                                              ^(UIBackgroundFetchResult result) {
        calls++;
        reported = (NSInteger)result;
    });

    XCTAssertEqual(calls, 1u);
    return reported;
}

- (NSInteger)deliverToPluginMethod:(NSDictionary *)userInfo {
    __block NSInteger reported = PWFetchResultNotReported;
    __block NSUInteger calls = 0;

    PushwooshPlugin *plugin = [PushwooshPlugin new];
    [plugin application:[UIApplication sharedApplication]
        didReceiveRemoteNotification:userInfo
              fetchCompletionHandler:^(UIBackgroundFetchResult result) {
        calls++;
        reported = (NSInteger)result;
    }];

    XCTAssertEqual(calls, 1u);
    return reported;
}

#pragma mark - swizzle replacement: the live site in a stock Flutter app

- (void)testStringDataIsReportedAsNoData {
    NSInteger result = [self deliverToSwizzleReplacement:[self payloadWithData:@"{\"custom\":\"payload\"}"]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testNumberDataIsReportedAsNoData {
    NSInteger result = [self deliverToSwizzleReplacement:[self payloadWithData:@42]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testBoolDataIsReportedAsNoData {
    NSInteger result = [self deliverToSwizzleReplacement:[self payloadWithData:@YES]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testNullDataIsReportedAsNoData {
    NSInteger result = [self deliverToSwizzleReplacement:[self payloadWithData:[NSNull null]]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testDictionaryDataIsStillReportedAsNewData {
    NSInteger result = [self deliverToSwizzleReplacement:[self payloadWithData:@{ @"custom" : @"payload" }]];
    XCTAssertEqual(result, UIBackgroundFetchResultNewData);
}

- (void)testArrayDataIsStillReportedAsNewData {
    NSInteger result = [self deliverToSwizzleReplacement:[self payloadWithData:@[ @"a", @"b" ]]];
    XCTAssertEqual(result, UIBackgroundFetchResultNewData);
}

- (void)testEmptyDictionaryDataIsReportedAsNoData {
    NSInteger result = [self deliverToSwizzleReplacement:[self payloadWithData:@{}]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testMissingDataKeyIsReportedAsNoData {
    NSInteger result = [self deliverToSwizzleReplacement:[self payloadWithData:nil]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testNilUserInfoIsReportedAsFailed {
    NSInteger result = [self deliverToSwizzleReplacement:nil];
    XCTAssertEqual(result, UIBackgroundFetchResultFailed);
}

#pragma mark - plugin method: the live site when the host declares the selector itself

- (void)testPluginMethodReportsStringDataAsNoData {
    NSInteger result = [self deliverToPluginMethod:[self payloadWithData:@"{\"custom\":\"payload\"}"]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testPluginMethodReportsNullDataAsNoData {
    NSInteger result = [self deliverToPluginMethod:[self payloadWithData:[NSNull null]]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testPluginMethodReportsNumberDataAsNoData {
    NSInteger result = [self deliverToPluginMethod:[self payloadWithData:@42]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testPluginMethodReportsBoolDataAsNoData {
    NSInteger result = [self deliverToPluginMethod:[self payloadWithData:@YES]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testPluginMethodReportsEmptyDictionaryDataAsNoData {
    NSInteger result = [self deliverToPluginMethod:[self payloadWithData:@{}]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

// Unlike the swizzle replacement, this site has no "failed" branch for a payload that is not there.
- (void)testPluginMethodReportsNilUserInfoAsNoData {
    NSInteger result = [self deliverToPluginMethod:nil];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

- (void)testPluginMethodStillReportsDictionaryDataAsNewData {
    NSInteger result = [self deliverToPluginMethod:[self payloadWithData:@{ @"custom" : @"payload" }]];
    XCTAssertEqual(result, UIBackgroundFetchResultNewData);
}

- (void)testPluginMethodStillReportsArrayDataAsNewData {
    NSInteger result = [self deliverToPluginMethod:[self payloadWithData:@[ @"a", @"b" ]]];
    XCTAssertEqual(result, UIBackgroundFetchResultNewData);
}

- (void)testPluginMethodReportsMissingDataKeyAsNoData {
    NSInteger result = [self deliverToPluginMethod:[self payloadWithData:nil]];
    XCTAssertEqual(result, UIBackgroundFetchResultNoData);
}

@end
