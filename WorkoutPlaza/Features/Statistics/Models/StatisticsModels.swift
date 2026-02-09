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
        case .month: return WorkoutPlazaStrings.Statistics.Period.month
        case .year: return WorkoutPlazaStrings.Statistics.Period.year
        case .all: return WorkoutPlazaStrings.Statistics.Period.all
        }
    }
}

enum StatSportType: Int, CaseIterable {
    case running = 0
    case climbing = 1

    var displayName: String {
        switch self {
        case .running: return WorkoutPlazaStrings.Workout.running
        case .climbing: return WorkoutPlazaStrings.Workout.climbing
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
