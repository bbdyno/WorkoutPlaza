//
//  BaseWorkoutDetailViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit
import UniformTypeIdentifiers
import PhotosUI

class BaseWorkoutDetailViewController: UIViewController, TemplateGroupDelegate, UIGestureRecognizerDelegate, TextWidgetDelegate, CompositeWidgetDelegate {

    // MARK: - Constants (Light Mode for Card Design)
    enum Constants {
        static let canvasBackgroundColor = UIColor.white
        static let canvasBorderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        static let centerGuideColor = ColorSystem.primaryGreen.withAlphaComponent(0.85)
        static let centerGuideThickness: CGFloat = 1
        static let centerSnapThreshold: CGFloat = 10
        static let centerGuideDisplayDuration: TimeInterval = 0.7

        static let toolbarBackgroundColor = UIColor.white.withAlphaComponent(0.95)
        static let multiSelectToolbarBackgroundColor = UIColor.white.withAlphaComponent(0.98)
        static let multiSelectBorderColor = ColorSystem.primaryGreen.withAlphaComponent(0.5).cgColor

        static let toastBackgroundColor = ColorSystem.toastBackground

        static let textPathDrawingToolbarBackgroundColor = UIColor.black.withAlphaComponent(0.85)
        static let textPathDrawingOverlayColor = UIColor.black.withAlphaComponent(0.2)

        static let dimOverlayColor = UIColor.black.withAlphaComponent(0.3)

        static let defaultBackgroundColor = UIColor.white
        
        struct Layout {
            static let instructionTopOffset: CGFloat = 10
            static let horizontalPadding: CGFloat = 20
            static let headerPadding: CGFloat = 16
            
            static let canvasTopOffset: CGFloat = 20
            static let canvasInitialWidth: CGFloat = 300
            static let canvasInitialHeight: CGFloat = 400
            
            static let watermarkInset: CGFloat = 16
            static let watermarkSize: CGFloat = 40
            static let watermarkAlpha: CGFloat = 0.3
            
            static let topToolbarTopOffset: CGFloat = 8
            static let topToolbarTrailingMargin: CGFloat = 16
            
            static let bottomToolbarBottomOffset: CGFloat = -20
            static let bottomToolbarHeight: CGFloat = 60
            static let bottomToolbarPadding = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
            
            static let multiSelectToolbarBottomOffset: CGFloat = -80
            static let multiSelectToolbarHeight: CGFloat = 50
            static let multiSelectToolbarWidth: CGFloat = 320
            
            static let toastTopOffset: CGFloat = 60
            static let toastHeight: CGFloat = 40
            
            static let textPathToolbarHeight: CGFloat = 180
            static let textPathButtonBottomOffset: CGFloat = -12
            static let standardButtonSize: CGFloat = 50
        }
    }

    struct RestoreCanvasTransform {
        let scaleX: CGFloat
        let scaleY: CGFloat
        let uniformScale: CGFloat

        static let identity = RestoreCanvasTransform(scaleX: 1, scaleY: 1, uniformScale: 1)
    }
    
    // MARK: - Properties

    // State
    var widgets: [UIView] = []
    var previousCanvasSize: CGSize = .zero
    var currentAspectRatio: AspectRatio = .portrait4_5 // Default 4:5
    var hasUnsavedChanges: Bool = false
    var centerGuideHideWorkItem: DispatchWorkItem?
    var restoreCanvasTransform: RestoreCanvasTransform = .identity

    // Background State
    var backgroundTransform: BackgroundTransform?

    // Navigation Bar State (for restoration)
    private var originalStandardAppearance: UINavigationBarAppearance?
    private var originalScrollEdgeAppearance: UINavigationBarAppearance?
    private var originalTintColor: UIColor?

    // Selection Manager
    lazy var selectionManager: SelectionManager = {
        let manager = SelectionManager()
        manager.delegate = self
        return manager
    }()

    // Document Picker State
    enum DocumentPickerPurpose {
        case templateImport
        case widgetPackageImport
    }
    var documentPickerPurpose: DocumentPickerPurpose = .templateImport
    
    // Template Groups
    var templateGroups: [TemplateGroupView] = []
    
    // Text Path State
    var pendingTextForPath: String = ""
    var isTextPathDrawingMode: Bool = false
    var textPathPoints: [CGPoint] = []
    var isTextPathStraightLineMode: Bool = false
    var textPathStraightLineStartPoint: CGPoint = .zero

    // Text Path Style
    var textPathSelectedColor: UIColor = .white
    var textPathSelectedFont: UIFont = .boldSystemFont(ofSize: 20)
    var textPathSelectedFontSize: CGFloat = 20
    var textPathSelectedColorIndex: Int = 0
    var textPathSelectedFontIndex: Int = 0

    // MARK: - UI Components
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        return scrollView
    }()

    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // Canvas Container
    lazy var canvasContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.canvasBackgroundColor
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = Constants.canvasBorderColor
        view.clipsToBounds = true
        return view
    }()

    var canvasWidthConstraint: Constraint?
    var canvasHeightConstraint: Constraint?

    // Background Views
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        imageView.backgroundColor = .black
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    lazy var backgroundTemplateView: BackgroundTemplateView = {
        let view = BackgroundTemplateView()
        view.isHidden = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var dimOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.dimOverlayColor
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("ui.drag.widgets.instruction", comment: "")
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var watermarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo_white")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.black.withAlphaComponent(Constants.Layout.watermarkAlpha) // Initial tint, will be updated dynamically
        return imageView
    }()

    // MARK: - Toolbars & Buttons
    
    lazy var topRightToolbar: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    lazy var bottomFloatingToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.toolbarBackgroundColor
        view.layer.cornerRadius = 30
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.isHidden = true // Initially hidden
        return view
    }()
    
    lazy var multiSelectToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.multiSelectToolbarBackgroundColor
        view.layer.cornerRadius = 25
        view.layer.borderWidth = 1
        view.layer.borderColor = Constants.multiSelectBorderColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.isHidden = true
        return view
    }()
    
    lazy var multiSelectCountLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Base.Multi.Select.count(0)
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    // Common Buttons
    lazy var aspectRatioButton: UIButton = createToolbarButton(systemName: "", action: #selector(cycleAspectRatio))
    lazy var layoutTemplateButton: UIButton = createToolbarButton(systemName: "square.grid.2x2", action: #selector(showTemplateMenu))
    lazy var addWidgetButton: UIButton = createToolbarButton(systemName: "plus", action: #selector(showAddWidgetMenuBase))
    lazy var shareImageButton: UIButton = createToolbarButton(systemName: "square.and.arrow.up", action: #selector(shareImage))
    lazy var selectPhotoButton: UIButton = createToolbarButton(systemName: "photo", action: #selector(selectPhoto))
    lazy var textPathButton: UIButton = createToolbarButton(systemName: "pencil.and.outline", action: #selector(showTextPathInput))
    lazy var backgroundTemplateButton: UIButton = createToolbarButton(systemName: "paintbrush", action: #selector(changeTemplate))
    
    lazy var colorPickerButton: UIButton = createToolbarButton(systemName: "paintpalette", action: #selector(showColorPicker))
    lazy var fontPickerButton: UIButton = createToolbarButton(systemName: "textformat", action: #selector(showFontPicker))
    lazy var alignmentButton: UIButton = createToolbarButton(systemName: WidgetContentAlignment.left.symbolName, action: #selector(cycleAlignmentForSelection))
    lazy var deleteItemButton: UIButton = createToolbarButton(systemName: "trash", action: #selector(deleteSelectedItem))
    
    lazy var groupButton: UIButton = createToolbarButton(systemName: "rectangle.stack.badge.plus", action: #selector(groupSelectedWidgets))
    lazy var ungroupButton: UIButton = createToolbarButton(systemName: "rectangle.stack.badge.minus", action: #selector(ungroupSelectedWidget))
    lazy var cancelMultiSelectButton: UIButton = createToolbarButton(systemName: "xmark", action: #selector(exitMultiSelectMode))

    lazy var toastLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = Constants.toastBackgroundColor
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.layer.cornerRadius = 20
        label.clipsToBounds = true
        label.alpha = 0
        return label
    }()

    lazy var verticalCenterGuideView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.centerGuideColor
        view.alpha = 0
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()

    lazy var horizontalCenterGuideView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.centerGuideColor
        view.alpha = 0
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()

    // Text Path Drawing Overlay
    lazy var textPathDrawingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.textPathDrawingOverlayColor
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()

    // Text Path Drawing Toolbar
    lazy var textPathDrawingToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.textPathDrawingToolbarBackgroundColor
        view.isHidden = true
        return view
    }()

    lazy var textPathConfirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.tintColor = .systemGreen
        button.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        button.layer.cornerRadius = 20
        button.isHidden = true
        return button
    }()

    lazy var textPathRedrawButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        button.layer.cornerRadius = 20
        button.isHidden = true
        return button
    }()

    var textPathColorButtons: [UIButton] = []
    var textPathFontButtons: [UIButton] = []
    // textPathPanelJustOpened flag removed as requested
    var textPathOverlayTapGesture: UITapGestureRecognizer?

    // Floating Panels
    lazy var textPathColorPanel: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.layer.cornerRadius = 12
        view.isHidden = true
        view.tag = 8000
        return view
    }()

    lazy var textPathFontPanel: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.layer.cornerRadius = 12
        view.isHidden = true
        view.tag = 8001
        return view
    }()

    lazy var textPathSizePanel: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.layer.cornerRadius = 12
        view.isHidden = true
        view.tag = 8002
        return view
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDefaultBackground()
        setupLongPressGesture()
        setupMultiSelectToolbarConfig() // Renamed to avoid confusion with constraints setup if any

        // Add observer for widget move notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleWidgetDidMove(_:)), name: .widgetDidMove, object: nil)

        // Initial button state
        aspectRatioButton.setTitle(currentAspectRatio.displayName, for: .normal)
        updateToolbarItemsState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Save original navigation bar appearance
        originalStandardAppearance = navigationController?.navigationBar.standardAppearance
        originalScrollEdgeAppearance = navigationController?.navigationBar.scrollEdgeAppearance
        originalTintColor = navigationController?.navigationBar.tintColor

        // Configure navigation bar to match the white background
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = ColorSystem.primaryGreen
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Restore original navigation bar appearance
        if let originalStandard = originalStandardAppearance {
            navigationController?.navigationBar.standardAppearance = originalStandard
        }
        if let originalScrollEdge = originalScrollEdgeAppearance {
            navigationController?.navigationBar.scrollEdgeAppearance = originalScrollEdge
        }
        if let originalTint = originalTintColor {
            navigationController?.navigationBar.tintColor = originalTint
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCanvasSize()
    }
    
    deinit {
        centerGuideHideWorkItem?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup UI
    
    func setupUI() {
        view.backgroundColor = ColorSystem.background
        navigationItem.largeTitleDisplayMode = .never
        
        setupNavigationButtons()
        setupCommonViews()
        setupConstraints()
    }
    
    // Subclasses can override if needed
    func setupNavigationButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: WorkoutPlazaStrings.Button.done,
            style: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
    }
    
    
    @objc dynamic func setupTopRightToolbar() {
        topRightToolbar.addArrangedSubview(aspectRatioButton)
        topRightToolbar.addArrangedSubview(addWidgetButton)
        topRightToolbar.addArrangedSubview(textPathButton)
        topRightToolbar.addArrangedSubview(layoutTemplateButton)
        topRightToolbar.addArrangedSubview(shareImageButton)
        topRightToolbar.addArrangedSubview(selectPhotoButton)
        topRightToolbar.addArrangedSubview(backgroundTemplateButton)
    }
    
    // MARK: - Actions (Stubs to be overridden or implemented)
    
    @objc func backButtonTapped() {
        let closeAction = { [weak self] in
            guard let self = self else { return }
            // Check if we are pushed on a stack or presented modally
            if let nav = self.navigationController, nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else if self.presentingViewController != nil {
                self.dismiss(animated: true)
            } else {
                // Fallback
                self.navigationController?.popViewController(animated: true)
            }
        }

        if hasUnsavedChanges {
            let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.Cancel.title, message: WorkoutPlazaStrings.Alert.Unsaved.changes, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Button.cancel, style: .cancel))
            alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Button.exit, style: .destructive) { _ in
                closeAction()
            })
            present(alert, animated: true)
        } else {
            closeAction()
        }
    }
    
    @objc func doneButtonTapped() {
        // Implement save logic in subclasses
    }
    
    @objc dynamic func saveCurrentDesign(completion: ((Bool) -> Void)? = nil) {
        // Get workout ID - subclasses should override getWorkoutId() if needed
        let workoutId = getWorkoutId()

        // 1. Deselect everything to hide selection UI
        selectionManager.deselectAll()

        // 2. Collect ALL widgets (both top-level and inside groups)
        var allWidgets: [UIView] = widgets
        for group in templateGroups {
            allWidgets.append(contentsOf: group.groupedItems)
        }

        // 3. Create SavedWidgetState objects
        let savedWidgets = allWidgets.compactMap { widget -> SavedWidgetState? in
            let frame = widget.frame
            let className = String(describing: type(of: widget))
            let definitionID = WidgetIdentity.definitionID(for: widget)
            let savedType = definitionID.map { WidgetIdentity.legacyTypeName(for: $0) } ?? className
            
            // Use stable identifier from Selectable if available
            let identifier: String
            if let selectable = widget as? Selectable {
                identifier = selectable.itemIdentifier
            } else {
                identifier = UUID().uuidString // Fallback (shouldn't happen for valid widgets)
            }
            let savedInitialSize: CGSize?
            if let selectable = widget as? Selectable {
                let candidate = selectable.initialSize
                if candidate.width > 0, candidate.height > 0 {
                    savedInitialSize = candidate
                } else if widget.bounds.width > 0, widget.bounds.height > 0 {
                    savedInitialSize = widget.bounds.size
                } else {
                    savedInitialSize = nil
                }
            } else {
                savedInitialSize = nil
            }

            var text: String?
            var fontName: String?
            var fontSize: CGFloat?
            var fontStyle: String?
            var textColor: String?
            var pathPoints: [[CGFloat]]?
            var workoutDate: Date?
            var additionalText: String?
            var contentAlignment: String?
            var widgetPayload: String?
            var statFontScale: CGFloat?
            var statTitleBaseFontSize: CGFloat?
            var statValueBaseFontSize: CGFloat?
            var statUnitBaseFontSize: CGFloat?

            // Extract fontStyle from Selectable widgets
            if let selectable = widget as? Selectable {
                fontStyle = selectable.currentFontStyle.rawValue
                textColor = selectable.currentColor.toHex()
            }

            if let alignableWidget = widget as? WidgetContentAlignable {
                contentAlignment = alignableWidget.contentAlignment.rawValue
            }

            // Extract data based on widget type
            if let textWidget = widget as? TextWidget {
                text = textWidget.textLabel.text
                fontName = textWidget.textLabel.font.fontName
                fontSize = textWidget.textLabel.font.pointSize
                textColor = textWidget.textLabel.textColor.toHex()
            }

            if let textPathWidget = widget as? TextPathWidget {
                text = textPathWidget.text
                textColor = textPathWidget.currentColor.toHex()
                fontSize = textPathWidget.fontSize
                // Save normalized path points
                pathPoints = textPathWidget.normalizedPoints.map { [$0.x, $0.y] }
            }

            if let dateWidget = widget as? DateWidget {
                workoutDate = dateWidget.configuredDate
                textColor = dateWidget.currentColor.toHex()
            }

            if let currentDateTimeWidget = widget as? CurrentDateTimeWidget {
                workoutDate = currentDateTimeWidget.configuredDate
                textColor = currentDateTimeWidget.currentColor.toHex()
            }

            if let locationWidget = widget as? LocationWidget {
                additionalText = locationWidget.locationText
                textColor = locationWidget.currentColor.toHex()
            }

            if let compositeWidget = widget as? CompositeWidget {
                widgetPayload = compositeWidget.encodedPayloadString()
            }

            // Stat widgets - save color and display mode
            var displayMode: String?
            if let statWidget = widget as? BaseStatWidget {
                textColor = statWidget.currentColor.toHex()
                statFontScale = statWidget.calculateScaleFactor()
                statTitleBaseFontSize = statWidget.baseFontSizes["title"] ?? LayoutConstants.titleFontSize
                statValueBaseFontSize = statWidget.baseFontSizes["value"] ?? LayoutConstants.valueFontSize
                statUnitBaseFontSize = statWidget.baseFontSizes["unit"] ?? LayoutConstants.unitFontSize
                if statWidget.widgetIconName != nil && statWidget.displayMode != .text {
                    displayMode = statWidget.displayMode.rawValue
                }
            }

            // Get rotation from Selectable widgets
            let rotation: CGFloat
            if let selectable = widget as? Selectable {
                rotation = selectable.rotation
            } else {
                rotation = 0
            }

            return SavedWidgetState(
                identifier: identifier,
                type: savedType,
                definitionID: definitionID?.rawValue,
                frame: frame,
                initialSize: savedInitialSize,
                statFontScale: statFontScale,
                statTitleBaseFontSize: statTitleBaseFontSize,
                statValueBaseFontSize: statValueBaseFontSize,
                statUnitBaseFontSize: statUnitBaseFontSize,
                text: text,
                fontName: fontName,
                fontSize: fontSize,
                fontStyle: fontStyle,
                textColor: textColor,
                backgroundColor: widget.backgroundColor?.toHex(),
                rotation: rotation,
                zIndex: 0,
                pathPoints: pathPoints,
                workoutDate: workoutDate,
                numericValue: nil,
                additionalText: additionalText,
                displayMode: displayMode,
                contentAlignment: contentAlignment,
                widgetPayload: widgetPayload
            )
        }
        
        // 4. Create SavedGroupState objects
        let savedGroups = templateGroups.compactMap { group -> SavedGroupState? in
            let widgetIds = group.groupedItems.compactMap { ($0 as? Selectable)?.itemIdentifier }
            return SavedGroupState(
                identifier: group.groupId,
                type: group.groupType.rawValue,
                frame: group.frame,
                ownerName: group.ownerName,
                widgetIdentifiers: widgetIds
            )
        }
        
        // 5. Determine background type and data
        var bgType: BackgroundType = .solid
        var bgData: Data? = nil
        var gradientStyleString: String? = nil
        var gradientColorsHex: [String]? = nil

        if !backgroundImageView.isHidden && backgroundImageView.image != nil {
            bgType = .image
            bgData = backgroundImageView.image?.jpegData(compressionQuality: 0.8)
        } else if !backgroundTemplateView.isHidden {
            bgType = .gradient
            gradientStyleString = backgroundTemplateView.currentStyle.rawValue
            if backgroundTemplateView.currentStyle == .custom,
               let customColors = backgroundTemplateView.customColors {
                gradientColorsHex = customColors.compactMap { $0.toHex() }
            }
        }

        // 6. Create design object
        let design = SavedCardDesign(
            backgroundType: bgType,
            backgroundColor: nil,
            backgroundImageData: bgData,
            widgets: savedWidgets,
            canvasSize: contentView.bounds.size,
            aspectRatio: currentAspectRatio,
            gradientColors: gradientColorsHex,
            gradientStyle: gradientStyleString,
            groups: savedGroups
        )
        
        // 5. Save design
        do {
            try CardPersistenceManager.shared.saveDesign(design, for: workoutId)
            
            // 6. Render and save card image
            guard let image = renderCanvasImage() else {
                completion?(false)
                return
            }
            
            saveWorkoutCard(image: image)
            completion?(true)
        } catch {
            WPLog.error("Error saving design: \(error)")
            completion?(false)
        }
    }
    
    // Subclasses should override this to provide workout ID
    @objc dynamic func getWorkoutId() -> String {
        return "default"
    }
    
    func renderCanvasImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: contentView.bounds)
        return renderer.image { context in
            contentView.layer.render(in: context.cgContext)
        }
    }
    
    @objc dynamic func saveWorkoutCard(image: UIImage) {
        // Override in subclasses
    }

    func frameForRestoredWidget(_ savedState: SavedWidgetState, widget: UIView) -> CGRect {
        scaledFrameForCurrentCanvas(savedState.frame)
    }

    func createWidgetFromSavedState(_ savedWidget: SavedWidgetState) -> UIView? {
        guard let definitionID = WidgetIdentity.resolvedDefinitionID(from: savedWidget) else {
            return nil
        }

        // Common widgets that can be created in base class
        switch definitionID {
        case .text:
            let widget = TextWidget()
            if let text = savedWidget.text {
                widget.configure(text: text)
            }
            widget.textDelegate = self
            applyCommonWidgetStyles(to: widget, from: savedWidget)
            return widget

        case .textPath:
            guard let pathPointsArray = savedWidget.pathPoints,
                  let text = savedWidget.text else {
                return nil
            }
            let pathPoints = pathPointsArray.compactMap { arr -> CGPoint? in
                guard arr.count >= 2 else { return nil }
                return CGPoint(x: arr[0], y: arr[1])
            }
            let framePoints = pathPoints.map { point in
                CGPoint(
                    x: point.x * savedWidget.frame.width,
                    y: point.y * savedWidget.frame.height
                )
            }
            let color = savedWidget.textColor.flatMap { UIColor(hex: $0) } ?? .white
            let fontSize = savedWidget.fontSize ?? 20
            let font = UIFont.boldSystemFont(ofSize: fontSize)
            let widget = TextPathWidget(
                text: text,
                pathPoints: framePoints,
                frame: savedWidget.frame,
                color: color,
                font: font
            )
            return widget

        case .date:
            let widget = DateWidget()
            if let date = savedWidget.workoutDate {
                widget.configure(startDate: date)
            } else if let date = getWorkoutDate() {
                widget.configure(startDate: date)
            }
            applyCommonWidgetStyles(to: widget, from: savedWidget)
            return widget

        case .currentDateTime:
            let widget = CurrentDateTimeWidget()
            if let date = savedWidget.workoutDate {
                widget.configure(date: date)
            } else if let date = getWorkoutDate() {
                widget.configure(date: date)
            }
            applyCommonWidgetStyles(to: widget, from: savedWidget)
            return widget

        case .composite:
            let widget = CompositeWidget()
            if let payload = CompositeWidget.payload(from: savedWidget.widgetPayload) {
                widget.configure(payload: payload)
            } else {
                widget.configure(payload: .default)
            }
            widget.compositeDelegate = self
            applyCommonWidgetStyles(to: widget, from: savedWidget)
            return widget

        default:
            // Subclasses should handle specific widget types
            return nil
        }
    }

    // Override in subclasses to provide workout date
    @objc dynamic func getWorkoutDate() -> Date? {
        return nil
    }

    func getSportType() -> SportType {
        return .running
    }

    // Shared actions

    /// Override in subclasses to provide sport-specific templates and widgets.
    func getToolSheetItems() -> (templates: [ToolSheetItem], widgets: [ToolSheetItem], templateActions: [ToolSheetHeaderAction]) {
        return ([], [], [])
    }

    @objc dynamic func refreshTemplateLibrary() {
        // Override in subclasses when template list needs async refresh.
    }

    @objc dynamic func shareImage() {
        // Hide UI elements that shouldn't be in the final image
        selectionManager.deselectAll()
        instructionLabel.isHidden = true

        // Capture after a short delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            if let image = self.captureContentView() {
                self.presentShareSheet(image: image)
            }

            // Restore UI
            self.instructionLabel.isHidden = false
        }
    }
    @objc dynamic func selectPhoto() {
        let actionSheet = UIAlertController(title: WorkoutPlazaStrings.Alert.Background.select, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Background.Select.photo, style: .default) { [weak self] _ in
            self?.presentPhotoPickerDefault()
        })

        actionSheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Background.Use.template, style: .default) { [weak self] _ in
            self?.useTemplateDefault()
        })

        actionSheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Background.remove, style: .destructive) { [weak self] _ in
            self?.removeBackgroundDefault()
        })

        actionSheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))
        
        // iPad 지원
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = selectPhotoButton
            popover.sourceRect = selectPhotoButton.bounds
        }

        present(actionSheet, animated: true)
    }
    @objc dynamic func showTextPathInput() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Textpath.title,
            message: WorkoutPlazaStrings.Textpath.message,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = WorkoutPlazaStrings.Textpath.placeholder
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Textpath.draw, style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let text = alert?.textFields?.first?.text,
                  !text.isEmpty else { return }

            self.pendingTextForPath = text + " "
            self.enterTextPathDrawingMode()
        })

        present(alert, animated: true)
    }


    @objc dynamic func changeTemplate() {
        let actionSheet = UIAlertController(title: WorkoutPlazaStrings.Alert.Background.options, message: nil, preferredStyle: .actionSheet)

        let templates: [(name: String, style: BackgroundTemplateView.TemplateStyle, colors: [UIColor])] = [
            (WorkoutPlazaStrings.Background.Gradient.blue, .gradient1, [UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0), UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)]),
            (WorkoutPlazaStrings.Background.Gradient.purple, .gradient2, [UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0), UIColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 1.0)]),
            (WorkoutPlazaStrings.Background.Gradient.orange, .gradient3, [UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0), UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)]),
            (WorkoutPlazaStrings.Background.Gradient.green, .gradient4, [UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0), UIColor(red: 0.4, green: 0.9, blue: 0.6, alpha: 1.0)]),
            (WorkoutPlazaStrings.Background.dark, .dark, [UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0), UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)]),
            (WorkoutPlazaStrings.Background.minimal, .minimal, [.white])
        ]

        for template in templates {
            let action = UIAlertAction(title: template.name, style: .default) { [weak self] _ in
                self?.applyTemplateDefault(template.style)
            }
            action.setValue(iconForGradientDefault(colors: template.colors), forKey: "image")
            actionSheet.addAction(action)
        }

        // Random
        actionSheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Background.random, style: .default) { [weak self] _ in
            self?.backgroundTemplateView.applyRandomTemplate()
            self?.hasUnsavedChanges = true
            self?.updateWatermarkColorForBackground()
        })

        // Custom
        actionSheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Background.Custom.gradient, style: .default) { [weak self] _ in
            self?.presentCustomGradientPickerDefault()
        })

        actionSheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = backgroundTemplateButton
            popover.sourceRect = backgroundTemplateButton.bounds
        }

        present(actionSheet, animated: true)
    }
    // MARK: - Template Management

    func createWidget(for item: WidgetItem, frame: CGRect) -> UIView? {
        // Override in subclasses to handle workout-specific widget types
        return nil
    }

    /// Override in subclasses to clear workout-specific widgets (e.g., routeMapView for running)
    func clearCustomWidgets() {
        // Override in subclasses if needed
    }

    
    
}
