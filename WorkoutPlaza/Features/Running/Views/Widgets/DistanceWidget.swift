//
//  DistanceWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

// MARK: - Distance Widget
class DistanceWidget: BaseStatWidget {
    func configure(distance: Double) {
        titleLabel.text = "거리"
        valueLabel.text = String(format: "%.2f", distance / 1000)
        unitLabel.text = "km"
    }
}
