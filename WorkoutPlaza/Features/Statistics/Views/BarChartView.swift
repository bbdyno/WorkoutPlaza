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
    let workoutData: Any?

    init(label: String, value: Double, color: UIColor = ColorSystem.primaryBlue, workoutData: Any? = nil) {
        self.label = label
        self.value = value
        self.color = color
        self.workoutData = workoutData
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
    private var gridLines: [UIView] = []
    private var yAxisLabels: [UILabel] = []

    private let chartContainerView = UIView()
    private let labelsContainerView = UIView()
    private let xAxisContainerView = UIView()
    private let yAxisContainerView = UIView()

    private var barSpacing: CGFloat = 4
    private var showValueLabels: Bool = true
    private var valueFormatter: ((Double) -> String)?
    private var onBarTapped: ((Int, Any?) -> Void)?
    private var onFloatingViewDismiss: (() -> Void)?

    private var highlightedBarView: UIView?
    private var isLongPressing = false
    private var currentLongPressIndex: Int?

    private struct YAxisConfiguration {
        let upperBound: Double
        let step: Double
        let values: [Double]
    }

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
        addSubview(yAxisContainerView)
        addSubview(xAxisContainerView)

        yAxisContainerView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.equalTo(50)
            make.bottom.equalTo(xAxisContainerView.snp.top).offset(-8)
        }

        chartContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(yAxisContainerView.snp.trailing)
            make.trailing.equalToSuperview()
            make.bottom.equalTo(xAxisContainerView.snp.top).offset(-8)
        }

        xAxisContainerView.snp.makeConstraints { make in
            make.leading.equalTo(yAxisContainerView.snp.trailing)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(20)
        }

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        chartContainerView.addGestureRecognizer(longPressGesture)
    }

    // MARK: - Configuration

    func configure(
        with data: [BarChartDataPoint],
        showValues: Bool = true,
        valueFormatter: ((Double) -> String)? = nil,
        onBarTapped: ((Int, Any?) -> Void)? = nil,
        onFloatingViewDismiss: (() -> Void)? = nil
    ) {
        self.dataPoints = data
        self.showValueLabels = showValues
        self.valueFormatter = valueFormatter
        self.onBarTapped = onBarTapped
        self.onFloatingViewDismiss = onFloatingViewDismiss
        self.maxValue = data.map { $0.value }.max() ?? 1

        if maxValue == 0 { maxValue = 1 }

        rebuildChart()
    }

    // MARK: - Chart Building

    private func rebuildChart() {
        barViews.forEach { $0.removeFromSuperview() }
        labelViews.forEach { $0.removeFromSuperview() }
        valueLabels.forEach { $0.removeFromSuperview() }
        gridLines.forEach { $0.removeFromSuperview() }
        yAxisLabels.forEach { $0.removeFromSuperview() }
        barViews.removeAll()
        labelViews.removeAll()
        valueLabels.removeAll()
        gridLines.removeAll()
        yAxisLabels.removeAll()

        guard !dataPoints.isEmpty else { return }

        let barCount = CGFloat(dataPoints.count)
        let yAxis = makeYAxisConfiguration(for: maxValue, availableHeight: max(chartContainerView.bounds.height, 120))

        for yValue in yAxis.values {
            let yRatio = CGFloat(yValue / yAxis.upperBound)

            let gridLine = UIView()
            chartContainerView.addSubview(gridLine)
            gridLines.append(gridLine)

            gridLine.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-chartContainerView.bounds.height * yRatio)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(1)
            }

            let dashLayer = CAShapeLayer()
            dashLayer.strokeColor = ColorSystem.divider.withAlphaComponent(0.5).cgColor
            dashLayer.lineDashPattern = [4, 4]
            dashLayer.lineWidth = 1
            gridLine.layer.addSublayer(dashLayer)

            DispatchQueue.main.async {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: gridLine.bounds.width, y: 0.5))
                dashLayer.path = path
            }

            let yLabel = UILabel()
            yLabel.font = AppFont.statRegular(10)
            yLabel.textColor = ColorSystem.subText
            yLabel.textAlignment = .right
            yLabel.text = formatYAxisValue(yValue)
            yAxisContainerView.addSubview(yLabel)
            yAxisLabels.append(yLabel)

            yLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-8)
                make.centerY.equalTo(gridLine)
            }
        }

        for (index, dataPoint) in dataPoints.enumerated() {
            let barView = UIView()
            barView.backgroundColor = dataPoint.color
            barView.layer.cornerRadius = 0
            barView.isUserInteractionEnabled = true
            chartContainerView.addSubview(barView)
            barViews.append(barView)

            if showValueLabels && dataPoint.value > 0 {
                let valueLabel = UILabel()
                valueLabel.font = AppFont.statRegular(10)
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

            let indexFloat = CGFloat(index)

            barView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.width.equalToSuperview().dividedBy(barCount).offset(-barSpacing)
                make.leading.equalToSuperview().offset(indexFloat * (chartContainerView.bounds.width / barCount) + barSpacing / 2)
                let heightRatio = dataPoint.value / yAxis.upperBound
                make.height.equalTo(chartContainerView).multipliedBy(max(heightRatio, 0.02))
            }

            if showValueLabels && dataPoint.value > 0, index < valueLabels.count {
                valueLabels[index].snp.makeConstraints { make in
                    make.bottom.equalTo(barView.snp.top).offset(-4)
                    make.centerX.equalTo(barView)
                    make.width.equalTo(barView)
                }
            }
        }

        layoutXAxisLabels()
    }

    private func layoutXAxisLabels() {
        labelViews.forEach { $0.removeFromSuperview() }
        labelViews.removeAll()

        let barCount = CGFloat(dataPoints.count)
        let labelInterval = max(1, Int(barCount / 6))

        for (index, dataPoint) in dataPoints.enumerated() {
            guard index % labelInterval == 0 || index == dataPoints.count - 1 else { continue }

            let label = UILabel()
            label.font = AppFont.bodySemiBold(11)
            label.textColor = ColorSystem.subText
            label.textAlignment = .center
            label.text = dataPoint.label
            xAxisContainerView.addSubview(label)
            labelViews.append(label)

            let centerX = CGFloat(index) * (xAxisContainerView.bounds.width / barCount) + (xAxisContainerView.bounds.width / barCount) / 2

            label.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.centerX.equalToSuperview().offset(centerX - xAxisContainerView.bounds.width / 2)
            }
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: chartContainerView)

        switch gesture.state {
        case .began:
            isLongPressing = true
            WPLog.debug("Long press began")
            highlightNearestBar(at: location)

        case .changed:
            if isLongPressing {
                highlightNearestBar(at: location)
            }

        case .ended, .cancelled:
            WPLog.info("Long press ended")
            onFloatingViewDismiss?()
            isLongPressing = false
            clearHighlight()

        default:
            break
        }
    }

    private func findNearestBarIndex(at location: CGPoint) -> Int? {
        guard !chartContainerView.bounds.isEmpty else {
            WPLog.warning("Chart container bounds are empty")
            return nil
        }

        let barCount = CGFloat(dataPoints.count)
        let barWidth = chartContainerView.bounds.width / barCount
        let index = Int(location.x / barWidth)
        let validIndex = index >= 0 && index < dataPoints.count ? index : nil

        if let idx = validIndex {
            WPLog.debug("Found bar index: \(idx) at x: \(location.x)")
        } else {
            WPLog.debug("No valid bar at x: \(location.x), barCount: \(Int(barCount))")
        }

        return validIndex
    }

    private func highlightNearestBar(at location: CGPoint) {
        guard let index = findNearestBarIndex(at: location), index < barViews.count else {
            onFloatingViewDismiss?()
            clearHighlight()
            return
        }

        let newBarView = barViews[index]

        if highlightedBarView != newBarView {
            highlightedBarView?.layer.borderWidth = 0
            highlightedBarView = newBarView
            highlightedBarView?.layer.borderWidth = 2
            highlightedBarView?.layer.borderColor = ColorSystem.mainText.cgColor

            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            if dataPoints[index].value > 0 {
                WPLog.debug("Showing floating view for index: \(index)")
                onBarTapped?(index, dataPoints[index].workoutData)
            } else {
                onFloatingViewDismiss?()
            }

            WPLog.debug("Highlighted bar at index: \(index)")
        }
    }

    private func clearHighlight() {
        highlightedBarView?.layer.borderWidth = 0
        highlightedBarView = nil
    }

    private func makeYAxisConfiguration(for maxValue: Double, availableHeight: CGFloat) -> YAxisConfiguration {
        let safeMaxValue = max(maxValue, 1)
        let maxTickCount = max(3, min(5, Int(availableHeight / 44)))
        let rawStep = safeMaxValue / Double(maxTickCount - 1)
        let step = max(niceStep(for: rawStep), 1)
        let upperBound = max(step, ceil(safeMaxValue / step) * step)

        var values: [Double] = []
        var current: Double = 0
        while current <= upperBound + (step * 0.001) {
            values.append(current)
            current += step
        }

        return YAxisConfiguration(upperBound: upperBound, step: step, values: values)
    }

    private func niceStep(for rawStep: Double) -> Double {
        guard rawStep > 0 else { return 1 }

        let magnitude = pow(10.0, floor(log10(rawStep)))
        let normalized = rawStep / magnitude

        let niceNormalized: Double
        switch normalized {
        case ..<1.5:
            niceNormalized = 1
        case ..<3:
            niceNormalized = 2
        case ..<7:
            niceNormalized = 5
        default:
            niceNormalized = 10
        }

        return niceNormalized * magnitude
    }

    private func formatYAxisValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }

        if value == floor(value) {
            return "\(Int(value))km"
        }

        return String(format: "%.1fkm", value)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

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
