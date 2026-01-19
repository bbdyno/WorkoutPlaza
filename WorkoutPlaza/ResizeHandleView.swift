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

    private let handleSize: CGFloat = 20
    private let circleSize: CGFloat = 8
    private var panGesture: UIPanGestureRecognizer!
    private var initialParentFrame: CGRect = .zero
    private var initialTouchPoint: CGPoint = .zero

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

        // Circle layer
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

    private func setupGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    // MARK: - Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let parentView = parentView,
              let superview = parentView.superview else { return }

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
            let snapStep: CGFloat = 5.0

            // Check if aspect ratio should be locked (for RouteMapView and TemplateGroupView)
            let shouldLockAspectRatio = parentView is RouteMapView || parentView is TemplateGroupView
            let aspectRatio = initialParentFrame.width / initialParentFrame.height

            if shouldLockAspectRatio {
                // Aspect Ratio Locked Resize
                // We'll drive resize primarily by width for simplicity, or diagonal.
                // Let's use the width change as the primary driver and snap it.
                
                var rawNewWidth: CGFloat = initialParentFrame.width
                
                // Calculate expected width change based on handle movement
                switch position {
                case .topLeft, .bottomLeft:
                    rawNewWidth = initialParentFrame.width - delta.x
                case .topRight, .bottomRight:
                    rawNewWidth = initialParentFrame.width + delta.x
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
                    
                case .bottomLeft:
                    // Top-Right is fixed
                    newFrame.origin.x = initialParentFrame.maxX - snappedWidth
                    newFrame.size = CGSize(width: snappedWidth, height: snappedHeight)
                    
                case .bottomRight:
                    // Top-Left is fixed
                    newFrame.size = CGSize(width: snappedWidth, height: snappedHeight)
                }
                
            } else {
                // Free Resize with Snapping
                // We snap the moving edges to the grid (relative to superview 0,0)
                
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

                case .bottomLeft:
                    let rawX = initialParentFrame.minX + delta.x
                    let rawMaxY = initialParentFrame.maxY + delta.y
                    
                    let snappedX = round(rawX / snapStep) * snapStep
                    let snappedMaxY = round(rawMaxY / snapStep) * snapStep
                    
                    newFrame.origin.x = snappedX
                    newFrame.size.width = initialParentFrame.maxX - snappedX
                    newFrame.size.height = snappedMaxY - initialParentFrame.minY

                case .bottomRight:
                    let rawMaxX = initialParentFrame.maxX + delta.x
                    let rawMaxY = initialParentFrame.maxY + delta.y
                    
                    let snappedMaxX = round(rawMaxX / snapStep) * snapStep
                    let snappedMaxY = round(rawMaxY / snapStep) * snapStep
                    
                    newFrame.size.width = snappedMaxX - initialParentFrame.minX
                    newFrame.size.height = snappedMaxY - initialParentFrame.minY
                }
            }

            // Apply minimum size constraint
            let minSize: CGFloat = 60
            if newFrame.width >= minSize && newFrame.height >= minSize {
                parentView.frame = newFrame

                // Reposition handles after resize
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
        let expandedBounds = bounds.insetBy(dx: -10, dy: -10)
        return expandedBounds.contains(point)
    }
}
