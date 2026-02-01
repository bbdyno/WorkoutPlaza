//
//  ClimbingGymWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Gym Name Widget

class ClimbingGymWidget: BaseClimbingWidget {
    private var gymName: String = ""
    private var gym: ClimbingGym?

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 4
        iv.isHidden = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "클라이밍짐"
        unitLabel.text = ""
        itemIdentifier = "climbing_gym_\(UUID().uuidString)"
        setupLogoImageView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLogoImageView()
    }

    private func setupLogoImageView() {
        addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalTo(valueLabel)
            make.width.height.equalTo(28)
        }
    }

    func configure(gymName: String, logoImageName: String? = nil) {
        self.gymName = gymName
        self.gym = ClimbingGymManager.shared.findGym(byName: gymName)

        valueLabel.text = gymName

        // Load logo using ClimbingGymLogoManager
        if let gym = self.gym {
            ClimbingGymLogoManager.shared.loadLogo(for: gym) { [weak self] image in
                guard let self = self, let image = image else { return }
                self.logoImageView.image = image
                self.logoImageView.isHidden = false

                // valueLabel을 로고 옆으로 이동
                self.valueLabel.snp.remakeConstraints { make in
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(4)
                    make.leading.equalTo(self.logoImageView.snp.trailing).offset(8)
                }
            }
        } else {
            // Try to load by suggested name for backward compatibility
            let suggestedName = suggestLogoImageName(for: gymName)
            if let image = UIImage(named: suggestedName) {
                logoImageView.image = image
                logoImageView.isHidden = false

                valueLabel.snp.remakeConstraints { make in
                    make.top.equalTo(titleLabel.snp.bottom).offset(4)
                    make.leading.equalTo(logoImageView.snp.trailing).offset(8)
                }
            } else {
                // 로고 없음 - 기본 레이아웃
                logoImageView.isHidden = true

                valueLabel.snp.remakeConstraints { make in
                    make.top.equalTo(titleLabel.snp.bottom).offset(4)
                    make.leading.equalToSuperview().inset(12)
                }
            }
        }
    }

    private func suggestLogoImageName(for name: String) -> String {
        let normalized = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).inverted)
            .joined()
        return "gym_logo_\(normalized)"
    }

    override func updateFonts() {
        super.updateFonts()

        // 로고 크기도 스케일에 맞게 조정
        let scaleFactor = calculateScaleFactor()
        let logoSize = 28 * scaleFactor

        logoImageView.snp.updateConstraints { make in
            make.width.height.equalTo(logoSize)
        }
    }
    
    override var idealSize: CGSize {
        layoutIfNeeded()
        
        let titleSize = titleLabel.intrinsicContentSize
        let valueSize = valueLabel.intrinsicContentSize
        
        var contentWidth: CGFloat = 0
        if !logoImageView.isHidden {
            // Logo (28) + Spacing (8) + Text
            contentWidth = max(titleSize.width, 28 + 8 + valueSize.width)
        } else {
            contentWidth = max(titleSize.width, valueSize.width)
        }
        
        let width = contentWidth + 24 // Padding
        let height = 12 + titleSize.height + 4 + max(valueSize.height, 28) + 12
        
        return CGSize(width: max(width, 120), height: max(height, 60))
    }
}
