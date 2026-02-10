//
//  BaseWorkoutDetailViewController+Delegates.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/10/26.
//

import UIKit
import PhotosUI

// MARK: - UIScrollViewDelegate
extension BaseWorkoutDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}

// MARK: - SelectionManagerDelegate
extension BaseWorkoutDetailViewController: SelectionManagerDelegate {
    func selectionManager(_ manager: SelectionManager, didSelect item: Selectable) {
        updateToolbarItemsState()
        
        // If a group is selected, show toolbar but DO NOT auto-enter multi-select mode
        // This allows user to switch selection by tapping another widget
        if item is TemplateGroupView {
            showMultiSelectToolbar()
            updateMultiSelectToolbarState()
        } else if manager.isMultiSelectMode {
            updateMultiSelectToolbarState()
        } else {
            // Normal widget selected in single mode - hide multi-select toolbar
            hideMultiSelectToolbar()
        }
    }
    
    func selectionManager(_ manager: SelectionManager, didDeselect item: Selectable) {
        updateToolbarItemsState()
        
        // Check current selection state
        let selectedItems = manager.getSelectedItems()
        let hasSelectedGroup = selectedItems.contains { $0 is TemplateGroupView }
        let currentIsGroup = manager.currentlySelectedItem is TemplateGroupView
        
        if selectedItems.isEmpty && !manager.isMultiSelectMode && !currentIsGroup {
            hideMultiSelectToolbar()
        } else if manager.isMultiSelectMode || hasSelectedGroup || currentIsGroup {
            updateMultiSelectToolbarState()
        }
    }
    
    func selectionManagerDidDeselectAll(_ manager: SelectionManager) {
        updateToolbarItemsState()
        hideMultiSelectToolbar()
    }
    
    func selectionManager(_ manager: SelectionManager, didSelectMultiple items: [Selectable]) {
        updateToolbarItemsState()
        updateMultiSelectToolbarState()
    }
    
    func selectionManager(_ manager: SelectionManager, didEnterMultiSelectMode: Bool) {
        if didEnterMultiSelectMode {
            showMultiSelectToolbar()
            updateMultiSelectToolbarState()
        } else {
            hideMultiSelectToolbar()
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension BaseWorkoutDetailViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }

        let shouldStopAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        switch documentPickerPurpose {
        case .templateImport:
            handleImportedTemplateFile(at: fileURL)
        case .widgetPackageImport:
            handleImportedWidgetPackageFile(at: fileURL)
        }
    }
    
    internal func handleImportedTemplateFile(at fileURL: URL) {
        Task {
            do {
                let template = try await TemplateManager.shared.importTemplate(from: fileURL)
                await MainActor.run {
                    self.refreshTemplateLibrary()
                    showTemplatePreview(template)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.Import.failed, message: WorkoutPlazaStrings.Alert.Import.error(error.localizedDescription), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    internal func handleImportedWidgetPackageFile(at fileURL: URL) {
        Task {
            do {
                let installed = try await WidgetPackageManager.shared.installPackage(from: fileURL)
                await MainActor.run {
                    self.refreshTemplateLibrary()
                    let alert = UIAlertController(
                        title: WorkoutPlazaStrings.Alert.Save.completed,
                        message: "\(installed.name) v\(installed.version)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: WorkoutPlazaStrings.Alert.Import.failed,
                        message: WorkoutPlazaStrings.Alert.Import.error(error.localizedDescription),
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - SelectionDelegate
extension BaseWorkoutDetailViewController: SelectionDelegate {
    func itemWasSelected(_ item: Selectable) {
        if selectionManager.isMultiSelectMode {
            selectionManager.toggleSelection(item)
        } else {
            selectionManager.selectItem(item)
        }
        updateToolbarItemsState()
    }

    func itemWasDeselected(_ item: Selectable) {
        if selectionManager.isMultiSelectMode {
            selectionManager.toggleSelection(item)
        } else {
            selectionManager.deselectItem(item)
        }
        updateToolbarItemsState()
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension BaseWorkoutDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let selectedColor = viewController.selectedColor

        // Check if in multi-select mode (includes group selection)
        let selectedItems = selectionManager.getSelectedItems()

        if !selectedItems.isEmpty {
            // Apply color to all selected items
            for item in selectedItems {
                if let group = item as? TemplateGroupView {
                    // Apply color to all widgets inside the group
                    for widget in group.groupedItems {
                        if let selectable = widget as? Selectable {
                            selectable.applyColor(selectedColor)
                            ColorPreferences.shared.saveColor(selectedColor, for: selectable.itemIdentifier)
                        }
                    }
                } else {
                    let mutableItem = item
                    mutableItem.applyColor(selectedColor)
                    ColorPreferences.shared.saveColor(selectedColor, for: item.itemIdentifier)
                }
            }
        } else if let selectedItem = selectionManager.currentlySelectedItem {
            // Single selection mode (fallback)
            selectedItem.applyColor(selectedColor)
            ColorPreferences.shared.saveColor(selectedColor, for: selectedItem.itemIdentifier)
        }
        hasUnsavedChanges = true
    }
}

// MARK: - PHPickerViewControllerDelegate
extension BaseWorkoutDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let image = object as? UIImage {
                    self?.presentBackgroundEditor(with: image)
                }
            }
        }
    }

    private func presentBackgroundEditor(with image: UIImage) {
        let editor = BackgroundImageEditorViewController(image: image, initialTransform: backgroundTransform, canvasSize: contentView.bounds.size)
        editor.delegate = self

        let navController = UINavigationController(rootViewController: editor)
        navController.modalPresentationStyle = .pageSheet

        // Set preferred size for iPad
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        present(navController, animated: true)
    }
}

// MARK: - BackgroundImageEditorDelegate
extension BaseWorkoutDetailViewController: BackgroundImageEditorDelegate {
    func backgroundImageEditor(_ editor: BackgroundImageEditorViewController, didFinishEditing image: UIImage, transform: BackgroundTransform) {
        backgroundImageView.image = image
        backgroundImageView.isHidden = false
        backgroundTemplateView.isHidden = true
        backgroundTransform = transform
        hasUnsavedChanges = true

        // Apply transform to background image
        applyBackgroundTransform(transform)

        // Update watermark color based on new background
        updateWatermarkColorForBackground()

        // Show dim overlay option
        showDimOverlayOption()
    }
}

// MARK: - CustomGradientPickerDelegate
extension BaseWorkoutDetailViewController: CustomGradientPickerDelegate {
    func customGradientPicker(_ picker: CustomGradientPickerViewController, didSelectColors colors: [UIColor], direction: GradientDirection) {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
        backgroundTemplateView.applyCustomGradient(colors: colors, direction: direction)
        hasUnsavedChanges = true
        updateWatermarkColorForBackground()
    }
}

// MARK: - UIGestureRecognizerDelegate for Text Path
extension BaseWorkoutDetailViewController {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't handle tap gesture if touching a button in the toolbar
        if touch.view is UIButton {
            return false
        }

        // Check if touching inside toolbar
        let location = touch.location(in: textPathDrawingToolbar)
        if textPathDrawingToolbar.bounds.contains(location) {
            return false
        }

        return true
    }
}

// MARK: - TextWidgetDelegate
extension BaseWorkoutDetailViewController {
    func textWidgetDidRequestEdit(_ widget: TextWidget) {
        let currentText = widget.textLabel.text ?? ""

        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Base.Text.Edit.title,
            message: WorkoutPlazaStrings.Base.Text.Edit.message,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = currentText
            textField.placeholder = WorkoutPlazaStrings.Text.Input.placeholder
            textField.clearButtonMode = .whileEditing
        }

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.done, style: .default) { [weak alert, weak widget] _ in
            guard let textField = alert?.textFields?.first,
                  let newText = textField.text,
                  !newText.isEmpty else { return }

            widget?.updateText(newText)
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        present(alert, animated: true)
    }
}

// MARK: - CompositeWidgetDelegate
extension BaseWorkoutDetailViewController {
    func compositeWidgetDidRequestEdit(_ widget: CompositeWidget) {
        presentCompositeWidgetEditor(initialPayload: widget.payload) { payload in
            widget.updatePayload(payload)
            self.hasUnsavedChanges = true
        }
    }

    func presentCompositeWidgetEditor(
        initialPayload: CompositeWidgetPayload = .default,
        onCommit: @escaping (CompositeWidgetPayload) -> Void
    ) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Widget.composite,
            message: WorkoutPlazaStrings.Base.Text.Edit.message,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = initialPayload.title
            textField.placeholder = WorkoutPlazaStrings.Widget.composite
            textField.clearButtonMode = .whileEditing
        }

        alert.addTextField { textField in
            textField.text = initialPayload.primaryText
            textField.placeholder = WorkoutPlazaStrings.Text.Input.placeholder
            textField.clearButtonMode = .whileEditing
        }

        alert.addTextField { textField in
            textField.text = initialPayload.secondaryText
            textField.placeholder = "Optional"
            textField.clearButtonMode = .whileEditing
        }

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.done, style: .default) { [weak alert] _ in
            guard let textFields = alert?.textFields, textFields.count >= 3 else { return }

            let title = textFields[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let primary = textFields[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let secondary = textFields[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !primary.isEmpty else { return }

            let payload = CompositeWidgetPayload(
                title: title.isEmpty ? WorkoutPlazaStrings.Widget.composite : title,
                primaryText: primary,
                secondaryText: secondary
            )
            onCommit(payload)
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))
        present(alert, animated: true)
    }
}
