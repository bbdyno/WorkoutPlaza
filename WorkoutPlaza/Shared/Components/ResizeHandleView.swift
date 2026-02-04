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

        if position == .bottomLeft {
            // Rotation handle - Blue
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
            circleLayer.shadowColor = UIColor.black.cgColor
            circleLayer.shadowOffset = CGSize(width: 0, height: 2)
            circleLayer.shadowOpacity = 0.3
            circleLayer.shadowRadius = 4
            layer.addSublayer(circleLayer)

            let iconImageView = UIImageView()
            let config = UIImage.SymbolConfiguration(pointSize: iconFontSize, weight: .semibold)
            iconImageView.image = UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90", withConfiguration: config)
            iconImageView.tintColor = .white
            iconImageView.contentMode = .center
            iconImageView.frame = CGRect(x: 0, y: 0, width: handleSize, height: handleSize)
            addSubview(iconImageView)

        } else if position == .bottomRight {
            // Resize handle - Green
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
            circleLayer.shadowColor = UIColor.black.cgColor
            circleLayer.shadowOffset = CGSize(width: 0, height: 2)
            circleLayer.shadowOpacity = 0.3
            circleLayer.shadowRadius = 4
            layer.addSublayer(circleLayer)

            let iconImageView = UIImageView()
            let config = UIImage.SymbolConfiguration(pointSize: iconFontSize, weight: .semibold)
            iconImageView.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: config)
            iconImageView.tintColor = .white
            iconImageView.contentMode = .center
            iconImageView.frame = CGRect(x: 0, y: 0, width: handleSize, height: handleSize)
            addSubview(iconImageView)

        } else {
            // Other handles - small white circle
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

        if position == .bottomLeft {
            handleRotationGesture(gesture, parentView: parentView, superview: superview)
            return
        }

        handleResizeGesture(gesture, parentView: parentView, superview: superview)
    }

    // MARK: - Rotation Gesture
    private func handleRotationGesture(_ gesture: UIPanGestureRecognizer, parentView: UIView, superview: UIView) {
        guard let selectable = parentView as? Selectable else { return }

        switch gesture.state {
        case .began:
            initialRotation = selectable.rotation
            initialTouchPoint = gesture.location(in: superview)
            let center = parentView.center
            initialAngle = atan2(initialTouchPoint.y - center.y, initialTouchPoint.x - center.x)
            selectable.isRotating = true
            selectable.showRotationIndicator()
            animateScale(to: 1.3)

        case .changed:
            let currentPoint = gesture.location(in: superview)
            let center = parentView.center
            let currentAngle = atan2(currentPoint.y - center.y, currentPoint.x - center.x)
            let angleChange = currentAngle - initialAngle
            let newRotationDegrees = initialRotation * 180 / .pi + angleChange * 180 / .pi
            let snappedRotationDegrees = round(newRotationDegrees / 5) * 5
            let snappedRotationRadians = snappedRotationDegrees * .pi / 180

            selectable.rotation = snappedRotationRadians
            parentView.transform = CGAffineTransform(rotationAngle: snappedRotationRadians)
            selectable.positionResizeHandles()

        case .ended, .cancelled:
            selectable.isRotating = false
            selectable.hideRotationIndicator()
            animateScale(to: 1.0)

        default:
            break
        }
    }

    // MARK: - Resize Gesture (비율 항상 고정, 좌상단 기준)
    private func handleResizeGesture(_ gesture: UIPanGestureRecognizer, parentView: UIView, superview: UIView) {
        guard let selectable = parentView as? Selectable else { return }

        switch gesture.state {
        case .began:
            initialBounds = parentView.bounds
            initialCenter = parentView.center
            initialTouchPoint = gesture.location(in: superview)
            initialTopLeft = parentView.convert(CGPoint.zero, to: superview)
            selectable.isResizing = true

            // TemplateGroupView인 경우 리사이즈 시작 알림
            if let groupView = parentView as? TemplateGroupView {
                groupView.beginResize()
            }

            // initialSize가 설정 안 됐으면 현재 크기로 설정
            if let statWidget = parentView as? BaseStatWidget, statWidget.initialSize == .zero {
                statWidget.initialSize = parentView.bounds.size
            } else if let textWidget = parentView as? TextWidget, textWidget.initialSize == .zero {
                textWidget.initialSize = parentView.bounds.size
            } else if let locationWidget = parentView as? LocationWidget, locationWidget.initialSize == .zero {
                locationWidget.initialSize = parentView.bounds.size
            }

            animateScale(to: 1.3)

        case .changed:
            let currentPoint = gesture.location(in: superview)
            let rotation = selectable.rotation

            // 드래그 델타를 로컬 좌표로 변환
            let rawDelta = CGPoint(
                x: currentPoint.x - initialTouchPoint.x,
                y: currentPoint.y - initialTouchPoint.y
            )
            let cosAngle = cos(-rotation)
            let sinAngle = sin(-rotation)
            let localDelta = CGPoint(
                x: rawDelta.x * cosAngle - rawDelta.y * sinAngle,
                y: rawDelta.x * sinAngle + rawDelta.y * cosAngle
            )

            // 비율 계산
            let aspectRatio = initialBounds.width / initialBounds.height

            // Get minimum size - use group's calculated minimum if it's a TemplateGroupView
            let minSize: CGFloat
            if let groupView = parentView as? TemplateGroupView {
                minSize = groupView.minimumSize
            } else {
                minSize = selectable.minimumSize
            }

            // 우하단 핸들 기준으로 크기 계산 (다른 핸들은 비활성화)
            var deltaSize: CGFloat = 0

            switch position {
            case .bottomRight:
                // 대각선 방향으로 크기 변경
                deltaSize = (localDelta.x + localDelta.y) / 2
            case .topRight:
                deltaSize = (localDelta.x - localDelta.y) / 2
            case .topLeft:
                deltaSize = (-localDelta.x - localDelta.y) / 2
            case .bottomLeft:
                return // 회전 전용
            }

            // 새 크기 계산 (비율 유지)
            var newWidth = initialBounds.width + deltaSize
            var newHeight = newWidth / aspectRatio

            // 최소/최대 크기 적용
            let maxSize: CGFloat = max(initialBounds.width, initialBounds.height) * LayoutConstants.maximumScaleFactor
            newWidth = max(minSize, min(maxSize, newWidth))
            newHeight = newWidth / aspectRatio

            // 스냅 적용
            let snapStep: CGFloat = LayoutConstants.snapStep
            newWidth = round(newWidth / snapStep) * snapStep
            newHeight = newWidth / aspectRatio

            // 최소 크기 재확인
            // TemplateGroupView의 경우 minSize는 최소 너비이므로 너비만 체크
            // 비율을 유지하므로 너비가 최소값 이상이면 높이도 자동으로 충족됨
            if let _ = parentView as? TemplateGroupView {
                if newWidth < minSize {
                    newWidth = minSize
                    newHeight = newWidth / aspectRatio
                }
            } else {
                // 일반 위젯은 둘 다 minSize 이상이 되도록
                if newWidth < minSize {
                    newWidth = minSize
                    newHeight = minSize / aspectRatio
                }
                if newHeight < minSize {
                    newHeight = minSize
                    newWidth = minSize * aspectRatio
                }
            }

            // 새 bounds 적용
            let newBounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
            
            // 좌상단 고정을 위한 center 계산
            let halfWidth = newWidth / 2
            let halfHeight = newHeight / 2
            let cosR = cos(rotation)
            let sinR = sin(rotation)
            let newCenter = CGPoint(
                x: initialTopLeft.x + halfWidth * cosR - halfHeight * sinR,
                y: initialTopLeft.y + halfWidth * sinR + halfHeight * cosR
            )

            // 적용
            parentView.bounds = newBounds
            parentView.center = newCenter

            // 폰트 업데이트 (직접 호출)
            if let statWidget = parentView as? BaseStatWidget {
                if statWidget.initialSize.width > 0 {
                    let scale = newWidth / statWidget.initialSize.width
                    statWidget.updateFontsWithScale(scale)
                }
            } else if let textWidget = parentView as? TextWidget {
                if textWidget.initialSize.width > 0 {
                    let scale = newWidth / textWidget.initialSize.width
                    textWidget.updateFontsWithScale(scale)
                }
            } else if let locationWidget = parentView as? LocationWidget {
                if locationWidget.initialSize.width > 0 {
                    let scale = newWidth / locationWidget.initialSize.width
                    locationWidget.updateFontsWithScale(scale)
                }
            }

            selectable.positionResizeHandles()

        case .ended, .cancelled:
            selectable.isResizing = false

            // TemplateGroupView인 경우 리사이즈 종료 알림
            if let groupView = parentView as? TemplateGroupView {
                groupView.endResize()
            }

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
                let currentRotation = atan2(self.transform.b, self.transform.a)
                self.transform = CGAffineTransform(rotationAngle: currentRotation)
                    .scaledBy(x: scale, y: scale)
            },
            completion: nil
        )
    }

    // MARK: - Hit Testing
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -LayoutConstants.resizeHitAreaExpansion, dy: -LayoutConstants.resizeHitAreaExpansion)
        return expandedBounds.contains(point)
    }
}
