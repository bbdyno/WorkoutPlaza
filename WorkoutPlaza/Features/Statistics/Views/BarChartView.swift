//
//  BarChartView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

// MARK: - Bar Chart Data Point

struct BarChartDataPoint {
    let label: String
    let value: Double
    let color: UIColor

    init(label: String, value: Double, color: UIColor = ColorSystem.primaryBlue) {
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - Bar Chart View

class BarChartView: UIView {

    // MARK: - Properties

    private var dataPoints: [BarChartDataPoint] = []
    private var maxValue: Double = 0
    private var barViews: [UIView] = []
    private var labelViews: [UILabel] = []
    private var valueLabels: [UILabel] = []

    private let chartContainerView = UIView()
    private let labelsContainerView = UIView()

    private var barSpacing: CGFloat = 8
    private var barCornerRadius: CGFloat = 4
    private var showValueLabels: Bool = true
    private var valueFormatter: ((Double) -> String)?

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
        addSubview(chartContainerView)
        addSubview(labelsContainerView)

        chartContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(labelsContainerView.snp.top).offset(-8)
        }

        labelsContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(20)
        }
    }

    // MARK: - Configuration

    func configure(
        with data: [BarChartDataPoint],
        showValues: Bool = true,
        valueFormatter: ((Double) -> String)? = nil
    ) {
        self.dataPoints = data
        self.showValueLabels = showValues
        self.valueFormatter = valueFormatter
        self.maxValue = data.map { $0.value }.max() ?? 1

        // Ensure maxValue is at least 1 to avoid division by zero
        if maxValue == 0 { maxValue = 1 }

        rebuildChart()
    }

    // MARK: - Chart Building

    private func rebuildChart() {
        // Clear existing views
        barViews.forEach { $0.removeFromSuperview() }
        labelViews.forEach { $0.removeFromSuperview() }
        valueLabels.forEach { $0.removeFromSuperview() }
        barViews.removeAll()
        labelViews.removeAll()
        valueLabels.removeAll()

        guard !dataPoints.isEmpty else { return }

        let barCount = CGFloat(dataPoints.count)

        for (index, dataPoint) in dataPoints.enumerated() {
            // Bar background (empty state)
            let barBackground = UIView()
            barBackground.backgroundColor = ColorSystem.divider
            barBackground.layer.cornerRadius = barCornerRadius
            chartContainerView.addSubview(barBackground)

            // Bar fill
            let barView = UIView()
            barView.backgroundColor = dataPoint.color
            barView.layer.cornerRadius = barCornerRadius
            chartContainerView.addSubview(barView)
            barViews.append(barView)

            // Value label (on top of bar)
            if showValueLabels {
                let valueLabel = UILabel()
                valueLabel.font = .systemFont(ofSize: 10, weight: .medium)
                valueLabel.textColor = ColorSystem.subText
                valueLabel.textAlignment = .center

                if let formatter = valueFormatter {
                    valueLabel.text = formatter(dataPoint.value)
                } else {
                    valueLabel.text = dataPoint.value >= 1000
                        ? String(format: "%.1fk", dataPoint.value / 1000)
                        : String(format: "%.0f", dataPoint.value)
                }

                chartContainerView.addSubview(valueLabel)
                valueLabels.append(valueLabel)
            }

            // X-axis label
            let label = UILabel()
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = ColorSystem.subText
            label.textAlignment = .center
            label.text = dataPoint.label
            labelsContainerView.addSubview(label)
            labelViews.append(label)

            // Layout
            let indexFloat = CGFloat(index)

            barBackground.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.top.equalToSuperview().offset(20) // Space for value labels
                make.width.equalToSuperview().dividedBy(barCount).offset(-barSpacing)
                make.leading.equalToSuperview().offset(indexFloat * (bounds.width / barCount) + barSpacing / 2)
            }

            barView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.leading.trailing.equalTo(barBackground)
                let heightRatio = dataPoint.value / maxValue
                make.height.equalTo(barBackground).multipliedBy(max(heightRatio, 0.02)) // Min 2% height for visibility
            }

            if showValueLabels, index < valueLabels.count {
                valueLabels[index].snp.makeConstraints { make in
                    make.bottom.equalTo(barView.snp.top).offset(-4)
                    make.centerX.equalTo(barView)
                    make.width.equalTo(barBackground)
                }
            }

            label.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalToSuperview().dividedBy(barCount)
                make.leading.equalToSuperview().offset(indexFloat * (bounds.width / barCount))
            }
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        // Rebuild on layout changes to update bar widths
        if !dataPoints.isEmpty {
            rebuildChart()
        }
    }
}

// MARK: - Horizontal Bar Chart View (for Gym Stats)

class HorizontalBarChartView: UIView {

    // MARK: - Properties

    private var segments: [(color: UIColor, value: Double)] = []
    private var totalValue: Double = 0
    private var segmentViews: [UIView] = []

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
        backgroundColor = ColorSystem.divider
        layer.cornerRadius = 4
        clipsToBounds = true
    }

    // MARK: - Configuration

    func configure(with segments: [(color: UIColor, value: Double)]) {
        self.segments = segments
        self.totalValue = segments.reduce(0) { $0 + $1.value }
        rebuildSegments()
    }

    private func rebuildSegments() {
        segmentViews.forEach { $0.removeFromSuperview() }
        segmentViews.removeAll()

        guard totalValue > 0 else { return }

        var currentX: CGFloat = 0

        for segment in segments {
            let segmentView = UIView()
            segmentView.backgroundColor = segment.color
            addSubview(segmentView)
            segmentViews.append(segmentView)

            let widthRatio = CGFloat(segment.value / totalValue)

            segmentView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.equalToSuperview().offset(currentX)
                make.width.equalToSuperview().multipliedBy(widthRatio)
            }

            currentX += bounds.width * widthRatio
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rebuildSegments()
    }
}
