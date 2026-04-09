//
//  ProUpgradeViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/5/26.
//

import UIKit
import SnapKit
import StoreKit

final class ProUpgradeViewController: UIViewController {

    // MARK: - Init

    /// 특정 진입 컨텍스트 (어떤 Pro 기능 때문에 열렸는지 힌트)
    var triggerFeature: String? // e.g. "premium_font", "watermark", "export"

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.alignment = .fill
        return sv
    }()

    private let headerView = UIView()

    private let crownLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "👑"
        lbl.font = AppFont.body(56)
        lbl.textAlignment = .center
        return lbl
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = NSLocalizedString("pro.upgrade.title", comment: "")
        lbl.font = AppFont.display(30)
        lbl.textAlignment = .center
        lbl.textColor = ColorSystem.mainText
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = NSLocalizedString("pro.upgrade.subtitle", comment: "")
        lbl.font = AppFont.body(15)
        lbl.textColor = ColorSystem.subText
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFont.bodySemiBold(13)
        lbl.textColor = ColorSystem.subText
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private let featuresCard: UIView = {
        let v = UIView()
        v.backgroundColor = ColorSystem.frostedFill
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = ColorSystem.divider.cgColor
        return v
    }()

    private let featuresStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 14
        sv.alignment = .fill
        return sv
    }()

    private let planStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 10
        sv.alignment = .fill
        return sv
    }()

    private var selectedProductID: String?

    private lazy var yearlyPlanButton = makePlanButton(productID: PurchaseManager.ProductID.proYearly)
    private lazy var monthlyPlanButton = makePlanButton(productID: PurchaseManager.ProductID.proMonthly)

    private let priceLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFont.stat(22)
        lbl.textAlignment = .center
        lbl.textColor = ColorSystem.mainText
        return lbl
    }()

    private let priceDescLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = NSLocalizedString("pro.upgrade.plan.featured", comment: "")
        lbl.font = AppFont.body(13)
        lbl.textColor = ColorSystem.subText
        lbl.textAlignment = .center
        return lbl
    }()

    private lazy var buyButton = WPPrimaryButton(
        title: NSLocalizedString("pro.upgrade.buy", comment: ""),
        cornerRadius: 24
    )

    private let restoreButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("pro.upgrade.restore", comment: ""), for: .normal)
        btn.titleLabel?.font = AppFont.body(14)
        btn.setTitleColor(ColorSystem.subText, for: .normal)
        return btn
    }()

    private let manageButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("pro.upgrade.manage", comment: ""), for: .normal)
        btn.titleLabel?.font = AppFont.body(14)
        btn.setTitleColor(ColorSystem.subText, for: .normal)
        btn.isHidden = true
        return btn
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.color = .white
        return ai
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        WPDesign.applyScreenBackground(to: view)
        title = "Pro"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        setupLayout()
        loadProductPrice()
        refreshPurchaseUI()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePurchaseStatusChanged),
            name: .wpPurchaseStatusDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 32, left: 20, bottom: 32, right: 20))
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }

        // Header
        [crownLabel, titleLabel, subtitleLabel, statusLabel].forEach { headerView.addSubview($0) }
        crownLabel.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(crownLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        contentStack.addArrangedSubview(headerView)
        contentStack.setCustomSpacing(28, after: headerView)

        // Features
        featuresCard.addSubview(featuresStack)
        featuresStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        let features: [(icon: String, title: String, desc: String)] = [
            ("sparkles",                 NSLocalizedString("pro.feature.vision.title", comment: ""),    NSLocalizedString("pro.feature.vision.desc", comment: "")),
            ("rectangle.on.rectangle.slash", NSLocalizedString("pro.feature.ads.title", comment: ""),   NSLocalizedString("pro.feature.ads.desc", comment: "")),
            ("doc.on.doc.fill",          NSLocalizedString("pro.feature.templates.title", comment: ""), NSLocalizedString("pro.feature.templates.desc", comment: "")),
            ("paintbrush.fill",          NSLocalizedString("pro.feature.fonts.title", comment: ""),     NSLocalizedString("pro.feature.fonts.desc", comment: "")),
            ("square.and.arrow.up.fill", NSLocalizedString("pro.feature.export.title", comment: ""),    NSLocalizedString("pro.feature.export.desc", comment: ""))
        ]

        features.forEach { f in
            featuresStack.addArrangedSubview(makeFeatureRow(icon: f.icon, title: f.title, desc: f.desc))
        }

        contentStack.addArrangedSubview(featuresCard)
        contentStack.setCustomSpacing(28, after: featuresCard)

        // Plans
        planStack.addArrangedSubview(yearlyPlanButton)
        planStack.addArrangedSubview(monthlyPlanButton)
        contentStack.addArrangedSubview(planStack)
        contentStack.setCustomSpacing(24, after: planStack)

        // Price
        let priceStack = UIStackView(arrangedSubviews: [priceLabel, priceDescLabel])
        priceStack.axis = .vertical
        priceStack.spacing = 4
        priceStack.alignment = .center
        contentStack.addArrangedSubview(priceStack)
        contentStack.setCustomSpacing(20, after: priceStack)

        // Buy button
        buyButton.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in make.center.equalToSuperview() }
        buyButton.addTarget(self, action: #selector(buyTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(buyButton)
        contentStack.setCustomSpacing(12, after: buyButton)

        // Restore button
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(restoreButton)
        contentStack.setCustomSpacing(8, after: restoreButton)

        manageButton.addTarget(self, action: #selector(manageTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(manageButton)
    }

    private func makeFeatureRow(icon: String, title: String, desc: String) -> UIView {
        let row = UIView()
        WPSurface.apply(to: row, style: .muted, cornerRadius: WPDesign.Radius.md)

        let iconView = UIImageView(image: UIImage(named: icon) ?? UIImage(systemName: icon))
        iconView.tintColor = ColorSystem.mainText
        iconView.contentMode = .scaleAspectFit

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = AppFont.bodySemiBold(15)
        titleLbl.textColor = ColorSystem.mainText

        let descLbl = UILabel()
        descLbl.text = desc
        descLbl.font = AppFont.body(13)
        descLbl.textColor = ColorSystem.subText
        descLbl.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLbl, descLbl])
        textStack.axis = .vertical
        textStack.spacing = 2

        row.addSubview(iconView)
        row.addSubview(textStack)

        row.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(70)
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.top.bottom.equalToSuperview().inset(12)
        }

        return row
    }

    private func makePlanButton(productID: String) -> UIButton {
        let button = UIButton(type: .system)
        button.accessibilityIdentifier = productID
        button.layer.cornerRadius = 18
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(planButtonTapped(_:)), for: .touchUpInside)

        var config = UIButton.Configuration.filled()
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        config.titleAlignment = .leading
        config.imagePlacement = .trailing
        config.imagePadding = 8
        button.configuration = config

        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(78)
        }

        return button
    }

    @objc private func planButtonTapped(_ sender: UIButton) {
        selectedProductID = sender.accessibilityIdentifier
        updatePlanSelectionUI()
    }

    private func loadProductPrice() {
        Task {
            if PurchaseManager.shared.products.isEmpty {
                await PurchaseManager.shared.fetchProducts()
            }
            let defaultProduct = PurchaseManager.shared.featuredProProduct ?? PurchaseManager.shared.availableProProducts.first
            if selectedProductID == nil {
                selectedProductID = defaultProduct?.id
            }
            updatePlanSelectionUI()
        }
    }

    private func subscriptionDescription(for product: Product?) -> String {
        switch product?.id {
        case PurchaseManager.ProductID.proYearly:
            return NSLocalizedString("pro.upgrade.plan.yearly", comment: "")
        case PurchaseManager.ProductID.proMonthly:
            return NSLocalizedString("pro.upgrade.plan.monthly", comment: "")
        default:
            return NSLocalizedString("pro.upgrade.plan.featured", comment: "")
        }
    }

    private func updatePlanSelectionUI() {
        let yearlyProduct = PurchaseManager.shared.product(for: PurchaseManager.ProductID.proYearly)
        let monthlyProduct = PurchaseManager.shared.product(for: PurchaseManager.ProductID.proMonthly)

        if selectedProductID == nil {
            selectedProductID = yearlyProduct?.id ?? monthlyProduct?.id
        }

        configurePlanButton(
            yearlyPlanButton,
            title: NSLocalizedString("pro.upgrade.plan.yearly", comment: ""),
            subtitle: yearlyProduct?.displayPrice ?? "—",
            badgeTitle: NSLocalizedString("pro.upgrade.plan.recommended", comment: ""),
            isSelected: selectedProductID == PurchaseManager.ProductID.proYearly
        )

        configurePlanButton(
            monthlyPlanButton,
            title: NSLocalizedString("pro.upgrade.plan.monthly", comment: ""),
            subtitle: monthlyProduct?.displayPrice ?? "—",
            badgeTitle: nil,
            isSelected: selectedProductID == PurchaseManager.ProductID.proMonthly
        )

        let selectedProduct = selectedProduct()
        priceLabel.text = selectedProduct?.displayPrice ?? "—"
        priceDescLabel.text = subscriptionDescription(for: selectedProduct)
        refreshPurchaseUI()
    }

    private func configurePlanButton(
        _ button: UIButton,
        title: String,
        subtitle: String,
        badgeTitle: String?,
        isSelected: Bool
    ) {
        var config = button.configuration ?? UIButton.Configuration.filled()
        config.title = title
        if let badgeTitle {
            config.subtitle = "\(subtitle) · \(badgeTitle)"
        } else {
            config.subtitle = subtitle
        }
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var updated = incoming
            updated.font = AppFont.bodySemiBold(16)
            return updated
        }
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var updated = incoming
            updated.font = AppFont.body(13)
            return updated
        }
        config.image = badgeTitle == nil ? nil : UIImage(systemName: "checkmark.circle.fill")

        if isSelected {
            config.baseBackgroundColor = ColorSystem.mainText
            config.baseForegroundColor = ColorSystem.background
            button.layer.borderColor = ColorSystem.mainText.cgColor
        } else {
            config.baseBackgroundColor = ColorSystem.frostedFill
            config.baseForegroundColor = ColorSystem.mainText
            button.layer.borderColor = ColorSystem.divider.cgColor
        }

        button.configuration = config
    }

    private func selectedProduct() -> Product? {
        if let selectedProductID {
            return PurchaseManager.shared.product(for: selectedProductID)
        }
        return PurchaseManager.shared.featuredProProduct
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func handlePurchaseStatusChanged() {
        refreshPurchaseUI()
    }

    @objc private func buyTapped() {
        setLoading(true)
        Task {
            do {
                if PurchaseManager.shared.products.isEmpty {
                    await PurchaseManager.shared.fetchProducts()
                }
                guard let product = selectedProduct() ?? PurchaseManager.shared.featuredProProduct else {
                    setLoading(false)
                    showToast(NSLocalizedString("purchase.error.notFound", comment: ""))
                    return
                }

                let outcome = try await PurchaseManager.shared.purchase(product.id)
                setLoading(false)
                switch outcome {
                case .success:
                    showSuccess()
                case .cancelled:
                    break
                case .pending:
                    showToast(NSLocalizedString("pro.upgrade.pending", comment: ""))
                }
            } catch {
                setLoading(false)
                showError(error)
            }
        }
    }

    @objc private func restoreTapped() {
        setLoading(true)
        Task {
            do {
                try await PurchaseManager.shared.restorePurchases()
                setLoading(false)
                if PurchaseManager.shared.isEffectivelyPro {
                    showSuccess()
                } else {
                    showToast(NSLocalizedString("pro.upgrade.noPurchaseFound", comment: ""))
                }
            } catch {
                setLoading(false)
                showError(error)
            }
        }
    }

    @objc private func manageTapped() {
        guard let scene = view.window?.windowScene else { return }

        Task { [weak self] in
            do {
                try await PurchaseManager.shared.showManageSubscriptions(in: scene)
            } catch {
                self?.showError(error)
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        buyButton.setTitle(loading ? "" : NSLocalizedString("pro.upgrade.buy", comment: ""), for: .normal)
        loading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        buyButton.isUserInteractionEnabled = !loading
        restoreButton.isUserInteractionEnabled = !loading
        manageButton.isUserInteractionEnabled = !loading
    }

    private func refreshPurchaseUI() {
        statusLabel.text = PurchaseManager.shared.subscriptionStatusDescription
        manageButton.isHidden = PurchaseManager.shared.hasActiveSubscription == false
    }

    private func showSuccess() {
        let alert = UIAlertController(
            title: NSLocalizedString("pro.upgrade.success.title", comment: ""),
            message: NSLocalizedString("pro.upgrade.success.message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: NSLocalizedString("common.error", comment: ""),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let label = UILabel()
        label.text = message
        label.font = AppFont.bodySemiBold(13)
        label.textColor = .white
        label.backgroundColor = ColorSystem.toastBackground
        label.textAlignment = .center
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        label.alpha = 0

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }

        UIView.animate(withDuration: 0.2) {
            label.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 0.2, animations: {
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
            })
        }
    }
}
