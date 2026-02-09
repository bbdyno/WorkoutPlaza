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
    private let typeIconImageView: UIImageView = {
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
        addSubview(typeIconImageView)
        typeIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalTo(valueLabel)
            make.width.height.equalTo(32)
        }
        
        valueLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(typeIconImageView.snp.trailing).offset(8)
        }
    }
    
    func configure(workoutType: String) {
        titleLabel.text = WorkoutPlazaStrings.Widget.Title.Workout.type
        valueLabel.text = workoutType
        unitLabel.text = ""

        // 아이콘 설정
        switch workoutType {
        case WorkoutPlazaStrings.Workout.running:
            typeIconImageView.image = UIImage(systemName: "figure.run")
        case WorkoutPlazaStrings.Workout.cycling:
            typeIconImageView.image = UIImage(systemName: "bicycle")
        case WorkoutPlazaStrings.Workout.walking:
            typeIconImageView.image = UIImage(systemName: "figure.walk")
        case WorkoutPlazaStrings.Workout.hiking:
            typeIconImageView.image = UIImage(systemName: "figure.hiking")
        default:
            typeIconImageView.image = UIImage(systemName: "figure.mixed.cardio")
        }
    }
}
