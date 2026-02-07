//
//  ClimbingDetailViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit
import SnapKit
import PhotosUI
import UniformTypeIdentifiers

class ClimbingDetailViewController: BaseWorkoutDetailViewController {

    // MARK: - Properties

    // Data
    var climbingData: ClimbingData?

    // Track date widgets for updating
    private var dateWidgets: [DateWidget] = []
    private var currentDateTimeWidgets: [CurrentDateTimeWidget] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Specific setup
        configureWithClimbingData()
        
        // Load saved design if exists
        loadSavedDesign()
        
        WPLog.debug("ClimbingDetailViewController loaded (Inherited from Base)")
    }
    
    // MARK: - UI Setup
    
    override func setupNavigationButtons() {
        super.setupNavigationButtons()
        title = "클라이밍 기록"
    }
    
    // MARK: - Configuration
    
    func configureWithClimbingData() {
        guard let data = climbingData else { return }

        // Background color based on gym or discipline if needed
        // For now, use default

        // Always create widgets first - loadSavedDesign() will restore their positions if saved design exists
        createDefaultWidgets(for: data)
    }
    
    func createDefaultWidgets(for data: ClimbingData) {
        let widgetSize = CGSize(width: 80, height: 80) // Small icon style for climbing? Or stick to standard
        // Climbing widgets might need different default sizes
        
        let gymWidget = ClimbingGymWidget()
        gymWidget.configure(gymName: data.gymName)
        addWidget(gymWidget, size: gymWidget.idealSize, position: CGPoint(x: 30, y: 100))
        
        let sessionWidget = ClimbingSessionWidget()
        sessionWidget.configure(sent: data.sentRoutes, total: data.totalRoutes)
        addWidget(sessionWidget, size: sessionWidget.idealSize, position: CGPoint(x: 30, y: 180))
        
        // Add more defaults...
    }
    
    // MARK: - Actions
    
    override func getToolSheetItems() -> (templates: [ToolSheetItem], widgets: [ToolSheetItem], templateActions: [ToolSheetHeaderAction]) {
        // Templates
        var templateItems: [ToolSheetItem] = []

        let builtInTemplates = WidgetTemplate.climbingTemplates
        for template in builtInTemplates {
            let compatible = template.isCompatible
            templateItems.append(ToolSheetItem(
                title: template.name,
                description: compatible ? template.description : "업데이트 필요",
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
            ToolSheetHeaderAction(title: "가져오기", iconName: "square.and.arrow.down") { [weak self] in
                self?.importTemplate()
            },
            ToolSheetHeaderAction(title: "내보내기", iconName: "square.and.arrow.up") { [weak self] in
                self?.exportCurrentLayout()
            }
        ]

        // Widgets
        var widgetItems: [ToolSheetItem] = []

        let climbingWidgets: [(String, WidgetType)] = [
            ("클라이밍짐", .climbingGym),
            ("암장 로고", .gymLogo),
            ("종목", .climbingDiscipline),
            ("세션 기록", .climbingSession),
            ("완등 현황", .climbingRoutesByColor),
            ("텍스트", .text),
            ("날짜", .date)
        ]

        for (name, type) in climbingWidgets {
            let added = !canAddWidget(type)

            widgetItems.append(ToolSheetItem(
                title: type.displayName,
                description: name,
                iconName: type.iconName,
                isEnabled: !added,
                isAdded: added,
                previewProvider: type.previewProvider,
                action: { [weak self] in
                    self?.addNewWidget(type: type)
                }
            ))
        }

        return (templateItems, widgetItems, templateActions)
    }

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
    
    // MARK: - Widget Management

    private func canAddWidget(_ type: WidgetType) -> Bool {
        switch type {
        case .climbingGym:
            return !widgets.contains(where: { $0 is ClimbingGymWidget })
        case .gymLogo:
            return !widgets.contains(where: { $0 is GymLogoWidget })
        case .climbingDiscipline:
            return !widgets.contains(where: { $0 is ClimbingDisciplineWidget })
        case .climbingSession:
            return !widgets.contains(where: { $0 is ClimbingSessionWidget })
        case .climbingRoutesByColor:
            return !widgets.contains(where: { $0 is ClimbingRoutesByColorWidget })
        case .date:
            return !widgets.contains(where: { $0 is DateWidget })
        case .currentDateTime:
            return !widgets.contains(where: { $0 is CurrentDateTimeWidget })
        case .text:
            return true  // Multiple text widgets allowed
        default:
            return true
        }
    }

    @objc private func showAddWidgetMenu() {
        let actionSheet = UIAlertController(title: "위젯 추가", message: nil, preferredStyle: .actionSheet)

        let climbingWidgets: [(String, WidgetType)] = [
            ("클라이밍짐", .climbingGym),
            ("암장 로고", .gymLogo),
            ("종목", .climbingDiscipline),
            ("세션 기록", .climbingSession),
            ("완등 현황", .climbingRoutesByColor),
            ("텍스트", .text),
            ("날짜", .date)
        ]

        for (name, type) in climbingWidgets {
            let isAdded = !canAddWidget(type)
            var title = name

            if isAdded {
                title = "✓ \(name)"
            }

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.addNewWidget(type: type)
            }

            action.isEnabled = !isAdded
            actionSheet.addAction(action)
        }

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = addWidgetButton
            popover.sourceRect = addWidgetButton.bounds
        }

        present(actionSheet, animated: true)
    }

    private func addNewWidget(type: WidgetType) {
        guard let data = climbingData else { return }

        let canvasWidth: CGFloat = 360  // 캔버스 고정 크기
        let canvasHeight = canvasWidth * currentAspectRatio.ratio
        let widgetSize = CGSize(width: 160, height: 80)
        let centerX = (canvasWidth - widgetSize.width) / 2
        let centerY = (canvasHeight - widgetSize.height) / 2

        var widget: UIView?

        switch type {
        case .climbingGym:
            let w = ClimbingGymWidget()
            w.configure(gymName: data.gymName)
            let gymSize = w.idealSize
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: gymSize)
            w.initialSize = gymSize
            widget = w

        case .gymLogo:
            let w = GymLogoWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)

            // Try to find the gym object to get logo and metadata
            WPLog.debug("🏢 Looking for gym with name: '\(data.gymName)'")

            // 1. Try exact match via manager (covers presets and custom saved)
            var gym = ClimbingGymManager.shared.findGym(byName: data.gymName)

            // 2. If not found, try searching ALL gyms including remote config explicitly
            if gym == nil {
                WPLog.debug("🏢 Gym not found by exact name, searching all gyms...")
                let allGyms = ClimbingGymManager.shared.getAllGyms()
                WPLog.debug("🏢 Total gyms available: \(allGyms.count)")
                gym = allGyms.first { $0.name.caseInsensitiveCompare(data.gymName) == .orderedSame }
            }

            // 3. Fallback to dummy
            if let foundGym = gym {
                WPLog.debug("🏢 Found gym: '\(foundGym.name)' with logoSource: \(foundGym.logoSource)")
            } else {
                WPLog.warning("🏢 Gym not found, using fallback with .none logoSource")
            }

            let finalGym = gym ?? ClimbingGym(id: "unknown", name: data.gymName, logoSource: .none, gradeColors: [], isBuiltIn: false, metadata: nil)

            w.configure(with: finalGym)
            w.initialSize = widgetSize
            widget = w

        case .climbingDiscipline:
            let w = ClimbingDisciplineWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(discipline: data.discipline)
            w.initialSize = widgetSize
            widget = w

        case .climbingSession:
            let w = ClimbingSessionWidget()
            w.configure(sent: data.sentRoutes, total: data.totalRoutes)
            let sessionSize = w.idealSize
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: sessionSize)
            w.initialSize = sessionSize
            widget = w

        case .climbingRoutesByColor:
            let w = ClimbingRoutesByColorWidget()
            w.configure(routes: data.routes)
            let routesByColorSize = w.idealSize
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: routesByColorSize)
            w.initialSize = routesByColorSize
            widget = w

        case .text:
            let w = TextWidget()
            w.configure(text: "텍스트")
            // Use a reasonable default size for text widget
            let defaultSize = CGSize(width: 100, height: 60)
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: defaultSize)
            w.initialSize = defaultSize
            widget = w

        case .date:
            let w = DateWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(startDate: data.sessionDate)
            w.dateDelegate = self
            w.initialSize = widgetSize
            dateWidgets.append(w)
            widget = w

            // Show date picker immediately when adding new date widget
            DispatchQueue.main.async { [weak self] in
                self?.showDatePicker(for: w)
            }

        default:
            break
        }

        if let widget = widget {
            addWidget(widget, size: widget.frame.size, position: widget.frame.origin)
        }
    }
    
    // Common addWidget wrapper to use Base's addWidget logic but adapting to Climbing's need?
    // Base's addWidget appends to widgets array and sets up selection.
    // We should expose addWidget in Base as internal.
    
    internal func addWidget(_ widget: UIView, size: CGSize, position: CGPoint) {
        contentView.addSubview(widget)
        contentView.bringSubviewToFront(widget)
        widgets.append(widget)
        hasUnsavedChanges = true

        widget.frame = CGRect(origin: position, size: size)

        // Setup selection if widget is selectable
        if var selectableWidget = widget as? Selectable {
            selectableWidget.selectionDelegate = self
            selectionManager.registerItem(selectableWidget)

            // Set initial size for BaseStatWidget (for font scaling)
            if let statWidget = widget as? BaseStatWidget {
                statWidget.initialSize = size
            }
            
            // Should prompt Base to handle common setup like loading colors?
             // Load saved color if available
            if let savedColor = ColorPreferences.shared.loadColor(for: selectableWidget.itemIdentifier) {
                selectableWidget.applyColor(savedColor)
            }

            // Load saved font if available
            if let savedFont = FontPreferences.shared.loadFont(for: selectableWidget.itemIdentifier) {
                if let statWidget = widget as? BaseStatWidget {
                    statWidget.applyFont(savedFont)
                } else if let routesWidget = widget as? ClimbingRoutesByColorWidget {
                    routesWidget.applyFont(savedFont)
                }
            }
        }
    }
    
    // MARK: - Template Application

    override func createWidget(for item: WidgetItem, frame: CGRect) -> UIView? {
        guard let data = climbingData else { return nil }

        var widget: UIView?

        switch item.type {
        case .climbingGym:
            let w = ClimbingGymWidget()
            w.configure(gymName: data.gymName)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .gymLogo:
            let w = GymLogoWidget()
            WPLog.debug("🏢 [Template] Looking for gym with name: '\(data.gymName)'")
            var gym = ClimbingGymManager.shared.findGym(byName: data.gymName)
            if gym == nil {
                WPLog.debug("🏢 [Template] Gym not found by exact name, searching all gyms...")
                let allGyms = ClimbingGymManager.shared.getAllGyms()
                gym = allGyms.first { $0.name.caseInsensitiveCompare(data.gymName) == .orderedSame }
            }
            if let foundGym = gym {
                WPLog.debug("🏢 [Template] Found gym: '\(foundGym.name)' with logoSource: \(foundGym.logoSource)")
            } else {
                WPLog.warning("🏢 [Template] Gym not found, using fallback")
            }
            let finalGym = gym ?? ClimbingGym(id: "unknown", name: data.gymName, logoSource: .none, gradeColors: [], isBuiltIn: false, metadata: nil)
            w.configure(with: finalGym)
            w.frame = frame
            w.initialSize = frame.size
            if let colorHex = item.color, let color = TemplateManager.color(from: colorHex) {
                w.applyColor(color)
            }
            widget = w

        case .climbingDiscipline:
            let w = ClimbingDisciplineWidget()
            w.configure(discipline: data.discipline)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .climbingSession:
            let w = ClimbingSessionWidget()
            w.configure(sent: data.sentRoutes, total: data.totalRoutes)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .climbingRoutesByColor:
            let w = ClimbingRoutesByColorWidget()
            w.configure(routes: data.routes)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .text:
            let w = TextWidget()
            w.configure(text: "텍스트 입력")
            w.textDelegate = self as? TextWidgetDelegate
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .date:
            let w = DateWidget()
            w.configure(startDate: data.sessionDate)
            w.dateDelegate = self
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            dateWidgets.append(w)
            widget = w

        case .currentDateTime:
            let w = CurrentDateTimeWidget()
            w.configure(date: data.sessionDate)
            w.currentDateTimeDelegate = self
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            currentDateTimeWidgets.append(w)
            widget = w

        case .composite, .routeMap, .distance, .duration, .pace, .speed, .calories, .heartRate, .location:
            return nil
        }

        return widget
    }

    // MARK: - Widget Restoration

    override func getWorkoutDate() -> Date? {
        return climbingData?.sessionDate
    }

    override func createWidgetFromSavedState(_ savedWidget: SavedWidgetState) -> UIView? {
        // Try base implementation first
        if let widget = super.createWidgetFromSavedState(savedWidget) {
            return widget
        }

        // Handle Climbing-specific widgets
        guard let data = climbingData else { return nil }
        let widgetType = savedWidget.type

        let widget: UIView?

        switch widgetType {
        case "ClimbingGymWidget":
            let w = ClimbingGymWidget()
            w.configure(gymName: data.gymName)
            widget = w

        case "ClimbingSessionWidget":
            let w = ClimbingSessionWidget()
            w.configure(sent: data.sentRoutes, total: data.totalRoutes)
            widget = w

        case "ClimbingDisciplineWidget":
            let w = ClimbingDisciplineWidget()
            w.configure(discipline: data.discipline)
            widget = w

        case "ClimbingRoutesByColorWidget":
            let w = ClimbingRoutesByColorWidget()
            w.configure(routes: data.routes)
            // Apply styles with fallback to old font preferences
            applyCommonWidgetStyles(to: w, from: savedWidget)
            if savedWidget.fontStyle == nil, let savedFont = FontPreferences.shared.loadFont(for: savedWidget.identifier) {
                w.applyFont(savedFont)
            }
            return w

        case "GymLogoWidget":
            let w = GymLogoWidget()
            WPLog.debug("🏢 [Saved] Looking for gym with name: '\(data.gymName)'")
            var gym = ClimbingGymManager.shared.findGym(byName: data.gymName)
            if gym == nil {
                WPLog.debug("🏢 [Saved] Gym not found by exact name, searching all gyms...")
                let allGyms = ClimbingGymManager.shared.getAllGyms()
                gym = allGyms.first { $0.name.caseInsensitiveCompare(data.gymName) == .orderedSame }
            }
            if let foundGym = gym {
                WPLog.debug("🏢 [Saved] Found gym: '\(foundGym.name)' with logoSource: \(foundGym.logoSource)")
            } else {
                WPLog.warning("🏢 [Saved] Gym not found, using fallback")
            }
            let finalGym = gym ?? ClimbingGym(id: "unknown", name: data.gymName, logoSource: .none, gradeColors: [], isBuiltIn: false, metadata: nil)
            w.configure(with: finalGym)
            widget = w

        case "DateWidget":
            let w = DateWidget()
            w.configure(startDate: data.sessionDate)
            w.dateDelegate = self
            applyCommonWidgetStyles(to: w, from: savedWidget)
            dateWidgets.append(w)
            return w

        case "CurrentDateTimeWidget":
            let w = CurrentDateTimeWidget()
            w.configure(date: data.sessionDate)
            w.currentDateTimeDelegate = self
            applyCommonWidgetStyles(to: w, from: savedWidget)
            currentDateTimeWidgets.append(w)
            return w

        default:
            return nil
        }

        // Apply common styles for non-special cases
        if let widget = widget {
            applyCommonWidgetStyles(to: widget, from: savedWidget)
        }

        return widget
    }
}

// MARK: - Date Widget Delegate
extension ClimbingDetailViewController: DateWidgetDelegate {
    func dateWidgetDidRequestEdit(_ widget: DateWidget) {
        showDatePicker(for: widget)
    }

    private func showDatePicker(for widget: DateWidget) {
        let alert = UIAlertController(title: "날짜 선택", message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "ko_KR")
        datePicker.date = widget.configuredDate ?? Date()

        alert.view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50)
        ])

        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self, weak widget] _ in
            guard let self = self, let widget = widget else { return }
            let selectedDate = datePicker.date

            // Update widget
            widget.updateDate(selectedDate)

            // Update climbing data
            if var data = self.climbingData {
                data.sessionDate = selectedDate
                self.climbingData = data

                // Update all date widgets to show the new date
                for dateWidget in self.dateWidgets {
                    dateWidget.updateDate(selectedDate)
                }

                // Update all current date time widgets to show the new date
                for currentDateTimeWidget in self.currentDateTimeWidgets {
                    currentDateTimeWidget.updateDate(selectedDate)
                }

                // Mark as having unsaved changes
                self.hasUnsavedChanges = true

                // Update the data in the manager
                ClimbingDataManager.shared.updateSession(data)

                WPLog.debug("Date updated to: \(selectedDate)")
            }
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(confirmAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
}

// MARK: - Current Date Time Widget Delegate
extension ClimbingDetailViewController: CurrentDateTimeWidgetDelegate {
    func currentDateTimeWidgetDidRequestEdit(_ widget: CurrentDateTimeWidget) {
        showCurrentDateTimePicker(for: widget)
    }

    private func showCurrentDateTimePicker(for widget: CurrentDateTimeWidget) {
        let alert = UIAlertController(title: "날짜 선택", message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "ko_KR")
        datePicker.date = widget.configuredDate ?? Date()

        alert.view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50)
        ])

        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self, weak widget] _ in
            guard let self = self, let widget = widget else { return }
            let selectedDate = datePicker.date

            // Update widget
            widget.updateDate(selectedDate)

            // Update climbing data
            if var data = self.climbingData {
                data.sessionDate = selectedDate
                self.climbingData = data

                // Update all date widgets to show the new date
                for dateWidget in self.dateWidgets {
                    dateWidget.updateDate(selectedDate)
                }

                // Update all current date time widgets to show the new date
                for currentDateTimeWidget in self.currentDateTimeWidgets {
                    currentDateTimeWidget.updateDate(selectedDate)
                }

                // Mark as having unsaved changes
                self.hasUnsavedChanges = true

                // Update the data in the manager
                ClimbingDataManager.shared.updateSession(data)

                WPLog.debug("Date updated to: \(selectedDate)")
            }
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(confirmAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
}
