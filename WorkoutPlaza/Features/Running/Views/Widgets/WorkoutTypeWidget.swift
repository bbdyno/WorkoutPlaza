//
//  WorkoutTypeWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  WorkoutTypeWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Workout Type Widget
class WorkoutTypeWidget: BaseStatWidget {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupIcon()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupIcon() {
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalTo(valueLabel)
            make.width.height.equalTo(32)
        }
        
        valueLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
        }
    }
    
    func configure(workoutType: String) {
        titleLabel.text = "운동 종류"
        valueLabel.text = workoutType
        unitLabel.text = ""
        
        // 아이콘 설정
        switch workoutType {
        case "러닝":
            iconImageView.image = UIImage(systemName: "figure.run")
        case "사이클링":
            iconImageView.image = UIImage(systemName: "bicycle")
        case "걷기":
            iconImageView.image = UIImage(systemName: "figure.walk")
        case "하이킹":
            iconImageView.image = UIImage(systemName: "figure.hiking")
        default:
            iconImageView.image = UIImage(systemName: "figure.mixed.cardio")
        }
    }
}
