//
//  CalendarCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

class CalendarCell: UICollectionViewCell {
    static let identifier = "CalendarCell"

    private let calendarView = CustomCalendarView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        WPSurface.apply(to: contentView, cornerRadius: WPDesign.Radius.md)

        contentView.addSubview(calendarView)
        calendarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(delegate: CustomCalendarViewDelegate, selectedDate: DateComponents?) {
        calendarView.delegate = delegate
        if let selectedDate = selectedDate {
            calendarView.selectDate(selectedDate)
        }
        calendarView.reloadDecorations()
    }
}
