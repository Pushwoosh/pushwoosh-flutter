#import "PushwooshInboxPlugin.h"
#import <PushwooshInboxUI/PushwooshInboxUI.h>

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
            
            NSString *defaultImageName = params[@"defaultImageName"];
            
            if (defaultImageName) {
                UIImage *image = [self imageForAsset:defaultImageName];
                
                if (image) {
                    style.defaultImageIcon = image;
                }
            }
            
            NSString *unreadImage = params[@"unreadImage"];
            
            if (unreadImage) {
                UIImage *image = [self imageForAsset:unreadImage];
                
                if (image) {
                    style.unreadImage = image;
                }
            }
            
            NSString *listErrorImage = params[@"listErrorImage"];
            
            if (listErrorImage) {
                UIImage *image = [self imageForAsset:listErrorImage];
                
                if (image) {
                    style.listErrorImage = image;
                }
            }
            
            NSString *listEmptyImage = params[@"listEmptyImage"];
            
            if (listEmptyImage) {
                UIImage *image = [self imageForAsset:listEmptyImage];
                
                if (image) {
                    style.listEmptyImage = image;
                }
            }
            
            NSString *listErrorMessage = params[@"listErrorMessage"];
            
            if (listErrorMessage) {
                style.listErrorMessage = listErrorMessage;
            }
            
            NSString *listEmptyMessage = params[@"listEmptyMessage"];
            
            if (listEmptyMessage) {
                style.listEmptyMessage = listEmptyMessage;
            }
            
            NSString *barTitle = params[@"barTitle"];
            
            if (barTitle) {
                style.barTitle = barTitle;
            }
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
