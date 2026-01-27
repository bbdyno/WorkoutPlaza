//
//  WorkoutType.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

enum WorkoutType: CaseIterable {
    case running
    case climbing
    // 추후 운동 추가 시 여기에 케이스 추가
    // case swimming
    // case cycling

    var color: UIColor {
        switch self {
        case .running: return .systemBlue
        case .climbing: return .systemOrange
        }
    }

    var displayOrder: Int {
        switch self {
        case .running: return 0
        case .climbing: return 1
        }
    }
}
