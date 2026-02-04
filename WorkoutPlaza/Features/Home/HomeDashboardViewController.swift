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

    private let recordsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        return stack
    }()

    private let addWorkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ 운동 추가", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = ColorSystem.primaryBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.layer.shadowColor = ColorSystem.primaryBlue.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecentRecords()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadRecentRecords()
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

        // Recent Records Section Header
        let sectionLabel = UILabel()
        sectionLabel.text = "최근 기록"
        sectionLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        sectionLabel.textColor = ColorSystem.mainText

        contentStackView.addArrangedSubview(sectionLabel)
        contentStackView.addArrangedSubview(recordsStackView)

        // Add Workout Button
        addWorkoutButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        addWorkoutButton.addTarget(self, action: #selector(addWorkoutTapped), for: .touchUpInside)

        contentStackView.addArrangedSubview(addWorkoutButton)
        contentStackView.setCustomSpacing(20, after: recordsStackView)
    }

    private func loadRecentRecords() {
        recordsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Load recent workouts
        let climbingSessions = ClimbingDataManager.shared.loadSessions()
        let sessions = climbingSessions.sorted(by: { $0.sessionDate > $1.sessionDate }).prefix(5)

        if sessions.isEmpty {
            let placeholderView = createPlaceholderView()
            recordsStackView.addArrangedSubview(placeholderView)
        } else {
            for session in sessions {
                let recordView = createRecordView(for: session)
                recordsStackView.addArrangedSubview(recordView)
                recordView.snp.makeConstraints { make in
                    make.height.equalTo(80)
                }
            }
        }
    }

    private func createPlaceholderView() -> UIView {
        let placeholder = UIView()
        placeholder.backgroundColor = ColorSystem.cardBackground
        placeholder.layer.cornerRadius = 16
        placeholder.layer.cornerCurve = .continuous

        let placeholderLabel = UILabel()
        placeholderLabel.text = "아직 기록이 없습니다"
        placeholderLabel.font = .systemFont(ofSize: 14, weight: .medium)
        placeholderLabel.textColor = ColorSystem.subText
        placeholderLabel.textAlignment = .center

        placeholder.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        placeholder.snp.makeConstraints { make in
            make.height.equalTo(100)
        }

        return placeholder
    }

    private func createRecordView(for session: ClimbingData) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = ColorSystem.cardBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.cornerCurve = .continuous

        let iconContainer = UIView()
        iconContainer.backgroundColor = ColorSystem.primaryGreen.withAlphaComponent(0.15)
        iconContainer.layer.cornerRadius = 20

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "figure.climbing")
        iconImageView.tintColor = ColorSystem.primaryGreen
        iconImageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = session.gymName.isEmpty ? "클라이밍" : session.gymName
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = ColorSystem.mainText

        let subtitleLabel = UILabel()
        subtitleLabel.text = "\(session.totalRoutes) 루트"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = ColorSystem.subText

        let dateLabel = UILabel()
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = ColorSystem.subText

        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        dateLabel.text = formatter.string(from: session.sessionDate)

        containerView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(dateLabel)

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.top.equalTo(iconContainer.snp.top).offset(4)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }

        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(recordTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        containerView.tag = hashValue(for: session)

        return containerView
    }

    private func hashValue(for session: ClimbingData) -> Int {
        return session.sessionDate.hashValue
    }

    // MARK: - Actions

    @objc private func addWorkoutTapped() {
        let sportSelectorVC = SportSelectorSheetViewController()
        sportSelectorVC.delegate = self
        sportSelectorVC.modalPresentationStyle = .pageSheet
        if let sheet = sportSelectorVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(sportSelectorVC, animated: true)
    }

    @objc private func recordTapped(_ gesture: UITapGestureRecognizer) {
        let climbingSessions = ClimbingDataManager.shared.loadSessions()
        let sessions = climbingSessions.sorted(by: { $0.sessionDate > $1.sessionDate })

        guard let view = gesture.view,
              let tag = view as? Int,
              tag != 0 else { return }

        let session = sessions.first { hashValue(for: $0) == tag }
        guard let session = session else { return }

        let detailVC = ClimbingDetailViewController()
        detailVC.climbingData = session
        let nav = UINavigationController(rootViewController: detailVC)
        present(nav, animated: true)
    }
}

// MARK: - SportSelectorSheetDelegate

extension HomeDashboardViewController: SportSelectorSheetDelegate {
    func sportSelectorDidSelect(_ sport: SportType) {
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
