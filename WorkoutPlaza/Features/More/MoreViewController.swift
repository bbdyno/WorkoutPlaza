//
//  MoreViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/23/26.
//

import UIKit
import SnapKit

class MoreViewController: UIViewController {

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    // MARK: - Data

    private struct MenuItem {
        let title: String
        let icon: String
        let action: () -> Void
    }

    private struct Section {
        let title: String?
        let items: [MenuItem]
    }

    private var sections: [Section] = []
    private var activeToastLabel: UILabel?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupUI()
    }

    // MARK: - Setup

    private func setupData() {
        sections = [
            Section(title: WorkoutPlazaStrings.More.Section.card, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Saved.cards, icon: "square.stack.3d.forward.dottedline", action: { [weak self] in
                    self?.showSavedCards()
                })
            ]),
            Section(title: WorkoutPlazaStrings.More.Section.data, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Export.data, icon: "square.and.arrow.up", action: { [weak self] in
                    self?.exportData()
                }),
                MenuItem(title: WorkoutPlazaStrings.More.Reset.data, icon: "trash", action: { [weak self] in
                    self?.resetData()
                })
            ]),
            Section(title: NSLocalizedString("more.section.healthkit", comment: "HealthKit section title"), items: [
                MenuItem(title: NSLocalizedString("more.healthkit.permissions", comment: "HealthKit permissions menu title"), icon: "heart.text.square", action: { [weak self] in
                    self?.showHealthKitPermissionManager()
                }),
                MenuItem(title: NSLocalizedString("more.healthkit.sync", comment: "HealthKit sync menu title"), icon: "arrow.triangle.2.circlepath", action: { [weak self] in
                    self?.syncHealthKitData()
                })
            ]),
            Section(title: WorkoutPlazaStrings.More.Section.App.info, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Version.info, icon: "info.circle", action: { [weak self] in
                    self?.showVersionInfo()
                }),
                MenuItem(title: WorkoutPlazaStrings.More.Contact.developer, icon: "envelope", action: { [weak self] in
                    self?.contactDeveloper()
                }),
                MenuItem(title: WorkoutPlazaStrings.More.Rate.app, icon: "star", action: { [weak self] in
                    self?.rateApp()
                })
            ]),
            Section(title: WorkoutPlazaStrings.More.Section.developer, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Developer.settings, icon: "wrench.and.screwdriver", action: { [weak self] in
                    self?.showDeveloperSettings()
                })
            ]),
            Section(title: nil, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Open.Source.licenses, icon: "doc.text", action: { [weak self] in
                    self?.showLicenses()
                })
            ])
        ]
    }

    private func setupUI() {
        view.backgroundColor = ColorSystem.background
        navigationController?.navigationBar.prefersLargeTitles = false
        title = WorkoutPlazaStrings.Tab.more

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = ColorSystem.background
        tableView.separatorColor = ColorSystem.divider
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Actions

    private func showSavedCards() {
        let savedCardsVC = SavedCardsViewController()
        navigationController?.pushViewController(savedCardsVC, animated: true)
    }

    private func exportData() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.More.Export.data,
            message: WorkoutPlazaStrings.More.Export.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Button.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.More.Export.action, style: .default) { _ in
            // TODO: Implement export
            self.showToast(WorkoutPlazaStrings.Toast.Feature.Coming.soon)
        })
        present(alert, animated: true)
    }

    private func resetData() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.More.Reset.data,
            message: WorkoutPlazaStrings.More.Reset.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Button.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.delete, style: .destructive) { _ in
            // TODO: Implement reset
            self.showToast(WorkoutPlazaStrings.Toast.Feature.Coming.soon)
        })
        present(alert, animated: true)
    }

    private func showVersionInfo() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        let alert = UIAlertController(
            title: "Workout Plaza",
            message: WorkoutPlazaStrings.More.version(version, build),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func contactDeveloper() {
        if let url = URL(string: "mailto:support@workoutplaza.app") {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        // TODO: Add App Store URL
        showToast(WorkoutPlazaStrings.Toast.Appstore.required)
    }

    private func showDeveloperSettings() {
        let devSettingsVC = DeveloperSettingsViewController()
        navigationController?.pushViewController(devSettingsVC, animated: true)
    }

    private func showLicenses() {
        let licensesVC = LicensesViewController()
        navigationController?.pushViewController(licensesVC, animated: true)
    }

    private func showHealthKitPermissionManager() {
        WorkoutManager.shared.authorizationState { [weak self] state in
            guard let self = self else { return }
            guard state != .notAvailable else {
                self.showHealthKitUnavailableAlert()
                return
            }

            let messageFormat = NSLocalizedString("more.healthkit.permission.status", comment: "HealthKit permission status message format")
            let statusText = self.localizedHealthKitStatus(state)
            let message = String(format: messageFormat, statusText)

            let alert = UIAlertController(
                title: NSLocalizedString("more.healthkit.permission.title", comment: "HealthKit permission manager title"),
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("more.healthkit.permission.request", comment: "Request HealthKit permission action"),
                style: .default
            ) { [weak self] _ in
                self?.requestHealthKitPermission()
            })
            alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Permission.Open.settings, style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))
            self.present(alert, animated: true)
        }
    }

    private func requestHealthKitPermission() {
        WorkoutManager.shared.requestAuthorization { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error {
                    self.showHealthKitAuthorizationError(error)
                    return
                }

                WorkoutManager.shared.authorizationState { [weak self] state in
                    guard let self = self else { return }
                    let status = self.localizedHealthKitStatus(state)
                    let format = NSLocalizedString("more.healthkit.permission.updated", comment: "HealthKit permission updated message format")
                    self.showToast(String(format: format, status))
                }
            }
        }
    }

    private func syncHealthKitData() {
        WorkoutManager.shared.authorizationState { [weak self] state in
            guard let self = self else { return }
            guard state != .notAvailable else {
                self.showHealthKitUnavailableAlert()
                return
            }

            self.showToast(NSLocalizedString("more.healthkit.sync.in.progress", comment: "HealthKit sync in progress"))
            WorkoutManager.shared.requestAuthorization { [weak self] _, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let error {
                        self.showHealthKitAuthorizationError(error)
                        return
                    }

                    WorkoutManager.shared.fetchWorkouts { workouts in
                        DispatchQueue.main.async {
                            let routeCount = workouts.filter(\.hasRoute).count
                            let messageFormat = NSLocalizedString("more.healthkit.sync.completed.message", comment: "HealthKit sync completed message format")
                            let message = String(format: messageFormat, workouts.count, routeCount)
                            let alert = UIAlertController(
                                title: NSLocalizedString("more.healthkit.sync.completed.title", comment: "HealthKit sync completed title"),
                                message: message,
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
                            self.present(alert, animated: true)
                        }
                    }
                }
            }
        }
    }

    private func localizedHealthKitStatus(_ state: HealthKitAuthorizationState) -> String {
        switch state {
        case .notAvailable:
            return NSLocalizedString("more.healthkit.status.not.available", comment: "HealthKit unavailable status")
        case .requestNeeded:
            return NSLocalizedString("more.healthkit.status.request.needed", comment: "HealthKit request needed status")
        case .authorized:
            return NSLocalizedString("more.healthkit.status.authorized", comment: "HealthKit authorized status")
        case .unknown:
            return NSLocalizedString("more.healthkit.status.unknown", comment: "HealthKit unknown status")
        }
    }

    private func showHealthKitUnavailableAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("more.healthkit.unavailable.title", comment: "HealthKit unavailable title"),
            message: NSLocalizedString("more.healthkit.unavailable.message", comment: "HealthKit unavailable message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func showHealthKitAuthorizationError(_ error: Error?) {
        let message = error?.localizedDescription ?? WorkoutPlazaStrings.Permission.Healthkit.message
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Permission.Healthkit.title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Permission.Open.settings, style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        activeToastLabel?.removeFromSuperview()
        activeToastLabel = nil

        let toast = UILabel()
        toast.text = message
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.alpha = 0
        activeToastLabel = toast

        view.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.width.equalTo(200)
            make.height.equalTo(40)
        }

        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0) {
                toast.alpha = 0
            } completion: { _ in
                toast.removeFromSuperview()
                if self.activeToastLabel === toast {
                    self.activeToastLabel = nil
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension MoreViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
        config.image = UIImage(systemName: item.icon)

        if item.icon == "trash" {
            config.textProperties.color = .systemRed
            config.imageProperties.tintColor = .systemRed
        } else {
            config.textProperties.color = ColorSystem.mainText
            config.imageProperties.tintColor = ColorSystem.mainText
        }
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .secondarySystemGroupedBackground // Dark card look
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        item.action()
    }
}

// MARK: - Licenses View Controller

class LicensesViewController: UIViewController {

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.textColor = .label
        tv.backgroundColor = .systemBackground
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = WorkoutPlazaStrings.More.Open.Source.licenses
        view.backgroundColor = .systemBackground

        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        textView.text = """
        SnapKit
        --------
        MIT License
        Copyright (c) 2011-Present SnapKit Team

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        """
    }
}
