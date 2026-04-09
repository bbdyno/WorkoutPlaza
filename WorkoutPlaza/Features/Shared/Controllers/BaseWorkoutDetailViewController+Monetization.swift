//
//  BaseWorkoutDetailViewController+Monetization.swift
//  WorkoutPlaza
//
//  Created by Codex on 4/9/26.
//

import UIKit

extension BaseWorkoutDetailViewController {
    func presentProUpgradeSheet(triggerFeature: String) {
        presentProUpgradeFlow(triggerFeature: triggerFeature)
    }

    func beginUsageLimitedFlow(
        for feature: UsageLimitedFeature,
        continueHandler: @escaping () -> Void
    ) {
        guard PurchaseManager.shared.isEffectivelyPro == false else {
            continueHandler()
            return
        }

        let remainingUses = UsageLimitManager.shared.remainingFreeUses(for: feature)
        guard remainingUses > 0 else {
            presentProUpgradeSheet(triggerFeature: feature.triggerFeature)
            return
        }

        let alert = CustomAlertViewController(
            title: feature.trialTitle,
            message: feature.trialMessage(remainingBeforeUse: remainingUses),
            iconName: feature.iconName,
            actions: [
                CustomAlertAction(
                    title: NSLocalizedString("usage.limit.action.continue", comment: ""),
                    iconName: nil,
                    style: .primary,
                    handler: continueHandler
                ),
                CustomAlertAction(
                    title: NSLocalizedString("usage.limit.action.upgrade", comment: ""),
                    iconName: nil,
                    style: .secondary
                ) { [weak self] in
                    self?.presentProUpgradeSheet(triggerFeature: feature.triggerFeature)
                },
                CustomAlertAction(
                    title: NSLocalizedString("common.cancel", comment: ""),
                    iconName: nil,
                    style: .cancel,
                    handler: nil
                )
            ]
        )
        present(alert, animated: true)
    }

    func consumeLimitedUsageIfNeeded(for feature: UsageLimitedFeature) {
        guard PurchaseManager.shared.isEffectivelyPro == false else { return }
        _ = UsageLimitManager.shared.consumeSuccessfulUse(for: feature)
    }
}
