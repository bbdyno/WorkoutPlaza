//
//  DistanceWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  DistanceWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

// MARK: - Distance Widget
class DistanceWidget: BaseStatWidget {
    private static let minimumStandaloneSize: CGFloat = 30

    override var widgetIconName: String? { "ruler" }
    override var minimumSize: CGFloat {
        isGroupManaged ? LayoutConstants.groupManagedMinimumWidgetSize : Self.minimumStandaloneSize
    }

    func configure(distance: Double) {
        titleLabel.text = WorkoutPlazaStrings.Widget.distance
        valueLabel.text = String(format: "%.2f", distance / 1000)
        unitLabel.text = "km"
    }
}
