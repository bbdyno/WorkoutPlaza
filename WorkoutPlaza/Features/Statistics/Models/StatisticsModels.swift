//
//  StatisticsModels.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit

enum StatPeriod: Int, CaseIterable {
    case month = 0
    case year = 1
    case all = 2

    var displayName: String {
        switch self {
        case .month: return "월"
        case .year: return "년"
        case .all: return "전체"
        }
    }
}

enum StatSportType: Int, CaseIterable {
    case running = 0
    case climbing = 1

    var displayName: String {
        switch self {
        case .running: return "러닝"
        case .climbing: return "클라이밍"
        }
    }

    var sportType: SportType {
        switch self {
        case .running: return .running
        case .climbing: return .climbing
        }
    }
}

// MARK: - Stats Summary Item

struct StatsSummaryItem {
    let title: String
    let value: String
    let icon: String
    let color: UIColor
}

// MARK: - Running Stats Data

struct RunningStatsData {
    let totalDistance: Double // in km
    let runCount: Int
    let avgPace: String
    let totalTime: String
}

// MARK: - Climbing Stats Data

struct ClimbingStatsData {
    let totalRoutes: Int
    let sentRoutes: Int
    let successRate: Double
    let visitCount: Int
}
