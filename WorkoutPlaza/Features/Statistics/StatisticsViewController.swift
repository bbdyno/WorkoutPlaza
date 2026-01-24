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

    private var selectedSegmentIndex: Int = 0

    // MARK: - UI Components

    private let segmentedControl: UISegmentedControl = {
        let items = ["달력", "러닝", "클라이밍"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .systemOrange
        return control
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // Child View Controllers
    private lazy var calendarVC = CalendarStatsViewController()
    private lazy var runningStatsVC = RunningStatsViewController()
    private lazy var climbingStatsVC = ClimbingStatsViewController()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showChildVC(at: 0)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "통계"

        // Segmented Control
        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(36)
        }
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        // Container View
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Child View Controller Management

    private func showChildVC(at index: Int) {
        // Remove current child
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        // Add new child
        let childVC: UIViewController
        switch index {
        case 0:
            childVC = calendarVC
        case 1:
            childVC = runningStatsVC
        case 2:
            childVC = climbingStatsVC
        default:
            return
        }

        addChild(childVC)
        containerView.addSubview(childVC.view)
        childVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        childVC.didMove(toParent: self)
    }

    // MARK: - Actions

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        showChildVC(at: sender.selectedSegmentIndex)
    }
}

// MARK: - Calendar Stats View Controller

class CalendarStatsViewController: UIViewController {

    private let calendarView = UICalendarView()
    private var workoutDates: Set<DateComponents> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadWorkoutDates()
        setupNotificationObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    private func refreshData() {
        workoutDates.removeAll()
        loadWorkoutDates()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        calendarView.calendar = Calendar.current
        calendarView.locale = Locale(identifier: "ko_KR")
        calendarView.fontDesign = .rounded
        calendarView.delegate = self
        calendarView.tintColor = .systemOrange

        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection

        view.addSubview(calendarView)
        calendarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(400)
        }
    }

    private func loadWorkoutDates() {
        // Load climbing workout dates first (synchronous)
        let climbingSessions = ClimbingDataManager.shared.loadSessions()
        for session in climbingSessions {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: session.sessionDate)
            workoutDates.insert(components)
        }

        // Load running workout dates (asynchronous from HealthKit, GPS 유무와 관계없이)
        WorkoutManager.shared.fetchWorkouts { [weak self] workouts in
            guard let self = self else { return }
            for workout in workouts {
                let components = Calendar.current.dateComponents([.year, .month, .day], from: workout.startDate)
                self.workoutDates.insert(components)
            }
            self.calendarView.reloadDecorations(forDateComponents: Array(self.workoutDates), animated: true)
        }

        // Initial reload with climbing data
        calendarView.reloadDecorations(forDateComponents: Array(workoutDates), animated: true)
    }
}

extension CalendarStatsViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        if workoutDates.contains(dateComponents) {
            return .default(color: .systemOrange, size: .medium)
        }
        return nil
    }
}

extension CalendarStatsViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        // TODO: Show workouts for selected date
    }
}

// MARK: - Running Stats View Controller

class RunningStatsViewController: UIViewController {

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStats()
        setupNotificationObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    private func refreshData() {
        // Clear existing stats
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        loadStats()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }
    }

    private var loadingLabel: UILabel?

    private func loadStats() {
        // Show loading state
        let loading = UILabel()
        loading.text = "데이터 로딩 중..."
        loading.font = .systemFont(ofSize: 16)
        loading.textColor = .secondaryLabel
        loading.textAlignment = .center
        stackView.addArrangedSubview(loading)
        loadingLabel = loading

        // Fetch workouts from HealthKit (async, GPS 유무와 관계없이)
        WorkoutManager.shared.fetchWorkouts { [weak self] workouts in
            guard let self = self else { return }

            // Remove loading label
            self.loadingLabel?.removeFromSuperview()

            // Total stats
            let totalDistance = workouts.reduce(0) { $0 + $1.distance }
            let totalDuration = workouts.reduce(0) { $0 + $1.duration }
            let totalCalories = workouts.reduce(0) { $0 + Int($1.calories) }
            let totalCount = workouts.count

            // Summary Card
            let summaryCard = self.createStatsCard(
                title: "러닝 요약",
                items: [
                    ("총 거리", String(format: "%.2f km", totalDistance / 1000)),
                    ("총 시간", self.formatDuration(totalDuration)),
                    ("총 칼로리", "\(totalCalories) kcal"),
                    ("총 기록", "\(totalCount)회")
                ],
                color: .systemBlue
            )
            self.stackView.addArrangedSubview(summaryCard)

            // Average Card
            if totalCount > 0 && totalDistance > 0 {
                let avgDistance = totalDistance / Double(totalCount)
                let avgDuration = totalDuration / Double(totalCount)
                let avgPace = totalDuration / (totalDistance / 1000) / 60

                let avgCard = self.createStatsCard(
                    title: "평균 기록",
                    items: [
                        ("평균 거리", String(format: "%.2f km", avgDistance / 1000)),
                        ("평균 시간", self.formatDuration(avgDuration)),
                        ("평균 페이스", String(format: "%.1f 분/km", avgPace))
                    ],
                    color: .systemGreen
                )
                self.stackView.addArrangedSubview(avgCard)
            }

            // Empty state
            if totalCount == 0 {
                let emptyLabel = UILabel()
                emptyLabel.text = "러닝 기록이 없습니다"
                emptyLabel.font = .systemFont(ofSize: 16)
                emptyLabel.textColor = .secondaryLabel
                emptyLabel.textAlignment = .center
                self.stackView.addArrangedSubview(emptyLabel)
            }
        }
    }

    private func createStatsCard(title: String, items: [(String, String)], color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = color.withAlphaComponent(0.1)
        card.layer.cornerRadius = 16

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = color

        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }

        var lastView: UIView = titleLabel

        for (label, value) in items {
            let itemView = createStatItem(label: label, value: value)
            card.addSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.top.equalTo(lastView.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(16)
            }
            lastView = itemView
        }

        lastView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
        }

        return card
    }

    private func createStatItem(label: String, value: String) -> UIView {
        let container = UIView()

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 14)
        labelView.textColor = .secondaryLabel

        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 16, weight: .semibold)
        valueView.textColor = .label

        container.addSubview(labelView)
        container.addSubview(valueView)

        labelView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        valueView.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
        }

        return container
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }
        return "\(minutes)분"
    }
}

// MARK: - Climbing Stats View Controller

class ClimbingStatsViewController: UIViewController {

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStats()
        setupNotificationObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    private func refreshData() {
        // Clear existing stats
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        loadStats()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }
    }

    private func loadStats() {
        let sessions = ClimbingDataManager.shared.loadSessions()

        // Total stats
        let totalSessions = sessions.count
        let totalRoutes = sessions.reduce(0) { $0 + $1.totalRoutes }
        let totalSent = sessions.reduce(0) { $0 + $1.sentRoutes }
        let overallSuccessRate = totalRoutes > 0 ? Double(totalSent) / Double(totalRoutes) * 100 : 0

        // Highest grade
        let allGrades = sessions.compactMap { $0.highestGradeSent }
        let highestGrade = allGrades.max() ?? "-"

        // Summary Card
        let summaryCard = createStatsCard(
            title: "클라이밍 요약",
            items: [
                ("총 세션", "\(totalSessions)회"),
                ("총 루트", "\(totalRoutes)개"),
                ("완등 루트", "\(totalSent)개"),
                ("완등률", String(format: "%.1f%%", overallSuccessRate)),
                ("최고 난이도", highestGrade)
            ],
            color: .systemOrange
        )
        stackView.addArrangedSubview(summaryCard)

        // By Discipline
        let boulderingSessions = sessions.filter { $0.discipline == .bouldering }
        let leadSessions = sessions.filter { $0.discipline == .leadEndurance }

        if !boulderingSessions.isEmpty {
            let boulderingCard = createStatsCard(
                title: "볼더링",
                items: [
                    ("세션", "\(boulderingSessions.count)회"),
                    ("총 문제", "\(boulderingSessions.reduce(0) { $0 + $1.totalRoutes })개"),
                    ("완등", "\(boulderingSessions.reduce(0) { $0 + $1.sentRoutes })개"),
                    ("총 시도", "\(boulderingSessions.reduce(0) { $0 + $1.totalAttempts })회")
                ],
                color: .systemPurple
            )
            stackView.addArrangedSubview(boulderingCard)
        }

        if !leadSessions.isEmpty {
            let leadCard = createStatsCard(
                title: "리드/지구력",
                items: [
                    ("세션", "\(leadSessions.count)회"),
                    ("총 루트", "\(leadSessions.reduce(0) { $0 + $1.totalRoutes })개"),
                    ("완등", "\(leadSessions.reduce(0) { $0 + $1.sentRoutes })개"),
                    ("총 테이크", "\(leadSessions.reduce(0) { $0 + $1.totalTakes })회")
                ],
                color: .systemTeal
            )
            stackView.addArrangedSubview(leadCard)
        }

        // Empty state
        if totalSessions == 0 {
            let emptyLabel = UILabel()
            emptyLabel.text = "클라이밍 기록이 없습니다"
            emptyLabel.font = .systemFont(ofSize: 16)
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.textAlignment = .center
            stackView.addArrangedSubview(emptyLabel)
        }
    }

    private func createStatsCard(title: String, items: [(String, String)], color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = color.withAlphaComponent(0.1)
        card.layer.cornerRadius = 16

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = color

        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }

        var lastView: UIView = titleLabel

        for (label, value) in items {
            let itemView = createStatItem(label: label, value: value)
            card.addSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.top.equalTo(lastView.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(16)
            }
            lastView = itemView
        }

        lastView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
        }

        return card
    }

    private func createStatItem(label: String, value: String) -> UIView {
        let container = UIView()

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 14)
        labelView.textColor = .secondaryLabel

        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 16, weight: .semibold)
        valueView.textColor = .label

        container.addSubview(labelView)
        container.addSubview(valueView)

        labelView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        valueView.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
        }

        return container
    }
}
