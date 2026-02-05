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
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

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
