//
//  ClimbingData.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import Foundation

// MARK: - Climbing Gym

// MARK: - Climbing Gym

struct ClimbingGym: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var logoSource: LogoSource  // 통합 로고 관리
    var gradeColors: [String]   // 난이도 체계 (Hex Colors)
    var isBuiltIn: Bool         // 프리셋 여부
    var metadata: GymMetadata?  // 확장 정보

    enum LogoSource: Codable, Equatable {
        case assetName(String)   // xcassets 이미지
        case imageData(Data)     // 사용자 업로드
        case url(String)         // Remote URL
        case none
    }

    struct GymMetadata: Codable, Equatable {
        var region: String?      // 지역 (예: "Seoul")
        var branch: String?      // 지점 (예: "구로점")
        var remoteId: String?    // Remote Config ID
        var lastUpdated: Date?   // 마지막 업데이트
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        logoSource: LogoSource = .none,
        gradeColors: [String] = [],
        isBuiltIn: Bool = false,
        metadata: GymMetadata? = nil
    ) {
        self.id = id
        self.name = name
        self.logoSource = logoSource
        self.gradeColors = gradeColors
        self.isBuiltIn = isBuiltIn
        self.metadata = metadata
    }

    // Legacy support: old initializer for backward compatibility during migration
    @available(*, deprecated, message: "Use new init with LogoSource")
    init(
        id: String = UUID().uuidString,
        name: String,
        logoImageName: String? = nil,
        logoImageData: Data? = nil,
        gradeColors: [String] = []
    ) {
        self.id = id
        self.name = name
        if let imageName = logoImageName {
            self.logoSource = .assetName(imageName)
        } else if let imageData = logoImageData {
            self.logoSource = .imageData(imageData)
        } else {
            self.logoSource = .none
        }
        self.gradeColors = gradeColors
        self.isBuiltIn = false
        self.metadata = nil
    }

    // 암장 이름으로 로고 이미지 이름을 추측하는 헬퍼
    var suggestedLogoImageName: String {
        // 암장 이름에서 특수문자, 공백 제거하고 소문자로 변환
        let normalized = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).inverted)
            .joined()
        return "gym_logo_\(normalized)"
    }
}

// MARK: - Climbing Gym Manager

class ClimbingGymManager {
    static let shared = ClimbingGymManager()
    private let userDefaults = UserDefaults.standard
    private let storageKey = "savedClimbingGyms"

    private init() {
        migrateOldGymsIfNeeded()
    }

    // MARK: - Presets
    
    var presets: [ClimbingGym] {
        return []
    }
    
    var defaultGradeColors: [String] {
        [
            "#FF3B30", // systemRed
            "#FF9500", // systemOrange
            "#FFCC00", // systemYellow
            "#34C759", // systemGreen
            "#007AFF", // systemBlue
            "#5856D6", // systemIndigo
            "#AF52DE", // systemPurple
            "#FF2D55", // systemPink
            "#A2845E", // brown
            "#8E8E93", // systemGray
            "#000000"  // black
        ]
    }

    // MARK: - CRUD Operations

    func saveGyms(_ gyms: [ClimbingGym]) {
        if let encoded = try? JSONEncoder().encode(gyms) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }

    func loadGyms() -> [ClimbingGym] {
        guard let data = userDefaults.data(forKey: storageKey),
              let gyms = try? JSONDecoder().decode([ClimbingGym].self, from: data) else {
            return []
        }
        return gyms.sorted { $0.name < $1.name }
    }

    func addGym(_ gym: ClimbingGym) {
        var gyms = loadGyms()
        gyms.append(gym)
        saveGyms(gyms)
    }

    func updateGym(_ gym: ClimbingGym) {
        var gyms = loadGyms()
        if let index = gyms.firstIndex(where: { $0.id == gym.id }) {
            gyms[index] = gym
            saveGyms(gyms)
        }
    }

    func deleteGym(id: String) {
        var gyms = loadGyms()
        gyms.removeAll { $0.id == id }
        saveGyms(gyms)
    }

    func findGym(byName name: String) -> ClimbingGym? {
        // defined gyms (presets) + saved gyms
        let allGyms = presets + loadGyms()
        return allGyms.first { $0.name.lowercased() == name.lowercased() }
    }

    func findOrCreateGym(name: String) -> ClimbingGym {
        if let existing = findGym(byName: name) {
            return existing
        }
        let newGym = ClimbingGym(name: name, logoSource: .none, gradeColors: defaultGradeColors, isBuiltIn: false)
        addGym(newGym)
        return newGym
    }

    // MARK: - Migration

    private func migrateOldGymsIfNeeded() {
        let migrationKey = "climbingGyms_migrated_v2"
        guard !userDefaults.bool(forKey: migrationKey) else { return }

        // Try to decode old format manually if standard decode fails
        guard let data = userDefaults.data(forKey: storageKey) else {
            userDefaults.set(true, forKey: migrationKey)
            return
        }

        // Attempt to decode with new format first (in case already migrated)
        if let _ = try? JSONDecoder().decode([ClimbingGym].self, from: data) {
            // Already in new format
            userDefaults.set(true, forKey: migrationKey)
            return
        }

        // Old data exists but can't decode with new format
        // This is expected - old format had different structure
        // For safety, we'll clear old data and mark as migrated
        // Users will need to re-add custom gyms (safer than risking data corruption)
        WPLog.warning("ClimbingGym migration: Old format detected, clearing for safety")
        userDefaults.removeObject(forKey: storageKey)
        userDefaults.set(true, forKey: migrationKey)
    }

    // MARK: - Helper Methods

    func getAllGyms() -> [ClimbingGym] {
        let builtIn = presets
        let remote = ClimbingGymRemoteConfigManager.shared.loadCachedRemoteGyms()
        let custom = loadGyms()

        // Combine and remove duplicates based on ID
        var uniqueGyms: [String: ClimbingGym] = [:]

        for gym in (builtIn + remote + custom) {
            uniqueGyms[gym.id] = gym
        }

        return Array(uniqueGyms.values).sorted { $0.name < $1.name }
    }

    func getBuiltInGyms() -> [ClimbingGym] {
        return presets
    }

    func getRemoteGyms() -> [ClimbingGym] {
        return ClimbingGymRemoteConfigManager.shared.loadCachedRemoteGyms()
    }

    func getCustomGyms() -> [ClimbingGym] {
        return loadGyms()
    }

    func syncRemotePresets(completion: @escaping (Result<Void, Error>) -> Void) {
        ClimbingGymRemoteConfigManager.shared.manualRefresh { result in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Climbing Discipline

enum ClimbingDiscipline: String, Codable, CaseIterable {
    case bouldering = "Bouldering"
    case leadEndurance = "LeadEndurance"

    var displayName: String {
        switch self {
        case .bouldering: return "볼더링"
        case .leadEndurance: return "리드/지구력"
        }
    }

    var iconName: String {
        switch self {
        case .bouldering: return "mountain.2.fill"
        case .leadEndurance: return "arrow.up.to.line"
        }
    }

    var description: String {
        switch self {
        case .bouldering: return "짧은 루트, 로프 없이 등반"
        case .leadEndurance: return "긴 루트, 로프로 등반"
        }
    }
}

// MARK: - Climbing Problem/Route

struct ClimbingRoute: Codable, Identifiable {
    let id: String
    var grade: String           // Grade text (e.g., "V3", "5.11a")
    var colorHex: String?       // Hold color as hex string (e.g., "#FF0000")
    var attempts: Int?          // For Bouldering: number of tries
    var takes: Int?             // For Lead: number of falls/hangs
    var isSent: Bool            // Successfully completed?
    var notes: String?          // Optional notes

    init(
        id: String = UUID().uuidString,
        grade: String,
        colorHex: String? = nil,
        attempts: Int? = nil,
        takes: Int? = nil,
        isSent: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.grade = grade
        self.colorHex = colorHex
        self.attempts = attempts
        self.takes = takes
        self.isSent = isSent
        self.notes = notes
    }

    // Display name combining color and grade
    var displayName: String {
        if let colorHex = colorHex, !grade.isEmpty {
            return grade
        } else if !grade.isEmpty {
            return grade
        } else {
            return "미지정"
        }
    }
}

// MARK: - Climbing Session Data

struct ClimbingData: SportDataProtocol, Codable {
    let id: String
    var gymName: String
    var discipline: ClimbingDiscipline
    var routes: [ClimbingRoute]
    var sessionDate: Date
    var sessionDuration: TimeInterval?  // Optional: session duration
    var notes: String?

    // SportDataProtocol
    var sportType: SportType { .climbing }
    var date: Date { sessionDate }
    var duration: TimeInterval? { sessionDuration }

    init(
        id: String = UUID().uuidString,
        gymName: String,
        discipline: ClimbingDiscipline,
        routes: [ClimbingRoute] = [],
        sessionDate: Date = Date(),
        sessionDuration: TimeInterval? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.gymName = gymName
        self.discipline = discipline
        self.routes = routes
        self.sessionDate = sessionDate
        self.sessionDuration = sessionDuration
        self.notes = notes
    }

    // MARK: - Computed Properties

    /// Total number of routes attempted
    var totalRoutes: Int {
        routes.count
    }

    /// Number of successfully sent routes
    var sentRoutes: Int {
        routes.filter { $0.isSent }.count
    }

    /// Total attempts across all bouldering problems
    var totalAttempts: Int {
        routes.compactMap { $0.attempts }.reduce(0, +)
    }

    /// Total takes across all lead routes
    var totalTakes: Int {
        routes.compactMap { $0.takes }.reduce(0, +)
    }

    /// Success rate (sent / total)
    var successRate: Double {
        guard totalRoutes > 0 else { return 0 }
        return Double(sentRoutes) / Double(totalRoutes) * 100
    }

    /// Highest grade sent (assumes grades are sortable strings - best effort)
    var highestGradeSent: String? {
        routes.filter { $0.isSent }.map { $0.grade }.max()
    }

    /// Summary text for display
    var summaryText: String {
        if discipline == .bouldering {
            return "\(sentRoutes)/\(totalRoutes) 완등"
        } else {
            return "\(sentRoutes)/\(totalRoutes) 완등, \(totalTakes) 테이크"
        }
    }
}

// MARK: - Exportable Climbing Data

struct ExportableClimbingData: ExportableSportData {
    let sportType: SportType = .climbing
    let id: String
    let gymName: String
    let discipline: ClimbingDiscipline
    let routes: [ClimbingRoute]
    let sessionDate: Date
    let sessionDuration: TimeInterval?
    let notes: String?

    init(from climbingData: ClimbingData) {
        self.id = climbingData.id
        self.gymName = climbingData.gymName
        self.discipline = climbingData.discipline
        self.routes = climbingData.routes
        self.sessionDate = climbingData.sessionDate
        self.sessionDuration = climbingData.sessionDuration
        self.notes = climbingData.notes
    }

    func toClimbingData() -> ClimbingData {
        ClimbingData(
            id: id,
            gymName: gymName,
            discipline: discipline,
            routes: routes,
            sessionDate: sessionDate,
            sessionDuration: sessionDuration,
            notes: notes
        )
    }
}

// MARK: - Climbing Data Manager

class ClimbingDataManager {
    static let shared = ClimbingDataManager()
    private let userDefaults = UserDefaults.standard
    private let storageKey = "savedClimbingSessions"

    private init() {}

    // MARK: - CRUD Operations

    func saveSessions(_ sessions: [ClimbingData]) {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }

    func loadSessions() -> [ClimbingData] {
        guard let data = userDefaults.data(forKey: storageKey),
              let sessions = try? JSONDecoder().decode([ClimbingData].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.sessionDate > $1.sessionDate }
    }

    func addSession(_ session: ClimbingData) {
        var sessions = loadSessions()
        sessions.append(session)
        saveSessions(sessions)
    }

    func updateSession(_ session: ClimbingData) {
        var sessions = loadSessions()
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            saveSessions(sessions)
        }
    }

    func deleteSession(id: String) {
        var sessions = loadSessions()
        sessions.removeAll { $0.id == id }
        saveSessions(sessions)
    }
}
