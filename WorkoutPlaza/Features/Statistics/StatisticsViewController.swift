//
//  StatisticsViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/23/26.
//

import UIKit
import SnapKit

enum StatPeriod: Int, CaseIterable {
    case month = 0
    case year = 1
    case all = 2

    var displayName: String {
        switch self {
        case .month: return "월"
        case .year: return "년"
        case .all: return "전체"
        }
    }
}

enum StatSportType: Int, CaseIterable {
    case running = 0
    case climbing = 1

    var displayName: String {
        switch self {
        case .running: return "러닝"
        case .climbing: return "클라이밍"
        }
    }

    var sportType: SportType {
        switch self {
        case .running: return .running
        case .climbing: return .climbing
        }
    }
}

// MARK: - Stats Summary Item

struct StatsSummaryItem {
    let title: String
    let value: String
    let icon: String
    let color: UIColor
}

class StatisticsViewController: UIViewController {

    // MARK: - Properties

    private var currentPeriod: StatPeriod = .month
    private var currentSport: StatSportType = .running
    private var currentPeriodOffset: Int = 0

    // Period selection: for month/year picker
    private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    private var selectedMonth: Int = Calendar.current.component(.month, from: Date())

    private var runningWorkouts: [WorkoutData] = []
    private var externalRunningWorkouts: [ExternalWorkout] = []
    private var climbingSessions: [ClimbingData] = []

    // Calendar Data
    private var runningDates: Set<DateComponents> = []
    private var climbingDates: Set<DateComponents> = []
    private var workoutsByDate: [DateComponents: Set<WorkoutType>] = [:]
    private var selectedDate: DateComponents?

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = createCompositionalLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = ColorSystem.background
        cv.delegate = self
        cv.dataSource = self
        cv.register(RunningStatsCell.self, forCellWithReuseIdentifier: RunningStatsCell.identifier)
        cv.register(ClimbingStatsCell.self, forCellWithReuseIdentifier: ClimbingStatsCell.identifier)
        cv.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
        cv.register(RecentSessionCell.self, forCellWithReuseIdentifier: RecentSessionCell.identifier)
        cv.register(CalendarHeaderCell.self, forCellWithReuseIdentifier: CalendarHeaderCell.identifier)
        cv.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        return cv
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
        view.backgroundColor = ColorSystem.background
        navigationController?.navigationBar.prefersLargeTitles = false
        title = "통계"

        view.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func createCompositionalLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            return self.createUnifiedLayout(for: sectionIndex)
        }
    }

    // Layout Structure:
    // === PART 1: Sport-specific Stats ===
    // Section 0: Running or Climbing Stats (one big cell with everything)
    // === PART 2: Unified Calendar ===
    // Section 1: Calendar Header
    // Section 2: Calendar
    // Section 3: Selected date workouts

    private func createUnifiedLayout(for sectionIndex: Int) -> NSCollectionLayoutSection? {
        switch sectionIndex {
        case 0:
            // Running or Climbing Stats - estimated height for dynamic content
            if currentSport == .running {
                return createSingleItemSection(height: 500, insets: NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16), estimated: true)
            } else {
                return createSingleItemSection(height: 450, insets: NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16), estimated: true)
            }
        case 1:
            // Calendar Header
            return createSingleItemSection(height: 50, insets: NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
        case 2:
            // Calendar (unified)
            return createSingleItemSection(height: 400, insets: NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16), estimated: true)
        case 3:
            // Selected date workouts (unified)
            return createRecentSessionsSection()
        default:
            return nil
        }
    }

    private func createSingleItemSection(height: CGFloat, insets: NSDirectionalEdgeInsets, estimated: Bool = false) -> NSCollectionLayoutSection {
        let heightDimension: NSCollectionLayoutDimension = estimated ? .estimated(height) : .absolute(height)
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: heightDimension)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: heightDimension)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = insets
        return section
    }

    private func createRecentSessionsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 12

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]

        return section
    }

    // Called from cells
    func handleSportChanged(_ sport: StatSportType) {
        currentSport = sport
        collectionView.setCollectionViewLayout(createCompositionalLayout(), animated: false)
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    func handlePeriodChanged(_ period: StatPeriod) {
        currentPeriod = period
        // Reset to current date when period changes
        selectedYear = Calendar.current.component(.year, from: Date())
        selectedMonth = Calendar.current.component(.month, from: Date())
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    func handleDateSelected(year: Int, month: Int?) {
        selectedYear = year
        if let month = month {
            selectedMonth = month
        }
        collectionView.reloadSections(IndexSet(integer: 0))
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
        // Reset Date Data
        runningDates.removeAll()
        climbingDates.removeAll()
        workoutsByDate.removeAll()

        // Load Data
        let sessions = ClimbingDataManager.shared.loadSessions()
        climbingSessions = sessions.sorted(by: { $0.sessionDate > $1.sessionDate })

        for session in climbingSessions {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: session.sessionDate)
            climbingDates.insert(components)
            workoutsByDate[components, default: []].insert(.climbing)
        }

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        WorkoutManager.shared.fetchWorkouts { [weak self] workouts in
            guard let self = self else { return }
            self.runningWorkouts = workouts.filter { $0.workoutType == "러닝" }

            for workout in self.runningWorkouts {
                let components = Calendar.current.dateComponents([.year, .month, .day], from: workout.startDate)
                self.runningDates.insert(components)
                self.workoutsByDate[components, default: []].insert(.running)
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        externalRunningWorkouts = ExternalWorkoutManager.shared.getAllWorkouts().filter { $0.workoutData.type == "러닝" }
        for workout in externalRunningWorkouts {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: workout.workoutData.startDate)
            runningDates.insert(components)
            workoutsByDate[components, default: []].insert(.running)
        }
        dispatchGroup.leave()

        dispatchGroup.notify(queue: .main) { [weak self] in
            if self?.selectedDate == nil {
                self?.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            }
            self?.collectionView.reloadData()
        }
    }

    // MARK: - Date Range Calculation

    private func getSelectedDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch currentPeriod {
        case .month:
            var components = DateComponents()
            components.year = selectedYear
            components.month = selectedMonth
            components.day = 1
            guard let monthStart = calendar.date(from: components),
                  let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart),
                  let monthEnd = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
                return (now, now)
            }
            return (monthStart, monthEnd)

        case .year:
            var components = DateComponents()
            components.year = selectedYear
            components.month = 1
            components.day = 1
            guard let yearStart = calendar.date(from: components),
                  let nextYear = calendar.date(byAdding: .year, value: 1, to: yearStart),
                  let yearEnd = calendar.date(byAdding: .day, value: -1, to: nextYear) else {
                return (now, now)
            }
            return (yearStart, yearEnd)

        case .all:
            // All time - from earliest workout to now
            var earliestDate = now
            for workout in runningWorkouts {
                if workout.startDate < earliestDate { earliestDate = workout.startDate }
            }
            for workout in externalRunningWorkouts {
                if workout.workoutData.startDate < earliestDate { earliestDate = workout.workoutData.startDate }
            }
            return (earliestDate, now)
        }
    }

    private func getDateRange(for period: StatPeriod, offset: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .month:
            guard let offsetDate = calendar.date(byAdding: .month, value: offset, to: now),
                  let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: offsetDate)),
                  let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart),
                  let monthEnd = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
                return (now, now)
            }
            return (monthStart, monthEnd)

        case .year:
            guard let offsetDate = calendar.date(byAdding: .year, value: offset, to: now),
                  let yearStart = calendar.date(from: calendar.dateComponents([.year], from: offsetDate)),
                  let nextYear = calendar.date(byAdding: .year, value: 1, to: yearStart),
                  let yearEnd = calendar.date(byAdding: .day, value: -1, to: nextYear) else {
                return (now, now)
            }
            return (yearStart, yearEnd)

        case .all:
            var earliestDate = now
            for workout in runningWorkouts {
                if workout.startDate < earliestDate { earliestDate = workout.startDate }
            }
            for workout in externalRunningWorkouts {
                if workout.workoutData.startDate < earliestDate { earliestDate = workout.workoutData.startDate }
            }
            for session in climbingSessions {
                if session.sessionDate < earliestDate { earliestDate = session.sessionDate }
            }
            return (earliestDate, now)
        }
    }

    private func handlePrevPeriod() {
        currentPeriodOffset -= 1
        updateSelectedYearMonth()
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    private func handleNextPeriod() {
        guard currentPeriodOffset < 0 else { return }
        currentPeriodOffset += 1
        updateSelectedYearMonth()
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    private func updateSelectedYearMonth() {
        let calendar = Calendar.current
        let now = Date()

        switch currentPeriod {
        case .month:
            if let date = calendar.date(byAdding: .month, value: currentPeriodOffset, to: now) {
                selectedYear = calendar.component(.year, from: date)
                selectedMonth = calendar.component(.month, from: date)
            }
        case .year:
            if let date = calendar.date(byAdding: .year, value: currentPeriodOffset, to: now) {
                selectedYear = calendar.component(.year, from: date)
            }
        case .all:
            break
        }
    }

    private func getAvailableYears() -> [Int] {
        var years = Set<Int>()
        let calendar = Calendar.current

        for workout in runningWorkouts {
            years.insert(calendar.component(.year, from: workout.startDate))
        }
        for workout in externalRunningWorkouts {
            years.insert(calendar.component(.year, from: workout.workoutData.startDate))
        }

        if years.isEmpty {
            years.insert(calendar.component(.year, from: Date()))
        }

        return years.sorted()
    }

    // MARK: - Running Statistics

    private func computeRunningChartData() -> [BarChartDataPoint] {
        let (startDate, endDate) = getSelectedDateRange()
        let calendar = Calendar.current

        switch currentPeriod {
        case .month:
            var data: [BarChartDataPoint] = []
            let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)?.count ?? 31

            for day in 1...daysInMonth {
                var components = DateComponents()
                components.year = selectedYear
                components.month = selectedMonth
                components.day = day
                guard let dayDate = calendar.date(from: components) else { continue }

                var dayDistance: Double = 0
                var dayWorkouts: [(type: String, data: Any, distance: Double)] = []

                for workout in runningWorkouts {
                    let workoutDay = calendar.component(.day, from: workout.startDate)
                    let workoutMonth = calendar.component(.month, from: workout.startDate)
                    let workoutYear = calendar.component(.year, from: workout.startDate)
                    if workoutDay == day && workoutMonth == selectedMonth && workoutYear == selectedYear {
                        dayDistance += workout.distance / 1000
                        dayWorkouts.append(("internal", workout, workout.distance / 1000))
                    }
                }

                for workout in externalRunningWorkouts {
                    let workoutDay = calendar.component(.day, from: workout.workoutData.startDate)
                    let workoutMonth = calendar.component(.month, from: workout.workoutData.startDate)
                    let workoutYear = calendar.component(.year, from: workout.workoutData.startDate)
                    if workoutDay == day && workoutMonth == selectedMonth && workoutYear == selectedYear {
                        dayDistance += workout.workoutData.distance / 1000
                        dayWorkouts.append(("external", workout, workout.workoutData.distance / 1000))
                    }
                }

                let label = (day == 1 || day % 8 == 1 || day == daysInMonth) ? "\(day)" : ""
                let workoutData: Any? = dayWorkouts.isEmpty ? nil : dayWorkouts
                data.append(BarChartDataPoint(label: label, value: dayDistance, color: ColorSystem.primaryBlue, workoutData: workoutData))
            }
            return data

        case .year:
            var data: [BarChartDataPoint] = []

            for month in 1...12 {
                var components = DateComponents()
                components.year = selectedYear
                components.month = month
                components.day = 1
                guard let monthStart = calendar.date(from: components),
                      let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }

                var monthDistance: Double = 0
                var monthDuration: TimeInterval = 0
                var monthCount = 0

                for workout in runningWorkouts {
                    if workout.startDate >= monthStart && workout.startDate < nextMonth {
                        monthDistance += workout.distance / 1000
                        monthDuration += workout.duration
                        monthCount += 1
                    }
                }

                for workout in externalRunningWorkouts {
                    if workout.workoutData.startDate >= monthStart && workout.workoutData.startDate < nextMonth {
                        monthDistance += workout.workoutData.distance / 1000
                        monthDuration += workout.workoutData.duration
                        monthCount += 1
                    }
                }

                let label = (month % 2 == 1) ? "\(month)월" : ""
                let workoutData: Any? = monthCount > 0 ? [
                    "distance": monthDistance,
                    "duration": monthDuration,
                    "count": monthCount,
                    "month": month
                ] : nil
                data.append(BarChartDataPoint(label: label, value: monthDistance, color: ColorSystem.primaryBlue, workoutData: workoutData))
            }
            return data

        case .all:
            var data: [BarChartDataPoint] = []
            let years = getAvailableYears()

            for year in years {
                var yearDistance: Double = 0
                var yearWorkouts: [(type: String, data: Any, distance: Double)] = []

                for workout in runningWorkouts {
                    if calendar.component(.year, from: workout.startDate) == year {
                        yearDistance += workout.distance / 1000
                        yearWorkouts.append(("internal", workout, workout.distance / 1000))
                    }
                }

                for workout in externalRunningWorkouts {
                    if calendar.component(.year, from: workout.workoutData.startDate) == year {
                        yearDistance += workout.workoutData.distance / 1000
                        yearWorkouts.append(("external", workout, workout.workoutData.distance / 1000))
                    }
                }

                let workoutData: Any? = yearWorkouts.isEmpty ? nil : yearWorkouts
                data.append(BarChartDataPoint(label: "\(year)", value: yearDistance, color: ColorSystem.primaryBlue, workoutData: workoutData))
            }
            return data
        }
    }

    // Stats data for RunningStatsCell
    struct RunningStatsData {
        let totalDistance: Double // in km
        let runCount: Int
        let avgPace: String
        let totalTime: String
    }

    private func computeRunningStatsData() -> RunningStatsData {
        let (startDate, endDate) = getSelectedDateRange()

        var totalDistance: Double = 0
        var totalDuration: TimeInterval = 0
        var runCount = 0

        for workout in runningWorkouts {
            if workout.startDate >= startDate && workout.startDate <= endDate {
                totalDistance += workout.distance
                totalDuration += workout.duration
                runCount += 1
            }
        }

        for workout in externalRunningWorkouts {
            if workout.workoutData.startDate >= startDate && workout.workoutData.startDate <= endDate {
                totalDistance += workout.workoutData.distance
                totalDuration += workout.workoutData.duration
                runCount += 1
            }
        }

        let distanceKm = totalDistance / 1000
        let avgPaceValue = totalDistance > 0 ? (totalDuration / 60) / (totalDistance / 1000) : 0
        let paceMinutes = Int(avgPaceValue)
        let paceSeconds = Int((avgPaceValue - Double(paceMinutes)) * 60)
        let avgPace = String(format: "%d'%02d''", paceMinutes, paceSeconds)

        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60
        let totalTime = String(format: "%d:%02d:%02d", hours, minutes, seconds)

        return RunningStatsData(totalDistance: distanceKm, runCount: runCount, avgPace: avgPace, totalTime: totalTime)
    }

    private func computeRunningSummary() -> [StatsSummaryItem] {
        let (startDate, endDate) = getDateRange(for: currentPeriod, offset: currentPeriodOffset)

        var totalDistance: Double = 0
        var totalDuration: TimeInterval = 0
        var totalWorkouts = 0

        for workout in runningWorkouts {
            if workout.startDate >= startDate && workout.startDate <= endDate {
                totalDistance += workout.distance
                totalDuration += workout.duration
                totalWorkouts += 1
            }
        }

        for workout in externalRunningWorkouts {
            if workout.workoutData.startDate >= startDate && workout.workoutData.startDate <= endDate {
                totalDistance += workout.workoutData.distance
                totalDuration += workout.workoutData.duration
                totalWorkouts += 1
            }
        }

        let distanceKm = totalDistance / 1000
        let avgPace = totalDistance > 0 ? (totalDuration / 60) / (totalDistance / 1000) : 0
        let durationHours = Int(totalDuration) / 3600
        let durationMinutes = (Int(totalDuration) % 3600) / 60

        let durationString = durationHours > 0
            ? String(format: "%d시간 %02d분", durationHours, durationMinutes)
            : String(format: "%d분", durationMinutes)

        let paceMinutes = Int(avgPace)
        let paceSeconds = Int((avgPace - Double(paceMinutes)) * 60)
        let paceString = String(format: "%d'%02d\"", paceMinutes, paceSeconds)

        return [
            StatsSummaryItem(title: "거리", value: String(format: "%.1f km", distanceKm), icon: "arrow.left.and.right", color: ColorSystem.primaryBlue),
            StatsSummaryItem(title: "시간", value: durationString, icon: "clock", color: ColorSystem.primaryBlue),
            StatsSummaryItem(title: "평균 페이스", value: paceString, icon: "speedometer", color: ColorSystem.primaryBlue),
            StatsSummaryItem(title: "횟수", value: "\(totalWorkouts)회", icon: "flame", color: ColorSystem.primaryBlue)
        ]
    }

    // MARK: - Climbing Statistics

    private func computeClimbingChartData() -> [BarChartDataPoint] {
        let (startDate, endDate) = getDateRange(for: currentPeriod, offset: currentPeriodOffset)
        let calendar = Calendar.current

        switch currentPeriod {
        case .month:
            // Show daily data for month view
            var data: [BarChartDataPoint] = []
            let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)?.count ?? 31

            for day in 1...daysInMonth {
                var components = calendar.dateComponents([.year, .month], from: startDate)
                components.day = day
                guard let dayDate = calendar.date(from: components) else { continue }

                var dayRoutes = 0

                for session in climbingSessions {
                    let sessionDay = calendar.component(.day, from: session.sessionDate)
                    let sessionMonth = calendar.component(.month, from: session.sessionDate)
                    let sessionYear = calendar.component(.year, from: session.sessionDate)
                    let startMonth = calendar.component(.month, from: startDate)
                    let startYear = calendar.component(.year, from: startDate)

                    if sessionDay == day && sessionMonth == startMonth && sessionYear == startYear {
                        dayRoutes += session.sentRoutes
                    }
                }

                let label = (day == 1 || day % 8 == 1 || day == daysInMonth) ? "\(day)" : ""
                data.append(BarChartDataPoint(label: label, value: Double(dayRoutes), color: ColorSystem.primaryGreen))
            }
            return data

        case .year:
            var data: [BarChartDataPoint] = []

            for monthOffset in 0..<12 {
                guard let monthStart = calendar.date(byAdding: .month, value: monthOffset, to: startDate),
                      let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }

                var monthRoutes = 0

                for session in climbingSessions {
                    if session.sessionDate >= monthStart && session.sessionDate < nextMonth {
                        monthRoutes += session.sentRoutes
                    }
                }

                let label = (monthOffset % 2 == 0) ? "\(monthOffset + 1)월" : ""
                data.append(BarChartDataPoint(label: label, value: Double(monthRoutes), color: ColorSystem.primaryGreen))
            }
            return data

        case .all:
            // Show years
            var data: [BarChartDataPoint] = []
            let years = getAvailableYears()

            for year in years {
                var yearRoutes = 0

                for session in climbingSessions {
                    if calendar.component(.year, from: session.sessionDate) == year {
                        yearRoutes += session.sentRoutes
                    }
                }

                data.append(BarChartDataPoint(label: "\(year)", value: Double(yearRoutes), color: ColorSystem.primaryGreen))
            }
            return data
        }
    }

    private func computeClimbingSummary() -> [StatsSummaryItem] {
        let (startDate, endDate) = getDateRange(for: currentPeriod, offset: currentPeriodOffset)

        var totalRoutes = 0
        var sentRoutes = 0
        var totalVisits = 0

        for session in climbingSessions {
            if session.sessionDate >= startDate && session.sessionDate <= endDate {
                totalRoutes += session.totalRoutes
                sentRoutes += session.sentRoutes
                totalVisits += 1
            }
        }

        let successRate = totalRoutes > 0 ? (Double(sentRoutes) / Double(totalRoutes) * 100) : 0

        return [
            StatsSummaryItem(title: "완등", value: "\(sentRoutes)", icon: "checkmark.circle", color: ColorSystem.primaryGreen),
            StatsSummaryItem(title: "시도", value: "\(totalRoutes)", icon: "figure.climbing", color: ColorSystem.primaryGreen),
            StatsSummaryItem(title: "성공률", value: String(format: "%.0f", successRate), icon: "percent", color: ColorSystem.primaryGreen),
            StatsSummaryItem(title: "방문", value: "\(totalVisits)회", icon: "location", color: ColorSystem.primaryGreen)
        ]
    }

    // Stats data for ClimbingStatsCell
    struct ClimbingStatsData {
        let totalRoutes: Int
        let sentRoutes: Int
        let successRate: Double
        let visitCount: Int
    }

    private func computeClimbingStatsData() -> ClimbingStatsData {
        let (startDate, endDate) = getSelectedDateRange()

        var totalRoutes = 0
        var sentRoutes = 0
        var visitCount = 0

        for session in climbingSessions {
            if session.sessionDate >= startDate && session.sessionDate <= endDate {
                totalRoutes += session.totalRoutes
                sentRoutes += session.sentRoutes
                visitCount += 1
            }
        }

        let successRate = totalRoutes > 0 ? (Double(sentRoutes) / Double(totalRoutes) * 100) : 0

        return ClimbingStatsData(
            totalRoutes: totalRoutes,
            sentRoutes: sentRoutes,
            successRate: successRate,
            visitCount: visitCount
        )
    }

    private func computeGymStats() -> [GymStatData] {
        let (startDate, endDate) = getDateRange(for: currentPeriod, offset: currentPeriodOffset)

        // Group sessions by gym
        var gymSessions: [String: [ClimbingData]] = [:]

        for session in climbingSessions {
            if session.sessionDate >= startDate && session.sessionDate <= endDate {
                let gymName = session.gymName.isEmpty ? "암장" : session.gymName
                gymSessions[gymName, default: []].append(session)
            }
        }

        // Calculate stats for each gym
        var gymStats: [GymStatData] = []

        for (gymName, sessions) in gymSessions {
            let visitCount = sessions.count
            let totalRoutes = sessions.reduce(0) { $0 + $1.totalRoutes }
            let sentRoutes = sessions.reduce(0) { $0 + $1.sentRoutes }

            // Count routes by color
            var colorCounts: [String: Int] = [:]
            for session in sessions {
                for route in session.routes {
                    if let colorHex = route.colorHex {
                        colorCounts[colorHex, default: 0] += 1
                    }
                }
            }

            let routesByDifficulty = colorCounts.map { (color: UIColor(hex: $0.key) ?? .gray, count: $0.value) }
                .sorted { $0.count > $1.count }

            gymStats.append(GymStatData(
                gymName: gymName,
                visitCount: visitCount,
                totalRoutes: totalRoutes,
                sentRoutes: sentRoutes,
                routesByDifficulty: routesByDifficulty
            ))
        }

        return gymStats.sorted { $0.visitCount > $1.visitCount }
    }

    // Computed property for filtered items (calendar mode) - shows ALL workout types
    private var filteredItems: [(type: SportType, data: Any, date: Date)] {
        guard let dateComponents = selectedDate,
              let date = Calendar.current.date(from: dateComponents) else { return [] }

        let queryComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)

        var items: [(SportType, Any, Date)] = []

        // Add running workouts
        for workout in runningWorkouts {
            let workoutDate = Calendar.current.dateComponents([.year, .month, .day], from: workout.startDate)
            if workoutDate == queryComponents {
                items.append((.running, workout, workout.startDate))
            }
        }

        for workout in externalRunningWorkouts {
            let workoutDate = Calendar.current.dateComponents([.year, .month, .day], from: workout.workoutData.startDate)
            if workoutDate == queryComponents {
                items.append((.running, workout, workout.workoutData.startDate))
            }
        }

        // Add climbing sessions
        for session in climbingSessions {
            let sessionDate = Calendar.current.dateComponents([.year, .month, .day], from: session.sessionDate)
            if sessionDate == queryComponents {
                items.append((.climbing, session, session.sessionDate))
            }
        }

        return items.sorted(by: { $0.2 > $1.2 })
    }
}

// MARK: - UICollectionViewDataSource

extension StatisticsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // Section 0: Running or Climbing Stats
        // Section 1: Calendar Header
        // Section 2: Calendar
        // Section 3: Selected date workouts
        return 4
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 3 {
            return max(1, filteredItems.count)
        }
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            // Running or Climbing Stats
            if currentSport == .running {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RunningStatsCell.identifier, for: indexPath) as! RunningStatsCell
                let stats = computeRunningStatsData()
                let chartData = computeRunningChartData()
                cell.configure(
                    period: currentPeriod,
                    year: selectedYear,
                    month: selectedMonth,
                    stats: stats,
                    chartData: chartData,
                    delegate: self
                )
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClimbingStatsCell.identifier, for: indexPath) as! ClimbingStatsCell
                let stats = computeClimbingStatsData()
                let gymStats = computeGymStats()
                cell.configure(stats: stats, gymStats: gymStats, delegate: self, sessions: climbingSessions)
                return cell
            }
        case 1:
            // Calendar Header
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarHeaderCell.identifier, for: indexPath) as! CalendarHeaderCell
            return cell
        case 2:
            // Calendar (unified)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarCell.identifier, for: indexPath) as! CalendarCell
            cell.configure(delegate: self, selectedDate: selectedDate)
            return cell
        case 3:
            // Selected date workouts (unified)
            return filteredSessionCell(at: indexPath)
        default:
            return UICollectionViewCell()
        }
    }

    private func filteredSessionCell(at indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentSessionCell.identifier, for: indexPath) as! RecentSessionCell

        if filteredItems.isEmpty {
            cell.configure(icon: "calendar", title: "기록 없음", subtitle: "운동 기록이 있는 날짜를 선택하세요", date: Date(), color: .secondaryLabel)
        } else {
            let item = filteredItems[indexPath.item]
            if let workout = item.data as? WorkoutData {
                cell.configure(
                    icon: "figure.run",
                    title: "러닝",
                    subtitle: String(format: "%.1fkm", workout.distance / 1000),
                    date: workout.startDate,
                    color: ColorSystem.primaryBlue
                )
            } else if let externalWorkout = item.data as? ExternalWorkout {
                cell.configure(
                    icon: "figure.run",
                    title: "러닝",
                    subtitle: String(format: "%.1fkm", externalWorkout.workoutData.distance / 1000),
                    date: externalWorkout.workoutData.startDate,
                    color: ColorSystem.primaryBlue
                )
            } else if let session = item.data as? ClimbingData {
                cell.configure(
                    icon: "figure.climbing",
                    title: session.gymName.isEmpty ? "클라이밍" : session.gymName,
                    subtitle: "\(session.sentRoutes) 완등",
                    date: session.sessionDate,
                    color: ColorSystem.primaryGreen
                )
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView

        // Section 3 is the selected date workouts
        if indexPath.section == 3 {
            if let date = selectedDate, let month = date.month, let day = date.day {
                header.titleLabel.text = "\(month)월 \(day)일"
            } else {
                header.titleLabel.text = "날짜를 선택하세요"
            }
        } else {
            header.titleLabel.text = ""
        }
        return header
    }
}

extension StatisticsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Recent section is section 3
        guard indexPath.section == 3 else { return }

        let items = filteredItems
        guard indexPath.item < items.count else { return }

        let item = items[indexPath.item]

        switch item.type {
        case .climbing:
            if let session = item.data as? ClimbingData {
                let detailVC = ClimbingDetailViewController()
                detailVC.climbingData = session
                let nav = UINavigationController(rootViewController: detailVC)
                present(nav, animated: true)
            }

        case .running:
            if let workout = item.data as? WorkoutData {
                let detailVC = RunningDetailViewController()
                detailVC.workoutData = workout
                let nav = UINavigationController(rootViewController: detailVC)
                present(nav, animated: true)
            }
        }
    }
}

// MARK: - Calendar Delegates

extension StatisticsViewController: CustomCalendarViewDelegate {

    func calendarView(_ view: CustomCalendarView, didChangeMonth monthDate: Date) {
        // Optional: Could load data for new month if pagination needed
    }

    func calendarView(_ view: CustomCalendarView, decorationFor dateComponents: DateComponents) -> [UIColor]? {
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        let queryComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)

        guard let types = workoutsByDate[queryComponents], !types.isEmpty else { return nil }

        // Use a single unified color for any workout day (brand gradient primary color)
        return [ColorSystem.primaryBlue]
    }

    func calendarView(_ view: CustomCalendarView, didSelectDate dateComponents: DateComponents) {
        self.selectedDate = dateComponents

        // Section 3 is selected date workouts
        UIView.performWithoutAnimation {
            self.collectionView.reloadSections(IndexSet(integer: 3))
        }
    }
}

// MARK: - Running Stats Cell Delegate Conformance

extension StatisticsViewController: RunningStatsCellDelegate {}

// MARK: - Climbing Stats Cell Delegate Conformance

extension StatisticsViewController: ClimbingStatsCellDelegate {}

// MARK: - Cells

class CalendarCell: UICollectionViewCell {
    static let identifier = "CalendarCell"

    private let calendarView = CustomCalendarView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        contentView.addSubview(calendarView)
        calendarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(delegate: CustomCalendarViewDelegate, selectedDate: DateComponents?) {
        calendarView.delegate = delegate
        if let selectedDate = selectedDate {
            calendarView.selectDate(selectedDate)
        }
        calendarView.reloadDecorations()
    }
}

class StatsSummaryCell: UICollectionViewCell {
    static let identifier = "StatsSummaryCell"

    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        iconContainer.layer.cornerRadius = 10
        iconContainer.addSubview(iconImageView)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white

        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = ColorSystem.mainText

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = ColorSystem.subText

        let stack = UIStackView(arrangedSubviews: [iconContainer, valueLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.setCustomSpacing(12, after: iconContainer)

        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        iconContainer.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: String, icon: String, color: UIColor) {
        titleLabel.text = title
        valueLabel.text = value
        iconImageView.image = UIImage(systemName: icon)
        iconContainer.backgroundColor = color
    }
}

class RecentSessionCell: UICollectionViewCell {
    static let identifier = "RecentSessionCell"

    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dateLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        iconContainer.layer.cornerRadius = 20
        iconContainer.addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = ColorSystem.mainText

        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = ColorSystem.subText

        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = ColorSystem.subText

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        contentView.addSubview(iconContainer)
        contentView.addSubview(textStack)
        contentView.addSubview(dateLabel)

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(icon: String, title: String, subtitle: String, date: Date, color: UIColor) {
        iconImageView.image = UIImage(systemName: icon)
        iconContainer.backgroundColor = color
        titleLabel.text = title
        subtitleLabel.text = subtitle

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        dateLabel.text = formatter.string(from: date)
    }
}

class SectionHeaderView: UICollectionReusableView {
    static let identifier = "SectionHeaderView"
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = ColorSystem.mainText
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Stats Control Cell Delegate

protocol StatsControlCellDelegate: AnyObject {
    func statsControlCell(_ cell: StatsControlCell, didChangeSport sport: StatSportType)
    func statsControlCell(_ cell: StatsControlCell, didChangePeriod period: StatPeriod)
    func statsControlCellDidTapPrevPeriod(_ cell: StatsControlCell)
    func statsControlCellDidTapNextPeriod(_ cell: StatsControlCell)
}

// MARK: - Stats Control Cell

class StatsControlCell: UICollectionViewCell {
    static let identifier = "StatsControlCell"

    weak var delegate: StatsControlCellDelegate?

    private let sportSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: StatSportType.allCases.map { $0.displayName })
        control.selectedSegmentIndex = 0
        control.backgroundColor = ColorSystem.divider
        control.selectedSegmentTintColor = ColorSystem.primaryBlue
        control.setTitleTextAttributes([.foregroundColor: ColorSystem.mainText], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    private let prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = ColorSystem.mainText
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = ColorSystem.mainText
        return button
    }()

    private let periodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = ColorSystem.mainText
        label.textAlignment = .center
        return label
    }()

    private let periodSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: StatPeriod.allCases.map { $0.displayName })
        control.selectedSegmentIndex = 0
        control.backgroundColor = ColorSystem.divider
        control.selectedSegmentTintColor = ColorSystem.primaryBlue
        control.setTitleTextAttributes([.foregroundColor: ColorSystem.mainText], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        contentView.addSubview(sportSegmentedControl)
        contentView.addSubview(prevButton)
        contentView.addSubview(periodLabel)
        contentView.addSubview(nextButton)
        contentView.addSubview(periodSegmentedControl)

        sportSegmentedControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(32)
        }

        prevButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.top.equalTo(sportSegmentedControl.snp.bottom).offset(12)
            make.width.height.equalTo(32)
        }

        periodLabel.snp.makeConstraints { make in
            make.leading.equalTo(prevButton.snp.trailing).offset(8)
            make.trailing.equalTo(nextButton.snp.leading).offset(-8)
            make.centerY.equalTo(prevButton)
        }

        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalTo(prevButton)
            make.width.height.equalTo(32)
        }

        periodSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(prevButton.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(32)
        }

        sportSegmentedControl.addTarget(self, action: #selector(sportChanged), for: .valueChanged)
        periodSegmentedControl.addTarget(self, action: #selector(periodChanged), for: .valueChanged)
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    func configure(sport: StatSportType, period: StatPeriod, periodLabel: String, canGoNext: Bool, delegate: StatsControlCellDelegate) {
        self.delegate = delegate
        sportSegmentedControl.selectedSegmentIndex = sport.rawValue
        periodSegmentedControl.selectedSegmentIndex = period.rawValue
        self.periodLabel.text = periodLabel
        nextButton.isEnabled = canGoNext
        nextButton.alpha = canGoNext ? 1.0 : 0.3

        let color = sport.sportType.themeColor
        sportSegmentedControl.selectedSegmentTintColor = color
        periodSegmentedControl.selectedSegmentTintColor = color
    }

    @objc private func sportChanged() {
        guard let sport = StatSportType(rawValue: sportSegmentedControl.selectedSegmentIndex) else { return }
        let color = sport.sportType.themeColor
        sportSegmentedControl.selectedSegmentTintColor = color
        periodSegmentedControl.selectedSegmentTintColor = color
        delegate?.statsControlCell(self, didChangeSport: sport)
    }

    @objc private func periodChanged() {
        guard let period = StatPeriod(rawValue: periodSegmentedControl.selectedSegmentIndex) else { return }
        delegate?.statsControlCell(self, didChangePeriod: period)
    }

    @objc private func prevTapped() {
        delegate?.statsControlCellDidTapPrevPeriod(self)
    }

    @objc private func nextTapped() {
        delegate?.statsControlCellDidTapNextPeriod(self)
    }
}

// MARK: - Calendar Header Cell

class CalendarHeaderCell: UICollectionViewCell {
    static let identifier = "CalendarHeaderCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "캘린더"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "모든 운동 기록"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = ColorSystem.subText
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2

        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - StatsControlCellDelegate

extension StatisticsViewController: StatsControlCellDelegate {
    func statsControlCell(_ cell: StatsControlCell, didChangeSport sport: StatSportType) {
        handleSportChanged(sport)
    }

    func statsControlCell(_ cell: StatsControlCell, didChangePeriod period: StatPeriod) {
        handlePeriodChanged(period)
    }

    func statsControlCellDidTapPrevPeriod(_ cell: StatsControlCell) {
        handlePrevPeriod()
    }

    func statsControlCellDidTapNextPeriod(_ cell: StatsControlCell) {
        handleNextPeriod()
    }
}

// MARK: - Custom Calendar Implementation

protocol CustomCalendarViewDelegate: AnyObject {
    func calendarView(_ view: CustomCalendarView, didSelectDate dateComponents: DateComponents)
    func calendarView(_ view: CustomCalendarView, didChangeMonth monthDate: Date)
    func calendarView(_ view: CustomCalendarView, decorationFor dateComponents: DateComponents) -> [UIColor]?
}

class CustomCalendarView: UIView {

    // MARK: - Properties

    weak var delegate: CustomCalendarViewDelegate?

    private var baseDate: Date = Date() {
        didSet {
            updateHeader()
            collectionView.reloadData()
            delegate?.calendarView(self, didChangeMonth: baseDate)
        }
    }

    private var selectedDate: DateComponents?

    private let calendar = Calendar.current
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var daysInMonth: [Date?] = []

    // MARK: - UI Components

    private let headerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let prevOpenButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = .label
        return btn
    }()

    private let nextOpenButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        btn.tintColor = .label
        return btn
    }()

    private let weekDayStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(CustomCalendarDayCell.self, forCellWithReuseIdentifier: CustomCalendarDayCell.identifier)
        return cv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        generateMonthData()
        updateHeader()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        prevOpenButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        nextOpenButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)

        headerStack.addArrangedSubview(monthLabel)
        headerStack.addArrangedSubview(UIView())
        headerStack.addArrangedSubview(prevOpenButton)
        headerStack.addArrangedSubview(nextOpenButton)
        headerStack.setCustomSpacing(20, after: prevOpenButton)

        addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }

        for day in weekDays {
            let label = UILabel()
            label.text = day
            label.font = .systemFont(ofSize: 13, weight: .semibold)
            label.textColor = ColorSystem.subText
            label.textAlignment = .center
            weekDayStack.addArrangedSubview(label)
        }

        addSubview(weekDayStack)
        weekDayStack.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
        }

        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(weekDayStack.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    // MARK: - Logic

    private func generateMonthData() {
        daysInMonth.removeAll()

        guard let range = calendar.range(of: .day, in: .month, for: baseDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: baseDate)) else { return }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        for _ in 1..<firstWeekday {
            daysInMonth.append(nil)
        }

        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                daysInMonth.append(date)
            }
        }
    }

    private func updateHeader() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: baseDate)
    }

    @objc private func prevMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: baseDate) {
            baseDate = newDate
            generateMonthData()
        }
    }

    @objc private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: baseDate) {
            baseDate = newDate
            generateMonthData()
        }
    }

    // MARK: - Configuration

    func selectDate(_ dateComponents: DateComponents) {
        selectedDate = dateComponents
        guard let date = calendar.date(from: dateComponents) else { return }

        let currentComponents = calendar.dateComponents([.year, .month], from: baseDate)
        if currentComponents.year != dateComponents.year || currentComponents.month != dateComponents.month {
            baseDate = date
            generateMonthData()
        } else {
            collectionView.reloadData()
        }
    }

    func reloadDecorations() {
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout & DataSource

extension CustomCalendarView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return daysInMonth.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCalendarDayCell.identifier, for: indexPath) as! CustomCalendarDayCell

        guard let date = daysInMonth[indexPath.item] else {
            cell.configureEmpty()
            return cell
        }

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let isSelected = selectedDate?.year == components.year && selectedDate?.month == components.month && selectedDate?.day == components.day
        let isToday = calendar.isDateInToday(date)

        let decorations = delegate?.calendarView(self, decorationFor: components)

        cell.configure(day: components.day ?? 0, isSelected: isSelected, isToday: isToday, decorations: decorations)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let date = daysInMonth[indexPath.item] else { return }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        selectedDate = components
        collectionView.reloadData()
        delegate?.calendarView(self, didSelectDate: components)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 7.0
        return CGSize(width: width, height: width)
    }
}

class CustomCalendarDayCell: UICollectionViewCell {
    static let identifier = "CustomCalendarDayCell"

    private let selectionBackground = UIView()
    private let dayLabel = UILabel()
    private let dotStackView = UIStackView()
    private let plusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        selectionBackground.layer.cornerRadius = 18
        selectionBackground.layer.masksToBounds = true
        selectionBackground.isHidden = true
        contentView.addSubview(selectionBackground)

        dayLabel.font = .systemFont(ofSize: 15, weight: .medium)
        dayLabel.textColor = ColorSystem.mainText
        dayLabel.textAlignment = .center
        contentView.addSubview(dayLabel)

        dotStackView.axis = .horizontal
        dotStackView.spacing = 2
        dotStackView.alignment = .center
        dotStackView.distribution = .fillEqually
        contentView.addSubview(dotStackView)

        plusLabel.text = "+"
        plusLabel.font = .systemFont(ofSize: 10, weight: .bold)
        plusLabel.textColor = ColorSystem.subText
        plusLabel.textAlignment = .center
        plusLabel.isHidden = true
        contentView.addSubview(plusLabel)

        selectionBackground.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(36)
        }

        dayLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        dotStackView.snp.makeConstraints { make in
            make.top.equalTo(dayLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.height.equalTo(6)
        }

        plusLabel.snp.makeConstraints { make in
            make.top.equalTo(dayLabel.snp.bottom).offset(0)
            make.centerX.equalToSuperview()
        }
    }

    func configureEmpty() {
        dayLabel.text = ""
        selectionBackground.isHidden = true
        dotStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        plusLabel.isHidden = true
        isUserInteractionEnabled = false
    }

    func configure(day: Int, isSelected: Bool, isToday: Bool, decorations: [UIColor]?) {
        dayLabel.text = "\(day)"
        isUserInteractionEnabled = true

        dotStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        plusLabel.isHidden = true

        if isSelected {
            selectionBackground.isHidden = false
            selectionBackground.setGradientBackground()
            dayLabel.textColor = .white

            if let decorations = decorations, !decorations.isEmpty {
                if decorations.count <= 2 {
                    for _ in decorations {
                        addDot(color: .white)
                    }
                } else {
                    plusLabel.textColor = .white
                    plusLabel.isHidden = false
                }
            }
        } else {
            selectionBackground.isHidden = true
            dayLabel.textColor = isToday ? .systemBlue : ColorSystem.mainText

            if let decorations = decorations, !decorations.isEmpty {
                if decorations.count <= 2 {
                    for color in decorations {
                        addDot(color: color)
                    }
                } else {
                    plusLabel.textColor = ColorSystem.subText
                    plusLabel.isHidden = false
                }
            }
        }
    }

    private func addDot(color: UIColor) {
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 2.5
        dot.snp.makeConstraints { make in
            make.width.height.equalTo(5)
        }
        dotStackView.addArrangedSubview(dot)
    }
}

// MARK: - Runner Tier Cell

class RunnerTierCell: UICollectionViewCell {
    static let identifier = "RunnerTierCell"

    private var gradientLayer: CAGradientLayer?

    private let tierLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let tierTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48)
        return label
    }()

    private let progressBarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let progressFillView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        contentView.addSubview(tierLabel)
        contentView.addSubview(tierTitleLabel)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(progressBarView)
        progressBarView.addSubview(progressFillView)
        contentView.addSubview(progressLabel)

        emojiLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        tierLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
        }

        tierTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(tierLabel)
            make.top.equalTo(tierLabel.snp.bottom).offset(4)
        }

        progressBarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-32)
            make.trailing.equalTo(emojiLabel.snp.leading).offset(-16)
            make.height.equalTo(8)
        }

        progressFillView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(0)
        }

        progressLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(progressBarView.snp.bottom).offset(4)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = contentView.bounds
    }

    func configure(totalDistance: Double) {
        let tier = RunnerTier.tier(for: totalDistance)
        let progress = tier.progress(to: totalDistance)

        tierLabel.text = tier.displayName
        tierTitleLabel.text = "총 \(String(format: "%.1f", totalDistance))km"
        emojiLabel.text = tier.emoji

        // Update gradient
        gradientLayer?.removeFromSuperlayer()
        let gradient = ColorSystem.tierGradientLayer(for: tier)
        gradient.frame = contentView.bounds
        contentView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient

        // Update progress bar
        progressFillView.snp.remakeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(max(progress, 0.01))
        }

        if let remaining = tier.remainingDistance(to: totalDistance) {
            progressLabel.text = "다음 등급까지 \(String(format: "%.1f", remaining))km"
        } else {
            progressLabel.text = "최고 등급 달성!"
        }
    }
}

// MARK: - Graph Chart Cell

class GraphChartCell: UICollectionViewCell {
    static let identifier = "GraphChartCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let chartView = BarChartView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        contentView.addSubview(titleLabel)
        contentView.addSubview(chartView)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }

        chartView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    func configure(title: String, data: [BarChartDataPoint], unit: String) {
        titleLabel.text = title
        chartView.configure(
            with: data,
            showValues: true,
            valueFormatter: { value in
                if value >= 100 {
                    return String(format: "%.0f", value)
                } else if value >= 10 {
                    return String(format: "%.1f", value)
                } else {
                    return String(format: "%.1f", value)
                }
            },
            onBarTapped: nil,
            onFloatingViewDismiss: nil
        )
    }
}

// MARK: - Summary Grid Cell

class SummaryGridCell: UICollectionViewCell {
    static let identifier = "SummaryGridCell"

    private let gridStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(gridStack)
        gridStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with items: [StatsSummaryItem]) {
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Create 2x2 grid
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 12
        bottomRow.distribution = .fillEqually

        for (index, item) in items.prefix(4).enumerated() {
            let cardView = createStatCard(for: item)
            if index < 2 {
                topRow.addArrangedSubview(cardView)
            } else {
                bottomRow.addArrangedSubview(cardView)
            }
        }

        gridStack.addArrangedSubview(topRow)
        gridStack.addArrangedSubview(bottomRow)
    }

    private func createStatCard(for item: StatsSummaryItem) -> UIView {
        let card = UIView()
        card.backgroundColor = ColorSystem.cardBackground
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous

        let iconContainer = UIView()
        iconContainer.backgroundColor = item.color.withAlphaComponent(0.15)
        iconContainer.layer.cornerRadius = 12

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: item.icon)
        iconImageView.tintColor = item.color
        iconImageView.contentMode = .scaleAspectFit

        let valueLabel = UILabel()
        valueLabel.text = item.value
        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        valueLabel.textColor = ColorSystem.mainText

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = ColorSystem.subText

        card.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        card.addSubview(valueLabel)
        card.addSubview(titleLabel)

        iconContainer.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(12)
            make.width.height.equalTo(24)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(14)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalTo(titleLabel.snp.top).offset(-2)
        }

        return card
    }
}

// MARK: - Running Stats Cell Delegate

protocol RunningStatsCellDelegate: AnyObject {
    func handleSportChanged(_ sport: StatSportType)
    func handlePeriodChanged(_ period: StatPeriod)
    func handleDateSelected(year: Int, month: Int?)
}

// MARK: - Running Stats Cell

class RunningStatsCell: UICollectionViewCell {
    static let identifier = "RunningStatsCell"

    weak var delegate: RunningStatsCellDelegate?

    private var gradientLayer: CAGradientLayer?

    // Sport Picker Button (Dropdown)
    private lazy var sportPickerButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    // Period Segment
    private let periodSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: StatPeriod.allCases.map { $0.displayName })
        control.selectedSegmentIndex = 0
        control.backgroundColor = ColorSystem.divider
        control.selectedSegmentTintColor = ColorSystem.primaryBlue
        control.setTitleTextAttributes([.foregroundColor: ColorSystem.mainText], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    // Date Picker Row
    private let datePickerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private let prevButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = ColorSystem.mainText
        return btn
    }()

    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        btn.tintColor = ColorSystem.mainText
        return btn
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = ColorSystem.mainText
        label.textAlignment = .center
        return label
    }()

    // Tier Card
    private let tierCardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()

    private let tierEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40)
        return label
    }()

    private let tierNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
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
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        return label
    }()

    // Chart View
    private let chartTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let chartView = BarChartView()

    private var floatingView: UIView?

    // Summary Grid
    private let summaryGridStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    private var currentPeriod: StatPeriod = .month
    private var currentYear: Int = 0
    private var currentMonth: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        // Sport Picker Button
        contentView.addSubview(sportPickerButton)

        // Period Segment
        contentView.addSubview(periodSegmentedControl)
        periodSegmentedControl.addTarget(self, action: #selector(periodChanged), for: .valueChanged)

        // Date Picker
        datePickerStack.addArrangedSubview(prevButton)
        datePickerStack.addArrangedSubview(dateLabel)
        datePickerStack.addArrangedSubview(nextButton)
        contentView.addSubview(datePickerStack)
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        // Tier Card
        contentView.addSubview(tierCardView)
        tierCardView.addSubview(tierEmojiLabel)
        tierCardView.addSubview(tierNameLabel)
        tierCardView.addSubview(tierDistanceLabel)
        tierCardView.addSubview(tierProgressBar)
        tierProgressBar.addSubview(tierProgressFill)
        tierCardView.addSubview(tierProgressLabel)

        // Chart
        contentView.addSubview(chartTitleLabel)
        contentView.addSubview(chartView)

        // Summary
        contentView.addSubview(summaryGridStack)

        // Constraints
        sportPickerButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }

        periodSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(sportPickerButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }

        datePickerStack.snp.makeConstraints { make in
            make.top.equalTo(periodSegmentedControl.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }

        prevButton.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        nextButton.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        dateLabel.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(120)
        }

        tierCardView.snp.makeConstraints { make in
            make.top.equalTo(datePickerStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }

        tierEmojiLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        tierNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
        }

        tierDistanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(tierNameLabel)
            make.top.equalTo(tierNameLabel.snp.bottom).offset(2)
        }

        tierProgressBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(tierEmojiLabel.snp.leading).offset(-16)
            make.bottom.equalToSuperview().offset(-24)
            make.height.equalTo(6)
        }

        tierProgressFill.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(0)
        }

        tierProgressLabel.snp.makeConstraints { make in
            make.leading.equalTo(tierProgressBar)
            make.top.equalTo(tierProgressBar.snp.bottom).offset(4)
        }

        chartTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(tierCardView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
        }

        chartView.snp.makeConstraints { make in
            make.top.equalTo(chartTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(120)
        }

        summaryGridStack.snp.makeConstraints { make in
            make.top.equalTo(chartView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(80)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        dismissFloatingView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = tierCardView.bounds
    }

    func configure(
        period: StatPeriod,
        year: Int,
        month: Int,
        stats: StatisticsViewController.RunningStatsData,
        chartData: [BarChartDataPoint],
        delegate: RunningStatsCellDelegate
    ) {
        self.delegate = delegate
        self.currentPeriod = period
        self.currentYear = year
        self.currentMonth = month

        updateSportPickerMenu(selectedSport: .running)

        periodSegmentedControl.selectedSegmentIndex = period.rawValue

        // Update date label
        switch period {
        case .month:
            dateLabel.text = "\(year)년 \(month)월"
        case .year:
            dateLabel.text = "\(year)년"
        case .all:
            dateLabel.text = "전체"
        }

        // Update tier card
        let tier = RunnerTier.tier(for: stats.totalDistance)
        let progress = tier.progress(to: stats.totalDistance)

        tierEmojiLabel.text = tier.emoji
        tierNameLabel.text = tier.displayName
        tierDistanceLabel.text = String(format: "총 %.1f km", stats.totalDistance)

        if let remaining = tier.remainingDistance(to: stats.totalDistance) {
            tierProgressLabel.text = String(format: "다음 등급까지 %.1f km", remaining)
        } else {
            tierProgressLabel.text = "최고 등급 달성!"
        }

        // Update gradient
        gradientLayer?.removeFromSuperlayer()
        let gradient = ColorSystem.tierGradientLayer(for: tier)
        gradient.frame = tierCardView.bounds
        tierCardView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient

        // Animate progress bar
        tierProgressFill.snp.remakeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(max(progress, 0.01))
        }

        // Chart
        chartTitleLabel.text = period == .month ? "일별 거리 (km)" : period == .year ? "월별 거리 (km)" : "연도별 거리 (km)"
        chartView.configure(
            with: chartData,
            showValues: true,
            valueFormatter: { value in
                String(format: "%.1f", value)
            },
            onBarTapped: { [weak self] index, workoutData in
                guard let self = self else { return }

                if currentPeriod == .year {
                    if let monthlyStats = workoutData as? [String: Any] {
                        self.showFloatingMonthlyStats(stats: monthlyStats)
                    } else {
                        self.dismissFloatingView()
                    }
                } else {
                    if let workouts = workoutData as? [(type: String, data: Any, distance: Double)] {
                        self.showFloatingWorkouts(workouts: workouts)
                    } else {
                        self.dismissFloatingView()
                    }
                }
            },
            onFloatingViewDismiss: { [weak self] in
                self?.dismissFloatingView()
            }
        )

        // Summary grid
        summaryGridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let summaryItems = [
            ("거리", String(format: "%.1f km", stats.totalDistance), "arrow.left.and.right", ColorSystem.primaryBlue),
            ("시간", stats.totalTime, "clock", ColorSystem.primaryBlue),
            ("페이스", stats.avgPace, "speedometer", ColorSystem.primaryBlue),
            ("횟수", "\(stats.runCount)회", "flame", ColorSystem.primaryBlue)
        ]

        for item in summaryItems {
            let card = createSummaryCard(title: item.0, value: item.1, icon: item.2, color: item.3)
            summaryGridStack.addArrangedSubview(card)
        }
    }

    private func createSummaryCard(title: String, value: String, icon: String, color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = color.withAlphaComponent(0.1)
        card.layer.cornerRadius = 12

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = ColorSystem.mainText
        valueLabel.adjustsFontSizeToFitWidth = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = ColorSystem.subText

        card.addSubview(iconView)
        card.addSubview(valueLabel)
        card.addSubview(titleLabel)

        iconView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(8)
            make.width.height.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(titleLabel.snp.top).offset(-2)
        }

        return card
    }

    private func showFloatingWorkouts(workouts: [(type: String, data: Any, distance: Double)]) {
        dismissFloatingView()

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill

        for workout in workouts {
            let row = createWorkoutRow(type: workout.type, data: workout.data)
            stack.addArrangedSubview(row)
        }

        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.centerX.equalTo(chartView)
            make.top.equalTo(chartView).offset(40)
            make.width.lessThanOrEqualToSuperview().offset(-32)
        }

        floatingView = container

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFloatingView))
        container.addGestureRecognizer(tapGesture)

        contentView.isUserInteractionEnabled = true
        let bgTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFloatingView))
        contentView.addGestureRecognizer(bgTapGesture)
    }

    private func showFloatingMonthlyStats(stats: [String: Any]) {
        dismissFloatingView()

        guard let distance = stats["distance"] as? Double,
              let duration = stats["duration"] as? TimeInterval,
              let count = stats["count"] as? Int,
              let month = stats["month"] as? Int else { return }

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        let countLabel = createStatRow(icon: "figure.run", title: "러닝 횟수", value: "\(count)회")
        let distanceLabel = createStatRow(icon: "arrow.left.and.right", title: "총 거리", value: String(format: "%.1f km", distance))
        let timeLabel = createStatRow(icon: "clock", title: "총 시간", value: formatDuration(duration))

        stack.addArrangedSubview(countLabel)
        stack.addArrangedSubview(distanceLabel)
        stack.addArrangedSubview(timeLabel)

        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.centerX.equalTo(chartView)
            make.top.equalTo(chartView).offset(40)
            make.width.lessThanOrEqualToSuperview().offset(-32)
        }

        floatingView = container

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFloatingView))
        container.addGestureRecognizer(tapGesture)

        contentView.isUserInteractionEnabled = true
        let bgTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFloatingView))
        contentView.addGestureRecognizer(bgTapGesture)
    }

    private func createStatRow(icon: String, title: String, value: String) -> UIView {
        let row = UIView()
        row.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        row.layer.cornerRadius = 8

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.8)

        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        valueLabel.textColor = .white

        titleLabel.text = title
        valueLabel.text = value

        row.addSubview(iconView)
        row.addSubview(titleLabel)
        row.addSubview(valueLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalTo(valueLabel.snp.top).offset(-4)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
        }

        return row
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

    private func createWorkoutRow(type: String, data: Any) -> UIView {
        let row = UIView()
        row.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        row.layer.cornerRadius = 8

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "figure.run")
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        let distanceLabel = UILabel()
        let timeLabel = UILabel()
        let paceLabel = UILabel()

        distanceLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        distanceLabel.textColor = .white

        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.8)

        paceLabel.font = .systemFont(ofSize: 12)
        paceLabel.textColor = UIColor.white.withAlphaComponent(0.8)

        let textStack = UIStackView(arrangedSubviews: [distanceLabel, timeLabel, paceLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        row.addSubview(iconView)
        row.addSubview(textStack)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        if type == "internal", let workout = data as? WorkoutData {
            let distanceKm = workout.distance / 1000
            distanceLabel.text = String(format: "%.1f km", distanceKm)

            let hours = Int(workout.duration) / 3600
            let minutes = (Int(workout.duration) % 3600) / 60
            let seconds = Int(workout.duration) % 60
            if hours > 0 {
                timeLabel.text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                timeLabel.text = String(format: "%d:%02d", minutes, seconds)
            }

            let avgPace = distanceKm > 0 ? (workout.duration / 60) / distanceKm : 0
            let paceMinutes = Int(avgPace)
            let paceSeconds = Int((avgPace - Double(paceMinutes)) * 60)
            paceLabel.text = String(format: "%d'%02d\"/km", paceMinutes, paceSeconds)
        } else if type == "external", let workout = data as? ExternalWorkout {
            let distanceKm = workout.workoutData.distance / 1000
            distanceLabel.text = String(format: "%.1f km", distanceKm)

            let hours = Int(workout.workoutData.duration) / 3600
            let minutes = (Int(workout.workoutData.duration) % 3600) / 60
            let seconds = Int(workout.workoutData.duration) % 60
            if hours > 0 {
                timeLabel.text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                timeLabel.text = String(format: "%d:%02d", minutes, seconds)
            }

            let avgPace = distanceKm > 0 ? (workout.workoutData.duration / 60) / distanceKm : 0
            let paceMinutes = Int(avgPace)
            let paceSeconds = Int((avgPace - Double(paceMinutes)) * 60)
            paceLabel.text = String(format: "%d'%02d\"/km", paceMinutes, paceSeconds)
        }

        return row
    }

    @objc private func dismissFloatingView() {
        floatingView?.removeFromSuperview()
        floatingView = nil
    }

    private func updateSportPickerMenu(selectedSport: StatSportType) {
        let actions = StatSportType.allCases.map { sport in
            UIAction(
                title: sport.displayName,
                state: sport == selectedSport ? .on : .off
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateSportPickerMenu(selectedSport: sport)
                self.periodSegmentedControl.selectedSegmentTintColor = sport.sportType.themeColor
                self.delegate?.handleSportChanged(sport)
            }
        }
        sportPickerButton.menu = UIMenu(children: actions)
        sportPickerButton.setTitle("\(selectedSport.displayName) ▾", for: .normal)
        sportPickerButton.backgroundColor = selectedSport.sportType.themeColor
    }

    @objc private func periodChanged() {
        guard let period = StatPeriod(rawValue: periodSegmentedControl.selectedSegmentIndex) else { return }
        delegate?.handlePeriodChanged(period)
    }

    @objc private func prevTapped() {
        switch currentPeriod {
        case .month:
            var newMonth = currentMonth - 1
            var newYear = currentYear
            if newMonth < 1 {
                newMonth = 12
                newYear -= 1
            }
            delegate?.handleDateSelected(year: newYear, month: newMonth)
        case .year:
            delegate?.handleDateSelected(year: currentYear - 1, month: nil)
        case .all:
            break
        }
    }

    @objc private func nextTapped() {
        let calendar = Calendar.current
        let currentActualYear = calendar.component(.year, from: Date())
        let currentActualMonth = calendar.component(.month, from: Date())

        switch currentPeriod {
        case .month:
            var newMonth = currentMonth + 1
            var newYear = currentYear
            if newMonth > 12 {
                newMonth = 1
                newYear += 1
            }
            // Don't go beyond current month
            if newYear > currentActualYear || (newYear == currentActualYear && newMonth > currentActualMonth) {
                return
            }
            delegate?.handleDateSelected(year: newYear, month: newMonth)
        case .year:
            if currentYear >= currentActualYear { return }
            delegate?.handleDateSelected(year: currentYear + 1, month: nil)
        case .all:
            break
        }
    }
}

// MARK: - Climbing Stats Cell Delegate

protocol ClimbingStatsCellDelegate: AnyObject {
    func handleSportChanged(_ sport: StatSportType)
    func handlePeriodChanged(_ period: StatPeriod)
}

// MARK: - Climbing Stats Cell

class ClimbingStatsCell: UICollectionViewCell {
    static let identifier = "ClimbingStatsCell"

    weak var delegate: ClimbingStatsCellDelegate?

    // Sport Picker Button (Dropdown)
    private lazy var sportPickerButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    // Period Segment
    private let periodSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["월별", "연도별", "전체"])
        control.selectedSegmentIndex = 0
        control.backgroundColor = ColorSystem.divider
        control.selectedSegmentTintColor = ColorSystem.primaryGreen
        control.setTitleTextAttributes([.foregroundColor: ColorSystem.mainText], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    // Period Navigation
    private let periodNavigationView: UIView = {
        let view = UIView()
        return view
    }()

    private let prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = ColorSystem.mainText
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = ColorSystem.mainText
        return button
    }()

    private let periodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = ColorSystem.mainText
        label.textAlignment = .center
        return label
    }()

    // Chart View
    private let chartTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let chartView = BarChartView()

    // Summary Grid
    private let summaryGridStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    // Gym Stats
    private let gymStatsView = GymStatsView()

    private var currentPeriod: StatPeriod = .month
    private var currentMonth: Int = Calendar.current.component(.month, from: Date())
    private var currentYear: Int = Calendar.current.component(.year, from: Date())
    private var floatingView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous

        // Sport Picker Button
        contentView.addSubview(sportPickerButton)

        // Period Segment
        contentView.addSubview(periodSegmentedControl)
        periodSegmentedControl.addTarget(self, action: #selector(periodChanged), for: .valueChanged)

        periodNavigationView.addSubview(prevButton)
        periodNavigationView.addSubview(periodLabel)
        periodNavigationView.addSubview(nextButton)
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        contentView.addSubview(chartTitleLabel)
        contentView.addSubview(chartView)
        contentView.addSubview(periodNavigationView)

        contentView.addSubview(summaryGridStack)
        contentView.addSubview(gymStatsView)

        sportPickerButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }

        periodSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(sportPickerButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(28)
        }

        periodNavigationView.snp.makeConstraints { make in
            make.top.equalTo(periodSegmentedControl.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }

        prevButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(40)
        }

        periodLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(prevButton.snp.trailing).offset(8)
            make.trailing.equalTo(nextButton.snp.leading).offset(-8)
        }

        nextButton.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalTo(40)
        }

        chartTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(periodNavigationView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        chartView.snp.makeConstraints { make in
            make.top.equalTo(chartTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(160)
        }

        summaryGridStack.snp.makeConstraints { make in
            make.top.equalTo(chartView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(80)
        }

        gymStatsView.snp.makeConstraints { make in
            make.top.equalTo(summaryGridStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    func configure(
        stats: StatisticsViewController.ClimbingStatsData,
        gymStats: [GymStatData],
        delegate: ClimbingStatsCellDelegate,
        sessions: [ClimbingData]
    ) {
        self.delegate = delegate

        updateSportPickerMenu(selectedSport: .climbing)

        let calendar = Calendar.current
        let now = Date()
        currentYear = calendar.component(.year, from: now)
        currentMonth = calendar.component(.month, from: now)
        currentPeriod = .month
        periodSegmentedControl.selectedSegmentIndex = 0

        updatePeriodLabel()
        updateButtonStates()
        updateChart(sessions: sessions)

        // Summary grid
        summaryGridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let summaryItems = [
            ("완등", "\(stats.sentRoutes)", "checkmark.circle", ColorSystem.primaryGreen),
            ("시도", "\(stats.totalRoutes)", "figure.climbing", ColorSystem.primaryGreen),
            ("성공률", String(format: "%.0f", stats.successRate), "percent", ColorSystem.primaryGreen),
            ("방문", "\(stats.visitCount)회", "location", ColorSystem.primaryGreen)
        ]

        for item in summaryItems {
            let card = createSummaryCard(title: item.0, value: item.1, icon: item.2, color: item.3)
            summaryGridStack.addArrangedSubview(card)
        }

        // Gym stats
        gymStatsView.configure(with: gymStats)
    }

    private func updatePeriodLabel() {
        switch currentPeriod {
        case .month:
            periodLabel.text = "\(currentYear)년 \(currentMonth)월"
        case .year:
            periodLabel.text = "\(currentYear)년"
        case .all:
            periodLabel.text = "전체"
        }
    }

    private func updateChart(sessions: [ClimbingData]) {
        let chartData = computeClimbingChartData(sessions: sessions)

        switch currentPeriod {
        case .month:
            chartTitleLabel.text = "일별 완등 수"
        case .year:
            chartTitleLabel.text = "월별 완등 수"
        case .all:
            chartTitleLabel.text = "연도별 완등 수"
        }

        chartView.configure(
            with: chartData,
            showValues: true,
            valueFormatter: { value in
                String(format: "%.0f", value)
            },
            onBarTapped: { [weak self] index, workoutData in
                guard let self = self, let data = workoutData as? [String: Any] else { return }
                self.showFloatingClimbingStats(data: data)
            },
            onFloatingViewDismiss: { [weak self] in
                self?.dismissFloatingView()
            }
        )
    }

    private func computeClimbingChartData(sessions: [ClimbingData]) -> [BarChartDataPoint] {
        let calendar = Calendar.current
        let (startDate, endDate) = getDateRange(for: currentPeriod, offset: 0)

        switch currentPeriod {
        case .month:
            var data: [BarChartDataPoint] = []
            let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)?.count ?? 31

            for day in 1...daysInMonth {
                var components = calendar.dateComponents([.year, .month], from: startDate)
                components.day = day
                guard let dayDate = calendar.date(from: components) else { continue }

                var dayRoutes = 0
                var daySessions: [ClimbingData] = []

                for session in sessions {
                    if calendar.isDate(session.sessionDate, inSameDayAs: dayDate) {
                        dayRoutes += session.sentRoutes
                        daySessions.append(session)
                    }
                }

                let label = (day == 1 || day % 7 == 1 || day == daysInMonth) ? "\(day)" : ""
                let workoutData: Any? = daySessions.isEmpty ? nil : ["type": "daily", "sessions": daySessions, "date": dayDate]
                data.append(BarChartDataPoint(label: label, value: Double(dayRoutes), color: ColorSystem.primaryGreen, workoutData: workoutData))
            }
            return data

        case .year:
            var data: [BarChartDataPoint] = []

            for month in 1...12 {
                var components = DateComponents()
                components.year = currentYear
                components.month = month
                components.day = 1
                guard let monthStart = calendar.date(from: components),
                      let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }

                var monthRoutes = 0
                var monthSessions: [ClimbingData] = []

                for session in sessions {
                    if session.sessionDate >= monthStart && session.sessionDate < nextMonth {
                        monthRoutes += session.sentRoutes
                        monthSessions.append(session)
                    }
                }

                let label = (month % 2 == 1) ? "\(month)월" : ""
                let workoutData: Any? = monthSessions.isEmpty ? nil : ["type": "monthly", "sessions": monthSessions, "month": month]
                data.append(BarChartDataPoint(label: label, value: Double(monthRoutes), color: ColorSystem.primaryGreen, workoutData: workoutData))
            }
            return data

        case .all:
            var data: [BarChartDataPoint] = []
            let years = sessions.map { calendar.component(.year, from: $0.sessionDate) }
            let uniqueYears = Set(years).sorted()

            for year in uniqueYears {
                var yearRoutes = 0
                var yearSessions: [ClimbingData] = []

                for session in sessions {
                    if calendar.component(.year, from: session.sessionDate) == year {
                        yearRoutes += session.sentRoutes
                        yearSessions.append(session)
                    }
                }

                let workoutData: Any? = yearSessions.isEmpty ? nil : ["type": "yearly", "sessions": yearSessions, "year": year]
                data.append(BarChartDataPoint(label: "\(year)", value: Double(yearRoutes), color: ColorSystem.primaryGreen, workoutData: workoutData))
            }
            return data
        }
    }

    private func getDateRange(for period: StatPeriod, offset: Int) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .month:
            var targetMonth = currentMonth + offset
            var targetYear = currentYear

            while targetMonth < 1 {
                targetMonth += 12
                targetYear -= 1
            }

            while targetMonth > 12 {
                targetMonth -= 12
                targetYear += 1
            }

            var components = DateComponents(year: targetYear, month: targetMonth, day: 1)
            guard let startDate = calendar.date(from: components) else { return (now, now) }
            guard let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else { return (now, now) }
            return (startDate, endDate)

        case .year:
            let targetYear = currentYear + offset
            var components = DateComponents(year: targetYear, month: 1, day: 1)
            guard let startDate = calendar.date(from: components) else { return (now, now) }
            guard let endDate = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startDate) else { return (now, now) }
            return (startDate, endDate)

        case .all:
            return (calendar.date(from: DateComponents(year: 1900, month: 1, day: 1))!, now)
        }
    }

    private func createSummaryCard(title: String, value: String, icon: String, color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = color.withAlphaComponent(0.1)
        card.layer.cornerRadius = 12

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = ColorSystem.mainText
        valueLabel.adjustsFontSizeToFitWidth = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = ColorSystem.subText

        card.addSubview(iconView)
        card.addSubview(valueLabel)
        card.addSubview(titleLabel)

        iconView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(8)
            make.width.height.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(titleLabel.snp.top).offset(-2)
        }

        return card
    }

    @objc private func periodChanged() {
        guard let period = StatPeriod(rawValue: periodSegmentedControl.selectedSegmentIndex) else { return }
        currentPeriod = period
        delegate?.handlePeriodChanged(period)
    }

    @objc private func prevTapped() {
        switch currentPeriod {
        case .month:
            currentMonth -= 1
            if currentMonth < 1 {
                currentMonth = 12
                currentYear -= 1
            }
        case .year:
            currentYear -= 1
        case .all:
            break
        }
        updatePeriodLabel()
        updateButtonStates()
        delegate?.handlePeriodChanged(currentPeriod)
    }

    @objc private func nextTapped() {
        let calendar = Calendar.current
        let now = Date()
        let maxYear = calendar.component(.year, from: now)
        let maxMonth = calendar.component(.month, from: now)

        switch currentPeriod {
        case .month:
            if currentYear == maxYear && currentMonth >= maxMonth {
                return
            }
            currentMonth += 1
            if currentMonth > 12 {
                currentMonth = 1
                currentYear += 1
            }
        case .year:
            if currentYear >= maxYear {
                return
            }
            currentYear += 1
        case .all:
            break
        }
        updatePeriodLabel()
        updateButtonStates()
        delegate?.handlePeriodChanged(currentPeriod)
    }

    private func updateButtonStates() {
        let calendar = Calendar.current
        let now = Date()
        let maxYear = calendar.component(.year, from: now)
        let maxMonth = calendar.component(.month, from: now)

        switch currentPeriod {
        case .month:
            prevButton.isEnabled = true
            nextButton.isEnabled = !(currentYear == maxYear && currentMonth >= maxMonth)
        case .year:
            prevButton.isEnabled = true
            nextButton.isEnabled = currentYear < maxYear
        case .all:
            prevButton.isEnabled = false
            nextButton.isEnabled = false
        }
    }

    private func updateSportPickerMenu(selectedSport: StatSportType) {
        let actions = StatSportType.allCases.map { sport in
            UIAction(
                title: sport.displayName,
                state: sport == selectedSport ? .on : .off
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateSportPickerMenu(selectedSport: sport)
                self.periodSegmentedControl.selectedSegmentTintColor = sport.sportType.themeColor
                self.delegate?.handleSportChanged(sport)
            }
        }
        sportPickerButton.menu = UIMenu(children: actions)
        sportPickerButton.setTitle("\(selectedSport.displayName) ▾", for: .normal)
        sportPickerButton.backgroundColor = selectedSport.sportType.themeColor
    }

    @objc private func dismissFloatingView() {
        floatingView?.removeFromSuperview()
        floatingView = nil
    }

    private func showFloatingClimbingStats(data: [String: Any]) {
        dismissFloatingView()

        guard let type = data["type"] as? String,
              let sessions = data["sessions"] as? [ClimbingData] else { return }

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill

        let countLabel = createStatRow(icon: "figure.climbing", title: "완등 수", value: "\(sessions.count)")
        let routesLabel = createStatRow(icon: "checkmark.circle", title: "총 완등", value: "\(sessions.reduce(0) { $0 + $1.sentRoutes })")
        
        stack.addArrangedSubview(countLabel)
        stack.addArrangedSubview(routesLabel)

        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.centerX.equalTo(chartView)
            make.top.equalTo(chartView).offset(40)
            make.width.lessThanOrEqualToSuperview().offset(-32)
        }

        floatingView = container

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFloatingView))
        container.addGestureRecognizer(tapGesture)

        contentView.isUserInteractionEnabled = true
        let bgTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFloatingView))
        contentView.addGestureRecognizer(bgTapGesture)
    }

    private func createStatRow(icon: String, title: String, value: String) -> UIView {
        let row = UIView()
        row.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        row.layer.cornerRadius = 8

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.8)

        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        valueLabel.textColor = .white

        titleLabel.text = title
        valueLabel.text = value

        row.addSubview(iconView)
        row.addSubview(titleLabel)
        row.addSubview(valueLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalTo(valueLabel.snp.top).offset(-4)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
        }

        return row
    }
}

