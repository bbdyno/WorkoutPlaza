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
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "운동 기록을 사진으로 만들어보세요"
        label.font = .systemFont(ofSize: 16)
        label.textColor = ColorSystem.subText
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
        view.backgroundColor = ColorSystem.background

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
        sectionLabel.textColor = ColorSystem.mainText

        contentStackView.addArrangedSubview(sectionLabel)
        contentStackView.addArrangedSubview(sportsStackView)
    }

    private func setupSportCards() {
        sportsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
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
        // Modern Card Style
        card.backgroundColor = ColorSystem.cardBackground
        card.layer.cornerRadius = 24
        card.layer.cornerCurve = .continuous
        // card.layer.borderWidth = 1
        // card.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        
        // Subtle shadow
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 12

        // Icon Container
        let iconContainer = UIView()
        // Use sport color for container with low alpha
        iconContainer.backgroundColor = sport.themeColor.withAlphaComponent(0.15)
        iconContainer.layer.cornerRadius = 28

        let iconView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
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
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = ColorSystem.mainText

        let descriptionLabel = UILabel()
        descriptionLabel.text = getDescription(for: sport)
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        descriptionLabel.textColor = ColorSystem.subText
        descriptionLabel.numberOfLines = 2

        // Arrow - Use a circle button look
        let arrowContainer = UIView()
        arrowContainer.backgroundColor = ColorSystem.background
        arrowContainer.layer.cornerRadius = 16

        let arrowView = UIImageView()
        arrowView.image = UIImage(systemName: "arrow.right")
        arrowView.tintColor = ColorSystem.mainText
        arrowView.contentMode = .scaleAspectFit
        
        arrowContainer.addSubview(arrowView)
        arrowView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(14)
        }

        // Layout
        card.addSubview(iconContainer)
        card.addSubview(titleLabel)
        card.addSubview(descriptionLabel)
        card.addSubview(arrowContainer)

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(56)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(20)
            make.top.equalTo(iconContainer.snp.top).offset(2)
            make.trailing.equalTo(arrowContainer.snp.leading).offset(-16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalTo(arrowContainer.snp.leading).offset(-16)
        }

        arrowContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
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
            return "HealthKit 데이터 연동\n러닝 기록 시각화"
        case .climbing:
            return "볼더링, 리드 클라이밍\n루트 및 등반 기록"
        }
    }

    // MARK: - Actions

    @objc private func sportCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view,
              let sportRawValue = card.accessibilityIdentifier,
              let sport = SportType(rawValue: sportRawValue) else { return }

        // Animate tap
        UIView.animate(withDuration: 0.1, animations: {
            card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
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
            let workoutListVC = RunningListViewController()
            let navController = UINavigationController(rootViewController: workoutListVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)

        case .climbing:
            let climbingInputVC = ClimbingInputViewController()
            climbingInputVC.delegate = self
            let navController = UINavigationController(rootViewController: climbingInputVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
}

// MARK: - ClimbingInputDelegate

extension HomeDashboardViewController: ClimbingInputDelegate {
    func climbingInputDidSave(_ controller: ClimbingInputViewController) {
        controller.dismiss(animated: true)
    }

    func climbingInput(_ controller: ClimbingInputViewController, didRequestCardFor session: ClimbingData) {
        let detailVC = ClimbingDetailViewController()
        detailVC.climbingData = session
        controller.navigationController?.pushViewController(detailVC, animated: true)
    }
}
