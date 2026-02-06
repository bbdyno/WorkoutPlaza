//
//  RecentRecordsSheetViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/6/26.
//

import UIKit
import SnapKit

protocol RecentRecordsSheetDelegate: AnyObject {
    func recentRecordsSheet(_ sheet: RecentRecordsSheetViewController, didSelectWorkoutAt index: Int)
}

class RecentRecordsSheetViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: RecentRecordsSheetDelegate?
    var workouts: [(sportType: SportType, data: Any, date: Date)] = []

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "최근 기록"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = ColorSystem.mainText
        label.textAlignment = .center
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = ColorSystem.subText
        button.backgroundColor = ColorSystem.divider
        button.layer.cornerRadius = 15
        return button
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = ColorSystem.background

        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(tableView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(30)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecordCell")
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Helpers

    private func configureCell(_ cell: UITableViewCell, for workout: (sportType: SportType, data: Any, date: Date)) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        let card = UIView()
        card.backgroundColor = ColorSystem.cardBackground
        card.layer.cornerRadius = 14
        card.layer.cornerCurve = .continuous

        let iconImageView = UIImageView()
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconImageView.image = UIImage(systemName: workout.sportType.iconName, withConfiguration: iconConfig)
        iconImageView.tintColor = ColorSystem.controlTint
        iconImageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = ColorSystem.mainText

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = ColorSystem.subText

        let dateLabel = UILabel()
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = ColorSystem.subText

        switch workout.sportType {
        case .running:
            if let healthKitWorkout = workout.data as? WorkoutData {
                titleLabel.text = "러닝"
                subtitleLabel.text = String(format: "%.1f km", healthKitWorkout.distance / 1000)
            } else if let externalWorkout = workout.data as? ExternalWorkout {
                titleLabel.text = "러닝"
                subtitleLabel.text = String(format: "%.1f km", externalWorkout.workoutData.distance / 1000)
            }
        case .climbing:
            if let session = workout.data as? ClimbingData {
                titleLabel.text = session.gymName.isEmpty ? "클라이밍" : session.gymName
                subtitleLabel.text = "\(session.totalRoutes) 루트"
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        dateLabel.text = formatter.string(from: workout.date)

        cell.contentView.addSubview(card)
        card.addSubview(iconImageView)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        card.addSubview(dateLabel)

        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-4)
        }

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(14)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }

        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension RecentRecordsSheetViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath)
        configureCell(cell, for: workouts[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.recentRecordsSheet(self, didSelectWorkoutAt: indexPath.row)
        }
    }
}
