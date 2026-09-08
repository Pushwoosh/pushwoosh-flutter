//
//  FlutterJavaScriptInterfacePoisoningTests.m
//  RunnerTests
//
//  Created by Pushwoosh on 2026
//

#import <XCTest/XCTest.h>

#import <pushwoosh_flutter/FlutterJavaScriptInterface.h>

@interface FlutterJavaScriptInterfacePoisoningTests : XCTestCase
@end

@implementation FlutterJavaScriptInterfacePoisoningTests

- (void)setUp {
    [super setUp];

    self.continueAfterFailure = NO;
}

- (FlutterJavaScriptInterface *)interfaceCapturingInto:(NSMutableArray<NSDictionary *> *)calls {
    return [[FlutterJavaScriptInterface alloc] initWithName:@"flutter"
                                                methodNames:@[ @"showToast" ]
                                                callHandler:^(NSDictionary *callData) {
                                                    [calls addObject:callData];
                                                }];
}

/// Calls `selectorName` on the interface the way PWEasyJSListener does for a prompt() coming from
/// a rich media page: the name is a string from the page, every argument is a string, and the
/// method signature is the only gate. Returns NO when that gate dropped the call.
- (BOOL)pageCalls:(NSString *)selectorName
      onInterface:(FlutterJavaScriptInterface *)interface
    withArguments:(NSArray<NSString *> *)arguments {
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *signature = [interface methodSignatureForSelector:selector];
    if (!signature) {
        return NO;
    }

    NSInvocation *invoker = [NSInvocation invocationWithMethodSignature:signature];
    invoker.selector = selector;
    invoker.target = interface;
    for (NSUInteger i = 0; i < arguments.count; i++) {
        NSUInteger argumentIndex = i + 2;
        if (argumentIndex >= signature.numberOfArguments) {
            break;
        }
        NSString *argument = arguments[i];
        [invoker setArgument:&argument atIndex:argumentIndex];
    }
    [invoker retainArguments];
    [invoker invoke];
    return YES;
}

#pragma mark - guard: the page cannot overwrite the interface's own state

- (void)testPropertySettersAreNotReachableFromThePage {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    XCTAssertFalse([self pageCalls:@"setAllowedMethodNames:" onInterface:interface withArguments:@[ @"x" ]]);
    XCTAssertFalse([self pageCalls:@"setCallHandler:" onInterface:interface withArguments:@[ @"x" ]]);
    XCTAssertFalse([self pageCalls:@"setInterfaceName:" onInterface:interface withArguments:@[ @"x" ]]);
}

- (void)testAllowlistSurvivesItsSetterBeingCalledFromThePage {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    [self pageCalls:@"setAllowedMethodNames:" onInterface:interface withArguments:@[ @"x" ]];
    [interface callFlutterMethod:@"showToast" :@"{\"a\":1}" :nil :nil];

    XCTAssertEqualObjects(interface.allowedMethodNames, @[ @"showToast" ]);
    XCTAssertEqual(calls.count, 1);
}

- (void)testCallHandlerSurvivesItsSetterBeingCalledFromThePage {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    [self pageCalls:@"setCallHandler:" onInterface:interface withArguments:@[ @"x" ]];
    [interface callFlutterMethod:@"showToast" :@"{\"a\":1}" :nil :nil];

    XCTAssertEqual(calls.count, 1);
}

- (void)testInterfaceNameSurvivesItsSetterBeingCalledFromThePage {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    [self pageCalls:@"setInterfaceName:" onInterface:interface withArguments:@[ @"x" ]];
    [interface callFlutterMethod:@"showToast" :@"{\"a\":1}" :nil :nil];

    XCTAssertEqualObjects(interface.interfaceName, @"flutter");
    XCTAssertEqualObjects(calls.firstObject[@"interfaceName"], @"flutter");
}

- (void)testReInitialisingFromThePageLeavesTheInterfaceIntact {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    NSArray<NSString *> *poison = @[ @"flutter", @"x", @"y" ];
    BOOL initialiserIsReachable = [self pageCalls:@"initWithName:methodNames:callHandler:"
                                      onInterface:interface
                                    withArguments:poison];

    XCTAssertTrue(initialiserIsReachable);
    [interface callFlutterMethod:@"showToast" :@"{\"a\":1}" :nil :nil];

    XCTAssertEqualObjects(interface.interfaceName, @"flutter");
    XCTAssertEqualObjects(interface.allowedMethodNames, @[ @"showToast" ]);
    XCTAssertEqual(calls.count, 1);
}

// `setValue:forKey:` is inherited from NSObject, so it stays reachable from the page; what must
// not survive is the write itself, which KVC would otherwise send straight to the ivar.
- (void)testKeyValueCodingFromThePageCannotReplaceTheAllowlist {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    NSArray<NSString *> *poison = @[ @"x", @"allowedMethodNames" ];
    [self pageCalls:@"setValue:forKey:" onInterface:interface withArguments:poison];
    [interface callFlutterMethod:@"showToast" :@"{\"a\":1}" :nil :nil];

    XCTAssertEqualObjects(interface.allowedMethodNames, @[ @"showToast" ]);
    XCTAssertEqual(calls.count, 1);
}

- (void)testKeyValueCodingFromThePageCannotReplaceTheCallHandler {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    NSArray<NSString *> *poison = @[ @"x", @"callHandler" ];
    [self pageCalls:@"setValue:forKey:" onInterface:interface withArguments:poison];
    [interface callFlutterMethod:@"showToast" :@"{\"a\":1}" :nil :nil];

    XCTAssertEqual(calls.count, 1);
}

- (void)testKeyValueCodingFromThePageCannotReplaceTheInterfaceName {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    NSArray<NSString *> *poison = @[ @"x", @"interfaceName" ];
    [self pageCalls:@"setValue:forKey:" onInterface:interface withArguments:poison];

    XCTAssertEqualObjects(interface.interfaceName, @"flutter");
}

#pragma mark - controls: the legitimate call path is unchanged

- (void)testValidArgumentsInitialiseTheInterface {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    XCTAssertEqualObjects(interface.interfaceName, @"flutter");
    XCTAssertEqualObjects(interface.allowedMethodNames, @[ @"showToast" ]);
    XCTAssertNotNil(interface.callHandler);
}

- (void)testAllowedCallReachesFlutterWithItsArguments {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    [interface callFlutterMethod:@"showToast" :@"{\"a\":1}" :nil :nil];

    XCTAssertEqual(calls.count, 1);
    XCTAssertEqualObjects(calls.firstObject[@"methodName"], @"showToast");
    XCTAssertEqualObjects(calls.firstObject[@"arguments"], @{ @"a" : @1 });
}

- (void)testMethodOutsideTheAllowlistIsNotForwarded {
    NSMutableArray<NSDictionary *> *calls = [NSMutableArray array];
    FlutterJavaScriptInterface *interface = [self interfaceCapturingInto:calls];

    [interface callFlutterMethod:@"nope" :@"{\"a\":1}" :nil :nil];

    XCTAssertEqual(calls.count, 0);
}

@end
