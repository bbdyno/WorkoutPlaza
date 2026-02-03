//
//  BackgroundTemplateView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

class BackgroundTemplateView: UIView {
    
    enum TemplateStyle: String, CaseIterable {
        case gradient1  // 브랜드 그라데이션 (Blue → Green)
        case gradient2  // 퍼플 그라데이션
        case gradient3  // 오렌지 그라데이션
        case gradient4  // 그린 그라데이션
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
    
    func applyTemplate(_ style: TemplateStyle) {
        currentStyle = style
        
        switch style {
        case .gradient1:
            applyGradient(
                colors: ColorSystem.brandGradientColors,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
            
        case .gradient2:
            applyGradient(
                colors: [
                    UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0),
                    UIColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 1.0)
                ],
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
            
        case .gradient3:
            applyGradient(
                colors: [
                    UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0),
                    UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
                ],
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
            
        case .gradient4:
            applyGradient(
                colors: [
                    UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0),
                    UIColor(red: 0.4, green: 0.9, blue: 0.6, alpha: 1.0)
                ],
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
            
        case .minimal:
            backgroundColor = ColorSystem.background
            gradientLayer.colors = []
            
        case .dark:
            applyGradient(
                colors: [
                    UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0),
                    UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                ],
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
            return ColorSystem.brandGradientColors
        case .gradient2:
            return [
                UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0),
                UIColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 1.0)
            ]
        case .gradient3:
            return [
                UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0),
                UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
            ]
        case .gradient4:
            return [
                UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0),
                UIColor(red: 0.4, green: 0.9, blue: 0.6, alpha: 1.0)
            ]
        case .minimal:
            return [.white]
        case .dark:
            return [
                UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0),
                UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            ]
        case .custom:
            return customColors ?? []
        }
    }
}
