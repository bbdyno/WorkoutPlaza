//
//  FeaturePackManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import Foundation
import FirebaseRemoteConfig

/// Remote Config `feature_pack` JSON parser.
/// Centralized feature on/off gate for optional app capabilities.
final class FeaturePackManager {
    static let shared = FeaturePackManager()

    private let remoteConfig = RemoteConfig.remoteConfig()
    private let featurePackKey = "feature_pack"
    private let featurePackCacheKey = "remoteFeaturePackJson"

    private init() {
        applyRemoteConfigSettings()
        setDefaultFeaturePack()
    }

    enum FeatureKey: String {
        case templateMarket = "template_market"
        case widgetMarket = "widget_market"
    }

    struct FeaturePack: Codable {
        let version: String
        let updatedAt: String
        let features: [String: FeatureConfig]

        static let `default` = FeaturePack(
            version: "1.0.0",
            updatedAt: "1970-01-01T00:00:00Z",
            features: [
                FeatureKey.templateMarket.rawValue: .disabled,
                FeatureKey.widgetMarket.rawValue: .disabled
            ]
        )
    }

    struct FeatureConfig: Codable {
        let enabled: Bool
        let minimumAppVersion: String?
        let payload: [String: String]?

        static let disabled = FeatureConfig(
            enabled: false,
            minimumAppVersion: nil,
            payload: nil
        )
    }

    struct TemplateMarketButtonConfig {
        let isEnabled: Bool
        let title: String
        let destination: String?
    }

    struct WidgetMarketButtonConfig {
        let isEnabled: Bool
        let title: String
        let destination: String?
    }

    func setupAutoUpdate() {
        remoteConfig.fetchAndActivate { [weak self] status, error in
            guard let self else { return }

            if let error {
                WPLog.warning("feature_pack fetch failed:", error.localizedDescription)
                return
            }

            let remoteJSON = self.remoteConfig.configValue(forKey: self.featurePackKey).stringValue
            if self.parseFeaturePack(jsonString: remoteJSON) != nil {
                self.cacheFeaturePack(jsonString: remoteJSON)
            }

            WPLog.info("feature_pack fetchAndActivate status:", status.rawValue)
        }
    }

    /// Generic boolean gate for any feature defined in `feature_pack.features`.
    func isEnabled(_ key: FeatureKey) -> Bool {
        isFeatureEnabled(feature(for: key))
    }

    func templateMarketButtonConfig() -> TemplateMarketButtonConfig {
        let feature = feature(for: .templateMarket)
        let enabled = isFeatureEnabled(feature)
        let title = feature?.payload?["button_title"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let destination = feature?.payload?["destination"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return TemplateMarketButtonConfig(
            isEnabled: enabled,
            title: (title?.isEmpty == false)
                ? title!
                : NSLocalizedString("feature.pack.market.button", comment: "Template market button title"),
            destination: (destination?.isEmpty == false) ? destination : nil
        )
    }

    func widgetMarketButtonConfig() -> WidgetMarketButtonConfig {
        let feature = feature(for: .widgetMarket)
        let enabled = isFeatureEnabled(feature)
        let title = feature?.payload?["button_title"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let destination = feature?.payload?["destination"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return WidgetMarketButtonConfig(
            isEnabled: enabled,
            title: (title?.isEmpty == false)
                ? title!
                : NSLocalizedString("feature.pack.widget.market.button", comment: "Widget market button title"),
            destination: (destination?.isEmpty == false) ? destination : nil
        )
    }

    private func feature(for key: FeatureKey) -> FeatureConfig? {
        loadFeaturePack().features[key.rawValue]
    }

    private func loadFeaturePack() -> FeaturePack {
        let remoteJSON = remoteConfig.configValue(forKey: featurePackKey).stringValue
        if let parsed = parseFeaturePack(jsonString: remoteJSON) {
            cacheFeaturePack(jsonString: remoteJSON)
            return parsed
        }

        if let cachedJSON = UserDefaults.standard.string(forKey: featurePackCacheKey),
           let cached = parseFeaturePack(jsonString: cachedJSON) {
            return cached
        }

        return .default
    }

    private func parseFeaturePack(jsonString: String) -> FeaturePack? {
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        if let standaloneBooleanPack = parseStandaloneBooleanPack(from: trimmed) {
            return standaloneBooleanPack
        }

        guard trimmed.isEmpty == false,
              let data = trimmed.data(using: .utf8) else {
            return nil
        }

        if let strictPack = try? JSONDecoder().decode(FeaturePack.self, from: data) {
            return strictPack
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let dictionary = jsonObject as? [String: Any],
           let fallbackPack = parseFeaturePackFallback(from: dictionary) {
            return fallbackPack
        }

        WPLog.warning("Failed to parse feature_pack JSON. Expected object payload.")
        return nil
    }

    private func parseStandaloneBooleanPack(from value: String) -> FeaturePack? {
        guard let enabled = boolValue(from: value) else { return nil }
        return FeaturePack(
            version: "1.0.0",
            updatedAt: "1970-01-01T00:00:00Z",
            features: [
                FeatureKey.templateMarket.rawValue: FeatureConfig(
                    enabled: enabled,
                    minimumAppVersion: nil,
                    payload: nil
                )
            ]
        )
    }

    private func parseFeaturePackFallback(from dictionary: [String: Any]) -> FeaturePack? {
        let version = stringValue(from: dictionary["version"]) ?? "1.0.0"
        let updatedAt = stringValue(from: dictionary["updatedAt"])
            ?? stringValue(from: dictionary["updated_at"])
            ?? stringValue(from: dictionary["lastUpdated"])
            ?? stringValue(from: dictionary["last_updated"])
            ?? "1970-01-01T00:00:00Z"

        let nestedFeatures = dictionary["features"] as? [String: Any]
        let featureSource: [String: Any]

        if let nestedFeatures {
            featureSource = nestedFeatures
        } else if let enabled = boolValue(from: dictionary["enabled"]) {
            return FeaturePack(
                version: version,
                updatedAt: updatedAt,
                features: [
                    FeatureKey.templateMarket.rawValue: FeatureConfig(
                        enabled: enabled,
                        minimumAppVersion: stringValue(from: dictionary["minimumAppVersion"])
                            ?? stringValue(from: dictionary["minimum_app_version"]),
                        payload: dictionaryToStringMap(dictionary["payload"] as? [String: Any])
                    )
                ]
            )
        } else {
            featureSource = dictionary.filter { key, _ in
                !["version", "updatedAt", "updated_at", "lastUpdated", "last_updated"].contains(key)
            }
        }

        let parsedFeatures = parseFeatures(from: featureSource)
        guard parsedFeatures.isEmpty == false else {
            return nil
        }

        return FeaturePack(version: version, updatedAt: updatedAt, features: parsedFeatures)
    }

    private func parseFeatures(from source: [String: Any]) -> [String: FeatureConfig] {
        var parsed: [String: FeatureConfig] = [:]

        for (key, rawValue) in source {
            if let enabled = boolValue(from: rawValue) {
                parsed[key] = FeatureConfig(enabled: enabled, minimumAppVersion: nil, payload: nil)
                continue
            }

            guard let object = rawValue as? [String: Any] else { continue }

            let enabled = boolValue(from: object["enabled"]) ?? false
            let minimumAppVersion = stringValue(from: object["minimumAppVersion"])
                ?? stringValue(from: object["minimum_app_version"])

            let payload = payloadMap(from: object)
            parsed[key] = FeatureConfig(
                enabled: enabled,
                minimumAppVersion: minimumAppVersion,
                payload: payload
            )
        }

        return parsed
    }

    private func payloadMap(from object: [String: Any]) -> [String: String]? {
        if let payloadObject = object["payload"] as? [String: Any] {
            return dictionaryToStringMap(payloadObject)
        }

        let reservedKeys: Set<String> = [
            "enabled",
            "minimumAppVersion",
            "minimum_app_version",
            "payload"
        ]
        let inferredPayload = object.filter { !reservedKeys.contains($0.key) }
        return dictionaryToStringMap(inferredPayload)
    }

    private func dictionaryToStringMap(_ dictionary: [String: Any]?) -> [String: String]? {
        guard let dictionary else { return nil }
        var mapped: [String: String] = [:]

        for (key, value) in dictionary {
            if let string = stringValue(from: value) {
                mapped[key] = string
            }
        }

        return mapped.isEmpty ? nil : mapped
    }

    private func stringValue(from value: Any?) -> String? {
        guard let value else { return nil }

        if let string = value as? String {
            return string
        }

        if let number = value as? NSNumber {
            return number.stringValue
        }

        return nil
    }

    private func boolValue(from value: Any?) -> Bool? {
        switch value {
        case let bool as Bool:
            return bool
        case let number as NSNumber:
            return number.boolValue
        case let string as String:
            let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if ["true", "1", "yes", "on"].contains(normalized) { return true }
            if ["false", "0", "no", "off"].contains(normalized) { return false }
            return nil
        default:
            return nil
        }
    }

    private func cacheFeaturePack(jsonString: String) {
        guard jsonString.isEmpty == false else { return }
        UserDefaults.standard.set(jsonString, forKey: featurePackCacheKey)
    }

    private func setDefaultFeaturePack() {
        guard let data = try? JSONEncoder().encode(FeaturePack.default),
              let json = String(data: data, encoding: .utf8) else { return }

        remoteConfig.setDefaults([
            featurePackKey: json as NSString
        ])
    }

    private func applyRemoteConfigSettings() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = 10
        #else
        settings.minimumFetchInterval = 3600
        settings.fetchTimeout = 60
        #endif
        remoteConfig.configSettings = settings
    }

    private func isFeatureEnabled(_ feature: FeatureConfig?) -> Bool {
        guard let feature, feature.enabled else { return false }

        if let minimumAppVersion = feature.minimumAppVersion,
           minimumAppVersion.isEmpty == false,
           isCurrentAppVersionLower(than: minimumAppVersion) {
            return false
        }

        return true
    }

    private func isCurrentAppVersionLower(than minimumVersion: String) -> Bool {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        return compareVersion(current, minimumVersion) == .orderedAscending
    }

    private func compareVersion(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let leftComponents = normalizedVersionComponents(lhs)
        let rightComponents = normalizedVersionComponents(rhs)
        let maxCount = max(leftComponents.count, rightComponents.count)

        for index in 0..<maxCount {
            let leftValue = index < leftComponents.count ? leftComponents[index] : 0
            let rightValue = index < rightComponents.count ? rightComponents[index] : 0

            if leftValue < rightValue { return .orderedAscending }
            if leftValue > rightValue { return .orderedDescending }
        }

        return .orderedSame
    }

    private func normalizedVersionComponents(_ version: String) -> [Int] {
        let separators = CharacterSet(charactersIn: ".-_+ ")
        let rawComponents = version.components(separatedBy: separators)
        let parsed = rawComponents.compactMap { component -> Int? in
            let digits = component.filter(\.isNumber)
            guard digits.isEmpty == false else { return nil }
            return Int(digits)
        }
        return parsed.isEmpty ? [0] : parsed
    }
}
