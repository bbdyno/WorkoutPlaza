//
//  GymPickerCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/29/26.
//

import UIKit
import SnapKit

class GymPickerCell: UITableViewCell {
    private enum Constants {
        static let borderWidth: CGFloat = 2.0
        static let logoContainerSize: CGFloat = 40
        static let logoImageSize: CGFloat = 34
        static let logoLeadingOffset: CGFloat = 16
        static let logoCornerRadius: CGFloat = 8
        static let labelStackLeadingOffset: CGFloat = 12
        static let labelStackSpacing: CGFloat = 2
        static let checkmarkTrailingOffset: CGFloat = 16
        static let checkmarkSize: CGFloat = 20
        static let cellMinHeight: CGFloat = 60
    }

    private let logoContainer = UIView()
    private let logoImageView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()
    private let checkmarkImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .secondarySystemGroupedBackground

        // Logo Container
        logoContainer.layer.cornerRadius = Constants.logoCornerRadius
        logoContainer.clipsToBounds = true
        logoContainer.backgroundColor = .tertiarySystemGroupedBackground

        // Logo Image
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.tintColor = .secondaryLabel

        // Name Label
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .label

        // Info Label
        infoLabel.font = .systemFont(ofSize: 13, weight: .regular)
        infoLabel.textColor = .secondaryLabel

        // Checkmark
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.contentMode = .scaleAspectFit

        // Stack for labels
        let labelStack = UIStackView(arrangedSubviews: [nameLabel, infoLabel])
        labelStack.axis = .vertical
        labelStack.spacing = Constants.labelStackSpacing

        // Add subviews
        contentView.addSubview(logoContainer)
        logoContainer.addSubview(logoImageView)
        contentView.addSubview(labelStack)
        contentView.addSubview(checkmarkImageView)

        logoContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.logoLeadingOffset)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.logoContainerSize)
        }

        logoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Constants.logoImageSize)
        }

        // Checkmark first, so labelStack can reference it
        checkmarkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.checkmarkTrailingOffset)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.checkmarkSize)
        }

        labelStack.snp.makeConstraints { make in
            make.leading.equalTo(logoContainer.snp.trailing).offset(Constants.labelStackLeadingOffset)
            make.centerY.equalToSuperview()
//            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-Constants.labelStackLeadingOffset)
        }

        contentView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Constants.cellMinHeight)
        }
    }

    func configure(with gym: ClimbingGym, isSelected: Bool) {
        // Reset state
//        logoImageView.image = UIImage(systemName: "building.2.fill")
//        logoImageView.tintColor = .secondaryLabel

        nameLabel.text = gym.displayName
        infoLabel.text = "\(gym.gradeColors.count)개 난이도 색상"
        checkmarkImageView.isHidden = !isSelected

        // Apply branch color border to container
        let branchColorHex = gym.branchColor ?? "#FFFFFF"
        let branchColor = TemplateManager.color(from: branchColorHex) ?? .white
        logoContainer.layer.borderWidth = Constants.borderWidth
        logoContainer.layer.borderColor = branchColor.cgColor
        logoContainer.backgroundColor = branchColor

        // Load logo asynchronously as template (white)
        Task { [weak self] in
            let image = await ClimbingGymLogoManager.shared.loadLogo(for: gym, asTemplate: true)
            
            // UI updates must be on main thread
            await MainActor.run {
                // Verify cell is still valid for this gym if possible, or just update
                if self?.nameLabel.text == gym.name {
                    self?.logoImageView.image = image
                    self?.logoImageView.tintColor = .white // User requested white
                }
            }
        }
    }
}
