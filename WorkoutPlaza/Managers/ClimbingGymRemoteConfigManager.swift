//
//  ClimbingGymRemoteConfigManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/29/26.
//

import Foundation
import FirebaseCore
import FirebaseRemoteConfig
import Combine

/// Firebase Remote Config Manager for Climbing Gym Presets
/// Supports both automatic updates and manual refresh
class ClimbingGymRemoteConfigManager {
    static let shared = ClimbingGymRemoteConfigManager()

    // MARK: - Properties
    
    private lazy var remoteConfig = RemoteConfig.remoteConfig()
    private let climbingGymPresetsKey = "climbing_gym_presets"
    private let climbingGymPresetsEnglishKey = "climbing_gym_presets_eng"
    private let cacheKey = "remoteClimbingGyms"
    private let lastSyncKey = "remoteClimbingGyms_lastSync"

    /// Publisher that emits when remote config is updated
    private let configUpdateSubject = PassthroughSubject<[ClimbingGym], Never>()
    var configUpdatePublisher: AnyPublisher<[ClimbingGym], Never> {
        configUpdateSubject.eraseToAnyPublisher()
    }

    private var configUpdateListenerHandle: ConfigUpdateListenerRegistration?

    // MARK: - Initialization

    private init() {
        setupRemoteConfig()
    }

    deinit {
        configUpdateListenerHandle?.remove()
    }

    private func setupRemoteConfig() {
        WPLog.info("Initializing ClimbingGymRemoteConfigManager...")

        // Remote Config 설정
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0 // 개발 중: 캐싱 없이 즉시 fetch
        settings.fetchTimeout = 10 // 개발 중: 10초 timeout
        #else
        settings.minimumFetchInterval = 3600 // 프로덕션: 1시간
        settings.fetchTimeout = 60 // 프로덕션: 60초 timeout
        #endif
        remoteConfig.configSettings = settings

        // 기본값 설정 (빈 JSON)
        let defaultJson = """
        {
            "version": "1.0.0",
            "lastUpdated": "2026-01-30T00:00:00Z",
            "gyms": []
        }
        """

        let defaults: [String: NSObject] = [
            climbingGymPresetsKey: defaultJson as NSString,
            climbingGymPresetsEnglishKey: defaultJson as NSString
        ]
        remoteConfig.setDefaults(defaults)

        // Default 값이 제대로 설정되었는지 확인
        let testValue = remoteConfig.configValue(forKey: climbingGymPresetsKey)
        WPLog.info("Firebase Remote Config initialized",
                   "Minimum fetch interval: \(settings.minimumFetchInterval)",
                   "Fetch timeout: \(settings.fetchTimeout)",
                   "Default value length: \(testValue.stringValue.count)")
    }

    // MARK: - Auto Update Setup

    /// 앱 시작 시 호출하여 자동 업데이트 설정
    /// 초기 fetch 및 실시간 업데이트 리스너 등록
    func setupAutoUpdate(completion: ((Result<[ClimbingGym], Error>) -> Void)? = nil) {
        WPLog.info("Setting up auto-update for Remote Config...")

        // 1. 초기 fetch and activate
        fetchAndActivate { [weak self] result in
            completion?(result)

            // 2. 실시간 업데이트 리스너 등록
            if case .success = result {
                self?.addConfigUpdateListener()
            }
        }
    }

    /// 실시간 config 업데이트 리스너 추가
    private func addConfigUpdateListener() {
        WPLog.info("Adding config update listener...")

        configUpdateListenerHandle = remoteConfig.addOnConfigUpdateListener { [weak self] configUpdate, error in
            guard let self = self else { return }

            if let error = error {
                WPLog.error("Config update listener error: \(error.localizedDescription)")
                return
            }

            guard let configUpdate = configUpdate else {
                WPLog.warning("Config update is nil")
                return
            }

            WPLog.network("Remote Config updated! Updated keys: \(configUpdate.updatedKeys)")
            AnalyticsManager.shared.logEvent("remote_config_updated", parameters: ["keys": configUpdate.updatedKeys])

            // 업데이트된 config를 activate하고 파싱
            self.remoteConfig.activate { activated, activateError in
                if let activateError = activateError {
                    WPLog.error("Auto-activate error: \(activateError.localizedDescription)")
                    AnalyticsManager.shared.logRemoteConfigFetch(status: "activate_failed", details: activateError.localizedDescription)
                    return
                }

                WPLog.info("Auto-activated updated config (changed: \(activated))")

                // 파싱하고 캐시 업데이트
                if let gyms = self.parseGyms() {
                    self.cacheRemoteGyms(gyms)
                    self.updateLastSyncDate()
                    
                    AnalyticsManager.shared.logGymsLoaded(count: gyms.count, source: "remote_update")

                    // Publisher를 통해 업데이트 알림
                    self.configUpdateSubject.send(gyms)
                    WPLog.info("Published \(gyms.count) gyms to subscribers")
                }
            }
        }

        WPLog.info("Config update listener registered")
    }

    // MARK: - Manual Refresh

    /// 수동으로 최신 config를 가져오기 (Pull-to-refresh 등에 사용)
    func manualRefresh(completion: @escaping (Result<[ClimbingGym], Error>) -> Void) {
        WPLog.info("Manual refresh triggered...")
        fetchAndActivate(completion: completion)
    }

    // MARK: - Core Fetch Logic

    /// Firebase Remote Config fetch and activate
    private func fetchAndActivate(completion: @escaping (Result<[ClimbingGym], Error>) -> Void) {
        WPLog.network("Starting fetchAndActivate...")

        // 상세 디버깅 정보
        WPLog.debug("Remote Config Debug Info:",
                    "Last fetch status: \(remoteConfig.lastFetchStatus.rawValue)",
                    "Last fetch time: \(remoteConfig.lastFetchTime ?? Date(timeIntervalSince1970: 0))",
                    "Config settings: \(remoteConfig.configSettings)")

        // Firebase 초기화 확인
        guard let app = FirebaseApp.app() else {
            let error = NSError(
                domain: "ClimbingGymRemoteConfig",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Firebase not initialized"]
            )
            WPLog.error("Firebase not initialized!")
            AnalyticsManager.shared.logRemoteConfigFetch(status: "failure", details: "Firebase not initialized")
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }

        // Firebase 앱 정보 출력
        WPLog.debug("Firebase App Info:",
                    "Name: \(app.name)",
                    "Project ID: \(app.options.projectID ?? "unknown")",
                    "Bundle ID: \(app.options.bundleID)",
                    "API Key: \(app.options.apiKey?.prefix(10) ?? "unknown")...")

        // GoogleService-Info.plist 확인
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            WPLog.debug("GoogleService-Info.plist found at: \(path)")
            if let dict = NSDictionary(contentsOfFile: path) {
                WPLog.debug("BUNDLE_ID: \(dict["BUNDLE_ID"] ?? "unknown")",
                            "PROJECT_ID: \(dict["PROJECT_ID"] ?? "unknown")")
            }
        } else {
            WPLog.error("GoogleService-Info.plist NOT found!")
        }

        // 현재 config 값 확인
        let selectedKey = selectedGymPresetsKey()
        let currentValue = remoteConfig.configValue(forKey: selectedKey)
        WPLog.debug("Current config value:",
                    "Selected key: \(selectedKey)",
                    "Source: \(currentValue.source.rawValue)",
                    "Value: \(currentValue.stringValue.prefix(100))...")

        // Timeout 처리
        var hasCompleted = false
        let timeoutSeconds = 15.0

        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds) {
            if !hasCompleted {
                WPLog.warning("Firebase Remote Config timeout after \(timeoutSeconds) seconds",
                              "Last fetch status was: \(self.remoteConfig.lastFetchStatus.rawValue)",
                              "Using cached values instead")
                hasCompleted = true
                let cached = self.loadCachedRemoteGyms()
                completion(.success(cached))
            }
        }

        // fetchAndActivate 호출 (권장되는 방식)
        WPLog.network("Calling fetchAndActivate()...")
        remoteConfig.fetchAndActivate { [weak self] status, error in
            guard let self = self else { return }

            guard !hasCompleted else {
                WPLog.warning("fetchAndActivate completed but timeout already triggered")
                return
            }
            hasCompleted = true
            
            WPLog.network("fetchAndActivate callback received")

            // 에러 처리
            if let error = error {
                let nsError = error as NSError
                WPLog.error("fetchAndActivate error: \(error.localizedDescription)")
                
                AnalyticsManager.shared.logRemoteConfigFetch(status: "failure", details: error.localizedDescription)

                // 특정 에러 코드에 대한 추가 정보
                if nsError.domain == "com.google.remoteconfig.ErrorDomain" {
                    switch nsError.code {
                    case 8001:
                        WPLog.warning("Error 8001: Throttled - too many requests")
                    case 8002:
                        WPLog.error("Error 8002: Internal error")
                    case 8003:
                        WPLog.warning("Error 8003: Config update unavailable")
                    default:
                        WPLog.error("Unknown Remote Config error code: \(nsError.code)")
                    }
                }

                // 에러 발생 시 캐시된 값 사용
                let cached = self.loadCachedRemoteGyms()
                AnalyticsManager.shared.logGymsLoaded(count: cached.count, source: "cache_fallback")
                DispatchQueue.main.async { completion(.success(cached)) }
                return
            }

            // 상태 확인
            WPLog.info("fetchAndActivate status: \(status.rawValue)")
            switch status {
            case .successFetchedFromRemote:
                WPLog.network("Successfully fetched and activated from remote")
                self.handleSuccessfulFetch(completion: completion)

            case .successUsingPreFetchedData:
                WPLog.info("Using pre-fetched data (no new data)")
                self.handleSuccessfulFetch(completion: completion)

            case .error:
                WPLog.error("fetchAndActivate failed with error status")
                let cached = self.loadCachedRemoteGyms()
                DispatchQueue.main.async { completion(.success(cached)) }

            @unknown default:
                WPLog.warning("Unknown fetchAndActivate status: \(status.rawValue)")
                let cached = self.loadCachedRemoteGyms()
                DispatchQueue.main.async { completion(.success(cached)) }
            }
        }
    }

    private func handleSuccessfulFetch(completion: @escaping (Result<[ClimbingGym], Error>) -> Void) {
        guard let gyms = parseGyms() else {
            let error = NSError(
                domain: "ClimbingGymRemoteConfig",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse remote config data"]
            )
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }

        WPLog.info("Parsed \(gyms.count) gyms from Remote Config")
        
        AnalyticsManager.shared.logRemoteConfigFetch(status: "success")
        AnalyticsManager.shared.logGymsLoaded(count: gyms.count, source: "remote")

        // 캐시 저장
        cacheRemoteGyms(gyms)
        updateLastSyncDate()

        DispatchQueue.main.async { completion(.success(gyms)) }
    }
    
    // MARK: - Parsing

    /// Remote Config에서 gym 데이터 파싱
    private func parseGyms() -> [ClimbingGym]? {
        let primaryKey = selectedGymPresetsKey()
        let fallbackKey = fallbackGymPresetsKey(for: primaryKey)

        let primaryJson = remoteConfig.configValue(forKey: primaryKey).stringValue
        let usingFallback = primaryJson.isEmpty
        let jsonString = usingFallback
            ? remoteConfig.configValue(forKey: fallbackKey).stringValue
            : primaryJson

        if usingFallback {
            WPLog.warning("Remote Config value empty for key '\(primaryKey)'. Using fallback key '\(fallbackKey)'.")
        }

        WPLog.debug("Using gym presets key: \(usingFallback ? fallbackKey : primaryKey)")

        WPLog.debug("Remote Config JSON: \(jsonString.prefix(200))...")

        guard !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8) else {
            WPLog.warning("Empty or invalid JSON string")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let remoteData = try decoder.decode(RemoteGymData.self, from: data)
            let gyms = remoteData.gyms.map { convertToClimbingGym($0) }

            return gyms
        } catch {
            WPLog.error("JSON parsing error: \(error)")
            if let decodingError = error as? DecodingError {
                WPLog.error("Decoding error details: \(decodingError)")
            }
            return nil
        }
    }

    private func selectedGymPresetsKey() -> String {
        let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? Locale.current.identifier.lowercased()
        let isKorean = preferredLanguage.hasPrefix("ko")
        return isKorean ? climbingGymPresetsKey : climbingGymPresetsEnglishKey
    }

    private func fallbackGymPresetsKey(for primaryKey: String) -> String {
        primaryKey == climbingGymPresetsKey ? climbingGymPresetsEnglishKey : climbingGymPresetsKey
    }

    private func convertToClimbingGym(_ remote: RemoteGym) -> ClimbingGym {
        let colorHexStrings = remote.colors.map { $0.hex }

        return ClimbingGym(
            id: remote.id,
            name: remote.name,
            logoSource: remote.logoUrl.isEmpty ? .none : {
                WPLog.debug("Gym \(remote.name) has logo URL: \(remote.logoUrl)")
                return .url(remote.logoUrl)
            }(),
            gradeColors: colorHexStrings,
            branchColor: remote.branchColor ?? "#FFFFFF",
            isBuiltIn: true,
            metadata: ClimbingGym.GymMetadata(
                region: remote.metadata?.region,
                branch: remote.metadata?.branch
            )
        )
    }

    // MARK: - Caching

    /// 캐시된 gym 데이터 불러오기
    func loadCachedRemoteGyms() -> [ClimbingGym] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let gyms = try? JSONDecoder().decode([ClimbingGym].self, from: data)
        else {
            WPLog.info("No cached remote gyms found")
            return []
        }
        WPLog.info("Loaded \(gyms.count) gyms from cache")
        AnalyticsManager.shared.logGymsLoaded(count: gyms.count, source: "cache_explicit")
        return gyms
    }

    private func cacheRemoteGyms(_ gyms: [ClimbingGym]) {
        if let data = try? JSONEncoder().encode(gyms) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            WPLog.info("Cached \(gyms.count) gyms")
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
        let gradeSystem: String
        let colors: [ColorPreset]
        let branchColor: String?
        let metadata: RemoteMetadata?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case logoUrl
            case gradeSystem
            case colors
            case branchColor
            case metadata
        }
    }

    struct ColorPreset: Codable {
        let name: String
        let hex: String
    }

    struct RemoteMetadata: Codable {
        let region: String?
        let brand: String?
        let branch: String?
    }
}
