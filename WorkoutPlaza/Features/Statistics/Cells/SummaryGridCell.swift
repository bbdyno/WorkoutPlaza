//
//  SummaryGridCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

// MARK: - Summary Grid Cell

class SummaryGridCell: UICollectionViewCell {
    static let identifier = "SummaryGridCell"

    private let gridStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(gridStack)
        gridStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with items: [StatsSummaryItem]) {
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Create 2x2 grid
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 12
        bottomRow.distribution = .fillEqually

        for (index, item) in items.prefix(4).enumerated() {
            let cardView = createStatCard(for: item)
            if index < 2 {
                topRow.addArrangedSubview(cardView)
            } else {
                bottomRow.addArrangedSubview(cardView)
            }
        }

        gridStack.addArrangedSubview(topRow)
        gridStack.addArrangedSubview(bottomRow)
    }

    private func createStatCard(for item: StatsSummaryItem) -> UIView {
        let card = UIView()
        card.backgroundColor = ColorSystem.cardBackground
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous

        let iconContainer = UIView()
        iconContainer.backgroundColor = item.color.withAlphaComponent(0.15)
        iconContainer.layer.cornerRadius = 12

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: item.icon)
        iconImageView.tintColor = item.color
        iconImageView.contentMode = .scaleAspectFit

        let valueLabel = UILabel()
        valueLabel.text = item.value
        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        valueLabel.textColor = ColorSystem.mainText

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = ColorSystem.subText

        card.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        card.addSubview(valueLabel)
        card.addSubview(titleLabel)

        iconContainer.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(12)
            make.width.height.equalTo(24)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(14)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalTo(titleLabel.snp.top).offset(-2)
        }

        return card
    }
}
