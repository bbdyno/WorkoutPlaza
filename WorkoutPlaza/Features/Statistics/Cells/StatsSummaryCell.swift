//
//  StatsSummaryCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

class StatsSummaryCell: UICollectionViewCell {
    static let identifier = "StatsSummaryCell"

    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        iconContainer.layer.cornerRadius = 10
        iconContainer.addSubview(iconImageView)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white

        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = ColorSystem.mainText

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = ColorSystem.subText

        let stack = UIStackView(arrangedSubviews: [iconContainer, valueLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.setCustomSpacing(12, after: iconContainer)

        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        iconContainer.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: String, icon: String, color: UIColor) {
        titleLabel.text = title
        valueLabel.text = value
        iconImageView.image = UIImage(systemName: icon)
        iconContainer.backgroundColor = color
    }
}
