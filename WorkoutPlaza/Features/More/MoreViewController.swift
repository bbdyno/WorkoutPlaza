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
        tv.register(TipProductCell.self, forCellReuseIdentifier: TipProductCell.reuseID)
        return tv
    }()

    // MARK: - Data

    private struct MenuItem {
        let title: String
        let icon: String
        let badge: String?
        let action: () -> Void

        init(title: String, icon: String, badge: String? = nil, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.badge = badge
            self.action = action
        }
    }

    private struct Section {
        enum SectionKind { case menu, tips }
        let title: String?
        let kind: SectionKind
        let items: [MenuItem]

        init(title: String? = nil, kind: SectionKind = .menu, items: [MenuItem]) {
            self.title = title
            self.kind = kind
            self.items = items
        }
    }

    private var sections: [Section] = []
    private var activeToastLabel: UILabel?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        rebuildData()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(purchaseStatusChanged),
            name: .wpPurchaseStatusDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func rebuildData() {
        let isPro = PurchaseManager.shared.isPro

        var configuredSections: [Section] = []

        // ── Pro 배너 (비구매자만 표시) ─────────────────────────────
        if !isPro {
            configuredSections.append(Section(title: nil, items: [
                MenuItem(title: NSLocalizedString("more.pro.upgrade.cell", comment: ""),
                         icon: "crown.fill",
                         action: { [weak self] in self?.showProUpgrade(trigger: nil) })
            ]))
        }

        // ── 카드 ──────────────────────────────────────────────────
        configuredSections.append(Section(title: WorkoutPlazaStrings.More.Section.card, items: [
            MenuItem(title: WorkoutPlazaStrings.More.Saved.cards, icon: "square.stack.3d.forward.dottedline", action: { [weak self] in
                self?.showSavedCards()
            })
        ]))

        // ── 데이터 ────────────────────────────────────────────────
        configuredSections.append(Section(title: WorkoutPlazaStrings.More.Section.data, items: [
            MenuItem(title: WorkoutPlazaStrings.More.Export.data,
                     icon: "square.and.arrow.up",
                     badge: isPro ? nil : "PRO",
                     action: { [weak self] in self?.exportData() }),
            MenuItem(title: WorkoutPlazaStrings.More.Reset.data, icon: "trash", action: { [weak self] in
                self?.resetData()
            })
        ]))

        // ── HealthKit ─────────────────────────────────────────────
        configuredSections.append(Section(title: WorkoutPlazaStrings.More.Section.healthkit, items: [
            MenuItem(title: WorkoutPlazaStrings.More.Healthkit.permissions, icon: "heart.text.square", action: { [weak self] in
                self?.showHealthKitPermissionManager()
            }),
            MenuItem(title: WorkoutPlazaStrings.More.Healthkit.sync, icon: "arrow.triangle.2.circlepath", action: { [weak self] in
                self?.syncHealthKitData()
            })
        ]))

        // ── 앱 정보 ───────────────────────────────────────────────
        configuredSections.append(Section(title: WorkoutPlazaStrings.More.Section.App.info, items: [
            MenuItem(title: WorkoutPlazaStrings.More.Version.info, icon: "info.circle", action: { [weak self] in
                self?.showVersionInfo()
            }),
            MenuItem(title: NSLocalizedString("more.view.walkthrough", comment: ""), icon: "book.pages", action: { [weak self] in
                self?.showWalkthrough()
            }),
            MenuItem(title: WorkoutPlazaStrings.More.Contact.developer, icon: "envelope", action: { [weak self] in
                self?.contactDeveloper()
            }),
            MenuItem(title: WorkoutPlazaStrings.More.Rate.app, icon: "star", action: { [weak self] in
                self?.rateApp()
            })
        ]))

        // ── 라이센스 ──────────────────────────────────────────────
        configuredSections.append(Section(title: nil, items: [
            MenuItem(title: WorkoutPlazaStrings.More.Open.Source.licenses, icon: "doc.text", action: { [weak self] in
                self?.showLicenses()
            })
        ]))

        // ── 개발자 후원 ───────────────────────────────────────────
        let tipTitle = PurchaseManager.shared.isSupporter
            ? NSLocalizedString("more.tip.section.supporter", comment: "")
            : NSLocalizedString("more.tip.section", comment: "")
        configuredSections.append(Section(title: tipTitle, kind: .tips, items: [
            MenuItem(title: NSLocalizedString("tip.product.small", comment: ""),  icon: "cup.and.saucer",     action: { [weak self] in self?.purchaseTip(PurchaseManager.ProductID.tipSmall) }),
            MenuItem(title: NSLocalizedString("tip.product.medium", comment: ""), icon: "drop.fill",           action: { [weak self] in self?.purchaseTip(PurchaseManager.ProductID.tipMedium) }),
            MenuItem(title: NSLocalizedString("tip.product.large", comment: ""),  icon: "shoeprints.fill",     action: { [weak self] in self?.purchaseTip(PurchaseManager.ProductID.tipLarge) })
        ]))

        // ── DEBUG ─────────────────────────────────────────────────
        #if DEBUG
        configuredSections.insert(
            Section(title: WorkoutPlazaStrings.More.Section.Developer.info, items: [
                MenuItem(title: WorkoutPlazaStrings.More.Github.developer, icon: "link", action: { [weak self] in
                    self?.openDeveloperGitHubProfile()
                })
            ]),
            at: 0
        )
        configuredSections.append(Section(title: WorkoutPlazaStrings.More.Section.developer, items: [
            MenuItem(title: WorkoutPlazaStrings.More.Developer.settings, icon: "wrench.and.screwdriver", action: { [weak self] in
                self?.showDeveloperSettings()
            })
        ]))
        #endif

        sections = configuredSections
        tableView.reloadData()
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

    // MARK: - Purchase Status

    @objc private func purchaseStatusChanged() {
        rebuildData()
    }

    // MARK: - Pro Upgrade

    private func showProUpgrade(trigger: String?) {
        let vc = ProUpgradeViewController()
        vc.triggerFeature = trigger
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    // MARK: - Tips

    private func purchaseTip(_ productID: String) {
        Task {
            do {
                let outcome = try await PurchaseManager.shared.purchase(productID)
                guard case .success(let product) = outcome else { return }

                PurchaseManager.shared.recordTip(product: product)

                let tier: TipThankYouViewController.Tier
                switch productID {
                case PurchaseManager.ProductID.tipSmall:  tier = .small
                case PurchaseManager.ProductID.tipMedium: tier = .medium
                default:                                   tier = .large
                }

                let thanksVC = TipThankYouViewController(tier: tier)
                thanksVC.onDismiss = { [weak self] in self?.rebuildData() }
                present(thanksVC, animated: true)

            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    // MARK: - Actions

    private func showSavedCards() {
        let savedCardsVC = SavedCardsViewController()
        navigationController?.pushViewController(savedCardsVC, animated: true)
    }

    private func exportData() {
        guard PurchaseManager.shared.isPro else {
            showProUpgrade(trigger: "export")
            return
        }

        let alert = UIAlertController(
            title: WorkoutPlazaStrings.More.Export.data,
            message: WorkoutPlazaStrings.More.Export.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Button.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.More.Export.action, style: .default) { _ in
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

    private func showWalkthrough() {
        if let mainTabBarController = tabBarController as? MainTabBarController {
            mainTabBarController.presentWalkthrough(force: true)
            return
        }

        let walkthroughVC = WalkthroughViewController()
        walkthroughVC.modalPresentationStyle = .fullScreen
        walkthroughVC.onFinish = { [weak walkthroughVC] in
            WalkthroughManager.markCompleted()
            walkthroughVC?.dismiss(animated: true)
        }
        present(walkthroughVC, animated: true)
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
        case .notAvailable:  return WorkoutPlazaStrings.More.Healthkit.Status.Not.available
        case .requestNeeded: return WorkoutPlazaStrings.More.Healthkit.Status.Request.needed
        case .authorized:    return WorkoutPlazaStrings.More.Healthkit.Status.authorized
        case .unknown:       return WorkoutPlazaStrings.More.Healthkit.Status.unknown
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
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let item = section.items[indexPath.row]

        if section.kind == .tips {
            let cell = tableView.dequeueReusableCell(withIdentifier: TipProductCell.reuseID, for: indexPath) as! TipProductCell
            let productID = [PurchaseManager.ProductID.tipSmall, PurchaseManager.ProductID.tipMedium, PurchaseManager.ProductID.tipLarge][indexPath.row]
            let product = PurchaseManager.shared.product(for: productID)
            cell.configure(title: item.title, icon: item.icon, price: product?.displayPrice)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
        config.image = UIImage(systemName: item.icon)

        // Pro 업그레이드 셀 강조
        if item.icon == "crown.fill" {
            config.textProperties.color = ColorSystem.mainText
            config.imageProperties.tintColor = ColorSystem.mainText
            cell.accessoryType = .disclosureIndicator
        } else if item.icon == "trash" {
            config.textProperties.color = .systemRed
            config.imageProperties.tintColor = .systemRed
            cell.accessoryType = .none
        } else {
            config.textProperties.color = ColorSystem.mainText
            config.imageProperties.tintColor = ColorSystem.mainText
            cell.accessoryType = .disclosureIndicator
        }

        // PRO 배지
        if let badge = item.badge {
            let badgeLabel = UILabel()
            badgeLabel.text = badge
            badgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
            badgeLabel.textColor = .white
            badgeLabel.backgroundColor = ColorSystem.mainText
            badgeLabel.layer.cornerRadius = 5
            badgeLabel.clipsToBounds = true
            badgeLabel.textAlignment = .center
            badgeLabel.frame = CGRect(x: 0, y: 0, width: 36, height: 20)
            cell.accessoryView = badgeLabel
        } else {
            cell.accessoryView = nil
        }

        cell.contentConfiguration = config
        cell.backgroundColor = .secondarySystemGroupedBackground
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].items[indexPath.row].action()
    }
}

// MARK: - TipProductCell

private final class TipProductCell: UITableViewCell {
    static let reuseID = "TipProductCell"

    private let iconLabel  = UILabel()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .secondarySystemGroupedBackground

        iconLabel.font  = .systemFont(ofSize: 22)
        iconLabel.textAlignment = .center

        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = ColorSystem.mainText

        priceLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        priceLabel.textColor = ColorSystem.mainText
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [iconLabel, titleLabel, priceLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center

        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(12)
        }

        iconLabel.snp.makeConstraints { make in make.width.equalTo(28) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, icon: String, price: String?) {
        // SF Symbol → emoji fallback
        if let img = UIImage(systemName: icon) {
            let attachment = NSTextAttachment(image: img)
            let imgString = NSAttributedString(attachment: attachment)
            let attrString = NSMutableAttributedString()
            attrString.append(imgString)
            iconLabel.attributedText = attrString
        } else {
            iconLabel.text = icon
        }
        titleLabel.text = title
        priceLabel.text = price ?? "—"
    }
}
