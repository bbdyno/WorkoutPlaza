//
//  AnalyticsManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/30/26.
//

import Foundation
import FirebaseAnalytics

/// Wrapper for Firebase Analytics to standardize event logging
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Core Logging
    
    /// Log a standard event
    /// - Parameters:
    ///   - name: Event name
    ///   - parameters: Event parameters
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
    
    // MARK: - Business Events
    
    /// Log when the app is opened
    func logAppOpen() {
        logEvent(AnalyticsEventAppOpen)
    }
    
    /// Log Remote Config fetch result
    /// - Parameter status: "success", "failure", or "throttled"
    func logRemoteConfigFetch(status: String, details: String? = nil) {
        var params: [String: Any] = [
            "status": status
        ]
        if let details = details {
            params["details"] = details
        }
        logEvent("remote_config_fetch", parameters: params)
    }
    
    /// Log when gyms are loaded from any source (cache or remote)
    /// - Parameters:
    ///   - count: Number of gyms loaded
    ///   - source: "remote" or "cache"
    func logGymsLoaded(count: Int, source: String) {
        logEvent("gyms_loaded", parameters: [
            "count": count,
            "source": source
        ])
    }
}
