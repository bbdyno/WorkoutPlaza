//
//  AppSchemeManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import Foundation
import UIKit

/// Handles custom URL scheme deep links such as:
/// - workoutplaza://home
/// - workoutplaza://statistics
/// - workoutplaza://more
/// - workoutplaza://template-market
/// - workoutplaza://widget-market
final class AppSchemeManager {
    static let shared = AppSchemeManager()

    private init() {}

    let scheme = "workoutplaza"

    enum Route: String {
        case home
        case statistics
        case more
        case browser
        case templateMarket = "template-market"
        case widgetMarket = "widget-market"
    }

    struct BrowserRouteOptions {
        let showsAddressBar: Bool?
        let showsBottomToolbar: Bool?
        let presentationStyle: InAppBrowserConfiguration.PresentationStyle?

        init(
            showsAddressBar: Bool? = nil,
            showsBottomToolbar: Bool? = nil,
            presentationStyle: InAppBrowserConfiguration.PresentationStyle? = nil
        ) {
            self.showsAddressBar = showsAddressBar
            self.showsBottomToolbar = showsBottomToolbar
            self.presentationStyle = presentationStyle
        }
    }

    func makeRouteURL(
        _ route: Route,
        targetURLString: String? = nil,
        browserOptions: BrowserRouteOptions? = nil
    ) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = route.rawValue

        var queryItems: [URLQueryItem] = []
        if let targetURLString {
            let trimmedTarget = targetURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedTarget.isEmpty == false else { return nil }
            queryItems.append(URLQueryItem(name: "target_url", value: trimmedTarget))
        }

        if let browserOptions {
            if let showsAddressBar = browserOptions.showsAddressBar {
                queryItems.append(URLQueryItem(name: "shows_address_bar", value: showsAddressBar ? "true" : "false"))
            }
            if let showsBottomToolbar = browserOptions.showsBottomToolbar {
                queryItems.append(URLQueryItem(name: "shows_bottom_toolbar", value: showsBottomToolbar ? "true" : "false"))
            }
            if let presentationStyle = browserOptions.presentationStyle {
                let value = presentationStyle == .pageSheet ? "page_sheet" : "full_screen"
                queryItems.append(URLQueryItem(name: "presentation_style", value: value))
            }
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }

    func makeBrowserRouteURL(
        targetURLString: String,
        options: BrowserRouteOptions = BrowserRouteOptions()
    ) -> URL? {
        makeRouteURL(.browser, targetURLString: targetURLString, browserOptions: options)
    }

    /// Returns true when the URL is a supported `workoutplaza://` route.
    @discardableResult
    func handle(_ url: URL, rootViewController: UIViewController?) -> Bool {
        guard canHandle(url) else { return false }
        guard let route = route(from: url) else {
            WPLog.warning("Unsupported app scheme route:", url.absoluteString)
            return false
        }

        NotificationCenter.default.post(
            name: .didOpenAppSchemeURL,
            object: nil,
            userInfo: ["url": url, "route": route.rawValue]
        )

        switch route {
        case .home:
            return selectTab(index: 0, rootViewController: rootViewController)
        case .statistics:
            return selectTab(index: 1, rootViewController: rootViewController)
        case .more:
            return selectTab(index: 2, rootViewController: rootViewController)
        case .browser:
            guard let targetURL = targetWebURL(from: url) else {
                WPLog.warning("Missing or invalid url query for browser route:", url.absoluteString)
                return false
            }
            return presentBrowser(with: targetURL, route: .browser, routeURL: url, rootViewController: rootViewController)
        case .templateMarket:
            if let targetURL = targetWebURL(from: url) {
                return presentBrowser(with: targetURL, route: .templateMarket, routeURL: url, rootViewController: rootViewController)
            }
            _ = selectTab(index: 2, rootViewController: rootViewController)
            NotificationCenter.default.post(name: .didOpenTemplateMarketDeepLink, object: nil, userInfo: ["url": url])
            return true
        case .widgetMarket:
            if let targetURL = targetWebURL(from: url) {
                return presentBrowser(with: targetURL, route: .widgetMarket, routeURL: url, rootViewController: rootViewController)
            }
            _ = selectTab(index: 2, rootViewController: rootViewController)
            NotificationCenter.default.post(name: .didOpenWidgetMarketDeepLink, object: nil, userInfo: ["url": url])
            return true
        }
    }

    func canHandle(_ url: URL) -> Bool {
        url.scheme?.lowercased() == scheme
    }

    private func route(from url: URL) -> Route? {
        let tokens = routeTokens(from: url)
        for token in tokens {
            switch normalize(token) {
            case "home":
                return .home
            case "statistics", "stats":
                return .statistics
            case "more":
                return .more
            case "browser", "web", "inappbrowser":
                return .browser
            case "templatemarket":
                return .templateMarket
            case "widgetmarket":
                return .widgetMarket
            default:
                continue
            }
        }
        return nil
    }

    private func routeTokens(from url: URL) -> [String] {
        var tokens: [String] = []

        if let host = url.host, host.isEmpty == false {
            tokens.append(host)
        }

        let pathComponents = url.pathComponents.filter { component in
            component.isEmpty == false && component != "/"
        }
        tokens.append(contentsOf: pathComponents)

        return tokens
    }

    private func normalize(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }

    private func targetWebURL(from url: URL) -> URL? {
        let queryItems = queryItems(from: url)
        guard let value = queryItems.first(where: { $0.name == "target_url" })?.value else { return nil }
        return normalizedWebURL(from: value)
    }

    private func presentBrowser(with url: URL, route: Route, routeURL: URL, rootViewController: UIViewController?) -> Bool {
        guard let rootViewController else { return false }
        guard let presenter = topMostViewController(from: rootViewController) else { return false }

        DispatchQueue.main.async {
            let configuration = self.browserConfiguration(for: route, routeURL: routeURL)
            let browser = InAppBrowserViewController(url: url, configuration: configuration)
            let navigationController = UINavigationController(rootViewController: browser)
            navigationController.modalPresentationStyle = self.modalPresentationStyle(for: configuration.presentationStyle)
            presenter.present(navigationController, animated: true)
        }
        return true
    }

    private func queryItems(from url: URL) -> [URLQueryItem] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return []
        }
        return queryItems
    }

    private func normalizedWebURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if let directURL = URL(string: trimmed),
           let scheme = directURL.scheme?.lowercased(),
           ["http", "https"].contains(scheme) {
            return directURL
        }

        if trimmed.contains("://") {
            return nil
        }

        return URL(string: "https://\(trimmed)")
    }

    private func browserConfiguration(for route: Route, routeURL: URL) -> InAppBrowserConfiguration {
        var configuration = InAppBrowserConfiguration.default
        switch route {
        case .browser:
            configuration.showsAddressBar = DevSettings.shared.isInAppBrowserAddressBarVisible
            configuration.showsBottomToolbar = DevSettings.shared.isInAppBrowserToolbarVisible
            configuration.presentationStyle = DevSettings.shared.isInAppBrowserPresentedAsSheet ? .pageSheet : .fullScreen
        case .templateMarket, .widgetMarket:
            configuration.showsAddressBar = false
            configuration.showsBottomToolbar = false
            configuration.presentationStyle = .pageSheet
        default:
            break
        }

        let queryItems = queryItems(from: routeURL)
        if let showsAddressBar = boolQueryValue(for: "shows_address_bar", queryItems: queryItems) {
            configuration.showsAddressBar = showsAddressBar
        }
        if let showsBottomToolbar = boolQueryValue(for: "shows_bottom_toolbar", queryItems: queryItems) {
            configuration.showsBottomToolbar = showsBottomToolbar
        }
        if let presentationStyle = presentationStyleQueryValue(for: "presentation_style", queryItems: queryItems) {
            configuration.presentationStyle = presentationStyle
        }

        return configuration
    }

    private func boolQueryValue(for key: String, queryItems: [URLQueryItem]) -> Bool? {
        guard let rawValue = queryItems.first(where: { $0.name == key })?.value else { return nil }
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if ["true", "1", "yes", "on"].contains(normalized) { return true }
        if ["false", "0", "no", "off"].contains(normalized) { return false }
        return nil
    }

    private func presentationStyleQueryValue(
        for key: String,
        queryItems: [URLQueryItem]
    ) -> InAppBrowserConfiguration.PresentationStyle? {
        guard let rawValue = queryItems.first(where: { $0.name == key })?.value else { return nil }
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "full_screen":
            return .fullScreen
        case "page_sheet":
            return .pageSheet
        default:
            return nil
        }
    }

    private func modalPresentationStyle(for presentationStyle: InAppBrowserConfiguration.PresentationStyle) -> UIModalPresentationStyle {
        switch presentationStyle {
        case .fullScreen:
            return .fullScreen
        case .pageSheet:
            return .pageSheet
        }
    }

    private func selectTab(index: Int, rootViewController: UIViewController?) -> Bool {
        guard let tabBarController = findMainTabBarController(from: rootViewController) else {
            WPLog.warning("MainTabBarController not found for app scheme routing")
            return false
        }

        guard let viewControllers = tabBarController.viewControllers,
              index >= 0,
              index < viewControllers.count else {
            WPLog.warning("Tab index out of range for app scheme routing:", index)
            return false
        }

        tabBarController.selectedIndex = index
        if let navigationController = tabBarController.selectedViewController as? UINavigationController {
            navigationController.popToRootViewController(animated: false)
        }
        return true
    }

    private func findMainTabBarController(from rootViewController: UIViewController?) -> MainTabBarController? {
        guard let rootViewController else { return nil }

        if let tabBarController = rootViewController as? MainTabBarController {
            return tabBarController
        }

        if let navigationController = rootViewController as? UINavigationController {
            return findMainTabBarController(from: navigationController.visibleViewController)
        }

        if let tabBarController = rootViewController as? UITabBarController {
            return tabBarController as? MainTabBarController
        }

        if let presented = rootViewController.presentedViewController {
            return findMainTabBarController(from: presented)
        }

        return nil
    }

    private func topMostViewController(from rootViewController: UIViewController?) -> UIViewController? {
        guard let rootViewController else { return nil }

        if let navigationController = rootViewController as? UINavigationController {
            return topMostViewController(from: navigationController.visibleViewController)
        }

        if let tabBarController = rootViewController as? UITabBarController {
            return topMostViewController(from: tabBarController.selectedViewController ?? tabBarController)
        }

        if let presented = rootViewController.presentedViewController {
            return topMostViewController(from: presented)
        }

        return rootViewController
    }
}

extension Notification.Name {
    static let didOpenAppSchemeURL = Notification.Name("didOpenAppSchemeURL")
    static let didOpenTemplateMarketDeepLink = Notification.Name("didOpenTemplateMarketDeepLink")
    static let didOpenWidgetMarketDeepLink = Notification.Name("didOpenWidgetMarketDeepLink")
}
