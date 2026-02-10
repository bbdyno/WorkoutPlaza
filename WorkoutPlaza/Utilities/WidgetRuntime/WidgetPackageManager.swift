//
//  WidgetPackageManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import Foundation

actor WidgetPackageManager {
    static let shared = WidgetPackageManager()

    private init() {}

    private var installedPackagesCache: [InstalledWidgetPackage] = []
    private var isInitialized = false

    private let fileManager = FileManager.default

    private var packagesDirectoryURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsURL.appendingPathComponent("WidgetPackages", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    private var indexFileURL: URL {
        packagesDirectoryURL.appendingPathComponent("index.json")
    }

    func installedPackages() async -> [InstalledWidgetPackage] {
        await ensureInitialized()
        return installedPackagesCache.sorted {
            if $0.packageID == $1.packageID {
                return $0.version > $1.version
            }
            return $0.packageID < $1.packageID
        }
    }

    func installPackage(from fileURL: URL) async throws -> InstalledWidgetPackage {
        await ensureInitialized()

        let ext = fileURL.pathExtension.lowercased()
        guard ext == "wpwidgetpack" || ext == "json" else {
            throw WidgetPackageError.invalidExtension
        }

        let data = try Data(contentsOf: fileURL)
        let package = try decodePackage(from: data)
        try validatePackage(package)

        let isDuplicate = installedPackagesCache.contains {
            $0.packageID == package.manifest.packageID && $0.version == package.manifest.version
        }
        if isDuplicate {
            throw WidgetPackageError.duplicatePackage(id: package.manifest.packageID, version: package.manifest.version)
        }

        let verification = await WidgetPackageVerifier.shared.verify(package: package)
        guard verification.isValid else {
            throw WidgetPackageError.invalidPackage(verification.messages.joined(separator: " "))
        }

        let packageFileName = Self.fileName(packageID: package.manifest.packageID, version: package.manifest.version)
        let targetURL = packagesDirectoryURL.appendingPathComponent(packageFileName)
        try data.write(to: targetURL, options: .atomic)

        for template in package.templates {
            try await TemplateManager.shared.saveCustomTemplate(template)
        }

        if let definitions = package.definitions, !definitions.isEmpty {
            await WidgetRegistry.shared.registerInstalledDefinitions(definitions)
        }

        let installed = InstalledWidgetPackage(
            packageID: package.manifest.packageID,
            name: package.manifest.name,
            version: package.manifest.version,
            installedAt: Date(),
            trustLevel: verification.trustLevel,
            packageFileName: packageFileName,
            templateIDs: package.templates.map(\.id),
            definitionIDs: package.definitions?.map { $0.id.rawValue } ?? []
        )

        installedPackagesCache.append(installed)
        try persistIndex()

        return installed
    }

    func installPackage(fromRemoteURL remoteURL: URL) async throws -> InstalledWidgetPackage {
        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wpwidgetpack")
        try data.write(to: temporaryURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }
        return try await installPackage(from: temporaryURL)
    }

    func removePackage(packageID: String, version: String? = nil) async throws {
        await ensureInitialized()

        let matches = installedPackagesCache.filter {
            guard $0.packageID == packageID else { return false }
            if let version {
                return $0.version == version
            }
            return true
        }

        guard !matches.isEmpty else {
            throw WidgetPackageError.notInstalled(id: packageID)
        }

        for installed in matches {
            let packageURL = packagesDirectoryURL.appendingPathComponent(installed.packageFileName)
            if let package = try? loadPackage(from: packageURL) {
                for template in package.templates {
                    try? await TemplateManager.shared.deleteCustomTemplate(template)
                }
                if let definitions = package.definitions, !definitions.isEmpty {
                    await WidgetRegistry.shared.unregisterInstalledDefinitions(definitions)
                }
            }
            if fileManager.fileExists(atPath: packageURL.path) {
                try? fileManager.removeItem(at: packageURL)
            }
        }

        installedPackagesCache.removeAll { installed in
            matches.contains(installed)
        }
        try persistIndex()
    }

    private func ensureInitialized() async {
        guard !isInitialized else { return }
        loadIndex()
        await restoreRegistryFromInstalledPackages()
        isInitialized = true
    }

    private func loadIndex() {
        guard fileManager.fileExists(atPath: indexFileURL.path),
              let data = try? Data(contentsOf: indexFileURL) else {
            installedPackagesCache = []
            return
        }

        do {
            installedPackagesCache = try Self.decoder.decode([InstalledWidgetPackage].self, from: data)
        } catch {
            installedPackagesCache = []
            WPLog.error("Failed to decode package index: \(error)")
        }
    }

    private func persistIndex() throws {
        let data = try Self.encoder.encode(installedPackagesCache)
        try data.write(to: indexFileURL, options: .atomic)
    }

    private func restoreRegistryFromInstalledPackages() async {
        var definitions: [WidgetDefinition] = []
        for package in installedPackagesCache {
            let packageURL = packagesDirectoryURL.appendingPathComponent(package.packageFileName)
            if let decoded = try? loadPackage(from: packageURL),
               let packageDefinitions = decoded.definitions {
                definitions.append(contentsOf: packageDefinitions)
            }
        }

        if !definitions.isEmpty {
            await WidgetRegistry.shared.registerInstalledDefinitions(definitions)
        }
    }

    private func loadPackage(from url: URL) throws -> WidgetPackage {
        let data = try Data(contentsOf: url)
        return try decodePackage(from: data)
    }

    private func decodePackage(from data: Data) throws -> WidgetPackage {
        do {
            return try Self.decoder.decode(WidgetPackage.self, from: data)
        } catch {
            throw WidgetPackageError.invalidPackage(error.localizedDescription)
        }
    }

    private func validatePackage(_ package: WidgetPackage) throws {
        if package.manifest.packageID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw WidgetPackageError.invalidPackage("Package id is missing.")
        }
        if package.manifest.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw WidgetPackageError.invalidPackage("Package name is missing.")
        }
        if package.templates.isEmpty {
            throw WidgetPackageError.invalidPackage("At least one template is required.")
        }

        if let minimumVersion = package.manifest.minimumAppVersion {
            let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            if currentAppVersion.compare(minimumVersion, options: .numeric) == .orderedAscending {
                throw WidgetPackageError.incompatibleVersion(required: minimumVersion)
            }
        }

        for template in package.templates {
            if !package.manifest.supportedSports.contains(template.sportType) {
                throw WidgetPackageError.invalidPackage("Template sport \(template.sportType.rawValue) is not declared in manifest.")
            }
        }
    }

    private static func fileName(packageID: String, version: String) -> String {
        "\(sanitize(packageID))_\(sanitize(version)).wpwidgetpack"
    }

    private static func sanitize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
}
