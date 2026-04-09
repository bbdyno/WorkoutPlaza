//
//  AdManager.swift
//  WorkoutPlaza
//
//  Created by Codex on 4/9/26.
//

import Foundation
import UIKit

enum AdPlacement: String, CaseIterable {
    case homeBanner = "home_banner"
    case statisticsBanner = "statistics_banner"

    var featureKey: FeaturePackManager.FeatureKey {
        switch self {
        case .homeBanner:
            return .adsHomeBanner
        case .statisticsBanner:
            return .adsStatisticsBanner
        }
    }

    var adUnitInfoPlistKey: String {
        switch self {
        case .homeBanner:
            return "WPHomeBannerAdUnitID"
        case .statisticsBanner:
            return "WPStatisticsBannerAdUnitID"
        }
    }

    var placeholderSubtitle: String {
        switch self {
        case .homeBanner:
            return NSLocalizedString("ads.slot.subtitle.home", comment: "")
        case .statisticsBanner:
            return NSLocalizedString("ads.slot.subtitle.statistics", comment: "")
        }
    }
}

enum AdPresentationState {
    case hidden
    case debugPlaceholder(String)
}

final class AdManager {
    static let shared = AdManager()

    private let appIDInfoPlistKey = "GADApplicationIdentifier"
    private var didLogStartup = false

    private init() {}

    func startIfNeeded() {
        guard didLogStartup == false else { return }
        didLogStartup = true

        let appID = configuredAppID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if appID.isEmpty {
            WPLog.warning("AdManager: GADApplicationIdentifier is empty. AdMob setup is pending.")
        } else {
            WPLog.info("AdManager: App ID configured. SDK hookup pending.")
        }
    }

    func presentationState(for placement: AdPlacement) -> AdPresentationState {
        guard PurchaseManager.shared.isEffectivelyPro == false else {
            return .hidden
        }

        guard FeaturePackManager.shared.isAdPlacementEnabled(placement) else {
            return .hidden
        }

        if hasConfiguredAdUnitID(for: placement) {
            return .debugPlaceholder(NSLocalizedString("ads.slot.debug.ready", comment: ""))
        }

        #if DEBUG
        return .debugPlaceholder(NSLocalizedString("ads.slot.debug.missingUnitID", comment: ""))
        #else
        return .hidden
        #endif
    }

    func preferredHeight(for placement: AdPlacement) -> CGFloat {
        switch presentationState(for: placement) {
        case .hidden:
            return 0
        case .debugPlaceholder:
            return 76
        }
    }

    func debugMessage(for placement: AdPlacement) -> String? {
        switch presentationState(for: placement) {
        case .hidden:
            return nil
        case .debugPlaceholder(let message):
            return message
        }
    }

    func hasConfiguredAdUnitID(for placement: AdPlacement) -> Bool {
        let value = configuredAdUnitID(for: placement)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty == false
    }

    private var configuredAppID: String? {
        Bundle.main.object(forInfoDictionaryKey: appIDInfoPlistKey) as? String
    }

    private func configuredAdUnitID(for placement: AdPlacement) -> String? {
        Bundle.main.object(forInfoDictionaryKey: placement.adUnitInfoPlistKey) as? String
    }
}
