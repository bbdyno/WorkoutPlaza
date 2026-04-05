//
//  SpeechBubbleWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/5/26.
//

import UIKit

// MARK: - Payload

struct SpeechBubblePayload: Codable {
    var text: String
    var style: SpeechBubbleStyle
    var bubbleColorHex: String    // 배경색
    var borderColorHex: String    // 테두리색
    var borderWidth: CGFloat      // 0 = 테두리 없음
    var textColorHex: String      // 글자색
    var fontStyleRaw: String      // FontStyle rawValue
    var fontSize: CGFloat         // 기준 폰트 크기

    static var `default`: SpeechBubblePayload {
        SpeechBubblePayload(
            text: NSLocalizedString("bubble.default.text", comment: ""),
            style: .roundedBubble,
            bubbleColorHex: "#FFFFFF",
            borderColorHex: "#000000",
            borderWidth: 2,
            textColorHex: "#000000",
            fontStyleRaw: FontStyle.system.rawValue,
            fontSize: 16
        )
    }

    var bubbleColor: UIColor { UIColor(hex: bubbleColorHex) ?? .white }
    var borderColor: UIColor { UIColor(hex: borderColorHex) ?? .black }
    var textColor:   UIColor { UIColor(hex: textColorHex)   ?? .black }
    var fontStyle:   FontStyle { FontStyle(rawValue: fontStyleRaw) ?? .system }

    func encoded() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decoded(from string: String?) -> SpeechBubblePayload? {
        guard let str = string, let data = str.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(SpeechBubblePayload.self, from: data)
    }
}

// MARK: - Delegate

protocol SpeechBubbleWidgetDelegate: AnyObject {
    func speechBubbleWidgetDidRequestEdit(_ widget: SpeechBubbleWidget)
}

// MARK: - Widget

class SpeechBubbleWidget: UIView, Selectable {

    // MARK: - Selectable
    var isSelected: Bool = false
    var currentColor: UIColor = .black { didSet { payload.textColorHex = currentColor.toHex() ?? "#000000"; setNeedsDisplay() } }
    var currentFontStyle: FontStyle = .system { didSet { payload.fontStyleRaw = currentFontStyle.rawValue; setNeedsDisplay() } }
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    var rotationIndicatorLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?
    var initialSize: CGSize = .zero
    var minimumSize: CGFloat { 70 }

    // MARK: - Properties
    private(set) var payload: SpeechBubblePayload = .default
    weak var bubbleDelegate: SpeechBubbleWidgetDelegate?

    private var initialCenter: CGPoint = .zero

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(payload: SpeechBubblePayload) {
        self.payload = payload
        currentColor = payload.textColor
        currentFontStyle = payload.fontStyle
        if initialSize == .zero, bounds.size != .zero {
            initialSize = bounds.size
        }
        setNeedsDisplay()
    }

    func updatePayload(_ newPayload: SpeechBubblePayload) {
        payload = newPayload
        currentColor = newPayload.textColor
        currentFontStyle = newPayload.fontStyle
        setNeedsDisplay()
        if isSelected { updateSelectionBorder() }
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let style = payload.style

        // 1. 말풍선 외형 경로
        let bubblePath = style.makePath(in: rect)

        // 2. 배경 채우기
        ctx.setFillColor(payload.bubbleColor.cgColor)
        bubblePath.fill()

        // 3. thoughtBubble 점 꼬리
        if style == .thoughtBubble {
            for dotRect in style.makeThoughtDots(in: rect) {
                let dotPath = UIBezierPath(ovalIn: dotRect)
                ctx.setFillColor(payload.bubbleColor.cgColor)
                dotPath.fill()
                if payload.borderWidth > 0 {
                    ctx.setStrokeColor(payload.borderColor.cgColor)
                    ctx.setLineWidth(payload.borderWidth)
                    dotPath.stroke()
                }
            }
        }

        // 4. 테두리
        if payload.borderWidth > 0 {
            ctx.setStrokeColor(payload.borderColor.cgColor)
            ctx.setLineWidth(payload.borderWidth)
            bubblePath.stroke()
        }

        // 5. 텍스트
        let textRect = style.textRect(in: rect)
        guard !textRect.isEmpty, !payload.text.isEmpty else { return }

        let scaleFactor = calculateScaleFactor()
        let fontSize = max(8, payload.fontSize * scaleFactor)
        let font = payload.fontStyle.font(size: fontSize, weight: .medium)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: payload.textColor,
            .paragraphStyle: paragraphStyle
        ]

        let attrStr = NSAttributedString(string: payload.text, attributes: attrs)
        let boundingSize = attrStr.boundingRect(
            with: textRect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let drawY = textRect.minY + max(0, (textRect.height - boundingSize.height) / 2)
        let drawRect = CGRect(x: textRect.minX, y: drawY,
                              width: textRect.width, height: boundingSize.height)
        attrStr.draw(in: drawRect)
    }

    // MARK: - Font Scaling

    func calculateScaleFactor() -> CGFloat {
        guard initialSize != .zero else { return 1.0 }
        let ws = bounds.width / initialSize.width
        let hs = bounds.height / initialSize.height
        return min(max(min(ws, hs), 0.3), 3.0)
    }

    // MARK: - Selectable

    func applyColor(_ color: UIColor) {
        currentColor = color
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
    }

    // MARK: - Gestures

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        tap.require(toFail: doubleTap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))

        [tap, doubleTap, pan, pinch].forEach { addGestureRecognizer($0) }
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        if isSelected {
            bubbleDelegate?.speechBubbleWidgetDidRequestEdit(self)
        } else {
            selectionDelegate?.itemWasSelected(self)
        }
    }

    @objc private func handleDoubleTap() {
        bubbleDelegate?.speechBubbleWidgetDidRequestEdit(self)
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard let superview = g.view?.superview else { return }
        switch g.state {
        case .began:
            initialCenter = center
            if !isSelected { selectionDelegate?.itemWasSelected(self) }
        case .changed:
            let t = g.translation(in: superview)
            let snap = LayoutConstants.snapStep
            let proposed = CGPoint(x: initialCenter.x + t.x, y: initialCenter.y + t.y)
            center = CGPoint(
                x: (proposed.x / snap).rounded() * snap,
                y: (proposed.y / snap).rounded() * snap
            )
            if isSelected { positionResizeHandles() }
            NotificationCenter.default.post(
                name: .widgetDidMove, object: self,
                userInfo: [WidgetMoveNotificationUserInfoKey.phase: WidgetMovePhase.changed.rawValue])
        case .ended, .cancelled:
            NotificationCenter.default.post(
                name: .widgetDidMove, object: self,
                userInfo: [WidgetMoveNotificationUserInfoKey.phase: WidgetMovePhase.ended.rawValue])
        default: break
        }
    }

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        guard DevSettings.shared.isPinchToResizeEnabled else { return }
        if g.state == .began || g.state == .changed {
            transform = transform.scaledBy(x: g.scale, y: g.scale)
            g.scale = 1.0
            if isSelected { positionResizeHandles() }
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
        if isSelected { updateSelectionBorder() }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for handle in resizeHandles {
            let hp = convert(point, to: handle)
            if handle.point(inside: hp, with: event) { return handle }
        }
        return super.hitTest(point, with: event)
    }
}
