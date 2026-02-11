//
//  MoreViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/23/26.
//

import UIKit
import SnapKit
import StoreKit

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
            Section(title: WorkoutPlazaStrings.More.Section.Developer.info, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Github.developer, icon: "link", action: { [weak self] in
                    self?.openDeveloperGitHubProfile()
                })
            ]),
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
            Section(title: WorkoutPlazaStrings.More.Section.healthkit, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Healthkit.permissions, icon: "heart.text.square", action: { [weak self] in
                    self?.showHealthKitPermissionManager()
                }),
                MenuItem(title: WorkoutPlazaStrings.More.Healthkit.sync, icon: "arrow.triangle.2.circlepath", action: { [weak self] in
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
            Section(title: nil, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Open.Source.licenses, icon: "doc.text", action: { [weak self] in
                    self?.showLicenses()
                })
            ]),
            Section(title: WorkoutPlazaStrings.More.Section.developer, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Developer.settings, icon: "wrench.and.screwdriver", action: { [weak self] in
                    self?.showDeveloperSettings()
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
            title: WorkoutPlazaStrings.Reset.All.data,
            message: WorkoutPlazaStrings.Reset.All.confirm,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.no, style: .cancel))
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.yes, style: .destructive) { [weak self] _ in
            self?.performAllResetAndResync()
        })
        present(alert, animated: true)
    }

    private func performAllResetAndResync() {
        AppDataManager.shared.resetAllInAppData()
        syncHealthKitAfterReset(additionalMessage: WorkoutPlazaStrings.Reset.All.completed)
    }

    private func syncHealthKitAfterReset(additionalMessage: String? = nil) {
        WorkoutManager.shared.requestAuthorization { [weak self] success, error in
            guard success else {
                DispatchQueue.main.async {
                    let message = [additionalMessage, WorkoutPlazaStrings.Reset.Healthkit.Sync.failed].compactMap { $0 }.joined(separator: "\n")
                    self?.showResetResultAlert(message: message)
                }
                return
            }
            WorkoutManager.shared.fetchWorkouts { workouts in
                DispatchQueue.main.async {
                    let resyncText = WorkoutPlazaStrings.Reset.Running.resynced(workouts.count)
                    let message = [additionalMessage, resyncText].compactMap { $0 }.joined(separator: "\n")
                    self?.showResetResultAlert(message: message)
                }
            }
        }
    }

    private func showResetResultAlert(message: String) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Reset.Result.title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
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
        if let url = URL(string: "mailto:della.kimko@gmail.com") {
            UIApplication.shared.open(url)
        }
    }

    private func openDeveloperGitHubProfile() {
        openURLString(GitHubLinks.developerProfile)
    }

    private func openURLString(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let scene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
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

            let statusText = self.localizedHealthKitStatus(state)
            let message = WorkoutPlazaStrings.More.Healthkit.Permission.status(statusText)

            let alert = UIAlertController(
                title: WorkoutPlazaStrings.More.Healthkit.Permission.title,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: WorkoutPlazaStrings.More.Healthkit.Permission.request,
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
                    self.showToast(WorkoutPlazaStrings.More.Healthkit.Permission.updated(status))
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

            self.showToast(WorkoutPlazaStrings.More.Healthkit.Sync.In.progress)
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
                            let message = WorkoutPlazaStrings.More.Healthkit.Sync.Completed.message(workouts.count, routeCount)
                            let alert = UIAlertController(
                                title: WorkoutPlazaStrings.More.Healthkit.Sync.Completed.title,
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
            return WorkoutPlazaStrings.More.Healthkit.Status.Not.available
        case .requestNeeded:
            return WorkoutPlazaStrings.More.Healthkit.Status.Request.needed
        case .authorized:
            return WorkoutPlazaStrings.More.Healthkit.Status.authorized
        case .unknown:
            return WorkoutPlazaStrings.More.Healthkit.Status.unknown
        }
    }

    private func showHealthKitUnavailableAlert() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.More.Healthkit.Unavailable.title,
            message: WorkoutPlazaStrings.More.Healthkit.Unavailable.message,
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
