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
    override var widgetIconName: String? { "gauge.high" }

    func configure(speed: Double) {
        titleLabel.text = WorkoutPlazaStrings.Widget.Title.Avg.speed
        valueLabel.text = String(format: "%.1f", speed)
        unitLabel.text = "km/h"
    }
}
