//
//  RecentSessionCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

class RecentSessionCell: UICollectionViewCell {
    static let identifier = "RecentSessionCell"

    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dateLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        iconContainer.layer.cornerRadius = 20
        iconContainer.addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = ColorSystem.mainText

        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = ColorSystem.subText

        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = ColorSystem.subText

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        contentView.addSubview(iconContainer)
        contentView.addSubview(textStack)
        contentView.addSubview(dateLabel)

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(icon: String, title: String, subtitle: String, date: Date, color: UIColor) {
        iconImageView.image = UIImage(systemName: icon)
        iconContainer.backgroundColor = color
        titleLabel.text = title
        subtitleLabel.text = subtitle

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        dateLabel.text = formatter.string(from: date)
    }
}
