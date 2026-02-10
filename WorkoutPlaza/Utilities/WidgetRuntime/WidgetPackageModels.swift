//
//  WidgetPackageModels.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import Foundation

enum WidgetPackageTrustLevel: String, Codable, CaseIterable {
    case unverified
    case signed
    case trusted
    case invalid
}

struct WidgetPackageManifest: Codable, Hashable {
    let packageID: String
    let name: String
    let description: String
    let version: String
    let minimumAppVersion: String?
    let supportedSports: [SportType]
    let signature: String?
    let templateChecksums: [String: String]?
    let createdAt: Date?
}

struct WidgetPackage: Codable {
    let manifest: WidgetPackageManifest
    let templates: [WidgetTemplate]
    let definitions: [WidgetDefinition]?
}

struct InstalledWidgetPackage: Codable, Hashable {
    let packageID: String
    let name: String
    let version: String
    let installedAt: Date
    let trustLevel: WidgetPackageTrustLevel
    let packageFileName: String
    let templateIDs: [String]
    let definitionIDs: [String]
}

struct WidgetPackageVerificationReport: Hashable {
    let trustLevel: WidgetPackageTrustLevel
    let messages: [String]

    nonisolated var isValid: Bool {
        trustLevel != .invalid
    }
}

enum WidgetPackageError: LocalizedError {
    case invalidExtension
    case invalidPackage(String)
    case incompatibleVersion(required: String)
    case duplicatePackage(id: String, version: String)
    case notInstalled(id: String)

    var errorDescription: String? {
        switch self {
        case .invalidExtension:
            return "Unsupported package extension. Use .wpwidgetpack."
        case .invalidPackage(let reason):
            return "Invalid widget package: \(reason)"
        case .incompatibleVersion(let required):
            return "This package requires app version \(required) or later."
        case .duplicatePackage(let id, let version):
            return "Package \(id) v\(version) is already installed."
        case .notInstalled(let id):
            return "Package \(id) is not installed."
        }
    }
}

struct WidgetCatalogItem: Codable, Hashable {
    let packageID: String
    let name: String
    let description: String
    let version: String
    let minimumAppVersion: String?
    let supportedSports: [SportType]
    let downloadURL: URL
    let signature: String?
    let trustLevel: WidgetPackageTrustLevel

    nonisolated func isCompatible(appVersion: String) -> Bool {
        guard let minimumAppVersion else { return true }
        return appVersion.compare(minimumAppVersion, options: .numeric) != .orderedAscending
    }
}
