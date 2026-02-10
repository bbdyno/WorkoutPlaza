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
    private static let minimumStandaloneSize: CGFloat = 30

    override var widgetIconName: String? { "gauge.high" }
    override var minimumSize: CGFloat {
        isGroupManaged ? LayoutConstants.groupManagedMinimumWidgetSize : Self.minimumStandaloneSize
    }

    func configure(speed: Double) {
        titleLabel.text = WorkoutPlazaStrings.Widget.Title.Avg.speed
        valueLabel.text = String(format: "%.1f", speed)
        unitLabel.text = "km/h"
    }
}
