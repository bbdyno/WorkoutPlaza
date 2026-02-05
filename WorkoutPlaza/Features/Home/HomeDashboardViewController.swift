//
//  HomeDashboardViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit
import SnapKit

class HomeDashboardViewController: UIViewController {

    // MARK: - Data

    private var runningWorkouts: [WorkoutData] = []
    private var externalRunningWorkouts: [ExternalWorkout] = []
    private var climbingSessions: [ClimbingData] = []
    private var combinedRecentWorkouts: [(sportType: SportType, data: Any, date: Date)] = []

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

    // Tier Card
    private let tierCardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()

    private var tierGradientLayer: CAGradientLayer?

    private let tierEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48)
        return label
    }()

    private let tierNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let tierDistanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()

    private let tierProgressBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let tierProgressFill: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 4
        return view
    }()

    private let tierProgressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        return label
    }()

    // Weekly Summary
    private let weeklySummaryStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    private let runningWeeklyCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let climbingWeeklyCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let recordsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
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

    // Weekly summary labels
    private let runningWeeklyValueLabel = UILabel()
    private let runningWeeklySubtitleLabel = UILabel()
    private let climbingWeeklyValueLabel = UILabel()
    private let climbingWeeklySubtitleLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAllData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadAllData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tierGradientLayer?.frame = tierCardView.bounds
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
        contentStackView.setCustomSpacing(24, after: headerContainer)

        // Tier Card Section
        setupTierCard()
        contentStackView.addArrangedSubview(tierCardView)
        tierCardView.snp.makeConstraints { make in
            make.height.equalTo(140)
        }
        contentStackView.setCustomSpacing(24, after: tierCardView)

        // Weekly Summary Section
        let weeklySectionLabel = UILabel()
        weeklySectionLabel.text = "이번 주"
        weeklySectionLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        weeklySectionLabel.textColor = ColorSystem.mainText

        contentStackView.addArrangedSubview(weeklySectionLabel)
        contentStackView.setCustomSpacing(12, after: weeklySectionLabel)

        setupWeeklySummaryCards()
        contentStackView.addArrangedSubview(weeklySummaryStack)
        weeklySummaryStack.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
        contentStackView.setCustomSpacing(24, after: weeklySummaryStack)

        // Recent Records Section Header
        let sectionLabel = UILabel()
        sectionLabel.text = "최근 기록"
        sectionLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        sectionLabel.textColor = ColorSystem.mainText

        contentStackView.addArrangedSubview(sectionLabel)
        contentStackView.setCustomSpacing(12, after: sectionLabel)
        contentStackView.addArrangedSubview(recordsStackView)

        // Add Workout Button
        addWorkoutButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        addWorkoutButton.addTarget(self, action: #selector(addWorkoutTapped), for: .touchUpInside)

        contentStackView.addArrangedSubview(addWorkoutButton)
        contentStackView.setCustomSpacing(20, after: recordsStackView)
    }

    private func setupTierCard() {
        // Setup tier card content
        tierCardView.addSubview(tierEmojiLabel)
        tierCardView.addSubview(tierNameLabel)
        tierCardView.addSubview(tierDistanceLabel)
        tierCardView.addSubview(tierProgressBar)
        tierProgressBar.addSubview(tierProgressFill)
        tierCardView.addSubview(tierProgressLabel)

        tierEmojiLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }

        tierNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
        }

        tierDistanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(tierNameLabel)
            make.top.equalTo(tierNameLabel.snp.bottom).offset(4)
        }

        tierProgressBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(tierEmojiLabel.snp.leading).offset(-20)
            make.bottom.equalToSuperview().offset(-36)
            make.height.equalTo(8)
        }

        tierProgressFill.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(0)
        }

        tierProgressLabel.snp.makeConstraints { make in
            make.leading.equalTo(tierProgressBar)
            make.top.equalTo(tierProgressBar.snp.bottom).offset(8)
        }
    }

    private func setupWeeklySummaryCards() {
        // Running Card
        let runningIconContainer = UIView()
        runningIconContainer.backgroundColor = ColorSystem.primaryBlue.withAlphaComponent(0.15)
        runningIconContainer.layer.cornerRadius = 16

        let runningIcon = UIImageView()
        runningIcon.image = UIImage(systemName: "figure.run")
        runningIcon.tintColor = ColorSystem.primaryBlue
        runningIcon.contentMode = .scaleAspectFit

        runningWeeklyValueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        runningWeeklyValueLabel.textColor = ColorSystem.mainText
        runningWeeklyValueLabel.text = "0 km"

        runningWeeklySubtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        runningWeeklySubtitleLabel.textColor = ColorSystem.subText
        runningWeeklySubtitleLabel.text = "러닝"

        runningWeeklyCard.addSubview(runningIconContainer)
        runningIconContainer.addSubview(runningIcon)
        runningWeeklyCard.addSubview(runningWeeklyValueLabel)
        runningWeeklyCard.addSubview(runningWeeklySubtitleLabel)

        runningIconContainer.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
            make.width.height.equalTo(32)
        }

        runningIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }

        runningWeeklyValueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalTo(runningWeeklySubtitleLabel.snp.top).offset(-2)
        }

        runningWeeklySubtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        // Climbing Card
        let climbingIconContainer = UIView()
        climbingIconContainer.backgroundColor = ColorSystem.primaryGreen.withAlphaComponent(0.15)
        climbingIconContainer.layer.cornerRadius = 16

        let climbingIcon = UIImageView()
        climbingIcon.image = UIImage(systemName: "figure.climbing")
        climbingIcon.tintColor = ColorSystem.primaryGreen
        climbingIcon.contentMode = .scaleAspectFit

        climbingWeeklyValueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        climbingWeeklyValueLabel.textColor = ColorSystem.mainText
        climbingWeeklyValueLabel.text = "0 회"

        climbingWeeklySubtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        climbingWeeklySubtitleLabel.textColor = ColorSystem.subText
        climbingWeeklySubtitleLabel.text = "클라이밍"

        climbingWeeklyCard.addSubview(climbingIconContainer)
        climbingIconContainer.addSubview(climbingIcon)
        climbingWeeklyCard.addSubview(climbingWeeklyValueLabel)
        climbingWeeklyCard.addSubview(climbingWeeklySubtitleLabel)

        climbingIconContainer.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
            make.width.height.equalTo(32)
        }

        climbingIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }

        climbingWeeklyValueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalTo(climbingWeeklySubtitleLabel.snp.top).offset(-2)
        }

        climbingWeeklySubtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        weeklySummaryStack.addArrangedSubview(runningWeeklyCard)
        weeklySummaryStack.addArrangedSubview(climbingWeeklyCard)
    }

    // MARK: - Data Loading

    private func loadAllData() {
        // Load climbing sessions
        climbingSessions = ClimbingDataManager.shared.loadSessions()

        // Load external running workouts
        externalRunningWorkouts = ExternalWorkoutManager.shared.getAllWorkouts().filter { $0.workoutData.type == "러닝" }

        // Load HealthKit running workouts
        WorkoutManager.shared.fetchWorkouts { [weak self] workouts in
            guard let self = self else { return }
            self.runningWorkouts = workouts.filter { $0.workoutType == "러닝" }

            DispatchQueue.main.async {
                self.updateTierCard()
                self.updateWeeklySummary()
                self.updateRecentRecords()
            }
        }
    }

    private func updateTierCard() {
        // Calculate total running distance
        let healthKitDistance = runningWorkouts.reduce(0) { $0 + $1.distance } / 1000.0
        let externalDistance = externalRunningWorkouts.reduce(0) { $0 + $1.workoutData.distance } / 1000.0
        let totalDistance = healthKitDistance + externalDistance

        let tier = RunnerTier.tier(for: totalDistance)
        let progress = tier.progress(to: totalDistance)

        // Update UI
        tierEmojiLabel.text = tier.emoji
        tierNameLabel.text = tier.displayName
        tierDistanceLabel.text = String(format: "총 %.1f km", totalDistance)

        if let remaining = tier.remainingDistance(to: totalDistance) {
            tierProgressLabel.text = String(format: "다음 등급까지 %.1f km", remaining)
        } else {
            tierProgressLabel.text = "최고 등급 달성!"
        }

        // Update gradient
        tierGradientLayer?.removeFromSuperlayer()
        let gradient = ColorSystem.tierGradientLayer(for: tier)
        gradient.frame = tierCardView.bounds
        tierCardView.layer.insertSublayer(gradient, at: 0)
        tierGradientLayer = gradient

        // Animate progress bar
        tierProgressFill.snp.remakeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(progress)
        }

        UIView.animate(withDuration: 0.3) {
            self.tierProgressBar.layoutIfNeeded()
        }
    }

    private func updateWeeklySummary() {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return }

        // Calculate weekly running distance
        var weeklyRunningDistance: Double = 0

        for workout in runningWorkouts {
            if workout.startDate >= weekStart {
                weeklyRunningDistance += workout.distance
            }
        }

        for workout in externalRunningWorkouts {
            if workout.workoutData.startDate >= weekStart {
                weeklyRunningDistance += workout.workoutData.distance
            }
        }

        let distanceKm = weeklyRunningDistance / 1000.0
        runningWeeklyValueLabel.text = String(format: "%.1f km", distanceKm)

        // Calculate weekly climbing sessions
        let weeklyClimbingSessions = climbingSessions.filter { $0.sessionDate >= weekStart }
        let weeklyRoutes = weeklyClimbingSessions.reduce(0) { $0 + $1.totalRoutes }
        climbingWeeklyValueLabel.text = "\(weeklyRoutes) 루트"
    }

    private func updateRecentRecords() {
        recordsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Combine all workouts
        combinedRecentWorkouts.removeAll()

        for workout in runningWorkouts {
            combinedRecentWorkouts.append((sportType: .running, data: workout, date: workout.startDate))
        }

        for workout in externalRunningWorkouts {
            combinedRecentWorkouts.append((sportType: .running, data: workout, date: workout.workoutData.startDate))
        }

        for session in climbingSessions {
            combinedRecentWorkouts.append((sportType: .climbing, data: session, date: session.sessionDate))
        }

        // Sort by date descending and take first 5
        combinedRecentWorkouts.sort { $0.date > $1.date }
        let recentWorkouts = combinedRecentWorkouts.prefix(5)

        if recentWorkouts.isEmpty {
            let placeholderView = createPlaceholderView()
            recordsStackView.addArrangedSubview(placeholderView)
        } else {
            for (index, workout) in recentWorkouts.enumerated() {
                let recordView = createRecordView(for: workout, index: index)
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

    private func createRecordView(for workout: (sportType: SportType, data: Any, date: Date), index: Int) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = ColorSystem.cardBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.cornerCurve = .continuous

        let themeColor = workout.sportType.themeColor
        let iconName = workout.sportType.iconName

        let iconContainer = UIView()
        iconContainer.backgroundColor = themeColor.withAlphaComponent(0.15)
        iconContainer.layer.cornerRadius = 20

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = themeColor
        iconImageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = ColorSystem.mainText

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = ColorSystem.subText

        let dateLabel = UILabel()
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = ColorSystem.subText

        // Configure based on workout type
        switch workout.sportType {
        case .running:
            if let healthKitWorkout = workout.data as? WorkoutData {
                titleLabel.text = "러닝"
                subtitleLabel.text = String(format: "%.1f km", healthKitWorkout.distance / 1000)
            } else if let externalWorkout = workout.data as? ExternalWorkout {
                titleLabel.text = "러닝"
                subtitleLabel.text = String(format: "%.1f km", externalWorkout.workoutData.distance / 1000)
            }
        case .climbing:
            if let session = workout.data as? ClimbingData {
                titleLabel.text = session.gymName.isEmpty ? "클라이밍" : session.gymName
                subtitleLabel.text = "\(session.totalRoutes) 루트"
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        dateLabel.text = formatter.string(from: workout.date)

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
        containerView.tag = index

        return containerView
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
        guard let view = gesture.view else { return }
        let index = view.tag

        guard index < combinedRecentWorkouts.count else { return }
        let workout = combinedRecentWorkouts[index]

        switch workout.sportType {
        case .running:
            if let healthKitWorkout = workout.data as? WorkoutData {
                let detailVC = RunningDetailViewController()
                detailVC.workoutData = healthKitWorkout
                let nav = UINavigationController(rootViewController: detailVC)
                present(nav, animated: true)
            } else if let externalWorkout = workout.data as? ExternalWorkout {
                let detailVC = RunningDetailViewController()
                detailVC.externalWorkout = externalWorkout
                let nav = UINavigationController(rootViewController: detailVC)
                present(nav, animated: true)
            }
        case .climbing:
            if let session = workout.data as? ClimbingData {
                let detailVC = ClimbingDetailViewController()
                detailVC.climbingData = session
                let nav = UINavigationController(rootViewController: detailVC)
                present(nav, animated: true)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d시간 %02d분", hours, minutes)
        } else {
            return String(format: "%d분 %02d초", minutes, seconds)
        }
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
