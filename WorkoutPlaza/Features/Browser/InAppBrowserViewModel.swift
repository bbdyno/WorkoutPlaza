//
//  InAppBrowserViewModel.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import Foundation

final class InAppBrowserViewModel {

    // MARK: - State

    struct State {
        var currentURL: URL?
        var title: String
        var estimatedProgress: Double
        var isLoading: Bool
        var canGoBack: Bool
        var canGoForward: Bool
    }

    private(set) var state: State {
        didSet { onStateDidChange?(state) }
    }

    var onStateDidChange: ((State) -> Void)?

    // MARK: - Init

    init(initialURL: URL) {
        self.state = State(
            currentURL: initialURL,
            title: "",
            estimatedProgress: 0,
            isLoading: false,
            canGoBack: false,
            canGoForward: false
        )
    }

    // MARK: - Updates

    func updateURL(_ url: URL?) {
        let previousURLString = state.currentURL?.absoluteString
        let currentURLString = url?.absoluteString
        if let currentURLString, currentURLString != previousURLString {
            WPLog.info("InAppBrowser current URL:", currentURLString)
        }
        state.currentURL = url
    }

    func updateTitle(_ title: String?) {
        state.title = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func updateProgress(_ progress: Double) {
        state.estimatedProgress = min(max(progress, 0), 1)
    }

    func updateLoading(_ isLoading: Bool) {
        state.isLoading = isLoading
    }

    func updateNavigationAvailability(canGoBack: Bool, canGoForward: Bool) {
        state.canGoBack = canGoBack
        state.canGoForward = canGoForward
    }

    // MARK: - Address Display

    func addressText(showsFullURL: Bool) -> String {
        guard let currentURL = state.currentURL else { return "" }
        return showsFullURL ? currentURL.absoluteString : shortAddressText(for: currentURL)
    }

    func shortAddressText(for url: URL) -> String {
        if let host = url.host, host.isEmpty == false {
            return host
        }
        return url.absoluteString
    }

    // MARK: - Input Sanitization

    /// 주소 입력값을 안전한 URL로 정규화한다.
    /// - Note: javascript:, data: 스킴은 차단하여 XSS 벡터를 예방한다.
    func normalizedURL(from rawText: String, allowsInsecureHTTP: Bool) -> URL? {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard var components = URLComponents(string: candidate) else { return nil }

        guard let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else {
            return nil
        }

        if scheme == "http" && allowsInsecureHTTP == false {
            return nil
        }

        guard let host = components.host, host.isEmpty == false else { return nil }

        // 호스트 입력에 공백/제어문자가 섞인 경우 안전하게 제거
        components.host = host.replacingOccurrences(of: " ", with: "")
        return components.url
    }
}
