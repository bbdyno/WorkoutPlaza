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
        lbl.font = .systemFont(ofSize: 56)
        lbl.textAlignment = .center
        return lbl
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Lifetime Pro"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textAlignment = .center
        lbl.textColor = ColorSystem.mainText
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = NSLocalizedString("pro.upgrade.subtitle", comment: "")
        lbl.font = .systemFont(ofSize: 15)
        lbl.textColor = ColorSystem.subText
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private let featuresCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 16
        return v
    }()

    private let featuresStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 14
        sv.alignment = .fill
        return sv
    }()

    private let priceLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.textAlignment = .center
        lbl.textColor = ColorSystem.mainText
        return lbl
    }()

    private let priceDescLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = NSLocalizedString("pro.upgrade.oneTime", comment: "")
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = ColorSystem.subText
        lbl.textAlignment = .center
        return lbl
    }()

    private let buyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("pro.upgrade.buy", comment: ""), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        return btn
    }()

    private let restoreButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("pro.upgrade.restore", comment: ""), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(ColorSystem.subText, for: .normal)
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
        view.backgroundColor = ColorSystem.background
        title = "Pro"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        setupLayout()
        applyGradientToBuyButton()
        loadProductPrice()
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
        [crownLabel, titleLabel, subtitleLabel].forEach { headerView.addSubview($0) }
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
            ("paintbrush.fill",        NSLocalizedString("pro.feature.fonts.title", comment: ""),    NSLocalizedString("pro.feature.fonts.desc", comment: "")),
            ("doc.on.doc.fill",        NSLocalizedString("pro.feature.templates.title", comment: ""), NSLocalizedString("pro.feature.templates.desc", comment: "")),
            ("eye.slash.fill",         NSLocalizedString("pro.feature.watermark.title", comment: ""), NSLocalizedString("pro.feature.watermark.desc", comment: "")),
            ("square.and.arrow.up.fill", NSLocalizedString("pro.feature.export.title", comment: ""), NSLocalizedString("pro.feature.export.desc", comment: ""))
        ]

        features.forEach { f in
            featuresStack.addArrangedSubview(makeFeatureRow(icon: f.icon, title: f.title, desc: f.desc))
        }

        contentStack.addArrangedSubview(featuresCard)
        contentStack.setCustomSpacing(28, after: featuresCard)

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
        buyButton.snp.makeConstraints { make in make.height.equalTo(56) }
        buyButton.addTarget(self, action: #selector(buyTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(buyButton)
        contentStack.setCustomSpacing(12, after: buyButton)

        // Restore button
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(restoreButton)
    }

    private func makeFeatureRow(icon: String, title: String, desc: String) -> UIView {
        let row = UIView()

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = ColorSystem.primaryBlue
        iconView.contentMode = .scaleAspectFit

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLbl.textColor = ColorSystem.mainText

        let descLbl = UILabel()
        descLbl.text = desc
        descLbl.font = .systemFont(ofSize: 13)
        descLbl.textColor = ColorSystem.subText
        descLbl.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLbl, descLbl])
        textStack.axis = .vertical
        textStack.spacing = 2

        row.addSubview(iconView)
        row.addSubview(textStack)

        iconView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(14)
            make.trailing.top.bottom.equalToSuperview()
        }

        return row
    }

    private func applyGradientToBuyButton() {
        let gradient = CAGradientLayer()
        gradient.colors = [ColorSystem.primaryBlue.cgColor, ColorSystem.primaryGreen.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = 16

        buyButton.layoutIfNeeded()
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 56)
        buyButton.layer.insertSublayer(gradient, at: 0)
    }

    private func loadProductPrice() {
        Task {
            if PurchaseManager.shared.products.isEmpty {
                await PurchaseManager.shared.fetchProducts()
            }
            let product = PurchaseManager.shared.product(for: PurchaseManager.ProductID.lifetimePro)
            priceLabel.text = product?.displayPrice ?? "—"
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func buyTapped() {
        setLoading(true)
        Task {
            do {
                let outcome = try await PurchaseManager.shared.purchase(PurchaseManager.ProductID.lifetimePro)
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
                if PurchaseManager.shared.isPro {
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

    private func setLoading(_ loading: Bool) {
        buyButton.setTitle(loading ? "" : NSLocalizedString("pro.upgrade.buy", comment: ""), for: .normal)
        loading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        buyButton.isUserInteractionEnabled = !loading
        restoreButton.isUserInteractionEnabled = !loading
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
        let toast = UILabel()
        toast.text = message
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.alpha = 0

        view.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.width.lessThanOrEqualToSuperview().offset(-40)
            make.height.equalTo(40)
        }
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.3) { toast.alpha = 1 } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0) { toast.alpha = 0 } completion: { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
