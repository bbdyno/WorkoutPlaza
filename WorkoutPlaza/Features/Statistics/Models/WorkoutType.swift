//
//  WorkoutType.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

enum WorkoutType: String, CaseIterable, Codable {
    case running = "running"
    case climbing = "climbing"
    // 추후 운동 추가 시 여기에 케이스 추가
    // case swimming = "swimming"
    // case cycling = "cycling"

    var color: UIColor {
        switch self {
        case .running: return ColorSystem.primaryBlue
        case .climbing: return ColorSystem.primaryGreen
        }
    }

    var displayOrder: Int {
        switch self {
        case .running: return 0
        case .climbing: return 1
        }
    }

    // Backward compatibility: decode from Korean strings
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        // Try English rawValue first
        if let type = WorkoutType(rawValue: value) {
            self = type
            return
        }

        // Fallback to Korean strings for backward compatibility
        switch value {
        case "러닝":
            self = .running
        case "클라이밍":
            self = .climbing
        default:
            self = .running // Default fallback
        }
    }

    // Always encode as English rawValue
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    // Convert to SportType
    var sportType: SportType? {
        switch self {
        case .running: return .running
        case .climbing: return .climbing
        }
    }
}
