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

// MARK: - Date Widget Delegate
protocol DateWidgetDelegate: AnyObject {
    func dateWidgetDidRequestEdit(_ widget: DateWidget)
}

// MARK: - Date Widget
class DateWidget: BaseStatWidget {
    override var widgetIconName: String? { "calendar" }

    // Store configured date for persistence
    private(set) var configuredDate: Date?

    // Date widget specific delegate
    weak var dateDelegate: DateWidgetDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDoubleTapGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)

        // Make single tap wait for double tap to fail
        if let tapGesture = gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer && ($0 as! UITapGestureRecognizer).numberOfTapsRequired == 1 }) {
            tapGesture.require(toFail: doubleTapGesture)
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        // Double tap opens date picker
        dateDelegate?.dateWidgetDidRequestEdit(self)
    }

    func configure(startDate: Date) {
        configuredDate = startDate
        titleLabel.text = "날짜"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let dateString = formatter.string(from: startDate)

        valueLabel.text = dateString
        unitLabel.text = "" // No time display for date widget
    }

    func updateDate(_ date: Date) {
        configuredDate = date
        configure(startDate: date)
    }
}
