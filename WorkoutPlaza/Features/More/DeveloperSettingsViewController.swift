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
            Section(title: WorkoutPlazaStrings.Dev.Widget.edit, items: [
                SettingItem(
                    title: WorkoutPlazaStrings.Dev.Pinch.resize,
                    isOn: { DevSettings.shared.isPinchToResizeEnabled },
                    onToggle: { DevSettings.shared.isPinchToResizeEnabled = $0 }
                )
            ])
        ]

        actionSections = [
            (title: NSLocalizedString("dev.reset.userdefaults", comment: "Reset UserDefaults"), action: { [weak self] in
                self?.confirmAndRun(
                    title: NSLocalizedString("dev.reset.userdefaults", comment: "Reset UserDefaults"),
                    message: NSLocalizedString("dev.reset.userdefaults.confirm", comment: "Confirm reset UserDefaults"),
                    completionMessage: NSLocalizedString("dev.reset.userdefaults.completed", comment: "Reset UserDefaults completed")
                ) {
                    AppDataManager.shared.resetUserDefaultsData()
                }
            }),
            (title: NSLocalizedString("dev.reset.localdb", comment: "Reset Local DB"), action: { [weak self] in
                self?.confirmAndRun(
                    title: NSLocalizedString("dev.reset.localdb", comment: "Reset Local DB"),
                    message: NSLocalizedString("dev.reset.localdb.confirm", comment: "Confirm reset Local DB"),
                    completionMessage: NSLocalizedString("dev.reset.localdb.completed", comment: "Reset Local DB completed")
                ) {
                    AppDataManager.shared.resetLocalDBData()
                }
            }),
            (title: NSLocalizedString("dev.reset.appdata", comment: "Reset In-App Data"), action: { [weak self] in
                self?.confirmAndRun(
                    title: NSLocalizedString("dev.reset.appdata", comment: "Reset In-App Data"),
                    message: NSLocalizedString("dev.reset.appdata.confirm", comment: "Confirm reset In-App Data"),
                    completionMessage: NSLocalizedString("dev.reset.appdata.completed", comment: "Reset In-App Data completed")
                ) {
                    AppDataManager.shared.resetAllInAppData()
                }
            }),
            (title: WorkoutPlazaStrings.Dev.Migration.rerun, action: { [weak self] in
                self?.runMigration()
            })
        ]
    }

    private func confirmAndRun(
        title: String,
        message: String,
        completionMessage: String,
        action: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.no", comment: "No"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.yes", comment: "Yes"), style: .destructive) { [weak self] _ in
            action()
            self?.showActionResultAlert(message: completionMessage)
        })
        present(alert, animated: true)
    }

    private func showActionResultAlert(message: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("reset.result.title", comment: "Reset result alert title"),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func runMigration() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Dev.Migration.title,
            message: WorkoutPlazaStrings.Dev.Migration.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Dev.Migration.run, style: .destructive) { [weak self] _ in
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
                title: WorkoutPlazaStrings.Dev.Migration.complete,
                message: WorkoutPlazaStrings.Dev.Migration.Complete.message,
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
            self.present(successAlert, animated: true)
        })

        present(alert, animated: true)
    }

    private func setupUI() {
        view.backgroundColor = ColorSystem.background
        title = WorkoutPlazaStrings.Dev.title

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
            return WorkoutPlazaStrings.Dev.Section.data
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
            let resetActionCount = 3
            let isDestructiveReset = indexPath.row < resetActionCount

            var config = cell.defaultContentConfiguration()
            config.text = action.title
            config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            config.textProperties.color = isDestructiveReset ? .systemRed : ColorSystem.primaryGreen
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
