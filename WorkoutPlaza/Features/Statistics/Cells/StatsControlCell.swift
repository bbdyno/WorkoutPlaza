//
//  StatsControlCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

// MARK: - Stats Control Cell Delegate

protocol StatsControlCellDelegate: AnyObject {
    func statsControlCell(_ cell: StatsControlCell, didChangeSport sport: StatSportType)
    func statsControlCell(_ cell: StatsControlCell, didChangePeriod period: StatPeriod)
    func statsControlCellDidTapPrevPeriod(_ cell: StatsControlCell)
    func statsControlCellDidTapNextPeriod(_ cell: StatsControlCell)
}

// MARK: - Stats Control Cell

class StatsControlCell: UICollectionViewCell {
    static let identifier = "StatsControlCell"

    weak var delegate: StatsControlCellDelegate?

    private let sportSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: StatSportType.allCases.map { $0.displayName })
        control.selectedSegmentIndex = 0
        control.backgroundColor = ColorSystem.divider
        control.selectedSegmentTintColor = ColorSystem.controlTint
        control.setTitleTextAttributes([.foregroundColor: ColorSystem.mainText], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    private let prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = ColorSystem.mainText
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = ColorSystem.mainText
        return button
    }()

    private let periodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = ColorSystem.mainText
        label.textAlignment = .center
        return label
    }()

    private let periodSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: StatPeriod.allCases.map { $0.displayName })
        control.selectedSegmentIndex = 0
        control.backgroundColor = ColorSystem.divider
        control.selectedSegmentTintColor = ColorSystem.controlTint
        control.setTitleTextAttributes([.foregroundColor: ColorSystem.mainText], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        contentView.addSubview(sportSegmentedControl)
        contentView.addSubview(prevButton)
        contentView.addSubview(periodLabel)
        contentView.addSubview(nextButton)
        contentView.addSubview(periodSegmentedControl)

        sportSegmentedControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(32)
        }

        prevButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.top.equalTo(sportSegmentedControl.snp.bottom).offset(12)
            make.width.height.equalTo(32)
        }

        periodLabel.snp.makeConstraints { make in
            make.leading.equalTo(prevButton.snp.trailing).offset(8)
            make.trailing.equalTo(nextButton.snp.leading).offset(-8)
            make.centerY.equalTo(prevButton)
        }

        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalTo(prevButton)
            make.width.height.equalTo(32)
        }

        periodSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(prevButton.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(32)
        }

        sportSegmentedControl.addTarget(self, action: #selector(sportChanged), for: .valueChanged)
        periodSegmentedControl.addTarget(self, action: #selector(periodChanged), for: .valueChanged)
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    func configure(sport: StatSportType, period: StatPeriod, periodLabel: String, canGoNext: Bool, delegate: StatsControlCellDelegate) {
        self.delegate = delegate
        sportSegmentedControl.selectedSegmentIndex = sport.rawValue
        periodSegmentedControl.selectedSegmentIndex = period.rawValue
        self.periodLabel.text = periodLabel
        nextButton.isEnabled = canGoNext
        nextButton.alpha = canGoNext ? 1.0 : 0.3

    }

    @objc private func sportChanged() {
        guard let sport = StatSportType(rawValue: sportSegmentedControl.selectedSegmentIndex) else { return }
        delegate?.statsControlCell(self, didChangeSport: sport)
    }

    @objc private func periodChanged() {
        guard let period = StatPeriod(rawValue: periodSegmentedControl.selectedSegmentIndex) else { return }
        delegate?.statsControlCell(self, didChangePeriod: period)
    }

    @objc private func prevTapped() {
        delegate?.statsControlCellDidTapPrevPeriod(self)
    }

    @objc private func nextTapped() {
        delegate?.statsControlCellDidTapNextPeriod(self)
    }
}
