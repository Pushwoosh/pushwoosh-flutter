//
//  FlutterJavaScriptInterface.m
//  pushwoosh_flutter
//
//  Created by Pushwoosh on 2025
//

#import "FlutterJavaScriptInterface.h"

@implementation FlutterJavaScriptInterface

static NSMutableDictionary<NSString *, NSDictionary *> *storedCallbacks;

+ (void)initialize {
    if (self == [FlutterJavaScriptInterface class]) {
        storedCallbacks = [[NSMutableDictionary alloc] init];
    }
}

// the page can name any selector, and NSObject's KVC would write the ivars through readonly
+ (BOOL)accessInstanceVariablesDirectly {
    return NO;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"[FlutterJSInterface] Security error: refusing to set '%@' on interface '%@'", key, self.interfaceName);
}

- (instancetype)initWithName:(NSString *)name
                 methodNames:(NSArray<NSString *> *)methodNames
                 callHandler:(FlutterJSCallHandler)handler {
    self = [super init];
    // the rich media page can call this initialiser too, so the arguments are untrusted input
    if (self && [name isKindOfClass:[NSString class]] && [methodNames isKindOfClass:[NSArray class]]
        && [(id)handler isKindOfClass:NSClassFromString(@"NSBlock")]) {
        _interfaceName = name;
        _allowedMethodNames = methodNames;
        _callHandler = handler;
    } else if (self) {
        NSLog(@"[FlutterJSInterface] Security error: ignoring initialisation with unexpected argument types");
    }
    return self;
}

- (void)callFlutterMethod:(NSString *)methodName :(NSString *)argumentsJson :(id)successCallback :(id)errorCallback {
    
    if (![self.allowedMethodNames containsObject:methodName]) {
        NSString *errorMessage = [NSString stringWithFormat:@"Method '%@' is not allowed for interface '%@'", methodName, self.interfaceName];
        NSLog(@"[FlutterJSInterface] Security error: %@", errorMessage);
        
        if (errorCallback && [errorCallback isKindOfClass:[PWJavaScriptCallback class]]) {
            PWJavaScriptCallback *callback = (PWJavaScriptCallback *)errorCallback;
            NSDictionary *errorData = @{@"error": errorMessage};
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:errorData options:0 error:&error];
            if (!error) {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [callback executeWithParam:jsonString];
            }
        }
        return;
    }
    
    NSString *callbackId = [NSString stringWithFormat:@"%@_%@_%lf", 
                           self.interfaceName, methodName, [[NSDate date] timeIntervalSince1970]];
    
    // EasyJS fills the argument slots by position without type checks: a JS function can land here.
    NSData *jsonData = nil;
    if ([argumentsJson isKindOfClass:[NSString class]]) {
        jsonData = [argumentsJson dataUsingEncoding:NSUTF8StringEncoding];
    } else if (argumentsJson) {
        NSLog(@"[FlutterJSInterface] Ignoring non-string arguments (%@) for method '%@'",
              NSStringFromClass([argumentsJson class]), methodName);
    }

    NSError *error = nil;
    NSDictionary *arguments = @{};
    
    if (jsonData) {
        id parsed = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                    options:0 
                                                      error:&error];
        if (!error && [parsed isKindOfClass:[NSDictionary class]]) {
            arguments = parsed;
        }
    }
    
    [FlutterJavaScriptInterface storeCallback:callbackId 
                              successCallback:successCallback 
                                errorCallback:errorCallback];
    
    NSDictionary *callData = @{
        @"interfaceName": self.interfaceName,
        @"methodName": methodName,
        @"arguments": arguments,
        @"callbackId": callbackId
    };
    
    if (self.callHandler) {
        self.callHandler(callData);
    }
}

+ (void)storeCallback:(NSString *)callbackId 
      successCallback:(id)successCallback 
        errorCallback:(id)errorCallback {
    @synchronized(storedCallbacks) {
        if (successCallback || errorCallback) {
            NSMutableDictionary *callbacks = [NSMutableDictionary dictionary];
            if (successCallback) {
                callbacks[@"success"] = successCallback;
            }
            if (errorCallback) {
                callbacks[@"error"] = errorCallback;
            }
            storedCallbacks[callbackId] = callbacks;
        }
    }
}

+ (NSDictionary *)getAndRemoveCallbacks:(NSString *)callbackId {
    @synchronized(storedCallbacks) {
        NSDictionary *callbacks = storedCallbacks[callbackId];
        [storedCallbacks removeObjectForKey:callbackId];
        return callbacks;
    }
}

+ (void)sendResponse:(NSString *)callbackId 
             success:(BOOL)success 
                data:(id)data 
               error:(NSString *)errorMessage {
    
    NSDictionary *callbacks = [self getAndRemoveCallbacks:callbackId];
    if (!callbacks) {
        return;
    }
    
    id callbackObj = success ? callbacks[@"success"] : callbacks[@"error"];
    if (!callbackObj) {
        return;
    }
        
    NSDictionary *response;
    if (success) {
        response = @{@"result": data ?: [NSNull null]};
    } else {
        response = @{@"error": errorMessage ?: @"Unknown error"};
    }
    
    // dataWithJSONObject: raises instead of filling the error out-param, so the check below never sees this.
    if (![NSJSONSerialization isValidJSONObject:response]) {
        NSLog(@"[FlutterJS] Dropping a response that is not JSON-serializable: %@", response);
        return;
    }

    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                        options:0
                                                          error:&jsonError];

    if (jsonError) {
        return;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // iOS passes callback names as strings, not PWJavaScriptCallback objects
    if ([callbackObj isKindOfClass:[NSString class]]) {
        NSString *callbackName = (NSString *)callbackObj;
    } else {
        NSLog(@"[FlutterJS] Unexpected callback type: %@", NSStringFromClass([callbackObj class]));
    }
}

@end
