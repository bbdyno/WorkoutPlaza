//
//  ShareableWorkout.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/19/26.
//

import Foundation

// MARK: - Share Type
enum ShareType: String, Codable {
    case workoutOnly = "WorkoutOnly"
    case workoutWithTemplate = "WorkoutWithTemplate"
}

// MARK: - ShareableWorkout
struct ShareableWorkout: Codable {
    let version: String
    let type: ShareType
    let createdAt: Date
    let creator: Creator?
    let workout: ExportableWorkoutData
    let template: WidgetTemplate?
    let metadata: ShareMetadata

    init(
        version: String = "1.0",
        type: ShareType = .workoutOnly,
        createdAt: Date = Date(),
        creator: Creator? = nil,
        workout: ExportableWorkoutData,
        template: WidgetTemplate? = nil,
        metadata: ShareMetadata = ShareMetadata()
    ) {
        self.version = version
        self.type = type
        self.createdAt = createdAt
        self.creator = creator
        self.workout = workout
        self.template = template
        self.metadata = metadata
    }
}

// MARK: - Creator
struct Creator: Codable {
    let name: String
    let id: String?

    init(name: String, id: String? = nil) {
        self.name = name
        self.id = id
    }
}

// MARK: - ExportableWorkoutData
struct ExportableWorkoutData: Codable {
    let type: WorkoutType
    let distance: Double       // 미터
    let duration: TimeInterval // 초
    let startDate: Date
    let endDate: Date
    let pace: Double           // 분/km
    let avgSpeed: Double       // km/h
    let calories: Double       // kcal
    let route: [RoutePoint]    // GPS 좌표
    let avgHeartRate: Double?  // bpm (이전 데이터 호환을 위해 optional)

    init(
        type: WorkoutType,
        distance: Double,
        duration: TimeInterval,
        startDate: Date,
        endDate: Date,
        pace: Double,
        avgSpeed: Double,
        calories: Double,
        route: [RoutePoint],
        avgHeartRate: Double? = nil
    ) {
        self.type = type
        self.distance = distance
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.pace = pace
        self.avgSpeed = avgSpeed
        self.calories = calories
        self.route = route
        self.avgHeartRate = avgHeartRate
    }

    // Initialize from WorkoutData
    init(from workoutData: WorkoutData) {
        self.type = workoutData.workoutType
        self.distance = workoutData.distance
        self.duration = workoutData.duration
        self.startDate = workoutData.startDate
        self.endDate = workoutData.endDate
        self.pace = workoutData.pace
        self.avgSpeed = workoutData.avgSpeed
        self.calories = workoutData.calories
        self.route = workoutData.route.map { RoutePoint(from: $0) }
        self.avgHeartRate = workoutData.avgHeartRate > 0 ? workoutData.avgHeartRate : nil
    }
}

// MARK: - RoutePoint
struct RoutePoint: Codable {
    let lat: Double
    let lon: Double
    let alt: Double?
    let timestamp: Date?

    init(lat: Double, lon: Double, alt: Double? = nil, timestamp: Date? = nil) {
        self.lat = lat
        self.lon = lon
        self.alt = alt
        self.timestamp = timestamp
    }

    // Initialize from CLLocation
    init(from location: CLLocation) {
        self.lat = location.coordinate.latitude
        self.lon = location.coordinate.longitude
        self.alt = location.altitude
        self.timestamp = location.timestamp
    }
}

// Import CoreLocation for CLLocation
import CoreLocation

// MARK: - ShareMetadata
struct ShareMetadata: Codable {
    let appVersion: String
    let platform: String
    let exportDate: Date
    let checksum: String?

    init(
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        platform: String = "iOS",
        exportDate: Date = Date(),
        checksum: String? = nil
    ) {
        self.appVersion = appVersion
        self.platform = platform
        self.exportDate = exportDate
        self.checksum = checksum
    }
}

// MARK: - Share Error
enum ShareError: LocalizedError {
    case invalidFileFormat
    case versionMismatch
    case corruptedData
    case missingRequiredFields
    case exportFailed
    case importFailed
    case invalidFileExtension
    case fileNotFound
    case encodingFailed
    case decodingFailed
    case templateVersionMismatch

    var errorDescription: String? {
        switch self {
        case .invalidFileFormat:
            return WorkoutPlazaStrings.Share.Error.Invalid.File.format
        case .versionMismatch:
            return WorkoutPlazaStrings.Share.Error.Version.mismatch
        case .corruptedData:
            return WorkoutPlazaStrings.Share.Error.Corrupted.data
        case .missingRequiredFields:
            return WorkoutPlazaStrings.Share.Error.Missing.Required.fields
        case .exportFailed:
            return WorkoutPlazaStrings.Share.Error.Export.failed
        case .importFailed:
            return WorkoutPlazaStrings.Share.Error.Import.failed
        case .invalidFileExtension:
            return WorkoutPlazaStrings.Share.Error.Invalid.File.extension
        case .fileNotFound:
            return WorkoutPlazaStrings.Share.Error.File.Not.found
        case .encodingFailed:
            return WorkoutPlazaStrings.Share.Error.Encoding.failed
        case .decodingFailed:
            return WorkoutPlazaStrings.Share.Error.Decoding.failed
        case .templateVersionMismatch:
            return WorkoutPlazaStrings.Share.Error.Template.Version.mismatch
        }
    }
}

// MARK: - Import Field
enum ImportField: String, CaseIterable, Codable {
    case distance = "distance"
    case duration = "duration"
    case pace = "pace"
    case speed = "speed"
    case calories = "calories"
    case heartRate = "heartRate"
    case date = "date"
    case route = "route"

    var displayName: String {
        switch self {
        case .distance: return WorkoutPlazaStrings.Widget.distance
        case .duration: return WorkoutPlazaStrings.Widget.duration
        case .pace: return WorkoutPlazaStrings.Widget.pace
        case .speed: return WorkoutPlazaStrings.Widget.speed
        case .calories: return WorkoutPlazaStrings.Widget.calories
        case .heartRate: return WorkoutPlazaStrings.Widget.Heart.rate
        case .date: return WorkoutPlazaStrings.Widget.date
        case .route: return WorkoutPlazaStrings.Import.Field.route
        }
    }

    var icon: String {
        switch self {
        case .distance: return "ruler"
        case .duration: return "clock"
        case .pace: return "speedometer"
        case .speed: return "gauge"
        case .calories: return "flame"
        case .heartRate: return "heart.fill"
        case .date: return "calendar"
        case .route: return "map"
        }
    }
}
