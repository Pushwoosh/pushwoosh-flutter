#import "PushwooshInboxPlugin.h"
#import "../Library/PushwooshInboxUI.h"

@interface PushwooshInboxPlugin ()

@property (nonatomic) PWIInboxViewController *inboxVC;
@property (nonatomic) NSObject<FlutterPluginRegistrar>* registrar;

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
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)closeInbox {
    [_inboxVC dismissViewControllerAnimated:YES completion:nil];
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
