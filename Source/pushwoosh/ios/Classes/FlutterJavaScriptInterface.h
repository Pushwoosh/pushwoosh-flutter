//
//  FlutterJavaScriptInterface.h
//  pushwoosh_flutter
//
//  Created by Pushwoosh on 2024
//

#import <Foundation/Foundation.h>
#import <PushwooshCore/PWInAppManager.h>

typedef void (^FlutterJSCallHandler)(NSDictionary *callData);

@interface FlutterJavaScriptInterface : NSObject <PWJavaScriptInterface>

@property (nonatomic, strong) NSString *interfaceName;
@property (nonatomic, strong) NSArray<NSString *> *allowedMethodNames;
@property (nonatomic, copy) FlutterJSCallHandler callHandler;

- (instancetype)initWithName:(NSString *)name 
                 methodNames:(NSArray<NSString *> *)methodNames
                 callHandler:(FlutterJSCallHandler)handler;

- (void)callFlutterMethod:(NSString *)methodName :(NSString *)argumentsJson :(PWJavaScriptCallback *)successCallback :(PWJavaScriptCallback *)errorCallback;

+ (void)sendResponse:(NSString *)callbackId success:(BOOL)success data:(id)data error:(NSString *)errorMessage;
+ (void)storeCallback:(NSString *)callbackId successCallback:(PWJavaScriptCallback *)successCallback errorCallback:(PWJavaScriptCallback *)errorCallback;
+ (NSDictionary *)getAndRemoveCallbacks:(NSString *)callbackId;

@end
