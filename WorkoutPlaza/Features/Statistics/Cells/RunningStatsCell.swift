//
//  RunningStatsCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

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
        let control = UISegmentedControl(items: StatPeriod.allCases.map { $0.displayName })
        control.selectedSegmentIndex = 0
        control.backgroundColor = ColorSystem.divider
        control.selectedSegmentTintColor = ColorSystem.controlTint
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

        chartTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(datePickerStack.snp.bottom).offset(20)
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
    }

    func configure(
        period: StatPeriod,
        year: Int,
        month: Int,
        stats: RunningStatsData,
        chartData: [BarChartDataPoint],
        delegate: RunningStatsCellDelegate
    ) {
        self.delegate = delegate
        self.currentPeriod = period
        self.currentYear = year
        self.currentMonth = month

        updateSportPickerMenu(selectedSport: .running)

        periodSegmentedControl.selectedSegmentIndex = period.rawValue

        dateLabel.text = StatisticsFormatter.periodLabel(for: period, year: year, month: month)

        // Chart
        chartTitleLabel.text = period == .month ? WorkoutPlazaStrings.Statistics.Chart.daily : period == .year ? WorkoutPlazaStrings.Statistics.Chart.monthly : WorkoutPlazaStrings.Statistics.Chart.yearly
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

        let accentColor = ColorSystem.primaryGreen
        let summaryItems = [
            (WorkoutPlazaStrings.Statistics.Summary.distance, String(format: "%.1f km", stats.totalDistance), "arrow.left.and.right", accentColor),
            (WorkoutPlazaStrings.Statistics.Summary.duration, stats.totalTime, "clock", accentColor),
            (WorkoutPlazaStrings.Statistics.Summary.Avg.pace, stats.avgPace, "speedometer", accentColor),
            (WorkoutPlazaStrings.Statistics.Running.count, WorkoutPlazaStrings.Statistics.Summary.count(stats.runCount), "flame", accentColor)
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
              let count = stats["count"] as? Int else { return }

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        let countLabel = createStatRow(
            icon: "figure.run",
            title: WorkoutPlazaStrings.Statistics.Running.count,
            value: WorkoutPlazaStrings.Statistics.Summary.count(count)
        )
        let distanceLabel = createStatRow(icon: "arrow.left.and.right", title: WorkoutPlazaStrings.Statistics.Total.distance, value: String(format: "%.1f km", distance))
        let timeLabel = createStatRow(icon: "clock", title: WorkoutPlazaStrings.Statistics.Total.time, value: formatDuration(duration))

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
            make.top.greaterThanOrEqualToSuperview().offset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
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
                self.delegate?.handleSportChanged(sport)
            }
        }
        sportPickerButton.menu = UIMenu(children: actions)
        sportPickerButton.setTitle("\(selectedSport.displayName) ▾", for: .normal)
        sportPickerButton.backgroundColor = ColorSystem.controlTint
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
