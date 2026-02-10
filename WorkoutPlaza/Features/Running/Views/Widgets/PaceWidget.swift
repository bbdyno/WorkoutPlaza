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
    private static let minimumStandaloneSize: CGFloat = 30

    override var widgetIconName: String? { "speedometer" }
    override var minimumSize: CGFloat {
        isGroupManaged ? LayoutConstants.groupManagedMinimumWidgetSize : Self.minimumStandaloneSize
    }

    func configure(pace: Double) {
        titleLabel.text = WorkoutPlazaStrings.Widget.Title.Avg.pace
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        valueLabel.text = String(format: "%d:%02d", minutes, seconds)
        unitLabel.text = "/km"
    }
}
