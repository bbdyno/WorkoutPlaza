//
//  RunningDetailViewController+Actions.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

extension RunningDetailViewController {
    
    // MARK: - Layout Actions
    
    @objc internal func resetLayout() {
        // 원래 위치로 리셋
        guard workoutData != nil || importedWorkoutData != nil || externalWorkout != nil else { return }
        
        // 모든 위젯 제거
        widgets.forEach { $0.removeFromSuperview() }
        routeMapView?.removeFromSuperview()
        widgets.removeAll()
        selectionManager.deselectAll()
        
        // 다시 생성
        configureWithWorkoutData()
        
        // 스크롤을 최상단으로
        scrollView.setContentOffset(.zero, animated: true)
        
        // Force update canvas size
        updateCanvasSize()
        
        showToast(WorkoutPlazaStrings.Toast.Layout.reset)
    }
}
