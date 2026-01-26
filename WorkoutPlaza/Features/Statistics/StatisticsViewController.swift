//
//  StatisticsViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/23/26.
//

import UIKit
import SnapKit

class StatisticsViewController: UIViewController {

    // MARK: - Properties

    private var runningWorkouts: [WorkoutData] = []
    private var externalRunningWorkouts: [ExternalWorkout] = []
    private var climbingSessions: [ClimbingData] = []
    private var runningDates: Set<DateComponents> = []
    private var climbingDates: Set<DateComponents> = []
    private var selectedDate: DateComponents?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        return stack
    }()

    // 통계 요약 섹션
    private let statsSummaryContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var runningStatsCard = createMiniStatsCard(
        title: "러닝",
        icon: "figure.run",
        color: .systemBlue
    )

    private lazy var climbingStatsCard = createMiniStatsCard(
        title: "클라이밍",
        icon: "figure.climbing",
        color: .systemOrange
    )

    // 달력
    private let calendarView = UICalendarView()

    // 선택된 날짜의 운동 목록
    private let workoutListContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private let workoutListHeaderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let workoutListStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()

    private let emptyWorkoutLabel: UILabel = {
        let label = UILabel()
        label.text = "이 날짜에 운동 기록이 없습니다"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotificationObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "통계"

        // Scroll View
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        scrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalToSuperview().offset(-32)
        }

        // 통계 요약 카드
        statsSummaryContainer.addArrangedSubview(runningStatsCard)
        statsSummaryContainer.addArrangedSubview(climbingStatsCard)
        contentStackView.addArrangedSubview(statsSummaryContainer)
        statsSummaryContainer.snp.makeConstraints { make in
            make.height.equalTo(100)
        }

        // 범례
        let legendContainer = createLegendView()
        contentStackView.addArrangedSubview(legendContainer)

        // 달력
        setupCalendarView()
        contentStackView.addArrangedSubview(calendarView)

        // 운동 목록 컨테이너
        setupWorkoutListContainer()
        contentStackView.addArrangedSubview(workoutListContainer)
    }

    private func setupCalendarView() {
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale(identifier: "ko_KR")
        calendarView.fontDesign = .rounded
        calendarView.delegate = self
        calendarView.tintColor = .systemOrange
        calendarView.backgroundColor = .secondarySystemBackground
        calendarView.layer.cornerRadius = 16

        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
    }

    private func setupWorkoutListContainer() {
        workoutListContainer.addSubview(workoutListHeaderLabel)
        workoutListContainer.addSubview(workoutListStackView)
        workoutListContainer.addSubview(emptyWorkoutLabel)

        workoutListHeaderLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }

        workoutListStackView.snp.makeConstraints { make in
            make.top.equalTo(workoutListHeaderLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-16)
        }

        emptyWorkoutLabel.snp.makeConstraints { make in
            make.top.equalTo(workoutListHeaderLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }

        // 초기 상태: 오늘 날짜 선택
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        selectedDate = today
        updateWorkoutListHeader()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func handleAppDidBecomeActive() {
        refreshData()
    }

    // MARK: - Data Loading

    private func refreshData() {
        runningDates.removeAll()
        climbingDates.removeAll()

        loadClimbingData()
        loadRunningData()
    }

    private func loadClimbingData() {
        climbingSessions = ClimbingDataManager.shared.loadSessions()

        for session in climbingSessions {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: session.sessionDate)
            climbingDates.insert(components)
        }

        updateClimbingStatsCard()
        updateCalendarDecorations()
        updateWorkoutListForSelectedDate()
    }

    private func loadRunningData() {
        // 외부 임포트 러닝 기록 로드
        externalRunningWorkouts = ExternalWorkoutManager.shared.getAllWorkouts().filter { $0.workoutData.type == "러닝" }

        for workout in externalRunningWorkouts {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: workout.workoutData.startDate)
            runningDates.insert(components)
        }

        // HealthKit 러닝 기록 로드
        WorkoutManager.shared.fetchWorkouts { [weak self] workouts in
            guard let self = self else { return }

            self.runningWorkouts = workouts.filter { $0.workoutType == "러닝" }

            for workout in self.runningWorkouts {
                let components = Calendar.current.dateComponents([.year, .month, .day], from: workout.startDate)
                self.runningDates.insert(components)
            }

            self.updateRunningStatsCard()
            self.updateCalendarDecorations()
            self.updateWorkoutListForSelectedDate()
        }
    }

    private func updateCalendarDecorations() {
        var allDates = runningDates.union(climbingDates)
        calendarView.reloadDecorations(forDateComponents: Array(allDates), animated: true)
    }

    // MARK: - Stats Cards

    private func createMiniStatsCard(title: String, icon: String, color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = color.withAlphaComponent(0.1)
        card.layer.cornerRadius = 16

        let iconView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        iconView.image = UIImage(systemName: icon, withConfiguration: config)
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabel

        let countLabel = UILabel()
        countLabel.font = .systemFont(ofSize: 22, weight: .bold)
        countLabel.textColor = color
        countLabel.text = "0회"
        countLabel.tag = 100 // Tag for updating

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textColor = .tertiaryLabel
        subtitleLabel.text = ""
        subtitleLabel.tag = 101 // Tag for updating

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(countLabel)
        card.addSubview(subtitleLabel)

        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(8)
        }

        countLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(countLabel.snp.trailing).offset(6)
            make.bottom.equalTo(countLabel).offset(-2)
        }

        return card
    }

    private func updateRunningStatsCard() {
        guard let countLabel = runningStatsCard.viewWithTag(100) as? UILabel,
              let subtitleLabel = runningStatsCard.viewWithTag(101) as? UILabel else { return }

        let healthKitCount = runningWorkouts.count
        let externalCount = externalRunningWorkouts.count
        let totalCount = healthKitCount + externalCount

        let healthKitDistance = runningWorkouts.reduce(0) { $0 + $1.distance }
        let externalDistance = externalRunningWorkouts.reduce(0) { $0 + $1.workoutData.distance }
        let totalDistance = healthKitDistance + externalDistance

        countLabel.text = "\(totalCount)회"
        subtitleLabel.text = String(format: "%.1fkm", totalDistance / 1000)
    }

    private func updateClimbingStatsCard() {
        guard let countLabel = climbingStatsCard.viewWithTag(100) as? UILabel,
              let subtitleLabel = climbingStatsCard.viewWithTag(101) as? UILabel else { return }

        let count = climbingSessions.count
        let totalRoutes = climbingSessions.reduce(0) { $0 + $1.totalRoutes }

        countLabel.text = "\(count)회"
        subtitleLabel.text = "\(totalRoutes)루트"
    }

    // MARK: - Legend View

    private func createLegendView() -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 20
        container.alignment = .center
        container.distribution = .equalCentering

        // Running legend
        let runningLegend = createLegendItem(color: .systemBlue, text: "러닝")
        container.addArrangedSubview(runningLegend)

        // Climbing legend
        let climbingLegend = createLegendItem(color: .systemOrange, text: "클라이밍")
        container.addArrangedSubview(climbingLegend)

        // Both legend
        let bothLegend = createLegendItem(colors: [.systemBlue, .systemOrange], text: "둘 다")
        container.addArrangedSubview(bothLegend)

        let wrapperView = UIView()
        wrapperView.addSubview(container)
        container.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(8)
        }

        return wrapperView
    }

    private func createLegendItem(color: UIColor, text: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center

        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 5
        dot.snp.makeConstraints { make in
            make.width.height.equalTo(10)
        }

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel

        stack.addArrangedSubview(dot)
        stack.addArrangedSubview(label)

        return stack
    }

    private func createLegendItem(colors: [UIColor], text: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center

        // Split dot
        let dotContainer = UIView()
        dotContainer.layer.cornerRadius = 5
        dotContainer.clipsToBounds = true
        dotContainer.snp.makeConstraints { make in
            make.width.height.equalTo(10)
        }

        let leftHalf = UIView()
        leftHalf.backgroundColor = colors[0]
        dotContainer.addSubview(leftHalf)
        leftHalf.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }

        let rightHalf = UIView()
        rightHalf.backgroundColor = colors[1]
        dotContainer.addSubview(rightHalf)
        rightHalf.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel

        stack.addArrangedSubview(dotContainer)
        stack.addArrangedSubview(label)

        return stack
    }

    // MARK: - Workout List

    private func updateWorkoutListHeader() {
        guard let date = selectedDate,
              let year = date.year,
              let month = date.month,
              let day = date.day else {
            workoutListHeaderLabel.text = "운동 기록"
            return
        }

        workoutListHeaderLabel.text = "\(month)월 \(day)일 운동 기록"
    }

    private func updateWorkoutListForSelectedDate() {
        // Clear existing cells
        workoutListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let selectedDate = selectedDate,
              let year = selectedDate.year,
              let month = selectedDate.month,
              let day = selectedDate.day else {
            showEmptyState()
            return
        }
        
        // Create normalized components for comparison
        var targetComponents = DateComponents()
        targetComponents.year = year
        targetComponents.month = month
        targetComponents.day = day

        var workoutsForDate: [(type: SportType, view: UIView)] = []

        // Get HealthKit running workouts for selected date
        for workout in runningWorkouts {
            let workoutDate = Calendar.current.dateComponents([.year, .month, .day], from: workout.startDate)
            if workoutDate.year == year && workoutDate.month == month && workoutDate.day == day {
                let cell = createRunningWorkoutCell(workout: workout)
                workoutsForDate.append((.running, cell))
            }
        }

        // Get external running workouts for selected date
        for workout in externalRunningWorkouts {
            let workoutDate = Calendar.current.dateComponents([.year, .month, .day], from: workout.workoutData.startDate)
            if workoutDate.year == year && workoutDate.month == month && workoutDate.day == day {
                let cell = createExternalRunningWorkoutCell(workout: workout)
                workoutsForDate.append((.running, cell))
            }
        }

        // Get climbing sessions for selected date
        for session in climbingSessions {
            let sessionDate = Calendar.current.dateComponents([.year, .month, .day], from: session.sessionDate)
            if sessionDate.year == year && sessionDate.month == month && sessionDate.day == day {
                let cell = createClimbingWorkoutCell(session: session)
                workoutsForDate.append((.climbing, cell))
            }
        }

        if workoutsForDate.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
            for (_, cellView) in workoutsForDate {
                workoutListStackView.addArrangedSubview(cellView)
            }
        }
    }

    private func showEmptyState() {
        emptyWorkoutLabel.isHidden = false
        workoutListStackView.isHidden = true
    }

    private func hideEmptyState() {
        emptyWorkoutLabel.isHidden = true
        workoutListStackView.isHidden = false
    }

    // MARK: - Workout Cells

    private func createRunningWorkoutCell(workout: WorkoutData) -> UIView {
        let cell = UIView()
        cell.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        cell.layer.cornerRadius = 12

        let iconView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image = UIImage(systemName: "figure.run", withConfiguration: config)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = workout.workoutType
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label

        let timeLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: workout.startDate)
        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = .secondaryLabel

        let distanceLabel = UILabel()
        distanceLabel.text = String(format: "%.2f km", workout.distance / 1000)
        distanceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        distanceLabel.textColor = .systemBlue

        let durationLabel = UILabel()
        let minutes = Int(workout.duration) / 60
        durationLabel.text = "\(minutes)분"
        durationLabel.font = .systemFont(ofSize: 13)
        durationLabel.textColor = .secondaryLabel

        let paceLabel = UILabel()
        if workout.distance > 0 {
            let pace = (workout.duration / 60) / (workout.distance / 1000)
            let paceMin = Int(pace)
            let paceSec = Int((pace - Double(paceMin)) * 60)
            paceLabel.text = String(format: "%d'%02d\"/km", paceMin, paceSec)
        } else {
            paceLabel.text = "-"
        }
        paceLabel.font = .systemFont(ofSize: 12)
        paceLabel.textColor = .tertiaryLabel

        cell.addSubview(iconView)
        cell.addSubview(titleLabel)
        cell.addSubview(timeLabel)
        cell.addSubview(distanceLabel)
        cell.addSubview(durationLabel)
        cell.addSubview(paceLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }

        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }

        distanceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }

        durationLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        paceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(durationLabel)
            make.trailing.equalToSuperview().offset(-12)
        }

        cell.snp.makeConstraints { make in
            make.height.equalTo(70)
        }

        return cell
    }

    private func createExternalRunningWorkoutCell(workout: ExternalWorkout) -> UIView {
        let cell = UIView()
        cell.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        cell.layer.cornerRadius = 12

        let iconView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image = UIImage(systemName: "figure.run", withConfiguration: config)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = workout.workoutData.type
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label

        let timeLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: workout.workoutData.startDate)
        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = .secondaryLabel

        let externalBadge = UILabel()
        externalBadge.text = "외부"
        externalBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        externalBadge.textColor = .white
        externalBadge.backgroundColor = .systemOrange
        externalBadge.textAlignment = .center
        externalBadge.layer.cornerRadius = 4
        externalBadge.clipsToBounds = true

        let distanceLabel = UILabel()
        distanceLabel.text = String(format: "%.2f km", workout.workoutData.distance / 1000)
        distanceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        distanceLabel.textColor = .systemBlue

        let durationLabel = UILabel()
        let minutes = Int(workout.workoutData.duration) / 60
        durationLabel.text = "\(minutes)분"
        durationLabel.font = .systemFont(ofSize: 13)
        durationLabel.textColor = .secondaryLabel

        let paceLabel = UILabel()
        if workout.workoutData.distance > 0 {
            let pace = (workout.workoutData.duration / 60) / (workout.workoutData.distance / 1000)
            let paceMin = Int(pace)
            let paceSec = Int((pace - Double(paceMin)) * 60)
            paceLabel.text = String(format: "%d'%02d\"/km", paceMin, paceSec)
        } else {
            paceLabel.text = "-"
        }
        paceLabel.font = .systemFont(ofSize: 12)
        paceLabel.textColor = .tertiaryLabel

        cell.addSubview(iconView)
        cell.addSubview(titleLabel)
        cell.addSubview(timeLabel)
        cell.addSubview(externalBadge)
        cell.addSubview(distanceLabel)
        cell.addSubview(durationLabel)
        cell.addSubview(paceLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }

        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }

        externalBadge.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(timeLabel.snp.trailing).offset(8)
            make.width.equalTo(30)
            make.height.equalTo(16)
        }

        distanceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }

        durationLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        paceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(durationLabel)
            make.trailing.equalToSuperview().offset(-12)
        }

        cell.snp.makeConstraints { make in
            make.height.equalTo(70)
        }

        return cell
    }

    private func createClimbingWorkoutCell(session: ClimbingData) -> UIView {
        let cell = ClimbingSessionCell()
        cell.configure(with: session)
        cell.onTap = { [weak self] in
            self?.openClimbingDetail(session: session)
        }
        return cell
    }

    private func openClimbingDetail(session: ClimbingData) {
        let detailVC = ClimbingDetailViewController(climbingData: session)
        let navVC = UINavigationController(rootViewController: detailVC)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
}

// MARK: - ClimbingSessionCell

private class ClimbingSessionCell: UIView {
    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let disciplineLabel = UILabel()
    private let routesLabel = UILabel()
    private let gradeLabel = UILabel()
    private let chevronView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .systemOrange.withAlphaComponent(0.1)
        layer.cornerRadius = 12

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image = UIImage(systemName: "figure.climbing", withConfiguration: config)
        iconView.tintColor = .systemOrange
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label

        disciplineLabel.font = .systemFont(ofSize: 13)
        disciplineLabel.textColor = .secondaryLabel

        routesLabel.font = .systemFont(ofSize: 14, weight: .medium)
        routesLabel.textColor = .systemOrange

        gradeLabel.font = .systemFont(ofSize: 12)
        gradeLabel.textColor = .tertiaryLabel

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        chevronView.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevronView.tintColor = .tertiaryLabel
        chevronView.contentMode = .scaleAspectFit

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(disciplineLabel)
        addSubview(routesLabel)
        addSubview(gradeLabel)
        addSubview(chevronView)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }

        disciplineLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }

        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        routesLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(chevronView.snp.leading).offset(-8)
        }

        gradeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        snp.makeConstraints { make in
            make.height.equalTo(70)
        }

        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    func configure(with session: ClimbingData) {
        titleLabel.text = session.gymName
        disciplineLabel.text = session.discipline.displayName
        routesLabel.text = "\(session.sentRoutes)/\(session.totalRoutes) 완등"
        if let highestGrade = session.highestGradeSent {
            gradeLabel.text = "최고: \(highestGrade)"
        } else {
            gradeLabel.text = ""
        }
    }

    @objc private func handleTap() {
        // Highlight effect
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.alpha = 1.0
            }
        }
        onTap?()
    }
}

// MARK: - UICalendarViewDelegate

extension StatisticsViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        // Normalize the date components to match how we store them (only year, month, day)
        var queryComponents = DateComponents()
        queryComponents.year = dateComponents.year
        queryComponents.month = dateComponents.month
        queryComponents.day = dateComponents.day
        
        let hasRunning = runningDates.contains(queryComponents)
        let hasClimbing = climbingDates.contains(queryComponents)

        if hasRunning && hasClimbing {
            // 둘 다 있으면 커스텀 뷰 (반반 색상)
            return .customView {
                let container = UIView()

                let leftDot = UIView()
                leftDot.backgroundColor = .systemBlue
                leftDot.layer.cornerRadius = 4

                let rightDot = UIView()
                rightDot.backgroundColor = .systemOrange
                rightDot.layer.cornerRadius = 4

                container.addSubview(leftDot)
                container.addSubview(rightDot)

                leftDot.snp.makeConstraints { make in
                    make.leading.centerY.equalToSuperview()
                    make.width.height.equalTo(8)
                }

                rightDot.snp.makeConstraints { make in
                    make.leading.equalTo(leftDot.snp.trailing).offset(2)
                    make.trailing.centerY.equalToSuperview()
                    make.width.height.equalTo(8)
                }

                return container
            }
        } else if hasRunning {
            return .default(color: .systemBlue, size: .medium)
        } else if hasClimbing {
            return .default(color: .systemOrange, size: .medium)
        }

        return nil
    }
}

// MARK: - UICalendarSelectionSingleDateDelegate

extension StatisticsViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selectedDate = dateComponents
        updateWorkoutListHeader()
        updateWorkoutListForSelectedDate()
    }
}
