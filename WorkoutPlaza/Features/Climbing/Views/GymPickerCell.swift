//
//  GymPickerCell.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/29/26.
//

import UIKit

class GymPickerCell: UITableViewCell {
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

        // Logo Image
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.layer.cornerRadius = 8
        logoImageView.clipsToBounds = true
        logoImageView.backgroundColor = .tertiarySystemGroupedBackground
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
        labelStack.spacing = 2

        // Add subviews
        contentView.addSubview(logoImageView)
        contentView.addSubview(labelStack)
        contentView.addSubview(checkmarkImageView)

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            logoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            logoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 40),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),

            labelStack.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 12),
            labelStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labelStack.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -12),

            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }

    func configure(with gym: ClimbingGym, isSelected: Bool) {
        // Reset state
        logoImageView.image = UIImage(systemName: "building.2.fill")
        logoImageView.tintColor = .secondaryLabel
        
        nameLabel.text = gym.name
        infoLabel.text = "\(gym.gradeColors.count)개 난이도 색상"
        checkmarkImageView.isHidden = !isSelected

        // Load logo asynchronously as template (white)
        ClimbingGymLogoManager.shared.loadLogo(for: gym, asTemplate: true) { [weak self] image in
            self?.logoImageView.image = image
            self?.logoImageView.tintColor = .white // User requested white
        }
    }
}
