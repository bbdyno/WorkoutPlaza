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
        title = WorkoutPlazaStrings.Running.Record.title
    }

    // MARK: - Actions
    
    override func getToolSheetItems() -> (templates: [ToolSheetItem], widgets: [ToolSheetItem], templateActions: [ToolSheetHeaderAction]) {
        // Templates
        var templateItems: [ToolSheetItem] = []

        let builtInTemplates = WidgetTemplate.runningTemplates
        for template in builtInTemplates {
            let compatible = template.isCompatible
            templateItems.append(ToolSheetItem(
                title: template.name,
                description: compatible ? template.description : WorkoutPlazaStrings.Template.Update.required,
                iconName: "rectangle.3.group",
                isEnabled: compatible,
                previewProvider: template.thumbnailProvider(widgetFactory: { [weak self] item, frame in
                    self?.createWidget(for: item, frame: frame)
                }),
                action: { [weak self] in
                    self?.showTemplatePreview(template)
                }
            ))
        }

        // Import / Export as header actions
        let templateActions: [ToolSheetHeaderAction] = [
            ToolSheetHeaderAction(title: WorkoutPlazaStrings.Import.action, iconName: "square.and.arrow.down") { [weak self] in
                self?.importTemplate()
            },
            ToolSheetHeaderAction(title: WorkoutPlazaStrings.Import.Export.action, iconName: "square.and.arrow.up") { [weak self] in
                self?.exportCurrentLayout()
            }
        ]

        // Widgets
        var widgetItems: [ToolSheetItem] = []
        let hasData = workoutData != nil || importedWorkoutData != nil || externalWorkout != nil
        let hasRoute = workoutData?.hasRoute ?? importedWorkoutData?.hasRoute ?? (externalWorkout?.workoutData.route.isEmpty == false)

        for type in SingleWidgetType.allCases {
            let added = !canAddWidget(type)
            let enabled: Bool
            if !hasData {
                enabled = false
            } else if (type == .routeMap || type == .location) && !hasRoute {
                enabled = false
            } else {
                enabled = !added
            }

            let widgetType: WidgetType
            switch type {
            case .routeMap: widgetType = .routeMap
            case .distance: widgetType = .distance
            case .duration: widgetType = .duration
            case .pace: widgetType = .pace
            case .speed: widgetType = .speed
            case .calories: widgetType = .calories
            case .heartRate: widgetType = .heartRate
            case .date: widgetType = .date
            case .currentDateTime: widgetType = .currentDateTime
            case .text: widgetType = .text
            case .location: widgetType = .location
            }

            widgetItems.append(ToolSheetItem(
                title: widgetType.displayName,
                description: type.displayName,
                iconName: widgetType.iconName,
                isEnabled: enabled,
                isAdded: added,
                previewProvider: widgetType.previewProvider,
                action: { [weak self] in
                    self?.addSingleWidgetFromAvailableData(type)
                }
            ))
        }

        return (templateItems, widgetItems, templateActions)
    }

    // Override other actions as needed or rely on Base if generic enough
    override func doneButtonTapped() {
        saveCurrentDesign { [weak self] success in
            if success {
                self?.hasUnsavedChanges = false
                let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.Save.completed, message: WorkoutPlazaStrings.Alert.Card.Design.saved, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
                self?.present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.Save.failed, message: WorkoutPlazaStrings.Alert.Card.Design.Save.error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
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
        let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.share, message: WorkoutPlazaStrings.Alert.Select.Share.method, preferredStyle: .actionSheet)

        // Share as image
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Share.As.image, style: .default) { [weak self] _ in
            self?.shareAsImage()
        })

        // Share as wplaza file (only if we have HealthKit data)
        if workoutData != nil {
            alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Share.Workout.data, style: .default) { [weak self] _ in
                self?.shareAsWplazaFile(creatorName: nil)
            })

            alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Share.With.name, style: .default) { [weak self] _ in
                self?.showCreatorNameInputForShare()
            })
        }

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Button.cancel, style: .cancel))

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
                title: WorkoutPlazaStrings.Share.failed,
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
            present(alert, animated: true)
        }
    }

    private func showCreatorNameInputForShare() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Share.Name.Input.title,
            message: WorkoutPlazaStrings.Share.Name.Input.message,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = WorkoutPlazaStrings.Share.Name.placeholder
        }

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Alert.share, style: .default) { [weak self, weak alert] _ in
            let name = alert?.textFields?.first?.text
            self?.shareAsWplazaFile(creatorName: name)
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        present(alert, animated: true)
    }

    // Logic specific to Running (HealthKit, GPS, etc)
    @objc func handleReceivedWorkoutInDetail(_ notification: Notification) {
        guard let shareableWorkout = notification.userInfo?["workout"] as? ShareableWorkout else { return }
        showImportOptionsSheet(for: shareableWorkout)
    }

    @objc func showImportOthersRecordMenu() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.init(filenameExtension: "wplaza")!])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func showImportOptionsSheet(for shareableWorkout: ShareableWorkout) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Import.Record.title,
            message: WorkoutPlazaStrings.Import.Record.message,
            preferredStyle: .actionSheet
        )

        // Option 1: Import as my record (clear existing content)
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Import.As.My.record, style: .default) { [weak self] _ in
            self?.importAsMyRecord(shareableWorkout)
        })

        // Option 2: Attach to current layout (as other's record)
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Import.As.Other.record, style: .default) { [weak self] _ in
            self?.showImportFieldSelectionSheet(for: shareableWorkout)
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

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
            w.configure(text: WorkoutPlazaStrings.Text.Input.placeholder)
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
        // Restore display mode (text/icon)
        if let statWidget = widget as? BaseStatWidget,
           let modeRaw = savedState.displayMode,
           let mode = WidgetDisplayMode(rawValue: modeRaw) {
            statWidget.setDisplayMode(mode)
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
            title: WorkoutPlazaStrings.Import.File.failed,
            message: WorkoutPlazaStrings.Import.File.Failed.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }
}
