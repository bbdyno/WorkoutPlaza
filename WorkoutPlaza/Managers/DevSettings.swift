//
//  DevSettings.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/7/26.
//

import Foundation

class DevSettings {

    // MARK: - Singleton
    static let shared = DevSettings()

    private init() {}

    // MARK: - Keys
    private enum Keys {
        static let pinchToResizeEnabled = "dev_pinchToResizeEnabled"
    }

    // MARK: - Properties
    var isPinchToResizeEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.pinchToResizeEnabled) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.pinchToResizeEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.pinchToResizeEnabled)
        }
    }
}
