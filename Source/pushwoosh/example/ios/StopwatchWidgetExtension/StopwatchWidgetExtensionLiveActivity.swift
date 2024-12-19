//
//  StopwatchWidgetExtensionLiveActivity.swift
//  StopwatchWidgetExtension
//
//  Created by André Kis on 11.12.24.
//  Copyright © 2024 The Chromium Authors. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StopwatchWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct StopwatchWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StopwatchWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension StopwatchWidgetExtensionAttributes {
    fileprivate static var preview: StopwatchWidgetExtensionAttributes {
        StopwatchWidgetExtensionAttributes(name: "World")
    }
}

extension StopwatchWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: StopwatchWidgetExtensionAttributes.ContentState {
        StopwatchWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: StopwatchWidgetExtensionAttributes.ContentState {
         StopwatchWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: StopwatchWidgetExtensionAttributes.preview) {
   StopwatchWidgetExtensionLiveActivity()
} contentStates: {
    StopwatchWidgetExtensionAttributes.ContentState.smiley
    StopwatchWidgetExtensionAttributes.ContentState.starEyes
}
