//
//  PushwooshSwizzleGuardTests.m
//  RunnerTests
//
//  Created by Pushwoosh on 2026
//

#import <XCTest/XCTest.h>

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import <pushwoosh_flutter/PushwooshPlugin.h>

// The swizzle installs this C function on the app delegate class; the tests need its address to tell
// our replacement from a host implementation. It has external linkage in PushwooshPlugin.m.
extern void _replacement_didReceiveRemoteNotification(id self,
                                                      SEL _cmd,
                                                      UIApplication *application,
                                                      NSDictionary *userInfo,
                                                      void (^completionHandler)(UIBackgroundFetchResult));

// Private to PushwooshPlugin.m, and the whole crash lives in it: every +registerWithRegistrar: calls
// it, and a second FlutterEngine in the process means a second +registerWithRegistrar:.
@interface PushwooshPlugin (PushwooshSwizzleGuardTests)
+ (void)swizzleNotificationSettingsHandler;
@end

typedef void (*PWDidReceiveRemoteNotificationImp)(id,
                                                  SEL,
                                                  UIApplication *,
                                                  NSDictionary *,
                                                  void (^)(UIBackgroundFetchResult));

// Sentinel for "the site never called the completion handler" — UIBackgroundFetchResult has no such
// value, and UIKit kills the app when the handler is skipped.
static const NSInteger PWFetchResultNotReported = -1;

static NSUInteger pwHostImplementationCalls = 0;

// A host's own handler for the selector. It reports Failed — a result the replacement never produces
// for the payload below, so a test can tell whose answer reached the completion handler.
static void pw_hostDidReceiveRemoteNotification(id self,
                                                SEL _cmd,
                                                UIApplication *application,
                                                NSDictionary *userInfo,
                                                void (^completionHandler)(UIBackgroundFetchResult)) {
    pwHostImplementationCalls++;
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultFailed);
    }
}

static NSUInteger pwForeignSwizzleCalls = 0;
static IMP pwForeignSwizzleOriginal = NULL;

// Another SDK swizzling the same selector: it keeps whatever IMP it found and calls it, which is
// what every swizzle in the wild does — including the native Pushwoosh SDK's own.
static void pw_foreignDidReceiveRemoteNotification(id self,
                                                   SEL _cmd,
                                                   UIApplication *application,
                                                   NSDictionary *userInfo,
                                                   void (^completionHandler)(UIBackgroundFetchResult)) {
    pwForeignSwizzleCalls++;
    if (pwForeignSwizzleOriginal != NULL) {
        ((PWDidReceiveRemoteNotificationImp)pwForeignSwizzleOriginal)(self, _cmd, application, userInfo, completionHandler);
    } else if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

static id pwStandInDelegate = nil;
static IMP pwOriginalDelegateGetter = NULL;

// The tests need the plugin to see their delegate. Assigning UIApplication.delegate is not an
// option — restoring the app's own delegate afterwards kills the test host with SIGSEGV.
static id pw_delegateGetter(id self, SEL _cmd) {
    if (pwStandInDelegate != nil) {
        return pwStandInDelegate;
    }
    return ((id (*)(id, SEL))pwOriginalDelegateGetter)(self, _cmd);
}

@interface PushwooshSwizzleGuardTests : XCTestCase
@property (nonatomic, strong) NSMutableArray *delegates;
@end

@implementation PushwooshSwizzleGuardTests

+ (void)setUp {
    [super setUp];

    // Installing it twice in one process (test repetitions) would make the getter call itself.
    if (pwOriginalDelegateGetter == NULL) {
        Method getter = class_getInstanceMethod([UIApplication class], @selector(delegate));
        pwOriginalDelegateGetter = method_setImplementation(getter, (IMP)pw_delegateGetter);
    }
}

- (void)setUp {
    [super setUp];

    self.continueAfterFailure = NO;
    self.delegates = [NSMutableArray array];
    pwHostImplementationCalls = 0;
    pwForeignSwizzleCalls = 0;
    pwForeignSwizzleOriginal = NULL;
}

- (void)tearDown {
    pwStandInDelegate = nil;
    [super tearDown];
}

#pragma mark - helpers

- (SEL)selector {
    return @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
}

// A fresh class per registration: the swizzle keeps process-global state, so a class reused across
// tests would carry the previous test's swizzle. Classes are never disposed for the same reason.
- (Class)makeDelegateClassWithSuperclass:(Class)superclass hostImplementation:(BOOL)hostImplementation {
    static NSUInteger counter = 0;
    NSString *name = [NSString stringWithFormat:@"PWSwizzleGuardDelegate%lu", (unsigned long)++counter];
    Class delegateClass = objc_allocateClassPair(superclass, name.UTF8String, 0);
    XCTAssertTrue(delegateClass != Nil);
    if (hostImplementation) {
        class_addMethod(delegateClass, [self selector], (IMP)pw_hostDidReceiveRemoteNotification, "v@:@@@?");
    }
    class_addProtocol(delegateClass, @protocol(UIApplicationDelegate));
    objc_registerClassPair(delegateClass);
    return delegateClass;
}

// One registration = one +registerWithRegistrar:, i.e. one FlutterEngine registering its plugins.
- (id)registerDelegateOfClass:(Class)delegateClass times:(NSUInteger)times {
    id delegate = [[delegateClass alloc] init];
    [self.delegates addObject:delegate];
    pwStandInDelegate = delegate;
    for (NSUInteger i = 0; i < times; i++) {
        [PushwooshPlugin swizzleNotificationSettingsHandler];
    }
    return delegate;
}

// Root `data` is a dictionary, so no value-shaped crash of a neighbouring candidate can steal the
// verdict; with no host implementation underneath, the replacement reports NewData for it.
- (NSDictionary *)benignPayload {
    return @{
        @"aps" : @{ @"content-available" : @1 },
        @"p" : @"swzRec01",
        @"data" : @{ @"custom" : @"payload" }
    };
}

- (NSInteger)deliverTo:(id)delegate {
    __block NSInteger reported = PWFetchResultNotReported;
    __block NSUInteger calls = 0;

    SEL selector = [self selector];
    // Dispatch the way UIKit does: through whatever IMP the delegate class carries after the swizzle.
    IMP imp = class_getMethodImplementation([delegate class], selector);
    ((PWDidReceiveRemoteNotificationImp)imp)(delegate,
                                             selector,
                                             [UIApplication sharedApplication],
                                             [self benignPayload],
                                             ^(UIBackgroundFetchResult result) {
        calls++;
        reported = (NSInteger)result;
    });

    XCTAssertEqual(calls, 1u);
    return reported;
}

#pragma mark - ground truth: a registration really swizzles the delegate class

- (void)testFirstRegistrationInstallsTheReplacementOnAStockDelegate {
    id delegate = [self registerDelegateOfClass:[self makeDelegateClassWithSuperclass:[NSObject class]
                                                                   hostImplementation:NO]
                                          times:1];
    IMP installed = class_getMethodImplementation([delegate class], [self selector]);
    XCTAssertEqual(installed, (IMP)_replacement_didReceiveRemoteNotification);
}

- (void)testFirstRegistrationInstallsTheReplacementOverAHostImplementation {
    id delegate = [self registerDelegateOfClass:[self makeDelegateClassWithSuperclass:[NSObject class]
                                                                   hostImplementation:YES]
                                          times:1];
    IMP installed = class_getMethodImplementation([delegate class], [self selector]);
    XCTAssertEqual(installed, (IMP)_replacement_didReceiveRemoteNotification);
}

#pragma mark - controls: one registration, the shape the plugin has always supported

- (void)testSingleRegistrationOnAStockDelegateReportsNewData {
    id delegate = [self registerDelegateOfClass:[self makeDelegateClassWithSuperclass:[NSObject class]
                                                                   hostImplementation:NO]
                                          times:1];
    XCTAssertEqual([self deliverTo:delegate], UIBackgroundFetchResultNewData);
    XCTAssertEqual(pwHostImplementationCalls, 0u);
}

- (void)testSingleRegistrationForwardsToTheHostImplementation {
    id delegate = [self registerDelegateOfClass:[self makeDelegateClassWithSuperclass:[NSObject class]
                                                                   hostImplementation:YES]
                                          times:1];
    XCTAssertEqual([self deliverTo:delegate], UIBackgroundFetchResultFailed);
    XCTAssertEqual(pwHostImplementationCalls, 1u);
}

#pragma mark - guard: a second registration of the same delegate class

- (void)testSecondRegistrationOnAStockDelegateStillReportsNewData {
    id delegate = [self registerDelegateOfClass:[self makeDelegateClassWithSuperclass:[NSObject class]
                                                                   hostImplementation:NO]
                                          times:2];
    XCTAssertEqual([self deliverTo:delegate], UIBackgroundFetchResultNewData);
    XCTAssertEqual(pwHostImplementationCalls, 0u);
}

- (void)testSecondRegistrationKeepsTheHostImplementationReachable {
    id delegate = [self registerDelegateOfClass:[self makeDelegateClassWithSuperclass:[NSObject class]
                                                                   hostImplementation:YES]
                                          times:2];
    XCTAssertEqual([self deliverTo:delegate], UIBackgroundFetchResultFailed);
    XCTAssertEqual(pwHostImplementationCalls, 1u);
}

- (void)testThirdRegistrationOnAStockDelegateStillReportsNewData {
    id delegate = [self registerDelegateOfClass:[self makeDelegateClassWithSuperclass:[NSObject class]
                                                                   hostImplementation:NO]
                                          times:3];
    XCTAssertEqual([self deliverTo:delegate], UIBackgroundFetchResultNewData);
}

#pragma mark - guard: a delegate class that inherits an already swizzled method

- (void)testSubclassRegistrationOnAStockDelegateStillReportsNewData {
    Class base = [self makeDelegateClassWithSuperclass:[NSObject class] hostImplementation:NO];
    [self registerDelegateOfClass:base times:1];
    // A different class, so the "same class twice" guard does not fire — but the method it inherits
    // is already ours.
    id delegate = [self registerDelegateOfClass:[self makeDelegateClassWithSuperclass:base
                                                                   hostImplementation:NO]
                                          times:1];
    XCTAssertEqual([self deliverTo:delegate], UIBackgroundFetchResultNewData);
    XCTAssertEqual(pwHostImplementationCalls, 0u);
}

#pragma mark - guard: someone else swizzles the selector between two registrations

- (void)testRegistrationAfterAForeignSwizzleKeepsBothHandlersReachable {
    Class delegateClass = [self makeDelegateClassWithSuperclass:[NSObject class] hostImplementation:NO];
    id delegate = [self registerDelegateOfClass:delegateClass times:1];

    Method method = class_getInstanceMethod(delegateClass, [self selector]);
    pwForeignSwizzleOriginal = method_setImplementation(method, (IMP)pw_foreignDidReceiveRemoteNotification);

    // The class no longer carries our replacement, so only the "same class twice" guard stands
    // between this registration and a chain that walks into itself.
    [PushwooshPlugin swizzleNotificationSettingsHandler];

    XCTAssertEqual([self deliverTo:delegate], UIBackgroundFetchResultNewData);
    XCTAssertEqual(pwForeignSwizzleCalls, 1u);
}

- (void)testSubclassRegistrationKeepsTheHostImplementationReachable {
    Class base = [self makeDelegateClassWithSuperclass:[NSObject class] hostImplementation:YES];
    [self registerDelegateOfClass:base times:1];
    id delegate = [self registerDelegateOfClass:[self makeDelegateClassWithSuperclass:base
                                                                   hostImplementation:NO]
                                          times:1];
    XCTAssertEqual([self deliverTo:delegate], UIBackgroundFetchResultFailed);
    XCTAssertEqual(pwHostImplementationCalls, 1u);
}

@end
