//
//  HeartRateWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit

// MARK: - Heart Rate Widget
class HeartRateWidget: BaseStatWidget {
    override var widgetIconName: String? { "heart.fill" }

    func configure(heartRate: Double) {
        titleLabel.text = "평균 심박수"
        valueLabel.text = String(format: "%.0f", heartRate)
        unitLabel.text = "bpm"
    }
}
