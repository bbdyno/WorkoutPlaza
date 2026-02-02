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
    
    override func showAddWidgetMenuBase() {
        showAddWidgetMenu() // Specific implementation
    }
    
    override func showTemplateMenu() {
        // Climbing specific templates
         let alert = UIAlertController(title: "레이아웃 템플릿", message: "위젯 배치를 선택하세요", preferredStyle: .actionSheet)

        // Get climbing templates
        let templates = TemplateManager.shared.getTemplates(for: .climbing)

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
            actionSheet.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.addNewWidget(type: type)
            })
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
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(text: "텍스트")
            w.initialSize = widgetSize
            widget = w

        case .date:
            let w = DateWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(startDate: data.sessionDate)
            w.initialSize = widgetSize
            widget = w

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
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .currentDateTime:
            let w = CurrentDateTimeWidget()
            w.configure(date: data.sessionDate)
            w.frame = frame
            w.initialSize = frame.size
            applyItemStyles(to: w, item: item)
            widget = w

        case .composite, .routeMap, .distance, .duration, .pace, .speed, .calories, .location:
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

        switch widgetType {
        case "ClimbingGymWidget":
            let widget = ClimbingGymWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            widget.configure(gymName: data.gymName)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        case "ClimbingSessionWidget":
            let widget = ClimbingSessionWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            widget.configure(sent: data.sentRoutes, total: data.totalRoutes)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        case "ClimbingDisciplineWidget":
            let widget = ClimbingDisciplineWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            widget.configure(discipline: data.discipline)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        case "ClimbingRoutesByColorWidget":
            let widget = ClimbingRoutesByColorWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
            widget.configure(routes: data.routes)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            if let savedFont = FontPreferences.shared.loadFont(for: savedWidget.identifier) {
                widget.applyFont(savedFont)
            }
            return widget

        case "GymLogoWidget":
            let widget = GymLogoWidget()
            widget.frame = savedWidget.frame
            widget.initialSize = savedWidget.frame.size
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
            widget.configure(with: finalGym)
            if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                widget.applyColor(color)
            }
            return widget

        default:
            return nil
        }
    }
}
