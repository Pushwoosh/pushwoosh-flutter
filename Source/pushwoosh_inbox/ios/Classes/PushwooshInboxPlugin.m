#import "PushwooshInboxPlugin.h"
#import <PushwooshInboxUI/PushwooshInboxUI.h>
#import <Pushwoosh/PWInbox.h>

@interface PushwooshInboxPlugin ()

@property (nonatomic) PWIInboxViewController *inboxVC;
@property (nonatomic) NSObject<FlutterPluginRegistrar>* registrar;

@end

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

@implementation PushwooshInboxPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"pushwoosh_inbox"
                                     binaryMessenger:[registrar messenger]];
    PushwooshInboxPlugin* instance = [[PushwooshInboxPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    instance.registrar = registrar;
}

- (UIImage *)imageForAsset:(NSString *)asset {
    NSString* key = [_registrar lookupKeyForAsset:asset];
    NSString *path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
    
    if (path) {
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        
        if (image) {
            return image;
        }
    }
    
    return nil;
}

- (UIColor *)colorFromColorString:(NSString *)colorString {
    // No value, nothing to do
    if (!colorString) {
        return nil;
    }
    
    // Validate format
    NSError* error = NULL;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^(#[0-9A-F]{3}|(0x|#)([0-9A-F]{2})?[0-9A-F]{6})$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSUInteger countMatches = [regex numberOfMatchesInString:colorString options:0 range:NSMakeRange(0, [colorString length])];
    
    if (!countMatches) {
        return nil;
    }
    
    // #FAB to #FFAABB
    if ([colorString hasPrefix:@"#"] && [colorString length] == 4) {
        NSString* r = [colorString substringWithRange:NSMakeRange(1, 1)];
        NSString* g = [colorString substringWithRange:NSMakeRange(2, 1)];
        NSString* b = [colorString substringWithRange:NSMakeRange(3, 1)];
        colorString = [NSString stringWithFormat:@"#%@%@%@%@%@%@", r, r, g, g, b, b];
    }
    
    // #RRGGBB to 0xRRGGBB
    colorString = [colorString stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
    
    // 0xRRGGBB to 0xAARRGGBB
    if ([colorString hasPrefix:@"0x"] && [colorString length] == 8) {
        colorString = [@"0xFF" stringByAppendingString:[colorString substringFromIndex:2]];
    }
    
    // 0xAARRGGBB to int
    unsigned colorValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    if (![scanner scanHexInt:&colorValue]) {
        return nil;
    }
    
    // int to UIColor
    return [UIColor colorWithRed:((float)((colorValue & 0x00FF0000) >> 16))/255.0
                           green:((float)((colorValue & 0x0000FF00) >>  8))/255.0
                            blue:((float)((colorValue & 0x000000FF) >>  0))/255.0
                           alpha:((float)((colorValue & 0xFF000000) >> 24))/255.0];
}

- (UIImage *)imageFromInboxStyleDict:(NSDictionary *)dict forKey:(NSString *)key {
    NSString *asset = dict[key];
    
    if (asset != nil && [asset isKindOfClass:[NSString class]]) {
        return [self imageForAsset:asset];
    }
    return nil;
}

- (UIColor *)colorFromInboxStyleDict:(NSDictionary *)dict forKey:(NSString *)key {
    NSString *object = dict[key];
    
    if (object != nil && [object isKindOfClass:[NSString class]]) {
        return [self colorFromColorString:object];
    }
    return nil;
}

- (NSString *)stringFromInboxStyleDict:(NSDictionary *)dict forKey:(NSString *)key {
    NSString *object = dict[key];
    
    if (object != nil && [object isKindOfClass:[NSString class]]) {
        return object;
    }
    return nil;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"presentInboxUI" isEqualToString:call.method]) {
        [self presentInboxUI:call result:result];
    } else if ([@"messagesWithNoActionPerformedCount" isEqualToString:call.method]){
        [self messagesWithNoActionPerformedCount:call result: result];
    } else if ([@"unreadMessagesCount" isEqualToString:call.method]) {
        [self unreadMessagesCount:call result:result];
    } else if ([@"messagesCount" isEqualToString:call.method]) {
        [self messagesCount:call result: result];
    } else if ([@"loadMessages" isEqualToString: call.method]) {
        [self loadMessages:call result:result];
    } else if ([@"loadCachedMessages" isEqualToString: call.method]) {
        [self loadMessages:call result:result];
    } else if ([@"readMessage" isEqualToString: call.method]) {
        [self readMessage:call result:result];
    } else if ([@"readMessages" isEqualToString:call.method]) {
        [self readMessages:call result:result];
    } else if ([@"deleteMessage" isEqualToString:call.method]) {
        [self deleteMessage:call result:result];
    } else if ([@"deleteMessages" isEqualToString:call.method]) {
        [self deleteMessages:call result:result];
    } else if ([@"performAction" isEqualToString:call.method]) {
        [self performAction:call result:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)messagesWithNoActionPerformedCount:(FlutterMethodCall*)call result:(FlutterResult) result {
    [PWInbox messagesWithNoActionPerformedCountWithCompletion:^(NSInteger count, NSError *error) {
        if (!error) {
            result(@(count));
        } else result(error.flutterError);
    }];
}

- (void)unreadMessagesCount:(FlutterMethodCall*)call result:(FlutterResult) result {
    [PWInbox unreadMessagesCountWithCompletion:^(NSInteger count, NSError *error) {
        if (!error) {
            result(@(count));
        } else result(error.flutterError);
    }];
}

- (void)messagesCount:(FlutterMethodCall*)call result:(FlutterResult) result {
    [PWInbox messagesCountWithCompletion:^(NSInteger count, NSError *error) {
        if (!error) {
            result(@(count));
        } else result(error.flutterError);
    }];
}

- (void)loadMessages:(FlutterMethodCall*) call result: (FlutterResult) result {
    [PWInbox loadMessagesWithCompletion:^(NSArray<NSObject<PWInboxMessageProtocol> *> *messages, NSError* error) {
        if (!error) {
            NSMutableArray* array = [[NSMutableArray alloc] init];
            for (NSObject<PWInboxMessageProtocol>* message in messages) {
                NSData* json = [self toJson:message];
                NSString* jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
                [array addObject:jsonString];
            }
            result(array);
        } else result(error.flutterError);
    }];
}

- (void)readMessage:(FlutterMethodCall*) call result:(FlutterResult) result {
    NSString* code = [call.arguments objectForKey:@"code"];
    NSArray* codes= [[NSArray alloc] initWithObjects:code, nil];
    [PWInbox readMessagesWithCodes:codes];
    result(nil);
}

- (void)readMessages:(FlutterMethodCall*) call result:(FlutterResult) result {
    NSArray<NSString*> *codes = [call.arguments objectForKey:@"codes"];
    [PWInbox readMessagesWithCodes:codes];
    result(nil);
}

- (void)deleteMessage:(FlutterMethodCall*) call result:(FlutterResult) result {
    NSString* code = [call.arguments objectForKey:@"code"];
    NSArray* codes= [[NSArray alloc] initWithObjects:code, nil];
    [PWInbox deleteMessagesWithCodes:codes];
    result(nil);
}

- (void)deleteMessages:(FlutterMethodCall*) call result:(FlutterResult) result {
    NSArray<NSString*> *codes = [call.arguments objectForKey:@"codes"];
    [PWInbox deleteMessagesWithCodes:codes];
    result(nil);
}

- (void)performAction:(FlutterMethodCall*) call result:(FlutterResult) result {
    NSString* code = [call.arguments objectForKey:@"code"];
    [PWInbox performActionForMessageWithCode:code];
    result(nil);
}

- (void)presentInboxUI: (FlutterMethodCall*)call result:(FlutterResult) result  {
    PWIInboxStyle *style = [PWIInboxStyle defaultStyle];
        
        NSDictionary *params = call.arguments;
        
        if (params) {
            NSString *dateFormat = params[@"dateFormat"];
            
            if (dateFormat) {
                style.dateFormatterBlock = ^NSString *(NSDate *date, NSObject *owner) {
                    NSDateFormatter *dateFormatter = [NSDateFormatter new];
                    dateFormatter.dateFormat = dateFormat;
                    return [dateFormatter stringFromDate:date];
                };
            }
            
            #define\
                styleValue(prop, key, type) {\
                    id val = [self type##FromInboxStyleDict:params forKey:key];\
                    if (val != nil)\
                        prop = val;\
                }
            
            styleValue(style.defaultImageIcon, @"defaultImage", image);
            styleValue(style.unreadImage, @"unreadImage", image);
            styleValue(style.listErrorImage, @"listErrorImage", image);
            styleValue(style.listEmptyImage, @"listEmptyImage", image);

            styleValue(style.listErrorMessage, @"listErrorMessage", string);
            styleValue(style.listEmptyMessage, @"listEmptyMessage", string);
            styleValue(style.barTitle, @"barTitle", string);
            
            styleValue(style.defaultTextColor, @"defaultTextColor", color);
            styleValue(style.accentColor, @"accentColor", color);
            styleValue(style.backgroundColor, @"backgroundColor", color);
            styleValue(style.selectionColor, @"highlightColor", color);
            styleValue(style.dateColor, @"dateColor", color);
            styleValue(style.titleColor, @"titleColor", color);
            styleValue(style.separatorColor, @"dividerColor", color);
            styleValue(style.descriptionColor, @"descriptionColor", color);
            styleValue(style.barBackgroundColor, @"barBackgroundColor", color);
            styleValue(style.barAccentColor, @"barAccentColor", color);
            styleValue(style.barTextColor, @"barTextColor", color);
        }
        
        _inboxVC = [PWIInboxUI createInboxControllerWithStyle:style];
        _inboxVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeInbox)];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:_inboxVC];
        UIViewController *topViewController = [self findTopViewController];
        [topViewController presentViewController:nc animated:YES completion:nil];

        result(nil);
}

- (void)closeInbox {
    [_inboxVC dismissViewControllerAnimated:YES completion:nil];
}

- (NSData*)toJson:(NSObject<PWInboxMessageProtocol>*) message {
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:@(message.type) forKey:@"type"];
    [dictionary setValue:[self stringOrEmpty: message.imageUrl] forKey:@"imageUrl"];
    [dictionary setValue:[self stringOrEmpty: message.code] forKey:@"code"];
    [dictionary setValue:[self stringOrEmpty: message.title] forKey:@"title"];
    [dictionary setValue:[self stringOrEmpty: message.message] forKey:@"message"];
    [dictionary setValue:[self stringOrEmpty: [self dateToString:message.sendDate]] forKey:@"sendDate"];
    [dictionary setValue:@(message.isRead) forKey:@"isRead"];
    [dictionary setValue:@(message.isActionPerformed) forKey:@"isActionPerformed"];
    [dictionary setValue:[self dictionaryOrEmpty:message.actionParams] forKey:@"actionParams"];

    NSDictionary* actionParams = [NSDictionary dictionaryWithDictionary:message.actionParams];
    NSData* customData = [actionParams valueForKey:@"u"];
    if (customData != nil) {
        [dictionary setValue:customData forKey:@"customData"];
    }
    
    NSError * error = nil;
    NSData* json = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return [[NSData alloc] init];   
    }
    return json;
}

- (NSString *)stringOrEmpty:(NSString *)string {
    return string != nil ? string : @"";
}

- (NSDictionary *)dictionaryOrEmpty:(NSDictionary *)dict {
    return dict != nil ? dict : @{};
}

- (NSString*)dateToString:(NSDate*)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    return [formatter stringFromDate:date];
}

- (UIViewController*)findTopViewController {
    UIApplication *sharedApplication = [UIApplication valueForKey:@"sharedApplication"];
    UIViewController *controller = sharedApplication.keyWindow.rootViewController;
    
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    return controller;
}

@end
