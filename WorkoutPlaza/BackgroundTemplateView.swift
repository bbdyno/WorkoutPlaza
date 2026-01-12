//
//  BackgroundTemplateView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

class BackgroundTemplateView: UIView {
    
    enum TemplateStyle {
        case gradient1  // 블루 그라데이션
        case gradient2  // 퍼플 그라데이션
        case gradient3  // 오렌지 그라데이션
        case gradient4  // 그린 그라데이션
        case minimal    // 미니멀 화이트
        case dark       // 다크 모드
    }
    
    private let gradientLayer = CAGradientLayer()
    private var currentStyle: TemplateStyle = .gradient1
    
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
                colors: [
                    UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
                    UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
                ],
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
            backgroundColor = .white
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
        }
    }
    
    private func applyGradient(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) {
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }
    
    // 커스텀 그라데이션 적용
    func applyCustomGradient(colors: [UIColor]) {
        applyGradient(
            colors: colors,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
    }
    
    // 랜덤 템플릿 적용
    func applyRandomTemplate() {
        let templates: [TemplateStyle] = [.gradient1, .gradient2, .gradient3, .gradient4, .minimal, .dark]
        let randomTemplate = templates.randomElement() ?? .gradient1
        applyTemplate(randomTemplate)
    }
}
