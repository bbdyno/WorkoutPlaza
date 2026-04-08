//
//  BackgroundTemplateView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

class BackgroundTemplateView: UIView {
    
    enum TemplateStyle: String, CaseIterable {
        case gradient1  // 브랜드 모노톤 그라데이션
        case gradient2  // 딥 차콜 그라데이션
        case gradient3  // 라이트 실버 그라데이션
        case gradient4  // 스톤 그라데이션
        case minimal    // 미니멀 화이트
        case dark       // 다크 모드
        case custom     // 커스텀 그라데이션
    }

    private let gradientLayer = CAGradientLayer()
    private(set) var currentStyle: TemplateStyle = .gradient1
    private(set) var customColors: [UIColor]?
    private(set) var customDirection: GradientDirection?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        layer.addSublayer(gradientLayer)
        applyTemplate(.gradient1)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    static func defaultColors(for style: TemplateStyle) -> [UIColor] {
        switch style {
        case .gradient1:
            return ColorSystem.brandGradientColors
        case .gradient2:
            return [
                UIColor(hex: "#161616") ?? .black,
                UIColor(hex: "#3A3A3A") ?? .darkGray,
                UIColor(hex: "#6B6B6B") ?? .gray
            ]
        case .gradient3:
            return [
                UIColor(hex: "#D8D8D3") ?? .lightGray,
                UIColor(hex: "#F1F0EA") ?? .white
            ]
        case .gradient4:
            return [
                UIColor(hex: "#6A6963") ?? .gray,
                UIColor(hex: "#A9A89F") ?? .lightGray,
                UIColor(hex: "#DDDDD5") ?? .white
            ]
        case .minimal:
            return [ColorSystem.background]
        case .dark:
            return [
                UIColor(hex: "#101010") ?? .black,
                UIColor(hex: "#222222") ?? .darkGray
            ]
        case .custom:
            return []
        }
    }
    
    func applyTemplate(_ style: TemplateStyle) {
        currentStyle = style
        
        switch style {
        case .gradient1:
            applyGradient(
                colors: Self.defaultColors(for: .gradient1),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
            
        case .gradient2:
            applyGradient(
                colors: Self.defaultColors(for: .gradient2),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
            
        case .gradient3:
            applyGradient(
                colors: Self.defaultColors(for: .gradient3),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
            
        case .gradient4:
            applyGradient(
                colors: Self.defaultColors(for: .gradient4),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
            
        case .minimal:
            backgroundColor = ColorSystem.background
            gradientLayer.colors = []
            
        case .dark:
            applyGradient(
                colors: Self.defaultColors(for: .dark),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )

        case .custom:
            // custom은 applyCustomGradient를 통해 설정됨
            // 저장된 customColors가 있으면 적용
            if let colors = customColors {
                let direction = customDirection ?? .topLeftToBottomRight
                applyGradient(
                    colors: colors,
                    startPoint: direction.startPoint,
                    endPoint: direction.endPoint
                )
            }
        }
    }
    
    private func applyGradient(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) {
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }
    
    // 커스텀 그라데이션 적용
    func applyCustomGradient(colors: [UIColor], direction: GradientDirection = .topLeftToBottomRight) {
        currentStyle = .custom
        customColors = colors
        customDirection = direction
        applyGradient(
            colors: colors,
            startPoint: direction.startPoint,
            endPoint: direction.endPoint
        )
    }
    
    // 랜덤 템플릿 적용
    func applyRandomTemplate() {
        let templates: [TemplateStyle] = [.gradient1, .gradient2, .gradient3, .gradient4, .minimal, .dark]
        let randomTemplate = templates.randomElement() ?? .gradient1
        applyTemplate(randomTemplate)
    }

    // 현재 그라데이션 색상 가져오기 (밝기 계산용)
    func getCurrentColors() -> [UIColor] {
        switch currentStyle {
        case .gradient1:
            return Self.defaultColors(for: .gradient1)
        case .gradient2:
            return Self.defaultColors(for: .gradient2)
        case .gradient3:
            return Self.defaultColors(for: .gradient3)
        case .gradient4:
            return Self.defaultColors(for: .gradient4)
        case .minimal:
            return Self.defaultColors(for: .minimal)
        case .dark:
            return Self.defaultColors(for: .dark)
        case .custom:
            return customColors ?? []
        }
    }
}
