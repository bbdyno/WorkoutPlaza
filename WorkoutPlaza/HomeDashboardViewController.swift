//
//  HomeDashboardViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit
import SnapKit

class HomeDashboardViewController: UIViewController {

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

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "WorkoutPlaza"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "운동 기록을 사진으로 만들어보세요"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .lightGray
        return label
    }()

    private let sportsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSportCards()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }

        // Header Section
        let headerContainer = UIView()
        headerContainer.addSubview(headerLabel)
        headerContainer.addSubview(subtitleLabel)

        headerLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStackView.addArrangedSubview(headerContainer)
        contentStackView.setCustomSpacing(40, after: headerContainer)

        // Sports Section Header
        let sectionLabel = UILabel()
        sectionLabel.text = "운동 종목 선택"
        sectionLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        sectionLabel.textColor = .white

        contentStackView.addArrangedSubview(sectionLabel)
        contentStackView.addArrangedSubview(sportsStackView)
    }

    private func setupSportCards() {
        for sport in SportType.allCases {
            let card = createSportCard(for: sport)
            sportsStackView.addArrangedSubview(card)
            card.snp.makeConstraints { make in
                make.height.equalTo(140)
            }
        }
    }

    private func createSportCard(for sport: SportType) -> UIView {
        let card = UIView()
        card.backgroundColor = sport.themeColor.withAlphaComponent(0.15)
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = sport.themeColor.withAlphaComponent(0.3).cgColor

        // Icon Container
        let iconContainer = UIView()
        iconContainer.backgroundColor = sport.themeColor.withAlphaComponent(0.2)
        iconContainer.layer.cornerRadius = 28

        let iconView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        iconView.image = UIImage(systemName: sport.iconName, withConfiguration: config)
        iconView.tintColor = sport.themeColor
        iconView.contentMode = .scaleAspectFit

        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // Labels
        let titleLabel = UILabel()
        titleLabel.text = sport.displayName
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white

        let descriptionLabel = UILabel()
        descriptionLabel.text = getDescription(for: sport)
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .lightGray
        descriptionLabel.numberOfLines = 2

        // Arrow
        let arrowView = UIImageView()
        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = sport.themeColor
        arrowView.contentMode = .scaleAspectFit

        // Layout
        card.addSubview(iconContainer)
        card.addSubview(titleLabel)
        card.addSubview(descriptionLabel)
        card.addSubview(arrowView)

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(56)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(16)
            make.top.equalToSuperview().offset(32)
            make.trailing.equalTo(arrowView.snp.leading).offset(-16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.trailing.equalTo(arrowView.snp.leading).offset(-16)
        }

        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        // Tap Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sportCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.isUserInteractionEnabled = true
        card.accessibilityIdentifier = sport.rawValue

        return card
    }

    private func getDescription(for sport: SportType) -> String {
        switch sport {
        case .running:
            return "HealthKit 또는 외부에서 가져온\n러닝 기록으로 사진 만들기"
        case .climbing:
            return "볼더링, 리드 클라이밍\n직접 기록을 입력하여 사진 만들기"
        }
    }

    // MARK: - Actions

    @objc private func sportCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view,
              let sportRawValue = card.accessibilityIdentifier,
              let sport = SportType(rawValue: sportRawValue) else { return }

        // Animate tap
        UIView.animate(withDuration: 0.1, animations: {
            card.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                card.transform = .identity
            } completion: { _ in
                self.navigateToSport(sport)
            }
        }
    }

    private func navigateToSport(_ sport: SportType) {
        switch sport {
        case .running:
            let workoutListVC = WorkoutListViewController()
            navigationController?.pushViewController(workoutListVC, animated: true)

        case .climbing:
            let climbingInputVC = ClimbingInputViewController()
            climbingInputVC.delegate = self
            let navController = UINavigationController(rootViewController: climbingInputVC)

            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.large()]
            }

            present(navController, animated: true)
        }
    }
}

// MARK: - ClimbingInputDelegate

extension HomeDashboardViewController: ClimbingInputDelegate {
    func climbingInput(_ controller: ClimbingInputViewController, didCreateSession session: ClimbingData) {
        let detailVC = ClimbingDetailViewController(climbingData: session)
        let navController = UINavigationController(rootViewController: detailVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}
