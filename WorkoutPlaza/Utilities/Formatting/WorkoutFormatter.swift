//
//  WorkoutFormatter.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/4/26.
//

import Foundation

enum WorkoutFormatter {

    // MARK: - Time Formatting

    /// Format duration in seconds to HH:MM:SS or MM:SS format
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    /// Format duration in seconds to hours and minutes (e.g., "1h 30m")
    static func formatDurationShort(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Pace Formatting (min/km)

    /// Format pace in seconds per kilometer to MM:SS format
    static func formatPace(_ secondsPerKm: Double) -> String {
        let minutes = Int(secondsPerKm) / 60
        let secs = Int(secondsPerKm) % 60
        return String(format: "%d'%02d\"", minutes, secs)
    }

    /// Format pace in minutes per kilometer (decimal) to MM:SS format
    static func formatPaceFromMinutes(_ minutesPerKm: Double) -> String {
        let secondsPerKm = minutesPerKm * 60
        return formatPace(secondsPerKm)
    }

    // MARK: - Speed Formatting (km/h)

    /// Format speed in kilometers per hour
    static func formatSpeed(_ kmPerHour: Double) -> String {
        return String(format: "%.1f", kmPerHour)
    }

    // MARK: - Distance Formatting

    /// Format distance in meters to kilometers
    static func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        if km >= 10.0 {
            return String(format: "%.1f", km)
        } else {
            return String(format: "%.2f", km)
        }
    }

    /// Format distance in meters to kilometers with unit
    static func formatDistanceWithUnit(_ meters: Double) -> String {
        let km = meters / 1000.0
        if km >= 10.0 {
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.2f km", km)
        }
    }

    // MARK: - Calories Formatting

    /// Format calories in kilocalories
    static func formatCalories(_ kcal: Double) -> String {
        if kcal >= 1000.0 {
            let kCal = kcal / 1000.0
            return String(format: "%.1f kcal", kCal)
        } else {
            return String(format: "%.0f kcal", kcal)
        }
    }

    /// Format calories as integer value
    static func formatCaloriesInteger(_ kcal: Double) -> String {
        return String(format: "%.0f", kcal)
    }

    // MARK: - Heart Rate Formatting

    /// Format heart rate in beats per minute
    static func formatHeartRate(_ bpm: Double) -> String {
        return String(format: "%.0f", bpm)
    }

    // MARK: - Cadence Formatting

    /// Format cadence in steps per minute
    static func formatCadence(_ spm: Double) -> String {
        return String(format: "%.0f", spm)
    }
}
