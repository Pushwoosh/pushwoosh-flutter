//
//  StopwatchWidgetBundle.swift
//  StopwatchWidget
//
//  Created by André Kis on 25.11.24.
//

import WidgetKit
import SwiftUI

@main
struct StopwatchWidgetBundle: WidgetBundle {
    @available(iOS 14.0, *)
    var body: some Widget {
        StopwatchWidgetLiveActivity()
    }
}
