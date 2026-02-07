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
    var branchColor: String?    // 지점 색상 (Hex Color, 기본값: "#FFFFFF")
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
        var brand: String?       // 암장명 (예: "서울숲클라이밍")
        var branch: String?      // 지점 (예: "구로점")
        var remoteId: String?    // Remote Config ID
        var lastUpdated: Date?   // 마지막 업데이트
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        logoSource: LogoSource = .none,
        gradeColors: [String] = [],
        branchColor: String? = nil,
        isBuiltIn: Bool = false,
        metadata: GymMetadata? = nil
    ) {
        self.id = id
        self.name = name
        self.logoSource = logoSource
        self.gradeColors = gradeColors
        self.branchColor = branchColor
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

    // 암장명만 추출 (예: "서울숲클라이밍")
    var gymBrandName: String {
        metadata?.brand ?? name
    }

    // 표시용 이름 (암장명 + 지점명)
    var displayName: String {
        if let brand = metadata?.brand, let branch = metadata?.branch {
            return "\(brand) \(branch)"
        }
        return name
    }
}

// MARK: - Climbing Gym Manager

class ClimbingGymManager {
    static let shared = ClimbingGymManager()
    private let userDefaults = UserDefaults.standard
    private let storageKey = "savedClimbingGyms"

    private init() {
        migrateOldGymsIfNeeded()
        migrateGymStructureIfNeeded()
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

    func migrateGymStructureIfNeeded() {
        let migrationKey = "climbingGyms_structure_migrated"
        guard !userDefaults.bool(forKey: migrationKey) else {
            WPLog.debug("Gym structure migration already completed")
            return
        }

        WPLog.info("Starting gym structure migration...")

        // 1. Load all custom gyms
        var customGyms = loadGyms()
        WPLog.info("Loaded \(customGyms.count) custom gyms for migration")

        // 2. Group gyms by brand name to find duplicates
        var brandGroups: [String: [ClimbingGym]] = [:]

        for gym in customGyms {
            let brandName = parseBrandName(from: gym.name)
            WPLog.debug("Gym: \(gym.name) -> Brand: \(brandName)")
            brandGroups[brandName, default: []].append(gym)
        }

        WPLog.info("Found \(brandGroups.count) brand groups")

        // 3. Process each brand group
        var updatedGyms: [ClimbingGym] = []

        for (brandName, gyms) in brandGroups {
            WPLog.info("Processing brand group: \(brandName) with \(gyms.count) gyms")
            
            if gyms.count == 1 {
                // Single gym - just add metadata
                var gym = gyms[0]
                if gym.metadata == nil {
                    gym.metadata = ClimbingGym.GymMetadata(brand: brandName, branch: nil)
                    WPLog.debug("Updated gym \(gym.name) with brand: \(brandName), branch: nil")
                    updatedGyms.append(gym)
                } else {
                    WPLog.debug("Gym \(gym.name) already has metadata, skipping")
                    updatedGyms.append(gym)
                }
            } else {
                // Multiple gyms with same brand - merge
                // Find the primary gym (usually the one with shortest name or first created)
                let primaryGym = gyms.min { $0.name.count < $1.name.count } ?? gyms[0]
                WPLog.debug("Primary gym: \(primaryGym.name)")

                for gym in gyms {
                    var updatedGym = gym
                    if gym.id == primaryGym.id {
                        // Primary gym - set brand without branch
                        updatedGym.metadata = ClimbingGym.GymMetadata(brand: brandName, branch: nil)
                        WPLog.debug("Updated primary gym \(gym.name) with brand: \(brandName), branch: nil")
                    } else {
                        // Branch gym - set brand and extract branch name
                        let branchName = gym.name.replacingOccurrences(of: brandName, with: "").trimmingCharacters(in: .whitespaces)
                        updatedGym.metadata = ClimbingGym.GymMetadata(brand: brandName, branch: branchName.isEmpty ? nil : branchName)
                        WPLog.debug("Updated branch gym \(gym.name) with brand: \(brandName), branch: \(branchName)")
                    }
                    updatedGyms.append(updatedGym)
                }
            }
        }

        // 4. Save updated gyms
        WPLog.info("Saving \(updatedGyms.count) updated gyms")
        saveGyms(updatedGyms)

        // 5. Update session data to use correct gym names
        migrateSessionGymNames()

        userDefaults.set(true, forKey: migrationKey)
        WPLog.info("Gym structure migration completed")
    }

    func forceMigrateGymStructure() {
        // Reset migration flag and run migration
        userDefaults.removeObject(forKey: "climbingGyms_structure_migrated")
        migrateGymStructureIfNeeded()
    }

    private func parseBrandName(from name: String) -> String {
        // Common patterns:
        // - "서울숲클라이밍 구로점" -> "서울숲클라이밍"
        // - "더클라이밍 강남" -> "더클라이밍"
        // - "더클라이밍홀딩스 강남점" -> "더클라이밍홀딩스"
        // - "더클라이밍 강남" -> "더클라이밍"

        let commonSuffixes = ["점", "지점", "센터", "클라이밍", "홀딩스"]

        var result = name

        // Try removing common suffixes
        for suffix in commonSuffixes {
            if result.hasSuffix(suffix) && result.count > suffix.count {
                let base = String(result.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                if !base.isEmpty {
                    WPLog.debug("  - Removed suffix '\(suffix)' from '\(result)' -> '\(base)'")
                    result = base
                }
            }
        }

        // Also check for patterns like "서울숲클라이밍 구로점" or "더클라이밍 강남"
        let parts = result.split(separator: " ").map { String($0) }
        if parts.count >= 2 {
            let firstPart = parts[0]
            // Check if second part is a location indicator
            let locationIndicators = ["강남", "구로", "홍대", "건대", "송파", "마포", "종로", "용산", "강서", "강동", "서초", "동작", "관악", "은평", "노원", "도봉", "중랑", "성동", "광진", "양천", "영등포", "금천", "동대문"]
            if locationIndicators.contains(parts[1]) {
                WPLog.debug("  - Detected location indicator '\(parts[1])' in '\(name)', returning '\(firstPart)'")
                return firstPart
            }
        }

        WPLog.debug("  - Final brand name for '\(name)': '\(result)'")
        return result
    }

    private func migrateSessionGymNames() {
        let sessionsKey = "savedClimbingSessions"

        guard let data = userDefaults.data(forKey: sessionsKey),
              var sessions = try? JSONDecoder().decode([ClimbingData].self, from: data) else {
            WPLog.warning("No climbing sessions found for migration")
            return
        }

        WPLog.info("Found \(sessions.count) sessions for gym name migration")

        var sessionsUpdated = false
        var updateCount = 0

        for i in 0..<sessions.count {
            var session = sessions[i]
            let gymName = session.gymName

            // Find the gym
            if let gym = findGym(byName: gymName) {
                WPLog.debug("Session gym '\(gymName)' found in gym manager")
                WPLog.debug("  - Gym metadata: brand=\(gym.metadata?.brand ?? "nil"), branch=\(gym.metadata?.branch ?? "nil")")
                // If gym has metadata with brand, update to use brand name
                if let brand = gym.metadata?.brand {
                    let branch = gym.metadata?.branch
                    let newGymName: String
                    if let branch = branch {
                        newGymName = "\(brand) \(branch)"
                    } else {
                        newGymName = brand
                    }

                    if session.gymName != newGymName {
                        session.gymName = newGymName
                        sessions[i] = session
                        sessionsUpdated = true
                        updateCount += 1
                        WPLog.debug("Updated session gym name: \(gymName) -> \(newGymName)")
                    } else {
                        WPLog.debug("Session gym name already matches: \(gymName)")
                    }
                } else {
                    WPLog.debug("Gym has no brand metadata, keeping original name")
                }
            } else {
                WPLog.debug("Session gym '\(gymName)' not found in gym manager")
            }
        }

        if sessionsUpdated {
            if let encoded = try? JSONEncoder().encode(sessions) {
                userDefaults.set(encoded, forKey: sessionsKey)
                WPLog.info("Session gym names migrated successfully: \(updateCount) sessions updated")
            }
        } else {
            WPLog.info("No session gym names needed updating")
        }
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
