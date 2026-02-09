//
//  GymStatsView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

// MARK: - Gym Stat Data

struct GymStatData {
    let gymName: String
    let visitCount: Int
    let totalRoutes: Int
    let sentRoutes: Int
    let routesByDifficulty: [(color: UIColor, count: Int)]

    var successRate: Double {
        guard totalRoutes > 0 else { return 0 }
        return Double(sentRoutes) / Double(totalRoutes) * 100
    }

    init(
        gymName: String,
        visitCount: Int,
        totalRoutes: Int,
        sentRoutes: Int,
        routesByDifficulty: [(color: UIColor, count: Int)]
    ) {
        self.gymName = gymName
        self.visitCount = visitCount
        self.totalRoutes = totalRoutes
        self.sentRoutes = sentRoutes
        self.routesByDifficulty = routesByDifficulty
    }
}

// MARK: - Gym Stats View

class GymStatsView: UIView {

    // MARK: - Properties

    private var gymStats: [GymStatData] = []

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Gym.Stats.title
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = ColorSystem.cardBackground
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous

        addSubview(titleLabel)
        addSubview(stackView)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Configuration

    func configure(with data: [GymStatData]) {
        self.gymStats = data

        // Clear existing views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add gym stat rows (limit to top 3 for space)
        let displayData = Array(data.prefix(3))

        for (index, gymStat) in displayData.enumerated() {
            let rowView = createGymStatRow(for: gymStat)
            stackView.addArrangedSubview(rowView)

            // Add separator except for last item
            if index < displayData.count - 1 {
                let separator = createSeparator()
                stackView.addArrangedSubview(separator)
            }
        }

        // Add empty state if no data
        if data.isEmpty {
            let emptyContainer = UIView()

            let emptyLabel = UILabel()
            emptyLabel.text = WorkoutPlazaStrings.Gym.Stats.empty
            emptyLabel.font = .systemFont(ofSize: 14, weight: .medium)
            emptyLabel.textColor = ColorSystem.subText
            emptyLabel.textAlignment = .center

            emptyContainer.addSubview(emptyLabel)
            emptyLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(20)
            }

            stackView.addArrangedSubview(emptyContainer)
        }
    }

    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = ColorSystem.divider
        separator.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        return separator
    }

    // MARK: - Row Creation

    private func createGymStatRow(for gymStat: GymStatData) -> UIView {
        let container = UIView()

        // Left side: Gym info
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 4
        infoStack.alignment = .leading

        let nameLabel = UILabel()
        nameLabel.text = gymStat.gymName.isEmpty ? WorkoutPlazaStrings.Statistics.Gym.fallback : gymStat.gymName
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = ColorSystem.mainText
        nameLabel.numberOfLines = 1

        let visitLabel = UILabel()
        visitLabel.text = WorkoutPlazaStrings.Gym.Stats.summary(gymStat.visitCount, gymStat.sentRoutes, gymStat.totalRoutes)
        visitLabel.font = .systemFont(ofSize: 13, weight: .regular)
        visitLabel.textColor = ColorSystem.subText

        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(visitLabel)



        // Difficulty bar with color dots
        let difficultyContainer = UIView()

        let difficultyBar = HorizontalBarChartView()
        let segments = gymStat.routesByDifficulty.map { (color: $0.color, value: Double($0.count)) }
        difficultyBar.configure(with: segments)

        // Color legend (horizontal scroll if needed)
        let legendScroll = UIScrollView()
        legendScroll.showsHorizontalScrollIndicator = false

        let legendStack = UIStackView()
        legendStack.axis = .horizontal
        legendStack.spacing = 12
        legendStack.alignment = .center

        for (color, count) in gymStat.routesByDifficulty where count > 0 {
            let dotView = createLegendItem(color: color, count: count)
            legendStack.addArrangedSubview(dotView)
        }

        legendScroll.addSubview(legendStack)
        legendStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        difficultyContainer.addSubview(difficultyBar)
        difficultyContainer.addSubview(legendScroll)

        difficultyBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(6)
        }

        legendScroll.snp.makeConstraints { make in
            make.top.equalTo(difficultyBar.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(20)
        }

        // Layout
        container.addSubview(infoStack)
        container.addSubview(difficultyContainer)

        infoStack.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        difficultyContainer.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        return container
    }

    private func createLegendItem(color: UIColor, count: Int) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 4
        container.alignment = .center

        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 5
        dot.snp.makeConstraints { make in
            make.width.height.equalTo(10)
        }

        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = .systemFont(ofSize: 12, weight: .medium)
        countLabel.textColor = ColorSystem.subText

        container.addArrangedSubview(dot)
        container.addArrangedSubview(countLabel)

        return container
    }
}

// MARK: - Gym Stats Cell (for CollectionView)

class GymStatsCell: UICollectionViewCell {
    static let identifier = "GymStatsCell"

    private let gymStatsView = GymStatsView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(gymStatsView)
        gymStatsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with data: [GymStatData]) {
        gymStatsView.configure(with: data)
    }
}
