//
//  GitHubProfileService.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

enum GitHubLinks {
    static let repository = "https://github.com/bbdyno/WorkoutPlaza"
    static let developerProfile = "https://github.com/bbdyno"
    static let apiProfile = "https://api.github.com/users/bbdyno"
}

struct GitHubUserProfile: Decodable, Sendable {
    let login: String
    let name: String?
    let bio: String?
    let publicRepos: Int
    let followers: Int
    let following: Int

    enum CodingKeys: String, CodingKey {
        case login
        case name
        case bio
        case publicRepos = "public_repos"
        case followers
        case following
    }
}

actor GitHubProfileService {
    static let shared = GitHubProfileService()

    enum ServiceError: Error {
        case invalidURL
        case invalidHTTPResponse
        case badStatusCode(Int)
    }

    private var cachedProfile: GitHubUserProfile?
    private var lastFetchedAt: Date?
    private let cacheDuration: TimeInterval = 300
    private let decoder = JSONDecoder()

    func fetchProfile(forceRefresh: Bool = false) async throws -> GitHubUserProfile {
        if forceRefresh == false,
           let cachedProfile,
           let lastFetchedAt,
           Date().timeIntervalSince(lastFetchedAt) < cacheDuration {
            return cachedProfile
        }

        guard let url = URL(string: GitHubLinks.apiProfile) else {
            throw ServiceError.invalidURL
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("WorkoutPlaza-iOS", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidHTTPResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ServiceError.badStatusCode(httpResponse.statusCode)
        }

        let profile = try decoder.decode(GitHubUserProfile.self, from: data)
        cachedProfile = profile
        lastFetchedAt = Date()
        return profile
    }
}
