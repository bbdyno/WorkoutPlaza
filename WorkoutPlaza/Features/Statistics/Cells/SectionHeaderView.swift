//
//  SectionHeaderView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/5/26.
//

import UIKit
import SnapKit

class SectionHeaderView: UICollectionReusableView {
    static let identifier = "SectionHeaderView"
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = ColorSystem.mainText
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}
