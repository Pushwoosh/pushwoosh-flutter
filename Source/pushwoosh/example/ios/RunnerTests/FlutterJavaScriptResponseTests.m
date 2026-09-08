//
//  FlutterJavaScriptResponseTests.m
//  RunnerTests
//
//  Created by Pushwoosh on 2026
//

#import <XCTest/XCTest.h>

#import <Flutter/Flutter.h>
#import <pushwoosh_flutter/FlutterJavaScriptInterface.h>

@interface FlutterJavaScriptResponseTests : XCTestCase
@end

@implementation FlutterJavaScriptResponseTests

- (NSString *)storedCallbackIdForTest:(NSString *)name {
    NSString *callbackId = [NSString stringWithFormat:@"flutter_showToast_%@", name];
    [FlutterJavaScriptInterface storeCallback:callbackId
                              successCallback:(id)@"successCallbackName"
                                errorCallback:(id)@"errorCallbackName"];
    return callbackId;
}

// Whatever the Dart handler returned travels here as is: NaN, infinity, typed data,
// a map keyed by ints — none of them survive NSJSONSerialization.
//
// The response itself is unobservable from the outside: the delivery branch of sendResponse:
// is dead code today, so a dropped and an accepted response differ only in the log. Hence
// every case asserts the same pair — no exception, and the stored callback consumed exactly
// once (which is what proves the call went through the real path instead of an early exit).

- (void)testNanResultIsDroppedAndTheCallbackIsConsumed {
    NSString *callbackId = [self storedCallbackIdForTest:@"nan"];

    XCTAssertNoThrow([FlutterJavaScriptInterface sendResponse:callbackId success:YES data:@(NAN) error:nil]);

    XCTAssertNil([FlutterJavaScriptInterface getAndRemoveCallbacks:callbackId]);
}

- (void)testInfiniteResultIsDroppedAndTheCallbackIsConsumed {
    NSString *callbackId = [self storedCallbackIdForTest:@"infinity"];

    XCTAssertNoThrow([FlutterJavaScriptInterface sendResponse:callbackId success:YES data:@(INFINITY) error:nil]);

    XCTAssertNil([FlutterJavaScriptInterface getAndRemoveCallbacks:callbackId]);
}

- (void)testTypedDataResultIsDroppedAndTheCallbackIsConsumed {
    NSString *callbackId = [self storedCallbackIdForTest:@"typed-data"];
    uint8_t bytes[] = { 1, 2, 3 };
    id typedData = [FlutterStandardTypedData typedDataWithBytes:[NSData dataWithBytes:bytes length:3]];

    XCTAssertNoThrow([FlutterJavaScriptInterface sendResponse:callbackId success:YES data:typedData error:nil]);

    XCTAssertNil([FlutterJavaScriptInterface getAndRemoveCallbacks:callbackId]);
}

- (void)testResultKeyedByNonStringsIsDroppedAndTheCallbackIsConsumed {
    NSString *callbackId = [self storedCallbackIdForTest:@"int-keys"];

    XCTAssertNoThrow([FlutterJavaScriptInterface sendResponse:callbackId success:YES data:@{ @1 : @"a" } error:nil]);

    XCTAssertNil([FlutterJavaScriptInterface getAndRemoveCallbacks:callbackId]);
}

- (void)testNestedNonSerializableResultIsDroppedAndTheCallbackIsConsumed {
    NSString *callbackId = [self storedCallbackIdForTest:@"nested-nan"];
    // Hoisted: the comma inside the literal would be read as a second macro argument.
    id nested = @{ @"ok" : @YES, @"value" : @(NAN) };

    XCTAssertNoThrow([FlutterJavaScriptInterface sendResponse:callbackId success:YES data:nested error:nil]);

    XCTAssertNil([FlutterJavaScriptInterface getAndRemoveCallbacks:callbackId]);
}

- (void)testNonSerializableResultWithoutAStoredCallbackIsIgnored {
    XCTAssertNoThrow([FlutterJavaScriptInterface sendResponse:@"flutter_showToast_unknown"
                                                     success:YES
                                                        data:@(NAN)
                                                       error:nil]);
}

- (void)testSerializableResultIsAcceptedAndTheCallbackIsConsumed {
    NSString *callbackId = [self storedCallbackIdForTest:@"map"];

    XCTAssertNoThrow([FlutterJavaScriptInterface sendResponse:callbackId success:YES data:@{ @"a" : @1 } error:nil]);

    XCTAssertNil([FlutterJavaScriptInterface getAndRemoveCallbacks:callbackId]);
}

- (void)testNilResultIsAcceptedAndTheCallbackIsConsumed {
    NSString *callbackId = [self storedCallbackIdForTest:@"nil"];

    XCTAssertNoThrow([FlutterJavaScriptInterface sendResponse:callbackId success:YES data:nil error:nil]);

    XCTAssertNil([FlutterJavaScriptInterface getAndRemoveCallbacks:callbackId]);
}

- (void)testErrorResponseIsAcceptedAndTheCallbackIsConsumed {
    NSString *callbackId = [self storedCallbackIdForTest:@"error"];

    XCTAssertNoThrow([FlutterJavaScriptInterface sendResponse:callbackId success:NO data:nil error:@"boom"]);

    XCTAssertNil([FlutterJavaScriptInterface getAndRemoveCallbacks:callbackId]);
}

@end
