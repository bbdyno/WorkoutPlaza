//
//  LayoutConstants.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/4/26.
//

import UIKit

enum LayoutConstants {
    // MARK: - Spacing
    static let standardPadding: CGFloat = 12
    static let standardSpacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 12

    // MARK: - Font Sizes
    static let titleFontSize: CGFloat = 12
    static let valueFontSize: CGFloat = 24
    static let unitFontSize: CGFloat = 14
    static let baseFontSize: CGFloat = 20

    // MARK: - Widget Sizing
    static let minimumWidgetSize: CGFloat = 60
    static let textWidgetMinimumSize: CGFloat = 40

    // MARK: - Snap Grid
    static let snapStep: CGFloat = 5.0

    // MARK: - Alpha Values
    static let secondaryAlpha: CGFloat = 0.7

    // MARK: - Resize Handle
    static let resizeHandleSize: CGFloat = 32
    static let resizeCircleSize: CGFloat = 8
    static let resizeHitAreaExpansion: CGFloat = 10
    static let handleIconSize: CGFloat = 28       // 회전/크기조절 핸들의 원형 배경 크기
    static let handleIconFontSize: CGFloat = 14   // 핸들 아이콘 폰트 크기

    // MARK: - Scale Factors
    static let minimumScaleFactor: CGFloat = 0.1
    static let titleMinimumScaleFactor: CGFloat = 0.2
    static let maximumScaleFactor: CGFloat = 3.0
    static let minimumAllowedScale: CGFloat = 0.65      // 0.5 → 0.65
    static let textWidgetMinimumScale: CGFloat = 0.35   // 0.2 → 0.35

    // MARK: - Size Thresholds
    static let significantSizeChange: CGFloat = 5
    static let significantSizeChange2pt: CGFloat = 2

    // MARK: - Minimum Widget Dimensions
    static let minWidth: CGFloat = 80
    static let minHeight: CGFloat = 60
}
