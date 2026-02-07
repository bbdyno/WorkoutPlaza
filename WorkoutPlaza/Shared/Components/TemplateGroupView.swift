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
//            return UIColor.systemBlue.withAlphaComponent(0.05)
            return .clear
        case .importedRecord:
//            return UIColor.systemOrange.withAlphaComponent(0.05)
            return .clear
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
    var rotationIndicatorLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?
    var initialSize: CGSize = .zero
    // rotation and isRotating are provided by Selectable protocol default implementation

    // MARK: - Group Properties
    private(set) var groupedItems: [UIView] = []
    private var originalItemFrames: [UIView: CGRect] = [:]
    private var originalGroupFrame: CGRect = .zero

    /// Store each widget's font scale at the time it was added to the group
    private var originalWidgetFontScales: [UIView: CGFloat] = [:]

    /// Minimum size for the group based on contained widgets
    var minimumSize: CGFloat {
        return calculateMinimumGroupSize()
    }

    // MARK: - Group Type Properties
    private(set) var groupType: WidgetGroupType = .myRecord
    private(set) var groupLabel: String = ""
    private(set) var ownerName: String?
    private(set) var groupId: String = UUID().uuidString


    private var overlayLayer: CAShapeLayer?




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
        }



        updateOverlayStyle()
    }

    private func updateOverlayStyle() {
        overlayLayer?.fillColor = groupType.overlayColor.cgColor
        // No stroke by default - only shown during selection
    }


    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear

        // Add overlay to show group boundary
        let overlay = CAShapeLayer()
        overlay.fillColor = groupType.overlayColor.cgColor

        // No border by default
        overlay.strokeColor = UIColor.clear.cgColor
        overlay.lineWidth = 0

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

            // Mark widget as group-managed BEFORE calculating scale
            // so that calculateScaleFactor uses the lower minimum (0.3)
            setGroupManaged(item, managed: true)

            // Store the widget's current font scale using its own calculateScaleFactor
            // This is the scale that determines the widget's font size (bounds / initialSize)
            if let statWidget = item as? BaseStatWidget {
                let scale = statWidget.calculateScaleFactor()
                originalWidgetFontScales[item] = scale
            } else if let textWidget = item as? TextWidget {
                let scale = textWidget.calculateScaleFactor()
                originalWidgetFontScales[item] = scale
            } else if let locationWidget = item as? LocationWidget {
                let scale = locationWidget.calculateScaleFactor()
                originalWidgetFontScales[item] = scale
            } else {
                originalWidgetFontScales[item] = 1.0
            }

            // Add to group
            addSubview(item)
            item.frame = frameInGroup
        }
    }

    /// Calculate the actual displayed font size considering adjustsFontSizeToFitWidth auto-shrink
    private func getActualDisplayedFontSize(label: UILabel) -> CGFloat {
        let nominalFontSize = label.font.pointSize
        guard let text = label.text, !text.isEmpty else { return nominalFontSize }
        guard label.adjustsFontSizeToFitWidth else { return nominalFontSize }
        guard label.bounds.width > 0 else { return nominalFontSize }

        // Calculate text width at nominal font size
        let textAttributes: [NSAttributedString.Key: Any] = [.font: label.font!]
        let textSize = (text as NSString).size(withAttributes: textAttributes)

        // If text fits, no shrinking needed
        if textSize.width <= label.bounds.width {
            return nominalFontSize
        }

        // Calculate shrink factor
        let shrinkFactor = label.bounds.width / textSize.width
        let clampedShrinkFactor = max(shrinkFactor, label.minimumScaleFactor)

        return nominalFontSize * clampedShrinkFactor
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
        selectionDelegate?.itemWasSelected(self)
    }

    private var initialCenter: CGPoint = .zero
    private var initialPinchBounds: CGRect = .zero
    private let snapStep: CGFloat = 5.0

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard DevSettings.shared.isPinchToResizeEnabled else { return }
        guard let view = gesture.view else { return }

        switch gesture.state {
        case .began:
            initialPinchBounds = view.bounds
            beginResize()

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

        case .ended, .cancelled:
            endResize()

        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view, let superview = superview else { return }

        switch gesture.state {
        case .began:
            initialCenter = view.center
            // Select this group immediately when drag starts
            if !isSelected {
                selectionDelegate?.itemWasSelected(self)
            }

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


    // MARK: - Group Resize
    private var isResizingGroup: Bool = false

    override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size && isResizingGroup {
                updateItemPositionsAndSizes()
            }
        }
    }

    override var bounds: CGRect {
        didSet {
            if bounds.size != oldValue.size && isResizingGroup {
                updateItemPositionsAndSizes()
            }
        }
    }

    /// Sync originalGroupFrame with current state (capture actual item frames)
    private func syncOriginalGroupFrame() {
        guard bounds.width > 0 && bounds.height > 0 else { return }

        // Capture actual current item frames (not calculated/scaled)
        for item in groupedItems {
            originalItemFrames[item] = item.frame
        }

        // Update originalGroupFrame to current bounds
        originalGroupFrame = CGRect(origin: .zero, size: bounds.size)
        initialSize = bounds.size
    }

    /// Call this when resize gesture begins
    func beginResize() {
        // Capture actual current state before starting resize
        // This ensures we scale from the real current positions, not stale data
        for item in groupedItems {
            originalItemFrames[item] = item.frame
        }
        originalGroupFrame = CGRect(origin: .zero, size: bounds.size)

        isResizingGroup = true
    }

    /// Call this when resize gesture ends
    func endResize() {
        // Accumulate font scales BEFORE syncing (need original group frame for scale calc)
        if originalGroupFrame.width > 0 && originalGroupFrame.height > 0 {
            let scaleX = bounds.width / originalGroupFrame.width
            let scaleY = bounds.height / originalGroupFrame.height
            let groupScale = (scaleX + scaleY) / 2.0

            for item in groupedItems {
                let prevScale = originalWidgetFontScales[item] ?? 1.0
                originalWidgetFontScales[item] = prevScale * groupScale
            }
        }

        isResizingGroup = false
        // Sync originalGroupFrame to current bounds for next resize
        syncOriginalGroupFrame()
    }

    private func updateItemPositionsAndSizes() {
        guard originalGroupFrame.width > 0 && originalGroupFrame.height > 0 else { return }

        let scaleX = bounds.width / originalGroupFrame.width
        let scaleY = bounds.height / originalGroupFrame.height
        let groupScale = (scaleX + scaleY) / 2.0

        // Update each item's position and size proportionally
        for (item, originalFrame) in originalItemFrames {
            let newX = originalFrame.origin.x * scaleX
            let newY = originalFrame.origin.y * scaleY
            let newWidth = originalFrame.width * scaleX
            let newHeight = originalFrame.height * scaleY

            item.frame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)

            let originalFontScale = originalWidgetFontScales[item] ?? 1.0
            let finalFontScale = originalFontScale * groupScale
            
            if let statWidget = item as? BaseStatWidget {
                statWidget.updateFontsWithScale(finalFontScale)
            } else if let textWidget = item as? TextWidget {
                textWidget.updateFontsWithScale(finalFontScale)
            } else if let locationWidget = item as? LocationWidget {
                locationWidget.updateFontsWithScale(finalFontScale)
            } else if let routeMap = item as? RouteMapView {
                routeMap.layoutSubviews()
            }
        }
    }

    /// Calculate minimum group size based on contained widgets' minimum sizes
    private func calculateMinimumGroupSize() -> CGFloat {
        guard originalGroupFrame.width > 0 && originalGroupFrame.height > 0 else {
            return LayoutConstants.minimumWidgetSize
        }

        var maxMinScale: CGFloat = 0

        for (_, originalFrame) in originalItemFrames {
            guard originalFrame.width > 0 && originalFrame.height > 0 else { continue }

            // 그룹 내 위젯은 독립 위젯보다 훨씬 작아질 수 있음
            let widgetMinSize: CGFloat = LayoutConstants.groupManagedMinimumWidgetSize

            // Calculate minimum scale needed for this widget
            let minScaleX = widgetMinSize / originalFrame.width
            let minScaleY = widgetMinSize / originalFrame.height
            let minScale = max(minScaleX, minScaleY)

            maxMinScale = max(maxMinScale, minScale)
        }

        // Return minimum group WIDTH based on the most restrictive widget
        let minWidth = originalGroupFrame.width * maxMinScale

        let result = max(minWidth, LayoutConstants.groupManagedMinimumWidgetSize)
        return result
    }

    // MARK: - Ungroup
    func ungroupItems(to targetView: UIView) -> [UIView] {
        var items: [UIView] = []

        // Get the group's rotation
        let groupRotation = self.rotation

        // Calculate current group scale
        let groupScaleX = bounds.width / originalGroupFrame.width
        let groupScaleY = bounds.height / originalGroupFrame.height
        let groupScale = (groupScaleX + groupScaleY) / 2.0

        for item in groupedItems {
            // Get item's current center in group coordinates
            let itemCenterInGroup = item.center

            // Convert item center to targetView coordinates (accounts for group rotation)
            let itemCenterInTargetView = convert(itemCenterInGroup, to: targetView)

            // Get the item's current size (bounds, not affected by rotation)
            let itemSize = item.bounds.size

            item.removeFromSuperview()
            targetView.addSubview(item)

            // Set the item's bounds and center
            item.bounds = CGRect(origin: .zero, size: itemSize)
            item.center = itemCenterInTargetView

            // Combine the widget's own rotation with the group's rotation
            if let selectableItem = item as? Selectable {
                let itemRotation = selectableItem.rotation
                let combinedRotation = itemRotation + groupRotation
                selectableItem.rotation = combinedRotation
                item.transform = CGAffineTransform(rotationAngle: combinedRotation)
            } else {
                // For non-selectable items, apply group rotation
                if groupRotation != 0 {
                    item.transform = CGAffineTransform(rotationAngle: groupRotation)
                }
            }

            // Reset group-managed flag so widget handles its own font scaling again
            setGroupManaged(item, managed: false)

            let originalFontScale = originalWidgetFontScales[item] ?? 1.0
            let totalFontScale = originalFontScale * groupScale

            if totalFontScale > 0 {
                let preservedInitialSize = CGSize(
                    width: itemSize.width / totalFontScale,
                    height: itemSize.height / totalFontScale
                )

                if let statWidget = item as? BaseStatWidget {
                    statWidget.initialSize = preservedInitialSize
                } else if let textWidget = item as? TextWidget {
                    textWidget.initialSize = preservedInitialSize
                } else if let locationWidget = item as? LocationWidget {
                    locationWidget.initialSize = preservedInitialSize
                }
            }

            items.append(item)
        }

        return items
    }

    // MARK: - Selectable Methods
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

        // Hide overlay when selected (selection border is more prominent)
        overlayLayer?.isHidden = true
    }

    func hideSelectionState() {
        isSelected = false
        removeSelectionBorder()
        removeResizeHandles()

        // Hide overlay and border when deselected
        overlayLayer?.isHidden = true
    }

    func applyColor(_ color: UIColor) {
        currentColor = color
        // Propagate color change to all grouped items
        for item in groupedItems {
            if var selectable = item as? Selectable {
                selectable.applyColor(color)
            }
        }
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        // Propagate font change to all grouped items
        for item in groupedItems {
            if let statWidget = item as? BaseStatWidget {
                statWidget.applyFont(fontStyle)
            }
            if let textWidget = item as? TextWidget {
                textWidget.applyFont(fontStyle)
            }
        }
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

        // Store the widget's current font scale using its own calculateScaleFactor
        if let statWidget = widget as? BaseStatWidget {
            originalWidgetFontScales[widget] = statWidget.calculateScaleFactor()
        } else if let textWidget = widget as? TextWidget {
            originalWidgetFontScales[widget] = textWidget.calculateScaleFactor()
        } else if let locationWidget = widget as? LocationWidget {
            originalWidgetFontScales[widget] = locationWidget.calculateScaleFactor()
        } else {
            originalWidgetFontScales[widget] = 1.0
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
        originalWidgetFontScales.removeValue(forKey: widget)

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
        // Allow touch if it's not on resize handles

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
