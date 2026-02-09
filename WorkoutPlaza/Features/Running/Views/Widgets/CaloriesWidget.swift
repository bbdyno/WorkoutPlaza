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
    override var widgetIconName: String? { "flame.fill" }

    func configure(calories: Double) {
        titleLabel.text = WorkoutPlazaStrings.Widget.calories
        valueLabel.text = String(format: "%.0f", calories)
        unitLabel.text = "kcal"
    }
}
