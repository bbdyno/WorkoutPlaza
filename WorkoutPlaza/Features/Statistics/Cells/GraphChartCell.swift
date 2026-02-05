//
//  GraphChartCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

// MARK: - Graph Chart Cell

class GraphChartCell: UICollectionViewCell {
    static let identifier = "GraphChartCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let chartView = BarChartView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        contentView.addSubview(titleLabel)
        contentView.addSubview(chartView)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }

        chartView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    func configure(title: String, data: [BarChartDataPoint], unit: String) {
        titleLabel.text = title
        chartView.configure(
            with: data,
            showValues: true,
            valueFormatter: { value in
                if value >= 100 {
                    return String(format: "%.0f", value)
                } else if value >= 10 {
                    return String(format: "%.1f", value)
                } else {
                    return String(format: "%.1f", value)
                }
            },
            onBarTapped: nil,
            onFloatingViewDismiss: nil
        )
    }
}
