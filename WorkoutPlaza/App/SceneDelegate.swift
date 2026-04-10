//
//  SceneDelegate.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var pendingURL: URL?
    private var purchaseRefreshTask: Task<Void, Never>?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .light
        AppChrome.installGlobalAppearance()
        _ = PurchaseManager.shared

        // Use Tab Bar Controller as root
        let tabBarController = MainTabBarController()
        tabBarController.suppressInitialWalkthrough = connectionOptions.urlContexts.isEmpty == false || AppShowcaseManager.isEnabled
        window?.rootViewController = tabBarController

        window?.makeKeyAndVisible()

        if AppShowcaseManager.isEnabled {
            AppShowcaseManager.configure(window: window)
        }

        // Handle URL if app was launched with one
        if let urlContext = connectionOptions.urlContexts.first {
            // Store URL to handle after view is ready
            pendingURL = urlContext.url
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.handleIncomingURL(urlContext.url)
            }
        }
    }

    // Handle URLs when app is already running
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        handleIncomingURL(urlContext.url)
    }

    private func handleIncomingURL(_ url: URL) {
        if AppSchemeManager.shared.handle(url, rootViewController: window?.rootViewController) {
            WPLog.info("Handled app scheme URL:", url.absoluteString)
            return
        }

        let ext = url.pathExtension.lowercased()

        if ext == "gpx" {
            WPLog.info("Received .gpx file: \(url.lastPathComponent)")
            NotificationCenter.default.post(
                name: .didReceiveGPXFile,
                object: nil,
                userInfo: ["url": url]
            )
        } else if ext == "wplaza" {
            WPLog.info("Received .wplaza file: \(url.lastPathComponent)")
            NotificationCenter.default.post(
                name: .didReceiveSharedWorkout,
                object: nil,
                userInfo: ["url": url]
            )
        } else {
            WPLog.warning("Unsupported incoming URL:", url.absoluteString)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        purchaseRefreshTask?.cancel()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        purchaseRefreshTask?.cancel()
        purchaseRefreshTask = Task {
            await PurchaseManager.shared.refreshStoreStateIfNeeded()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
