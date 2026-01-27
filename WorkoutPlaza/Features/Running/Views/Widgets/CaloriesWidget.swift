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
    func configure(calories: Double) {
        titleLabel.text = "칼로리"
        valueLabel.text = String(format: "%.0f", calories)
        unitLabel.text = "kcal"
    }
}
