//
//  WidgetContentAlignment.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import UIKit

enum WidgetContentAlignment: String, Codable, CaseIterable {
    case left
    case center
    case right

    var textAlignment: NSTextAlignment {
        switch self {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        }
    }

    var symbolName: String {
        switch self {
        case .left:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .right:
            return "text.alignright"
        }
    }

    var localizedTitle: String {
        switch self {
        case .left:
            return NSLocalizedString("ui.align.left", comment: "Left alignment")
        case .center:
            return NSLocalizedString("ui.align.center", comment: "Center alignment")
        case .right:
            return NSLocalizedString("ui.align.right", comment: "Right alignment")
        }
    }
}

protocol WidgetContentAlignable: Selectable {
    var contentAlignment: WidgetContentAlignment { get }
    func applyContentAlignment(_ alignment: WidgetContentAlignment)
}
