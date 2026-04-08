//
//  ColorSystem.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/2/26.
//

import UIKit

/// 블랙 & 화이트 기반 모노크롬 디자인 시스템
/// 스포츠별 액센트 컬러(Blue/Green)로 포인트를 주는 미니멀 컬러 시스템
enum ColorSystem {

    private static let blue = UIColor(hex: "#1459F5") ?? .systemBlue
    private static let blueStrong = UIColor(hex: "#0E3BB8") ?? .systemBlue
    private static let mint = UIColor(hex: "#13BFA0") ?? .systemTeal
    private static let bg = UIColor(hex: "#F4F7FB") ?? .systemBackground
    private static let bgAccent = UIColor(hex: "#DBE8FF") ?? .secondarySystemBackground
    private static let surface = UIColor.white
    private static let surfaceSoft = UIColor(hex: "#ECF2FF") ?? .secondarySystemBackground
    private static let text = UIColor(hex: "#0F172A") ?? .label
    private static let textSoft = UIColor(hex: "#516077") ?? .secondaryLabel
    private static let line = UIColor(hex: "#D7E2F1") ?? .separator
    private static let danger = UIColor(hex: "#E35D6A") ?? .systemRed
    private static let warn = UIColor(hex: "#F59E0B") ?? .systemOrange

    // MARK: - Core Brand Colors

    /// Primary Blue (Running): 청량하고 에너지 넘치는 블루
    static var primaryBlue: UIColor {
        blue
    }

    /// Primary Green (Climbing): 성취감과 자연을 상징하는 민트 그린
    static var primaryGreen: UIColor {
        mint
    }

    // MARK: - Common Control Tint

    /// 공통 컨트롤 틴트: 블랙 (라이트) / 화이트 (다크)
    static var controlTint: UIColor {
        blueStrong
    }

    // MARK: - Interface & Typography

    /// Background: 순백 (라이트) / 순흑 (다크)
    static var background: UIColor {
        bg
    }

    static var backgroundAccent: UIColor {
        bgAccent
    }

    /// Main Text: 순흑 (라이트) / 순백 (다크)
    static var mainText: UIColor {
        text
    }

    /// Sub Text: 날짜, 단위, 설명용 그레이
    static var subText: UIColor {
        textSoft
    }

    /// Divider/Border: 매우 연한 경계선
    static var divider: UIColor {
        line
    }

    /// Card Background: 연한 그레이 #F5F5F5 (라이트) / 진한 그레이 #1A1A1A (다크)
    static var cardBackground: UIColor {
        surface
    }

    /// Card Background Highlight: 선택/강조 상태의 카드 배경
    static var cardBackgroundHighlight: UIColor {
        surfaceSoft
    }

    /// Toast Background: 토스트 메시지 배경
    static var toastBackground: UIColor {
        text.withAlphaComponent(0.9)
    }

    // MARK: - Shadow Colors

    /// Card Shadow: 순수 블랙 @8% opacity
    static var cardShadow: UIColor {
        text.withAlphaComponent(0.12)
    }

    /// Standard Shadow: 일반 그림자
    static let standardShadow = UIColor.black.withAlphaComponent(0.1)

    static var frostedFill: UIColor {
        UIColor.white.withAlphaComponent(0.72)
    }

    // MARK: - Gradient

    /// Brand Gradient Layer: 135도 그라데이션 (Blue → Green)
    /// - Returns: 앱의 상징적인 그라데이션 레이어
    static func brandGradientLayer() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            primaryBlue.cgColor,
            blueStrong.cgColor,
            primaryGreen.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.1)
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

    // MARK: - Sample Route Colors (위젯 미리보기용)

    /// 샘플 루트 빨강: 높은 난이도
    static var sampleRouteRed: UIColor {
        UIColor(hex: "#E55B5B") ?? .systemRed
    }

    /// 샘플 루트 주황: 중간 난이도
    static var sampleRouteOrange: UIColor {
        UIColor(hex: "#FF9B45") ?? .systemOrange
    }

    /// 샘플 루트 초록: 낮은 난이도
    static var sampleRouteGreen: UIColor {
        UIColor(hex: "#7ACB7A") ?? .systemGreen
    }

    // MARK: - Semantic Colors

    /// Success: 성공, 완료 상태
    static var success: UIColor {
        primaryGreen
    }

    /// Warning: 경고, 주의 상태
    static var warning: UIColor {
        warn
    }

    /// Error: 에러, 위험 상태
    static var error: UIColor {
        danger
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

// MARK: - App Chrome

enum AppChrome {

    static func installGlobalAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = ColorSystem.background.withAlphaComponent(0.88)
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        navAppearance.shadowColor = .clear
        navAppearance.titleTextAttributes = [
            .foregroundColor: ColorSystem.mainText,
            .font: AppFont.bodyBold(17)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: ColorSystem.mainText,
            .font: AppFont.display(32)
        ]

        let barButtonAppearance = UIBarButtonItemAppearance()
        barButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: ColorSystem.primaryBlue,
            .font: AppFont.bodySemiBold(15)
        ]
        navAppearance.buttonAppearance = barButtonAppearance
        navAppearance.doneButtonAppearance = barButtonAppearance

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = ColorSystem.primaryBlue

        let tableAppearance = UITableView.appearance()
        tableAppearance.backgroundColor = .clear
        tableAppearance.separatorColor = ColorSystem.divider

        let groupedHeader = UITableViewHeaderFooterView.appearance()
        groupedHeader.tintColor = .clear
    }

    static func installAmbientBackground(in view: UIView) {
        guard view.subviews.contains(where: { $0 is AmbientBackgroundView }) == false else { return }

        let backgroundView = AmbientBackgroundView()
        view.insertSubview(backgroundView, at: 0)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    static func stylePrimaryButton(_ button: UIButton, cornerRadius: CGFloat = 20) {
        button.layer.cornerRadius = cornerRadius
        button.layer.cornerCurve = .continuous
        button.layer.masksToBounds = false
        button.backgroundColor = .clear
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = AppFont.bodyBold(16)
        button.layer.shadowColor = ColorSystem.primaryBlue.withAlphaComponent(0.36).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 12)
        button.layer.shadowRadius = 24
    }

    static func applyPrimaryGradient(to view: UIView, cornerRadius: CGFloat) {
        let layerName = "AppChromePrimaryGradient"
        view.layer.sublayers?
            .filter { $0.name == layerName }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.name = layerName
        gradient.frame = view.bounds
        gradient.cornerRadius = cornerRadius
        gradient.colors = [
            ColorSystem.primaryBlue.cgColor,
            ColorSystem.primaryBlue.withAlphaComponent(0.92).cgColor,
            ColorSystem.primaryGreen.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.1)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradient, at: 0)
    }
}

final class AmbientBackgroundView: UIView {
    private let topOrb = UIView()
    private let bottomOrb = UIView()
    private let gradientLayer = CAGradientLayer()
    private let topBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let bottomBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.insertSublayer(gradientLayer, at: 0)
        [topOrb, bottomOrb].forEach {
            $0.layer.cornerRadius = 180
            $0.layer.masksToBounds = true
            addSubview($0)
        }
        topOrb.addSubview(topBlur)
        bottomOrb.addSubview(bottomBlur)

        topOrb.backgroundColor = ColorSystem.primaryBlue.withAlphaComponent(0.18)
        bottomOrb.backgroundColor = ColorSystem.primaryGreen.withAlphaComponent(0.16)
        topOrb.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        bottomOrb.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds
        gradientLayer.colors = [
            ColorSystem.backgroundAccent.cgColor,
            ColorSystem.background.cgColor,
            UIColor.white.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.08, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.92, y: 1)

        topOrb.frame = CGRect(x: -120, y: -40, width: 280, height: 280)
        bottomOrb.frame = CGRect(x: bounds.width - 180, y: bounds.height - 240, width: 240, height: 240)

        topOrb.layer.cornerRadius = topOrb.bounds.width / 2
        bottomOrb.layer.cornerRadius = bottomOrb.bounds.width / 2
        topBlur.frame = topOrb.bounds
        bottomBlur.frame = bottomOrb.bounds
    }
}
