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
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = ColorSystem.subText
        return button
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fillEqually
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

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
        }

        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(32)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        setupSportCards()
    }

    private func setupSportCards() {
        for sport in SportType.allCases {
            let card = createSportCard(for: sport)
            stackView.addArrangedSubview(card)
            card.snp.makeConstraints { make in
                make.height.equalTo(100)
            }
        }
    }

    private func createSportCard(for sport: SportType) -> UIView {
        let card = UIView()
        card.backgroundColor = ColorSystem.cardBackground
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = ColorSystem.divider.cgColor

        let iconContainer = UIView()
        iconContainer.backgroundColor = sport.themeColor.withAlphaComponent(0.15)
        iconContainer.layer.cornerRadius = 24

        let iconImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .semibold)
        iconImageView.image = UIImage(systemName: sport.iconName, withConfiguration: config)
        iconImageView.tintColor = sport.themeColor
        iconImageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = sport.displayName
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = ColorSystem.mainText

        card.addSubview(iconContainer)
        card.addSubview(titleLabel)

        iconContainer.addSubview(iconImageView)

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(56)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(20)
            make.centerY.equalToSuperview()
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

        delegate?.sportSelectorDidSelect(sport)

        UIView.animate(withDuration: 0.1, animations: {
            card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                card.transform = .identity
            } completion: { _ in
                self.dismiss(animated: true)
            }
        }
    }
}
