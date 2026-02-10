//
//  TextPathPreviewView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit

final class TextPathPreviewView: UIView {
    var points: [CGPoint] = []
    var textToRepeat: String = ""
    var textFont: UIFont = .boldSystemFont(ofSize: 20)
    var textColor: UIColor = .white
    private let letterSpacing: CGFloat = 2.0

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              points.count >= 2,
              !textToRepeat.isEmpty else { return }

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: textColor
        ]

        var segmentLengths: [CGFloat] = []
        var cumulativeDistances: [CGFloat] = [0.0]

        for i in 0..<(points.count - 1) {
            let dx = points[i + 1].x - points[i].x
            let dy = points[i + 1].y - points[i].y
            let length = sqrt(dx * dx + dy * dy)
            segmentLengths.append(length)
            cumulativeDistances.append(cumulativeDistances.last! + length)
        }

        let totalPathLength = cumulativeDistances.last ?? 0
        guard totalPathLength > 0 else { return }

        let characters = Array(textToRepeat)
        var characterWidths: [CGFloat] = []

        for char in characters {
            let charString = String(char)
            let size = charString.size(withAttributes: textAttributes)
            characterWidths.append(size.width)
        }

        var currentDistance: CGFloat = 0.0
        var charIndex = 0

        while currentDistance < totalPathLength && charIndex < characters.count * 100 {
            let char = characters[charIndex % characters.count]
            let charString = String(char)
            let charWidth = characterWidths[charIndex % characters.count]
            let charSize = charString.size(withAttributes: textAttributes)

            let charCenterDistance = currentDistance + charWidth / 2.0

            if charCenterDistance > totalPathLength {
                break
            }

            var segmentIndex = 0
            for i in 0..<segmentLengths.count {
                if charCenterDistance <= cumulativeDistances[i + 1] {
                    segmentIndex = i
                    break
                }
            }

            let startPoint = points[segmentIndex]
            let endPoint = points[segmentIndex + 1]
            let segmentLength = segmentLengths[segmentIndex]

            guard segmentLength > 0 else {
                charIndex += 1
                continue
            }

            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y

            let distanceWithinSegment = charCenterDistance - cumulativeDistances[segmentIndex]

            let normalizedDx = dx / segmentLength
            let normalizedDy = dy / segmentLength

            let charX = startPoint.x + normalizedDx * distanceWithinSegment
            let charY = startPoint.y + normalizedDy * distanceWithinSegment

            let angle = atan2(dy, dx)

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

            currentDistance += charWidth + letterSpacing
            charIndex += 1
        }
    }
}
