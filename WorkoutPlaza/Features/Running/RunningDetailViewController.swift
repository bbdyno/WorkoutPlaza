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
import CoreLocation

class RunningDetailViewController: BaseWorkoutDetailViewController {

    // MARK: - Properties

    struct RunningWidgetDataSource {
        let distance: Double
        let duration: TimeInterval
        let pace: Double
        let avgSpeed: Double
        let calories: Double
        let avgHeartRate: Double
        let startDate: Date
        let routeLocations: [CLLocation]

        static func from(workoutData: WorkoutData) -> RunningWidgetDataSource {
            RunningWidgetDataSource(
                distance: workoutData.distance,
                duration: workoutData.duration,
                pace: workoutData.pace,
                avgSpeed: workoutData.avgSpeed,
                calories: workoutData.calories,
                avgHeartRate: workoutData.avgHeartRate,
                startDate: workoutData.startDate,
                routeLocations: workoutData.route
            )
        }

        static func from(importedData: ImportedWorkoutData) -> RunningWidgetDataSource {
            let data = importedData.originalData
            return RunningWidgetDataSource(
                distance: data.distance,
                duration: data.duration,
                pace: data.pace,
                avgSpeed: data.avgSpeed,
                calories: data.calories,
                avgHeartRate: data.avgHeartRate ?? 0,
                startDate: data.startDate,
                routeLocations: importedData.routeLocations
            )
        }

        static func from(externalWorkout: ExternalWorkout) -> RunningWidgetDataSource {
            let data = externalWorkout.workoutData
            let routeLocations = data.route.map { point in
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon),
                    altitude: point.alt ?? 0,
                    horizontalAccuracy: 10,
                    verticalAccuracy: 10,
                    timestamp: point.timestamp ?? Date()
                )
            }

            return RunningWidgetDataSource(
                distance: data.distance,
                duration: data.duration,
                pace: data.pace,
                avgSpeed: data.avgSpeed,
                calories: data.calories,
                avgHeartRate: data.avgHeartRate ?? 0,
                startDate: data.startDate,
                routeLocations: routeLocations
            )
        }
    }

    // Data
    var workoutData: WorkoutData?
    var importedWorkoutData: ImportedWorkoutData?
    var externalWorkout: ExternalWorkout?

    var routeMapView: RouteMapView?
    var availableTemplates: [WidgetTemplate] = WidgetTemplate.runningTemplates

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        // Base setup (UI, Background, Gestures, MultiSelect, Observers)
        super.viewDidLoad()
        
        // Specific setup
        configureWithWorkoutData()
        refreshTemplateLibrary()
        
        // Load saved design if exists
        loadSavedDesign()
        
        // Add observer for receiving workout (e.g., via AirDrop)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReceivedWorkoutInDetail(_:)), name: NSNotification.Name("ReceivedWorkoutInDetail"), object: nil)
        
        WPLog.debug("RunningDetailViewController loaded (Inherited from Base)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTemplateLibrary()
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

        for template in availableTemplates {
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

        // Market / Import / Export as header actions
        var templateActions: [ToolSheetHeaderAction] = []

        let marketConfig = FeaturePackManager.shared.templateMarketButtonConfig()
        if marketConfig.isEnabled {
            templateActions.append(
                ToolSheetHeaderAction(title: marketConfig.title, iconName: "storefront") { [weak self] in
                    self?.showTemplateMarket()
                }
            )
        }

        templateActions.append(
            ToolSheetHeaderAction(title: WorkoutPlazaStrings.Import.action, iconName: "square.and.arrow.down") { [weak self] in
                self?.importTemplate()
            }
        )

        templateActions.append(
            ToolSheetHeaderAction(title: WorkoutPlazaStrings.Import.Export.action, iconName: "square.and.arrow.up") { [weak self] in
                self?.exportCurrentLayout()
            }
        )

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
            case .composite: widgetType = .composite
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

    override func refreshTemplateLibrary() {
        Task {
            let templates = await TemplateManager.shared.getTemplates(for: .running)
            await MainActor.run {
                self.availableTemplates = templates
            }
        }
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

    private func resolveCurrentWidgetDataSource() -> RunningWidgetDataSource? {
        if let workoutData {
            return .from(workoutData: workoutData)
        }
        if let importedWorkoutData {
            return .from(importedData: importedWorkoutData)
        }
        if let externalWorkout {
            return .from(externalWorkout: externalWorkout)
        }
        return nil
    }

    private func makeCompositePayload(from source: RunningWidgetDataSource) -> CompositeWidgetPayload {
        CompositeWidgetPayload(
            title: WorkoutPlazaStrings.Widget.composite,
            primaryText: "\(WorkoutFormatter.formatDistance(source.distance)) km",
            secondaryText: WorkoutFormatter.formatDuration(source.duration)
        )
    }

    override func createWidget(for item: WidgetItem, frame: CGRect) -> UIView? {
        guard let source = resolveCurrentWidgetDataSource() else { return nil }
        return createWidget(for: item, frame: frame, source: source)
    }

    func createWidget(for item: WidgetItem, frame: CGRect, source: RunningWidgetDataSource) -> UIView? {
        var widget: UIView?

        switch item.type {
        case .routeMap:
            let mapView = RouteMapView()
            mapView.setRoute(source.routeLocations)
            routeMapView = mapView
            mapView.frame = frame
            mapView.initialSize = frame.size

            if let colorHex = item.color, let color = TemplateManager.color(from: colorHex) {
                mapView.applyColor(color)
            }
            widget = mapView

        case .distance:
            let w = DistanceWidget()
            w.configure(distance: source.distance)
            let normalizedSize = WidgetSizeNormalizer.normalizeRunningCompactStatSize(frame.size, widgetType: .distance)
            w.frame = CGRect(origin: frame.origin, size: normalizedSize)
            w.initialSize = normalizedSize
            applyItemStyles(to: w, item: item)
            widget = w

        case .duration:
            let w = DurationWidget()
            w.configure(duration: source.duration)
            let normalizedSize = WidgetSizeNormalizer.normalizeRunningCompactStatSize(frame.size, widgetType: .duration)
            w.frame = CGRect(origin: frame.origin, size: normalizedSize)
            w.initialSize = normalizedSize
            applyItemStyles(to: w, item: item)
            widget = w

        case .pace:
            let w = PaceWidget()
            w.configure(pace: source.pace)
            let normalizedSize = WidgetSizeNormalizer.normalizeRunningCompactStatSize(frame.size, widgetType: .pace)
            w.frame = CGRect(origin: frame.origin, size: normalizedSize)
            w.initialSize = normalizedSize
            applyItemStyles(to: w, item: item)
            widget = w

        case .speed:
            let w = SpeedWidget()
            w.configure(speed: source.avgSpeed)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .calories:
            let w = CaloriesWidget()
            w.configure(calories: source.calories)
            let normalizedSize = WidgetSizeNormalizer.normalizeRunningCompactStatSize(frame.size, widgetType: .calories)
            w.frame = CGRect(origin: frame.origin, size: normalizedSize)
            w.initialSize = normalizedSize
            applyItemStyles(to: w, item: item)
            widget = w

        case .heartRate:
            let w = HeartRateWidget()
            w.configure(heartRate: source.avgHeartRate)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .date:
            let w = DateWidget()
            w.configure(startDate: source.startDate)
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
            guard let firstLocation = source.routeLocations.first else {
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
            w.configure(date: source.startDate)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .composite:
            let w = CompositeWidget()
            if let payload = CompositeWidget.payload(from: item.payload) {
                w.configure(payload: payload)
            } else {
                w.configure(payload: makeCompositePayload(from: source))
            }
            w.compositeDelegate = self
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .climbingGym, .climbingDiscipline, .climbingSession, .climbingRoutesByColor, .gymLogo:
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

    override func getSportType() -> SportType {
        return .running
    }

    private func applyWidgetStyles(to widget: UIView, from savedState: SavedWidgetState) {
        if let selectable = widget as? Selectable {
            if let colorHex = savedState.textColor, let color = UIColor(hex: colorHex) {
                selectable.applyColor(color)
            }
            if let fontStyleRaw = savedState.fontStyle, let fontStyle = FontStyle(rawValue: fontStyleRaw) {
                selectable.applyFont(fontStyle)
            }
            if let alignmentRaw = savedState.contentAlignment,
               let alignment = WidgetContentAlignment(rawValue: alignmentRaw),
               let alignableWidget = widget as? WidgetContentAlignable {
                alignableWidget.applyContentAlignment(alignment)
            }
        }
        // Restore display mode (text/icon)
        if let statWidget = widget as? BaseStatWidget,
           let modeRaw = savedState.displayMode,
           let mode = WidgetDisplayMode(rawValue: modeRaw) {
            statWidget.setDisplayMode(mode)
        }
    }

    override func frameForRestoredWidget(_ savedState: SavedWidgetState, widget: UIView) -> CGRect {
        let scaledBaseFrame = super.frameForRestoredWidget(savedState, widget: widget)
        let widgetType: WidgetType?
        if let definitionID = WidgetIdentity.definitionID(for: widget) {
            widgetType = WidgetIdentity.widgetType(for: definitionID)
        } else if let definitionID = WidgetIdentity.resolvedDefinitionID(from: savedState) {
            widgetType = WidgetIdentity.widgetType(for: definitionID)
        } else {
            widgetType = nil
        }

        guard let widgetType else {
            return scaledBaseFrame
        }

        let isLegacySavedWidget = savedState.definitionID == nil
        let normalizedSize = WidgetSizeNormalizer.normalizeRestoredRunningStatSize(
            scaledBaseFrame.size,
            widgetType: widgetType,
            forceLegacyMigration: isLegacySavedWidget,
            canvasScale: restoreCanvasUniformScale()
        )
        return CGRect(origin: scaledBaseFrame.origin, size: normalizedSize)
    }

    override func createWidgetFromSavedState(_ savedWidget: SavedWidgetState) -> UIView? {
        // Try base implementation first
        if let widget = super.createWidgetFromSavedState(savedWidget) {
            return widget
        }

        // Handle Running-specific widgets
        guard let source = resolveCurrentWidgetDataSource(),
              let definitionID = WidgetIdentity.resolvedDefinitionID(from: savedWidget) else {
            return nil
        }
        let widget: UIView?

        switch definitionID {
        case .routeMap:
            let w = RouteMapView()
            w.setRoute(source.routeLocations)
            routeMapView = w
            widget = w

        case .location:
            let w = LocationWidget()
            if let locationText = savedWidget.additionalText {
                w.configure(withText: locationText)
            } else if let firstLocation = source.routeLocations.first {
                w.configure(location: firstLocation) { _ in }
            }
            widget = w

        case .distance:
            let w = DistanceWidget()
            w.configure(distance: source.distance)
            widget = w

        case .duration:
            let w = DurationWidget()
            w.configure(duration: source.duration)
            widget = w

        case .pace:
            let w = PaceWidget()
            w.configure(pace: source.pace)
            widget = w

        case .speed:
            let w = SpeedWidget()
            w.configure(speed: source.avgSpeed)
            widget = w

        case .calories:
            let w = CaloriesWidget()
            w.configure(calories: source.calories)
            widget = w

        case .heartRate:
            let w = HeartRateWidget()
            w.configure(heartRate: source.avgHeartRate)
            widget = w

        default:
            return nil
        }

        // Apply common properties
        if let widget = widget {
            let restoredFrame = frameForRestoredWidget(savedWidget, widget: widget)
            widget.frame = restoredFrame
            if let selectable = widget as? Selectable {
                selectable.initialSize = resolvedRestoredInitialSize(
                    savedWidget,
                    widget: widget,
                    restoredFrame: restoredFrame
                )
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
