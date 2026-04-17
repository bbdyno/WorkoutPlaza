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

    enum SupportTier: CaseIterable {
        case small
        case medium
        case large

        var productID: String {
            switch self {
            case .small: return ProductID.tipSmall
            case .medium: return ProductID.tipMedium
            case .large: return ProductID.tipLarge
            }
        }

        var fallbackDisplayName: String {
            switch self {
            case .small: return NSLocalizedString("tip.product.small", comment: "")
            case .medium: return NSLocalizedString("tip.product.medium", comment: "")
            case .large: return NSLocalizedString("tip.product.large", comment: "")
            }
        }

        var fallbackDescription: String {
            switch self {
            case .small: return NSLocalizedString("tip.product.small.desc", comment: "")
            case .medium: return NSLocalizedString("tip.product.medium.desc", comment: "")
            case .large: return NSLocalizedString("tip.product.large.desc", comment: "")
            }
        }

        var showcaseDisplayPrice: String {
            let prefersKorean = Locale.preferredLanguages.first?.hasPrefix("ko") == true

            switch self {
            case .small:
                return prefersKorean ? "￦2,900" : "$1.99"
            case .medium:
                return prefersKorean ? "￦6,600" : "$4.99"
            case .large:
                return prefersKorean ? "￦14,000" : "$9.99"
            }
        }
    }

    struct SupportProductOption {
        let tier: SupportTier
        let storeProduct: Product?

        var id: String { tier.productID }
        var displayName: String {
            if AppShowcaseManager.isEnabled {
                return tier.fallbackDisplayName
            }
            return storeProduct?.displayName ?? tier.fallbackDisplayName
        }
        var descriptionText: String {
            if AppShowcaseManager.isEnabled {
                return tier.fallbackDescription
            }
            return storeProduct?.description ?? tier.fallbackDescription
        }
        var displayPrice: String {
            if AppShowcaseManager.isEnabled {
                return tier.showcaseDisplayPrice
            }

            if let displayPrice = storeProduct?.displayPrice {
                return displayPrice
            }

            return NSLocalizedString("support.product.unavailable", comment: "")
        }
        var isAvailable: Bool { storeProduct != nil || AppShowcaseManager.isEnabled }
    }

    enum ProductID {
        static let proMonthly  = "com.workoutplaza.pro.monthly"
        static let proYearly   = "com.workoutplaza.pro.yearly"
        static let tipSmall    = "com.workoutplaza.tip.item.small"
        static let tipMedium   = "com.workoutplaza.tip.item.medium"
        static let tipLarge    = "com.workoutplaza.tip.item.large"

        static let proSubscriptions: [String] = [proYearly, proMonthly]
        static let tips: [String] = SupportTier.allCases.map(\.productID)
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
    private(set) var isFetchingProducts = false
    private(set) var hasAttemptedProductFetch = false
    private(set) var lastProductFetchError: String?

    var isSupporter: Bool { supportPurchaseCount > 0 || totalTipAmount > 0 }

    var hasActiveSubscription: Bool { isPro }
    var hasLoadedProductCatalog: Bool { hasAttemptedProductFetch }

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

    var supportPurchaseCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.supportPurchaseCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.supportPurchaseCount) }
    }

    var availableSupportProducts: [SupportProductOption] {
        SupportTier.allCases.map { SupportProductOption(tier: $0, storeProduct: product(for: $0.productID)) }
    }

    // MARK: - Private

    private enum Keys {
        static let isPro = "purchase.isProActive"
        static let totalTip = "purchase.totalTipAmount"
        static let supportPurchaseCount = "purchase.supportPurchaseCount"
        static let activeSubscriptionProductID = "purchase.activeSubscriptionProductID"
        static let processedTipTransactionIDs = "purchase.processedTipTransactionIDs"
    }

    private var transactionListener: Task<Void, Never>?
    private var lastProductsFetchDate: Date?
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
        await processUnfinishedTransactions()
    }

    // MARK: - Products

    func fetchProducts(force: Bool = false) async {
        if isFetchingProducts {
            return
        }

        if force == false,
           let lastProductsFetchDate,
           hasAttemptedProductFetch,
           Date().timeIntervalSince(lastProductsFetchDate) < 30 {
            return
        }

        hasAttemptedProductFetch = true
        isFetchingProducts = true
        lastProductFetchError = nil
        NotificationCenter.default.post(name: .wpPurchaseCatalogDidChange, object: nil)

        defer {
            isFetchingProducts = false
            NotificationCenter.default.post(name: .wpPurchaseCatalogDidChange, object: nil)
        }

        do {
            products = try await Product.products(for: ProductID.all)
            lastProductsFetchDate = Date()
            lastProductFetchError = nil
            WPLog.info("PurchaseManager: fetched \(products.count) products")
        } catch {
            lastProductFetchError = error.localizedDescription
            WPLog.warning("PurchaseManager: fetchProducts failed —", error.localizedDescription)
        }

        NotificationCenter.default.post(name: .wpPurchaseCatalogDidChange, object: nil)
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

    func supportTier(for productID: String) -> SupportTier? {
        SupportTier.allCases.first { $0.productID == productID }
    }

    func refreshStoreState(forceProductFetch: Bool = false) async {
        await fetchProducts(force: forceProductFetch)
        await refreshProStatus()
        await processUnfinishedTransactions()
    }

    func refreshStoreStateIfNeeded() async {
        let shouldRefreshCatalog: Bool
        if let lastProductsFetchDate {
            shouldRefreshCatalog = Date().timeIntervalSince(lastProductsFetchDate) >= 300
        } else {
            shouldRefreshCatalog = true
        }

        await refreshStoreState(forceProductFetch: shouldRefreshCatalog)
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

    private func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            do {
                let transaction = try verified(result)
                await process(transaction)
                await transaction.finish()
            } catch {
                WPLog.warning("PurchaseManager: unfinished transaction verification failed —", error.localizedDescription)
            }
        }
    }

    private func process(_ transaction: Transaction) async {
        if ProductID.proSubscriptions.contains(transaction.productID) {
            await refreshProStatus()
        }

        if ProductID.tips.contains(transaction.productID), transaction.revocationDate == nil {
            recordSupportPurchaseIfNeeded(for: transaction)
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw PurchaseError.verificationFailed
        case .verified(let v): return v
        }
    }

    private var processedTipTransactionIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: Keys.processedTipTransactionIDs) ?? []) }
        set { UserDefaults.standard.set(Array(newValue).sorted(), forKey: Keys.processedTipTransactionIDs) }
    }

    private func recordSupportPurchaseIfNeeded(for transaction: Transaction) {
        let transactionKey = String(transaction.id)
        var processedIDs = processedTipTransactionIDs
        guard processedIDs.contains(transactionKey) == false else { return }

        processedIDs.insert(transactionKey)
        processedTipTransactionIDs = processedIDs
        supportPurchaseCount += 1

        if let product = product(for: transaction.productID) {
            let value = NSDecimalNumber(decimal: product.price).doubleValue
            if value > 0 {
                totalTipAmount += value
            }
        }

        NotificationCenter.default.post(name: .wpPurchaseStatusDidChange, object: nil)
        WPLog.info(
            "PurchaseManager: support purchase recorded →",
            transaction.productID,
            "count:",
            supportPurchaseCount
        )
    }

    func resetSupportStateForDebug() {
        totalTipAmount = 0
        supportPurchaseCount = 0
        processedTipTransactionIDs = []
        NotificationCenter.default.post(name: .wpPurchaseStatusDidChange, object: nil)
        WPLog.info("PurchaseManager: support debug state reset")
    }
}

// MARK: - Notification

extension Notification.Name {
    static let wpPurchaseStatusDidChange = Notification.Name("wpPurchaseStatusDidChange")
    static let wpPurchaseCatalogDidChange = Notification.Name("wpPurchaseCatalogDidChange")
}
