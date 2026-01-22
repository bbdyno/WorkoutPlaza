//
//  ClimbingData.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import Foundation

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
