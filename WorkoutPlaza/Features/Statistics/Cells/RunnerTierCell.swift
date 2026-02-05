//
//  RunnerTierCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

// MARK: - Runner Tier Cell

class RunnerTierCell: UICollectionViewCell {
    static let identifier = "RunnerTierCell"

    private var gradientLayer: CAGradientLayer?

    private let tierLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let tierTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48)
        return label
    }()

    private let progressBarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let progressFillView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        contentView.addSubview(tierLabel)
        contentView.addSubview(tierTitleLabel)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(progressBarView)
        progressBarView.addSubview(progressFillView)
        contentView.addSubview(progressLabel)

        emojiLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        tierLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
        }

        tierTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(tierLabel)
            make.top.equalTo(tierLabel.snp.bottom).offset(4)
        }

        progressBarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-32)
            make.trailing.equalTo(emojiLabel.snp.leading).offset(-16)
            make.height.equalTo(8)
        }

        progressFillView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(0)
        }

        progressLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(progressBarView.snp.bottom).offset(4)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = contentView.bounds
    }

    func configure(totalDistance: Double) {
        let tier = RunnerTier.tier(for: totalDistance)
        let progress = tier.progress(to: totalDistance)

        tierLabel.text = tier.displayName
        tierTitleLabel.text = "총 \(String(format: "%.1f", totalDistance))km"
        emojiLabel.text = tier.emoji

        // Update gradient
        gradientLayer?.removeFromSuperlayer()
        let gradient = ColorSystem.tierGradientLayer(for: tier)
        gradient.frame = contentView.bounds
        contentView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient

        // Update progress bar
        progressFillView.snp.remakeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(max(progress, 0.01))
        }

        if let remaining = tier.remainingDistance(to: totalDistance) {
            progressLabel.text = "다음 등급까지 \(String(format: "%.1f", remaining))km"
        } else {
            progressLabel.text = "최고 등급 달성!"
        }
    }
}
