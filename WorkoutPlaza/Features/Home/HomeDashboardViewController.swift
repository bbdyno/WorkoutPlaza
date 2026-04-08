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

    private let previewRecordCount = 2

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

    private let logoContainerView = UIView()

    private let logoGradientLayer: CAGradientLayer = ColorSystem.brandGradientLayer()

    private let logoMaskImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo_white")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let subtitleContainerView = UIView()

    private let subtitleGradientLayer: CAGradientLayer = ColorSystem.brandGradientLayer()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Home.description
        label.font = AppFont.body(16)
        label.textColor = .black
        label.textAlignment = .center
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
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let climbingWeeklyCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 20
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
        button.setTitle(WorkoutPlazaStrings.Button.Add.workout, for: .normal)
        button.titleLabel?.font = AppFont.bodySemiBold(16)
        button.backgroundColor = ColorSystem.mainText
        button.setTitleColor(ColorSystem.background, for: .normal)
        button.layer.cornerRadius = 24
        button.layer.cornerCurve = .continuous
        button.layer.shadowColor = ColorSystem.mainText.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        return button
    }()

    // Weekly summary labels - Running
    private let runningWeeklyDistanceLabel = UILabel()
    private let runningWeeklyCountLabel = UILabel()
    private let runningWeeklyTimeLabel = UILabel()

    // Weekly summary labels - Climbing
    private let climbingWeeklyRoutesLabel = UILabel()
    private let climbingWeeklyVisitLabel = UILabel()
    private let climbingWeeklySentLabel = UILabel()

    // Recent records toggle
    private let recordsToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = AppFont.bodySemiBold(14)
        button.setTitleColor(ColorSystem.subText, for: .normal)
        return button
    }()

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
        logoGradientLayer.frame = logoContainerView.bounds
        logoMaskImageView.frame = logoContainerView.bounds
        subtitleGradientLayer.frame = subtitleContainerView.bounds
        subtitleLabel.frame = subtitleContainerView.bounds
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

        logoContainerView.layer.addSublayer(logoGradientLayer)
        logoContainerView.mask = logoMaskImageView

        subtitleContainerView.layer.addSublayer(subtitleGradientLayer)
        subtitleContainerView.mask = subtitleLabel

        headerContainer.addSubview(logoContainerView)
        headerContainer.addSubview(subtitleContainerView)

        logoContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
            make.width.equalTo(150)
        }

        subtitleContainerView.snp.makeConstraints { make in
            make.top.equalTo(logoContainerView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStackView.addArrangedSubview(headerContainer)
        contentStackView.setCustomSpacing(24, after: headerContainer)

        // Weekly Summary Section
        let weeklySectionLabel = UILabel()
        weeklySectionLabel.text = WorkoutPlazaStrings.Home.This.week
        weeklySectionLabel.font = AppFont.bodySemiBold(20)
        weeklySectionLabel.textColor = ColorSystem.mainText

        contentStackView.addArrangedSubview(weeklySectionLabel)
        contentStackView.setCustomSpacing(12, after: weeklySectionLabel)

        setupWeeklySummaryCards()
        contentStackView.addArrangedSubview(weeklySummaryStack)
        weeklySummaryStack.snp.makeConstraints { make in
            make.height.equalTo(116)
        }
        contentStackView.setCustomSpacing(24, after: weeklySummaryStack)

        // Recent Records Section Header
        let sectionHeaderView = UIView()

        let sectionLabel = UILabel()
        sectionLabel.text = WorkoutPlazaStrings.Home.Recent.records
        sectionLabel.font = AppFont.bodySemiBold(20)
        sectionLabel.textColor = ColorSystem.mainText

        sectionHeaderView.addSubview(sectionLabel)
        sectionHeaderView.addSubview(recordsToggleButton)

        sectionLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        recordsToggleButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }

        recordsToggleButton.addTarget(self, action: #selector(showAllRecords), for: .touchUpInside)

        contentStackView.addArrangedSubview(sectionHeaderView)
        contentStackView.setCustomSpacing(12, after: sectionHeaderView)
        contentStackView.addArrangedSubview(recordsStackView)

        // Add Workout Button
        addWorkoutButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        addWorkoutButton.addTarget(self, action: #selector(addWorkoutTapped), for: .touchUpInside)

        contentStackView.addArrangedSubview(addWorkoutButton)
        contentStackView.setCustomSpacing(20, after: recordsStackView)
    }

    private func setupWeeklySummaryCards() {
        // Running Card
        let runningHeader = UIStackView()
        runningHeader.axis = .horizontal
        runningHeader.spacing = 6
        runningHeader.alignment = .center

        let runningIcon = UIImageView()
        runningIcon.image = UIImage(named: "icon.person.run")
        runningIcon.tintColor = ColorSystem.controlTint
        runningIcon.contentMode = .scaleAspectFit
        runningIcon.snp.makeConstraints { make in make.width.height.equalTo(16) }

        let runningTitleLabel = UILabel()
        runningTitleLabel.text = WorkoutPlazaStrings.Workout.running
        runningTitleLabel.font = AppFont.bodySemiBold(13)
        runningTitleLabel.textColor = ColorSystem.subText

        runningHeader.addArrangedSubview(runningIcon)
        runningHeader.addArrangedSubview(runningTitleLabel)

        runningWeeklyDistanceLabel.font = AppFont.stat(28)
        runningWeeklyDistanceLabel.textColor = ColorSystem.mainText
        runningWeeklyDistanceLabel.text = "0.0 km"

        runningWeeklyCountLabel.font = AppFont.statRegular(12)
        runningWeeklyCountLabel.textColor = ColorSystem.subText
        runningWeeklyCountLabel.text = WorkoutPlazaStrings.Zero.times

        runningWeeklyTimeLabel.font = AppFont.statRegular(12)
        runningWeeklyTimeLabel.textColor = ColorSystem.subText
        runningWeeklyTimeLabel.text = WorkoutPlazaStrings.Zero.minutes

        let runningDetailStack = UIStackView(arrangedSubviews: [runningWeeklyCountLabel, runningWeeklyTimeLabel])
        runningDetailStack.axis = .horizontal
        runningDetailStack.spacing = 8

        runningWeeklyCard.addSubview(runningHeader)
        runningWeeklyCard.addSubview(runningWeeklyDistanceLabel)
        runningWeeklyCard.addSubview(runningDetailStack)

        runningHeader.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
        }

        runningWeeklyDistanceLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalTo(runningHeader.snp.bottom).offset(8)
        }

        runningDetailStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-14)
        }

        // Climbing Card
        let climbingHeader = UIStackView()
        climbingHeader.axis = .horizontal
        climbingHeader.spacing = 6
        climbingHeader.alignment = .center

        let climbingIcon = UIImageView()
        climbingIcon.image = UIImage(named: "icon.mountains")
        climbingIcon.tintColor = ColorSystem.controlTint
        climbingIcon.contentMode = .scaleAspectFit
        climbingIcon.snp.makeConstraints { make in make.width.height.equalTo(16) }

        let climbingTitleLabel = UILabel()
        climbingTitleLabel.text = WorkoutPlazaStrings.Workout.climbing
        climbingTitleLabel.font = AppFont.bodySemiBold(13)
        climbingTitleLabel.textColor = ColorSystem.subText

        climbingHeader.addArrangedSubview(climbingIcon)
        climbingHeader.addArrangedSubview(climbingTitleLabel)

        climbingWeeklyRoutesLabel.font = AppFont.stat(22)
        climbingWeeklyRoutesLabel.textColor = ColorSystem.mainText
        climbingWeeklyRoutesLabel.text = WorkoutPlazaStrings.Zero.routes

        climbingWeeklyVisitLabel.font = AppFont.statRegular(12)
        climbingWeeklyVisitLabel.textColor = ColorSystem.subText
        climbingWeeklyVisitLabel.text = WorkoutPlazaStrings.Zero.visits

        climbingWeeklySentLabel.font = AppFont.statRegular(12)
        climbingWeeklySentLabel.textColor = ColorSystem.subText
        climbingWeeklySentLabel.text = WorkoutPlazaStrings.Sent.zero

        let climbingDetailStack = UIStackView(arrangedSubviews: [climbingWeeklyVisitLabel, climbingWeeklySentLabel])
        climbingDetailStack.axis = .horizontal
        climbingDetailStack.spacing = 8

        climbingWeeklyCard.addSubview(climbingHeader)
        climbingWeeklyCard.addSubview(climbingWeeklyRoutesLabel)
        climbingWeeklyCard.addSubview(climbingDetailStack)

        climbingHeader.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
        }

        climbingWeeklyRoutesLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalTo(climbingHeader.snp.bottom).offset(8)
        }

        climbingDetailStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-14)
        }

        weeklySummaryStack.addArrangedSubview(runningWeeklyCard)
        weeklySummaryStack.addArrangedSubview(climbingWeeklyCard)
    }

    // MARK: - Data Loading

    private func loadAllData() {
        // Load climbing sessions
        climbingSessions = ClimbingDataManager.shared.loadSessions()

        // Load external running workouts
        externalRunningWorkouts = ExternalWorkoutManager.shared.getAllWorkouts().filter { $0.workoutData.type == .running }

        // Load HealthKit indoor/outdoor running workouts.
        WorkoutManager.shared.fetchIndoorOutdoorRunningWorkouts { [weak self] workouts in
            guard let self = self else { return }
            self.runningWorkouts = workouts

            DispatchQueue.main.async {
                self.updateWeeklySummary()
                self.updateRecentRecords()
            }
        }
    }

    private func updateWeeklySummary() {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return }

        // Running stats
        var weeklyRunningDistance: Double = 0
        var weeklyRunningDuration: TimeInterval = 0
        var weeklyRunningCount = 0

        for workout in runningWorkouts {
            if workout.startDate >= weekStart {
                weeklyRunningDistance += workout.distance
                weeklyRunningDuration += workout.duration
                weeklyRunningCount += 1
            }
        }

        for workout in externalRunningWorkouts {
            if workout.workoutData.startDate >= weekStart {
                weeklyRunningDistance += workout.workoutData.distance
                weeklyRunningDuration += workout.workoutData.duration
                weeklyRunningCount += 1
            }
        }

        let distanceKm = weeklyRunningDistance / 1000.0
        runningWeeklyDistanceLabel.text = String(format: "%.1f km", distanceKm)
        runningWeeklyCountLabel.text = WorkoutPlazaStrings.Home.Weekly.count(weeklyRunningCount)

        let totalMinutes = Int(weeklyRunningDuration) / 60
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            runningWeeklyTimeLabel.text = WorkoutPlazaStrings.Home.Weekly.Time.hours(hours, mins)
        } else {
            runningWeeklyTimeLabel.text = WorkoutPlazaStrings.Home.Weekly.Time.minutes(totalMinutes)
        }

        // Climbing stats
        let weeklyClimbingSessions = climbingSessions.filter { $0.sessionDate >= weekStart }
        let weeklyRoutes = weeklyClimbingSessions.reduce(0) { $0 + $1.totalRoutes }
        let weeklySent = weeklyClimbingSessions.reduce(0) { $0 + $1.sentRoutes }
        let weeklyVisits = weeklyClimbingSessions.count

        climbingWeeklyRoutesLabel.text = WorkoutPlazaStrings.Home.Weekly.routes(weeklyRoutes)
        climbingWeeklyVisitLabel.text = WorkoutPlazaStrings.Home.Weekly.visits(weeklyVisits)
        climbingWeeklySentLabel.text = WorkoutPlazaStrings.Home.Weekly.sent(weeklySent)
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

        combinedRecentWorkouts.sort { $0.date > $1.date }

        // Show "더보기" only when 3+
        let hasMore = combinedRecentWorkouts.count > previewRecordCount
        recordsToggleButton.isHidden = !hasMore
        if hasMore {
            recordsToggleButton.setTitle(WorkoutPlazaStrings.Button.Show.more, for: .normal)
        }

        let previewWorkouts = Array(combinedRecentWorkouts.prefix(previewRecordCount))

        if combinedRecentWorkouts.isEmpty {
            let placeholderView = createPlaceholderView()
            recordsStackView.addArrangedSubview(placeholderView)
        } else {
            for (index, workout) in previewWorkouts.enumerated() {
                let recordView = createRecordView(for: workout, index: index)
                recordsStackView.addArrangedSubview(recordView)
                recordView.snp.makeConstraints { make in
                    make.height.equalTo(64)
                }
            }
        }
    }

    private func createPlaceholderView() -> UIView {
        let placeholder = UIView()
        placeholder.backgroundColor = ColorSystem.cardBackground
        placeholder.layer.cornerRadius = 20
        placeholder.layer.cornerCurve = .continuous

        let placeholderLabel = UILabel()
        placeholderLabel.text = WorkoutPlazaStrings.Home.No.records
        placeholderLabel.font = AppFont.bodySemiBold(14)
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
        containerView.layer.cornerRadius = 20
        containerView.layer.cornerCurve = .continuous

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: workout.sportType.iconName)
        iconImageView.tintColor = ColorSystem.controlTint
        iconImageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.font = AppFont.bodySemiBold(15)
        titleLabel.textColor = ColorSystem.mainText

        let subtitleLabel = UILabel()
        subtitleLabel.font = AppFont.body(13)
        subtitleLabel.textColor = ColorSystem.subText

        let dateLabel = UILabel()
        dateLabel.font = AppFont.body(12)
        dateLabel.textColor = ColorSystem.subText

        // Configure based on workout type
        switch workout.sportType {
        case .running:
            if let healthKitWorkout = workout.data as? WorkoutData {
                titleLabel.text = WorkoutPlazaStrings.Workout.running
                subtitleLabel.text = String(format: "%.1f km", healthKitWorkout.distance / 1000)
            } else if let externalWorkout = workout.data as? ExternalWorkout {
                titleLabel.text = WorkoutPlazaStrings.Workout.running
                subtitleLabel.text = String(format: "%.1f km", externalWorkout.workoutData.distance / 1000)
            }
        case .climbing:
            if let session = workout.data as? ClimbingData {
                let gymDisplayName = session.gymDisplayName
                titleLabel.text = gymDisplayName.isEmpty ? WorkoutPlazaStrings.Workout.climbing : gymDisplayName
                subtitleLabel.text = WorkoutPlazaStrings.Home.Weekly.routes(session.totalRoutes)
            }
        }

        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        dateLabel.text = formatter.string(from: workout.date)

        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(dateLabel)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(14)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }

        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(recordTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        containerView.tag = index

        return containerView
    }

    // MARK: - Actions

    @objc private func showAllRecords() {
        let sheetVC = RecentRecordsSheetViewController()
        sheetVC.workouts = combinedRecentWorkouts
        sheetVC.delegate = self
        sheetVC.modalPresentationStyle = .pageSheet
        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(sheetVC, animated: true)
    }

    @objc private func addWorkoutTapped() {
        let sportSelectorVC = SportSelectorSheetViewController()
        sportSelectorVC.delegate = self
        sportSelectorVC.modalPresentationStyle = .pageSheet
        if let sheet = sportSelectorVC.sheetPresentationController {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                return 240
            }
            sheet.detents = [customDetent]
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
                presentWorkoutDetail(detailVC)
            } else if let externalWorkout = workout.data as? ExternalWorkout {
                let detailVC = RunningDetailViewController()
                detailVC.externalWorkout = externalWorkout
                presentWorkoutDetail(detailVC)
            }
        case .climbing:
            if let session = workout.data as? ClimbingData {
                let detailVC = ClimbingDetailViewController()
                detailVC.climbingData = session
                presentWorkoutDetail(detailVC)
            }
        }
    }

    private func presentWorkoutDetail(_ detailViewController: UIViewController) {
        let nav = UINavigationController(rootViewController: detailViewController)
        if traitCollection.userInterfaceIdiom == .pad {
            nav.modalPresentationStyle = .fullScreen
        }
        present(nav, animated: true)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return WorkoutPlazaStrings.Home.Duration.hours(hours, minutes)
        } else {
            return WorkoutPlazaStrings.Home.Duration.minutes(minutes, seconds)
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

    func climbingInputDidRequestCardCreation(_ controller: ClimbingInputViewController, session: ClimbingData) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.showCardCreationAlert(for: session)
        }
    }

    private func showCardCreationAlert(for session: ClimbingData) {
        let alert = CustomAlertViewController(
            title: WorkoutPlazaStrings.Alert.Save.completed,
            message: WorkoutPlazaStrings.Home.Climbing.Saved.message,
            iconName: "icon.check.circle.fill",
            actions: [
                CustomAlertAction(title: WorkoutPlazaStrings.Home.Create.card, iconName: nil, style: .primary) { [weak self] in
                    guard let self = self else { return }
                    let detailVC = ClimbingDetailViewController()
                    detailVC.climbingData = session
                    self.presentWorkoutDetail(detailVC)
                },
                CustomAlertAction(title: WorkoutPlazaStrings.Home.later, iconName: nil, style: .cancel, handler: nil)
            ]
        )

        present(alert, animated: true)
    }
}

// MARK: - RecentRecordsSheetDelegate

extension HomeDashboardViewController: RecentRecordsSheetDelegate {
    func recentRecordsSheet(_ sheet: RecentRecordsSheetViewController, didSelectWorkoutAt index: Int) {
        guard index < combinedRecentWorkouts.count else { return }
        let workout = combinedRecentWorkouts[index]

        switch workout.sportType {
        case .running:
            if let healthKitWorkout = workout.data as? WorkoutData {
                let detailVC = RunningDetailViewController()
                detailVC.workoutData = healthKitWorkout
                presentWorkoutDetail(detailVC)
            } else if let externalWorkout = workout.data as? ExternalWorkout {
                let detailVC = RunningDetailViewController()
                detailVC.externalWorkout = externalWorkout
                presentWorkoutDetail(detailVC)
            }
        case .climbing:
            if let session = workout.data as? ClimbingData {
                let detailVC = ClimbingDetailViewController()
                detailVC.climbingData = session
                presentWorkoutDetail(detailVC)
            }
        }
    }

    func recentRecordsSheetDidDeleteRecord(_ sheet: RecentRecordsSheetViewController) {
        climbingSessions = ClimbingDataManager.shared.loadSessions()
        externalRunningWorkouts = ExternalWorkoutManager.shared.getAllWorkouts().filter { $0.workoutData.type == .running }
        updateWeeklySummary()
        updateRecentRecords()
    }
}
