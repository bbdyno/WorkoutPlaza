//
//  WidgetGroup.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/19/26.
//

import UIKit

// MARK: - WidgetGroup Model
struct WidgetGroup: Codable {
    let id: String
    let type: WidgetGroupType
    let ownerName: String?
    let widgetIds: [String]
    let frame: CodableRect

    init(
        id: String = UUID().uuidString,
        type: WidgetGroupType,
        ownerName: String? = nil,
        widgetIds: [String],
        frame: CGRect
    ) {
        self.id = id
        self.type = type
        self.ownerName = ownerName
        self.widgetIds = widgetIds
        self.frame = CodableRect(rect: frame)
    }

    var cgFrame: CGRect {
        return frame.rect
    }
}

// MARK: - Codable CGRect Wrapper
struct CodableRect: Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }

    var rect: CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Widget Group Info (for serialization)
struct WidgetGroupInfo: Codable {
    let groups: [WidgetGroup]

    init(groups: [WidgetGroup] = []) {
        self.groups = groups
    }
}

// MARK: - Group Conflict Result
enum GroupConflictResult {
    case allowed
    case denied(reason: String)

    var isAllowed: Bool {
        switch self {
        case .allowed:
            return true
        case .denied:
            return false
        }
    }

    var denialReason: String? {
        switch self {
        case .allowed:
            return nil
        case .denied(let reason):
            return reason
        }
    }
}

// MARK: - Group Manager
class GroupManager {

    static let shared = GroupManager()

    private init() {}

    // MARK: - Group Conflict Prevention

    /// Check if a widget can be added to a group
    /// - Parameters:
    ///   - widget: The widget to check
    ///   - targetGroup: The group to add the widget to
    ///   - widgetCurrentGroup: The widget's current group (if any)
    /// - Returns: Result indicating if the operation is allowed
    func canAddWidgetToGroup(
        widget: UIView,
        targetGroup: TemplateGroupView,
        widgetCurrentGroup: TemplateGroupView? = nil
    ) -> GroupConflictResult {
        // Get the widget's group type (if it belongs to a group)
        let widgetGroupType = widgetCurrentGroup?.groupType

        // Check compatibility
        if let widgetType = widgetGroupType {
            if widgetType != targetGroup.groupType {
                switch (widgetType, targetGroup.groupType) {
                case (.myRecord, .importedRecord):
                    return .denied(reason: "내 기록 위젯은 타인 기록 그룹에 추가할 수 없습니다")
                case (.importedRecord, .myRecord):
                    return .denied(reason: "타인 기록 위젯은 내 기록 그룹에 추가할 수 없습니다")
                default:
                    return .denied(reason: "그룹 타입이 호환되지 않습니다")
                }
            }
        }

        return .allowed
    }

    /// Check if multiple widgets can be grouped together
    /// - Parameter widgets: The widgets to group
    /// - Returns: Result indicating if the operation is allowed
    func canGroupWidgets(_ widgets: [UIView]) -> GroupConflictResult {
        var hasMyRecord = false
        var hasImportedRecord = false

        for widget in widgets {
            // Check if widget is part of an imported group
            if let group = findParentGroup(for: widget) {
                switch group.groupType {
                case .myRecord:
                    hasMyRecord = true
                case .importedRecord:
                    hasImportedRecord = true
                }
            } else {
                // Widgets not in a group are treated as myRecord
                hasMyRecord = true
            }
        }

        if hasMyRecord && hasImportedRecord {
            return .denied(reason: "내 기록과 타인 기록을 함께 그룹화할 수 없습니다")
        }

        return .allowed
    }

    /// Find the parent group of a widget
    /// - Parameter widget: The widget to check
    /// - Returns: The parent group if found
    func findParentGroup(for widget: UIView) -> TemplateGroupView? {
        var currentView: UIView? = widget.superview
        while let view = currentView {
            if let group = view as? TemplateGroupView {
                return group
            }
            currentView = view.superview
        }
        return nil
    }

    /// Get the effective group type for a widget
    /// - Parameter widget: The widget to check
    /// - Returns: The group type (myRecord for ungrouped widgets)
    func getGroupType(for widget: UIView) -> WidgetGroupType {
        if let group = findParentGroup(for: widget) {
            return group.groupType
        }
        return .myRecord  // Default for ungrouped widgets
    }

    // MARK: - Visual Feedback

    /// Get the visual feedback color for a drag operation
    /// - Parameters:
    ///   - widget: The widget being dragged
    ///   - targetGroup: The target group
    /// - Returns: Color to use for visual feedback
    func getDragFeedbackColor(for widget: UIView, over targetGroup: TemplateGroupView) -> UIColor {
        let result = canAddWidgetToGroup(widget: widget, targetGroup: targetGroup)
        return result.isAllowed ? .systemGreen.withAlphaComponent(0.3) : .systemRed.withAlphaComponent(0.3)
    }
}
