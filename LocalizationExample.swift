// MARK: - Localization Usage Example with Tuist
//
// Tuist automatically generates type-safe string accessors from your Localizable.strings files.
// The generated code is located at: Derived/Sources/TuistStrings+WorkoutPlaza.swift
//
// This file demonstrates how to use localized strings in your code.

import UIKit

class LocalizationExampleViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: - Using Tuist Generated Localized Strings

        // Common strings
        let okText = WorkoutPlazaStrings.Common.ok         // "확인" (ko) / "OK" (en)
        let cancelText = WorkoutPlazaStrings.Common.cancel // "취소" (ko) / "Cancel" (en)
        let saveText = WorkoutPlazaStrings.Common.save     // "저장" (ko) / "Save" (en)

        // Tab bar strings
        let homeTab = WorkoutPlazaStrings.Tab.home         // "홈" (ko) / "Home" (en)
        let statsTab = WorkoutPlazaStrings.Tab.statistics  // "통계" (ko) / "Statistics" (en)

        // Workout type strings
        let running = WorkoutPlazaStrings.Workout.running  // "러닝" (ko) / "Running" (en)
        let climbing = WorkoutPlazaStrings.Workout.climbing // "클라이밍" (ko) / "Climbing" (en)

        // Permission strings (nested)
        let healthShare = WorkoutPlazaStrings.Permission.Health.share
        let photoLibrary = WorkoutPlazaStrings.Permission.Photo.library

        // MARK: - Usage in Alert
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Workout.running,
            message: "Your message here",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: WorkoutPlazaStrings.Common.ok,
            style: .default
        ))

        alert.addAction(UIAlertAction(
            title: WorkoutPlazaStrings.Common.cancel,
            style: .cancel
        ))

        // MARK: - Usage in UI Elements
        let saveButton = UIButton()
        saveButton.setTitle(WorkoutPlazaStrings.Common.save, for: .normal)

        let label = UILabel()
        label.text = WorkoutPlazaStrings.Tab.home
    }
}

// MARK: - Adding New Localized Strings
//
// To add new localized strings:
//
// 1. Open Resources/ko.lproj/Localizable.strings
// 2. Add your key-value pair: "key.name" = "한국어 값";
//
// 3. Open Resources/en.lproj/Localizable.strings
// 4. Add the same key: "key.name" = "English Value";
//
// 5. Run: make install
//    This regenerates the Swift accessors in Derived/Sources/
//
// 6. Use in code: WorkoutPlazaStrings.Key.name
//
// Example:
// Resources/ko.lproj/Localizable.strings:
// "workout.distance" = "거리";
//
// Resources/en.lproj/Localizable.strings:
// "workout.distance" = "Distance";
//
// After `make install`:
// let distance = WorkoutPlazaStrings.Workout.distance
