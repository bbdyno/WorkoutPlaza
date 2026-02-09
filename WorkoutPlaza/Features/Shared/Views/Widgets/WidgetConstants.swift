//
//  WidgetConstants.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  WidgetConstants.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let widgetDidMove = Notification.Name("widgetDidMove")
}

enum WidgetMovePhase: String {
    case changed
    case ended
}

enum WidgetMoveNotificationUserInfoKey {
    static let phase = "phase"
}
