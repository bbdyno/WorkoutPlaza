//
//  CalendarHeaderCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

// MARK: - Calendar Header Cell

class CalendarHeaderCell: UICollectionViewCell {
    static let identifier = "CalendarHeaderCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "캘린더"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "모든 운동 기록"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = ColorSystem.subText
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2

        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}
