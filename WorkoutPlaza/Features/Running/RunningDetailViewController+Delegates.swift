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

// MARK: - TextWidgetDelegate
extension RunningDetailViewController: TextWidgetDelegate {
    func textWidgetDidRequestEdit(_ widget: TextWidget) {
        let currentText = widget.textLabel.text ?? ""

        let alert = UIAlertController(
            title: "텍스트 편집",
            message: "위젯에 표시할 텍스트를 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = currentText
            textField.placeholder = "텍스트 입력"
            textField.clearButtonMode = .whileEditing
        }

        alert.addAction(UIAlertAction(title: "완료", style: .default) { [weak alert, weak widget] _ in
            guard let textField = alert?.textFields?.first,
                  let newText = textField.text,
                  !newText.isEmpty else { return }

            widget?.updateText(newText)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }
}
