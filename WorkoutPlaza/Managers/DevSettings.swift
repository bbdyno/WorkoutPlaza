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
        static let inAppBrowserAddressBarVisible = "dev_inAppBrowserAddressBarVisible"
        static let inAppBrowserToolbarVisible = "dev_inAppBrowserToolbarVisible"
        static let inAppBrowserPresentedAsSheet = "dev_inAppBrowserPresentedAsSheet"
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

    var isInAppBrowserAddressBarVisible: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.inAppBrowserAddressBarVisible) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.inAppBrowserAddressBarVisible)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.inAppBrowserAddressBarVisible)
        }
    }

    var isInAppBrowserToolbarVisible: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.inAppBrowserToolbarVisible) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.inAppBrowserToolbarVisible)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.inAppBrowserToolbarVisible)
        }
    }

    var isInAppBrowserPresentedAsSheet: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.inAppBrowserPresentedAsSheet) == nil {
                return false
            }
            return UserDefaults.standard.bool(forKey: Keys.inAppBrowserPresentedAsSheet)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.inAppBrowserPresentedAsSheet)
        }
    }
}
