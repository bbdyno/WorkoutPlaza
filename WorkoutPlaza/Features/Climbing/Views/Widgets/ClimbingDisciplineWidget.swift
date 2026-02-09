//
//  ClimbingDisciplineWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Discipline Widget

class ClimbingDisciplineWidget: BaseStatWidget {
    private var discipline: ClimbingDiscipline = .bouldering

    private let disciplineIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = WorkoutPlazaStrings.Widget.Climbing.discipline
        unitLabel.text = ""
        itemIdentifier = "climbing_discipline_\(UUID().uuidString)"
        setupIcon()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupIcon()
    }

    private func setupIcon() {
        addSubview(disciplineIconImageView)
        disciplineIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalTo(valueLabel)
            make.width.height.equalTo(24)
        }

        // Move valueLabel to the right of icon
        valueLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(disciplineIconImageView.snp.trailing).offset(8)
        }
    }

    func configure(discipline: ClimbingDiscipline) {
        self.discipline = discipline
        valueLabel.text = discipline.displayName
        disciplineIconImageView.image = UIImage(systemName: discipline.iconName)
    }

    override func updateColors() {
        super.updateColors()
        disciplineIconImageView.tintColor = currentColor
    }

    override func updateFonts() {
        super.updateFonts()

        // 아이콘 크기도 스케일에 맞게 조정
        let scaleFactor = calculateScaleFactor()
        let iconSize = 24 * scaleFactor

        disciplineIconImageView.snp.updateConstraints { make in
            make.width.height.equalTo(iconSize)
        }
    }

    override var alignmentSubjectViews: [UIView] {
        var views = super.alignmentSubjectViews
        views.insert(disciplineIconImageView, at: 0)
        return views
    }
}
