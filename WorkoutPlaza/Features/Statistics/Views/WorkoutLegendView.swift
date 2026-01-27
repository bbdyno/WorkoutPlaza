//
//  WorkoutLegendView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

class WorkoutLegendView: UIView {
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 20
        container.alignment = .center
        container.distribution = .equalCentering
        
        // Running legend
        let runningLegend = createLegendItem(color: .systemBlue, text: "러닝")
        container.addArrangedSubview(runningLegend)
        
        // Climbing legend
        let climbingLegend = createLegendItem(color: .systemOrange, text: "클라이밍")
        container.addArrangedSubview(climbingLegend)
        
        addSubview(container)
        container.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(8)
        }
    }
    
    private func createLegendItem(color: UIColor, text: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 5
        dot.snp.makeConstraints { make in
            make.width.height.equalTo(10)
        }
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        
        stack.addArrangedSubview(dot)
        stack.addArrangedSubview(label)
        
        return stack
    }
}
