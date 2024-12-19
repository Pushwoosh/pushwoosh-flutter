//
//  NotificationService.swift
//  NotificationService
//
//  Created by Andrew Kis on 16.4.24..
//

import UserNotifications
import PushwooshFramework

/**
 Setting up Badges for Flutter
 docs: https://docs.pushwoosh.com/platform-docs/pushwoosh-sdk/cross-platform-frameworks/flutter/setting-up-badges-for-flutter
 
 1. Open your iOS project located in your_project/ios/Runner.xcworkspace and create NotificationServiceExtension
 2. Open Podfile (located in your_project/ios/Podfile) and add  NotificationService target
 
  `target ‘NotificationService’ do`
     `use_frameworks!`
  `end`

 3.  Install pods via Terminal
 `cd ios && pod install`
 
 4. Make sure that your Deployment target matches the one in the Runner target; otherwise, you might face an issue when building your app (e.g., if you specify iOS 10.0 in Runner and iOS 15.5 in NotificationService targets).
 5.  Add App Groups capability to both Runner and NotificationService targets and add a new group with the same name for both targets
 6. Add PW_APP_GROUPS_NAME info.plist flag to both Runner and NotificationService targets with the group name as its string value
 7. Add code
 */

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
       
        PWNotificationExtensionManager.shared().handle(request, contentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
