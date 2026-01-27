//
//  SportSelectorViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit
import SnapKit

protocol SportSelectorDelegate: AnyObject {
    func sportSelector(_ controller: SportSelectorViewController, didSelect sport: SportType)
}

class SportSelectorViewController: UIViewController {

    weak var delegate: SportSelectorDelegate?

    // MARK: - UI Components

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "운동 기록 만들기"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "기록할 운동을 선택하세요"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let sportsStackView: UIStackView = {
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
        setupSportCards()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        view.addSubview(headerLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(sportsStackView)

        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        sportsStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }

    private func setupSportCards() {
        for sport in SportType.allCases {
            let card = createSportCard(for: sport)
            sportsStackView.addArrangedSubview(card)
            card.snp.makeConstraints { make in
                make.height.equalTo(120)
            }
        }
    }

    private func createSportCard(for sport: SportType) -> UIView {
        let card = UIView()
        card.backgroundColor = sport.themeColor.withAlphaComponent(0.1)
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 2
        card.layer.borderColor = sport.themeColor.withAlphaComponent(0.3).cgColor

        let iconView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        iconView.image = UIImage(systemName: sport.iconName, withConfiguration: config)
        iconView.tintColor = sport.themeColor
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = sport.displayName
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label

        let descriptionLabel = UILabel()
        descriptionLabel.text = getDescription(for: sport)
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2

        let arrowView = UIImageView()
        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = sport.themeColor
        arrowView.contentMode = .scaleAspectFit

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(descriptionLabel)
        card.addSubview(arrowView)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.top.equalToSuperview().offset(24)
            make.trailing.equalTo(arrowView.snp.leading).offset(-16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalTo(arrowView.snp.leading).offset(-16)
        }

        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sportCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.isUserInteractionEnabled = true
        card.tag = sport.hashValue

        // Store sport type for retrieval
        card.accessibilityIdentifier = sport.rawValue

        return card
    }

    private func getDescription(for sport: SportType) -> String {
        switch sport {
        case .running:
            return "러닝, 걷기, 하이킹 등\nHealthKit에서 데이터를 가져옵니다"
        case .climbing:
            return "볼더링, 리드 클라이밍\n직접 기록을 입력합니다"
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func sportCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view,
              let sportRawValue = card.accessibilityIdentifier,
              let sport = SportType(rawValue: sportRawValue) else { return }

        // Animate tap
        UIView.animate(withDuration: 0.1, animations: {
            card.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                card.transform = .identity
            } completion: { _ in
                self.delegate?.sportSelector(self, didSelect: sport)
            }
        }
    }
}

// MARK: - Main Entry Point Extension

extension SportSelectorViewController {

    /// Present the appropriate view controller based on sport selection
    func navigateToSport(_ sport: SportType, from presenter: UIViewController) {
        switch sport {
        case .running:
            // Navigate to running workout list (existing flow)
            let workoutListVC = RunningListViewController()
            let navController = UINavigationController(rootViewController: workoutListVC)
            navController.modalPresentationStyle = .fullScreen
            presenter.present(navController, animated: true)

        case .climbing:
            // Navigate to climbing input
            let climbingInputVC = ClimbingInputViewController()
            climbingInputVC.delegate = self as? ClimbingInputDelegate
            let navController = UINavigationController(rootViewController: climbingInputVC)

            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.large()]
            }

            presenter.present(navController, animated: true)
        }
    }
}
