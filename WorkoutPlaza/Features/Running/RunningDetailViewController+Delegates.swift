//
//  RunningDetailViewController+Delegates.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers

// MARK: - ImportWorkoutViewControllerDelegate
extension RunningDetailViewController: ImportWorkoutViewControllerDelegate {
    func importWorkoutViewController(_ controller: ImportWorkoutViewController, didImport data: ImportedWorkoutData, mode: ImportMode, attachTo: WorkoutData?) {
        // Add imported workout as a group
        addImportedWorkoutGroup(data)
    }

    func importWorkoutViewControllerDidCancel(_ controller: ImportWorkoutViewController) {
        // Nothing to do
    }
}
