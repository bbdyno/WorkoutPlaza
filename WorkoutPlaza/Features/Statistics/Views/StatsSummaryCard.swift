//
//  StatsSummaryCard.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

class StatsSummaryCard: UIView {
    
    // MARK: - UI Components
    
    private let iconView: UIImageView = {
        let view = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = ColorSystem.subText
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.text = WorkoutPlazaStrings.Statistics.Summary.count(0)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = ColorSystem.subText
        return label
    }()
    
    // MARK: - Init
    
    init(title: String, icon: String, color: UIColor) {
        super.init(frame: .zero)
        setupUI(title: title, icon: icon, color: color)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI(title: String, icon: String, color: UIColor) {
        backgroundColor = color.withAlphaComponent(0.1)
        layer.cornerRadius = 16
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        iconView.image = UIImage(systemName: icon, withConfiguration: config)
        iconView.tintColor = color
        
        titleLabel.text = title
        countLabel.textColor = color
        
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(countLabel)
        addSubview(subtitleLabel)
        
        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(28)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(8)
        }
        
        countLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(countLabel.snp.trailing).offset(6)
            make.bottom.equalTo(countLabel).offset(-2)
        }
    }
    
    // MARK: - Public Methods
    
    func update(count: String, subtitle: String) {
        countLabel.text = count
        subtitleLabel.text = subtitle
    }
}
