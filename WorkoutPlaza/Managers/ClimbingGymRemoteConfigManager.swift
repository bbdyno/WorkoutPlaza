//
//  ClimbingGymRemoteConfigManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/29/26.
//

import Foundation
import FirebaseCore
import FirebaseRemoteConfig

class ClimbingGymRemoteConfigManager {
    static let shared = ClimbingGymRemoteConfigManager()

    private let remoteConfig = RemoteConfig.remoteConfig()
    private let cacheKey = "remoteClimbingGyms"
    private let lastSyncKey = "remoteClimbingGyms_lastSync"

    private init() {
        print("🔧 Initializing ClimbingGymRemoteConfigManager...")

        // Remote Config 설정
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0 // 개발 중: 캐싱 없이 즉시 fetch
        #else
        settings.minimumFetchInterval = 3600 // 프로덕션: 1시간
        #endif
        remoteConfig.configSettings = settings

        // 기본값 설정
        let defaults: [String: NSObject] = [
            "climbing_gym_presets": "{\"version\":\"1.0.0\",\"gyms\":[]}" as NSString
        ]
        remoteConfig.setDefaults(defaults)

        print("✅ Firebase Remote Config initialized")
        print("🔧 Minimum fetch interval: \(settings.minimumFetchInterval) seconds")
        print("🔧 Last fetch status: \(remoteConfig.lastFetchStatus.rawValue)")
        print("🔧 Last fetch time: \(remoteConfig.lastFetchTime ?? Date(timeIntervalSince1970: 0))")
    }

    func fetchRemotePresets(completion: @escaping (Result<[ClimbingGym], Error>) -> Void) {
        print("🔄 Starting Firebase Remote Config fetch...")
        print("🔄 Current fetch status: \(remoteConfig.lastFetchStatus.rawValue)")

        // Firebase가 제대로 초기화되었는지 확인
        if FirebaseApp.app() == nil {
            print("❌ FirebaseApp is not initialized!")
            let error = NSError(domain: "ClimbingGymRemoteConfig", code: -3, userInfo: [NSLocalizedDescriptionKey: "Firebase not initialized"])
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }

        // GoogleService-Info.plist가 번들에 있는지 확인
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("✅ GoogleService-Info.plist found at: \(path)")
        } else {
            print("❌ GoogleService-Info.plist NOT found in bundle!")
        }

        // 간단한 네트워크 테스트
        testNetworkConnection()

        // Timeout 타이머 (15초로 증가)
        var hasCompleted = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if !hasCompleted {
                print("⏱️ Firebase Remote Config fetch timeout after 15 seconds")
                print("⚠️ Using cached/default values instead")
                hasCompleted = true
                let cached = self.loadCachedRemoteGyms()
                completion(.success(cached))
            }
        }

        // 명시적으로 expirationDuration을 0으로 설정하여 캐시 무시
        print("🔄 Calling fetch with expirationDuration: 0")
        remoteConfig.fetch(withExpirationDuration: 0) { [weak self] status, error in
            guard let self = self else { return }

            guard !hasCompleted else {
                print("⚠️ Fetch completed but timeout already triggered")
                return
            }
            hasCompleted = true

            print("📡 Firebase Remote Config fetch completed")
            print("📡 Fetch status: \(status.rawValue)")

            if let error = error {
                print("❌ Firebase Remote Config error: \(error.localizedDescription)")
                print("❌ Error domain: \((error as NSError).domain)")
                print("❌ Error code: \((error as NSError).code)")
                print("❌ Error userInfo: \((error as NSError).userInfo)")

                // 오류 발생 시 캐시된 값 사용
                let cached = self.loadCachedRemoteGyms()
                DispatchQueue.main.async { completion(.success(cached)) }
                return
            }

            if status == .success {
                print("✅ Fetch successful, now activating...")
                self.remoteConfig.activate { changed, activateError in
                    if let activateError = activateError {
                        print("❌ Activate error: \(activateError.localizedDescription)")
                    } else {
                        print("✅ Activate successful, config changed: \(changed)")
                    }
                    self.parseAndCacheGyms(completion: completion)
                }
            } else {
                print("❌ Fetch failed with status: \(status.rawValue)")
                let cached = self.loadCachedRemoteGyms()
                DispatchQueue.main.async { completion(.success(cached)) }
            }
        }
    }

    private func parseAndCacheGyms(completion: @escaping (Result<[ClimbingGym], Error>) -> Void) {
        let jsonString = remoteConfig.configValue(forKey: "climbing_gym_presets").stringValue ?? ""

        print("📥 Remote Config JSON: \(jsonString.prefix(200))...")

        guard let data = jsonString.data(using: .utf8) else {
            let error = NSError(domain: "ClimbingGymRemoteConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to data"])
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let remoteData = try decoder.decode(RemoteGymData.self, from: data)
            let gyms = remoteData.gyms.map { convertToClimbingGym($0) }

            print("✅ Parsed \(gyms.count) gyms from Remote Config")

            // Cache locally
            cacheRemoteGyms(gyms)
            updateLastSyncDate()

            DispatchQueue.main.async { completion(.success(gyms)) }
        } catch {
            print("❌ JSON parsing error: \(error)")
            DispatchQueue.main.async { completion(.failure(error)) }
        }
    }

    private func convertToClimbingGym(_ remote: RemoteGym) -> ClimbingGym {
        // Convert color presets to hex strings
        let colorHexStrings = remote.colors.map { $0.hex }

        return ClimbingGym(
            id: remote.id,
            name: remote.name,
            logoSource: remote.logoUrl.isEmpty ? .none : .url(remote.logoUrl),
            gradeColors: colorHexStrings,
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

    private func testNetworkConnection() {
        print("🌐 Testing network connection...")
        guard let url = URL(string: "https://www.google.com") else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Network test failed: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("✅ Network test successful: HTTP \(httpResponse.statusCode)")
            }
        }
        task.resume()
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
        let gradeSystem: String
        let colors: [ColorPreset]
        let metadata: RemoteMetadata?
    }

    struct ColorPreset: Codable {
        let name: String
        let hex: String
    }

    struct RemoteMetadata: Codable {
        let region: String?
        let branch: String?
        let website: String?
    }
}
