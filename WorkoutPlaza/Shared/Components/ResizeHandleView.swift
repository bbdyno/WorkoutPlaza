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
    private var initialTouchPoint: CGPoint = .zero

    // Rotation-specific properties
    private var initialRotation: CGFloat = 0
    private var initialAngle: CGFloat = 0

    // Resize-specific properties
    private var initialBounds: CGRect = .zero
    private var initialCenter: CGPoint = .zero
    private var initialTopLeft: CGPoint = .zero

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

        let iconSize = LayoutConstants.handleIconSize
        let iconFontSize = LayoutConstants.handleIconFontSize

        // Different style for rotation handle (bottomLeft) and resize handle (bottomRight)
        if position == .bottomLeft {
            // Rotation handle - larger circular with rotation icon (Blue)
            let circleLayer = CAShapeLayer()
            circleLayer.path = UIBezierPath(
                ovalIn: CGRect(
                    x: (handleSize - iconSize) / 2,
                    y: (handleSize - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
            ).cgPath
            circleLayer.fillColor = ColorSystem.rotationHandle.cgColor
            circleLayer.strokeColor = UIColor.white.cgColor
            circleLayer.lineWidth = 2

            // Shadow
            circleLayer.shadowColor = UIColor.black.cgColor
            circleLayer.shadowOffset = CGSize(width: 0, height: 2)
            circleLayer.shadowOpacity = 0.3
            circleLayer.shadowRadius = 4

            layer.addSublayer(circleLayer)

            // Add rotation icon using SF Symbol
            let iconImageView = UIImageView()
            let config = UIImage.SymbolConfiguration(pointSize: iconFontSize, weight: .semibold)
            iconImageView.image = UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90", withConfiguration: config)
            iconImageView.tintColor = .white
            iconImageView.contentMode = .center
            iconImageView.frame = CGRect(x: 0, y: 0, width: handleSize, height: handleSize)
            addSubview(iconImageView)

        } else if position == .bottomRight {
            // Resize handle - larger circular with resize icon (Green)
            let circleLayer = CAShapeLayer()
            circleLayer.path = UIBezierPath(
                ovalIn: CGRect(
                    x: (handleSize - iconSize) / 2,
                    y: (handleSize - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
            ).cgPath
            circleLayer.fillColor = ColorSystem.resizeHandle.cgColor
            circleLayer.strokeColor = UIColor.white.cgColor
            circleLayer.lineWidth = 2

            // Shadow
            circleLayer.shadowColor = UIColor.black.cgColor
            circleLayer.shadowOffset = CGSize(width: 0, height: 2)
            circleLayer.shadowOpacity = 0.3
            circleLayer.shadowRadius = 4

            layer.addSublayer(circleLayer)

            // Add resize icon using SF Symbol
            let iconImageView = UIImageView()
            let config = UIImage.SymbolConfiguration(pointSize: iconFontSize, weight: .semibold)
            iconImageView.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: config)
            iconImageView.tintColor = .white
            iconImageView.contentMode = .center
            iconImageView.frame = CGRect(x: 0, y: 0, width: handleSize, height: handleSize)
            addSubview(iconImageView)

        } else {
            // Other resize handles (topLeft, topRight) - small white circle with blue border
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
            circleLayer.strokeColor = ColorSystem.primaryBlue.cgColor
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

            // 핸들 위치도 함께 업데이트
            selectable.positionResizeHandles()

        case .ended, .cancelled:
            selectable.isRotating = false
            selectable.hideRotationIndicator()
            animateScale(to: 1.0)

        default:
            break
        }
    }

    private func handleResizeGesture(_ gesture: UIPanGestureRecognizer, parentView: UIView, superview: UIView) {
        guard let selectable = parentView as? Selectable else { return }

        switch gesture.state {
        case .began:
            // 회전된 뷰에서는 bounds와 center를 사용해야 함
            initialBounds = parentView.bounds
            initialCenter = parentView.center
            initialTouchPoint = gesture.location(in: superview)

            // 좌상단 위치를 superview 좌표로 저장
            initialTopLeft = parentView.convert(CGPoint.zero, to: superview)

            // Set resizing flag to prevent auto-resize during handle resize
            selectable.isResizing = true

            animateScale(to: 1.3)

        case .changed:
            let currentPoint = gesture.location(in: superview)
            let rotation = selectable.rotation

            // 델타를 회전 역방향으로 변환하여 로컬 좌표계 기준으로 계산
            let rawDelta = CGPoint(
                x: currentPoint.x - initialTouchPoint.x,
                y: currentPoint.y - initialTouchPoint.y
            )

            // 회전 역변환 적용
            let cosAngle = cos(-rotation)
            let sinAngle = sin(-rotation)
            let localDelta = CGPoint(
                x: rawDelta.x * cosAngle - rawDelta.y * sinAngle,
                y: rawDelta.x * sinAngle + rawDelta.y * cosAngle
            )

            let snapStep: CGFloat = LayoutConstants.snapStep
            let minSize: CGFloat = selectable.minimumSize

            // 모든 크기 조절은 좌상단 기준으로 통일
            var newWidth = initialBounds.width
            var newHeight = initialBounds.height

            // Check if aspect ratio should be locked
            // 회전된 상태에서는 항상 비율 고정 (회전 + 자유 비율 조합 시 좌표 계산 복잡성 회피)
            let isRotated = abs(rotation) > 0.01
            let shouldLockAspectRatio = isRotated || parentView is RouteMapView || parentView is TemplateGroupView || parentView is TextPathWidget
            let aspectRatio = initialBounds.width / initialBounds.height

            switch position {
            case .topLeft:
                // 좌상단: width와 height 모두 음의 델타로 증가
                newWidth = initialBounds.width - localDelta.x
                newHeight = initialBounds.height - localDelta.y
            case .topRight:
                // 우상단: width는 양의 델타, height는 음의 델타
                newWidth = initialBounds.width + localDelta.x
                newHeight = initialBounds.height - localDelta.y
            case .bottomRight:
                // 우하단: 양의 델타로 증가 (좌상단 기준)
                newWidth = initialBounds.width + localDelta.x
                newHeight = initialBounds.height + localDelta.y
            case .bottomLeft:
                // 회전 전용
                return
            }

            // Snap to grid
            newWidth = round(newWidth / snapStep) * snapStep
            newHeight = round(newHeight / snapStep) * snapStep

            // Apply aspect ratio if needed
            if shouldLockAspectRatio {
                // 더 큰 변화량을 기준으로 비율 유지
                let widthChange = abs(newWidth - initialBounds.width)
                let heightChange = abs(newHeight - initialBounds.height)

                if widthChange > heightChange {
                    newHeight = newWidth / aspectRatio
                } else {
                    newWidth = newHeight * aspectRatio
                }
            }

            // Clamp to minimum size
            newWidth = max(minSize, newWidth)
            newHeight = max(minSize, newHeight)

            // 새 bounds 적용
            let newBounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)

            // 좌상단을 고정하기 위해 center 조정
            // 새 center = 좌상단 위치 + 회전된 (width/2, height/2)
            let halfWidth = newWidth / 2
            let halfHeight = newHeight / 2

            let cosR = cos(rotation)
            let sinR = sin(rotation)

            let newCenter = CGPoint(
                x: initialTopLeft.x + halfWidth * cosR - halfHeight * sinR,
                y: initialTopLeft.y + halfWidth * sinR + halfHeight * cosR
            )

            // bounds와 center 업데이트
            parentView.bounds = newBounds
            parentView.center = newCenter

            // 핸들 위치 업데이트
            selectable.positionResizeHandles()

        case .ended, .cancelled:
            // Reset resizing flag
            selectable.isResizing = false

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
                // 기존 회전을 유지하면서 스케일 적용
                let currentRotation = atan2(self.transform.b, self.transform.a)
                self.transform = CGAffineTransform(rotationAngle: currentRotation)
                    .scaledBy(x: scale, y: scale)
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
