//
//  CurrentDateTimeWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  CurrentDateTimeWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

// MARK: - Current Date Time Widget Delegate
protocol CurrentDateTimeWidgetDelegate: AnyObject {
    func currentDateTimeWidgetDidRequestEdit(_ widget: CurrentDateTimeWidget)
}

// MARK: - Current Date Time Widget
class CurrentDateTimeWidget: BaseStatWidget {
    // Store configured date for persistence
    private(set) var configuredDate: Date?

    // Date widget specific delegate
    weak var currentDateTimeDelegate: CurrentDateTimeWidgetDelegate?

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
        currentDateTimeDelegate?.currentDateTimeWidgetDidRequestEdit(self)
    }

    func configure(date: Date) {
        configuredDate = date
        // Set smaller base font size for long date string
        baseFontSizes["title"] = 12
        baseFontSizes["value"] = 16 // Much smaller than default 24
        baseFontSizes["unit"] = 14

        titleLabel.text = WorkoutPlazaStrings.Widget.Title.Workout.datetime

        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMMdhmma")

        let dateTimeString = formatter.string(from: date)

        valueLabel.text = dateTimeString
        unitLabel.text = "" // No unit for combined date/time

        // Force font update with new base sizes
        updateFonts()
    }

    func updateDate(_ date: Date) {
        configuredDate = date
        configure(date: date)
    }
}
