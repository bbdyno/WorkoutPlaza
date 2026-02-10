//
//  BaseWorkoutDetailViewController+SelectionAndGrouping.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/10/26.
//

import UIKit

extension BaseWorkoutDetailViewController {

    // MARK: - Widget Grouping and Management

    @objc func groupSelectedWidgets() {
        let selectedItems = selectionManager.getSelectedItems()
        let widgetsToGroup = selectedItems.map { $0 as UIView }.filter { !($0 is TemplateGroupView) }

        guard widgetsToGroup.count >= 2 else { return }

        // Check for group conflicts
        let conflictResult = GroupManager.shared.canGroupWidgets(widgetsToGroup)
        if !conflictResult.isAllowed {
            showGroupConflictAlert(reason: conflictResult.denialReason ?? WorkoutPlazaStrings.Base.Group.Conflict.default)
            return
        }

        // IMPORTANT: Hide selection state BEFORE moving widgets to group
        // This removes resize handles from contentView
        for widget in widgetsToGroup {
            if let selectable = widget as? Selectable {
                selectable.hideSelectionState()
            }
        }

        // Determine the group type based on widget origins
        let groupType = determineGroupTypeForWidgets(widgetsToGroup)

        // Calculate bounding frame for all selected widgets
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude

        for widget in widgetsToGroup {
            minX = min(minX, widget.frame.minX)
            minY = min(minY, widget.frame.minY)
            maxX = max(maxX, widget.frame.maxX)
            maxY = max(maxY, widget.frame.maxY)
        }

        // Add padding
        let padding: CGFloat = 16
        let groupFrame = CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + (padding * 2),
            height: maxY - minY + (padding * 2)
        )

        // Create group
        let group = TemplateGroupView(items: widgetsToGroup, frame: groupFrame, groupType: groupType)
        group.groupDelegate = self
        group.selectionDelegate = self
        selectionManager.registerItem(group)

        contentView.addSubview(group)
        templateGroups.append(group)
        hasUnsavedChanges = true

        // Remove widgets from main widgets array (they're now in the group)
        for widget in widgetsToGroup {
            widgets.removeAll { $0 === widget }
            if let selectable = widget as? Selectable {
                selectionManager.unregisterItem(selectable)
            }
        }

        // Exit multi-select mode and select the new group
        selectionManager.exitMultiSelectMode()

        // Select the new group (will trigger delegate to show toolbar)
        selectionManager.selectItem(group)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func determineGroupTypeForWidgets(_ widgets: [UIView]) -> WidgetGroupType {
        // Check if any widget is from an imported group
        for widget in widgets {
            if let parentGroup = GroupManager.shared.findParentGroup(for: widget) {
                if parentGroup.groupType == .importedRecord {
                    return .importedRecord
                }
            }
        }
        return .myRecord
    }

    private func showGroupConflictAlert(reason: String) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Base.Group.Conflict.title,
            message: reason,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }

    @objc func ungroupSelectedWidget() {
        // Check both multi-select and single selection modes
        let selectedItems = selectionManager.getSelectedItems()
        let selectedGroup: TemplateGroupView?

        if let group = selectedItems.first(where: { $0 is TemplateGroupView }) as? TemplateGroupView {
            selectedGroup = group
        } else if let group = selectionManager.currentlySelectedItem as? TemplateGroupView {
            selectedGroup = group
        } else {
            return
        }

        guard let groupToUngroup = selectedGroup else { return }

        // Ungroup items
        let ungroupedItems = groupToUngroup.ungroupItems(to: contentView)

        // Re-register widgets
        for item in ungroupedItems {
            widgets.append(item)
            if let selectable = item as? Selectable {
                selectable.selectionDelegate = self
                selectionManager.registerItem(selectable)
            }
        }

        // Remove group
        selectionManager.unregisterItem(groupToUngroup)
        templateGroups.removeAll { $0 === groupToUngroup }
        groupToUngroup.removeFromSuperview()
        hasUnsavedChanges = true

        // Exit multi-select mode
        selectionManager.exitMultiSelectMode()
        hideMultiSelectToolbar()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    @objc func exitMultiSelectMode() {
        selectionManager.exitMultiSelectMode()
        hideMultiSelectToolbar()
    }

    @objc func deleteSelectedItem() {
        guard selectionManager.currentlySelectedItem != nil else { return }

        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Base.Item.Delete.title,
            message: WorkoutPlazaStrings.Base.Item.Delete.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.delete, style: .destructive) { [weak self] _ in
            self?.performDelete()
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        present(alert, animated: true)
    }

    private func performDelete() {
        guard let selectedItem = selectionManager.currentlySelectedItem else { return }
        let selectedView = selectedItem as UIView

        // Remove from selection manager
        selectionManager.deselectAll()
        selectionManager.unregisterItem(selectedItem)

        // Remove from widgets or templateGroups array
        widgets.removeAll { $0 === selectedView }
        templateGroups.removeAll { $0 === selectedView }
        hasUnsavedChanges = true

        // Remove from view hierarchy
        UIView.animate(withDuration: 0.25, animations: {
            selectedView.alpha = 0
            selectedView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            selectedView.removeFromSuperview()
        }

        updateToolbarItemsState()
    }

    private func selectedItemsForEditActions() -> [Selectable] {
        var selectedItems = selectionManager.getSelectedItems()
        if selectedItems.isEmpty, let selectedItem = selectionManager.currentlySelectedItem {
            selectedItems = [selectedItem]
        }
        return selectedItems
    }

    private func selectedAlignableTargets() -> [WidgetContentAlignable] {
        let selectedItems = selectedItemsForEditActions()
        var targets: [WidgetContentAlignable] = []
        var seenIdentifiers = Set<String>()

        for item in selectedItems {
            if let group = item as? TemplateGroupView {
                for groupedItem in group.groupedItems {
                    guard let alignable = groupedItem as? WidgetContentAlignable else { continue }
                    guard !seenIdentifiers.contains(alignable.itemIdentifier) else { continue }
                    seenIdentifiers.insert(alignable.itemIdentifier)
                    targets.append(alignable)
                }
                continue
            }

            guard let alignable = item as? WidgetContentAlignable else { continue }
            guard !seenIdentifiers.contains(alignable.itemIdentifier) else { continue }
            seenIdentifiers.insert(alignable.itemIdentifier)
            targets.append(alignable)
        }

        return targets
    }

    private func currentAlignment(from targets: [WidgetContentAlignable]) -> WidgetContentAlignment? {
        guard let firstAlignment = targets.first?.contentAlignment else { return nil }
        let allSame = targets.allSatisfy { $0.contentAlignment == firstAlignment }
        return allSame ? firstAlignment : nil
    }

    private func updateToolbarButtonIcon(_ button: UIButton, systemName: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
    }

    @objc func showColorPicker() {
        // Check both multi-select and single selection modes
        let selectedItems = selectionManager.getSelectedItems()
        let currentColor: UIColor

        if let firstItem = selectedItems.first {
            currentColor = firstItem.currentColor
        } else if let selectedItem = selectionManager.currentlySelectedItem {
            currentColor = selectedItem.currentColor
        } else {
            return
        }

        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = currentColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }

    @objc func showFontPicker() {
        // Check both multi-select and single selection modes
        let selectedItems = selectionManager.getSelectedItems()
        let hasValidSelection = !selectedItems.isEmpty || selectionManager.currentlySelectedItem != nil

        guard hasValidSelection else { return }

        let actionSheet = UIAlertController(title: WorkoutPlazaStrings.Alert.Font.style, message: nil, preferredStyle: .actionSheet)

        for fontStyle in FontStyle.allCases {
            actionSheet.addAction(UIAlertAction(title: fontStyle.displayName, style: .default) { [weak self] _ in
                self?.applyFontToSelection(fontStyle)
            })
        }

        actionSheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Button.cancel, style: .cancel))

        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = fontPickerButton
            popover.sourceRect = fontPickerButton.bounds
        }

        present(actionSheet, animated: true)
    }

    @objc func cycleAlignmentForSelection() {
        let targets = selectedAlignableTargets()
        guard !targets.isEmpty else { return }

        let current = currentAlignment(from: targets) ?? .left
        let next: WidgetContentAlignment
        switch current {
        case .left:
            next = .center
        case .center:
            next = .right
        case .right:
            next = .left
        }

        applyAlignmentToSelection(next)
    }

    private func applyAlignmentToSelection(_ alignment: WidgetContentAlignment) {
        let targets = selectedAlignableTargets()
        guard !targets.isEmpty else { return }

        for target in targets {
            target.applyContentAlignment(alignment)
        }

        hasUnsavedChanges = true
        updateToolbarItemsState()
    }

    private func applyFontToSelection(_ fontStyle: FontStyle) {
        let selectedItems = selectionManager.getSelectedItems()

        if !selectedItems.isEmpty {
            // Apply font to all selected items
            for item in selectedItems {
                if let group = item as? TemplateGroupView {
                    // Apply font to all widgets inside the group
                    for widget in group.groupedItems {
                        if let statWidget = widget as? BaseStatWidget {
                            statWidget.applyFont(fontStyle)
                            FontPreferences.shared.saveFont(fontStyle, for: statWidget.itemIdentifier)
                        } else if let textWidget = widget as? TextWidget {
                            textWidget.applyFont(fontStyle)
                            FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
                        } else if let routesWidget = widget as? ClimbingRoutesByColorWidget {
                            routesWidget.applyFont(fontStyle)
                            FontPreferences.shared.saveFont(fontStyle, for: routesWidget.itemIdentifier)
                        }
                    }
                    // Also update the group's font style
                    group.applyFont(fontStyle)
                } else if let statWidget = item as? BaseStatWidget {
                    statWidget.applyFont(fontStyle)
                    FontPreferences.shared.saveFont(fontStyle, for: statWidget.itemIdentifier)
                } else if let textWidget = item as? TextWidget {
                    textWidget.applyFont(fontStyle)
                    FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
                } else if let routesWidget = item as? ClimbingRoutesByColorWidget {
                    routesWidget.applyFont(fontStyle)
                    FontPreferences.shared.saveFont(fontStyle, for: routesWidget.itemIdentifier)
                }
            }
        } else if let selectedItem = selectionManager.currentlySelectedItem {
            // Single selection mode (fallback)
            if let statWidget = selectedItem as? BaseStatWidget {
                statWidget.applyFont(fontStyle)
                FontPreferences.shared.saveFont(fontStyle, for: statWidget.itemIdentifier)
            } else if let textWidget = selectedItem as? TextWidget {
                textWidget.applyFont(fontStyle)
                FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
            } else if let routesWidget = selectedItem as? ClimbingRoutesByColorWidget {
                routesWidget.applyFont(fontStyle)
                FontPreferences.shared.saveFont(fontStyle, for: routesWidget.itemIdentifier)
            } else if let group = selectedItem as? TemplateGroupView {
                for widget in group.groupedItems {
                    if let statWidget = widget as? BaseStatWidget {
                        statWidget.applyFont(fontStyle)
                        FontPreferences.shared.saveFont(fontStyle, for: statWidget.itemIdentifier)
                    } else if let textWidget = widget as? TextWidget {
                        textWidget.applyFont(fontStyle)
                        FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
                    } else if let routesWidget = widget as? ClimbingRoutesByColorWidget {
                        routesWidget.applyFont(fontStyle)
                        FontPreferences.shared.saveFont(fontStyle, for: routesWidget.itemIdentifier)
                    }
                }
                group.applyFont(fontStyle)
            }
        }
        hasUnsavedChanges = true
    }

    func showDimOverlayOption() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Base.Dim.Effect.title,
            message: WorkoutPlazaStrings.Base.Dim.Effect.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Base.Dim.add, style: .default) { [weak self] _ in
            self?.dimOverlay.isHidden = false
            self?.hasUnsavedChanges = true
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Base.Dim.skip, style: .cancel) { [weak self] _ in
            self?.dimOverlay.isHidden = true
        })

        present(alert, animated: true)
    }

    @objc func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: contentView)

        // Check if tapped on any widget or route map
        for widget in widgets {
            if widget.frame.contains(location) {
                return // Let the widget handle the tap
            }
        }

        // Check if tapped on any template group
        for group in templateGroups {
            if group.frame.contains(location) {
                return // Let the group handle the tap
            }
        }

        // Tapped on background, deselect all
        selectionManager.deselectAll()
    }

    func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        contentView.addGestureRecognizer(longPressGesture)
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let location = gesture.location(in: contentView)

        // Check if long-pressed on a widget
        for widget in widgets {
            if widget.frame.contains(location), let selectable = widget as? Selectable {
                // Enter multi-select mode
                selectionManager.enterMultiSelectMode()
                selectionManager.selectItem(selectable)
                showMultiSelectToolbar()

                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                return
            }
        }

        // Check template groups
        for group in templateGroups {
            if group.frame.contains(location) {
                selectionManager.enterMultiSelectMode()
                selectionManager.selectItem(group)
                showMultiSelectToolbar()

                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                return
            }
        }
    }

    // MARK: - TemplateGroupDelegate

    func templateGroupDidConfirm(_ group: TemplateGroupView) {
        // Group confirmed - just hide check button
        hasUnsavedChanges = true
    }

    func templateGroupDidRequestUngroup(_ group: TemplateGroupView) {
        // Imported group requested ungroup
        ungroupSelectedWidget()
    }

    // MARK: - Multi-Select Toolbar Helpers

    func showMultiSelectToolbar() {
        self.multiSelectToolbar.isHidden = false
        self.multiSelectToolbar.alpha = 1.0
        self.bottomFloatingToolbar.alpha = 0.0
        self.bottomFloatingToolbar.isHidden = true
    }

    func hideMultiSelectToolbar() {
        self.multiSelectToolbar.isHidden = true
        self.multiSelectToolbar.alpha = 0.0

        let hasSelection = selectionManager.hasSelection
        self.bottomFloatingToolbar.isHidden = !hasSelection
        self.bottomFloatingToolbar.alpha = hasSelection ? 1.0 : 0.0
    }

    func updateMultiSelectToolbarState() {
        // Check both multi-select list and single selection
        var selectedItems = selectionManager.getSelectedItems()

        // If empty but there is a single selection, treat it as a list of 1
        if selectedItems.isEmpty, let singleItem = selectionManager.currentlySelectedItem {
            selectedItems = [singleItem]
        }

        multiSelectCountLabel.text = WorkoutPlazaStrings.Base.Multi.Select.count(selectedItems.count)

        // Group logic: can group if > 1 and not already grouped (simplified)
        // Check if any selected item is a group
        let hasGroup = selectedItems.contains { $0 is TemplateGroupView }
        let canGroup = selectedItems.count > 1 && !hasGroup

        groupButton.isEnabled = canGroup
        groupButton.alpha = canGroup ? 1.0 : 0.5

        // Ungroup logic: can ungroup if single group selected
        let canUngroup = selectedItems.count == 1 && hasGroup
        ungroupButton.isEnabled = canUngroup
        ungroupButton.alpha = canUngroup ? 1.0 : 0.5
    }

    func updateToolbarItemsState() {
        let hasSelection = selectionManager.hasSelection

        UIView.animate(withDuration: 0.25) {
            self.bottomFloatingToolbar.isHidden = !hasSelection
            self.bottomFloatingToolbar.alpha = hasSelection ? 1.0 : 0.0
        }

        let alignableTargets = selectedAlignableTargets()
        let hasAlignableSelection = !alignableTargets.isEmpty
        let selectedAlignment = currentAlignment(from: alignableTargets) ?? .left

        colorPickerButton.isEnabled = hasSelection
        fontPickerButton.isEnabled = hasSelection
        alignmentButton.isEnabled = hasAlignableSelection
        alignmentButton.isHidden = !hasAlignableSelection
        updateToolbarButtonIcon(alignmentButton, systemName: selectedAlignment.symbolName)
        deleteItemButton.isEnabled = hasSelection
    }
}
