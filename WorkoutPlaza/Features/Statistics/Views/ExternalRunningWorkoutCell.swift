//
//  ExternalRunningWorkoutCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

class ExternalRunningWorkoutCell: UIView {
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let externalBadge = UILabel()
    private let distanceLabel = UILabel()
    private let durationLabel = UILabel()
    private let paceLabel = UILabel()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemBlue.withAlphaComponent(0.1)
        layer.cornerRadius = 12
        
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image = UIImage(systemName: "figure.run", withConfiguration: config)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label
        
        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = .secondaryLabel
        
        externalBadge.text = "외부"
        externalBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        externalBadge.textColor = .white
        externalBadge.backgroundColor = .systemOrange
        externalBadge.textAlignment = .center
        externalBadge.layer.cornerRadius = 4
        externalBadge.clipsToBounds = true
        
        distanceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        distanceLabel.textColor = .systemBlue
        
        durationLabel.font = .systemFont(ofSize: 13)
        durationLabel.textColor = .secondaryLabel
        
        paceLabel.font = .systemFont(ofSize: 12)
        paceLabel.textColor = .tertiaryLabel
        
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(timeLabel)
        addSubview(externalBadge)
        addSubview(distanceLabel)
        addSubview(durationLabel)
        addSubview(paceLabel)
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }
        
        externalBadge.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(timeLabel.snp.trailing).offset(8)
            make.width.equalTo(30)
            make.height.equalTo(16)
        }
        
        distanceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        paceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(durationLabel)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(70)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with workout: ExternalWorkout) {
        titleLabel.text = workout.workoutData.type
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: workout.workoutData.startDate)
        
        distanceLabel.text = String(format: "%.2f km", workout.workoutData.distance / 1000)
        
        let minutes = Int(workout.workoutData.duration) / 60
        durationLabel.text = "\(minutes)분"
        
        if workout.workoutData.distance > 0 {
            let pace = (workout.workoutData.duration / 60) / (workout.workoutData.distance / 1000)
            let paceMin = Int(pace)
            let paceSec = Int((pace - Double(paceMin)) * 60)
            paceLabel.text = String(format: "%d'%02d\"/km", paceMin, paceSec)
        } else {
            paceLabel.text = "-"
        }
    }
}
