//
//  DeveloperSupportViewController.swift
//  WorkoutPlaza
//
//  Created by Codex on 4/10/26.
//

import UIKit
import SnapKit

final class DeveloperSupportViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = WPDesign.Spacing.lg
        stack.alignment = .fill
        return stack
    }()

    private let heroCard = UIView()
    private let summaryCard = UIView()
    private let notesCard = UIView()
    private let optionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = WPDesign.Spacing.sm
        stack.alignment = .fill
        return stack
    }()

    private let summaryBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodyBold(12)
        label.textColor = ColorSystem.background
        label.backgroundColor = ColorSystem.mainText
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let summaryTitleLabel = WPDesign.makeLabel(style: .title, lines: 0)
    private let summaryBodyLabel = WPDesign.makeLabel(style: .body, lines: 0)

    private var optionViews: [PurchaseManager.SupportTier: SupportOptionCardView] = [:]
    private var activeToastLabel: UILabel?
    private var loadingProductID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        WPDesign.applyScreenBackground(to: view)
        title = NSLocalizedString("support.screen.nav.title", comment: "")
        navigationItem.largeTitleDisplayMode = .never

        setupLayout()
        rebuildSupportOptions()
        refreshSummary()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePurchaseStatusChanged),
            name: .wpPurchaseStatusDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePurchaseCatalogChanged),
            name: .wpPurchaseCatalogDidChange,
            object: nil
        )

        Task { [weak self] in
            await PurchaseManager.shared.fetchProducts()
            self?.rebuildSupportOptions()
            self?.refreshSummary()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 24, left: 20, bottom: 32, right: 20))
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }

        contentStack.addArrangedSubview(makeHeroCard())
        contentStack.addArrangedSubview(makeSummaryCard())

        let optionsHeader = WPSectionHeaderView(
            title: NSLocalizedString("support.screen.options.title", comment: ""),
            subtitle: NSLocalizedString("support.screen.options.subtitle", comment: "")
        )
        contentStack.addArrangedSubview(optionsHeader)
        contentStack.addArrangedSubview(optionsStack)
        contentStack.addArrangedSubview(makeNotesCard())
    }

    private func makeHeroCard() -> UIView {
        WPSurface.apply(to: heroCard, cornerRadius: WPDesign.Radius.xl)

        let eyebrowLabel = WPDesign.makeLabel(
            style: .eyebrow,
            text: NSLocalizedString("support.screen.hero.eyebrow", comment: ""),
            color: ColorSystem.primaryBlue
        )
        let titleLabel = WPDesign.makeLabel(
            style: .displayLarge,
            text: NSLocalizedString("support.screen.hero.title", comment: ""),
            lines: 0
        )
        let bodyLabel = WPDesign.makeLabel(
            style: .body,
            text: NSLocalizedString("support.screen.hero.body", comment: ""),
            lines: 0
        )

        let badge = WPBadgeView(
            icon: UIImage(named: "icon.support"),
            tintColor: .white,
            backgroundColor: ColorSystem.mainText
        )

        let textStack = UIStackView(arrangedSubviews: [eyebrowLabel, titleLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = WPDesign.Spacing.xs
        textStack.alignment = .leading

        let topRow = UIStackView(arrangedSubviews: [textStack, badge])
        topRow.axis = .horizontal
        topRow.spacing = WPDesign.Spacing.md
        topRow.alignment = .top

        let footerLabel = WPDesign.makeLabel(
            style: .caption,
            text: NSLocalizedString("support.screen.hero.footer", comment: ""),
            color: ColorSystem.subText,
            lines: 0
        )

        let stack = UIStackView(arrangedSubviews: [topRow, footerLabel])
        stack.axis = .vertical
        stack.spacing = WPDesign.Spacing.md
        stack.alignment = .fill

        heroCard.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        return heroCard
    }

    private func makeSummaryCard() -> UIView {
        WPSurface.apply(to: summaryCard, style: .muted, cornerRadius: WPDesign.Radius.lg)

        let stack = UIStackView(arrangedSubviews: [summaryBadgeLabel, summaryTitleLabel, summaryBodyLabel])
        stack.axis = .vertical
        stack.spacing = WPDesign.Spacing.xs
        stack.alignment = .leading

        summaryCard.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        summaryBadgeLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(110)
        }

        return summaryCard
    }

    private func makeNotesCard() -> UIView {
        WPSurface.apply(to: notesCard, style: .muted, cornerRadius: WPDesign.Radius.lg)

        let titleLabel = WPDesign.makeLabel(
            style: .title,
            text: NSLocalizedString("support.screen.notes.title", comment: "")
        )

        let noteKeys = [
            "support.screen.notes.item.1",
            "support.screen.notes.item.2",
            "support.screen.notes.item.3"
        ]

        let noteLabels = noteKeys.map { key -> UILabel in
            let label = WPDesign.makeLabel(style: .body, lines: 0)
            label.text = "• " + NSLocalizedString(key, comment: "")
            return label
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel] + noteLabels)
        stack.axis = .vertical
        stack.spacing = WPDesign.Spacing.xs
        stack.alignment = .fill

        notesCard.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        return notesCard
    }

    private func rebuildSupportOptions() {
        optionsStack.arrangedSubviews.forEach {
            optionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        optionViews.removeAll()

        if let stateView = makeCatalogStateViewIfNeeded() {
            optionsStack.addArrangedSubview(stateView)
            return
        }

        for option in PurchaseManager.shared.availableSupportProducts {
            let card = SupportOptionCardView(tier: option.tier)
            card.configure(option: option, isLoading: loadingProductID == option.id)
            card.onTap = { [weak self] in
                self?.purchaseSupport(option.tier)
            }
            optionsStack.addArrangedSubview(card)
            optionViews[option.tier] = card
        }
    }

    private func makeCatalogStateViewIfNeeded() -> UIView? {
        if AppShowcaseManager.isEnabled {
            return nil
        }

        let purchaseManager = PurchaseManager.shared

        if purchaseManager.products.isEmpty,
           purchaseManager.hasLoadedProductCatalog == false || purchaseManager.isFetchingProducts {
            return makeCatalogStateCard(
                title: NSLocalizedString("support.screen.loading.title", comment: ""),
                body: NSLocalizedString("support.screen.loading.body", comment: ""),
                showsSpinner: true,
                actionTitle: nil,
                action: nil
            )
        }

        if purchaseManager.products.isEmpty {
            return makeCatalogStateCard(
                title: NSLocalizedString("support.screen.error.title", comment: ""),
                body: NSLocalizedString("support.screen.error.body", comment: ""),
                showsSpinner: false,
                actionTitle: NSLocalizedString("support.screen.retry", comment: ""),
                action: { [weak self] in self?.retryLoadingProducts() }
            )
        }

        return nil
    }

    private func makeCatalogStateCard(
        title: String,
        body: String,
        showsSpinner: Bool,
        actionTitle: String?,
        action: (() -> Void)?
    ) -> UIView {
        let container = UIView()
        WPSurface.apply(to: container, style: .muted, cornerRadius: WPDesign.Radius.lg)

        let titleLabel = WPDesign.makeLabel(style: .title, text: title, lines: 0)
        let bodyLabel = WPDesign.makeLabel(style: .body, text: body, lines: 0)

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = WPDesign.Spacing.xs
        stack.alignment = .leading

        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
        }

        if showsSpinner {
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.color = ColorSystem.mainText
            indicator.startAnimating()
            container.addSubview(indicator)
            indicator.snp.makeConstraints { make in
                make.top.equalTo(stack.snp.bottom).offset(16)
                make.leading.equalToSuperview().inset(20)
                make.bottom.equalToSuperview().inset(20)
            }
        } else if let actionTitle, let action {
            let button = WPPrimaryButton(title: actionTitle, cornerRadius: 20)
            button.addAction(UIAction { _ in action() }, for: .touchUpInside)
            container.addSubview(button)
            button.snp.makeConstraints { make in
                make.top.equalTo(stack.snp.bottom).offset(16)
                make.leading.trailing.bottom.equalToSuperview().inset(20)
            }
        } else {
            stack.snp.makeConstraints { make in
                make.bottom.equalToSuperview().inset(20)
            }
        }

        return container
    }

    private func refreshSummary() {
        let supportCount = max(PurchaseManager.shared.supportPurchaseCount, PurchaseManager.shared.isSupporter ? 1 : 0)

        if supportCount > 0 {
            summaryBadgeLabel.isHidden = false
            summaryBadgeLabel.text = "  " + NSLocalizedString("tip.supporter.badge", comment: "") + "  "
            summaryTitleLabel.text = NSLocalizedString("support.screen.summary.supporter.title", comment: "")
            summaryBodyLabel.text = String.localizedStringWithFormat(
                NSLocalizedString("support.screen.summary.supporter.body", comment: ""),
                supportCount
            )
        } else {
            summaryBadgeLabel.isHidden = true
            summaryTitleLabel.text = NSLocalizedString("support.screen.summary.default.title", comment: "")
            summaryBodyLabel.text = NSLocalizedString("support.screen.summary.default.body", comment: "")
        }
    }

    @objc private func handlePurchaseStatusChanged() {
        rebuildSupportOptions()
        refreshSummary()
    }

    @objc private func handlePurchaseCatalogChanged() {
        rebuildSupportOptions()
    }

    private func retryLoadingProducts() {
        Task { [weak self] in
            await PurchaseManager.shared.fetchProducts(force: true)
            self?.rebuildSupportOptions()
        }
    }

    private func purchaseSupport(_ tier: PurchaseManager.SupportTier) {
        loadingProductID = tier.productID
        rebuildSupportOptions()

        Task { [weak self] in
            guard let self else { return }

            do {
                if PurchaseManager.shared.product(for: tier.productID) == nil {
                    await PurchaseManager.shared.fetchProducts()
                    rebuildSupportOptions()
                }

                guard PurchaseManager.shared.product(for: tier.productID) != nil else {
                    loadingProductID = nil
                    rebuildSupportOptions()
                    showToast(NSLocalizedString("support.product.unavailable", comment: ""))
                    return
                }

                let outcome = try await PurchaseManager.shared.purchase(tier.productID)
                loadingProductID = nil
                rebuildSupportOptions()
                refreshSummary()

                switch outcome {
                case .success:
                    showThankYou(for: tier)
                case .cancelled:
                    break
                case .pending:
                    showToast(NSLocalizedString("support.screen.pending", comment: ""))
                }
            } catch {
                loadingProductID = nil
                rebuildSupportOptions()
                showToast(error.localizedDescription)
            }
        }
    }

    private func showThankYou(for tier: PurchaseManager.SupportTier) {
        let thanksVC = TipThankYouViewController(tier: tier.tipThankYouTier)
        thanksVC.onDismiss = { [weak self] in
            self?.refreshSummary()
        }
        present(thanksVC, animated: true)
    }

    private func showToast(_ message: String) {
        activeToastLabel?.removeFromSuperview()

        let label = UILabel()
        label.text = message
        label.font = AppFont.bodySemiBold(13)
        label.textColor = .white
        label.backgroundColor = ColorSystem.toastBackground
        label.textAlignment = .center
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        label.alpha = 0
        label.numberOfLines = 0

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }

        activeToastLabel = label
        UIView.animate(withDuration: 0.2) {
            label.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self, weak label] in
            guard let label else { return }
            UIView.animate(withDuration: 0.2, animations: {
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
                if self?.activeToastLabel === label {
                    self?.activeToastLabel = nil
                }
            })
        }
    }
}

private extension PurchaseManager.SupportTier {
    var tintColor: UIColor {
        switch self {
        case .small: return .white
        case .medium: return .white
        case .large: return .white
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .small: return ColorSystem.primaryGreen
        case .medium: return ColorSystem.primaryBlue
        case .large: return ColorSystem.mainText
        }
    }

    var tipThankYouTier: TipThankYouViewController.Tier {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
}

private final class SupportOptionCardView: UIView {
    private let tier: PurchaseManager.SupportTier
    private let titleLabel = WPDesign.makeLabel(style: .title, lines: 0)
    private let descriptionLabel = WPDesign.makeLabel(style: .body, lines: 0)
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.stat(22)
        label.textColor = ColorSystem.mainText
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    private let purchaseButton = WPPrimaryButton(title: NSLocalizedString("support.product.button", comment: ""), cornerRadius: 20)
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    var onTap: (() -> Void)?

    init(tier: PurchaseManager.SupportTier) {
        self.tier = tier
        super.init(frame: .zero)
        WPSurface.apply(to: self, cornerRadius: WPDesign.Radius.lg)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupLayout() {
        let badge = WPBadgeView(
            icon: UIImage(named: "icon.support"),
            tintColor: tier.tintColor,
            backgroundColor: tier.backgroundColor
        )

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        let topRow = UIStackView(arrangedSubviews: [badge, textStack, priceLabel])
        topRow.axis = .horizontal
        topRow.spacing = WPDesign.Spacing.sm
        topRow.alignment = .top

        addSubview(topRow)
        addSubview(purchaseButton)
        purchaseButton.addSubview(loadingIndicator)

        topRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(18)
        }

        purchaseButton.snp.makeConstraints { make in
            make.top.equalTo(topRow.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview().inset(18)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        purchaseButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    func configure(option: PurchaseManager.SupportProductOption, isLoading: Bool) {
        titleLabel.text = option.displayName
        descriptionLabel.text = option.descriptionText
        priceLabel.text = option.displayPrice

        if isLoading {
            purchaseButton.setTitle("", for: .normal)
            purchaseButton.isEnabled = false
            loadingIndicator.startAnimating()
            return
        }

        loadingIndicator.stopAnimating()
        let buttonTitle = option.isAvailable
            ? NSLocalizedString("support.product.button", comment: "")
            : NSLocalizedString("support.product.unavailable", comment: "")
        purchaseButton.setTitle(buttonTitle, for: .normal)
        purchaseButton.isEnabled = option.isAvailable
        purchaseButton.alpha = option.isAvailable ? 1 : 0.65
    }

    @objc private func buttonTapped() {
        onTap?()
    }
}
