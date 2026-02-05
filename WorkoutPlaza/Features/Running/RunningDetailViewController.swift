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
    var externalWorkout: ExternalWorkout?

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

        // Add import button to navigation bar
        let importButton = UIBarButtonItem(
            image: UIImage(systemName: "person.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(showImportOthersRecordMenu)
        )
        navigationItem.rightBarButtonItems = [
            navigationItem.rightBarButtonItem!,
            importButton
        ]
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

        Task {
            // Get running templates
            let templates = await TemplateManager.shared.getTemplates(for: .running)

            await MainActor.run {
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
        }
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
    
    // MARK: - Share Options

    override func shareImage() {
        // Check if we have data to share as wplaza file
        let canShareAsFile = workoutData != nil || externalWorkout != nil

        if canShareAsFile {
            showShareOptionsSheet()
        } else {
            // No workout data - just share the image
            super.shareImage()
        }
    }

    private func showShareOptionsSheet() {
        let alert = UIAlertController(title: "공유", message: "공유 방식을 선택하세요", preferredStyle: .actionSheet)

        // Share as image
        alert.addAction(UIAlertAction(title: "이미지로 공유", style: .default) { [weak self] _ in
            self?.shareAsImage()
        })

        // Share as wplaza file (only if we have HealthKit data)
        if workoutData != nil {
            alert.addAction(UIAlertAction(title: "운동 데이터 공유 (.wplaza)", style: .default) { [weak self] _ in
                self?.shareAsWplazaFile(creatorName: nil)
            })

            alert.addAction(UIAlertAction(title: "이름과 함께 공유 (.wplaza)", style: .default) { [weak self] _ in
                self?.showCreatorNameInputForShare()
            })
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = shareImageButton
            popover.sourceRect = shareImageButton.bounds
        }

        present(alert, animated: true)
    }

    private func shareAsImage() {
        selectionManager.deselectAll()
        instructionLabel.isHidden = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            if let image = self.captureContentView() {
                self.presentShareSheet(image: image)
            }

            self.instructionLabel.isHidden = false
        }
    }

    private func shareAsWplazaFile(creatorName: String?) {
        guard let data = workoutData else { return }

        do {
            let fileURL = try ShareManager.shared.exportWorkout(data, creatorName: creatorName)
            ShareManager.shared.presentShareSheet(for: fileURL, from: self, sourceView: shareImageButton)
        } catch {
            let alert = UIAlertController(
                title: "공유 실패",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }

    private func showCreatorNameInputForShare() {
        let alert = UIAlertController(
            title: "이름 입력",
            message: "공유할 때 표시될 이름을 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "이름"
        }

        alert.addAction(UIAlertAction(title: "공유", style: .default) { [weak self, weak alert] _ in
            let name = alert?.textFields?.first?.text
            self?.shareAsWplazaFile(creatorName: name)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    // Logic specific to Running (HealthKit, GPS, etc)
    @objc func handleReceivedWorkoutInDetail(_ notification: Notification) {
        guard let shareableWorkout = notification.userInfo?["workout"] as? ShareableWorkout else { return }
        showImportOptionsSheet(for: shareableWorkout)
    }

    @objc private func showImportOthersRecordMenu() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.init(filenameExtension: "wplaza")!])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func showImportOptionsSheet(for shareableWorkout: ShareableWorkout) {
        let alert = UIAlertController(
            title: "기록 가져오기",
            message: "이 기록을 어떻게 가져올까요?",
            preferredStyle: .actionSheet
        )

        // Option 1: Import as my record (clear existing content)
        alert.addAction(UIAlertAction(title: "내 기록으로 가져오기", style: .default) { [weak self] _ in
            self?.importAsMyRecord(shareableWorkout)
        })

        // Option 2: Attach to current layout (as other's record)
        alert.addAction(UIAlertAction(title: "타인 기록으로 추가", style: .default) { [weak self] _ in
            self?.showImportFieldSelectionSheet(for: shareableWorkout)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
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

        case .heartRate:
            let w = HeartRateWidget()
            w.configure(heartRate: data.avgHeartRate)
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

    private func applyWidgetStyles(to widget: UIView, from savedState: SavedWidgetState) {
        if let selectable = widget as? Selectable {
            if let colorHex = savedState.textColor, let color = UIColor(hex: colorHex) {
                selectable.applyColor(color)
            }
            if let fontStyleRaw = savedState.fontStyle, let fontStyle = FontStyle(rawValue: fontStyleRaw) {
                selectable.applyFont(fontStyle)
            }
        }
    }

    override func createWidgetFromSavedState(_ savedWidget: SavedWidgetState) -> UIView? {
        // Try base implementation first
        if let widget = super.createWidgetFromSavedState(savedWidget) {
            return widget
        }

        // Handle Running-specific widgets
        // Get data from workoutData, importedWorkoutData, or externalWorkout
        let distance: Double
        let duration: TimeInterval
        let pace: Double
        let avgSpeed: Double
        let calories: Double
        let avgHeartRate: Double

        if let data = workoutData {
            distance = data.distance
            duration = data.duration
            pace = data.pace
            avgSpeed = data.avgSpeed
            calories = data.calories
            avgHeartRate = data.avgHeartRate
        } else if let imported = importedWorkoutData {
            distance = imported.originalData.distance
            duration = imported.originalData.duration
            pace = imported.originalData.pace
            avgSpeed = imported.originalData.avgSpeed
            calories = imported.originalData.calories
            avgHeartRate = imported.originalData.avgHeartRate ?? 0
        } else if let external = externalWorkout {
            distance = external.workoutData.distance
            duration = external.workoutData.duration
            pace = external.workoutData.pace
            avgSpeed = external.workoutData.avgSpeed
            calories = external.workoutData.calories
            avgHeartRate = external.workoutData.avgHeartRate ?? 0
        } else {
            return nil
        }

        let widgetType = savedWidget.type
        let widget: UIView?

        switch widgetType {
        case "LocationWidget":
            let w = LocationWidget()
            if let locationText = savedWidget.additionalText {
                w.configure(withText: locationText)
            }
            widget = w

        case "DistanceWidget":
            let w = DistanceWidget()
            w.configure(distance: distance)
            widget = w

        case "DurationWidget":
            let w = DurationWidget()
            w.configure(duration: duration)
            widget = w

        case "PaceWidget":
            let w = PaceWidget()
            w.configure(pace: pace)
            widget = w

        case "SpeedWidget":
            let w = SpeedWidget()
            w.configure(speed: avgSpeed)
            widget = w

        case "CaloriesWidget":
            let w = CaloriesWidget()
            w.configure(calories: calories)
            widget = w

        case "HeartRateWidget":
            let w = HeartRateWidget()
            w.configure(heartRate: avgHeartRate)
            widget = w

        default:
            return nil
        }

        // Apply common properties
        if let widget = widget {
            widget.frame = savedWidget.frame
            if var selectable = widget as? Selectable {
                selectable.initialSize = savedWidget.frame.size
            }
            applyWidgetStyles(to: widget, from: savedWidget)
        }

        return widget
    }
}

// MARK: - UIDocumentPickerDelegate
extension RunningDetailViewController {
    override func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        // Request access to security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            WPLog.error("Failed to access security-scoped resource")
            showFileLoadError()
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let shareableWorkout = try decoder.decode(ShareableWorkout.self, from: data)

            WPLog.info("Successfully loaded workout from file: \(url.lastPathComponent)")
            showImportOptionsSheet(for: shareableWorkout)
        } catch {
            WPLog.error("Failed to load workout file: \(error)")
            showFileLoadError()
        }
    }

    private func showFileLoadError() {
        let alert = UIAlertController(
            title: "파일 불러오기 실패",
            message: "선택한 파일을 불러올 수 없습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
