//
//  ClimbingSessionCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

class ClimbingSessionCell: UIView {
    var onTap: (() -> Void)?
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let disciplineLabel = UILabel()
    private let routesLabel = UILabel()
    private let gradeLabel = UILabel()
    private let chevronView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = ColorSystem.primaryGreen.withAlphaComponent(0.1)
        layer.cornerRadius = 12

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image = UIImage(systemName: "figure.climbing", withConfiguration: config)
        iconView.tintColor = ColorSystem.primaryGreen
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = ColorSystem.mainText

        disciplineLabel.font = .systemFont(ofSize: 13)
        disciplineLabel.textColor = ColorSystem.subText

        routesLabel.font = .systemFont(ofSize: 14, weight: .medium)
        routesLabel.textColor = ColorSystem.primaryGreen

        gradeLabel.font = .systemFont(ofSize: 12)
        gradeLabel.textColor = ColorSystem.subText
        
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        chevronView.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevronView.tintColor = .tertiaryLabel
        chevronView.contentMode = .scaleAspectFit
        
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(disciplineLabel)
        addSubview(routesLabel)
        addSubview(gradeLabel)
        addSubview(chevronView)
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }
        
        disciplineLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }
        
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        routesLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(chevronView.snp.leading).offset(-8)
        }
        
        gradeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(70)
        }
        
        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    
    func configure(with session: ClimbingData) {
        titleLabel.text = session.gymName
        disciplineLabel.text = session.discipline.displayName
        routesLabel.text = "\(session.sentRoutes)/\(session.totalRoutes) 완등"
        if let highestGrade = session.highestGradeSent {
            gradeLabel.text = "최고: \(highestGrade)"
        } else {
            gradeLabel.text = ""
        }
    }
    
    @objc private func handleTap() {
        // Highlight effect
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.alpha = 1.0
            }
        }
        onTap?()
    }
}
