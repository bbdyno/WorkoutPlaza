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
        
        print("🚀 RunningDetailViewController loaded (Inherited from Base)")
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
    
    override func applyWidgetTemplate(_ template: WidgetTemplate) {
        guard let data = workoutData else { return }

        // Clear existing widgets
        widgets.forEach { $0.removeFromSuperview() }
        routeMapView?.removeFromSuperview()
        widgets.removeAll()
        selectionManager.deselectAll()

        print("📐 Applying template '\(template.name)' version \(template.version)")

        // Get template canvas size
        let templateCanvasSize: CGSize
        if let tCanvasSize = template.canvasSize {
            templateCanvasSize = CGSize(width: tCanvasSize.width, height: tCanvasSize.height)
        } else {
            // For very old templates without canvas size, assume a default
            templateCanvasSize = CGSize(width: 414, height: 700)
        }

        // STEP 1: Change canvas aspect ratio to match template
        let detectedAspectRatio = AspectRatio.detect(from: templateCanvasSize)

        // Update aspect ratio button and canvas size
        currentAspectRatio = detectedAspectRatio
        aspectRatioButton.setTitle(detectedAspectRatio.displayName, for: .normal)
        updateCanvasSize()

        // Force immediate layout update
        view.layoutIfNeeded()

        // STEP 2: Get updated canvas size after aspect ratio change
        let canvasSize = contentView.bounds.size

        // STEP 3: Apply background image aspect ratio if available
        if let aspectRatio = template.backgroundImageAspectRatio {
            // Note: This will be applied when user selects a background image
            // Store it for later use
        }

        // STEP 4: Apply background transform if available
        if let transformData = template.backgroundTransform {
            let transform = BackgroundTransform(
                scale: transformData.scale,
                offset: CGPoint(x: transformData.offsetX, y: transformData.offsetY)
            )
            backgroundTransform = transform
            if !backgroundImageView.isHidden {
                applyBackgroundTransform(transform)
            }
        }

        // STEP 5: Create all widgets in the new canvas
        for item in template.items {
            // Use ratio-based positioning (version 2.0+) or fallback to legacy
            let frame = TemplateManager.absoluteFrame(from: item, canvasSize: canvasSize, templateCanvasSize: templateCanvasSize)

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
                    print("⚠️ No GPS data for location widget in template")
                    break
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

            case .composite:
                break

            case .climbingGym, .climbingDiscipline, .climbingSession, .climbingRoutesByColor:
                break
            }

            if let w = widget {
                contentView.addSubview(w)
                widgets.append(w)
                
                if var selectable = w as? Selectable {
                    selectable.selectionDelegate = self
                    selectionManager.registerItem(selectable)
                }
            }
        }
        
        instructionLabel.text = "위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"
        print("✅ Applied template directly: \(template.name)")
    }
}
