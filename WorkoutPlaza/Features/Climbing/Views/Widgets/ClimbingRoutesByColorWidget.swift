//
//  ClimbingRoutesByColorWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Routes By Color Widget (난이도 색별 완등 현황)

class ClimbingRoutesByColorWidget: UIView, Selectable, WidgetContentAlignable {
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
    var rotationIndicatorLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?
    // rotation and isRotating are provided by Selectable protocol default implementation
    private(set) var contentAlignment: WidgetContentAlignment = .left

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Widget.Climbing.Routes.By.color
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.7)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.2
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
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
        let fontSize: CGFloat = 16 * scaleFactor

        for data in routeData {
            let rowView = createRowView(colorHex: data.colorHex, sent: data.sent, total: data.total, fontSize: fontSize)
            stackView.addArrangedSubview(rowView)
        }
    }

    private func createRowView(colorHex: String, sent: Int, total: Int, fontSize: CGFloat) -> UIView {
        let rowView = UIView()
        let scaleFactor = calculateScaleFactor()

        // Color circle - 크기도 스케일에 맞게 조정
        let circleSize: CGFloat = 24 * scaleFactor
        let colorCircle = UIView()
        colorCircle.backgroundColor = UIColor(hex: colorHex) ?? .white
        colorCircle.layer.cornerRadius = circleSize / 2
        colorCircle.clipsToBounds = true
        colorCircle.layer.borderWidth = 1
        colorCircle.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

        // Text label: "완등 수 / 총 수"
        let textLabel = UILabel()
        textLabel.text = "\(sent) / \(total)"
        textLabel.font = currentFontStyle.font(size: fontSize, weight: .bold)
        textLabel.textColor = currentColor
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.2

        rowView.addSubview(colorCircle)
        rowView.addSubview(textLabel)

        colorCircle.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(circleSize)
        }

        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(colorCircle.snp.trailing).offset(2)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        let rowHeight: CGFloat = 26 * scaleFactor
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

            NotificationCenter.default.post(
                name: .widgetDidMove,
                object: self,
                userInfo: [WidgetMoveNotificationUserInfoKey.phase: WidgetMovePhase.changed.rawValue]
            )

        case .ended, .cancelled:
            NotificationCenter.default.post(
                name: .widgetDidMove,
                object: self,
                userInfo: [WidgetMoveNotificationUserInfoKey.phase: WidgetMovePhase.ended.rawValue]
            )

        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard DevSettings.shared.isPinchToResizeEnabled else { return }
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

    func applyContentAlignment(_ alignment: WidgetContentAlignment) {
        contentAlignment = alignment
        titleLabel.textAlignment = alignment.textAlignment

        switch alignment {
        case .left:
            stackView.alignment = .leading
        case .center:
            stackView.alignment = .center
        case .right:
            stackView.alignment = .trailing
        }

        updateStackView()
    }

    func showSelectionState() {
        showSelectionState(multiSelectMode: false)
    }

    func showSelectionState(multiSelectMode: Bool) {
        isSelected = true
        createSelectionBorder()
        updateSelectionBorder()

        // In multi-select mode (group selection), don't show resize/rotation handles
        if !multiSelectMode {
            createResizeHandles()
            positionResizeHandles()
            bringSubviewsToFront()
        }
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

    var idealSize: CGSize {
        layoutIfNeeded()
        
        let titleSize = titleLabel.intrinsicContentSize
        
        var maxRowWidth: CGFloat = 0
        var totalStackHeight: CGFloat = 0
        
        // Calculate max width from subviews in stackView
        for view in stackView.arrangedSubviews {
            // Re-calculate assuming base sizes (scale=1)
            // Circle (24) + Spacing (2) + Text
            // We can approximate by checking the subviews of the row view
            if let label = view.subviews.first(where: { $0 is UILabel }) as? UILabel {
                let textWidth = label.intrinsicContentSize.width
                let rowWidth = 24 + 2 + textWidth
                maxRowWidth = max(maxRowWidth, rowWidth)
            }
            totalStackHeight += 26 // Row Height
        }
        
        let contentWidth = max(titleSize.width, maxRowWidth)
        let width = contentWidth + 24 // Padding
        
        let height = 8 + titleSize.height + 6 + totalStackHeight + 8
        
        return CGSize(width: max(width, 100), height: max(height, 80))
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

        // Use the smaller scale factor to prevent text overflow
        // This ensures text fits within the available space without causing extra padding
        let minScale = min(widthScale, heightScale)

        return max(minScale, 0.5)
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
        borderLayer.strokeColor = ColorSystem.primaryBlue.cgColor
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

        // Update fonts when size changes significantly (more than 5pt)
        // This prevents excessive font updates during small resize adjustments
        if initialSize != .zero {
            let sizeDelta = abs(bounds.width - initialSize.width) + abs(bounds.height - initialSize.height)
            if sizeDelta > 5 {
                updateFonts()
            }
        }

        selectionBorderLayer?.frame = bounds
        selectionBorderLayer?.path = UIBezierPath(rect: bounds).cgPath
        if isSelected {
            positionResizeHandles()
        }
    }
}
