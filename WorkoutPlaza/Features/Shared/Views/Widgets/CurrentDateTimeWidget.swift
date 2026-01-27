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

// MARK: - Current Date Time Widget
class CurrentDateTimeWidget: BaseStatWidget {
    func configure(date: Date) {
        // Set smaller base font size for long date string
        baseFontSizes["title"] = 12
        baseFontSizes["value"] = 16 // Much smaller than default 24
        baseFontSizes["unit"] = 14

        titleLabel.text = "운동 일시"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR") // Ensure Korean locale for "오후"
        formatter.dateFormat = "yyyy년 M월 d일 a h시 m분" // 2026년 1월 12일 오후 8시 50분

        let dateTimeString = formatter.string(from: date)

        valueLabel.text = dateTimeString
        unitLabel.text = "" // No unit for combined date/time

        // Force font update with new base sizes
        updateFonts()
    }
}
