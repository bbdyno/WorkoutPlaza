//
//  PaceWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  PaceWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

// MARK: - Pace Widget
class PaceWidget: BaseStatWidget {
    override var widgetIconName: String? { "speedometer" }

    func configure(pace: Double) {
        titleLabel.text = "평균 페이스"
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        valueLabel.text = String(format: "%d:%02d", minutes, seconds)
        unitLabel.text = "/km"
    }
}
