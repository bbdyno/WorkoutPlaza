//
//  SportType.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit

// MARK: - Sport Type Enum

enum SportType: String, Codable, CaseIterable {
    case running = "Running"
    case climbing = "Climbing"

    var displayName: String {
        switch self {
        case .running: return "러닝"
        case .climbing: return "클라이밍"
        }
    }

    var iconName: String {
        switch self {
        case .running: return "figure.run"
        case .climbing: return "figure.climbing"
        }
    }

    var themeColor: UIColor {
        return ColorSystem.color(for: self)
    }

    var availableWidgetTypes: [WidgetType] {
        switch self {
        case .running:
            return [.routeMap, .distance, .duration, .pace, .speed, .calories, .date, .text, .location]
        case .climbing:
            return [.climbingGym, .climbingDiscipline, .climbingSession, .climbingRoutesByColor, .date, .text]
        }
    }
}

// MARK: - Sport Data Protocol

protocol SportDataProtocol {
    var sportType: SportType { get }
    var date: Date { get }
    var duration: TimeInterval? { get }
}

// MARK: - Exportable Sport Data Protocol

protocol ExportableSportData: Codable {
    var sportType: SportType { get }
}
