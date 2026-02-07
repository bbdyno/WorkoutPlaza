//
//  ColorSystem.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/2/26.
//

import UIKit

/// Active Card 운동 앱의 색상 디자인 시스템
/// 텍스트 정보보다 시각적 수치와 카드의 세련미를 강조하는 색상 시스템
enum ColorSystem {

    // MARK: - Core Brand Colors

    /// Primary Blue (Running): 청량하고 에너지 넘치는 블루
    static var primaryBlue: UIColor {
        WorkoutPlazaAsset.primaryBlue.color
    }

    /// Primary Green (Climbing): 성취감과 자연을 상징하는 민트 그린
    static var primaryGreen: UIColor {
        WorkoutPlazaAsset.primaryGreen.color
    }

    // MARK: - Common Control Tint

    /// 공통 컨트롤 틴트: 다크 그레이 (세그먼트 컨트롤, 피커 등)
    static var controlTint: UIColor {
        WorkoutPlazaAsset.controlTint.color
    }

    // MARK: - Interface & Typography

    /// Background: 매우 밝은 그레이 (라이트) / 진한 검정 (다크)
    static var background: UIColor {
        WorkoutPlazaAsset.background.color
    }

    /// Main Text: 가독성을 위한 짙은 차콜 (라이트) / 밝은 화이트 (다크)
    static var mainText: UIColor {
        WorkoutPlazaAsset.mainText.color
    }

    /// Sub Text: 날짜, 단위, 설명용 그레이
    static var subText: UIColor {
        WorkoutPlazaAsset.subText.color
    }

    /// Divider/Border: 매우 연한 경계선
    static var divider: UIColor {
        WorkoutPlazaAsset.divider.color
    }

    /// Card Background: 순수 화이트 (라이트) / 진한 그레이 (다크)
    static var cardBackground: UIColor {
        WorkoutPlazaAsset.cardBackground.color
    }

    /// Card Background Highlight: 선택/강조 상태의 카드 배경
    static var cardBackgroundHighlight: UIColor {
        WorkoutPlazaAsset.cardBackgroundHighlight.color
    }

    // MARK: - Shadow Colors

    /// Card Shadow: Blue 색상이 미세하게 섞인 그림자
    static var cardShadow: UIColor {
        WorkoutPlazaAsset.cardShadow.color
    }

    /// Standard Shadow: 일반 그림자
    static let standardShadow = UIColor.black.withAlphaComponent(0.1)

    // MARK: - Gradient

    /// Brand Gradient Layer: 135도 그라데이션 (Blue → Green)
    /// - Returns: 앱의 상징적인 그라데이션 레이어
    static func brandGradientLayer() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            primaryBlue.cgColor,
            primaryGreen.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        return gradientLayer
    }

    /// Brand Gradient Colors: UIColor 배열로 반환
    static var brandGradientColors: [UIColor] {
        return [primaryBlue, primaryGreen]
    }

    // MARK: - Sport Type Colors

    /// 운동 타입별 색상 반환
    /// - Parameter sportType: 운동 타입
    /// - Returns: 해당 운동 타입의 테마 색상
    static func color(for sportType: SportType) -> UIColor {
        switch sportType {
        case .running:
            return primaryBlue
        case .climbing:
            return primaryGreen
        }
    }

    // MARK: - Handle Colors

    /// Rotation Handle: 회전 핸들용 블루
    static let rotationHandle = primaryBlue

    /// Resize Handle: 크기조절 핸들용 그린
    static let resizeHandle = primaryGreen

    // MARK: - Semantic Colors

    /// Success: 성공, 완료 상태
    static var success: UIColor {
        primaryGreen
    }

    /// Warning: 경고, 주의 상태
    static var warning: UIColor {
        WorkoutPlazaAsset.warning.color
    }

    /// Error: 에러, 위험 상태
    static var error: UIColor {
        WorkoutPlazaAsset.error.color
    }

    /// Info: 정보, 안내
    static var info: UIColor {
        primaryBlue
    }

}

// MARK: - UIColor Extension

extension UIColor {
    /// Hex 문자열로 UIColor 생성
    /// - Parameter hex: "#RRGGBB" 또는 "RRGGBB" 형식의 문자열
    /// - Note: 기존 CardPersistenceManager에 정의된 init?(hex:)를 사용하세요
    // convenience init(hex: String) { ... }

    /// UIColor를 Hex 문자열로 변환
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255)

        return String(format: "#%06x", rgb)
    }

    /// 색상의 인지 밝기를 계산 (0.0 = 어두움, 1.0 = 밝음)
    /// Perceived brightness formula: (0.299*R + 0.587*G + 0.114*B)
    var perceivedBrightness: CGFloat {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        return (0.299 * r + 0.587 * g + 0.114 * b)
    }

    /// 배경이 밝은지 어두운지 판단
    var isLight: Bool {
        return perceivedBrightness > 0.5
    }
}

// MARK: - UIImage Extension

extension UIImage {
    /// 이미지의 평균 색상 계산
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }

        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        guard let filter = CIFilter(
            name: "CIAreaAverage",
            parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]
        ) else { return nil }

        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
    }

    /// 이미지가 밝은지 어두운지 판단
    var isLight: Bool {
        return averageColor?.isLight ?? true
    }
}

// MARK: - CALayer Extension

extension CALayer {
    /// 브랜드 그라데이션 적용
    func applyBrandGradient() {
        let gradientLayer = ColorSystem.brandGradientLayer()
        gradientLayer.frame = bounds
        insertSublayer(gradientLayer, at: 0)
    }

    /// 카드 스타일 그림자 적용
    func applyCardShadow() {
        shadowColor = ColorSystem.cardShadow.cgColor
        shadowOpacity = 1.0
        shadowOffset = CGSize(width: 0, height: 4)
        shadowRadius = 12
    }

    /// 표준 그림자 적용
    func applyStandardShadow() {
        shadowColor = ColorSystem.standardShadow.cgColor
        shadowOpacity = 1.0
        shadowOffset = CGSize(width: 0, height: 2)
        shadowRadius = 8
    }
}

// MARK: - UIView Extension

extension UIView {
    /// 브랜드 그라데이션 배경 설정
    func setGradientBackground() {
        let gradientLayer = ColorSystem.brandGradientLayer()
        gradientLayer.frame = bounds

        // 기존 그라데이션 레이어 제거
        layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }

        // 새 그라데이션 레이어 추가
        layer.insertSublayer(gradientLayer, at: 0)
    }

    /// 카드 스타일 적용 (배경 + 그림자)
    func applyCardStyle(cornerRadius: CGFloat = 12) {
        backgroundColor = ColorSystem.cardBackground
        layer.cornerRadius = cornerRadius
        layer.applyCardShadow()
    }
}
