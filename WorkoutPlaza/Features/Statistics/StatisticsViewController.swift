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
        cv.register(StatsSummaryCell.self, forCellWithReuseIdentifier: StatsSummaryCell.identifier)
        cv.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
        cv.register(RecentSessionCell.self, forCellWithReuseIdentifier: RecentSessionCell.identifier)
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
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Statistics"
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            if sectionIndex == 0 {
                // Summary Section: 2 columns
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(120))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(120))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16)
                return section
            } else if sectionIndex == 1 {
                // Calendar Section
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(400))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(400))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16)
                return section
            } else {
                // Recent Sessions Section: List
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
        }
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
        // Mock async for external if needed, but currently synchronous
        externalRunningWorkouts = ExternalWorkoutManager.shared.getAllWorkouts().filter { $0.workoutData.type == "러닝" }
        for workout in externalRunningWorkouts {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: workout.workoutData.startDate)
            runningDates.insert(components)
            workoutsByDate[components, default: []].insert(.running)
        }
        dispatchGroup.leave()
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            // Default selected date to today if not set
            if self?.selectedDate == nil {
                self?.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            }
            self?.collectionView.reloadData()
        }
    }
    
    // Computed property to get filtered workouts for selected date
    private var filteredItems: [(type: SportType, data: Any, date: Date)] {
        guard let dateComponents = selectedDate,
              let date = Calendar.current.date(from: dateComponents) else { return [] }
        
        let queryComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        
        var items: [(SportType, Any, Date)] = []
        
        // Filter Climbing
        for session in climbingSessions {
             let sessionDate = Calendar.current.dateComponents([.year, .month, .day], from: session.sessionDate)
             if sessionDate == queryComponents {
                 items.append((.climbing, session, session.sessionDate))
             }
        }
        
        // Filter Running
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
        
        return items.sorted(by: { $0.2 > $1.2 })
    }
}

// MARK: - UICollectionViewDataSource

extension StatisticsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3 // Summary, Calendar, Recent(Filtered)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 2 // Running, Climbing
        } else if section == 1 {
            return 1 // Calendar View
        } else {
            return max(1, filteredItems.count) // Show empty state if needed, but simplified for now
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatsSummaryCell.identifier, for: indexPath) as! StatsSummaryCell
            if indexPath.item == 0 {
                let totalDistance = (runningWorkouts.reduce(0) { $0 + $1.distance } + externalRunningWorkouts.reduce(0) { $0 + $1.workoutData.distance }) / 1000.0
                cell.configure(title: "Running", value: String(format: "%.1f km", totalDistance), icon: "figure.run", color: ColorSystem.primaryBlue)
            } else {
                let totalRoutes = climbingSessions.reduce(0) { $0 + $1.totalRoutes }
                cell.configure(title: "Climbing", value: "\(totalRoutes) Routes", icon: "figure.climbing", color: ColorSystem.primaryGreen)
            }
            return cell
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarCell.identifier, for: indexPath) as! CalendarCell
            cell.configure(delegate: self, selectedDate: selectedDate)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentSessionCell.identifier, for: indexPath) as! RecentSessionCell
            
            if filteredItems.isEmpty {
                 // Empty state placeholder reuse logic or simple check
                 cell.configure(icon: "calendar", title: "No Workouts", subtitle: "Select a date with activity", date: Date(), color: .secondaryLabel)
            } else {
                let item = filteredItems[indexPath.item]
                switch item.type {
                case .climbing:
                    if let session = item.data as? ClimbingData {
                        cell.configure(
                            icon: "figure.climbing",
                            title: session.gymName.isEmpty ? "Climbing" : session.gymName,
                            subtitle: "\(session.totalRoutes) Routes",
                            date: session.sessionDate,
                            color: ColorSystem.primaryGreen
                        )
                    }
                case .running:
                    if let workout = item.data as? WorkoutData {
                        cell.configure(
                            icon: "figure.run",
                            title: "Running",
                            subtitle: String(format: "%.1fkm", workout.distance/1000),
                            date: workout.startDate,
                            color: .systemBlue
                        )
                    } else if let workout = item.data as? ExternalWorkout {
                        cell.configure(
                            icon: "figure.run",
                            title: "Running (Ext)",
                            subtitle: String(format: "%.1fkm", workout.workoutData.distance/1000),
                            date: workout.workoutData.startDate,
                            color: .systemBlue
                        )
                    }
                default: break
                }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
        if indexPath.section == 2 {
            if let date = selectedDate, let month = date.month, let day = date.day {
                header.titleLabel.text = "\(month)월 \(day)일"
            } else {
                header.titleLabel.text = "선택된 날짜"
            }
        } else {
            header.titleLabel.text = ""
        }
        return header
    }
}

extension StatisticsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Only handle taps in Recent Sessions section (Section 2)
        guard indexPath.section == 2 else { return }
        
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
             // Running Detail
             if let workout = item.data as? WorkoutData {
                 let detailVC = RunningDetailViewController()
                 detailVC.workoutData = workout
                 let nav = UINavigationController(rootViewController: detailVC)
                 present(nav, animated: true)
             } else if let externalWorkout = item.data as? ExternalWorkout {
                 // For now, minimal support or ignore external
                 // Or map ExternalWorkout to WorkoutData if compatible
             }
            
        default: break
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
        
        var colors: [UIColor] = []
        if types.contains(.running) { colors.append(ColorSystem.primaryBlue) }
        if types.contains(.climbing) { colors.append(ColorSystem.primaryGreen) }
        // Add other types if any
        
        return colors
    }
    
    func calendarView(_ view: CustomCalendarView, didSelectDate dateComponents: DateComponents) {
        self.selectedDate = dateComponents
        
        // Since we are using Compositional Layout, reloadData is fine but reloadSections is better for anims
        UIView.performWithoutAnimation {
            self.collectionView.reloadSections(IndexSet(integer: 2))
        }
    }
}


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
        calendarView.reloadDecorations() // ensure dots update
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
            make.leading.equalToSuperview().offset(4) // Align with cell content inset if needed
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}


// MARK: - Custom Calendar Implementation (Embedded to ensure build)

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
        // Header
        prevOpenButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        nextOpenButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
        
        headerStack.addArrangedSubview(monthLabel)
        headerStack.addArrangedSubview(UIView()) // Flexible spacer
        headerStack.addArrangedSubview(prevOpenButton)
        headerStack.addArrangedSubview(nextOpenButton)
        headerStack.setCustomSpacing(20, after: prevOpenButton)
        
        addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Weekdays
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
        
        // CollectionView
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
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) // 1 = Sun, 2 = Mon...
        
        // Add empty days for padding
        for _ in 1..<firstWeekday {
            daysInMonth.append(nil)
        }
        
        // Add actual days
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
        
        // If selected date is not in current month, switch month
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
        // 7 columns
        let width = collectionView.bounds.width / 7.0
        return CGSize(width: width, height: width) // Square cells
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
        selectionBackground.layer.cornerRadius = 18  // Perfect circle (36 / 2)
        selectionBackground.layer.masksToBounds = true  // Clip gradient to circle
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
        
        // Reset
        dotStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        plusLabel.isHidden = true
        
        if isSelected {
            selectionBackground.isHidden = false
            selectionBackground.setGradientBackground()
            dayLabel.textColor = .white  // Selected cell - white text on blue background

            // Show white dots if selected? Or hide? Standard behavior usually dots become white or hidden.
            // Let's show white dots.
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
