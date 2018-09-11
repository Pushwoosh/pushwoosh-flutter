#import "PushwooshInboxPlugin.h"
#import <PushwooshInboxUI/PushwooshInboxUI.h>

@interface PushwooshInboxPlugin ()

@property (nonatomic) PWIInboxViewController *inboxVC;

@end

@implementation PushwooshInboxPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"pushwoosh_inbox"
            binaryMessenger:[registrar messenger]];
  PushwooshInboxPlugin* instance = [[PushwooshInboxPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    NSString* key = [registrar lookupKeyForAsset:@"assets/alert-2.png"];
    NSString *path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
    NSLog(@"");
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"presentInboxUI" isEqualToString:call.method]) {
        
        PWIInboxStyle *style = [PWIInboxStyle defaultStyle];
        _inboxVC = [PWIInboxUI createInboxControllerWithStyle:style];
        _inboxVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Close") style:UIBarButtonItemStylePlain target:self action:@selector(closeInbox)];
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
