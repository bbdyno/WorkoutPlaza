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

    private let selectedDateHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter
    }()

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
        title = WorkoutPlazaStrings.Statistics.title

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
        let scrollOffset = collectionView.contentOffset
        currentSport = sport
        collectionView.setCollectionViewLayout(createCompositionalLayout(), animated: false)
        collectionView.reloadSections(IndexSet(integer: 0))
        collectionView.contentOffset = scrollOffset
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

    func refreshData() {
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
            self.runningWorkouts = workouts.filter { $0.workoutType == .running }

            for workout in self.runningWorkouts {
                let components = Calendar.current.dateComponents([.year, .month, .day], from: workout.startDate)
                self.runningDates.insert(components)
                self.workoutsByDate[components, default: []].insert(.running)
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        externalRunningWorkouts = ExternalWorkoutManager.shared.getAllWorkouts().filter { $0.workoutData.type == .running }
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

    private func computeRunningChartData(barColor: UIColor = ColorSystem.primaryBlue) -> [BarChartDataPoint] {
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
                data.append(BarChartDataPoint(label: label, value: dayDistance, color: barColor, workoutData: workoutData))
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

                let label = (month % 2 == 1) ? WorkoutPlazaStrings.Statistics.Month.label(month) : ""
                let workoutData: Any? = monthCount > 0 ? [
                    "distance": monthDistance,
                    "duration": monthDuration,
                    "count": monthCount,
                    "month": month
                ] : nil
                data.append(BarChartDataPoint(label: label, value: monthDistance, color: barColor, workoutData: workoutData))
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
                data.append(BarChartDataPoint(label: String(describing: year), value: yearDistance, color: barColor, workoutData: workoutData))
            }
            return data
        }
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

    private func computeRunningSummary(tierColor: UIColor = ColorSystem.primaryBlue) -> [StatsSummaryItem] {
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
            ? WorkoutPlazaStrings.Home.Duration.hours(durationHours, durationMinutes)
            : WorkoutPlazaStrings.Home.Weekly.Time.minutes(durationMinutes)

        let paceMinutes = Int(avgPace)
        let paceSeconds = Int((avgPace - Double(paceMinutes)) * 60)
        let paceString = String(format: "%d'%02d\"", paceMinutes, paceSeconds)

        return [
            StatsSummaryItem(title: WorkoutPlazaStrings.Statistics.Summary.distance, value: String(format: "%.1f km", distanceKm), icon: "arrow.left.and.right", color: tierColor),
            StatsSummaryItem(title: WorkoutPlazaStrings.Statistics.Summary.duration, value: durationString, icon: "clock", color: tierColor),
            StatsSummaryItem(title: WorkoutPlazaStrings.Statistics.Summary.Avg.pace, value: paceString, icon: "speedometer", color: tierColor),
            StatsSummaryItem(title: WorkoutPlazaStrings.Statistics.Running.count, value: WorkoutPlazaStrings.Statistics.Summary.count(totalWorkouts), icon: "flame", color: tierColor)
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

                let label = (monthOffset % 2 == 0) ? WorkoutPlazaStrings.Statistics.Month.label(monthOffset + 1) : ""
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
            StatsSummaryItem(title: WorkoutPlazaStrings.Statistics.Sent.routes, value: "\(sentRoutes)", icon: "checkmark.circle", color: ColorSystem.primaryGreen),
            StatsSummaryItem(title: WorkoutPlazaStrings.Statistics.Total.routes, value: "\(totalRoutes)", icon: "figure.climbing", color: ColorSystem.primaryGreen),
            StatsSummaryItem(title: WorkoutPlazaStrings.Statistics.Success.rate, value: String(format: "%.0f", successRate), icon: "percent", color: ColorSystem.primaryGreen),
            StatsSummaryItem(title: WorkoutPlazaStrings.Statistics.visits, value: WorkoutPlazaStrings.Statistics.Summary.count(totalVisits), icon: "location", color: ColorSystem.primaryGreen)
        ]
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

        // Group sessions by gym brand name
        var gymSessions: [String: [ClimbingData]] = [:]

        for session in climbingSessions {
            if session.sessionDate >= startDate && session.sessionDate <= endDate {
                // gymName is brand name (e.g. "더클라임"), use it for grouping
                let brandName = session.gymName.isEmpty ? WorkoutPlazaStrings.Statistics.Gym.fallback : session.gymName
                gymSessions[brandName, default: []].append(session)
            }
        }

        WPLog.info("Gym stats computed: \(gymSessions.count) unique gym groups")
        for (key, sessions) in gymSessions {
            WPLog.debug("  - \(key): \(sessions.count) sessions")
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
                let chartData = computeRunningChartData(barColor: ColorSystem.primaryGreen)
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
            cell.configure(icon: "calendar", title: WorkoutPlazaStrings.Statistics.No.records, subtitle: WorkoutPlazaStrings.Statistics.No.Records.hint, date: Date(), color: .secondaryLabel)
        } else {
            let item = filteredItems[indexPath.item]
            if let workout = item.data as? WorkoutData {
                cell.configure(
                    icon: "figure.run",
                    title: WorkoutPlazaStrings.Workout.running,
                    subtitle: String(format: "%.1fkm", workout.distance / 1000),
                    date: workout.startDate,
                    color: ColorSystem.primaryBlue
                )
            } else if let externalWorkout = item.data as? ExternalWorkout {
                cell.configure(
                    icon: "figure.run",
                    title: WorkoutPlazaStrings.Workout.running,
                    subtitle: String(format: "%.1fkm", externalWorkout.workoutData.distance / 1000),
                    date: externalWorkout.workoutData.startDate,
                    color: ColorSystem.primaryBlue
                )
            } else if let session = item.data as? ClimbingData {
                let displayName = session.gymDisplayName.isEmpty ? WorkoutPlazaStrings.Workout.climbing : session.gymDisplayName
                cell.configure(
                    icon: "figure.climbing",
                    title: displayName,
                    subtitle: WorkoutPlazaStrings.Statistics.Climbing.Sent.count(session.sentRoutes),
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
            if let selectedDate = selectedDate, let date = Calendar.current.date(from: selectedDate) {
                header.titleLabel.text = selectedDateHeaderFormatter.string(from: date)
            } else {
                header.titleLabel.text = WorkoutPlazaStrings.Statistics.Date.Select.hint
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
            } else if let externalWorkout = item.data as? ExternalWorkout {
                let detailVC = RunningDetailViewController()
                detailVC.externalWorkout = externalWorkout
                let nav = UINavigationController(rootViewController: detailVC)
                present(nav, animated: true)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.section == 3 else { return nil }

        let items = filteredItems
        guard indexPath.item < items.count else { return nil }

        let item = items[indexPath.item]

        // Only allow deletion for climbing sessions
        guard item.type == .climbing else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }

            let deleteAction = UIAction(title: WorkoutPlazaStrings.Common.delete, image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.deleteItem(at: indexPath, item: item)
            }

            return UIMenu(title: "", children: [deleteAction])
        }
    }

    private func deleteItem(at indexPath: IndexPath, item: (type: SportType, data: Any, date: Date)) {
        guard item.type == .climbing else { return }
        guard let session = item.data as? ClimbingData else { return }

        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Statistics.Delete.Climbing.title,
            message: WorkoutPlazaStrings.Statistics.Delete.Climbing.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.delete, style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            ClimbingDataManager.shared.deleteSession(id: session.id)
            self.refreshData()
        })

        present(alert, animated: true)
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
