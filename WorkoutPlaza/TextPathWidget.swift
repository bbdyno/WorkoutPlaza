//
//  TextPathWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/21/26.
//

import UIKit

class TextPathWidget: UIView, Selectable {

    // MARK: - Selectable Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .white {
        didSet {
            textColor = currentColor
            setNeedsDisplay()
        }
    }
    var currentFontStyle: FontStyle = .system
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?
    var initialSize: CGSize = .zero

    // MARK: - Text Path Properties

    /// 경로를 따라 반복할 텍스트
    private(set) var textToRepeat: String

    /// 사용자가 드래그한 경로의 좌표들
    private var pathPoints: [CGPoint] = []

    /// 텍스트 색상
    private var textColor: UIColor = .white

    /// 텍스트 폰트 사이즈
    private var fontSize: CGFloat = 20

    // MARK: - Initialization

    init(text: String, pathPoints: [CGPoint], frame: CGRect) {
        self.textToRepeat = text
        self.pathPoints = pathPoints
        super.init(frame: frame)
        self.initialSize = frame.size
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true

        // Add tap gesture for selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)

        // Add pan gesture for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        selectionDelegate?.itemWasSelected(self)
    }

    private var initialCenter: CGPoint = .zero

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }

        switch gesture.state {
        case .began:
            initialCenter = center

        case .changed:
            let translation = gesture.translation(in: superview)
            center = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )

        default:
            break
        }
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              pathPoints.count >= 2 else { return }

        drawTextAlongPath(in: context)
    }

    /// 경로를 따라 텍스트 그리기
    private func drawTextAlongPath(in context: CGContext) {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: textColor
        ]

        // 각 글자의 크기 미리 계산
        let characters = Array(textToRepeat)
        var characterWidths: [CGFloat] = []

        for char in characters {
            let charString = String(char)
            let size = charString.size(withAttributes: textAttributes)
            characterWidths.append(size.width)
        }

        // 경로를 따라 텍스트 배치
        var charIndex = 0

        // 각 세그먼트(선분)를 순회
        for i in 0..<(pathPoints.count - 1) {
            let startPoint = pathPoints[i]
            let endPoint = pathPoints[i + 1]

            // 세그먼트의 벡터 계산
            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y
            let segmentLength = sqrt(dx * dx + dy * dy)

            guard segmentLength > 0 else { continue }

            // 세그먼트의 각도 계산 (라디안)
            let angle = atan2(dy, dx)

            // 각도 정규화: 텍스트가 거꾸로 뒤집히는 것을 방지
            var normalizedAngle = angle
            var isFlipped = false

            if angle > .pi / 2 {
                normalizedAngle = angle - .pi
                isFlipped = true
            } else if angle < -.pi / 2 {
                normalizedAngle = angle + .pi
                isFlipped = true
            }

            // 정규화된 방향 벡터
            let normalizedDx = dx / segmentLength
            let normalizedDy = dy / segmentLength

            // 이 세그먼트에서 글자들을 배치
            var distanceInSegment: CGFloat = 0.0

            while distanceInSegment < segmentLength {
                guard charIndex < characters.count * 100 else { break } // 무한 루프 방지

                let char = characters[charIndex % characters.count]
                let charString = String(char)
                let charWidth = characterWidths[charIndex % characters.count]
                let charSize = charString.size(withAttributes: textAttributes)

                let charCenterDistance = distanceInSegment + charWidth / 2.0

                if charCenterDistance > segmentLength {
                    break
                }

                let charX = startPoint.x + normalizedDx * charCenterDistance
                let charY = startPoint.y + normalizedDy * charCenterDistance

                context.saveGState()

                context.translateBy(x: charX, y: charY)
                context.rotate(by: normalizedAngle)

                let remainingInSegment = segmentLength - charCenterDistance
                let availableWidth = remainingInSegment + charWidth / 2.0

                let drawX: CGFloat = -charWidth / 2.0
                let clipX: CGFloat = -charWidth / 2.0

                if availableWidth < charWidth {
                    let clipRect = CGRect(
                        x: clipX,
                        y: -charSize.height / 2.0,
                        width: availableWidth,
                        height: charSize.height
                    )
                    context.clip(to: clipRect)
                }

                let drawRect = CGRect(
                    x: drawX,
                    y: -charSize.height / 2.0,
                    width: charWidth,
                    height: charSize.height
                )
                charString.draw(in: drawRect, withAttributes: textAttributes)

                context.restoreGState()

                distanceInSegment += charWidth
                charIndex += 1

                if distanceInSegment >= segmentLength {
                    break
                }
            }
        }
    }

    // MARK: - Selectable Methods

    func applyColor(_ color: UIColor) {
        currentColor = color
    }

    func applyFont(_ fontStyle: FontStyle) {
        // TextPathWidget doesn't support font changes
    }
}

// MARK: - Text Path Drawing Overlay View

class TextPathDrawingOverlay: UIView {

    /// 사용자가 드래그한 경로의 좌표들
    private(set) var pathPoints: [CGPoint] = []

    /// 반복할 텍스트
    var textToRepeat: String = ""

    /// 드래그 완료 콜백
    var onDrawingComplete: (([CGPoint], CGRect) -> Void)?

    /// 드래그 취소 콜백
    var onDrawingCancelled: (() -> Void)?

    private let textAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 20),
        .foregroundColor: UIColor.white
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        isUserInteractionEnabled = true

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        // Cancel on tap outside drawing
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // Cancel drawing mode
        onDrawingCancelled?()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)

        switch gesture.state {
        case .began:
            pathPoints = [location]

        case .changed:
            pathPoints.append(location)
            setNeedsDisplay()

        case .ended, .cancelled:
            pathPoints.append(location)
            setNeedsDisplay()

            // Calculate bounding rect
            if pathPoints.count >= 2 {
                let boundingRect = calculateBoundingRect()
                onDrawingComplete?(pathPoints, boundingRect)
            } else {
                onDrawingCancelled?()
            }

        default:
            break
        }
    }

    private func calculateBoundingRect() -> CGRect {
        guard !pathPoints.isEmpty else { return .zero }

        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude

        for point in pathPoints {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }

        // Add padding for text height
        let padding: CGFloat = 30
        return CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + padding * 2,
            height: maxY - minY + padding * 2
        )
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              pathPoints.count >= 2 else { return }

        // Draw path line
        drawPathLine(in: context)

        // Draw text along path
        drawTextAlongPath(in: context)
    }

    private func drawPathLine(in context: CGContext) {
        context.saveGState()

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(2.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        context.beginPath()
        context.move(to: pathPoints[0])
        for point in pathPoints.dropFirst() {
            context.addLine(to: point)
        }
        context.strokePath()

        context.restoreGState()
    }

    private func drawTextAlongPath(in context: CGContext) {
        guard !textToRepeat.isEmpty else { return }

        let characters = Array(textToRepeat)
        var characterWidths: [CGFloat] = []

        for char in characters {
            let charString = String(char)
            let size = charString.size(withAttributes: textAttributes)
            characterWidths.append(size.width)
        }

        var charIndex = 0

        for i in 0..<(pathPoints.count - 1) {
            let startPoint = pathPoints[i]
            let endPoint = pathPoints[i + 1]

            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y
            let segmentLength = sqrt(dx * dx + dy * dy)

            guard segmentLength > 0 else { continue }

            let angle = atan2(dy, dx)

            var normalizedAngle = angle
            var isFlipped = false

            if angle > .pi / 2 {
                normalizedAngle = angle - .pi
                isFlipped = true
            } else if angle < -.pi / 2 {
                normalizedAngle = angle + .pi
                isFlipped = true
            }

            let normalizedDx = dx / segmentLength
            let normalizedDy = dy / segmentLength

            var distanceInSegment: CGFloat = 0.0

            while distanceInSegment < segmentLength {
                guard charIndex < characters.count * 100 else { break }

                let char = characters[charIndex % characters.count]
                let charString = String(char)
                let charWidth = characterWidths[charIndex % characters.count]
                let charSize = charString.size(withAttributes: textAttributes)

                let charCenterDistance = distanceInSegment + charWidth / 2.0

                if charCenterDistance > segmentLength {
                    break
                }

                let charX = startPoint.x + normalizedDx * charCenterDistance
                let charY = startPoint.y + normalizedDy * charCenterDistance

                context.saveGState()

                context.translateBy(x: charX, y: charY)
                context.rotate(by: normalizedAngle)

                let remainingInSegment = segmentLength - charCenterDistance
                let availableWidth = remainingInSegment + charWidth / 2.0

                let drawX: CGFloat = -charWidth / 2.0

                if availableWidth < charWidth {
                    let clipRect = CGRect(
                        x: drawX,
                        y: -charSize.height / 2.0,
                        width: availableWidth,
                        height: charSize.height
                    )
                    context.clip(to: clipRect)
                }

                let drawRect = CGRect(
                    x: drawX,
                    y: -charSize.height / 2.0,
                    width: charWidth,
                    height: charSize.height
                )
                charString.draw(in: drawRect, withAttributes: textAttributes)

                context.restoreGState()

                distanceInSegment += charWidth
                charIndex += 1

                if distanceInSegment >= segmentLength {
                    break
                }
            }
        }
    }

    func reset() {
        pathPoints.removeAll()
        setNeedsDisplay()
    }
}
