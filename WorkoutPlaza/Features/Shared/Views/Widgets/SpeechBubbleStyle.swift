//
//  SpeechBubbleStyle.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/5/26.
//

import UIKit

// MARK: - Speech Bubble Style

enum SpeechBubbleStyle: String, Codable, CaseIterable {
    case roundedBubble       // 둥근 사각형 + 아래 중앙 꼬리 (무료)
    case roundedBubbleLeft   // 둥근 사각형 + 아래 왼쪽 꼬리
    case roundedBubbleRight  // 둥근 사각형 + 아래 오른쪽 꼬리
    case ovalBubble          // 타원형 + 아래 꼬리
    case squareBubble        // 직각 사각형 + 아래 중앙 꼬리
    case thoughtBubble       // 구름형 생각풍선 (점 꼬리)
    case shoutBubble         // 톱니형 외침풍선
    case noTail              // 꼬리 없는 둥근 박스

    var displayName: String {
        switch self {
        case .roundedBubble:      return NSLocalizedString("bubble.style.rounded", comment: "말풍선")
        case .roundedBubbleLeft:  return NSLocalizedString("bubble.style.roundedLeft", comment: "말풍선 (왼쪽)")
        case .roundedBubbleRight: return NSLocalizedString("bubble.style.roundedRight", comment: "말풍선 (오른쪽)")
        case .ovalBubble:         return NSLocalizedString("bubble.style.oval", comment: "타원 말풍선")
        case .squareBubble:       return NSLocalizedString("bubble.style.square", comment: "각진 말풍선")
        case .thoughtBubble:      return NSLocalizedString("bubble.style.thought", comment: "생각 풍선")
        case .shoutBubble:        return NSLocalizedString("bubble.style.shout", comment: "외침 풍선")
        case .noTail:             return NSLocalizedString("bubble.style.noTail", comment: "박스")
        }
    }

    /// 무료 사용자에게 제공되는 기본 스타일
    var isProRequired: Bool {
        self != .roundedBubble
    }

    // MARK: - Layout

    /// 꼬리가 차지하는 높이 비율 (전체 rect 기준)
    var tailHeightRatio: CGFloat {
        switch self {
        case .thoughtBubble: return 0.22  // 점 꼬리 영역
        case .shoutBubble:   return 0.0
        case .noTail:        return 0.0
        default:             return 0.20
        }
    }

    /// 텍스트를 배치할 영역 (rect 기준)
    func textRect(in rect: CGRect) -> CGRect {
        let tailH = rect.height * tailHeightRatio
        switch self {
        case .shoutBubble:
            return rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.18)
        default:
            let bodyRect = CGRect(x: rect.minX, y: rect.minY,
                                  width: rect.width, height: rect.height - tailH)
            return bodyRect.insetBy(dx: 12, dy: 10)
        }
    }

    // MARK: - Path Generation

    /// 말풍선 전체 외형 경로 (fill + stroke 용)
    func makePath(in rect: CGRect) -> UIBezierPath {
        switch self {
        case .roundedBubble:      return makeRoundedTailPath(in: rect, tailX: 0.5)
        case .roundedBubbleLeft:  return makeRoundedTailPath(in: rect, tailX: 0.25)
        case .roundedBubbleRight: return makeRoundedTailPath(in: rect, tailX: 0.75)
        case .ovalBubble:         return makeOvalTailPath(in: rect)
        case .squareBubble:       return makeSquareTailPath(in: rect)
        case .thoughtBubble:      return makeThoughtPath(in: rect)
        case .shoutBubble:        return makeShoutPath(in: rect)
        case .noTail:             return UIBezierPath(roundedRect: rect, cornerRadius: 14)
        }
    }

    /// thoughtBubble의 점 꼬리 경로 (별도 그리기)
    func makeThoughtDots(in rect: CGRect) -> [CGRect] {
        let tailH = rect.height * tailHeightRatio
        let bodyBottom = rect.maxY - tailH
        let dotAreaY = bodyBottom + 4
        let sizes: [CGFloat] = [10, 7, 4]
        let startX = rect.minX + rect.width * 0.28
        var result: [CGRect] = []
        var x = startX
        var y = dotAreaY
        for (i, size) in sizes.enumerated() {
            _ = i
            result.append(CGRect(x: x - size / 2, y: y, width: size, height: size))
            x -= size * 0.4
            y += size * 0.9
        }
        return result
    }

    // MARK: - Private Path Builders

    private func makeRoundedTailPath(in rect: CGRect, tailX: CGFloat) -> UIBezierPath {
        let tailH = rect.height * tailHeightRatio
        let bodyH = rect.height - tailH
        let r: CGFloat = 14  // corner radius
        let tw: CGFloat = 22 // tail base width
        let bodyRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: bodyH)

        let tailCenterX = rect.minX + rect.width * tailX
        let tailLeft  = max(bodyRect.minX + r + 2, tailCenterX - tw / 2)
        let tailRight = min(bodyRect.maxX - r - 2, tailCenterX + tw / 2)

        let path = UIBezierPath()
        // Start at top-left corner arc end
        path.move(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.minY))
        // Top edge
        path.addLine(to: CGPoint(x: bodyRect.maxX - r, y: bodyRect.minY))
        // Top-right corner
        path.addArc(withCenter: CGPoint(x: bodyRect.maxX - r, y: bodyRect.minY + r),
                    radius: r, startAngle: -.pi / 2, endAngle: 0, clockwise: true)
        // Right edge
        path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY - r))
        // Bottom-right corner
        path.addArc(withCenter: CGPoint(x: bodyRect.maxX - r, y: bodyRect.maxY - r),
                    radius: r, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        // Bottom edge right segment
        path.addLine(to: CGPoint(x: tailRight, y: bodyRect.maxY))
        // Tail
        path.addLine(to: CGPoint(x: tailCenterX, y: rect.maxY))
        path.addLine(to: CGPoint(x: tailLeft, y: bodyRect.maxY))
        // Bottom edge left segment
        path.addLine(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY))
        // Bottom-left corner
        path.addArc(withCenter: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY - r),
                    radius: r, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        // Left edge
        path.addLine(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + r))
        // Top-left corner
        path.addArc(withCenter: CGPoint(x: bodyRect.minX + r, y: bodyRect.minY + r),
                    radius: r, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)
        path.close()
        return path
    }

    private func makeOvalTailPath(in rect: CGRect) -> UIBezierPath {
        let tailH = rect.height * tailHeightRatio
        let bodyRect = CGRect(x: rect.minX, y: rect.minY,
                              width: rect.width, height: rect.height - tailH)
        let cx = bodyRect.midX, cy = bodyRect.midY
        let rx = bodyRect.width / 2, ry = bodyRect.height / 2

        let path = UIBezierPath(ovalIn: bodyRect)

        // Tail: isosceles triangle from bottom of oval
        let tw: CGFloat = 18
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: cx - tw / 2, y: cy + ry - 4))
        tailPath.addLine(to: CGPoint(x: cx, y: rect.maxY))
        tailPath.addLine(to: CGPoint(x: cx + tw / 2, y: cy + ry - 4))
        tailPath.close()

        path.append(tailPath)
        return path
    }

    private func makeSquareTailPath(in rect: CGRect) -> UIBezierPath {
        let tailH = rect.height * tailHeightRatio
        let bodyRect = CGRect(x: rect.minX, y: rect.minY,
                              width: rect.width, height: rect.height - tailH)
        let cx = rect.midX
        let tw: CGFloat = 22

        let path = UIBezierPath()
        path.move(to: bodyRect.origin)
        path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.minY))
        path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY))
        path.addLine(to: CGPoint(x: cx + tw / 2, y: bodyRect.maxY))
        path.addLine(to: CGPoint(x: cx, y: rect.maxY))
        path.addLine(to: CGPoint(x: cx - tw / 2, y: bodyRect.maxY))
        path.addLine(to: CGPoint(x: bodyRect.minX, y: bodyRect.maxY))
        path.close()
        return path
    }

    private func makeThoughtPath(in rect: CGRect) -> UIBezierPath {
        let tailH = rect.height * tailHeightRatio
        let bodyRect = CGRect(x: rect.minX, y: rect.minY,
                              width: rect.width, height: rect.height - tailH)

        // Cloud body: rounded rect with scalloped top
        let scallop: CGFloat = 10
        let r: CGFloat = 12
        let path = UIBezierPath()

        // Top edge with scallops
        let scallops = Int(bodyRect.width / (scallop * 2.2))
        let scallopSpacing = bodyRect.width / CGFloat(max(scallops, 1))
        path.move(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + scallop))
        for i in 0..<max(scallops, 1) {
            let cx = bodyRect.minX + CGFloat(i) * scallopSpacing + scallopSpacing / 2
            path.addArc(withCenter: CGPoint(x: cx, y: bodyRect.minY + scallop),
                        radius: scallop * 0.85,
                        startAngle: .pi, endAngle: 0, clockwise: false)
        }
        // Right side
        path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY - r))
        path.addArc(withCenter: CGPoint(x: bodyRect.maxX - r, y: bodyRect.maxY - r),
                    radius: r, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        // Bottom
        path.addLine(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY))
        path.addArc(withCenter: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY - r),
                    radius: r, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        // Left side
        path.addLine(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + scallop))
        path.close()
        return path
    }

    private func makeShoutPath(in rect: CGRect) -> UIBezierPath {
        let cx = rect.midX, cy = rect.midY
        let outerR = min(rect.width, rect.height) * 0.5
        let innerR = outerR * 0.72
        let points = 14  // 톱니 수

        let path = UIBezierPath()
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let r = i % 2 == 0 ? outerR : innerR
            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.close()
        return path
    }
}
