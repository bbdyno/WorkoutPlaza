//
//  ClimbingDetailViewController+Persistence.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

extension ClimbingDetailViewController {

    override func getWorkoutId() -> String {
        if let data = climbingData {
            // Climbing data might not have a UUID, so create one from session date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"
            let dateStr = formatter.string(from: data.sessionDate)
            return "climbing_\(data.gymName)_\(dateStr)"
        }
        return "default"
    }

    override func saveWorkoutCard(image: UIImage) {
        if let data = climbingData {
            let title = "\(data.gymName) - \(data.discipline)"
            WorkoutCardManager.shared.createCard(
                sportType: .climbing,
                workoutId: getWorkoutId(),
                workoutTitle: title,
                workoutDate: data.sessionDate,
                image: image
            )
        }
    }
}
