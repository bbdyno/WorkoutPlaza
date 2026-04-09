//
//  PurchaseManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/5/26.
//

import Foundation
import StoreKit
import UIKit

@MainActor
final class PurchaseManager {
    static let shared = PurchaseManager()

    // MARK: - Product IDs

    enum ProductID {
        static let proMonthly  = "com.workoutplaza.pro.monthly"
        static let proYearly   = "com.workoutplaza.pro.yearly"
        static let tipSmall    = "com.workoutplaza.tip.small"
        static let tipMedium   = "com.workoutplaza.tip.medium"
        static let tipLarge    = "com.workoutplaza.tip.large"

        static let proSubscriptions: [String] = [proYearly, proMonthly]
        static let tips: [String]   = [tipSmall, tipMedium, tipLarge]
        static let all: Set<String> = Set(proSubscriptions + tips)
    }

    // MARK: - State

    /// 실제 결제 상태 또는 개발자 오버라이드를 반영한 Pro 여부.
    /// DEBUG 빌드에서 DevSettings.devOverridePro가 true이면 항상 true를 반환합니다.
    var isEffectivelyPro: Bool {
        #if DEBUG
        if DevSettings.shared.devOverridePro { return true }
        #endif
        return isPro
    }

    private(set) var isPro: Bool = false {
        didSet {
            guard oldValue != isPro else { return }
            UserDefaults.standard.set(isPro, forKey: Keys.isPro)
            NotificationCenter.default.post(name: .wpPurchaseStatusDidChange, object: nil)
            WPLog.info("PurchaseManager: isPro →", isPro)
        }
    }

    private(set) var products: [Product] = []

    var isSupporter: Bool { totalTipAmount > 0 }

    var hasActiveSubscription: Bool { isPro }

    var currentSubscriptionDisplayName: String {
        switch activeSubscriptionProductID {
        case ProductID.proYearly:
            return NSLocalizedString("pro.upgrade.plan.yearly", comment: "")
        case ProductID.proMonthly:
            return NSLocalizedString("pro.upgrade.plan.monthly", comment: "")
        default:
            return NSLocalizedString("purchase.subscription.plan.active", comment: "")
        }
    }

    var subscriptionStatusDescription: String {
        #if DEBUG
        if DevSettings.shared.devOverridePro && !isPro {
            return NSLocalizedString("purchase.subscription.status.debug", comment: "")
        }
        #endif

        guard hasActiveSubscription else {
            return NSLocalizedString("purchase.subscription.status.free", comment: "")
        }
        return currentSubscriptionDisplayName
    }

    var totalTipAmount: Double {
        get { UserDefaults.standard.double(forKey: Keys.totalTip) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.totalTip) }
    }

    // MARK: - Private

    private enum Keys {
        static let isPro = "purchase.isProActive"
        static let totalTip = "purchase.totalTipAmount"
        static let activeSubscriptionProductID = "purchase.activeSubscriptionProductID"
    }

    private var transactionListener: Task<Void, Never>?
    private(set) var activeSubscriptionProductID: String? {
        didSet {
            guard oldValue != activeSubscriptionProductID else { return }

            if let activeSubscriptionProductID {
                UserDefaults.standard.set(activeSubscriptionProductID, forKey: Keys.activeSubscriptionProductID)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.activeSubscriptionProductID)
            }

            NotificationCenter.default.post(name: .wpPurchaseStatusDidChange, object: nil)
            WPLog.info("PurchaseManager: activeSubscriptionProductID →", activeSubscriptionProductID ?? "nil")
        }
    }

    private init() {
        isPro = UserDefaults.standard.bool(forKey: Keys.isPro)
        activeSubscriptionProductID = UserDefaults.standard.string(forKey: Keys.activeSubscriptionProductID)
        transactionListener = startTransactionListener()
        Task { await boot() }
    }

    deinit { transactionListener?.cancel() }

    // MARK: - Boot

    private func boot() async {
        await fetchProducts()
        await refreshProStatus()
    }

    // MARK: - Products

    func fetchProducts() async {
        do {
            products = try await Product.products(for: ProductID.all)
            WPLog.info("PurchaseManager: fetched \(products.count) products")
        } catch {
            WPLog.warning("PurchaseManager: fetchProducts failed —", error.localizedDescription)
        }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    var featuredProProduct: Product? {
        product(for: ProductID.proYearly) ?? product(for: ProductID.proMonthly)
    }

    var availableProProducts: [Product] {
        ProductID.proSubscriptions.compactMap { product(for: $0) }
    }

    // MARK: - Purchase

    enum PurchaseError: LocalizedError {
        case productNotFound
        case verificationFailed
        case unknown

        var errorDescription: String? {
            switch self {
            case .productNotFound:    return NSLocalizedString("purchase.error.notFound", comment: "")
            case .verificationFailed: return NSLocalizedString("purchase.error.verification", comment: "")
            case .unknown:            return NSLocalizedString("purchase.error.unknown", comment: "")
            }
        }
    }

    enum PurchaseOutcome {
        case success(Product)
        case cancelled
        case pending
    }

    func purchase(_ productID: String) async throws -> PurchaseOutcome {
        guard let product = product(for: productID) else {
            throw PurchaseError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try verified(verification)
            await process(transaction)
            await transaction.finish()
            return .success(product)

        case .userCancelled:
            return .cancelled

        case .pending:
            return .pending

        @unknown default:
            throw PurchaseError.unknown
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshProStatus()
    }

    func showManageSubscriptions(in scene: UIWindowScene) async throws {
        try await AppStore.showManageSubscriptions(in: scene)
    }

    // MARK: - Entitlement Refresh

    func refreshProStatus() async {
        var activeProductIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               ProductID.proSubscriptions.contains(tx.productID),
               tx.revocationDate == nil {
                activeProductIDs.insert(tx.productID)
            }
        }

        let activeProductID = ProductID.proSubscriptions.first(where: activeProductIDs.contains)
        activeSubscriptionProductID = activeProductID
        isPro = activeProductID != nil
    }

    // MARK: - Tip Recording

    func recordTip(product: Product) {
        let value = NSDecimalNumber(decimal: product.price).doubleValue
        totalTipAmount += value > 0 ? value : 1.0
        NotificationCenter.default.post(name: .wpPurchaseStatusDidChange, object: nil)
        WPLog.info("PurchaseManager: tip recorded, total →", totalTipAmount)
    }

    // MARK: - Private Helpers

    private func startTransactionListener() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let tx) = result {
                    await self.process(tx)
                    await tx.finish()
                }
            }
        }
    }

    private func process(_ transaction: Transaction) async {
        if ProductID.proSubscriptions.contains(transaction.productID) {
            await refreshProStatus()
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw PurchaseError.verificationFailed
        case .verified(let v): return v
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let wpPurchaseStatusDidChange = Notification.Name("wpPurchaseStatusDidChange")
}
