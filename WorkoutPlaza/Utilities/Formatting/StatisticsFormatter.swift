//
//  StatisticsFormatter.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import Foundation

enum StatisticsFormatter {

    static func periodLabel(for period: StatPeriod, year: Int, month: Int) -> String {
        switch period {
        case .month:
            return WorkoutFormatter.stripGroupingSeparators(
                from: WorkoutPlazaStrings.Statistics.Year.Month.label(year, month)
            )
        case .year:
            return WorkoutFormatter.stripGroupingSeparators(
                from: WorkoutPlazaStrings.Statistics.Year.label(year)
            )
        case .all:
            return WorkoutPlazaStrings.Statistics.Period.all
        }
    }

    static func selectedDateHeaderText(
        from dateComponents: DateComponents,
        calendar: Calendar = .current,
        locale: Locale = .autoupdatingCurrent
    ) -> String? {
        guard let date = calendar.date(from: dateComponents) else { return nil }
        return monthDayText(from: date, calendar: calendar, locale: locale)
    }

    static func monthDayText(
        from date: Date,
        calendar: Calendar = .current,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }
}
