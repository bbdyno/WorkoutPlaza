//
//  AppDataManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

/// Central manager for app-local data reset operations.
final class AppDataManager {
    static let shared = AppDataManager()

    private init() {}

    func resetUserDefaultsData() {
        resetInMemoryExternalWorkouts()
        removePersistentUserDefaultsDomain()
    }

    func resetLocalDBData() {
        // Keep file-based card metadata in sync with file deletion.
        resetWorkoutCardsStore()
        removeLocalFileData()
    }

    func resetAllInAppData() {
        resetInMemoryExternalWorkouts()
        resetClimbingDataStores()
        resetWorkoutCardsStore()
        removeLocalFileData()
        removePersistentUserDefaultsDomain()
    }

    private func resetInMemoryExternalWorkouts() {
        let allExternal = ExternalWorkoutManager.shared.getAllWorkouts()
        for workout in allExternal {
            ExternalWorkoutManager.shared.deleteWorkout(id: workout.id)
        }
    }

    private func resetClimbingDataStores() {
        ClimbingDataManager.shared.saveSessions([])
        ClimbingGymManager.shared.saveGyms([])
    }

    private func resetWorkoutCardsStore() {
        WorkoutCardManager.shared.saveCards([])
    }

    private func removePersistentUserDefaultsDomain() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()
    }

    private func removeLocalFileData() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let files = (try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.hasPrefix("card_design_") && file.pathExtension == "json" {
            try? fileManager.removeItem(at: file)
        }

        let removableDirectories = ["Templates", "WorkoutCards", "WidgetPackages"]
        for directory in removableDirectories {
            let directoryURL = documentsURL.appendingPathComponent(directory, isDirectory: true)
            if fileManager.fileExists(atPath: directoryURL.path) {
                try? fileManager.removeItem(at: directoryURL)
            }
        }
    }
}
