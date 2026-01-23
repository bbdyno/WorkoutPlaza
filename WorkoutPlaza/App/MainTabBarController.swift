//
//  MainTabBarController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/23/26.
//

import UIKit

class MainTabBarController: UITabBarController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    // MARK: - Setup

    private func setupTabs() {
        // Tab 1: Home (기록)
        let homeVC = HomeDashboardViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.navigationBar.prefersLargeTitles = true
        homeNav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // Tab 2: Statistics (통계)
        let statsVC = StatisticsViewController()
        let statsNav = UINavigationController(rootViewController: statsVC)
        statsNav.navigationBar.prefersLargeTitles = true
        statsNav.tabBarItem = UITabBarItem(
            title: "통계",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )

        // Tab 3: More (더보기)
        let moreVC = MoreViewController()
        let moreNav = UINavigationController(rootViewController: moreVC)
        moreNav.navigationBar.prefersLargeTitles = true
        moreNav.tabBarItem = UITabBarItem(
            title: "더보기",
            image: UIImage(systemName: "ellipsis.circle"),
            selectedImage: UIImage(systemName: "ellipsis.circle.fill")
        )

        viewControllers = [homeNav, statsNav, moreNav]
    }

    private func setupAppearance() {
        // Tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        tabBar.tintColor = .systemOrange
        tabBar.unselectedItemTintColor = .systemGray
    }
}
