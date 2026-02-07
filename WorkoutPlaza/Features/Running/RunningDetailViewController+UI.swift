//
//  RunningDetailViewController+UI.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

extension RunningDetailViewController {
    
    // MARK: - UI Setup
    
    // Core UI setup is now handled by BaseWorkoutDetailViewController.
    // This extension normally contained setupUI() and subviews layout which are now in Base.
    // We can keep specific overrides here if needed, but for now we'll rely on Base.
    
    // Example: If we wanted to add a specific button only for Running, we'd override setupTopRightToolbar here.
    
    override func setupTopRightToolbar() {
        super.setupTopRightToolbar()
        let importOthersButton = createToolbarButton(systemName: "person.badge.plus", action: #selector(showImportOthersRecordMenu))
        topRightToolbar.addArrangedSubview(importOthersButton)
    }
}
