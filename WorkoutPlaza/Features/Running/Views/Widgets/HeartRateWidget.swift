//
//  HeartRateWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit

// MARK: - Heart Rate Widget
class HeartRateWidget: BaseStatWidget {
    private static let minimumStandaloneSize: CGFloat = 30

    override var widgetIconName: String? { "heart.fill" }
    override var minimumSize: CGFloat {
        isGroupManaged ? LayoutConstants.groupManagedMinimumWidgetSize : Self.minimumStandaloneSize
    }

    func configure(heartRate: Double) {
        titleLabel.text = WorkoutPlazaStrings.Widget.Title.Avg.Heart.rate
        valueLabel.text = String(format: "%.0f", heartRate)
        unitLabel.text = "bpm"
    }
}
