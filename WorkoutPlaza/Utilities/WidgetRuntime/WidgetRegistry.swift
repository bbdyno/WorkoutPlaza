//
//  WidgetRegistry.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import Foundation

struct WidgetCapabilities: Codable, Hashable {
    let supportsColor: Bool
    let supportsFont: Bool
    let supportsAlignment: Bool
    let supportsPayloadEditing: Bool
}

struct WidgetDefinition: Codable, Hashable {
    let id: WidgetDefinitionID
    let displayName: String
    let iconName: String
    let supportedSports: [SportType]
    let widgetType: WidgetType
    let capabilities: WidgetCapabilities
    let minimumAppVersion: String?
}

actor WidgetRegistry {
    static let shared = WidgetRegistry()

    private init() {}

    private var installedDefinitions: [WidgetDefinitionID: WidgetDefinition] = [:]

    func registerInstalledDefinitions(_ definitions: [WidgetDefinition]) {
        for definition in definitions {
            installedDefinitions[definition.id] = definition
        }
    }

    func unregisterInstalledDefinitions(_ definitions: [WidgetDefinition]) {
        for definition in definitions {
            installedDefinitions.removeValue(forKey: definition.id)
        }
    }

    func definition(for id: WidgetDefinitionID) async -> WidgetDefinition? {
        if let installed = installedDefinitions[id] {
            return installed
        }
        return await Self.builtInDefinition(for: id)
    }

    func allDefinitions(for sport: SportType? = nil) async -> [WidgetDefinition] {
        var builtIn: [WidgetDefinition] = []
        for id in WidgetDefinitionID.allCases {
            if let definition = await Self.builtInDefinition(for: id) {
                builtIn.append(definition)
            }
        }
        let merged = Dictionary(uniqueKeysWithValues: (builtIn + installedDefinitions.values).map { ($0.id, $0) })
        let values = Array(merged.values)
        guard let sport else {
            return values.sorted { $0.displayName < $1.displayName }
        }
        return values
            .filter { $0.supportedSports.contains(sport) }
            .sorted { $0.displayName < $1.displayName }
    }

    @MainActor
    private static func builtInDefinition(for id: WidgetDefinitionID) -> WidgetDefinition? {
        let widgetType = WidgetIdentity.widgetType(for: id)
        let capabilities = capabilities(for: id)
        return WidgetDefinition(
            id: id,
            displayName: widgetType.displayName,
            iconName: widgetType.iconName,
            supportedSports: widgetType.supportedSports,
            widgetType: widgetType,
            capabilities: capabilities,
            minimumAppVersion: nil
        )
    }

    private static func capabilities(for id: WidgetDefinitionID) -> WidgetCapabilities {
        switch id {
        case .routeMap:
            return WidgetCapabilities(
                supportsColor: true,
                supportsFont: false,
                supportsAlignment: false,
                supportsPayloadEditing: false
            )
        case .text, .composite, .date, .currentDateTime, .location, .climbingRoutesByColor, .gymLogo:
            return WidgetCapabilities(
                supportsColor: true,
                supportsFont: true,
                supportsAlignment: true,
                supportsPayloadEditing: true
            )
        default:
            return WidgetCapabilities(
                supportsColor: true,
                supportsFont: true,
                supportsAlignment: true,
                supportsPayloadEditing: false
            )
        }
    }
}
