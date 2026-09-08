//
//  FlutterJavaScriptInterfaceTests.m
//  RunnerTests
//
//  Created by Pushwoosh on 2026
//

#import <XCTest/XCTest.h>

#import <pushwoosh_flutter/FlutterJavaScriptInterface.h>

@interface FlutterJavaScriptInterfaceTests : XCTestCase
@end

@implementation FlutterJavaScriptInterfaceTests

- (FlutterJavaScriptInterface *)interfaceCapturingInto:(NSMutableArray<NSDictionary *> *)calls {
    return [[FlutterJavaScriptInterface alloc] initWithName:@"flutter"
                                                methodNames:@[ @"showToast" ]
                                                callHandler:^(NSDictionary *callData) {
                                                    [calls addObject:callData];
                                                }];
}

// A rich media page can pass a JS function in the arguments slot; EasyJS forwards it as is.
- (void)testNonStringInArgumentsSlotIsIgnoredAndTheCallStillReachesFlutter {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    id notAString = [NSObject new];

    [[self interfaceCapturingInto:calls] callFlutterMethod:@"showToast" :notAString :nil :nil];

    XCTAssertEqual(calls.count, 1);
    XCTAssertEqualObjects(calls.firstObject[@"methodName"], @"showToast");
    XCTAssertEqualObjects(calls.firstObject[@"arguments"], @{});
}

- (void)testNullInArgumentsSlotIsIgnoredAndTheCallStillReachesFlutter {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];

    [[self interfaceCapturingInto:calls] callFlutterMethod:@"showToast" :(id)[NSNull null] :nil :nil];

    XCTAssertEqual(calls.count, 1);
    XCTAssertEqualObjects(calls.firstObject[@"arguments"], @{});
}

- (void)testJsonArgumentsAreParsed {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];

    [[self interfaceCapturingInto:calls] callFlutterMethod:@"showToast" :@"{\"a\":1}" :nil :nil];

    XCTAssertEqual(calls.count, 1);
    XCTAssertEqualObjects(calls.firstObject[@"arguments"], @{ @"a" : @1 });
}

- (void)testMissingArgumentsBecomeAnEmptyDictionary {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];

    [[self interfaceCapturingInto:calls] callFlutterMethod:@"showToast" :nil :nil :nil];

    XCTAssertEqual(calls.count, 1);
    XCTAssertEqualObjects(calls.firstObject[@"arguments"], @{});
}

- (void)testMalformedJsonArgumentsBecomeAnEmptyDictionary {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];

    [[self interfaceCapturingInto:calls] callFlutterMethod:@"showToast" :@"{not json" :nil :nil];

    XCTAssertEqual(calls.count, 1);
    XCTAssertEqualObjects(calls.firstObject[@"arguments"], @{});
}

- (void)testMethodOutsideTheAllowlistIsNotForwarded {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    id notAString = [NSObject new];

    [[self interfaceCapturingInto:calls] callFlutterMethod:@"nope" :notAString :nil :nil];

    XCTAssertEqual(calls.count, 0);
}

@end
