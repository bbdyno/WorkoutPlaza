//
//  WidgetMarketplaceManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import Foundation

actor WidgetMarketplaceManager {
    static let shared = WidgetMarketplaceManager()

    private init() {}

    private var catalogURL: URL?
    private var minimumTrustLevel: WidgetPackageTrustLevel = .unverified

    func configure(catalogURL: URL?, minimumTrustLevel: WidgetPackageTrustLevel = .unverified) {
        self.catalogURL = catalogURL
        self.minimumTrustLevel = minimumTrustLevel
    }

    func fetchCatalog(for sport: SportType? = nil) async throws -> [WidgetCatalogItem] {
        guard let catalogURL else { return [] }
        let response = try await WidgetCatalogService.shared.fetchCatalog(from: catalogURL)
        return await WidgetCatalogService.shared.filterCompatibleItems(
            response.items,
            sport: sport,
            minimumTrust: minimumTrustLevel
        )
    }

    func installPackage(from item: WidgetCatalogItem) async throws -> InstalledWidgetPackage {
        let compatibleItems = await WidgetCatalogService.shared.filterCompatibleItems(
            [item],
            minimumTrust: minimumTrustLevel
        )
        guard compatibleItems.isEmpty == false else {
            throw WidgetPackageError.invalidPackage("Catalog item is not compatible with current trust policy.")
        }
        return try await WidgetPackageManager.shared.installPackage(fromRemoteURL: item.downloadURL)
    }

    func installedPackages() async -> [InstalledWidgetPackage] {
        await WidgetPackageManager.shared.installedPackages()
    }
}
