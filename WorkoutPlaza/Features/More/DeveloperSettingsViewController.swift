//
//  DeveloperSettingsViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/7/26.
//

import UIKit
import SnapKit

class DeveloperSettingsViewController: UIViewController {

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    // MARK: - Data

    private struct SettingItem {
        let title: String
        let isOn: () -> Bool
        let onToggle: (Bool) -> Void
    }

    private struct Section {
        let title: String?
        let items: [SettingItem]
    }

    private var sections: [Section] = []
    private var actionSections: [(title: String, action: () -> Void)] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupUI()
    }

    // MARK: - Setup

    private func setupData() {
        sections = [
            Section(title: "위젯 편집", items: [
                SettingItem(
                    title: "핀치로 크기 조절",
                    isOn: { DevSettings.shared.isPinchToResizeEnabled },
                    onToggle: { DevSettings.shared.isPinchToResizeEnabled = $0 }
                )
            ])
        ]

        actionSections = [
            (title: "암장 구조 마이그레이션 재실행", action: { [weak self] in
                self?.runMigration()
            })
        ]
    }

    private func runMigration() {
        let alert = UIAlertController(
            title: "마이그레이션 재실행",
            message: "암장 구조를 다시 마이그레이션하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "실행", style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            WPLog.info("=== Force migrating gym structure ===")

            // Reset migration flag
            UserDefaults.standard.removeObject(forKey: "climbingGyms_structure_migrated")
            UserDefaults.standard.synchronize()
            WPLog.debug("Migration flag reset")

            // Run migration
            ClimbingGymManager.shared.migrateGymStructureIfNeeded()

            WPLog.debug("Migration completed, reloading all gyms")

            // Reload gyms to verify
            let allGyms = ClimbingGymManager.shared.getAllGyms()
            WPLog.info("Total gyms after migration: \(allGyms.count)")
            for gym in allGyms {
                WPLog.debug("  - Gym: name=\(gym.name), displayName=\(gym.displayName), branch=\(gym.metadata?.branch ?? "nil")")
            }

            // Check sessions
            let sessions = ClimbingDataManager.shared.loadSessions()
            WPLog.info("Total sessions: \(sessions.count)")
            for session in sessions.prefix(5) {
                WPLog.debug("  - Session: gymName=\(session.gymName), gymId=\(session.gymId ?? "nil"), branch=\(session.gymBranch ?? "nil"), display=\(session.gymDisplayName)")
            }

            // Refresh data to update UI
            if let tabBarController = self.tabBarController,
               let navigationController = tabBarController.selectedViewController as? UINavigationController,
               let statisticsVC = navigationController.viewControllers.first as? StatisticsViewController {
                statisticsVC.refreshData()
            }

            WPLog.info("=== Migration process completed ===")

            let successAlert = UIAlertController(
                title: "완료",
                message: "마이그레이션이 완료되었습니다. 기록을 다시 확인해주세요.",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "확인", style: .default))
            self.present(successAlert, animated: true)
        })

        present(alert, animated: true)
    }

    private func setupUI() {
        view.backgroundColor = ColorSystem.background
        title = "개발자 설정"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = ColorSystem.background
        tableView.separatorColor = ColorSystem.divider

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource

extension DeveloperSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < sections.count {
            return sections[section].items.count
        } else {
            return actionSections.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < sections.count {
            return sections[section].title
        } else {
            return "데이터"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        if indexPath.section < sections.count {
            let item = sections[indexPath.section].items[indexPath.row]

            var config = cell.defaultContentConfiguration()
            config.text = item.title
            config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            config.textProperties.color = ColorSystem.mainText
            cell.contentConfiguration = config

            let toggle = UISwitch()
            toggle.isOn = item.isOn()
            toggle.tag = indexPath.row
            toggle.onTintColor = ColorSystem.primaryGreen
            toggle.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle

            cell.selectionStyle = .none
        } else {
            let action = actionSections[indexPath.row]

            var config = cell.defaultContentConfiguration()
            config.text = action.title
            config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            config.textProperties.color = ColorSystem.primaryGreen
            cell.contentConfiguration = config

            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
        }

        cell.backgroundColor = .secondarySystemGroupedBackground

        return cell
    }

    @objc private func switchToggled(_ sender: UISwitch) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let item = sections[indexPath.section].items[indexPath.row]
        item.onToggle(sender.isOn)
    }
}

// MARK: - UITableViewDelegate

extension DeveloperSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section >= sections.count {
            let action = actionSections[indexPath.row]
            action.action()
        }
    }
}
