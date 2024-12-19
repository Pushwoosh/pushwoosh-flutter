//
//  LiveActivityManager.swift
//  Runner
//
//  Created by André Kis on 25.11.24.
//

import ActivityKit
import Flutter
import Foundation

@available(iOS 16.1, *)
class LiveActivityManager {
    
    private var stopwatchActivity: Activity<StopwatchWidgetAttributes>? = nil
    
    func startLiveActivity(data: [String: Any]?, result: FlutterResult) {
        let attributes = StopwatchWidgetAttributes()
        
        if let info = data {
            let state = StopwatchWidgetAttributes.ContentState(
                elapsedTime: info["elapsedSeconds"] as? Int ?? 0
            )
            stopwatchActivity = try? Activity<StopwatchWidgetAttributes>.request(
                attributes: attributes, contentState: state, pushType: nil)
        } else {
            result(FlutterError(code: "418", message: "Live activity didn't invoked", details: nil))
        }
    }
    
    func updateLiveActivity(data: [String: Any]?, result: FlutterResult) {
        if let info = data {
            let updatedState = StopwatchWidgetAttributes.ContentState(
                elapsedTime: info["elapsedSeconds"] as? Int ?? 0
            )
            
            Task {
                await stopwatchActivity?.update(using: updatedState)
            }
        } else {
            result(FlutterError(code: "418", message: "Live activity didn't updated", details: nil))
        }
    }
    
    func stopLiveActivity(result: FlutterResult) {
        do {
            Task {
                await stopwatchActivity?.end(using: nil, dismissalPolicy: .immediate)
            }
        } catch {
            result(FlutterError(code: "418", message: error.localizedDescription, details: nil))
        }
    }
}
