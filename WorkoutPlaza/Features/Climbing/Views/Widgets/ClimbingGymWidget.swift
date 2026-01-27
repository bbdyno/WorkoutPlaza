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
    private var logoImageName: String?

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
        self.logoImageName = logoImageName

        // 로고 이미지 이름 결정 순서:
        // 1. 직접 전달된 logoImageName
        // 2. ClimbingGymManager에서 저장된 암장 정보의 로고
        // 3. 암장 이름으로 추론한 로고 이름
        var effectiveLogoName: String? = logoImageName

        if effectiveLogoName == nil {
            // ClimbingGymManager에서 암장 정보 조회
            if let savedGym = ClimbingGymManager.shared.findGym(byName: gymName) {
                effectiveLogoName = savedGym.logoImageName
            }
        }

        if effectiveLogoName == nil {
            // 암장 이름으로 로고 추론
            effectiveLogoName = suggestLogoImageName(for: gymName)
        }

        // 로고 이미지 표시 시도
        if let imageName = effectiveLogoName, let image = UIImage(named: imageName) {
            logoImageView.image = image
            logoImageView.isHidden = false

            // valueLabel을 로고 옆으로 이동
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

        valueLabel.text = gymName
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
}
