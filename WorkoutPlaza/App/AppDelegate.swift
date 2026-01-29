//
//  AppDelegate.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import FirebaseCore
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("🚀 App launching...")
        print("📋 App Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

        FirebaseApp.configure()

        if let app = FirebaseApp.app() {
            print("✅ Firebase initialized successfully")
            print("📱 Firebase App Name: \(app.name)")

            let options = app.options
            print("🔑 Firebase Project ID: \(options.projectID ?? "unknown")")
            print("🔑 Firebase GCM Sender ID: \(options.gcmSenderID)")
            print("🔑 Firebase Google App ID: \(options.googleAppID)")
            print("🔑 Firebase API Key: \(options.apiKey ?? "unknown")")
            print("🔑 Firebase Bundle ID: \(options.bundleID ?? "unknown")")
        } else {
            print("❌ Firebase initialization failed!")
        }

        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
