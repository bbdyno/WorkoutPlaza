//
//  DurationWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  DurationWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

// MARK: - Duration Widget
class DurationWidget: BaseStatWidget {
    override var widgetIconName: String? { "timer" }

    func configure(duration: TimeInterval) {
        titleLabel.text = "시간"
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            valueLabel.text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            valueLabel.text = String(format: "%02d:%02d", minutes, seconds)
        }
        unitLabel.text = ""
    }
}
