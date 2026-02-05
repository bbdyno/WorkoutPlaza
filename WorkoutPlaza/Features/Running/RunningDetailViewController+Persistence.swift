//
//  RunningDetailViewController+Persistence.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import PhotosUI
import HealthKit

extension RunningDetailViewController {

    // MARK: - Persistence Actions
    
    // Core persistence (saveCurrentDesign, loadSavedDesign, shareImage etc.) is now in BaseWorkoutDetailViewController.
    
    override func saveCurrentDesign(completion: ((Bool) -> Void)? = nil) {
        // We can override here if we need to inject specific metadata for Running
        // But the base implementation uses 'widgets' array which is shared.
        // The one thing Base needs is a workoutId generator.
        
        super.saveCurrentDesign(completion: completion)
    }
    
    override func getWorkoutId() -> String {
        if let data = workoutData {
            return data.workout.uuid.uuidString
        } else if let imported = importedWorkoutData {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"
            let dateStr = formatter.string(from: imported.originalData.startDate)
            return "imported_\(dateStr)"
        } else if let external = externalWorkout {
            return "external_\(external.id.uuidString)"
        }
        return "default"
    }

    // MARK: - Sharing & Export
    
    override func saveWorkoutCard(image: UIImage) {
        if let data = workoutData {
            let distanceKm = data.distance / 1000
            let title = String(format: "러닝 - %.2fkm", distanceKm)
            WorkoutCardManager.shared.createCard(
                sportType: .running,
                workoutId: data.workout.uuid.uuidString,
                workoutTitle: title,
                workoutDate: data.startDate,
                image: image
            )
        } else if let imported = importedWorkoutData {
            let distanceKm = imported.originalData.distance / 1000
            let title = String(format: "러닝 - %.2fkm", distanceKm)
            WorkoutCardManager.shared.createCard(
                sportType: .running,
                workoutId: UUID().uuidString,
                workoutTitle: title,
                workoutDate: imported.originalData.startDate,
                image: image
            )
        } else if let external = externalWorkout {
            let distanceKm = external.workoutData.distance / 1000
            let title = String(format: "러닝 - %.2fkm", distanceKm)
            WorkoutCardManager.shared.createCard(
                sportType: .running,
                workoutId: external.id.uuidString,
                workoutTitle: title,
                workoutDate: external.workoutData.startDate,
                image: image
            )
        }
    }
}
