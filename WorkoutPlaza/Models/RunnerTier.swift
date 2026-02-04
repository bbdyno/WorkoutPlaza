//
//  RunnerTier.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit

enum RunnerTier: String, Codable, CaseIterable {
    case beginner = "beginner"
    case runner = "runner"
    case marathoner = "marathoner"
    case elite = "elite"
    case legend = "legend"
    
    var displayName: String {
        switch self {
        case .beginner: return "초보자"
        case .runner: return "러너"
        case .marathoner: return "마라토너"
        case .elite: return "엘리트"
        case .legend: return "레전드"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .runner: return "🥉"
        case .marathoner: return "🥈"
        case .elite: return "🥇"
        case .legend: return "👑"
        }
    }
    
    var themeColor: UIColor {
        switch self {
        case .beginner: return ColorSystem.primaryBlue
        case .runner: return UIColor(red: 45/255, green: 180/255, blue: 109/255, alpha: 1.0)
        case .marathoner: return UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: 1.0)
        case .elite: return UIColor(red: 255/255, green: 159/255, blue: 10/255, alpha: 1.0)
        case .legend: return UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
        }
    }
    
    var minDistance: Double {
        switch self {
        case .beginner: return 0
        case .runner: return 50
        case .marathoner: return 200
        case .elite: return 500
        case .legend: return 1000
        }
    }
    
    var nextTier: RunnerTier? {
        switch self {
        case .beginner: return .runner
        case .runner: return .marathoner
        case .marathoner: return .elite
        case .elite: return .legend
        case .legend: return nil
        }
    }
    
    var nextTierDistance: Double? {
        return nextTier?.minDistance
    }
    
    static func tier(for distance: Double) -> RunnerTier {
        if distance >= 1000 { return .legend }
        if distance >= 500 { return .elite }
        if distance >= 200 { return .marathoner }
        if distance >= 50 { return .runner }
        return .beginner
    }
    
    func progress(to distance: Double) -> Double {
        guard let nextTier = nextTier else { return 1.0 }
        let currentProgress = distance - minDistance
        let totalProgress = nextTier.minDistance - minDistance
        return min(max(currentProgress / totalProgress, 0), 1)
    }
    
    func remainingDistance(to distance: Double) -> Double? {
        guard let next = nextTier else { return nil }
        return max(next.minDistance - distance, 0)
    }
}
