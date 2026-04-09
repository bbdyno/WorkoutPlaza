//
//  UsageLimitManager.swift
//  WorkoutPlaza
//
//  Created by Codex on 4/9/26.
//

import Foundation
import Security

enum UsageLimitedFeature: String, Codable {
    case visionCutout
    case transparentStickerExport

    var freeUseLimit: Int { 3 }

    var triggerFeature: String {
        switch self {
        case .visionCutout:
            return "vision"
        case .transparentStickerExport:
            return "transparent_export"
        }
    }

    var iconName: String {
        switch self {
        case .visionCutout:
            return "sparkles"
        case .transparentStickerExport:
            return "icon.download"
        }
    }

    var trialTitle: String {
        switch self {
        case .visionCutout:
            return NSLocalizedString("usage.limit.vision.title", comment: "")
        case .transparentStickerExport:
            return NSLocalizedString("usage.limit.transparentSticker.title", comment: "")
        }
    }

    var exhaustedTitle: String {
        switch self {
        case .visionCutout:
            return NSLocalizedString("usage.limit.vision.exhausted.title", comment: "")
        case .transparentStickerExport:
            return NSLocalizedString("usage.limit.transparentSticker.exhausted.title", comment: "")
        }
    }

    func trialMessage(remainingBeforeUse: Int) -> String {
        let remainingAfterUse = max(remainingBeforeUse - 1, 0)

        if remainingAfterUse == 0 {
            switch self {
            case .visionCutout:
                return NSLocalizedString("usage.limit.vision.message.last", comment: "")
            case .transparentStickerExport:
                return NSLocalizedString("usage.limit.transparentSticker.message.last", comment: "")
            }
        }

        switch self {
        case .visionCutout:
            return String(
                format: NSLocalizedString("usage.limit.vision.message.remaining", comment: ""),
                remainingAfterUse
            )
        case .transparentStickerExport:
            return String(
                format: NSLocalizedString("usage.limit.transparentSticker.message.remaining", comment: ""),
                remainingAfterUse
            )
        }
    }

    var exhaustedMessage: String {
        switch self {
        case .visionCutout:
            return NSLocalizedString("usage.limit.vision.exhausted.message", comment: "")
        case .transparentStickerExport:
            return NSLocalizedString("usage.limit.transparentSticker.exhausted.message", comment: "")
        }
    }
}

final class UsageLimitManager {
    static let shared = UsageLimitManager()

    private let service = "com.workoutplaza.usage-limits"
    private let account = "free-trial-counts"
    private var cachedCounts: [String: Int]

    private init() {
        cachedCounts = Self.loadCounts(service: service, account: account)
    }

    func remainingFreeUses(for feature: UsageLimitedFeature) -> Int {
        max(0, feature.freeUseLimit - usedCount(for: feature))
    }

    func hasRemainingFreeUses(for feature: UsageLimitedFeature) -> Bool {
        remainingFreeUses(for: feature) > 0
    }

    @discardableResult
    func consumeSuccessfulUse(for feature: UsageLimitedFeature) -> Int {
        let currentCount = usedCount(for: feature)
        guard currentCount < feature.freeUseLimit else { return 0 }

        cachedCounts[feature.rawValue] = currentCount + 1
        saveCounts()
        return remainingFreeUses(for: feature)
    }

    #if DEBUG
    func resetAllForDebug() {
        cachedCounts = [:]
        saveCounts()
    }
    #endif

    private func usedCount(for feature: UsageLimitedFeature) -> Int {
        cachedCounts[feature.rawValue] ?? 0
    }

    private func saveCounts() {
        guard let data = try? JSONEncoder().encode(cachedCounts) else { return }
        Self.saveCounts(data: data, service: service, account: account)
    }

    private static func loadCounts(service: String, account: String) -> [String: Int] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound,
              status == errSecSuccess,
              let data = item as? Data,
              let counts = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }

        return counts
    }

    private static func saveCounts(data: Data, service: String, account: String) {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemCopyMatching(baseQuery as CFDictionary, nil)
        if status == errSecSuccess {
            SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
            return
        }

        var addQuery = baseQuery
        attributes.forEach { addQuery[$0.key] = $0.value }
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
