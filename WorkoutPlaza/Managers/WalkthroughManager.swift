//
//  WalkthroughManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/19/26.
//

import Foundation

enum WalkthroughManager {
    private static let hasCompletedKey = "walkthrough.hasCompleted"

    static var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: hasCompletedKey)
    }

    static var shouldPresentOnLaunch: Bool {
        hasCompleted == false
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: hasCompletedKey)
    }
}
