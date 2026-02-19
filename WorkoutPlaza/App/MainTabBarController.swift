//
//  MainTabBarController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/23/26.
//

import UIKit

class MainTabBarController: UITabBarController {
    var suppressInitialWalkthrough = false

    private var hasEvaluatedInitialWalkthrough = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentInitialWalkthroughIfNeeded()
    }

    // MARK: - Setup

    private func setupTabs() {
        // Tab 1: Home (대시보드)
        let homeVC = HomeDashboardViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.navigationBar.prefersLargeTitles = true
        homeNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.home", comment: ""),
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // Tab 2: Statistics (통계)
        let statsVC = StatisticsViewController()
        let statsNav = UINavigationController(rootViewController: statsVC)
        statsNav.navigationBar.prefersLargeTitles = true
        statsNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.statistics", comment: ""),
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )

        // Tab 3: More (더보기)
        let moreVC = MoreViewController()
        let moreNav = UINavigationController(rootViewController: moreVC)
        moreNav.navigationBar.prefersLargeTitles = true
        moreNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.more", comment: ""),
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

        tabBar.tintColor = ColorSystem.primaryBlue
        tabBar.unselectedItemTintColor = ColorSystem.subText
    }

    private func presentInitialWalkthroughIfNeeded() {
        guard hasEvaluatedInitialWalkthrough == false else { return }

        if suppressInitialWalkthrough {
            hasEvaluatedInitialWalkthrough = true
            return
        }

        guard WalkthroughManager.shouldPresentOnLaunch else {
            hasEvaluatedInitialWalkthrough = true
            return
        }

        guard presentedViewController == nil else { return }

        hasEvaluatedInitialWalkthrough = true
        presentWalkthrough(force: true)
    }

    func presentWalkthrough(force: Bool = false) {
        guard force || WalkthroughManager.shouldPresentOnLaunch else { return }
        guard presentedViewController == nil else { return }

        let walkthroughVC = WalkthroughViewController()
        walkthroughVC.modalPresentationStyle = .fullScreen
        walkthroughVC.onFinish = { [weak walkthroughVC] in
            WalkthroughManager.markCompleted()
            walkthroughVC?.dismiss(animated: true)
        }

        present(walkthroughVC, animated: true)
    }
}
