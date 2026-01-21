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

    /// 정규화된 경로 좌표 (0~1 범위, 비율 유지용)
    private var normalizedPathPoints: [CGPoint] = []

    /// 현재 크기에 맞게 스케일된 경로 좌표
    private var scaledPathPoints: [CGPoint] = []

    /// 텍스트 색상
    private var textColor: UIColor = .white

    /// 기본 텍스트 폰트 사이즈
    private let baseFontSize: CGFloat = 20

    /// 글자 간격
    private let letterSpacing: CGFloat = 2.0

    // MARK: - Initialization

    init(text: String, pathPoints: [CGPoint], frame: CGRect) {
        self.textToRepeat = text
        super.init(frame: frame)
        self.initialSize = frame.size

        // 경로를 정규화 (0~1 범위로 변환)
        let simplified = Self.simplifyPath(pathPoints, minDistance: 8.0)
        self.normalizedPathPoints = simplified.map { point in
            CGPoint(
                x: point.x / frame.width,
                y: point.y / frame.height
            )
        }
        updateScaledPathPoints()
        setupView()
    }

    // MARK: - Path Simplification

    /// 경로 단순화: 너무 가까운 점들을 제거하여 각도 계산을 안정화
    private static func simplifyPath(_ points: [CGPoint], minDistance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var simplified: [CGPoint] = [points[0]]

        for i in 1..<points.count {
            let lastPoint = simplified.last!
            let currentPoint = points[i]
            let dx = currentPoint.x - lastPoint.x
            let dy = currentPoint.y - lastPoint.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance >= minDistance {
                simplified.append(currentPoint)
            }
        }

        // 마지막 점은 항상 포함
        if let last = points.last, simplified.last != last {
            simplified.append(last)
        }

        return simplified.count >= 2 ? simplified : points
    }

    /// 현재 bounds에 맞게 스케일된 경로 좌표 업데이트
    private func updateScaledPathPoints() {
        scaledPathPoints = normalizedPathPoints.map { point in
            CGPoint(
                x: point.x * bounds.width,
                y: point.y * bounds.height
            )
        }
    }

    /// 현재 스케일에 맞는 폰트 사이즈 계산
    private var currentFontSize: CGFloat {
        guard initialSize.width > 0 else { return baseFontSize }
        let scale = bounds.width / initialSize.width
        return baseFontSize * scale
    }

    /// 현재 스케일에 맞는 글자 간격 계산
    private var currentLetterSpacing: CGFloat {
        guard initialSize.width > 0 else { return letterSpacing }
        let scale = bounds.width / initialSize.width
        return letterSpacing * scale
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateScaledPathPoints()
        updateSelectionBorder()
        positionResizeHandles()
        setNeedsDisplay()
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
            // 이동 시 핸들 위치 업데이트
            if isSelected {
                positionResizeHandles()
            }

        default:
            break
        }
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              scaledPathPoints.count >= 2 else { return }

        drawTextAlongPath(in: context)
    }

    /// 경로를 따라 텍스트 그리기
    private func drawTextAlongPath(in context: CGContext) {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: currentFontSize),
            .foregroundColor: textColor
        ]

        // 각 세그먼트의 길이와 누적 거리 계산
        var segmentLengths: [CGFloat] = []
        var cumulativeDistances: [CGFloat] = [0.0]

        for i in 0..<(scaledPathPoints.count - 1) {
            let dx = scaledPathPoints[i + 1].x - scaledPathPoints[i].x
            let dy = scaledPathPoints[i + 1].y - scaledPathPoints[i].y
            let length = sqrt(dx * dx + dy * dy)
            segmentLengths.append(length)
            cumulativeDistances.append(cumulativeDistances.last! + length)
        }

        let totalPathLength = cumulativeDistances.last ?? 0
        guard totalPathLength > 0 else { return }

        // 각 글자의 크기 미리 계산
        let characters = Array(textToRepeat)
        var characterWidths: [CGFloat] = []

        for char in characters {
            let charString = String(char)
            let size = charString.size(withAttributes: textAttributes)
            characterWidths.append(size.width)
        }

        // 전체 경로를 따라 글자 배치
        var currentDistance: CGFloat = 0.0
        var charIndex = 0

        while currentDistance < totalPathLength && charIndex < characters.count * 100 {
            let char = characters[charIndex % characters.count]
            let charString = String(char)
            let charWidth = characterWidths[charIndex % characters.count]
            let charSize = charString.size(withAttributes: textAttributes)

            // 글자 중심의 경로상 위치
            let charCenterDistance = currentDistance + charWidth / 2.0

            if charCenterDistance > totalPathLength {
                break
            }

            // 이 위치가 어느 세그먼트에 해당하는지 찾기
            var segmentIndex = 0
            for i in 0..<segmentLengths.count {
                if charCenterDistance <= cumulativeDistances[i + 1] {
                    segmentIndex = i
                    break
                }
            }

            let startPoint = scaledPathPoints[segmentIndex]
            let endPoint = scaledPathPoints[segmentIndex + 1]
            let segmentLength = segmentLengths[segmentIndex]

            guard segmentLength > 0 else {
                charIndex += 1
                continue
            }

            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y

            // 세그먼트 내에서의 위치 계산
            let distanceWithinSegment = charCenterDistance - cumulativeDistances[segmentIndex]

            let normalizedDx = dx / segmentLength
            let normalizedDy = dy / segmentLength

            let charX = startPoint.x + normalizedDx * distanceWithinSegment
            let charY = startPoint.y + normalizedDy * distanceWithinSegment

            // 각도 계산 (세그먼트 방향 그대로 사용)
            let angle = atan2(dy, dx)

            // 글자 그리기
            context.saveGState()
            context.translateBy(x: charX, y: charY)
            context.rotate(by: angle)

            let drawRect = CGRect(
                x: -charWidth / 2.0,
                y: -charSize.height / 2.0,
                width: charWidth,
                height: charSize.height
            )
            charString.draw(in: drawRect, withAttributes: textAttributes)

            context.restoreGState()

            // 다음 글자 위치로 이동
            currentDistance += charWidth + currentLetterSpacing
            charIndex += 1
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

    private let letterSpacing: CGFloat = 2.0

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              pathPoints.count >= 2 else { return }

        // Draw text along path only (no path line)
        drawTextAlongPath(in: context)
    }

    /// 경로 단순화: 너무 가까운 점들을 제거
    private func simplifyPath(_ points: [CGPoint], minDistance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var simplified: [CGPoint] = [points[0]]

        for i in 1..<points.count {
            let lastPoint = simplified.last!
            let currentPoint = points[i]
            let dx = currentPoint.x - lastPoint.x
            let dy = currentPoint.y - lastPoint.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance >= minDistance {
                simplified.append(currentPoint)
            }
        }

        if let last = points.last, simplified.last != last {
            simplified.append(last)
        }

        return simplified.count >= 2 ? simplified : points
    }

    private func drawTextAlongPath(in context: CGContext) {
        guard !textToRepeat.isEmpty else { return }

        // 경로 단순화
        let simplifiedPath = simplifyPath(pathPoints, minDistance: 8.0)
        guard simplifiedPath.count >= 2 else { return }

        // 각 세그먼트의 길이와 누적 거리 계산
        var segmentLengths: [CGFloat] = []
        var cumulativeDistances: [CGFloat] = [0.0]

        for i in 0..<(simplifiedPath.count - 1) {
            let dx = simplifiedPath[i + 1].x - simplifiedPath[i].x
            let dy = simplifiedPath[i + 1].y - simplifiedPath[i].y
            let length = sqrt(dx * dx + dy * dy)
            segmentLengths.append(length)
            cumulativeDistances.append(cumulativeDistances.last! + length)
        }

        let totalPathLength = cumulativeDistances.last ?? 0
        guard totalPathLength > 0 else { return }

        // 각 글자의 크기 미리 계산
        let characters = Array(textToRepeat)
        var characterWidths: [CGFloat] = []

        for char in characters {
            let charString = String(char)
            let size = charString.size(withAttributes: textAttributes)
            characterWidths.append(size.width)
        }

        // 전체 경로를 따라 글자 배치
        var currentDistance: CGFloat = 0.0
        var charIndex = 0

        while currentDistance < totalPathLength && charIndex < characters.count * 100 {
            let char = characters[charIndex % characters.count]
            let charString = String(char)
            let charWidth = characterWidths[charIndex % characters.count]
            let charSize = charString.size(withAttributes: textAttributes)

            // 글자 중심의 경로상 위치
            let charCenterDistance = currentDistance + charWidth / 2.0

            if charCenterDistance > totalPathLength {
                break
            }

            // 이 위치가 어느 세그먼트에 해당하는지 찾기
            var segmentIndex = 0
            for i in 0..<segmentLengths.count {
                if charCenterDistance <= cumulativeDistances[i + 1] {
                    segmentIndex = i
                    break
                }
            }

            let startPoint = simplifiedPath[segmentIndex]
            let endPoint = simplifiedPath[segmentIndex + 1]
            let segmentLength = segmentLengths[segmentIndex]

            guard segmentLength > 0 else {
                charIndex += 1
                continue
            }

            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y

            // 세그먼트 내에서의 위치 계산
            let distanceWithinSegment = charCenterDistance - cumulativeDistances[segmentIndex]

            let normalizedDx = dx / segmentLength
            let normalizedDy = dy / segmentLength

            let charX = startPoint.x + normalizedDx * distanceWithinSegment
            let charY = startPoint.y + normalizedDy * distanceWithinSegment

            // 각도 계산 (세그먼트 방향 그대로 사용)
            let angle = atan2(dy, dx)

            // 글자 그리기
            context.saveGState()
            context.translateBy(x: charX, y: charY)
            context.rotate(by: angle)

            let drawRect = CGRect(
                x: -charWidth / 2.0,
                y: -charSize.height / 2.0,
                width: charWidth,
                height: charSize.height
            )
            charString.draw(in: drawRect, withAttributes: textAttributes)

            context.restoreGState()

            // 다음 글자 위치로 이동
            currentDistance += charWidth + letterSpacing
            charIndex += 1
        }
    }

    func reset() {
        pathPoints.removeAll()
        setNeedsDisplay()
    }
}
