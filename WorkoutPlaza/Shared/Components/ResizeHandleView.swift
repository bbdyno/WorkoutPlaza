//
//  ResizeHandleView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

class ResizeHandleView: UIView {

    // MARK: - Properties
    let position: ResizeHandlePosition
    weak var parentView: UIView?

    private let handleSize: CGFloat = LayoutConstants.resizeHandleSize
    private let circleSize: CGFloat = LayoutConstants.resizeCircleSize
    private var panGesture: UIPanGestureRecognizer!
    private var initialParentFrame: CGRect = .zero
    private var initialTouchPoint: CGPoint = .zero

    // Rotation-specific properties
    private var initialRotation: CGFloat = 0
    private var initialAngle: CGFloat = 0

    // MARK: - Initialization
    init(position: ResizeHandlePosition) {
        self.position = position
        super.init(frame: CGRect(x: 0, y: 0, width: handleSize, height: handleSize))
        setupView()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear

        // Different style for rotation handle (bottomLeft)
        if position == .bottomLeft {
            // Rotation handle - circular with rotation icon
            let circleLayer = CAShapeLayer()
            circleLayer.path = UIBezierPath(
                ovalIn: CGRect(
                    x: (handleSize - circleSize) / 2,
                    y: (handleSize - circleSize) / 2,
                    width: circleSize,
                    height: circleSize
                )
            ).cgPath
            circleLayer.fillColor = UIColor.systemBlue.cgColor
            circleLayer.strokeColor = UIColor.white.cgColor
            circleLayer.lineWidth = 2

            // Shadow
            circleLayer.shadowColor = UIColor.black.cgColor
            circleLayer.shadowOffset = CGSize(width: 0, height: 2)
            circleLayer.shadowOpacity = 0.3
            circleLayer.shadowRadius = 3

            layer.addSublayer(circleLayer)

            // Add rotation icon
            let iconLayer = CATextLayer()
            iconLayer.string = "↻"
            iconLayer.font = CTFontCreateWithName("ArialMT" as CFString, 20, nil)
            iconLayer.fontSize = 20
            iconLayer.foregroundColor = UIColor.white.cgColor
            iconLayer.alignmentMode = .center
            iconLayer.frame = CGRect(x: 0, y: 0, width: handleSize, height: handleSize)
            layer.addSublayer(iconLayer)
        } else {
            // Resize handle - white circle with blue border
            let circleLayer = CAShapeLayer()
            circleLayer.path = UIBezierPath(
                ovalIn: CGRect(
                    x: (handleSize - circleSize) / 2,
                    y: (handleSize - circleSize) / 2,
                    width: circleSize,
                    height: circleSize
                )
            ).cgPath
            circleLayer.fillColor = UIColor.white.cgColor
            circleLayer.strokeColor = UIColor.systemBlue.cgColor
            circleLayer.lineWidth = 2

            // Shadow
            circleLayer.shadowColor = UIColor.black.cgColor
            circleLayer.shadowOffset = CGSize(width: 0, height: 2)
            circleLayer.shadowOpacity = 0.3
            circleLayer.shadowRadius = 3

            layer.addSublayer(circleLayer)
        }
    }

    private func setupGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    // MARK: - Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let parentView = parentView,
              let superview = parentView.superview else { return }

        // Handle rotation for bottomLeft (rotation handle)
        if position == .bottomLeft {
            handleRotationGesture(gesture, parentView: parentView, superview: superview)
            return
        }

        // Handle resize for other handles
        handleResizeGesture(gesture, parentView: parentView, superview: superview)
    }

    private func handleRotationGesture(_ gesture: UIPanGestureRecognizer, parentView: UIView, superview: UIView) {
        guard let selectable = parentView as? Selectable else { return }

        switch gesture.state {
        case .began:
            initialRotation = selectable.rotation
            initialTouchPoint = gesture.location(in: superview)

            // Calculate initial angle from widget center to touch point
            let center = parentView.center
            initialAngle = atan2(initialTouchPoint.y - center.y, initialTouchPoint.x - center.x)

            selectable.isRotating = true
            selectable.showRotationIndicator()
            animateScale(to: 1.3)

        case .changed:
            let currentPoint = gesture.location(in: superview)
            let center = parentView.center

            // Calculate current angle
            let currentAngle = atan2(currentPoint.y - center.y, currentPoint.x - center.x)

            // Calculate rotation change in radians
            let angleChange = currentAngle - initialAngle

            // Convert to degrees and add to initial rotation
            let newRotationDegrees = initialRotation * 180 / .pi + angleChange * 180 / .pi

            // Snap to 5-degree increments
            let snappedRotationDegrees = round(newRotationDegrees / 5) * 5

            // Convert back to radians and apply
            let snappedRotationRadians = snappedRotationDegrees * .pi / 180
            selectable.rotation = snappedRotationRadians

            // Apply rotation transform
            parentView.transform = CGAffineTransform(rotationAngle: snappedRotationRadians)

        case .ended, .cancelled:
            selectable.isRotating = false
            selectable.hideRotationIndicator()
            animateScale(to: 1.0)

        default:
            break
        }
    }

    private func handleResizeGesture(_ gesture: UIPanGestureRecognizer, parentView: UIView, superview: UIView) {
        switch gesture.state {
        case .began:
            initialParentFrame = parentView.frame
            initialTouchPoint = gesture.location(in: superview)
            animateScale(to: 1.3)

        case .changed:
            let currentPoint = gesture.location(in: superview)
            let delta = CGPoint(
                x: currentPoint.x - initialTouchPoint.x,
                y: currentPoint.y - initialTouchPoint.y
            )

            var newFrame = initialParentFrame
            let snapStep: CGFloat = LayoutConstants.snapStep

            // Check if aspect ratio should be locked (for RouteMapView, TemplateGroupView, and TextPathWidget)
            let shouldLockAspectRatio = parentView is RouteMapView || parentView is TemplateGroupView || parentView is TextPathWidget
            let aspectRatio = initialParentFrame.width / initialParentFrame.height

            if shouldLockAspectRatio {
                // Aspect ratio locked resize
                // Drive resize primarily by width for simplicity, or diagonal.
                // Use the width change as the primary driver and snap it.

                var rawNewWidth: CGFloat = initialParentFrame.width

                // Calculate expected width change based on handle movement
                switch position {
                case .topLeft:
                    rawNewWidth = initialParentFrame.width - delta.x
                case .topRight, .bottomRight:
                    rawNewWidth = initialParentFrame.width + delta.x
                case .bottomLeft:
                    // Rotation-only, no resize - keep original width
                    rawNewWidth = initialParentFrame.width
                }

                // Snap the width
                let snappedWidth = round(rawNewWidth / snapStep) * snapStep
                let snappedHeight = snappedWidth / aspectRatio

                // Determine new frame based on fixed corner
                switch position {
                case .topLeft:
                    // Bottom-Right is fixed
                    newFrame.origin.x = initialParentFrame.maxX - snappedWidth
                    newFrame.origin.y = initialParentFrame.maxY - snappedHeight
                    newFrame.size = CGSize(width: snappedWidth, height: snappedHeight)

                case .topRight:
                    // Bottom-Left is fixed
                    newFrame.origin.y = initialParentFrame.maxY - snappedHeight
                    newFrame.size = CGSize(width: snappedWidth, height: snappedHeight)

                case .bottomRight:
                    // Top-Left is fixed
                    newFrame.size = CGSize(width: snappedWidth, height: snappedHeight)

                case .bottomLeft:
                    // Rotation-only, no resize
                    break
                }

            } else {
                // Free resize with snapping
                // Snap the moving edges to the grid (relative to superview origin)

                switch position {
                case .topLeft:
                    let rawX = initialParentFrame.minX + delta.x
                    let rawY = initialParentFrame.minY + delta.y

                    let snappedX = round(rawX / snapStep) * snapStep
                    let snappedY = round(rawY / snapStep) * snapStep

                    newFrame.origin.x = snappedX
                    newFrame.origin.y = snappedY
                    newFrame.size.width = initialParentFrame.maxX - snappedX
                    newFrame.size.height = initialParentFrame.maxY - snappedY

                case .topRight:
                    let rawMaxX = initialParentFrame.maxX + delta.x
                    let rawY = initialParentFrame.minY + delta.y

                    let snappedMaxX = round(rawMaxX / snapStep) * snapStep
                    let snappedY = round(rawY / snapStep) * snapStep

                    newFrame.origin.y = snappedY
                    newFrame.size.width = snappedMaxX - initialParentFrame.minX
                    newFrame.size.height = initialParentFrame.maxY - snappedY

                case .bottomRight:
                    let rawMaxX = initialParentFrame.maxX + delta.x
                    let rawMaxY = initialParentFrame.maxY + delta.y

                    let snappedMaxX = round(rawMaxX / snapStep) * snapStep
                    let snappedMaxY = round(rawMaxY / snapStep) * snapStep

                    newFrame.size.width = snappedMaxX - initialParentFrame.minX
                    newFrame.size.height = snappedMaxY - initialParentFrame.minY

                case .bottomLeft:
                    // Rotation-only, no resize
                    break
                }
            }

            // Apply minimum size constraint
            let minSize: CGFloat
            if let selectable = parentView as? Selectable {
                minSize = selectable.minimumSize
            } else {
                minSize = LayoutConstants.minimumWidgetSize
            }

            // If already at minimum size and shrinking, don't update
            let atMinHeight = parentView.frame.height <= minSize
            let atMinWidth = parentView.frame.width <= minSize

            let shrinkingHeight: Bool
            let shrinkingWidth: Bool

            switch position {
            case .topLeft, .topRight:
                shrinkingHeight = delta.y > 0  // dragging down shrinks
            case .bottomRight:
                shrinkingHeight = delta.y < 0  // dragging up shrinks
            case .bottomLeft:
                shrinkingHeight = false // Rotation-only
            }

            switch position {
            case .topLeft:
                shrinkingWidth = delta.x > 0  // dragging right shrinks
            case .topRight, .bottomRight:
                shrinkingWidth = delta.x < 0  // dragging left shrinks
            case .bottomLeft:
                shrinkingWidth = false // Rotation-only
            }

            // Stop updating if at min size and still shrinking in that direction
            if (atMinHeight && shrinkingHeight) || (atMinWidth && shrinkingWidth) {
                return
            }

            // Clamp and update
            let clampedWidth = max(minSize, newFrame.width)
            let clampedHeight = max(minSize, newFrame.height)

            if clampedWidth != parentView.frame.width || clampedHeight != parentView.frame.height {
                let finalFrame: CGRect

                switch position {
                case .topLeft:
                    finalFrame = CGRect(
                        x: initialParentFrame.maxX - clampedWidth,
                        y: initialParentFrame.maxY - clampedHeight,
                        width: clampedWidth,
                        height: clampedHeight
                    )
                case .topRight:
                    finalFrame = CGRect(
                        x: initialParentFrame.minX,
                        y: initialParentFrame.maxY - clampedHeight,
                        width: clampedWidth,
                        height: clampedHeight
                    )
                case .bottomRight:
                    finalFrame = CGRect(
                        x: initialParentFrame.minX,
                        y: initialParentFrame.minY,
                        width: clampedWidth,
                        height: clampedHeight
                    )
                case .bottomLeft:
                    finalFrame = newFrame // Should not reach here for rotation
                }

                parentView.frame = finalFrame

                if let selectable = parentView as? Selectable {
                    selectable.positionResizeHandles()
                }
            }

        case .ended, .cancelled:
            animateScale(to: 1.0)

        default:
            break
        }
    }

    // MARK: - Animation
    private func animateScale(to scale: CGFloat) {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut],
            animations: {
                self.transform = CGAffineTransform(scaleX: scale, y: scale)
            },
            completion: nil
        )
    }

    // MARK: - Hit Testing
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Expand the hit area for better touch handling
        let expandedBounds = bounds.insetBy(dx: -LayoutConstants.resizeHitAreaExpansion, dy: -LayoutConstants.resizeHitAreaExpansion)
        return expandedBounds.contains(point)
    }
}
