//
//  SelectionManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

protocol SelectionManagerDelegate: AnyObject {
    func selectionManager(_ manager: SelectionManager, didSelect item: Selectable)
    func selectionManager(_ manager: SelectionManager, didDeselect item: Selectable)
    func selectionManagerDidDeselectAll(_ manager: SelectionManager)
    // Multi-select delegate methods
    func selectionManager(_ manager: SelectionManager, didSelectMultiple items: [Selectable])
    func selectionManager(_ manager: SelectionManager, didEnterMultiSelectMode: Bool)
}

// Default implementation for optional delegate methods
extension SelectionManagerDelegate {
    func selectionManager(_ manager: SelectionManager, didSelectMultiple items: [Selectable]) {}
    func selectionManager(_ manager: SelectionManager, didEnterMultiSelectMode: Bool) {}
}

class SelectionManager {

    // MARK: - Properties
    weak var delegate: SelectionManagerDelegate?
    private(set) var currentlySelectedItem: Selectable?
    private var allSelectableItems: [Selectable] = []

    // MARK: - Multi-Select Properties
    private(set) var selectedItemIdentifiers: Set<String> = []
    private(set) var isMultiSelectMode: Bool = false

    // MARK: - Initialization
    init() {}

    // MARK: - Item Registration
    func registerItem(_ item: Selectable) {
        guard !allSelectableItems.contains(where: { $0.itemIdentifier == item.itemIdentifier }) else {
            return
        }
        allSelectableItems.append(item)
    }

    func unregisterItem(_ item: Selectable) {
        // Hide selection state first to clean up resize handles
        if item.isSelected || selectedItemIdentifiers.contains(item.itemIdentifier) {
            item.hideSelectionState()
        }

        allSelectableItems.removeAll { $0.itemIdentifier == item.itemIdentifier }
        if currentlySelectedItem?.itemIdentifier == item.itemIdentifier {
            currentlySelectedItem = nil
        }
        // Remove from multi-select as well
        selectedItemIdentifiers.remove(item.itemIdentifier)
    }

    func unregisterAllItems() {
        allSelectableItems.removeAll()
        currentlySelectedItem = nil
        selectedItemIdentifiers.removeAll()
        isMultiSelectMode = false
    }

    // MARK: - Selection Management (Single Select)
    func selectItem(_ item: Selectable) {
        // If in multi-select mode, use toggle instead
        if isMultiSelectMode {
            toggleSelection(item)
            return
        }

        // Deselect current item if different
        if let currentItem = currentlySelectedItem,
           currentItem.itemIdentifier != item.itemIdentifier {
            deselectItem(currentItem)
        }

        // Select new item
        currentlySelectedItem = item
        item.showSelectionState()

        // Bring to front
        if let superview = item.superview {
            superview.bringSubviewToFront(item)
        }

        delegate?.selectionManager(self, didSelect: item)
    }

    func deselectItem(_ item: Selectable) {
        item.hideSelectionState()

        if currentlySelectedItem?.itemIdentifier == item.itemIdentifier {
            currentlySelectedItem = nil
            delegate?.selectionManager(self, didDeselect: item)
        }

        // Remove from multi-select as well
        selectedItemIdentifiers.remove(item.itemIdentifier)
    }

    func deselectAll() {
        // Deselect single selection
        if let selectedItem = currentlySelectedItem {
            deselectItem(selectedItem)
        }

        // Deselect all multi-selected items
        for identifier in selectedItemIdentifiers {
            if let item = allSelectableItems.first(where: { $0.itemIdentifier == identifier }) {
                item.hideSelectionState()
            }
        }
        selectedItemIdentifiers.removeAll()

        // Exit multi-select mode
        if isMultiSelectMode {
            isMultiSelectMode = false
            delegate?.selectionManager(self, didEnterMultiSelectMode: false)
        }

        delegate?.selectionManagerDidDeselectAll(self)
    }

    // MARK: - Multi-Select Management

    /// Enter multi-select mode
    func enterMultiSelectMode() {
        guard !isMultiSelectMode else { return }

        isMultiSelectMode = true

        // If there's a current single selection, convert it to multi-select mode
        if let currentItem = currentlySelectedItem {
            selectedItemIdentifiers.insert(currentItem.itemIdentifier)
            // Re-show selection state without bottom handles
            currentItem.hideSelectionState()
            currentItem.showSelectionState(multiSelectMode: true)
        }

        delegate?.selectionManager(self, didEnterMultiSelectMode: true)
    }

    /// Exit multi-select mode
    func exitMultiSelectMode() {
        guard isMultiSelectMode else { return }

        // Hide all multi-selected items' selection state
        for identifier in selectedItemIdentifiers {
            if let item = allSelectableItems.first(where: { $0.itemIdentifier == identifier }) {
                item.hideSelectionState()
            }
        }

        selectedItemIdentifiers.removeAll()
        isMultiSelectMode = false
        currentlySelectedItem = nil

        delegate?.selectionManager(self, didEnterMultiSelectMode: false)
        delegate?.selectionManagerDidDeselectAll(self)
    }

    /// Toggle selection of an item in multi-select mode
    func toggleSelection(_ item: Selectable) {
        if selectedItemIdentifiers.contains(item.itemIdentifier) {
            // Deselect
            selectedItemIdentifiers.remove(item.itemIdentifier)
            item.hideSelectionState()
            delegate?.selectionManager(self, didDeselect: item)
        } else {
            // Select - use multiSelectMode to hide bottom handles
            selectedItemIdentifiers.insert(item.itemIdentifier)
            item.showSelectionState(multiSelectMode: true)
            delegate?.selectionManager(self, didSelect: item)
        }

        // Notify about current selection
        let selectedItems = getSelectedItems()
        delegate?.selectionManager(self, didSelectMultiple: selectedItems)
    }

    /// Select multiple items at once
    func selectMultiple(_ items: [Selectable]) {
        // Enter multi-select mode if not already
        if !isMultiSelectMode {
            enterMultiSelectMode()
        }

        for item in items {
            if !selectedItemIdentifiers.contains(item.itemIdentifier) {
                selectedItemIdentifiers.insert(item.itemIdentifier)
                item.showSelectionState(multiSelectMode: true)
            }
        }

        delegate?.selectionManager(self, didSelectMultiple: getSelectedItems())
    }

    /// Get all currently selected items
    func getSelectedItems() -> [Selectable] {
        return allSelectableItems.filter { selectedItemIdentifiers.contains($0.itemIdentifier) }
    }

    /// Get all registered selectable items
    func getAllItems() -> [Selectable] {
        return allSelectableItems
    }

    /// Clear selection for group creation (no delegate calls, keeps multi-select mode)
    func clearSelectionForGroupCreation() {
        selectedItemIdentifiers.removeAll()
        currentlySelectedItem = nil
        // Stay in multi-select mode, don't call delegate
        isMultiSelectMode = true
    }

    /// Add item to multi-select without toggling (for group creation)
    func addToMultiSelect(_ item: Selectable) {
        if !isMultiSelectMode {
            isMultiSelectMode = true
        }
        selectedItemIdentifiers.insert(item.itemIdentifier)
        // Don't call showSelectionState here - caller will do it
        delegate?.selectionManager(self, didSelectMultiple: getSelectedItems())
    }

    // MARK: - Query
    var hasSelection: Bool {
        if isMultiSelectMode {
            return !selectedItemIdentifiers.isEmpty
        }
        return currentlySelectedItem != nil
    }

    var selectedCount: Int {
        if isMultiSelectMode {
            return selectedItemIdentifiers.count
        }
        return currentlySelectedItem != nil ? 1 : 0
    }

    func isSelected(_ item: Selectable) -> Bool {
        if isMultiSelectMode {
            return selectedItemIdentifiers.contains(item.itemIdentifier)
        }
        return currentlySelectedItem?.itemIdentifier == item.itemIdentifier
    }
}
