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
    
    // 날짜별 운동 타입 저장 (확장 가능한 구조)
    private var workoutsByDate: [DateComponents: Set<WorkoutType>] = [:]
    
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
    
    private lazy var runningStatsCard = StatsSummaryCard(
        title: "러닝",
        icon: "figure.run",
        color: .systemBlue
    )
    
    private lazy var climbingStatsCard = StatsSummaryCard(
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
        let legendContainer = WorkoutLegendView()
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
        // workoutsByDate 업데이트
        workoutsByDate.removeAll()
        for date in runningDates {
            workoutsByDate[date, default: []].insert(.running)
        }
        for date in climbingDates {
            workoutsByDate[date, default: []].insert(.climbing)
        }
        
        let allDates = runningDates.union(climbingDates)
        calendarView.reloadDecorations(forDateComponents: Array(allDates), animated: true)
    }
    
    // MARK: - UI Updates
    
    private func updateRunningStatsCard() {
        let healthKitCount = runningWorkouts.count
        let externalCount = externalRunningWorkouts.count
        let totalCount = healthKitCount + externalCount
        
        let healthKitDistance = runningWorkouts.reduce(0) { $0 + $1.distance }
        let externalDistance = externalRunningWorkouts.reduce(0) { $0 + $1.workoutData.distance }
        let totalDistance = healthKitDistance + externalDistance
        
        runningStatsCard.update(
            count: "\(totalCount)회",
            subtitle: String(format: "%.1fkm", totalDistance / 1000)
        )
    }
    
    private func updateClimbingStatsCard() {
        let count = climbingSessions.count
        let totalRoutes = climbingSessions.reduce(0) { $0 + $1.totalRoutes }
        
        climbingStatsCard.update(
            count: "\(count)회",
            subtitle: "\(totalRoutes)루트"
        )
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
        
        guard let selectedDate = self.selectedDate,
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
    
    // MARK: - Workout Cells Helpers
    
    private func createRunningWorkoutCell(workout: WorkoutData) -> UIView {
        let cell = RunningWorkoutCell()
        cell.configure(with: workout)
        cell.onTap = { [weak self] in
            self?.openRunningDetail(workout: workout)
        }
        return cell
    }
    
    private func openRunningDetail(workout: WorkoutData) {
        let detailVC = RunningDetailViewController()
        detailVC.workoutData = workout
        let navVC = UINavigationController(rootViewController: detailVC)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
    
    private func createExternalRunningWorkoutCell(workout: ExternalWorkout) -> UIView {
        let cell = ExternalRunningWorkoutCell()
        cell.configure(with: workout)
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
        let detailVC = ClimbingDetailViewController()
        detailVC.climbingData = session
        let navVC = UINavigationController(rootViewController: detailVC)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
}

// MARK: - UICalendarViewDelegate

extension StatisticsViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        // Calendar.current.dateComponents를 사용해서 저장된 것과 동일한 형식으로 생성
        guard let date = Calendar.current.date(from: dateComponents) else {
            return nil
        }
        let queryComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        
        guard let workoutTypes = workoutsByDate[queryComponents], !workoutTypes.isEmpty else {
            return nil
        }
        
        // 운동 타입을 displayOrder로 정렬
        let sortedTypes = workoutTypes.sorted { $0.displayOrder < $1.displayOrder }
        let typeCount = sortedTypes.count
        
        if typeCount == 1 {
            // 1개 운동: 해당 색상 도트
            return .default(color: sortedTypes[0].color, size: .medium)
        } else {
            // 2개 이상 운동: 커스텀 뷰
            let label = UILabel()
            label.textAlignment = .center
            
            let combinedString = NSMutableAttributedString()
            
            // 최대 2개의 도트 표시
            for i in 0..<min(typeCount, 2) {
                // Add spacing if not first
                if i > 0 {
                    combinedString.append(NSAttributedString(string: " "))
                }
                
                let dotString = NSAttributedString(
                    string: "●",
                    attributes: [
                        .foregroundColor: sortedTypes[i].color,
                        .font: UIFont.systemFont(ofSize: 10)
                    ]
                )
                combinedString.append(dotString)
            }
            
            if typeCount > 2 {
                // 3개 이상 운동: '+' 심볼 추가
                combinedString.append(NSAttributedString(string: " "))
                let plusString = NSAttributedString(
                    string: "+",
                    attributes: [
                        .foregroundColor: UIColor.secondaryLabel,
                        .font: UIFont.systemFont(ofSize: 10, weight: .bold)
                    ]
                )
                combinedString.append(plusString)
            }
            
            label.attributedText = combinedString
            return .customView { label }
        }
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
