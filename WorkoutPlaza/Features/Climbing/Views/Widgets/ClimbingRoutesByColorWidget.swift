//
//  ClimbingRoutesByColorWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Routes By Color Widget (난이도 색별 완등 현황)

class ClimbingRoutesByColorWidget: UIView, Selectable {
    // MARK: - Selectable Protocol Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .white {
        didSet { updateColors() }
    }
    var currentFontStyle: FontStyle = .system {
        didSet { updateFonts() }
    }
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "완등 현황"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.7)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Properties
    var initialSize: CGSize = .zero
    var baseFontSizes: [String: CGFloat] = [:]
    private var initialCenter: CGPoint = .zero
    private var routeData: [(colorHex: String, sent: Int, total: Int)] = []

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        itemIdentifier = "climbing_routes_by_color_\(UUID().uuidString)"
        setupView()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupGestures()
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(stackView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)

        isUserInteractionEnabled = true
    }

    // MARK: - Configure
    func configure(routes: [ClimbingRoute]) {
        // Group routes by color
        var colorGroups: [String: (sent: Int, total: Int)] = [:]

        for route in routes {
            let colorKey = route.colorHex ?? "#FFFFFF"
            var group = colorGroups[colorKey] ?? (sent: 0, total: 0)
            group.total += 1
            if route.isSent {
                group.sent += 1
            }
            colorGroups[colorKey] = group
        }

        // Sort by total count (descending)
        routeData = colorGroups.map { (colorHex: $0.key, sent: $0.value.sent, total: $0.value.total) }
            .sorted { $0.total > $1.total }

        updateStackView()
    }

    private func updateStackView() {
        // Clear existing rows
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let scaleFactor = calculateScaleFactor()
        let fontSize: CGFloat = 14 * scaleFactor

        for data in routeData {
            let rowView = createRowView(colorHex: data.colorHex, sent: data.sent, total: data.total, fontSize: fontSize)
            stackView.addArrangedSubview(rowView)
        }
    }

    private func createRowView(colorHex: String, sent: Int, total: Int, fontSize: CGFloat) -> UIView {
        let rowView = UIView()
        let scaleFactor = calculateScaleFactor()

        // Color circle - 크기도 스케일에 맞게 조정
        let circleSize: CGFloat = 12 * scaleFactor
        let colorCircle = UIView()
        colorCircle.backgroundColor = UIColor(hexString: colorHex) ?? .white
        colorCircle.layer.cornerRadius = circleSize / 2
        colorCircle.layer.borderWidth = 1
        colorCircle.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

        // Text label: "완등 수 / 총 수"
        let textLabel = UILabel()
        textLabel.text = "\(sent) / \(total)"
        textLabel.font = currentFontStyle.font(size: fontSize, weight: .bold)
        textLabel.textColor = currentColor
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.5

        rowView.addSubview(colorCircle)
        rowView.addSubview(textLabel)

        colorCircle.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(circleSize)
        }

        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(colorCircle.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        let rowHeight: CGFloat = 20 * scaleFactor
        rowView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(rowHeight)
        }

        return rowView
    }

    // MARK: - Gesture Handlers
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        selectionDelegate?.itemWasSelected(self)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view, let superview = view.superview else { return }

        switch gesture.state {
        case .began:
            initialCenter = view.center
            if !isSelected {
                selectionDelegate?.itemWasSelected(self)
            }

        case .changed:
            let translation = gesture.translation(in: superview)
            let proposedCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )

            let snapStep: CGFloat = 5.0
            let width = view.frame.width
            let height = view.frame.height

            let proposedOriginX = proposedCenter.x - width / 2
            let proposedOriginY = proposedCenter.y - height / 2

            let snappedOriginX = round(proposedOriginX / snapStep) * snapStep
            let snappedOriginY = round(proposedOriginY / snapStep) * snapStep

            let snappedCenter = CGPoint(
                x: snappedOriginX + width / 2,
                y: snappedOriginY + height / 2
            )

            view.center = snappedCenter

            if isSelected {
                positionResizeHandles()
            }

        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        switch gesture.state {
        case .changed:
            let currentWidth = view.frame.width
            let currentHeight = view.frame.height
            let newWidth = currentWidth * gesture.scale
            let newHeight = currentHeight * gesture.scale

            let minSize: CGFloat = 80
            let maxSize: CGFloat = 500

            let clampedWidth = max(minSize, min(maxSize, newWidth))
            let clampedHeight = max(minSize, min(maxSize, newHeight))

            let center = view.center
            view.frame.size = CGSize(width: clampedWidth, height: clampedHeight)
            view.center = center

            updateStackView()
            gesture.scale = 1.0

            if isSelected {
                positionResizeHandles()
            }

        default:
            break
        }
    }

    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        currentColor = color
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        updateFonts()
    }

    func showSelectionState() {
        isSelected = true
        createResizeHandles()
        createSelectionBorder()
    }

    func hideSelectionState() {
        isSelected = false
        removeResizeHandles()
        removeSelectionBorder()
    }

    // MARK: - Update Methods
    func updateColors() {
        titleLabel.textColor = currentColor.withAlphaComponent(0.7)
        updateStackView()
    }

    func updateFonts() {
        let scaleFactor = calculateScaleFactor()
        titleLabel.font = currentFontStyle.font(size: 12 * scaleFactor, weight: .medium)
        updateStackView()
    }

    func calculateScaleFactor() -> CGFloat {
        // initialSize must be set externally before scaling works
        guard initialSize.width > 0 && initialSize.height > 0 else {
            return 1.0
        }

        guard bounds.width > 0 && bounds.height > 0 else {
            return 1.0
        }

        let widthScale = bounds.width / initialSize.width
        let heightScale = bounds.height / initialSize.height
        let averageScale = (widthScale + heightScale) / 2.0

        return min(max(averageScale, 0.5), 3.0)
    }

    // MARK: - Resize Handles
    private func createResizeHandles() {
        removeResizeHandles()

        let positions: [ResizeHandlePosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        for position in positions {
            let handle = ResizeHandleView(position: position)
            handle.parentView = self
            superview?.addSubview(handle)
            resizeHandles.append(handle)
        }

        positionResizeHandles()
    }

    private func removeResizeHandles() {
        resizeHandles.forEach { $0.removeFromSuperview() }
        resizeHandles.removeAll()
    }

    func positionResizeHandles() {
        let handleSize: CGFloat = 20
        let offset: CGFloat = handleSize / 2

        for handle in resizeHandles {
            switch handle.position {
            case .topLeft:
                handle.center = CGPoint(x: frame.minX - offset + handleSize/2, y: frame.minY - offset + handleSize/2)
            case .topRight:
                handle.center = CGPoint(x: frame.maxX + offset - handleSize/2, y: frame.minY - offset + handleSize/2)
            case .bottomLeft:
                handle.center = CGPoint(x: frame.minX - offset + handleSize/2, y: frame.maxY + offset - handleSize/2)
            case .bottomRight:
                handle.center = CGPoint(x: frame.maxX + offset - handleSize/2, y: frame.maxY + offset - handleSize/2)
            default:
                break
            }
        }
    }

    // MARK: - Selection Border
    private func createSelectionBorder() {
        removeSelectionBorder()

        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor.systemBlue.cgColor
        borderLayer.fillColor = nil
        borderLayer.lineWidth = 2
        borderLayer.lineDashPattern = [6, 4]
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(rect: bounds).cgPath
        layer.addSublayer(borderLayer)
        selectionBorderLayer = borderLayer
    }

    private func removeSelectionBorder() {
        selectionBorderLayer?.removeFromSuperlayer()
        selectionBorderLayer = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update fonts when size changes (during resize)
        if initialSize != .zero && bounds.size != initialSize {
            updateFonts()
        }

        selectionBorderLayer?.frame = bounds
        selectionBorderLayer?.path = UIBezierPath(rect: bounds).cgPath
        if isSelected {
            positionResizeHandles()
        }
    }
}
