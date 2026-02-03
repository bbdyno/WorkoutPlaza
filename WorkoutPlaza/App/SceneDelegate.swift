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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        // Use Tab Bar Controller as root
        let tabBarController = MainTabBarController()
        window?.rootViewController = tabBarController

        window?.makeKeyAndVisible()

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
        // Only handle .wplaza files
        guard url.pathExtension.lowercased() == "wplaza" else {
            WPLog.warning("Unsupported file extension: \(url.pathExtension)")
            return
        }

        WPLog.info("Received .wplaza file: \(url.lastPathComponent)")

        // Post notification to handle the file
        NotificationCenter.default.post(
            name: .didReceiveSharedWorkout,
            object: nil,
            userInfo: ["url": url]
        )
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
