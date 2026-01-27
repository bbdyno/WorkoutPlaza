//
//  RunningWorkoutCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

class RunningWorkoutCell: UIView {
    var onTap: (() -> Void)?
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let distanceLabel = UILabel()
    private let durationLabel = UILabel()
    private let paceLabel = UILabel()
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
        
        distanceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        distanceLabel.textColor = .systemBlue
        
        durationLabel.font = .systemFont(ofSize: 13)
        durationLabel.textColor = .secondaryLabel
        
        paceLabel.font = .systemFont(ofSize: 12)
        paceLabel.textColor = .tertiaryLabel
        
        chevronView.image = UIImage(systemName: "chevron.right")
        chevronView.tintColor = .tertiaryLabel
        chevronView.contentMode = .scaleAspectFit
        
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(timeLabel)
        addSubview(distanceLabel)
        addSubview(durationLabel)
        addSubview(paceLabel)
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
        
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }
        
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        distanceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(chevronView.snp.leading).offset(-8)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        paceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(durationLabel)
            make.trailing.equalTo(chevronView.snp.leading).offset(-8)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(70)
        }
        
        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    
    func configure(with workout: WorkoutData) {
        titleLabel.text = workout.workoutType
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: workout.startDate)
        
        distanceLabel.text = String(format: "%.2f km", workout.distance / 1000)
        
        let minutes = Int(workout.duration) / 60
        durationLabel.text = "\(minutes)분"
        
        if workout.distance > 0 {
            let pace = (workout.duration / 60) / (workout.distance / 1000)
            let paceMin = Int(pace)
            let paceSec = Int((pace - Double(paceMin)) * 60)
            paceLabel.text = String(format: "%d'%02d\"/km", paceMin, paceSec)
        } else {
            paceLabel.text = "-"
        }
    }
    
    @objc private func handleTap() {
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
