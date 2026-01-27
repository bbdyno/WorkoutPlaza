//
//  BaseWorkoutDetailViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit
import PhotosUI

class BaseWorkoutDetailViewController: UIViewController, TemplateGroupDelegate {

    // MARK: - Properties
    
    // State
    var widgets: [UIView] = []
    var previousCanvasSize: CGSize = .zero
    var currentAspectRatio: AspectRatio = .portrait4_5 // Default 4:5
    var hasUnsavedChanges: Bool = false
    
    // Background State
    var backgroundTransform: BackgroundTransform?

    // Selection Manager
    lazy var selectionManager: SelectionManager = {
        let manager = SelectionManager()
        manager.delegate = self
        return manager
    }()

    // Document Picker State
    enum DocumentPickerPurpose {
        case templateImport
    }
    var documentPickerPurpose: DocumentPickerPurpose = .templateImport
    
    // Template Groups
    var templateGroups: [TemplateGroupView] = []
    
    // Text Path State
    var pendingTextForPath: String = ""
    weak var textPathDrawingOverlay: TextPathDrawingOverlay?

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
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(white: 0.2, alpha: 1.0).cgColor
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
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var watermarkLabel: UILabel = {
        let label = UILabel()
        label.text = "WorkoutPlaza"
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.textAlignment = .right
        return label
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
        view.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
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
        view.backgroundColor = UIColor(white: 0.2, alpha: 0.95)
        view.layer.cornerRadius = 25
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.isHidden = true
        return view
    }()
    
    lazy var multiSelectCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0개 선택"
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
    lazy var deleteItemButton: UIButton = createToolbarButton(systemName: "trash", action: #selector(deleteSelectedItem))
    
    lazy var groupButton: UIButton = createToolbarButton(systemName: "rectangle.3.group", action: #selector(groupSelectedWidgets))
    lazy var ungroupButton: UIButton = createToolbarButton(systemName: "rectangle.grid.1x2", action: #selector(ungroupSelectedWidget))
    lazy var cancelMultiSelectButton: UIButton = createToolbarButton(systemName: "xmark", action: #selector(exitMultiSelectMode))

    lazy var toastLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.layer.cornerRadius = 20
        label.clipsToBounds = true
        label.alpha = 0
        return label
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDefaultBackground()
        setupLongPressGesture()
        setupMultiSelectToolbarConfig() // Renamed to avoid confusion with constraints setup if any
        
        // Add observer for widget move notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleWidgetDidMove), name: .widgetDidMove, object: nil)
        
        // Initial button state
        aspectRatioButton.setTitle(currentAspectRatio.displayName, for: .normal)
        updateToolbarItemsState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCanvasSize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup UI
    
    func setupUI() {
        view.backgroundColor = .black
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
            title: "완료",
            style: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
    }
    
    func setupCommonViews() {
        view.addSubview(instructionLabel)
        view.addSubview(canvasContainerView)
        canvasContainerView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(backgroundTemplateView)
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(dimOverlay)
        contentView.addSubview(watermarkLabel)
        
        view.addSubview(topRightToolbar)
        view.addSubview(bottomFloatingToolbar)
        view.addSubview(multiSelectToolbar)
        view.addSubview(toastLabel)
        
        setupTopRightToolbar()
        setupBottomFloatingToolbar()
        
        // Background tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tapGesture)
        
        updateCanvasSize()
    }
    
    func setupConstraints() {
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        canvasContainerView.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            // Initial constraints, will be updated by updateCanvasSize
            canvasWidthConstraint = make.width.equalTo(300).constraint
            canvasHeightConstraint = make.height.equalTo(400).constraint
        }
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalToSuperview()
        }
        
        backgroundTemplateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // backgroundImageView frame is set manually in updateCanvasSize
        
        dimOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        watermarkLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        topRightToolbar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().inset(16)
        }
        
        bottomFloatingToolbar.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.centerX.equalToSuperview()
            make.height.equalTo(60)
        }
        
        multiSelectToolbar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-80)
            make.height.equalTo(50)
        }
        
        toastLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.width.greaterThanOrEqualTo(100)
            make.height.equalTo(40)
        }
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
    
    func setupBottomFloatingToolbar() {
        let stack = UIStackView(arrangedSubviews: [colorPickerButton, fontPickerButton, deleteItemButton])
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .center
        
        bottomFloatingToolbar.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
        }
    }

    func setupMultiSelectToolbarConfig() {
        let stack = UIStackView(arrangedSubviews: [groupButton, ungroupButton])
        stack.axis = .horizontal
        stack.spacing = 16
        
        multiSelectToolbar.addSubview(multiSelectCountLabel)
        multiSelectToolbar.addSubview(stack)
        multiSelectToolbar.addSubview(cancelMultiSelectButton)
        
        multiSelectCountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        cancelMultiSelectButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(34)
        }
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
            let alert = UIAlertController(title: "작업 취소", message: "변경사항이 저장되지 않을 수 있습니다. 나가시겠습니까?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "나가기", style: .destructive) { _ in
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
        
        // 2. Collect widget states
        let savedWidgets = widgets.compactMap { widget -> SavedWidgetState? in
            let frame = widget.frame
            let className = String(describing: type(of: widget))
            var text: String?
            var fontName: String?
            var fontSize: CGFloat?
            var textColor: String?

            if let textWidget = widget as? TextWidget {
                text = textWidget.textLabel.text
                fontName = textWidget.textLabel.font.fontName
                fontSize = textWidget.textLabel.font.pointSize
                textColor = textWidget.textLabel.textColor.toHex()
            }

            return SavedWidgetState(
                identifier: className,
                type: className,
                frame: frame,
                text: text,
                fontName: fontName,
                fontSize: fontSize,
                textColor: textColor,
                backgroundColor: widget.backgroundColor?.toHex(),
                rotation: 0,
                zIndex: 0
            )
        }
        
        // 3. Determine background type and data
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

        // 4. Create design object
        let design = SavedCardDesign(
            backgroundType: bgType,
            backgroundColor: nil,
            backgroundImageData: bgData,
            widgets: savedWidgets,
            canvasSize: contentView.bounds.size,
            aspectRatio: currentAspectRatio,
            gradientColors: gradientColorsHex,
            gradientStyle: gradientStyleString
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
            print("Error saving design: \(error)")
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
    
    @objc dynamic func loadSavedDesign() {
        let workoutId = getWorkoutId()
        
        guard let design = CardPersistenceManager.shared.loadDesign(for: workoutId) else {
            print("No saved design found for \(workoutId)")
            // Reset flag even if no saved design (initial state should be "no changes")
            hasUnsavedChanges = false
            return
        }
        
        print("📂 Loading saved design for \(workoutId)")
        
        // Restore Aspect Ratio
        currentAspectRatio = design.aspectRatio
        aspectRatioButton.setTitle(design.aspectRatio.displayName, for: .normal)
        updateCanvasSize()
        
        // Force layout update
        view.layoutIfNeeded()

        // Restore Background
        if design.backgroundType == .image, let data = design.backgroundImageData {
            backgroundImageView.image = UIImage(data: data)
            backgroundImageView.isHidden = false
            backgroundTemplateView.isHidden = true
        } else if design.backgroundType == .gradient, let styleString = design.gradientStyle {
            backgroundImageView.isHidden = true
            backgroundTemplateView.isHidden = false

            if let style = BackgroundTemplateView.TemplateStyle(rawValue: styleString) {
                if style == .custom, let colorsHex = design.gradientColors {
                    let colors = colorsHex.compactMap { UIColor(hex: $0) }
                    if !colors.isEmpty {
                        backgroundTemplateView.applyCustomGradient(colors: colors, direction: .topToBottom)
                    }
                } else {
                    backgroundTemplateView.applyTemplate(style)
                }
            }
        }

        // Restore Widget Positions
        for savedWidget in design.widgets {
            let savedClassName = savedWidget.identifier

            for widget in widgets {
                let widgetClassName = String(describing: type(of: widget))
                if widgetClassName == savedClassName {
                    widget.frame = savedWidget.frame
                    
                    // Update initialSize for stat widgets
                    if let statWidget = widget as? BaseStatWidget {
                        statWidget.initialSize = savedWidget.frame.size
                        statWidget.updateFonts()
                    }
                    break
                }
            }
        }

        print("✅ Design loaded and restored for \(workoutId)")
        
        // Reset unsaved changes flag since we just loaded the saved state
        hasUnsavedChanges = false
    }
    
    // Shared actions
    @objc func cycleAspectRatio() {
        let allRatios = AspectRatio.allCases
        if let index = allRatios.firstIndex(of: currentAspectRatio) {
            let nextIndex = (index + 1) % allRatios.count
            currentAspectRatio = allRatios[nextIndex]
            aspectRatioButton.setTitle(currentAspectRatio.displayName, for: .normal)
            updateCanvasSize()
            showToast("Aspect Ratio: \(currentAspectRatio.displayName)")
        }
    }
    
    // Abstract method to be overridden
    @objc func showAddWidgetMenuBase() {
        // Subclasses should implement
    }
    
    @objc func showTemplateMenu() {
        // Shared template menu logic - override in subclasses
    }

    @objc func shareImage() {
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

    private func captureContentView() -> UIImage? {
        // Use current aspect ratio for export
        let targetSize = currentAspectRatio.exportSize

        // Use high quality scale (3x for retina displays)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0  // High quality rendering
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // Calculate scale for rendering
        let renderScale = targetSize.width / contentView.bounds.width

        let image = renderer.image { context in
            // Scale context
            context.cgContext.scaleBy(x: renderScale, y: renderScale)

            // Render content view (which includes background, template, widgets, etc.)
            contentView.layer.render(in: context.cgContext)
        }

        return image
    }

    private func presentShareSheet(image: UIImage) {
        // 카드 저장
        saveWorkoutCard(image: image)

        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        activityViewController.completionWithItemsHandler = { [weak self] activityType, completed, returnedItems, error in
            if completed && activityType == .saveToCameraRoll {
                // Image was saved to camera roll
                let alert = UIAlertController(title: "저장 완료", message: "이미지가 앨범에 저장되었습니다", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self?.present(alert, animated: true)
            } else if let error = error {
                let alert = UIAlertController(title: "저장 실패", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self?.present(alert, animated: true)
            }
        }

        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = shareImageButton
            popover.sourceRect = shareImageButton.bounds
        }

        present(activityViewController, animated: true)
    }
    
    @objc dynamic func selectPhoto() {
        let actionSheet = UIAlertController(title: "배경 선택", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "사진 선택", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: "템플릿 사용", style: .default) { [weak self] _ in
            self?.useTemplate()
        })
        
        actionSheet.addAction(UIAlertAction(title: "배경 제거", style: .destructive) { [weak self] _ in
            self?.removeBackground()
        })
        
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad 지원
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = selectPhotoButton
            popover.sourceRect = selectPhotoButton.bounds
        }

        present(actionSheet, animated: true)
    }
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func useTemplate() {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
        hasUnsavedChanges = true
    }
    
    private func removeBackground() {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = true
        dimOverlay.isHidden = true
        view.backgroundColor = .systemGroupedBackground
        hasUnsavedChanges = true
    }
    
    @objc dynamic func showTextPathInput() {
        let alert = UIAlertController(
            title: "텍스트 패스",
            message: "경로를 따라 반복할 텍스트를 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "반복할 텍스트 입력"
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        alert.addAction(UIAlertAction(title: "그리기", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let text = alert?.textFields?.first?.text,
                  !text.isEmpty else { return }

            self.pendingTextForPath = text + " "
            self.enterTextPathDrawingMode()
        })

        present(alert, animated: true)
    }

    private func enterTextPathDrawingMode() {
        // Create overlay for drawing
        let overlay = TextPathDrawingOverlay(frame: contentView.bounds)
        overlay.textToRepeat = pendingTextForPath

        overlay.onDrawingComplete = { [weak self] pathPoints, boundingRect, color, font in
            self?.createTextPathWidget(
                pathPoints: pathPoints,
                boundingRect: boundingRect,
                color: color,
                font: font
            )
            self?.exitTextPathDrawingMode()
        }

        overlay.onDrawingCancelled = { [weak self] in
            self?.exitTextPathDrawingMode()
        }

        contentView.addSubview(overlay)
        textPathDrawingOverlay = overlay
    }

    private func exitTextPathDrawingMode() {
        textPathDrawingOverlay?.removeFromSuperview()
        textPathDrawingOverlay = nil
        pendingTextForPath = ""
    }

    private func createTextPathWidget(
        pathPoints: [CGPoint],
        boundingRect: CGRect,
        color: UIColor,
        font: UIFont
    ) {
        guard pathPoints.count >= 2 else { return }

        // Convert path points to widget's local coordinate system
        let localPathPoints = pathPoints.map { point in
            CGPoint(
                x: point.x - boundingRect.origin.x,
                y: point.y - boundingRect.origin.y
            )
        }

        // Create widget with color and font
        let widget = TextPathWidget(
            text: pendingTextForPath,
            pathPoints: localPathPoints,
            frame: boundingRect,
            color: color,
            font: font
        )

        widget.selectionDelegate = self
        selectionManager.registerItem(widget)
        widgets.append(widget)
        contentView.addSubview(widget)
        contentView.bringSubviewToFront(widget)

        // Select the new widget
        selectionManager.selectItem(widget)
        hasUnsavedChanges = true
    }

    @objc dynamic func changeTemplate() {
        let actionSheet = UIAlertController(title: "배경 옵션", message: nil, preferredStyle: .actionSheet)

        let templates: [(name: String, style: BackgroundTemplateView.TemplateStyle, colors: [UIColor])] = [
            ("블루 그라데이션", .gradient1, [UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0), UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)]),
            ("퍼플 그라데이션", .gradient2, [UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0), UIColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 1.0)]),
            ("오렌지 그라데이션", .gradient3, [UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0), UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)]),
            ("그린 그라데이션", .gradient4, [UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0), UIColor(red: 0.4, green: 0.9, blue: 0.6, alpha: 1.0)]),
            ("다크", .dark, [UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0), UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)]),
            ("미니멀", .minimal, [.white])
        ]

        for template in templates {
            let action = UIAlertAction(title: template.name, style: .default) { [weak self] _ in
                self?.applyTemplate(template.style)
            }
            action.setValue(iconForGradient(colors: template.colors), forKey: "image")
            actionSheet.addAction(action)
        }

        // Random
        actionSheet.addAction(UIAlertAction(title: "랜덤", style: .default) { [weak self] _ in
            self?.backgroundTemplateView.applyRandomTemplate()
            self?.hasUnsavedChanges = true
        })

        // Custom
        actionSheet.addAction(UIAlertAction(title: "커스텀 그라데이션...", style: .default) { [weak self] _ in
            self?.presentCustomGradientPicker()
        })

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = backgroundTemplateButton
            popover.sourceRect = backgroundTemplateButton.bounds
        }

        present(actionSheet, animated: true)
    }

    private func presentCustomGradientPicker() {
        let picker = CustomGradientPickerViewController()
        picker.delegate = self

        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.medium()]
        }

        present(picker, animated: true)
    }

    private func iconForGradient(colors: [UIColor]) -> UIImage? {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()

            if colors.count > 1 {
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { $0.cgColor } as CFArray, locations: [0, 1])!
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            } else {
                colors.first?.setFill()
                path.fill()

                if colors.first == .white {
                    UIColor.systemGray4.setStroke()
                    path.lineWidth = 1
                    path.stroke()
                }
            }
        }

        return image.withRenderingMode(.alwaysOriginal)
    }

    private func applyTemplate(_ style: BackgroundTemplateView.TemplateStyle) {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        backgroundTemplateView.applyTemplate(style)
        dimOverlay.isHidden = true
        hasUnsavedChanges = true
    }

    // MARK: - Template Management
    
    func applyWidgetTemplate(_ template: WidgetTemplate) {
        // Override in subclasses
    }
    
    @objc dynamic func importTemplate() {
        documentPickerPurpose = .templateImport
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @objc dynamic func exportCurrentLayout() {
        let items = createTemplateItemsFromCurrentLayout()
        let canvasSize = contentView.bounds.size

        var backgroundImageAspectRatio: CGFloat? = nil
        if let image = backgroundImageView.image, !backgroundImageView.isHidden {
            backgroundImageAspectRatio = image.size.width / image.size.height
        }

        var backgroundTransformData: BackgroundTransformData? = nil
        if let transform = backgroundTransform {
            backgroundTransformData = BackgroundTransformData(
                scale: transform.scale,
                offsetX: transform.offset.x,
                offsetY: transform.offset.y
            )
        }

        let alert = UIAlertController(title: "템플릿 저장", message: "템플릿 이름과 설명을 입력하세요", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "템플릿 이름" }
        alert.addTextField { $0.placeholder = "설명 (선택사항)" }

        alert.addAction(UIAlertAction(title: "저장", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty else { return }
            let description = alert.textFields?[1].text ?? ""

            let template = WidgetTemplate(
                name: name,
                description: description,
                version: "2.0",
                items: items,
                canvasSize: WidgetTemplate.CanvasSize(width: canvasSize.width, height: canvasSize.height),
                backgroundImageAspectRatio: backgroundImageAspectRatio,
                backgroundTransform: backgroundTransformData
            )

            do {
                let fileURL = try TemplateManager.shared.exportTemplate(template)
                self?.shareTemplate(fileURL: fileURL)
            } catch {
                print("❌ Failed to export template: \(error)")
            }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
    
    func createTemplateItemsFromCurrentLayout() -> [WidgetItem] {
        var items: [WidgetItem] = []
        let canvasSize = contentView.bounds.size

        for widget in widgets {
            let frame = widget.frame
            var type: WidgetType?
            var color: String?
            var font: String?

            // Determine Widget Type (Generic detection)
            // Subclasses could override this, but we can try to include known types here
            
            // Running Widgets
            if let _ = widget as? RouteMapView { type = .routeMap } // Assuming generic RouteMapView type
            else if widget is DistanceWidget { type = .distance }
            else if widget is DurationWidget { type = .duration }
            else if widget is PaceWidget { type = .pace }
            else if widget is SpeedWidget { type = .speed }
            else if widget is CaloriesWidget { type = .calories }
            else if widget is DateWidget { type = .date }
            else if widget is TextWidget { type = .text }
            else if widget is LocationWidget { type = .location }
            else if widget is CurrentDateTimeWidget { type = .currentDateTime }
            
            // Climbing Widgets
            else if widget is ClimbingGymWidget { type = .climbingGym }
            else if widget is ClimbingDisciplineWidget { type = .climbingDiscipline }
            else if widget is ClimbingSessionWidget { type = .climbingSession }
            else if widget is ClimbingRoutesByColorWidget { type = .climbingRoutesByColor }

            if let selectable = widget as? Selectable {
                 color = TemplateManager.hexString(from: selectable.currentColor)
                 font = selectable.currentFontStyle.rawValue
            }

            if let widgetType = type {
                let item = TemplateManager.createRatioBasedItem(
                    type: widgetType,
                    frame: frame,
                    canvasSize: canvasSize,
                    color: color,
                    font: font
                )
                items.append(item)
            }
        }
        return items
    }
    
    func shareTemplate(fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = layoutTemplateButton
            popover.sourceRect = layoutTemplateButton.bounds
        }
        present(activityViewController, animated: true)
    }

    // MARK: - Helper Methods
    
    func applyItemStyles(to widget: any Selectable, item: WidgetItem) {
        if let colorHex = item.color, let color = TemplateManager.color(from: colorHex) {
            widget.applyColor(color)
        }

        if let fontName = item.font, let fontStyle = FontStyle(rawValue: fontName) {
            widget.applyFont(fontStyle)
        }
    }
    
    func constrainFrameToCanvas(_ frame: CGRect, canvasSize: CGSize, margin: CGFloat) -> CGRect {
        var newFrame = frame
        
        // Horizontal constraints
        if newFrame.minX < margin {
            newFrame.origin.x = margin
        } else if newFrame.maxX > canvasSize.width - margin {
            newFrame.origin.x = canvasSize.width - margin - newFrame.width
        }
        
        // Vertical constraints
        if newFrame.minY < margin {
            newFrame.origin.y = margin
        } else if newFrame.maxY > canvasSize.height - margin {
            newFrame.origin.y = canvasSize.height - margin - newFrame.height
        }
        
        return newFrame
    }

    func updateCanvasSize() {
        // Skip if view is not laid out yet
        guard view.bounds.width > 0 && view.bounds.height > 0 else { return }

        // Calculate canvas size based on available space and aspect ratio
        let availableWidth = view.bounds.width - 40 // 20pt padding on each side
        let maxHeight = view.bounds.height - 300 // Account for navigation, controls, toolbar, and padding

        let targetRatio = currentAspectRatio.ratio
        var canvasWidth: CGFloat
        var canvasHeight: CGFloat

        // Calculate size that fits within available space while maintaining ratio
        canvasWidth = availableWidth
        canvasHeight = canvasWidth * targetRatio

        if canvasHeight > maxHeight {
            canvasHeight = maxHeight
            canvasWidth = canvasHeight / targetRatio
        }

        // Ensure minimum size
        canvasWidth = max(canvasWidth, 200)
        canvasHeight = max(canvasHeight, 200)

        let newCanvasSize = CGSize(width: canvasWidth, height: canvasHeight)

        // Scale existing widgets if canvas size changed
        if previousCanvasSize.width > 0 && previousCanvasSize.height > 0 && previousCanvasSize != newCanvasSize {
            let scaleX = newCanvasSize.width / previousCanvasSize.width
            let scaleY = newCanvasSize.height / previousCanvasSize.height
            // Use area-preserving uniform scale for aspect-ratio-locked widgets (reversible)
            let uniformScale = sqrt(scaleX * scaleY)

            print("📐 Scaling widgets: \(scaleX) x \(scaleY), uniform: \(uniformScale)")

            // Scale individual widgets
            for widget in widgets {
                var newWidth = widget.frame.width * scaleX
                var newHeight = widget.frame.height * scaleY
                var newX = widget.frame.origin.x * scaleX
                var newY = widget.frame.origin.y * scaleY

                if widget is RouteMapView {
                    // Use uniform scale to maintain aspect ratio AND be reversible
                    newWidth = widget.frame.width * uniformScale
                    newHeight = widget.frame.height * uniformScale

                    // Center the widget in its new relative position
                    let oldCenter = CGPoint(x: widget.frame.midX, y: widget.frame.midY)
                    let newCenterX = oldCenter.x * scaleX
                    let newCenterY = oldCenter.y * scaleY

                    newX = newCenterX - (newWidth / 2)
                    newY = newCenterY - (newHeight / 2)
                }

                let newFrame = CGRect(
                    x: newX,
                    y: newY,
                    width: newWidth,
                    height: newHeight
                )
                widget.frame = newFrame

                // Update initialSize for stat widgets
                if let statWidget = widget as? BaseStatWidget {
                    statWidget.initialSize = newFrame.size
                    statWidget.updateFonts()
                    statWidget.layoutSubviews()
                }

                // Update initialSize for route map
                if let routeMap = widget as? RouteMapView {
                    routeMap.initialSize = newFrame.size
                    routeMap.layoutSubviews()
                }
            }
        }

        // Update constraints
        canvasWidthConstraint?.update(offset: canvasWidth)
        canvasHeightConstraint?.update(offset: canvasHeight)

        // Update background image frame if needed
        if let transform = backgroundTransform {
            applyBackgroundTransform(transform)
        } else if let image = backgroundImageView.image, backgroundImageView.frame == .zero {
             // Initial frame if no transform set yet
             backgroundImageView.frame = CGRect(origin: .zero, size: newCanvasSize)
        }

        // Store current size for next comparison
        previousCanvasSize = newCanvasSize

        print("📐 Canvas size updated: \(canvasWidth) x \(canvasHeight) (ratio: \(currentAspectRatio.displayName))")
    }
    
    func applyBackgroundTransform(_ transform: BackgroundTransform) {
        guard let image = backgroundImageView.image else { return }

        // Reset transform first to ensure frame calculations are correct
        backgroundImageView.transform = .identity
        
        let canvasSize = contentView.bounds.size
        let imageSize = image.size

        // Calculate base scale to fill canvas (Aspect Fill logic)
        let widthRatio = canvasSize.width / imageSize.width
        let heightRatio = canvasSize.height / imageSize.height
        let baseScale = max(widthRatio, heightRatio)

        // Apply user's zoom on top of base scale
        let finalScale = baseScale * transform.scale
        
        // Calculate the final size of the image
        let scaledWidth = imageSize.width * finalScale
        let scaledHeight = imageSize.height * finalScale
        
        // Calculate position
        let x = -transform.offset.x
        let y = -transform.offset.y
        
        // Apply frame
        backgroundImageView.frame = CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
        
        print("🖼️ Applied Background Frame: \(backgroundImageView.frame)")
    }
    
    func createToolbarButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.3, alpha: 0.8)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: action, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
        return button
    }
    
    func showToast(_ message: String) {
        toastLabel.text = "  \(message)  "
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.toastLabel.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut) {
                self.toastLabel.alpha = 0
            }
        }
    }
    
    func setupDefaultBackground() {
        backgroundTemplateView.applyTemplate(.gradient1)
        backgroundImageView.isHidden = true
    }
    
    // MARK: - Notifications
    @objc func handleWidgetDidMove() {
        hasUnsavedChanges = true
    }
    
    
    // MARK: - Widget Grouping and Management
    
    @objc func groupSelectedWidgets() {
        let selectedItems = selectionManager.getSelectedItems()
        let widgetsToGroup = selectedItems.compactMap { $0 as? UIView }.filter { !($0 is TemplateGroupView) }

        guard widgetsToGroup.count >= 2 else { return }

        // Check for group conflicts
        let conflictResult = GroupManager.shared.canGroupWidgets(widgetsToGroup)
        if !conflictResult.isAllowed {
            showGroupConflictAlert(reason: conflictResult.denialReason ?? "그룹화할 수 없습니다")
            return
        }

        // IMPORTANT: Hide selection state BEFORE moving widgets to group
        // This removes resize handles from contentView
        for widget in widgetsToGroup {
            if let selectable = widget as? Selectable {
                selectable.hideSelectionState()
            }
        }

        // Determine the group type based on widget origins
        let groupType = determineGroupTypeForWidgets(widgetsToGroup)

        // Calculate bounding frame for all selected widgets
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude

        for widget in widgetsToGroup {
            minX = min(minX, widget.frame.minX)
            minY = min(minY, widget.frame.minY)
            maxX = max(maxX, widget.frame.maxX)
            maxY = max(maxY, widget.frame.maxY)
        }

        // Add padding
        let padding: CGFloat = 16
        let groupFrame = CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + (padding * 2),
            height: maxY - minY + (padding * 2)
        )

        // Create group
        let group = TemplateGroupView(items: widgetsToGroup, frame: groupFrame, groupType: groupType)
        group.groupDelegate = self
        group.selectionDelegate = self
        selectionManager.registerItem(group)

        contentView.addSubview(group)
        templateGroups.append(group)
        hasUnsavedChanges = true

        // Remove widgets from main widgets array (they're now in the group)
        for widget in widgetsToGroup {
            widgets.removeAll { $0 === widget }
            if let selectable = widget as? Selectable {
                selectionManager.unregisterItem(selectable)
            }
        }

        // Clear selection state without hiding toolbar (manual control)
        for identifier in selectionManager.selectedItemIdentifiers {
            if let item = selectionManager.getAllItems().first(where: { $0.itemIdentifier == identifier }) {
                item.hideSelectionState()
            }
        }

        // Directly manipulate selection state for the new group
        selectionManager.clearSelectionForGroupCreation()

        // Add group to selection
        selectionManager.addToMultiSelect(group)
        group.showSelectionState()

        // Update toolbar for group-only mode
        updateMultiSelectToolbarState()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func determineGroupTypeForWidgets(_ widgets: [UIView]) -> WidgetGroupType {
        // Check if any widget is from an imported group
        for widget in widgets {
            if let parentGroup = GroupManager.shared.findParentGroup(for: widget) {
                if parentGroup.groupType == .importedRecord {
                    return .importedRecord
                }
            }
        }
        return .myRecord
    }
    
    private func showGroupConflictAlert(reason: String) {
        let alert = UIAlertController(
            title: "그룹화 불가",
            message: reason,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    @objc func ungroupSelectedWidget() {
        // Check both multi-select and single selection modes
        let selectedItems = selectionManager.getSelectedItems()
        let selectedGroup: TemplateGroupView?

        if let group = selectedItems.first(where: { $0 is TemplateGroupView }) as? TemplateGroupView {
            selectedGroup = group
        } else if let group = selectionManager.currentlySelectedItem as? TemplateGroupView {
            selectedGroup = group
        } else {
            return
        }

        guard let groupToUngroup = selectedGroup else { return }

        // Ungroup items
        let ungroupedItems = groupToUngroup.ungroupItems(to: contentView)

        // Re-register widgets
        for item in ungroupedItems {
            widgets.append(item)
            if var selectable = item as? Selectable {
                selectable.selectionDelegate = self
                selectionManager.registerItem(selectable)
            }
        }

        // Remove group
        selectionManager.unregisterItem(groupToUngroup)
        templateGroups.removeAll { $0 === groupToUngroup }
        groupToUngroup.removeFromSuperview()
        hasUnsavedChanges = true

        // Exit multi-select mode
        selectionManager.exitMultiSelectMode()
        hideMultiSelectToolbar()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @objc func exitMultiSelectMode() {
        selectionManager.exitMultiSelectMode()
        hideMultiSelectToolbar()
    }
    
    @objc func deleteSelectedItem() {
        guard let selectedItem = selectionManager.currentlySelectedItem else { return }

        let alert = UIAlertController(
            title: "아이템 삭제",
            message: "선택한 아이템을 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func performDelete() {
        guard let selectedItem = selectionManager.currentlySelectedItem as? UIView else { return }

        // Remove from selection manager
        selectionManager.deselectAll()
        selectionManager.unregisterItem(selectedItem as! Selectable)

        // Remove from widgets or templateGroups array
        widgets.removeAll { $0 === selectedItem }
        templateGroups.removeAll { $0 === selectedItem }
        hasUnsavedChanges = true

        // Remove from view hierarchy
        UIView.animate(withDuration: 0.25, animations: {
            selectedItem.alpha = 0
            selectedItem.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            selectedItem.removeFromSuperview()
        }

        updateToolbarItemsState()
    }
    
    @objc func showColorPicker() {
        // Check both multi-select and single selection modes
        let selectedItems = selectionManager.getSelectedItems()
        let currentColor: UIColor

        if let firstItem = selectedItems.first {
            currentColor = firstItem.currentColor
        } else if let selectedItem = selectionManager.currentlySelectedItem {
            currentColor = selectedItem.currentColor
        } else {
            return
        }

        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = currentColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }

    @objc func showFontPicker() {
        // Check both multi-select and single selection modes
        let selectedItems = selectionManager.getSelectedItems()
        let hasValidSelection = !selectedItems.isEmpty || selectionManager.currentlySelectedItem != nil

        guard hasValidSelection else { return }

        let actionSheet = UIAlertController(title: "폰트 스타일 선택", message: nil, preferredStyle: .actionSheet)

        for fontStyle in FontStyle.allCases {
            actionSheet.addAction(UIAlertAction(title: fontStyle.displayName, style: .default) { [weak self] _ in
                self?.applyFontToSelection(fontStyle)
            })
        }

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = fontPickerButton
            popover.sourceRect = fontPickerButton.bounds
        }

        present(actionSheet, animated: true)
    }

    private func applyFontToSelection(_ fontStyle: FontStyle) {
        let selectedItems = selectionManager.getSelectedItems()

        if !selectedItems.isEmpty {
            // Apply font to all selected items
            for item in selectedItems {
                if let group = item as? TemplateGroupView {
                    // Apply font to all widgets inside the group
                    for widget in group.groupedItems {
                        if let statWidget = widget as? BaseStatWidget {
                            statWidget.applyFont(fontStyle)
                            FontPreferences.shared.saveFont(fontStyle, for: statWidget.itemIdentifier)
                        }
                        if let textWidget = widget as? TextWidget {
                            textWidget.applyFont(fontStyle)
                            FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
                        }
                    }
                    // Also update the group's font style
                    group.applyFont(fontStyle)
                } else if let statWidget = item as? BaseStatWidget {
                    statWidget.applyFont(fontStyle)
                    FontPreferences.shared.saveFont(fontStyle, for: statWidget.itemIdentifier)
                } else if let textWidget = item as? TextWidget {
                    textWidget.applyFont(fontStyle)
                    FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
                }
            }
        } else if let selectedItem = selectionManager.currentlySelectedItem {
            // Single selection mode (fallback)
            if let statWidget = selectedItem as? BaseStatWidget {
                statWidget.applyFont(fontStyle)
                FontPreferences.shared.saveFont(fontStyle, for: statWidget.itemIdentifier)
            } else if let textWidget = selectedItem as? TextWidget {
                textWidget.applyFont(fontStyle)
                FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
            } else if let group = selectedItem as? TemplateGroupView {
                for widget in group.groupedItems {
                    if let statWidget = widget as? BaseStatWidget {
                        statWidget.applyFont(fontStyle)
                        FontPreferences.shared.saveFont(fontStyle, for: statWidget.itemIdentifier)
                    }
                    if let textWidget = widget as? TextWidget {
                        textWidget.applyFont(fontStyle)
                        FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
                    }
                }
                group.applyFont(fontStyle)
            }
        }
        hasUnsavedChanges = true
    }

    func showDimOverlayOption() {
        let alert = UIAlertController(
            title: "딤 효과",
            message: "위젯이 잘 보이도록 어두운 오버레이를 추가하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            self?.dimOverlay.isHidden = false
            self?.hasUnsavedChanges = true
        })

        alert.addAction(UIAlertAction(title: "추가 안함", style: .cancel) { [weak self] _ in
            self?.dimOverlay.isHidden = true
        })

        present(alert, animated: true)
    }
    
    
    @objc func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: contentView)

        // Check if tapped on any widget or route map
        for widget in widgets {
            if widget.frame.contains(location) {
                return // Let the widget handle the tap
            }
        }

        // Check if tapped on any template group
        for group in templateGroups {
            if group.frame.contains(location) {
                return // Let the group handle the tap
            }
        }

        // Tapped on background, deselect all
        selectionManager.deselectAll()
    }
    
    func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        contentView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let location = gesture.location(in: contentView)

        // Check if long-pressed on a widget
        for widget in widgets {
            if widget.frame.contains(location), let selectable = widget as? Selectable {
                // Enter multi-select mode
                selectionManager.enterMultiSelectMode()
                selectionManager.selectItem(selectable)
                showMultiSelectToolbar()

                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                return
            }
        }

        // Check template groups
        for group in templateGroups {
            if group.frame.contains(location) {
                selectionManager.enterMultiSelectMode()
                selectionManager.selectItem(group)
                showMultiSelectToolbar()

                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                return
            }
        }
    }
    
    // MARK: - TemplateGroupDelegate
    
    func templateGroupDidConfirm(_ group: TemplateGroupView) {
        // Group confirmed - just hide check button
        hasUnsavedChanges = true
    }
    
    func templateGroupDidRequestUngroup(_ group: TemplateGroupView) {
        // Imported group requested ungroup
        ungroupSelectedWidget()
    }
    
    // MARK: - Multi-Select Toolbar Helpers
    
    func showMultiSelectToolbar() {
        self.multiSelectToolbar.isHidden = false
        self.multiSelectToolbar.alpha = 1.0
        self.bottomFloatingToolbar.alpha = 0.0
        self.bottomFloatingToolbar.isHidden = true
    }
    
    func hideMultiSelectToolbar() {
        self.multiSelectToolbar.isHidden = true
        self.multiSelectToolbar.alpha = 0.0
        
        let hasSelection = selectionManager.hasSelection
        self.bottomFloatingToolbar.isHidden = !hasSelection
        self.bottomFloatingToolbar.alpha = hasSelection ? 1.0 : 0.0
    }
    
    func updateMultiSelectToolbarState() {
        let selectedItems = selectionManager.getSelectedItems()
        multiSelectCountLabel.text = "\(selectedItems.count)개 선택"
        
        // Group logic: can group if > 1 and not already grouped (simplified)
        // Check if any selected item is a group
        let hasGroup = selectedItems.contains { $0 is TemplateGroupView }
        let canGroup = selectedItems.count > 1 && !hasGroup
        
        groupButton.isEnabled = canGroup
        groupButton.alpha = canGroup ? 1.0 : 0.5
        
        // Ungroup logic: can ungroup if single group selected
        let canUngroup = selectedItems.count == 1 && hasGroup
        ungroupButton.isEnabled = canUngroup
        ungroupButton.alpha = canUngroup ? 1.0 : 0.5
    }
    
    func updateToolbarItemsState() {
        let hasSelection = selectionManager.hasSelection
        
        UIView.animate(withDuration: 0.25) {
            self.bottomFloatingToolbar.isHidden = !hasSelection
            self.bottomFloatingToolbar.alpha = hasSelection ? 1.0 : 0.0
        }
        
        colorPickerButton.isEnabled = hasSelection
        deleteItemButton.isEnabled = hasSelection
    }
}

// MARK: - UIScrollViewDelegate
extension BaseWorkoutDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}

// MARK: - SelectionManagerDelegate
extension BaseWorkoutDetailViewController: SelectionManagerDelegate {
    func selectionManager(_ manager: SelectionManager, didSelect item: Selectable) {
        updateToolbarItemsState()
        
        // If a group is selected, automatically enter multi-select mode and show toolbar
        if item is TemplateGroupView {
            // Enter multi-select mode to add the group to selectedItemIdentifiers
            if !manager.isMultiSelectMode {
                manager.enterMultiSelectMode()
            }
            showMultiSelectToolbar()
            updateMultiSelectToolbarState()
        } else if manager.isMultiSelectMode {
            updateMultiSelectToolbarState()
        }
    }
    
    func selectionManager(_ manager: SelectionManager, didDeselect item: Selectable) {
        updateToolbarItemsState()
        
        // Check current selection state
        let selectedItems = manager.getSelectedItems()
        let hasSelectedGroup = selectedItems.contains { $0 is TemplateGroupView }
        
        if selectedItems.isEmpty && !manager.isMultiSelectMode {
            hideMultiSelectToolbar()
        } else if manager.isMultiSelectMode || hasSelectedGroup {
            updateMultiSelectToolbarState()
        }
    }
    
    func selectionManagerDidDeselectAll(_ manager: SelectionManager) {
        updateToolbarItemsState()
        hideMultiSelectToolbar()
    }
    
    func selectionManager(_ manager: SelectionManager, didSelectMultiple items: [Selectable]) {
        updateToolbarItemsState()
        updateMultiSelectToolbarState()
    }
    
    func selectionManager(_ manager: SelectionManager, didEnterMultiSelectMode: Bool) {
        if didEnterMultiSelectMode {
            showMultiSelectToolbar()
            updateMultiSelectToolbarState()
        } else {
            hideMultiSelectToolbar()
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension BaseWorkoutDetailViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }

        let shouldStopAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        switch documentPickerPurpose {
        case .templateImport:
            handleImportedTemplateFile(at: fileURL)
        }
    }
    
    internal func handleImportedTemplateFile(at fileURL: URL) {
        do {
            let template = try TemplateManager.shared.importTemplate(from: fileURL)
            let alert = UIAlertController(
                title: "템플릿 가져오기 성공",
                message: "'\(template.name)' 템플릿을 적용하시겠습니까?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "적용", style: .default) { [weak self] _ in
                self?.applyWidgetTemplate(template)
            })
            alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
            present(alert, animated: true)
        } catch {
            let alert = UIAlertController(title: "가져오기 실패", message: "오류: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - SelectionDelegate
extension BaseWorkoutDetailViewController: SelectionDelegate {
    func itemWasSelected(_ item: Selectable) {
        if selectionManager.isMultiSelectMode {
            selectionManager.toggleSelection(item)
        } else {
            selectionManager.selectItem(item)
        }
        updateToolbarItemsState()
    }

    func itemWasDeselected(_ item: Selectable) {
        if selectionManager.isMultiSelectMode {
            selectionManager.toggleSelection(item)
        } else {
            selectionManager.deselectItem(item)
        }
        updateToolbarItemsState()
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension BaseWorkoutDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let selectedColor = viewController.selectedColor

        // Check if in multi-select mode (includes group selection)
        let selectedItems = selectionManager.getSelectedItems()

        if !selectedItems.isEmpty {
            // Apply color to all selected items
            for item in selectedItems {
                if let group = item as? TemplateGroupView {
                    // Apply color to all widgets inside the group
                    for widget in group.groupedItems {
                        if var selectable = widget as? Selectable {
                            selectable.applyColor(selectedColor)
                            ColorPreferences.shared.saveColor(selectedColor, for: selectable.itemIdentifier)
                        }
                    }
                } else {
                    var mutableItem = item
                    mutableItem.applyColor(selectedColor)
                    ColorPreferences.shared.saveColor(selectedColor, for: item.itemIdentifier)
                }
            }
        } else if var selectedItem = selectionManager.currentlySelectedItem {
            // Single selection mode (fallback)
            selectedItem.applyColor(selectedColor)
            ColorPreferences.shared.saveColor(selectedColor, for: selectedItem.itemIdentifier)
        }
        hasUnsavedChanges = true
    }
}

// MARK: - PHPickerViewControllerDelegate
extension BaseWorkoutDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let image = object as? UIImage {
                    self?.presentBackgroundEditor(with: image)
                }
            }
        }
    }

    private func presentBackgroundEditor(with image: UIImage) {
        let editor = BackgroundImageEditorViewController(image: image, initialTransform: backgroundTransform, canvasSize: contentView.bounds.size)
        editor.delegate = self

        let navController = UINavigationController(rootViewController: editor)
        navController.modalPresentationStyle = .pageSheet

        // Set preferred size for iPad
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        present(navController, animated: true)
    }
}

// MARK: - BackgroundImageEditorDelegate
extension BaseWorkoutDetailViewController: BackgroundImageEditorDelegate {
    func backgroundImageEditor(_ editor: BackgroundImageEditorViewController, didFinishEditing image: UIImage, transform: BackgroundTransform) {
        backgroundImageView.image = image
        backgroundImageView.isHidden = false
        backgroundTemplateView.isHidden = true
        backgroundTransform = transform
        hasUnsavedChanges = true

        // Apply transform to background image
        applyBackgroundTransform(transform)

        // Show dim overlay option
        showDimOverlayOption()
    }
}

// MARK: - CustomGradientPickerDelegate
extension BaseWorkoutDetailViewController: CustomGradientPickerDelegate {
    func customGradientPicker(_ picker: CustomGradientPickerViewController, didSelectColors colors: [UIColor], direction: GradientDirection) {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
        backgroundTemplateView.applyCustomGradient(colors: colors, direction: direction)
        hasUnsavedChanges = true
    }
}
