//
//  SpeedWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  SpeedWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

// MARK: - Speed Widget
class SpeedWidget: BaseStatWidget {
    func configure(speed: Double) {
        titleLabel.text = "평균 속도"
        valueLabel.text = String(format: "%.1f", speed)
        unitLabel.text = "km/h"
    }
}
