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
            image: UIImage(named: "icon.tab.home"),
            selectedImage: UIImage(named: "icon.tab.home.fill")
        )

        // Tab 2: Statistics (통계)
        let statsVC = StatisticsViewController()
        let statsNav = UINavigationController(rootViewController: statsVC)
        statsNav.navigationBar.prefersLargeTitles = true
        statsNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.statistics", comment: ""),
            image: UIImage(named: "icon.tab.stats"),
            selectedImage: UIImage(named: "icon.tab.stats.fill")
        )

        // Tab 3: More (더보기)
        let moreVC = MoreViewController()
        let moreNav = UINavigationController(rootViewController: moreVC)
        moreNav.navigationBar.prefersLargeTitles = true
        moreNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.more", comment: ""),
            image: UIImage(named: "icon.tab.more"),
            selectedImage: UIImage(named: "icon.tab.more.fill")
        )

        viewControllers = [homeNav, statsNav, moreNav]
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = ColorSystem.background.withAlphaComponent(0.84)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        appearance.shadowColor = .clear

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = [
            .font: AppFont.micro(10),
            .foregroundColor: ColorSystem.subText
        ]
        itemAppearance.selected.titleTextAttributes = [
            .font: AppFont.bodyBold(10),
            .foregroundColor: ColorSystem.primaryBlue
        ]
        itemAppearance.normal.iconColor = ColorSystem.subText
        itemAppearance.selected.iconColor = ColorSystem.primaryBlue
        appearance.stackedLayoutAppearance = itemAppearance

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        tabBar.tintColor = ColorSystem.primaryBlue
        tabBar.unselectedItemTintColor = ColorSystem.subText
        tabBar.layer.cornerRadius = 24
        tabBar.layer.cornerCurve = .continuous
        tabBar.layer.masksToBounds = true
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
