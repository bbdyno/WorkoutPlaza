//
//  BaseStatWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Base Stat Widget
class BaseStatWidget: UIView, Selectable {

    // MARK: - Selectable Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .white {
        didSet {
            updateColors()
        }
    }
    var currentFontStyle: FontStyle = .system {
        didSet {
            updateFonts()
        }
    }
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?

    // Font scaling properties
    var initialSize: CGSize = .zero
    var baseFontSizes: [String: CGFloat] = [:]  // labelName: baseSize
    var isGroupManaged: Bool = false  // Prevents auto font scaling when inside a group

    // Movement properties
    private var initialCenter: CGPoint = .zero

    // MARK: - UI Components
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: LayoutConstants.titleFontSize, weight: .medium)
        label.textColor = .white.withAlphaComponent(LayoutConstants.secondaryAlpha)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = LayoutConstants.minimumScaleFactor
        return label
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: LayoutConstants.valueFontSize, weight: .bold)
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = LayoutConstants.minimumScaleFactor
        return label
    }()

    let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: LayoutConstants.unitFontSize, weight: .regular)
        label.textColor = .white.withAlphaComponent(LayoutConstants.secondaryAlpha)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = LayoutConstants.minimumScaleFactor
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Background, shadow, and border removed for clean look
        backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LayoutConstants.standardPadding)
            make.leading.trailing.equalToSuperview().inset(LayoutConstants.standardPadding)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(LayoutConstants.standardPadding)
        }

        unitLabel.snp.makeConstraints { make in
            make.bottom.equalTo(valueLabel.snp.bottom).offset(-2)
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualToSuperview().inset(LayoutConstants.standardPadding)
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
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view, let superview = view.superview else { return }

        switch gesture.state {
        case .began:
            initialCenter = view.center
            // Select this widget immediately when drag starts
            if !isSelected {
                selectionDelegate?.itemWasSelected(self)
            }

        case .changed:
            let translation = gesture.translation(in: superview)
            
            // Calculate new proposed center based on initial center + total translation
            let proposedCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )
            
            // Snap to grid based on origin
            let snapStep: CGFloat = LayoutConstants.snapStep
            let width = view.frame.width
            let height = view.frame.height
            
            // Convert center to origin
            let proposedOriginX = proposedCenter.x - width / 2
            let proposedOriginY = proposedCenter.y - height / 2
            
            // Snap origin
            let snappedOriginX = round(proposedOriginX / snapStep) * snapStep
            let snappedOriginY = round(proposedOriginY / snapStep) * snapStep
            
            // Convert snapped origin back to center
            let snappedCenter = CGPoint(
                x: snappedOriginX + width / 2,
                y: snappedOriginY + height / 2
            )
            
            view.center = snappedCenter
            
            // Update handles position
            if isSelected {
                positionResizeHandles()
            }

        case .ended, .cancelled:
            // Notify widget movement complete
            NotificationCenter.default.post(name: .widgetDidMove, object: nil)

        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
            
            if isSelected {
                positionResizeHandles()
            }
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        selectionDelegate?.itemWasSelected(self)
    }

    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        currentColor = color
        updateColors()
    }

    func updateColors() {
        valueLabel.textColor = currentColor
        titleLabel.textColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
        unitLabel.textColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
    }

    func updateFonts() {
        // Store base font sizes if not already stored
        if baseFontSizes.isEmpty {
            baseFontSizes["title"] = LayoutConstants.titleFontSize
            baseFontSizes["value"] = LayoutConstants.valueFontSize
            baseFontSizes["unit"] = LayoutConstants.unitFontSize
        }

        // Calculate scale factor based on current size
        let scaleFactor = calculateScaleFactor()

        let titleSize = (baseFontSizes["title"] ?? LayoutConstants.titleFontSize) * scaleFactor
        let valueSize = (baseFontSizes["value"] ?? LayoutConstants.valueFontSize) * scaleFactor
        let unitSize = (baseFontSizes["unit"] ?? LayoutConstants.unitFontSize) * scaleFactor

        titleLabel.font = currentFontStyle.font(size: titleSize, weight: .medium)
        valueLabel.font = currentFontStyle.font(size: valueSize, weight: .bold)
        unitLabel.font = currentFontStyle.font(size: unitSize, weight: .regular)

        WPLog.debug("Font updated: style=\(currentFontStyle.displayName), scale=\(scaleFactor), valueSize=\(valueSize)")

        // Auto-resize to fit content if font style changed
        autoResizeToFitContent()
    }

    // MARK: - Auto Resize
    func autoResizeToFitContent() {
        // Force layout to get accurate label sizes
        layoutIfNeeded()

        // Calculate required size based on label content
        let titleHeight = titleLabel.intrinsicContentSize.height
        let valueHeight = valueLabel.intrinsicContentSize.height
        let unitHeight = unitLabel.intrinsicContentSize.height

        let valuePlusUnit = max(valueHeight, unitHeight)

        // Calculate total height needed (with padding)
        let topPadding: CGFloat = LayoutConstants.standardPadding
        let bottomPadding: CGFloat = LayoutConstants.standardPadding
        let titleToValueSpacing: CGFloat = 4

        let requiredHeight = topPadding + titleHeight + titleToValueSpacing + valuePlusUnit + bottomPadding

        // Calculate required width based on content
        let titleWidth = titleLabel.intrinsicContentSize.width
        let valueWidth = valueLabel.intrinsicContentSize.width + unitLabel.intrinsicContentSize.width + 4
        let requiredContentWidth = max(titleWidth, valueWidth)

        let sidePadding: CGFloat = LayoutConstants.standardPadding * 2
        let requiredWidth = requiredContentWidth + sidePadding

        // Only resize if content doesn't fit in current frame
        let currentWidth = bounds.width
        let currentHeight = bounds.height

        var newWidth = currentWidth
        var newHeight = currentHeight

        // Expand if content doesn't fit, but don't auto-shrink
        // This prevents the widget from shrinking when user intentionally makes it larger
        let minWidth: CGFloat = LayoutConstants.minWidth
        let minHeight: CGFloat = LayoutConstants.minHeight

        if requiredWidth > currentWidth {
            newWidth = max(requiredWidth, minWidth)
        }

        if requiredHeight > currentHeight {
            newHeight = max(requiredHeight, minHeight)
        }

        // Only update if size changed significantly
        if abs(newWidth - currentWidth) > LayoutConstants.significantSizeChange2pt || abs(newHeight - currentHeight) > LayoutConstants.significantSizeChange2pt {
            let newFrame = CGRect(
                x: frame.origin.x,
                y: frame.origin.y,
                width: newWidth,
                height: newHeight
            )

            frame = newFrame

            // Update initial size to prevent scaling issues
            initialSize = newFrame.size

            // Update selection handles if selected
            if isSelected {
                positionResizeHandles()
            }

            WPLog.debug("Auto-resized widget: \(currentWidth)x\(currentHeight) -> \(newWidth)x\(newHeight)")
        }
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        // Store initial size when font is first applied
        if initialSize == .zero {
            initialSize = bounds.size
        }
        updateFonts()
    }

    func calculateScaleFactor() -> CGFloat {
        guard initialSize != .zero else {
            // If initial size not set, use current size as initial
            initialSize = bounds.size
            return 1.0
        }

        // Calculate scale based on width and height change
        let widthScale = bounds.width / initialSize.width
        let heightScale = bounds.height / initialSize.height

        // Use the smaller scale factor to prevent text overflow
        // This ensures text fits within the available space without causing extra padding
        let minScale = min(widthScale, heightScale)

        // Clamp scale factor between minimum and maximum
        return min(max(minScale, LayoutConstants.minimumAllowedScale), LayoutConstants.maximumScaleFactor)
    }

    /// Update fonts with a specific scale factor (used by group resize)
    /// This method doesn't call autoResizeToFitContent to prevent resize feedback loops
    func updateFontsWithScale(_ scale: CGFloat) {
        if baseFontSizes.isEmpty {
            baseFontSizes["title"] = LayoutConstants.titleFontSize
            baseFontSizes["value"] = LayoutConstants.valueFontSize
            baseFontSizes["unit"] = LayoutConstants.unitFontSize
        }

        let clampedScale = min(max(scale, LayoutConstants.minimumAllowedScale), LayoutConstants.maximumScaleFactor)

        let titleSize = (baseFontSizes["title"] ?? LayoutConstants.titleFontSize) * clampedScale
        let valueSize = (baseFontSizes["value"] ?? LayoutConstants.valueFontSize) * clampedScale
        let unitSize = (baseFontSizes["unit"] ?? LayoutConstants.unitFontSize) * clampedScale

        titleLabel.font = currentFontStyle.font(size: titleSize, weight: .medium)
        valueLabel.font = currentFontStyle.font(size: valueSize, weight: .bold)
        unitLabel.font = currentFontStyle.font(size: unitSize, weight: .regular)
    }

    // MARK: - Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Check if touch is on a resize handle first
        for handle in resizeHandles {
            let handlePoint = convert(point, to: handle)
            if handle.point(inside: handlePoint, with: event) {
                return handle
            }
        }

        // Otherwise, return default behavior
        return super.hitTest(point, with: event)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // Update fonts when size changes significantly
        // This prevents excessive font updates during small resize adjustments
        // But not when managed by a group - group handles font scaling
        if !isGroupManaged && initialSize != .zero {
            let sizeDelta = abs(bounds.width - initialSize.width) + abs(bounds.height - initialSize.height)
            if sizeDelta > LayoutConstants.significantSizeChange {
                updateFonts()
            }
        }

        if isSelected {
            positionResizeHandles()
        }
    }
}
