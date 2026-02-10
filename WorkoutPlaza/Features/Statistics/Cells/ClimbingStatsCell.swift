//
//  ClimbingStatsCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

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
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        button.configuration = configuration
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    // Period Segment
    private let periodSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [WorkoutPlazaStrings.Statistics.Period.month, WorkoutPlazaStrings.Statistics.Period.year, WorkoutPlazaStrings.Statistics.Period.all])
        control.selectedSegmentIndex = 0
        control.backgroundColor = ColorSystem.divider
        control.selectedSegmentTintColor = ColorSystem.controlTint
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
        stats: ClimbingStatsData,
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
            (WorkoutPlazaStrings.Statistics.Sent.routes, "\(stats.sentRoutes)", "checkmark.circle", ColorSystem.primaryGreen),
            (WorkoutPlazaStrings.Statistics.Total.routes, "\(stats.totalRoutes)", "figure.climbing", ColorSystem.primaryGreen),
            (WorkoutPlazaStrings.Statistics.Success.rate, String(format: "%.0f", stats.successRate), "percent", ColorSystem.primaryGreen),
            (WorkoutPlazaStrings.Statistics.visits, WorkoutPlazaStrings.Statistics.Summary.count(stats.visitCount), "location", ColorSystem.primaryGreen)
        ]

        for item in summaryItems {
            let card = createSummaryCard(title: item.0, value: item.1, icon: item.2, color: item.3)
            summaryGridStack.addArrangedSubview(card)
        }

        // Gym stats
        gymStatsView.configure(with: gymStats)
    }

    private func updatePeriodLabel() {
        periodLabel.text = StatisticsFormatter.periodLabel(
            for: currentPeriod,
            year: currentYear,
            month: currentMonth
        )
    }

    private func updateChart(sessions: [ClimbingData]) {
        let chartData = computeClimbingChartData(sessions: sessions)

        switch currentPeriod {
        case .month:
            chartTitleLabel.text = WorkoutPlazaStrings.Statistics.Chart.Daily.sent
        case .year:
            chartTitleLabel.text = WorkoutPlazaStrings.Statistics.Chart.Monthly.sent
        case .all:
            chartTitleLabel.text = WorkoutPlazaStrings.Statistics.Chart.Yearly.sent
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
        let (startDate, _) = getDateRange(for: currentPeriod, offset: 0)

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

                let label = (month % 2 == 1) ? WorkoutPlazaStrings.Statistics.Month.label(month) : ""
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
                data.append(BarChartDataPoint(label: String(describing: year), value: Double(yearRoutes), color: ColorSystem.primaryGreen, workoutData: workoutData))
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

            let components = DateComponents(year: targetYear, month: targetMonth, day: 1)
            guard let startDate = calendar.date(from: components) else { return (now, now) }
            guard let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else { return (now, now) }
            return (startDate, endDate)

        case .year:
            let targetYear = currentYear + offset
            let components = DateComponents(year: targetYear, month: 1, day: 1)
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
                self.delegate?.handleSportChanged(sport)
            }
        }
        sportPickerButton.menu = UIMenu(children: actions)
        sportPickerButton.setTitle("\(selectedSport.displayName) ▾", for: .normal)
        sportPickerButton.backgroundColor = ColorSystem.controlTint
    }

    @objc private func dismissFloatingView() {
        floatingView?.removeFromSuperview()
        floatingView = nil
    }

    private func showFloatingClimbingStats(data: [String: Any]) {
        dismissFloatingView()

        guard let sessions = data["sessions"] as? [ClimbingData] else { return }

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill

        let countLabel = createStatRow(icon: "figure.climbing", title: WorkoutPlazaStrings.Statistics.Sent.count, value: "\(sessions.count)")
        let routesLabel = createStatRow(icon: "checkmark.circle", title: WorkoutPlazaStrings.Statistics.Total.sent, value: "\(sessions.reduce(0) { $0 + $1.sentRoutes })")

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
            make.top.equalToSuperview().offset(10)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-10)
        }

        return row
    }
}
