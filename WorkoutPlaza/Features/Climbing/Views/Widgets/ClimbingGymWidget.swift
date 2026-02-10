//
//  ClimbingGymWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Gym Name Widget

class ClimbingGymWidget: BaseStatWidget {
    private var gymName: String = ""
    private var gym: ClimbingGym?

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = WorkoutPlazaStrings.Widget.Climbing.gym
        unitLabel.text = ""
        itemIdentifier = "climbing_gym_\(UUID().uuidString)"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(
        gymName: String,
        gymId: String? = nil,
        gymBranch: String? = nil,
        gymRegion: String? = nil,
        displayName: String? = nil,
        logoImageName: String? = nil
    ) {
        self.gymName = gymName
        let resolvedGym = ClimbingGymManager.shared.resolveGym(
            gymId: gymId,
            gymName: gymName,
            gymBranch: gymBranch,
            gymRegion: gymRegion
        )
        applyResolvedGym(resolvedGym, fallbackName: gymName, displayName: displayName)
    }

    func configure(with gym: ClimbingGym, displayName: String? = nil) {
        self.gymName = gym.name
        applyResolvedGym(gym, fallbackName: gym.name, displayName: displayName)
    }

    private func applyResolvedGym(_ gym: ClimbingGym?, fallbackName: String, displayName: String?) {
        self.gym = gym

        // ClimbingGymWidget is text-only. Logo is handled by GymLogoWidget.
        valueLabel.text = displayName ?? gym?.displayName ?? fallbackName
        valueLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }
    }
    
    var idealSize: CGSize {
        layoutIfNeeded()
        
        let titleSize = titleLabel.intrinsicContentSize
        let valueSize = valueLabel.intrinsicContentSize

        let contentWidth = max(titleSize.width, valueSize.width)
        let width = contentWidth + 24 // Padding
        let height = 12 + titleSize.height + 4 + valueSize.height + 12
        
        return CGSize(width: max(width, 120), height: max(height, 60))
    }
}
