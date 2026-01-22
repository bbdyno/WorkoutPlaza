//
//  ExternalWorkoutManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import Foundation
import CoreLocation
import HealthKit

// MARK: - External Workout (Persisted)

struct ExternalWorkout: Codable, Identifiable {
    let id: UUID
    let importedAt: Date
    let sourceFileName: String?
    let creatorName: String?
    let workoutData: ExportableWorkoutData

    init(
        id: UUID = UUID(),
        importedAt: Date = Date(),
        sourceFileName: String? = nil,
        creatorName: String? = nil,
        workoutData: ExportableWorkoutData
    ) {
        self.id = id
        self.importedAt = importedAt
        self.sourceFileName = sourceFileName
        self.creatorName = creatorName
        self.workoutData = workoutData
    }

    // Convert from ShareableWorkout
    init(from shareable: ShareableWorkout, sourceFileName: String? = nil) {
        self.id = UUID()
        self.importedAt = Date()
        self.sourceFileName = sourceFileName
        self.creatorName = shareable.creator?.name
        self.workoutData = shareable.workout
    }
}

// MARK: - Unified Workout Item

enum UnifiedWorkoutSource {
    case healthKit
    case external
}

struct UnifiedWorkoutItem {
    let id: String
    let source: UnifiedWorkoutSource
    let workoutType: String
    let distance: Double
    let duration: TimeInterval
    let startDate: Date
    let endDate: Date
    let pace: Double
    let avgSpeed: Double
    let calories: Double
    let route: [CLLocation]
    let creatorName: String?

    // For HealthKit data
    let healthKitWorkout: WorkoutData?

    // For External data
    let externalWorkout: ExternalWorkout?

    // Initialize from WorkoutData (HealthKit)
    init(from healthKitData: WorkoutData) {
        self.id = healthKitData.workout.uuid.uuidString
        self.source = .healthKit
        self.workoutType = healthKitData.workoutType
        self.distance = healthKitData.distance
        self.duration = healthKitData.duration
        self.startDate = healthKitData.startDate
        self.endDate = healthKitData.endDate
        self.pace = healthKitData.pace
        self.avgSpeed = healthKitData.avgSpeed
        self.calories = healthKitData.calories
        self.route = healthKitData.route
        self.creatorName = nil
        self.healthKitWorkout = healthKitData
        self.externalWorkout = nil
    }

    // Initialize from ExternalWorkout
    init(from externalData: ExternalWorkout) {
        self.id = externalData.id.uuidString
        self.source = .external
        self.workoutType = externalData.workoutData.type
        self.distance = externalData.workoutData.distance
        self.duration = externalData.workoutData.duration
        self.startDate = externalData.workoutData.startDate
        self.endDate = externalData.workoutData.endDate
        self.pace = externalData.workoutData.pace
        self.avgSpeed = externalData.workoutData.avgSpeed
        self.calories = externalData.workoutData.calories
        self.route = externalData.workoutData.route.map { point in
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon),
                altitude: point.alt ?? 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                timestamp: point.timestamp ?? Date()
            )
        }
        self.creatorName = externalData.creatorName
        self.healthKitWorkout = nil
        self.externalWorkout = externalData
    }
}

// MARK: - External Workout Manager

class ExternalWorkoutManager {

    // MARK: - Singleton
    static let shared = ExternalWorkoutManager()

    private init() {
        loadWorkouts()
    }

    // MARK: - Storage
    private let storageKey = "external_workouts"
    private var workouts: [ExternalWorkout] = []

    // MARK: - Public Methods

    /// Get all external workouts
    func getAllWorkouts() -> [ExternalWorkout] {
        return workouts.sorted { $0.workoutData.startDate > $1.workoutData.startDate }
    }

    /// Save a new external workout
    func saveWorkout(_ workout: ExternalWorkout) {
        workouts.append(workout)
        persistWorkouts()
        NotificationCenter.default.post(name: .externalWorkoutsDidChange, object: nil)
    }

    /// Save from ShareableWorkout
    func saveWorkout(from shareable: ShareableWorkout, sourceFileName: String? = nil) -> ExternalWorkout {
        let external = ExternalWorkout(from: shareable, sourceFileName: sourceFileName)
        saveWorkout(external)
        return external
    }

    /// Delete a workout by ID
    func deleteWorkout(id: UUID) {
        workouts.removeAll { $0.id == id }
        persistWorkouts()
        NotificationCenter.default.post(name: .externalWorkoutsDidChange, object: nil)
    }

    /// Check if a workout already exists (by date and distance)
    func workoutExists(startDate: Date, distance: Double) -> Bool {
        return workouts.contains { workout in
            abs(workout.workoutData.startDate.timeIntervalSince(startDate)) < 60 &&
            abs(workout.workoutData.distance - distance) < 10
        }
    }

    // MARK: - Persistence

    private func loadWorkouts() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            workouts = try decoder.decode([ExternalWorkout].self, from: data)
            print("✅ Loaded \(workouts.count) external workouts")
        } catch {
            print("❌ Failed to load external workouts: \(error)")
            workouts = []
        }
    }

    private func persistWorkouts() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(workouts)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("✅ Saved \(workouts.count) external workouts")
        } catch {
            print("❌ Failed to save external workouts: \(error)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let externalWorkoutsDidChange = Notification.Name("externalWorkoutsDidChange")
}
