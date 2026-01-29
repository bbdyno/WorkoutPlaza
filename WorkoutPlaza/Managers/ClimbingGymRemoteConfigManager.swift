//
//  ClimbingGymRemoteConfigManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/29/26.
//

import Foundation

class ClimbingGymRemoteConfigManager {
    static let shared = ClimbingGymRemoteConfigManager()

    private let remoteURL = "https://raw.githubusercontent.com/YOUR_REPO/main/remote-presets/climbing_gyms.json"
    private let cacheKey = "remoteClimbingGyms"
    private let lastSyncKey = "remoteClimbingGyms_lastSync"

    private init() {}

    func fetchRemotePresets(completion: @escaping (Result<[ClimbingGym], Error>) -> Void) {
        guard let url = URL(string: remoteURL) else {
            completion(.failure(NSError(domain: "ClimbingGymRemoteConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "ClimbingGymRemoteConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let remoteData = try decoder.decode(RemoteGymData.self, from: data)
                let gyms = remoteData.gyms.map { self?.convertToClimbingGym($0) }.compactMap { $0 }

                // Cache locally
                self?.cacheRemoteGyms(gyms)
                self?.updateLastSyncDate()

                DispatchQueue.main.async { completion(.success(gyms)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    private func convertToClimbingGym(_ remote: RemoteGym) -> ClimbingGym {
        ClimbingGym(
            id: remote.id,
            name: remote.name,
            logoSource: remote.logoUrl.isEmpty ? .none : .url(remote.logoUrl),
            gradeColors: remote.gradeColors,
            isBuiltIn: true,
            metadata: ClimbingGym.GymMetadata(
                region: remote.metadata?.region,
                branch: remote.metadata?.branch,
                remoteId: remote.id,
                lastUpdated: Date()
            )
        )
    }

    func loadCachedRemoteGyms() -> [ClimbingGym] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let gyms = try? JSONDecoder().decode([ClimbingGym].self, from: data)
        else { return [] }
        return gyms
    }

    private func cacheRemoteGyms(_ gyms: [ClimbingGym]) {
        if let data = try? JSONEncoder().encode(gyms) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func updateLastSyncDate() {
        UserDefaults.standard.set(Date(), forKey: lastSyncKey)
    }

    var lastSyncDate: Date? {
        UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    // MARK: - Remote Data Models

    struct RemoteGymData: Codable {
        let version: String
        let lastUpdated: String
        let gyms: [RemoteGym]
    }

    struct RemoteGym: Codable {
        let id: String
        let name: String
        let logoUrl: String
        let gradeColors: [String]
        let metadata: RemoteMetadata?
    }

    struct RemoteMetadata: Codable {
        let region: String?
        let branch: String?
        let website: String?
    }
}
