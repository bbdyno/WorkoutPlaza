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
        case templateMarket = "template-market"
        case widgetMarket = "widget-market"
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
        case .templateMarket:
            _ = selectTab(index: 2, rootViewController: rootViewController)
            NotificationCenter.default.post(name: .didOpenTemplateMarketDeepLink, object: nil, userInfo: ["url": url])
            return true
        case .widgetMarket:
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

        if let presented = rootViewController.presentedViewController {
            return findMainTabBarController(from: presented)
        }

        if let navigationController = rootViewController as? UINavigationController {
            return findMainTabBarController(from: navigationController.visibleViewController)
        }

        if let tabBarController = rootViewController as? UITabBarController {
            return tabBarController as? MainTabBarController
        }

        return nil
    }
}

extension Notification.Name {
    static let didOpenAppSchemeURL = Notification.Name("didOpenAppSchemeURL")
    static let didOpenTemplateMarketDeepLink = Notification.Name("didOpenTemplateMarketDeepLink")
    static let didOpenWidgetMarketDeepLink = Notification.Name("didOpenWidgetMarketDeepLink")
}
