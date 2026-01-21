//
//  TemplateGroupView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

// MARK: - Widget Group Type
enum WidgetGroupType: String, Codable {
    case myRecord = "MyRecord"
    case importedRecord = "ImportedRecord"

    var borderColor: UIColor {
        switch self {
        case .myRecord:
            return .systemBlue
        case .importedRecord:
            return .systemOrange
        }
    }

    var overlayColor: UIColor {
        switch self {
        case .myRecord:
            return UIColor.systemBlue.withAlphaComponent(0.05)
        case .importedRecord:
            return UIColor.systemOrange.withAlphaComponent(0.05)
        }
    }
}

class TemplateGroupView: UIView, Selectable {

    // MARK: - Selectable Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .systemBlue
    var currentFontStyle: FontStyle = .system  // Not directly used, but required by protocol
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?
    var initialSize: CGSize = .zero

    // MARK: - Group Properties
    private(set) var groupedItems: [UIView] = []
    private var originalItemFrames: [UIView: CGRect] = [:]
    private var originalGroupFrame: CGRect = .zero

    // MARK: - Group Type Properties
    private(set) var groupType: WidgetGroupType = .myRecord
    private(set) var groupLabel: String = ""
    private(set) var ownerName: String?
    private(set) var groupId: String = UUID().uuidString
    private(set) var isConfirmed: Bool = false  // Track if group is confirmed (check button pressed)

    private var overlayLayer: CAShapeLayer?

    private let ownerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemOrange
        label.textAlignment = .center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()

    private let checkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.tintColor = .systemGreen
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
        return button
    }()

    weak var groupDelegate: TemplateGroupDelegate?

    // MARK: - Initialization
    init(items: [UIView], frame: CGRect, groupType: WidgetGroupType = .myRecord, ownerName: String? = nil) {
        super.init(frame: frame)
        self.groupedItems = items
        // Store only the size for scaling calculations (origin should be 0,0)
        self.originalGroupFrame = CGRect(origin: .zero, size: frame.size)
        self.initialSize = frame.size
        self.groupType = groupType
        self.ownerName = ownerName

        if let owner = ownerName {
            self.groupLabel = "\(owner)의 기록"
        }

        setupView()
        addItemsToGroup()
        setupCheckButton()
        setupOwnerLabel()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Group Type Configuration
    func configure(groupType: WidgetGroupType, ownerName: String? = nil) {
        self.groupType = groupType
        self.ownerName = ownerName

        if let owner = ownerName {
            self.groupLabel = "\(owner)의 기록"
            ownerLabel.text = "  \(groupLabel)  "
            ownerLabel.textColor = groupType.borderColor
            ownerLabel.isHidden = false
        } else {
            ownerLabel.isHidden = true
        }

        // Update check button visibility based on group type
        if groupType == .importedRecord {
            checkButton.isHidden = true
        }

        updateOverlayStyle()
    }

    private func updateOverlayStyle() {
        overlayLayer?.fillColor = groupType.overlayColor.cgColor
        // No stroke by default - only shown during selection
    }

    private func setupOwnerLabel() {
        addSubview(ownerLabel)

        if let owner = ownerName {
            ownerLabel.text = "  \(owner)의 기록  "
            ownerLabel.textColor = groupType.borderColor
            ownerLabel.isHidden = false
            ownerLabel.frame = CGRect(x: 8, y: -24, width: 120, height: 20)
            ownerLabel.sizeToFit()
            ownerLabel.frame.size.height = 20
            ownerLabel.frame.size.width += 16
        }
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear

        // Add overlay to show group boundary
        let overlay = CAShapeLayer()
        overlay.fillColor = groupType.overlayColor.cgColor

        // Show dashed border for unconfirmed groups (both myRecord and importedRecord)
        overlay.strokeColor = groupType.borderColor.withAlphaComponent(0.5).cgColor
        overlay.lineWidth = 2
        overlay.lineDashPattern = [8, 4]

        layer.insertSublayer(overlay, at: 0)
        self.overlayLayer = overlay

        // Update path
        DispatchQueue.main.async {
            overlay.path = UIBezierPath(rect: self.bounds).cgPath
        }
    }

    private func addItemsToGroup() {
        for item in groupedItems {
            // Store original frame (in contentView coordinates)
            let originalFrame = item.frame

            // Convert to group coordinate system (relative to group's origin)
            let frameInGroup = CGRect(
                x: originalFrame.origin.x - self.frame.origin.x,
                y: originalFrame.origin.y - self.frame.origin.y,
                width: originalFrame.width,
                height: originalFrame.height
            )

            // Store the frame in group coordinates for proper scaling
            originalItemFrames[item] = frameInGroup

            // Mark widget as group-managed to prevent auto font scaling
            setGroupManaged(item, managed: true)

            // Add to group
            addSubview(item)
            item.frame = frameInGroup
        }
    }

    /// Set the isGroupManaged flag on a widget
    private func setGroupManaged(_ item: UIView, managed: Bool) {
        if let statWidget = item as? BaseStatWidget {
            statWidget.isGroupManaged = managed
        }
        if let textWidget = item as? TextWidget {
            textWidget.isGroupManaged = managed
        }
        if let locationWidget = item as? LocationWidget {
            locationWidget.isGroupManaged = managed
        }
    }

    private func setupCheckButton() {
        addSubview(checkButton)
        checkButton.frame = CGRect(x: bounds.width - 50, y: -50, width: 40, height: 40)
        checkButton.addTarget(self, action: #selector(checkButtonTapped), for: .touchUpInside)
        // Check button is visible for all group types until confirmed
    }

    private func setupGestures() {
        // Tap gesture for selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

        // Pan gesture for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)

        // Pinch gesture for resizing
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)

        isUserInteractionEnabled = true
    }

    // MARK: - Actions
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // If already selected, don't toggle - just keep selected
        if isSelected {
            return
        }
        selectionDelegate?.itemWasSelected(self)
    }

    private var initialCenter: CGPoint = .zero
    private var initialPinchBounds: CGRect = .zero
    private let snapStep: CGFloat = 5.0

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        switch gesture.state {
        case .began:
            initialPinchBounds = view.bounds

        case .changed:
            let scale = gesture.scale

            // Calculate new size maintaining aspect ratio
            let aspectRatio = initialPinchBounds.width / initialPinchBounds.height
            let rawWidth = initialPinchBounds.width * scale

            // Snap width to grid, then calculate height from aspect ratio
            let snappedWidth = round(rawWidth / snapStep) * snapStep
            let snappedHeight = snappedWidth / aspectRatio

            // Limit minimum and maximum sizes
            let minSize: CGFloat = 100
            let maxSize: CGFloat = 2000

            guard snappedWidth >= minSize && snappedWidth <= maxSize &&
                  snappedHeight >= minSize && snappedHeight <= maxSize else {
                return
            }

            // Scale from center - snap center position too
            let centerX = view.center.x
            let centerY = view.center.y
            let snappedCenterX = round(centerX / snapStep) * snapStep
            let snappedCenterY = round(centerY / snapStep) * snapStep

            view.bounds = CGRect(x: 0, y: 0, width: snappedWidth, height: snappedHeight)
            view.center = CGPoint(x: snappedCenterX, y: snappedCenterY)

        case .ended:
            // Update initial size for future scaling
            initialSize = bounds.size

        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view, let superview = superview else { return }

        switch gesture.state {
        case .began:
            initialCenter = view.center

        case .changed:
            let translation = gesture.translation(in: superview)

            // Calculate new proposed center
            let proposedCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )

            // Snap to grid based on origin
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

            // Update resize handles if selected
            if isSelected {
                positionResizeHandles()
            }

        case .ended, .cancelled:
            break

        default:
            break
        }
    }
    @objc private func checkButtonTapped() {
        // For imported groups, ungroup when check button is pressed
        if groupType == .importedRecord {
            // Hide check button with animation
            UIView.animate(withDuration: 0.2) {
                self.checkButton.alpha = 0
            } completion: { _ in
                self.checkButton.isHidden = true
                self.checkButton.alpha = 1
                // Request ungroup after animation
                self.groupDelegate?.templateGroupDidRequestUngroup(self)
            }
            return
        }

        // For my record groups, just confirm (keep grouped)
        isConfirmed = true

        // Hide dashed border
        overlayLayer?.strokeColor = UIColor.clear.cgColor
        overlayLayer?.lineWidth = 0

        // Hide check button after confirmation
        UIView.animate(withDuration: 0.2) {
            self.checkButton.alpha = 0
        } completion: { _ in
            self.checkButton.isHidden = true
            self.checkButton.alpha = 1
        }

        groupDelegate?.templateGroupDidConfirm(self)
    }

    /// Hide the check button (call when group is confirmed externally)
    func hideCheckButton() {
        checkButton.isHidden = true
        isConfirmed = true
        // Hide dashed border
        overlayLayer?.strokeColor = UIColor.clear.cgColor
        overlayLayer?.lineWidth = 0
    }

    /// Show the check button (call when group needs confirmation)
    func showCheckButton() {
        guard groupType != .importedRecord else { return }  // Never show for imported groups
        checkButton.isHidden = false
    }

    // MARK: - Group Resize
    override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size {
                updateItemPositionsAndSizes()
            }

            // Update check button position
            checkButton.frame.origin = CGPoint(x: bounds.width - 50, y: -50)
        }
    }

    private func updateItemPositionsAndSizes() {
        guard originalGroupFrame.width > 0 && originalGroupFrame.height > 0 else { return }

        let scaleX = bounds.width / originalGroupFrame.width
        let scaleY = bounds.height / originalGroupFrame.height

        // Use average scale for font sizing (maintains proportions)
        let averageScale = (scaleX + scaleY) / 2.0

        // Update each item's position and size proportionally
        for (item, originalFrame) in originalItemFrames {
            let newX = originalFrame.origin.x * scaleX
            let newY = originalFrame.origin.y * scaleY
            let newWidth = originalFrame.width * scaleX
            let newHeight = originalFrame.height * scaleY

            item.frame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)

            // Update fonts using group scale factor (prevents auto-resize feedback)
            if let statWidget = item as? BaseStatWidget {
                statWidget.updateFontsWithScale(averageScale)
            }

            if let textWidget = item as? TextWidget {
                textWidget.updateFontsWithScale(averageScale)
            }

            if let locationWidget = item as? LocationWidget {
                locationWidget.updateFontsWithScale(averageScale)
            }

            // Redraw route map
            if let routeMap = item as? RouteMapView {
                routeMap.layoutSubviews()
            }
        }
    }

    // MARK: - Ungroup
    func ungroupItems(to targetView: UIView) -> [UIView] {
        var items: [UIView] = []

        for item in groupedItems {
            // Convert frame back to target view coordinate system
            let frameInTargetView = convert(item.frame, to: targetView)
            item.removeFromSuperview()
            targetView.addSubview(item)
            item.frame = frameInTargetView

            // Reset group-managed flag so widget handles its own font scaling again
            setGroupManaged(item, managed: false)

            items.append(item)
        }

        return items
    }

    // MARK: - Selectable Methods
    func showSelectionState() {
        isSelected = true
        createSelectionBorder()
        createResizeHandles()
        positionResizeHandles()
        bringSubviewsToFront()

        // Hide overlay when selected (selection border is more prominent)
        overlayLayer?.isHidden = true

        // Show check button if not confirmed
        if !isConfirmed {
            showCheckButton()
        }
    }

    func hideSelectionState() {
        isSelected = false
        removeSelectionBorder()
        removeResizeHandles()

        // Hide overlay and border when deselected (confirmed groups stay clean)
        if isConfirmed {
            overlayLayer?.isHidden = true
        } else {
            // For unconfirmed groups, hide overlay but show check button
            overlayLayer?.isHidden = true
            showCheckButton()
        }
    }

    func applyColor(_ color: UIColor) {
        // Groups don't change color
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        // Groups don't use fonts, so this is a no-op
    }

    // MARK: - Dynamic Widget Management

    /// Add a widget to this group
    func addWidget(_ widget: UIView) {
        guard !groupedItems.contains(where: { $0 === widget }) else { return }

        // Get widget's current frame in group's coordinate system
        let frameInGroup: CGRect
        if let superview = widget.superview {
            frameInGroup = superview.convert(widget.frame, to: self)
        } else {
            frameInGroup = widget.frame
        }

        // Remove from current parent and add to group
        widget.removeFromSuperview()
        addSubview(widget)
        widget.frame = frameInGroup

        // Mark widget as group-managed
        setGroupManaged(widget, managed: true)

        // Store in arrays
        groupedItems.append(widget)
        originalItemFrames[widget] = frameInGroup

        // Recalculate group bounds
        recalculateBounds()
    }

    /// Remove a widget from this group
    func removeWidget(_ widget: UIView) {
        guard let index = groupedItems.firstIndex(where: { $0 === widget }) else { return }

        // Get frame in parent coordinate system before removing
        let frameInParent = convert(widget.frame, to: superview)

        // Remove from group
        widget.removeFromSuperview()
        groupedItems.remove(at: index)
        originalItemFrames.removeValue(forKey: widget)

        // Reset group-managed flag
        setGroupManaged(widget, managed: false)

        // If group still has items, recalculate bounds
        if !groupedItems.isEmpty {
            recalculateBounds()
        }

        // Return frame for re-adding to parent
        widget.frame = frameInParent
    }

    /// Recalculate group bounds based on current items
    func recalculateBounds() {
        guard !groupedItems.isEmpty else { return }

        // Find bounding rect of all items
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude

        for item in groupedItems {
            minX = min(minX, item.frame.minX)
            minY = min(minY, item.frame.minY)
            maxX = max(maxX, item.frame.maxX)
            maxY = max(maxY, item.frame.maxY)
        }

        // Add padding
        let padding: CGFloat = 16
        minX -= padding
        minY -= padding
        maxX += padding
        maxY += padding

        // Calculate offset needed to adjust item positions
        let offsetX = -minX
        let offsetY = -minY

        // Adjust item positions
        for item in groupedItems {
            item.frame.origin.x += offsetX
            item.frame.origin.y += offsetY
            originalItemFrames[item] = item.frame
        }

        // Update group frame
        let newWidth = maxX - minX
        let newHeight = maxY - minY

        // Adjust group position in parent
        frame = CGRect(
            x: frame.origin.x + minX,
            y: frame.origin.y + minY,
            width: newWidth,
            height: newHeight
        )

        originalGroupFrame = CGRect(origin: .zero, size: frame.size)
        initialSize = frame.size

        // Update overlay path
        overlayLayer?.path = UIBezierPath(rect: bounds).cgPath

        // Update owner label position
        if !ownerLabel.isHidden {
            ownerLabel.frame.origin = CGPoint(x: 8, y: -24)
        }
    }

    /// Check if a widget can be added to this group based on type compatibility
    func canAcceptWidget(_ widget: UIView, widgetGroupType: WidgetGroupType?) -> Bool {
        // If widget has a group type, it must match this group's type
        if let widgetType = widgetGroupType {
            return widgetType == self.groupType
        }

        // Widgets without a group type can be added to myRecord groups only
        return self.groupType == .myRecord
    }

    /// Get group info for serialization
    func getGroupInfo() -> (id: String, type: WidgetGroupType, ownerName: String?, widgetIds: [String], frame: CGRect) {
        let widgetIds = groupedItems.compactMap { ($0 as? Selectable)?.itemIdentifier }
        return (groupId, groupType, ownerName, widgetIds, frame)
    }

    // MARK: - Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Check check button first
        if !checkButton.isHidden {
            let buttonPoint = convert(point, to: checkButton)
            if checkButton.point(inside: buttonPoint, with: event) {
                return checkButton
            }
        }

        // Check resize handles
        for handle in resizeHandles {
            let handlePoint = convert(point, to: handle)
            if handle.point(inside: handlePoint, with: event) {
                return handle
            }
        }

        // Otherwise return self for dragging
        if bounds.contains(point) {
            return self
        }

        return nil
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        if isSelected {
            positionResizeHandles()
        }

        // Update overlay path
        overlayLayer?.path = UIBezierPath(rect: bounds).cgPath
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TemplateGroupView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Allow touch if it's not on the check button or resize handles
        if touch.view == checkButton {
            return false
        }

        for handle in resizeHandles {
            if touch.view == handle {
                return false
            }
        }

        return true
    }
}

// MARK: - Template Group Delegate
protocol TemplateGroupDelegate: AnyObject {
    func templateGroupDidConfirm(_ group: TemplateGroupView)
    func templateGroupDidRequestUngroup(_ group: TemplateGroupView)
}
