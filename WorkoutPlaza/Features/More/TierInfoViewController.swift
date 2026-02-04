//
//  TierInfoViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

class TierInfoViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTiers()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = ColorSystem.background
        title = "러너 티어 시스템"

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }

        // Header
        let headerLabel = UILabel()
        headerLabel.text = "러너 티어 시스템"
        headerLabel.font = .systemFont(ofSize: 28, weight: .bold)
        headerLabel.textColor = ColorSystem.mainText

        let descLabel = UILabel()
        descLabel.text = "총 러닝 거리에 따라 티어가 상승하며, 앱 테마 색상이 변화합니다."
        descLabel.font = .systemFont(ofSize: 15)
        descLabel.textColor = ColorSystem.subText
        descLabel.numberOfLines = 0

        let headerContainer = UIView()
        headerContainer.addSubview(headerLabel)
        headerContainer.addSubview(descLabel)

        headerLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        descLabel.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStackView.addArrangedSubview(headerContainer)
        contentStackView.setCustomSpacing(32, after: headerContainer)
    }

    private func setupTiers() {
        for tier in RunnerTier.allCases {
            let tierCard = createTierCard(for: tier)
            contentStackView.addArrangedSubview(tierCard)
        }
    }

    private func createTierCard(for tier: RunnerTier) -> UIView {
        let card = UIView()
        card.backgroundColor = ColorSystem.cardBackground
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 2
        card.layer.borderColor = tier.themeColor.withAlphaComponent(0.3).cgColor

        let emojiLabel = UILabel()
        emojiLabel.text = tier.emoji
        emojiLabel.font = .systemFont(ofSize: 48)

        let titleLabel = UILabel()
        titleLabel.text = tier.displayName
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = ColorSystem.mainText

        let distanceLabel = UILabel()
        distanceLabel.text = "\(tier.minDistance)km+"
        distanceLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        distanceLabel.textColor = tier.themeColor

        let colorLabel = UILabel()
        colorLabel.text = "테마: "
        colorLabel.font = .systemFont(ofSize: 14)
        colorLabel.textColor = ColorSystem.subText

        let colorView = UIView()
        colorView.backgroundColor = tier.themeColor
        colorView.layer.cornerRadius = 8
        colorView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        let colorStack = UIStackView(arrangedSubviews: [colorLabel, colorView])
        colorStack.axis = .horizontal
        colorStack.spacing = 8
        colorStack.alignment = .center

        card.addSubview(emojiLabel)
        card.addSubview(titleLabel)
        card.addSubview(distanceLabel)
        card.addSubview(colorStack)

        emojiLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(emojiLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
        }

        distanceLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(20)
        }

        colorStack.snp.makeConstraints { make in
            make.top.equalTo(distanceLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
        }

        return card
    }
}
