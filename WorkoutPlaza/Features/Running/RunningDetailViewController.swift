//
//  RunningDetailViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit
import PhotosUI
import UniformTypeIdentifiers
import HealthKit

class RunningDetailViewController: BaseWorkoutDetailViewController {

    // MARK: - Properties
    
    // Data
    var workoutData: WorkoutData?
    var importedWorkoutData: ImportedWorkoutData?
    
    var routeMapView: RouteMapView?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        // Base setup (UI, Background, Gestures, MultiSelect, Observers)
        super.viewDidLoad()
        
        // Specific setup
        configureWithWorkoutData()
        
        // Load saved design if exists
        loadSavedDesign()
        
        // Add observer for receiving workout (e.g., via AirDrop)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReceivedWorkoutInDetail(_:)), name: NSNotification.Name("ReceivedWorkoutInDetail"), object: nil)
        
        WPLog.debug("RunningDetailViewController loaded (Inherited from Base)")
    }
    
    // MARK: - Setup UI
    
    override func setupNavigationButtons() {
        super.setupNavigationButtons()
        title = "러닝 기록"
    }
    
    // MARK: - Actions
    
    override func showAddWidgetMenuBase() {
        showAddWidgetMenu() // Call the specific implementation
    }
    
    override func showTemplateMenu() {
        super.showTemplateMenu() // Base implementation or specific override
        // Assuming base has the shared logic, or we specifically implement here if dependent on Running data
        // For now, we'll keep the specific implementation in extension if it relies on Running templates
         let alert = UIAlertController(title: "레이아웃 템플릿", message: "위젯 배치를 선택하세요", preferredStyle: .actionSheet)

        // Get running templates
        let templates = TemplateManager.shared.getTemplates(for: .running)

        for template in templates {
            alert.addAction(UIAlertAction(title: template.name, style: .default) { [weak self] _ in
                self?.applyWidgetTemplate(template)
            })
        }

        // Import template
        alert.addAction(UIAlertAction(title: "📥 템플릿 가져오기", style: .default) { [weak self] _ in
            self?.importTemplate()
        })

        // Export current layout
        alert.addAction(UIAlertAction(title: "📤 현재 레이아웃 내보내기", style: .default) { [weak self] _ in
            self?.exportCurrentLayout()
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = layoutTemplateButton
            popover.sourceRect = layoutTemplateButton.bounds
        }

        present(alert, animated: true)
    }
    
    // Override other actions as needed or rely on Base if generic enough
    override func doneButtonTapped() {
        saveCurrentDesign { [weak self] success in
            if success {
                self?.hasUnsavedChanges = false
                let alert = UIAlertController(title: "저장 완료", message: "카드 디자인이 저장되었습니다.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self?.present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: "저장 실패", message: "디자인을 저장하는 중 오류가 발생했습니다.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    // Logic specific to Running (HealthKit, GPS, etc)
    @objc func handleReceivedWorkoutInDetail(_ notification: Notification) {
         // Handle received workout data
    }
    // MARK: - Template Application

    override func clearCustomWidgets() {
        routeMapView?.removeFromSuperview()
        routeMapView = nil
    }

    override func createWidget(for item: WidgetItem, frame: CGRect) -> UIView? {
        guard let data = workoutData else { return nil }

        var widget: UIView?

        switch item.type {
        case .routeMap:
            let mapView = RouteMapView()
            mapView.setRoute(data.route)
            routeMapView = mapView
            mapView.frame = frame
            mapView.initialSize = frame.size

            if let colorHex = item.color, let color = TemplateManager.color(from: colorHex) {
                mapView.applyColor(color)
            }
            widget = mapView

        case .distance:
            let w = DistanceWidget()
            w.configure(distance: data.distance)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .duration:
            let w = DurationWidget()
            w.configure(duration: data.duration)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .pace:
            let w = PaceWidget()
            w.configure(pace: data.pace)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .speed:
            let w = SpeedWidget()
            w.configure(speed: data.avgSpeed)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .calories:
            let w = CaloriesWidget()
            w.configure(calories: data.calories)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .date:
            let w = DateWidget()
            w.configure(startDate: data.startDate)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .text:
            let w = TextWidget()
            w.configure(text: "텍스트 입력")
            w.textDelegate = self
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .location:
            guard let firstLocation = data.route.first else {
                WPLog.warning("No GPS data for location widget in template")
                return nil
            }

            let w = LocationWidget()
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)

            // Configure asynchronously
            w.configure(location: firstLocation) { success in
                // Completion
            }

            widget = w

        case .currentDateTime:
            let w = CurrentDateTimeWidget()
            w.configure(date: data.startDate)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .composite, .climbingGym, .climbingDiscipline, .climbingSession, .climbingRoutesByColor, .gymLogo:
            return nil
        }

        return widget
    }

    // MARK: - Widget Restoration

    override func getWorkoutDate() -> Date? {
        if let data = workoutData {
            return data.startDate
        } else if let imported = importedWorkoutData {
            return imported.originalData.startDate
        }
        return nil
    }

    override func createWidgetFromSavedState(_ savedWidget: SavedWidgetState) -> UIView? {
        // Try base implementation first
        if let widget = super.createWidgetFromSavedState(savedWidget) {
            return widget
        }

        // Handle Running-specific widgets
        let widgetType = savedWidget.type

        switch widgetType {
        case "LocationWidget":
            let widget = LocationWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            if let locationText = savedWidget.additionalText {
                widget.configure(withText: locationText)
            }
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        case "DistanceWidget":
            guard let data = workoutData else { return nil }
            let widget = DistanceWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            widget.configure(distance: data.distance)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        case "DurationWidget":
            guard let data = workoutData else { return nil }
            let widget = DurationWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            widget.configure(duration: data.duration)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        case "PaceWidget":
            guard let data = workoutData else { return nil }
            let widget = PaceWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            widget.configure(pace: data.pace)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        case "SpeedWidget":
            guard let data = workoutData else { return nil }
            let widget = SpeedWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            widget.configure(speed: data.avgSpeed)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        case "CaloriesWidget":
            guard let data = workoutData else { return nil }
            let widget = CaloriesWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            widget.configure(calories: data.calories)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        default:
            return nil
        }
    }
}
