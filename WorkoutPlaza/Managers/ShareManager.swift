//
//  ShareManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/19/26.
//

import Foundation
import UIKit

class ShareManager {

    // MARK: - Singleton
    static let shared = ShareManager()

    private init() {}

    // MARK: - File Extension
    static let fileExtension = "wplaza"
    static let mimeType = "application/json"
    static let uti = "com.workoutplaza.workout"

    // MARK: - Export

    /// Export workout data to a .wplaza file
    /// - Parameters:
    ///   - workoutData: The workout data to export
    ///   - template: Optional widget template to include
    ///   - creatorName: Optional creator name
    /// - Returns: URL of the exported file
    func exportWorkout(
        _ workoutData: WorkoutData,
        template: WidgetTemplate? = nil,
        creatorName: String? = nil
    ) throws -> URL {
        // Create exportable workout data
        let exportableData = ExportableWorkoutData(from: workoutData)

        // Create creator if name provided
        let creator = creatorName.map { Creator(name: $0) }

        // Determine share type
        let shareType: ShareType = template != nil ? .workoutWithTemplate : .workoutOnly

        // Create shareable workout
        let shareableWorkout = ShareableWorkout(
            version: "1.0",
            type: shareType,
            createdAt: Date(),
            creator: creator,
            workout: exportableData,
            template: template,
            metadata: ShareMetadata()
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let jsonData = try? encoder.encode(shareableWorkout) else {
            throw ShareError.encodingFailed
        }

        // Create file name
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: workoutData.startDate)
        let fileName = "workout_\(dateString).\(ShareManager.fileExtension)"

        // Get temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        // Write to file
        do {
            try jsonData.write(to: fileURL)
            print("✅ Exported workout to: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ Export failed: \(error)")
            throw ShareError.exportFailed
        }
    }

    // MARK: - Import

    /// Import workout data from a .wplaza file
    /// - Parameter url: URL of the file to import
    /// - Returns: ShareableWorkout containing the imported data
    func importWorkout(from url: URL) throws -> ShareableWorkout {
        // Validate file extension
        guard url.pathExtension.lowercased() == ShareManager.fileExtension else {
            throw ShareError.invalidFileExtension
        }

        // Start accessing security-scoped resource if needed
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Read file data
        guard let jsonData = try? Data(contentsOf: url) else {
            throw ShareError.fileNotFound
        }

        // Decode JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let shareableWorkout = try decoder.decode(ShareableWorkout.self, from: jsonData)

            // Validate imported data
            let validationResult = validateImportedWorkout(shareableWorkout)
            switch validationResult {
            case .success:
                print("✅ Imported workout from: \(url.lastPathComponent)")
                return shareableWorkout
            case .failure(let error):
                throw error
            }
        } catch let decodingError as DecodingError {
            print("❌ Decoding error: \(decodingError)")
            throw ShareError.decodingFailed
        } catch {
            throw error
        }
    }

    // MARK: - Validation

    /// Validate imported workout data
    /// - Parameter workout: The workout to validate
    /// - Returns: Result indicating success or failure with error
    func validateImportedWorkout(_ workout: ShareableWorkout) -> Result<Void, ShareError> {
        // Check version compatibility
        let supportedVersions = ["1.0"]
        guard supportedVersions.contains(workout.version) else {
            return .failure(.versionMismatch)
        }

        // Check required fields
        let workoutData = workout.workout

        // Distance must be positive
        guard workoutData.distance >= 0 else {
            return .failure(.missingRequiredFields)
        }

        // Duration must be positive
        guard workoutData.duration >= 0 else {
            return .failure(.missingRequiredFields)
        }

        // Validate route coordinates if present
        for point in workoutData.route {
            // Latitude: -90 to 90
            guard point.lat >= -90 && point.lat <= 90 else {
                return .failure(.corruptedData)
            }

            // Longitude: -180 to 180
            guard point.lon >= -180 && point.lon <= 180 else {
                return .failure(.corruptedData)
            }
        }

        return .success(())
    }

    // MARK: - Share Sheet

    /// Present share sheet for a workout file
    /// - Parameters:
    ///   - fileURL: URL of the file to share
    ///   - viewController: View controller to present from
    ///   - sourceView: Source view for iPad popover
    func presentShareSheet(
        for fileURL: URL,
        from viewController: UIViewController,
        sourceView: UIView? = nil,
        sourceBarButtonItem: UIBarButtonItem? = nil
    ) {
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        // iPad popover configuration
        if let popover = activityViewController.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else if let barButtonItem = sourceBarButtonItem {
                popover.barButtonItem = barButtonItem
            }
        }

        viewController.present(activityViewController, animated: true)
    }

    // MARK: - Utility

    /// Get the documents directory URL
    var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Clean up temporary export files
    func cleanupTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory

        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: nil
            )

            for file in tempFiles where file.pathExtension == ShareManager.fileExtension {
                try? FileManager.default.removeItem(at: file)
            }

            print("🧹 Cleaned up temporary .wplaza files")
        } catch {
            print("⚠️ Failed to clean up temp files: \(error)")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didReceiveSharedWorkout = Notification.Name("didReceiveSharedWorkout")
    static let didReceiveSharedWorkoutInDetail = Notification.Name("didReceiveSharedWorkoutInDetail")
}
