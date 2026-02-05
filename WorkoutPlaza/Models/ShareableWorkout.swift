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
    let type: String           // "러닝", "사이클링" 등
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
        type: String,
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

    var errorDescription: String? {
        switch self {
        case .invalidFileFormat:
            return "잘못된 파일 형식입니다."
        case .versionMismatch:
            return "파일 버전이 지원되지 않습니다."
        case .corruptedData:
            return "파일 데이터가 손상되었습니다."
        case .missingRequiredFields:
            return "필수 데이터가 누락되었습니다."
        case .exportFailed:
            return "내보내기에 실패했습니다."
        case .importFailed:
            return "가져오기에 실패했습니다."
        case .invalidFileExtension:
            return "지원되지 않는 파일 확장자입니다."
        case .fileNotFound:
            return "파일을 찾을 수 없습니다."
        case .encodingFailed:
            return "데이터 인코딩에 실패했습니다."
        case .decodingFailed:
            return "데이터 디코딩에 실패했습니다."
        }
    }
}

// MARK: - Import Field
enum ImportField: String, CaseIterable, Codable {
    case distance = "거리"
    case duration = "시간"
    case pace = "페이스"
    case speed = "속도"
    case calories = "칼로리"
    case heartRate = "심박수"
    case date = "날짜"
    case route = "경로"

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
