//
//  DateWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  DateWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

// MARK: - Date Widget
class DateWidget: BaseStatWidget {
    // Store configured date for persistence
    private(set) var configuredDate: Date?

    func configure(startDate: Date) {
        configuredDate = startDate
        titleLabel.text = "날짜"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let dateString = formatter.string(from: startDate)

        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: startDate)

        valueLabel.text = dateString
        unitLabel.text = timeString
    }
}
