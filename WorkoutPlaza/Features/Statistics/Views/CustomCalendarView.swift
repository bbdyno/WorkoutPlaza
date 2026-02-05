//
//  CustomCalendarView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

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
