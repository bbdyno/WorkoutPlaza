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
}

class SelectionManager {

    // MARK: - Properties
    weak var delegate: SelectionManagerDelegate?
    private(set) var currentlySelectedItem: Selectable?
    private var allSelectableItems: [Selectable] = []

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
        allSelectableItems.removeAll { $0.itemIdentifier == item.itemIdentifier }
        if currentlySelectedItem?.itemIdentifier == item.itemIdentifier {
            currentlySelectedItem = nil
        }
    }

    func unregisterAllItems() {
        allSelectableItems.removeAll()
        currentlySelectedItem = nil
    }

    // MARK: - Selection Management
    func selectItem(_ item: Selectable) {
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
    }

    func deselectAll() {
        if let selectedItem = currentlySelectedItem {
            deselectItem(selectedItem)
            delegate?.selectionManagerDidDeselectAll(self)
        }
    }

    // MARK: - Query
    var hasSelection: Bool {
        return currentlySelectedItem != nil
    }

    func isSelected(_ item: Selectable) -> Bool {
        return currentlySelectedItem?.itemIdentifier == item.itemIdentifier
    }
}
