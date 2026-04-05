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
        window?.overrideUserInterfaceStyle = .dark

        // Global navigation bar font
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = ColorSystem.background
        navAppearance.titleTextAttributes = [
            .foregroundColor: ColorSystem.mainText,
            .font: AppFont.bodyBold(17)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: ColorSystem.mainText,
            .font: AppFont.bodyBold(34)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = ColorSystem.mainText

        // Use Tab Bar Controller as root
        let tabBarController = MainTabBarController()
        tabBarController.suppressInitialWalkthrough = connectionOptions.urlContexts.isEmpty == false
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
