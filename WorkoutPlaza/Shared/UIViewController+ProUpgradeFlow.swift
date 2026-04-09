//
//  UIViewController+ProUpgradeFlow.swift
//  WorkoutPlaza
//
//  Created by Codex on 4/9/26.
//

import UIKit

extension UIViewController {
    func presentProUpgradeFlow(triggerFeature: String?) {
        let proVC = ProUpgradeViewController()
        proVC.triggerFeature = triggerFeature

        let nav = UINavigationController(rootViewController: proVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        present(nav, animated: true)
    }
}
