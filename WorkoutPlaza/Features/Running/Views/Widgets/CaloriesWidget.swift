//
//  CaloriesWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  CaloriesWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

// MARK: - Calories Widget
class CaloriesWidget: BaseStatWidget {
    private static let minimumStandaloneSize: CGFloat = 30

    override var widgetIconName: String? { "flame.fill" }
    override var minimumSize: CGFloat {
        isGroupManaged ? LayoutConstants.groupManagedMinimumWidgetSize : Self.minimumStandaloneSize
    }

    func configure(calories: Double) {
        titleLabel.text = WorkoutPlazaStrings.Widget.calories
        valueLabel.text = String(format: "%.0f", calories)
        unitLabel.text = "kcal"
    }
}
