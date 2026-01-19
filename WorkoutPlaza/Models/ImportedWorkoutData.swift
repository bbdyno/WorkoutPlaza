//
//  ImportedWorkoutData.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/19/26.
//

import Foundation
import CoreLocation

// MARK: - Import Mode
enum ImportMode {
    case createNew
    case attachToExisting
}

// MARK: - ImportedWorkoutData
struct ImportedWorkoutData {
    let ownerName: String
    let originalData: ExportableWorkoutData
    let selectedFields: Set<ImportField>
    let importedAt: Date
    let useCurrentLayout: Bool  // If true, match current template layout

    init(
        ownerName: String,
        originalData: ExportableWorkoutData,
        selectedFields: Set<ImportField>,
        importedAt: Date = Date(),
        useCurrentLayout: Bool = false
    ) {
        self.ownerName = ownerName
        self.originalData = originalData
        self.selectedFields = selectedFields
        self.importedAt = importedAt
        self.useCurrentLayout = useCurrentLayout
    }

    // MARK: - Computed Properties

    var displayDistance: String? {
        guard selectedFields.contains(.distance) else { return nil }
        return String(format: "%.2f km", originalData.distance / 1000)
    }

    var displayDuration: String? {
        guard selectedFields.contains(.duration) else { return nil }
        let minutes = Int(originalData.duration) / 60
        let seconds = Int(originalData.duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var displayPace: String? {
        guard selectedFields.contains(.pace) else { return nil }
        let paceMinutes = Int(originalData.pace)
        let paceSeconds = Int((originalData.pace - Double(paceMinutes)) * 60)
        return String(format: "%d'%02d\"", paceMinutes, paceSeconds)
    }

    var displaySpeed: String? {
        guard selectedFields.contains(.speed) else { return nil }
        return String(format: "%.1f km/h", originalData.avgSpeed)
    }

    var displayCalories: String? {
        guard selectedFields.contains(.calories) else { return nil }
        return String(format: "%.0f kcal", originalData.calories)
    }

    var displayDate: String? {
        guard selectedFields.contains(.date) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: originalData.startDate)
    }

    var hasRoute: Bool {
        return selectedFields.contains(.route) && !originalData.route.isEmpty
    }

    // Convert route points to CLLocation array
    var routeLocations: [CLLocation] {
        guard hasRoute else { return [] }
        return originalData.route.map { point in
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon),
                altitude: point.alt ?? 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: point.timestamp ?? Date()
            )
        }
    }
}
