//
//  StopwatchWidgetExtensionBundle.swift
//  StopwatchWidgetExtension
//
//  Created by André Kis on 11.12.24.
//  Copyright © 2024 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct StopwatchWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        StopwatchWidgetExtension()
        StopwatchWidgetExtensionLiveActivity()
    }
}
