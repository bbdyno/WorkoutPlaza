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

    private enum Row {
        case toggle(title: String, isOn: () -> Bool, onToggle: (Bool) -> Void)
        case action(title: String, isDestructive: Bool, action: () -> Void)
    }

    private struct Section {
        let title: String?
        let rows: [Row]
    }

    private var sections: [Section] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupUI()
    }

    // MARK: - Setup

    private func setupData() {
        sections = [
            Section(title: WorkoutPlazaStrings.Dev.Widget.edit, rows: [
                .toggle(
                    title: WorkoutPlazaStrings.Dev.Pinch.resize,
                    isOn: { DevSettings.shared.isPinchToResizeEnabled },
                    onToggle: { DevSettings.shared.isPinchToResizeEnabled = $0 }
                )
            ]),
            Section(title: WorkoutPlazaStrings.Dev.Browser.section, rows: [
                .toggle(
                    title: WorkoutPlazaStrings.Dev.Browser.addressbar,
                    isOn: { DevSettings.shared.isInAppBrowserAddressBarVisible },
                    onToggle: { DevSettings.shared.isInAppBrowserAddressBarVisible = $0 }
                ),
                .toggle(
                    title: WorkoutPlazaStrings.Dev.Browser.toolbar,
                    isOn: { DevSettings.shared.isInAppBrowserToolbarVisible },
                    onToggle: { DevSettings.shared.isInAppBrowserToolbarVisible = $0 }
                ),
                .toggle(
                    title: WorkoutPlazaStrings.Dev.Browser.Presentation.sheet,
                    isOn: { DevSettings.shared.isInAppBrowserPresentedAsSheet },
                    onToggle: { DevSettings.shared.isInAppBrowserPresentedAsSheet = $0 }
                ),
                .action(title: WorkoutPlazaStrings.Dev.Browser.test, isDestructive: false, action: { [weak self] in
                    self?.showInAppBrowserTestPrompt()
                })
            ]),
            Section(title: WorkoutPlazaStrings.Dev.Section.data, rows: [
                .action(title: WorkoutPlazaStrings.Dev.Reset.userdefaults, isDestructive: true, action: { [weak self] in
                    self?.confirmAndRun(
                        title: WorkoutPlazaStrings.Dev.Reset.userdefaults,
                        message: WorkoutPlazaStrings.Dev.Reset.Userdefaults.confirm,
                        completionMessage: WorkoutPlazaStrings.Dev.Reset.Userdefaults.completed
                    ) {
                        AppDataManager.shared.resetUserDefaultsData()
                    }
                }),
                .action(title: WorkoutPlazaStrings.Dev.Reset.localdb, isDestructive: true, action: { [weak self] in
                    self?.confirmAndRun(
                        title: WorkoutPlazaStrings.Dev.Reset.localdb,
                        message: WorkoutPlazaStrings.Dev.Reset.Localdb.confirm,
                        completionMessage: WorkoutPlazaStrings.Dev.Reset.Localdb.completed
                    ) {
                        AppDataManager.shared.resetLocalDBData()
                    }
                }),
                .action(title: WorkoutPlazaStrings.Dev.Reset.appdata, isDestructive: true, action: { [weak self] in
                    self?.confirmAndRun(
                        title: WorkoutPlazaStrings.Dev.Reset.appdata,
                        message: WorkoutPlazaStrings.Dev.Reset.Appdata.confirm,
                        completionMessage: WorkoutPlazaStrings.Dev.Reset.Appdata.completed
                    ) {
                        AppDataManager.shared.resetAllInAppData()
                    }
                }),
                .action(title: WorkoutPlazaStrings.Dev.Migration.rerun, isDestructive: false, action: { [weak self] in
                    self?.runMigration()
                })
            ]),
            Section(title: WorkoutPlazaStrings.Dev.Section.appscheme, rows: [
                .action(title: WorkoutPlazaStrings.Dev.Appscheme.test, isDestructive: false, action: { [weak self] in
                    self?.showAppSchemeTestPrompt()
                })
            ])
        ]
    }

    private func confirmAndRun(
        title: String,
        message: String,
        completionMessage: String,
        action: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.no, style: .cancel))
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.yes, style: .destructive) { [weak self] _ in
            action()
            self?.showActionResultAlert(message: completionMessage)
        })
        present(alert, animated: true)
    }

    private func showActionResultAlert(message: String) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Reset.Result.title,
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

    private func showInAppBrowserTestPrompt() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Dev.Browser.test,
            message: WorkoutPlazaStrings.Dev.Browser.Prompt.message,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            let exampleURL = WorkoutPlazaStrings.Dev.Browser.Prompt.placeholder
            textField.placeholder = exampleURL
            textField.text = exampleURL
            textField.keyboardType = .URL
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default) { [weak self] _ in
            guard let self else { return }
            guard let rawValue = alert.textFields?.first?.text,
                  let url = normalizedWebURL(from: rawValue) else {
                self.showSimpleAlert(
                    title: WorkoutPlazaStrings.Dev.Browser.Invalid.title,
                    message: WorkoutPlazaStrings.Dev.Browser.Invalid.message
                )
                return
            }
            presentInAppBrowser(with: url)
        })
        present(alert, animated: true)
    }

    private func showAppSchemeTestPrompt() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Dev.Appscheme.test,
            message: WorkoutPlazaStrings.Dev.Appscheme.Prompt.message,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = WorkoutPlazaStrings.Dev.Appscheme.Prompt.placeholder
            textField.text = WorkoutPlazaStrings.Dev.Appscheme.Prompt.default
            textField.keyboardType = .URL
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default) { [weak self] _ in
            guard let self else { return }
            guard let rawValue = alert.textFields?.first?.text,
                  let url = normalizedAnyURL(from: rawValue) else {
                self.showSimpleAlert(
                    title: WorkoutPlazaStrings.Dev.Appscheme.Invalid.title,
                    message: WorkoutPlazaStrings.Dev.Appscheme.Invalid.message
                )
                return
            }

            let rootViewController = self.tabBarController ?? self.view.window?.rootViewController ?? self
            let handled = AppSchemeManager.shared.handle(url, rootViewController: rootViewController)
            if handled == false {
                self.showSimpleAlert(
                    title: WorkoutPlazaStrings.Dev.Appscheme.Unhandled.title,
                    message: WorkoutPlazaStrings.Dev.Appscheme.Unhandled.message
                )
            }
        })
        present(alert, animated: true)
    }

    private func presentInAppBrowser(with url: URL) {
        let configuration = makeInAppBrowserConfigurationForTesting()
        let browser = InAppBrowserViewController(url: url, configuration: configuration)
        let navigationController = UINavigationController(rootViewController: browser)
        navigationController.modalPresentationStyle = modalPresentationStyle(for: configuration)
        present(navigationController, animated: true)
    }

    private func makeInAppBrowserConfigurationForTesting() -> InAppBrowserConfiguration {
        var configuration = InAppBrowserConfiguration.default
        configuration.showsAddressBar = DevSettings.shared.isInAppBrowserAddressBarVisible
        configuration.showsBottomToolbar = DevSettings.shared.isInAppBrowserToolbarVisible
        configuration.presentationStyle = DevSettings.shared.isInAppBrowserPresentedAsSheet ? .pageSheet : .fullScreen
        return configuration
    }

    private func modalPresentationStyle(for configuration: InAppBrowserConfiguration) -> UIModalPresentationStyle {
        switch configuration.presentationStyle {
        case .fullScreen:
            return .fullScreen
        case .pageSheet:
            return .pageSheet
        }
    }

    private func showSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func normalizedWebURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if let url = URL(string: trimmed),
           let scheme = url.scheme?.lowercased(),
           ["http", "https"].contains(scheme) {
            return url
        }

        if trimmed.contains("://") { return nil }
        return URL(string: "https://\(trimmed)")
    }

    private func normalizedAnyURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        guard let url = URL(string: trimmed), url.scheme?.isEmpty == false else { return nil }
        return url
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
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let row = sections[indexPath.section].rows[indexPath.row]

        switch row {
        case let .toggle(title, isOn, _):
            var config = cell.defaultContentConfiguration()
            config.text = title
            config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            config.textProperties.color = ColorSystem.mainText
            cell.contentConfiguration = config

            let toggle = UISwitch()
            toggle.isOn = isOn()
            toggle.tag = (indexPath.section * 1000) + indexPath.row
            toggle.onTintColor = ColorSystem.primaryGreen
            toggle.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.accessoryType = .none

            cell.selectionStyle = .none
        case let .action(title, isDestructive, _):
            var config = cell.defaultContentConfiguration()
            config.text = title
            config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            config.textProperties.color = isDestructive ? .systemRed : ColorSystem.primaryGreen
            cell.contentConfiguration = config

            cell.accessoryView = nil
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
        }

        cell.backgroundColor = .secondarySystemGroupedBackground

        return cell
    }

    @objc private func switchToggled(_ sender: UISwitch) {
        let sectionIndex = sender.tag / 1000
        let row = sender.tag % 1000
        guard sectionIndex >= 0, sectionIndex < sections.count else { return }
        guard row >= 0, row < sections[sectionIndex].rows.count else { return }

        let targetRow = sections[sectionIndex].rows[row]
        guard case let .toggle(_, _, onToggle) = targetRow else { return }
        onToggle(sender.isOn)
    }
}

// MARK: - UITableViewDelegate

extension DeveloperSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        guard case let .action(_, _, action) = row else { return }
        action()
    }
}
