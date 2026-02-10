//
//  WidgetCatalogService.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import Foundation

struct WidgetCatalogResponse: Codable {
    let updatedAt: Date?
    let items: [WidgetCatalogItem]
}

actor WidgetCatalogService {
    static let shared = WidgetCatalogService()

    private init() {}

    func fetchCatalog(from url: URL) async throws -> WidgetCatalogResponse {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try Self.decoder.decode(WidgetCatalogResponse.self, from: data)
    }

    func filterCompatibleItems(
        _ items: [WidgetCatalogItem],
        sport: SportType? = nil,
        minimumTrust: WidgetPackageTrustLevel = .unverified
    ) -> [WidgetCatalogItem] {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        return items
            .filter { $0.isCompatible(appVersion: appVersion) }
            .filter { item in
                guard let sport else { return true }
                return item.supportedSports.contains(sport)
            }
            .filter { item in
                Self.trustRank(item.trustLevel) >= Self.trustRank(minimumTrust)
            }
            .sorted { lhs, rhs in
                if lhs.trustLevel == rhs.trustLevel {
                    return lhs.name < rhs.name
                }
                return Self.trustRank(lhs.trustLevel) > Self.trustRank(rhs.trustLevel)
            }
    }

    private static func trustRank(_ trustLevel: WidgetPackageTrustLevel) -> Int {
        switch trustLevel {
        case .invalid: return 0
        case .unverified: return 1
        case .signed: return 2
        case .trusted: return 3
        }
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
