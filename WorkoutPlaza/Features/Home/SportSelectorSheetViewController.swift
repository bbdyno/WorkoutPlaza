//
//  SportSelectorSheetViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

protocol SportSelectorSheetDelegate: AnyObject {
    func sportSelectorDidSelect(_ sport: SportType)
}

class SportSelectorSheetViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: SportSelectorSheetDelegate?

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "운동 종목 선택"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = ColorSystem.mainText
        label.textAlignment = .center
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = ColorSystem.subText
        button.backgroundColor = ColorSystem.divider
        button.layer.cornerRadius = 15
        return button
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = ColorSystem.background

        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(stackView)

        // 타이틀: 시트 가로 중앙 (닫기 버튼과 독립 레이어)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }

        // 닫기 버튼: 우측 상단, 타이틀과 별도 배치
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(30)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        setupSportCards()
    }

    private func setupSportCards() {
        for sport in SportType.allCases {
            let card = createSportCard(for: sport)
            stackView.addArrangedSubview(card)
        }
    }

    private func createSportCard(for sport: SportType) -> UIView {
        let card = UIView()
        card.backgroundColor = ColorSystem.cardBackground
        card.layer.cornerRadius = 14
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = ColorSystem.divider.cgColor

        let iconContainer = UIView()
        iconContainer.backgroundColor = sport.themeColor.withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 22

        let iconImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iconImageView.image = UIImage(systemName: sport.iconName, withConfiguration: config)
        iconImageView.tintColor = sport.themeColor
        iconImageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = sport.displayName
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = ColorSystem.mainText

        let chevron = UIImageView()
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevron.tintColor = ColorSystem.subText
        chevron.contentMode = .scaleAspectFit

        card.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        card.addSubview(titleLabel)
        card.addSubview(chevron)

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
            make.height.equalTo(14)
        }

        card.snp.makeConstraints { make in
            make.height.equalTo(64)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sportCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.isUserInteractionEnabled = true
        card.accessibilityIdentifier = sport.rawValue

        return card
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func sportCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view,
              let sportRawValue = card.accessibilityIdentifier,
              let sport = SportType(rawValue: sportRawValue) else { return }

        UIView.animate(withDuration: 0.08, animations: {
            card.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            card.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.08) {
                card.transform = .identity
                card.alpha = 1.0
            } completion: { _ in
                self.dismiss(animated: true) {
                    self.delegate?.sportSelectorDidSelect(sport)
                }
            }
        }
    }
}
