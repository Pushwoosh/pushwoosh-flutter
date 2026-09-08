//
//  PushwooshApsPayloadTests.m
//  RunnerTests
//
//  Created by Pushwoosh on 2026
//

#import <XCTest/XCTest.h>

#import <pushwoosh_flutter/PushwooshPlugin.h>

@interface PushwooshApsPayloadTests : XCTestCase
@end

@implementation PushwooshApsPayloadTests

- (void)setUp {
    [super setUp];

    // An "unrecognized selector" from the test's own scaffolding reads like the crash under guard.
    self.continueAfterFailure = NO;
}

// `p` only keeps the payload recognisable as a push; `pw_msg` is what the delivery routes gate on
// and this test calls the stream handler directly, so it is left out on purpose.
- (NSDictionary *)payloadWithAps:(id)aps {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"p"] = @"pushHash01";
    if (aps != nil) {
        userInfo[@"aps"] = aps;
    }
    return userInfo;
}

- (NSDictionary *)deliver:(NSDictionary *)userInfo onStart:(BOOL)onStart {
    PushwooshStreamHandler *handler = [PushwooshStreamHandler new];

    __block NSDictionary *event = nil;
    __block NSUInteger calls = 0;
    [handler onListenWithArguments:nil eventSink:^(id _Nullable value) {
        calls++;
        event = value;
    }];

    [handler sendPushNotification:userInfo onStart:onStart];

    XCTAssertEqual(calls, 1u);
    return event;
}

- (NSDictionary *)deliver:(NSDictionary *)userInfo {
    return [self deliver:userInfo onStart:NO];
}

// The delivered payload is the wire payload plus the two application-state keys the Android SDK
// writes into its push bundle, so a Dart branch on payload['foreground'] fits both platforms.
- (NSDictionary *)deliveredPayloadOf:(NSDictionary *)userInfo onStart:(BOOL)onStart {
    BOOL foreground = !onStart;
    NSMutableDictionary *expected = [userInfo mutableCopy];
    expected[@"foreground"] = @(foreground);
    expected[@"onStart"] = @(onStart);
    return expected;
}

- (NSDictionary *)deliveredPayloadOf:(NSDictionary *)userInfo {
    return [self deliveredPayloadOf:userInfo onStart:NO];
}

#pragma mark - guard: a non-dictionary `aps` degrades to "no alert", it does not raise

- (void)testStringApsIsDeliveredWithoutTitleOrMessage {
    NSDictionary *userInfo = [self payloadWithAps:@"alert"];
    NSDictionary *event = [self deliver:userInfo];

    XCTAssertNil(event[@"title"]);
    XCTAssertNil(event[@"message"]);
    XCTAssertEqualObjects(event[@"payload"], [self deliveredPayloadOf:userInfo]);
}

- (void)testNumberApsIsDeliveredWithoutTitleOrMessage {
    NSDictionary *userInfo = [self payloadWithAps:@42];
    NSDictionary *event = [self deliver:userInfo];

    XCTAssertNil(event[@"title"]);
    XCTAssertNil(event[@"message"]);
    XCTAssertEqualObjects(event[@"payload"], [self deliveredPayloadOf:userInfo]);
}

- (void)testArrayApsIsDeliveredWithoutTitleOrMessage {
    NSDictionary *userInfo = [self payloadWithAps:@[ @"alert" ]];
    NSDictionary *event = [self deliver:userInfo];

    XCTAssertNil(event[@"title"]);
    XCTAssertNil(event[@"message"]);
    XCTAssertEqualObjects(event[@"payload"], [self deliveredPayloadOf:userInfo]);
}

- (void)testBoolApsIsDeliveredWithoutTitleOrMessage {
    NSDictionary *userInfo = [self payloadWithAps:@YES];
    NSDictionary *event = [self deliver:userInfo];

    XCTAssertNil(event[@"title"]);
    XCTAssertNil(event[@"message"]);
    XCTAssertEqualObjects(event[@"payload"], [self deliveredPayloadOf:userInfo]);
}

- (void)testNullApsIsDeliveredWithoutTitleOrMessage {
    NSDictionary *userInfo = [self payloadWithAps:[NSNull null]];
    NSDictionary *event = [self deliver:userInfo];

    XCTAssertNil(event[@"title"]);
    XCTAssertNil(event[@"message"]);
    XCTAssertEqualObjects(event[@"payload"], [self deliveredPayloadOf:userInfo]);
}

#pragma mark - controls: every shape that works today still works

- (void)testDictionaryApsWithAlertDictionaryStillCarriesTitleAndMessage {
    NSDictionary *userInfo = [self payloadWithAps:@{ @"alert" : @{ @"title" : @"t", @"body" : @"b" } }];
    NSDictionary *event = [self deliver:userInfo];

    XCTAssertEqualObjects(event[@"title"], @"t");
    XCTAssertEqualObjects(event[@"message"], @"b");
    XCTAssertEqualObjects(event[@"payload"], [self deliveredPayloadOf:userInfo]);
}

- (void)testDictionaryApsWithAlertStringStillCarriesMessage {
    NSDictionary *userInfo = [self payloadWithAps:@{ @"alert" : @"b" }];
    NSDictionary *event = [self deliver:userInfo];

    XCTAssertNil(event[@"title"]);
    XCTAssertEqualObjects(event[@"message"], @"b");
}

- (void)testDictionaryApsWithoutAlertIsDeliveredWithoutTitleOrMessage {
    NSDictionary *userInfo = [self payloadWithAps:@{ @"content-available" : @1 }];
    NSDictionary *event = [self deliver:userInfo];

    XCTAssertNil(event[@"title"]);
    XCTAssertNil(event[@"message"]);
}

- (void)testMissingApsKeyIsDeliveredWithoutTitleOrMessage {
    NSDictionary *userInfo = [self payloadWithAps:nil];
    NSDictionary *event = [self deliver:userInfo];

    XCTAssertNil(event[@"title"]);
    XCTAssertNil(event[@"message"]);
    XCTAssertEqualObjects(event[@"payload"], [self deliveredPayloadOf:userInfo]);
}

- (void)testOnStartFlagIsForwarded {
    NSDictionary *event = [self deliver:[self payloadWithAps:@"alert"] onStart:YES];

    XCTAssertEqualObjects(event[@"fromBackground"], @YES);
}

#pragma mark - the flag the delivery paths feed into the payload

// The three delivery paths ask the plugin for the live application state, and under XCTest that read
// only ever returns the active case - so the mapping is tested here, on its own.
- (void)testActiveApplicationCountsAsForeground {
    XCTAssertFalse([PushwooshPlugin isNotActiveApplicationState:UIApplicationStateActive]);
}

- (void)testInactiveApplicationDoesNotCountAsForeground {
    XCTAssertTrue([PushwooshPlugin isNotActiveApplicationState:UIApplicationStateInactive]);
}

- (void)testBackgroundedApplicationDoesNotCountAsForeground {
    XCTAssertTrue([PushwooshPlugin isNotActiveApplicationState:UIApplicationStateBackground]);
}

#pragma mark - parity: the payload carries the application state Android puts in its push bundle

- (void)testPayloadCarriesForegroundWhenTheAppWasActive {
    NSDictionary *event = [self deliver:[self payloadWithAps:@{ @"alert" : @"b" }] onStart:NO];

    XCTAssertEqualObjects(event[@"payload"][@"foreground"], @YES);
    XCTAssertEqualObjects(event[@"payload"][@"onStart"], @NO);
}

- (void)testPayloadCarriesBackgroundWhenTheAppWasNotActive {
    NSDictionary *event = [self deliver:[self payloadWithAps:@{ @"alert" : @"b" }] onStart:YES];

    XCTAssertEqualObjects(event[@"payload"][@"foreground"], @NO);
    XCTAssertEqualObjects(event[@"payload"][@"onStart"], @YES);
}

// Both keys have to reach Dart as booleans, not as numbers: the Flutter codec keys that off the
// boxed NSNumber's type, and `@(!onStart)` boxes an int, because `!` yields an int in C. That ships
// `foreground: 1` to Dart, where `payload['foreground'] == true` is then false - on iOS only.
// Compared against `@YES`'s own encoding rather than `@encode(BOOL)`: NSNumber stores a BOOL as a
// char, so the two do not match. XCTAssertEqualObjects cannot stand in for this - `[@1 isEqual:@YES]`
// is true, so a number-typed key passes every value assertion in this file.
- (void)testStateKeysReachDartAsBooleansNotNumbers {
    for (NSNumber *onStart in @[ @NO, @YES ]) {
        NSDictionary *payload = [self deliver:[self payloadWithAps:@"alert"] onStart:onStart.boolValue][@"payload"];

        XCTAssertEqual(strcmp([payload[@"foreground"] objCType], [@YES objCType]), 0,
                       @"foreground is %s, not a boolean (onStart=%@)", [payload[@"foreground"] objCType], onStart);
        XCTAssertEqual(strcmp([payload[@"onStart"] objCType], [@YES objCType]), 0,
                       @"onStart is %s, not a boolean (onStart=%@)", [payload[@"onStart"] objCType], onStart);
    }
}

// The two keys are inverses of each other on Android, and a Dart branch reading one and asserting
// the other would break the moment they disagree.
- (void)testForegroundAndOnStartAreInverses {
    for (NSNumber *onStart in @[ @NO, @YES ]) {
        NSDictionary *payload = [self deliver:[self payloadWithAps:@"alert"] onStart:onStart.boolValue][@"payload"];

        XCTAssertNotEqualObjects(payload[@"foreground"], payload[@"onStart"]);
    }
}

// The wire dictionary is handed to us by the native SDK, which keeps using it after this call: the
// state keys have to land on a copy.
- (void)testTheWireDictionaryIsNotMutated {
    NSDictionary *userInfo = [self payloadWithAps:@{ @"alert" : @"b" }];

    [self deliver:userInfo];

    XCTAssertNil(userInfo[@"foreground"]);
    XCTAssertNil(userInfo[@"onStart"]);
}

// A server-sent `foreground` must not survive as the answer to "was the app active": it is the
// same key, and the local state is the one Dart is asking about.
- (void)testServerSentForegroundKeyIsOverwrittenByTheLocalState {
    NSMutableDictionary *userInfo = [[self payloadWithAps:@"alert"] mutableCopy];
    userInfo[@"foreground"] = @"whatever the server sent";

    NSDictionary *event = [self deliver:userInfo onStart:YES];

    XCTAssertEqualObjects(event[@"payload"][@"foreground"], @NO);
}

// Ground truth for the `if (!_eventSink) return` early exit: with no subscriber the payload is only
// stashed, and the stashed one is replayed as onStart on the first listen.
- (void)testPayloadArrivingBeforeAnySubscriberIsReplayedOnListen {
    PushwooshStreamHandler *handler = [PushwooshStreamHandler new];
    NSDictionary *userInfo = [self payloadWithAps:@{ @"alert" : @"b" }];

    [handler sendPushNotification:userInfo onStart:NO];

    __block NSDictionary *event = nil;
    __block NSUInteger calls = 0;
    [handler onListenWithArguments:nil eventSink:^(id _Nullable value) {
        calls++;
        event = value;
    }];

    XCTAssertEqual(calls, 1u);
    XCTAssertEqualObjects(event[@"message"], @"b");
    XCTAssertEqualObjects(event[@"fromBackground"], @YES);
}

@end
