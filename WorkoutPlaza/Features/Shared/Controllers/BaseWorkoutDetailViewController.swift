//
//  BaseWorkoutDetailViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Text Path Preview View
class TextPathPreviewView: UIView {
    var points: [CGPoint] = []
    var textToRepeat: String = ""
    var textFont: UIFont = .boldSystemFont(ofSize: 20)
    var textColor: UIColor = .white
    private let letterSpacing: CGFloat = 2.0

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              points.count >= 2,
              !textToRepeat.isEmpty else { return }

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: textColor
        ]

        var segmentLengths: [CGFloat] = []
        var cumulativeDistances: [CGFloat] = [0.0]

        for i in 0..<(points.count - 1) {
            let dx = points[i + 1].x - points[i].x
            let dy = points[i + 1].y - points[i].y
            let length = sqrt(dx * dx + dy * dy)
            segmentLengths.append(length)
            cumulativeDistances.append(cumulativeDistances.last! + length)
        }

        let totalPathLength = cumulativeDistances.last ?? 0
        guard totalPathLength > 0 else { return }

        let characters = Array(textToRepeat)
        var characterWidths: [CGFloat] = []

        for char in characters {
            let charString = String(char)
            let size = charString.size(withAttributes: textAttributes)
            characterWidths.append(size.width)
        }

        var currentDistance: CGFloat = 0.0
        var charIndex = 0

        while currentDistance < totalPathLength && charIndex < characters.count * 100 {
            let char = characters[charIndex % characters.count]
            let charString = String(char)
            let charWidth = characterWidths[charIndex % characters.count]
            let charSize = charString.size(withAttributes: textAttributes)

            let charCenterDistance = currentDistance + charWidth / 2.0

            if charCenterDistance > totalPathLength {
                break
            }

            var segmentIndex = 0
            for i in 0..<segmentLengths.count {
                if charCenterDistance <= cumulativeDistances[i + 1] {
                    segmentIndex = i
                    break
                }
            }

            let startPoint = points[segmentIndex]
            let endPoint = points[segmentIndex + 1]
            let segmentLength = segmentLengths[segmentIndex]

            guard segmentLength > 0 else {
                charIndex += 1
                continue
            }

            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y

            let distanceWithinSegment = charCenterDistance - cumulativeDistances[segmentIndex]

            let normalizedDx = dx / segmentLength
            let normalizedDy = dy / segmentLength

            let charX = startPoint.x + normalizedDx * distanceWithinSegment
            let charY = startPoint.y + normalizedDy * distanceWithinSegment

            let angle = atan2(dy, dx)

            context.saveGState()
            context.translateBy(x: charX, y: charY)
            context.rotate(by: angle)

            let drawRect = CGRect(
                x: -charWidth / 2.0,
                y: -charSize.height / 2.0,
                width: charWidth,
                height: charSize.height
            )
            charString.draw(in: drawRect, withAttributes: textAttributes)

            context.restoreGState()

            currentDistance += charWidth + letterSpacing
            charIndex += 1
        }
    }
}
import PhotosUI

class BaseWorkoutDetailViewController: UIViewController, TemplateGroupDelegate, UIGestureRecognizerDelegate, TextWidgetDelegate {

    // MARK: - Constants (Light Mode for Card Design)
    private enum Constants {
        static let canvasBackgroundColor = UIColor.white
        static let canvasBorderColor = UIColor(white: 0.9, alpha: 1.0).cgColor

        static let toolbarBackgroundColor = UIColor.white.withAlphaComponent(0.95)
        static let multiSelectToolbarBackgroundColor = UIColor.white.withAlphaComponent(0.98)
        static let multiSelectBorderColor = ColorSystem.primaryGreen.withAlphaComponent(0.5).cgColor

        static let toastBackgroundColor = UIColor(white: 0.95, alpha: 0.95)

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
    
    // MARK: - Properties

    // State
    var widgets: [UIView] = []
    var previousCanvasSize: CGSize = .zero
    var currentAspectRatio: AspectRatio = .portrait4_5 // Default 4:5
    var hasUnsavedChanges: Bool = false

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
        label.text = "위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleWidgetDidMove), name: .widgetDidMove, object: nil)

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
        contentView.addSubview(watermarkImageView)
        contentView.addSubview(textPathDrawingOverlayView)

        view.addSubview(topRightToolbar)
        view.addSubview(bottomFloatingToolbar)
        view.addSubview(multiSelectToolbar)
        view.addSubview(textPathDrawingToolbar)
        textPathDrawingToolbar.addSubview(textPathConfirmButton)
        textPathDrawingToolbar.addSubview(textPathRedrawButton)
        view.addSubview(toastLabel)
        view.addSubview(textPathColorPanel)
        view.addSubview(textPathFontPanel)
        view.addSubview(textPathSizePanel)

        setupTopRightToolbar()
        setupBottomFloatingToolbar()
        setupTextPathDrawingToolbar()
        setupTextPathFloatingPanels()
        
        // Background tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tapGesture)
        
        updateCanvasSize()
    }
    
    func setupConstraints() {
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.instructionTopOffset)
            make.leading.trailing.equalToSuperview().inset(Constants.Layout.horizontalPadding)
        }
        
        canvasContainerView.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(Constants.Layout.canvasTopOffset)
            make.centerX.equalToSuperview()
            // Initial constraints, will be updated by updateCanvasSize
            canvasWidthConstraint = make.width.equalTo(Constants.Layout.canvasInitialWidth).constraint
            canvasHeightConstraint = make.height.equalTo(Constants.Layout.canvasInitialHeight).constraint
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
        
        watermarkImageView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(Constants.Layout.watermarkInset)
            make.trailing.equalToSuperview().inset(Constants.Layout.watermarkInset)
            make.width.equalTo(Constants.Layout.watermarkSize)
            make.height.equalTo(Constants.Layout.watermarkSize)
        }

        textPathDrawingOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        topRightToolbar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.topToolbarTopOffset)
            make.trailing.equalToSuperview().inset(Constants.Layout.topToolbarTrailingMargin)
        }
        
        bottomFloatingToolbar.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.bottomToolbarBottomOffset)
            make.centerX.equalToSuperview()
            make.height.equalTo(Constants.Layout.bottomToolbarHeight)
        }
        
        multiSelectToolbar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.multiSelectToolbarBottomOffset)
            make.height.equalTo(Constants.Layout.multiSelectToolbarHeight)
            make.width.equalTo(Constants.Layout.multiSelectToolbarWidth)
        }
        
        toastLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.toastTopOffset)
            make.width.greaterThanOrEqualTo(100)
            make.height.equalTo(Constants.Layout.toastHeight)
        }

        textPathDrawingToolbar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(Constants.Layout.textPathToolbarHeight)
        }

        textPathConfirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(8)
            make.size.equalTo(40)
        }

        textPathRedrawButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(8)
            make.size.equalTo(40)
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
            make.edges.equalToSuperview().inset(Constants.Layout.bottomToolbarPadding)
        }
    }

    func setupTextPathDrawingToolbar() {
        let availableColors: [UIColor] = [
            .white, .systemYellow, .systemOrange, .systemPink,
            .systemRed, .systemGreen, .systemBlue, .systemPurple
        ]

        let availableFonts: [(name: String, font: UIFont)] = [
            ("기본", .boldSystemFont(ofSize: 20)),
            ("얇게", .systemFont(ofSize: 20, weight: .light)),
            ("둥글게", .systemFont(ofSize: 20, weight: .medium)),
            ("굵게", .systemFont(ofSize: 20, weight: .black))
        ]

        // MARK: - Main Control Buttons
        // Color Button (Circle)
        let colorButtonContainer = UIView()
        let colorLabel = UILabel()
        colorLabel.text = "색상"
        colorLabel.textColor = .white
        colorLabel.font = .systemFont(ofSize: 11, weight: .medium)
        colorLabel.textAlignment = .center

        let textPathColorMainButton = UIButton(type: .custom)
        textPathColorMainButton.backgroundColor = .white
        textPathColorMainButton.layer.cornerRadius = 16
        textPathColorMainButton.layer.borderWidth = 2
        textPathColorMainButton.layer.borderColor = UIColor.gray.cgColor
        textPathColorMainButton.tag = 9000
        textPathColorMainButton.addTarget(self, action: #selector(textPathColorMainButtonTapped(_:)), for: .touchUpInside)

        colorButtonContainer.addSubview(textPathColorMainButton)
        colorButtonContainer.addSubview(colorLabel)

        colorButtonContainer.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
        textPathColorMainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.size.equalTo(32)
        }
        colorLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(textPathColorMainButton.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }

        // Font Button
        let fontButtonContainer = UIView()
        let fontLabel = UILabel()
        fontLabel.text = "폰트"
        fontLabel.textColor = .white
        fontLabel.font = .systemFont(ofSize: 11, weight: .medium)
        fontLabel.textAlignment = .center

        let textPathFontMainButton = UIButton(type: .system)
        textPathFontMainButton.setTitle("기본", for: .normal)
        textPathFontMainButton.setTitleColor(.white, for: .normal)
        textPathFontMainButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        textPathFontMainButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        textPathFontMainButton.layer.cornerRadius = 8
        textPathFontMainButton.layer.borderWidth = 2
        textPathFontMainButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        textPathFontMainButton.tag = 9001
        textPathFontMainButton.addTarget(self, action: #selector(textPathFontMainButtonTapped(_:)), for: .touchUpInside)

        fontButtonContainer.addSubview(textPathFontMainButton)
        fontButtonContainer.addSubview(fontLabel)

        fontButtonContainer.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
        textPathFontMainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(55)
            make.height.equalTo(32)
        }
        fontLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(textPathFontMainButton.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }

        // Size Button
        let sizeButtonContainer = UIView()
        let sizeLabel = UILabel()
        sizeLabel.text = "크기"
        sizeLabel.textColor = .white
        sizeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        sizeLabel.textAlignment = .center

        let textPathSizeMainButton = UIButton(type: .system)
        textPathSizeMainButton.setTitle("20", for: .normal)
        textPathSizeMainButton.setTitleColor(.white, for: .normal)
        textPathSizeMainButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        textPathSizeMainButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        textPathSizeMainButton.layer.cornerRadius = 8
        textPathSizeMainButton.layer.borderWidth = 2
        textPathSizeMainButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        textPathSizeMainButton.tag = 9002
        textPathSizeMainButton.addTarget(self, action: #selector(textPathSizeMainButtonTapped(_:)), for: .touchUpInside)

        sizeButtonContainer.addSubview(textPathSizeMainButton)
        sizeButtonContainer.addSubview(sizeLabel)

        sizeButtonContainer.snp.makeConstraints { make in
            make.width.equalTo(50)
        }
        textPathSizeMainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(45)
            make.height.equalTo(32)
        }
        sizeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(textPathSizeMainButton.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }

        // Mode Button (자유곡선/직선 토글)
        let modeButtonContainer = UIView()
        let modeLabel = UILabel()
        modeLabel.text = "모드"
        modeLabel.textColor = .white
        modeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        modeLabel.textAlignment = .center

        let textPathModeMainButton = UIButton(type: .system)
        textPathModeMainButton.setImage(UIImage(systemName: "scribble"), for: .normal)
        textPathModeMainButton.tintColor = .white
        textPathModeMainButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        textPathModeMainButton.layer.cornerRadius = 16
        textPathModeMainButton.layer.borderWidth = 2
        textPathModeMainButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        textPathModeMainButton.tag = 9003
        textPathModeMainButton.addTarget(self, action: #selector(textPathModeButtonTapped(_:)), for: .touchUpInside)

        modeButtonContainer.addSubview(textPathModeMainButton)
        modeButtonContainer.addSubview(modeLabel)

        modeButtonContainer.snp.makeConstraints { make in
            make.width.equalTo(50)
        }
        textPathModeMainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.size.equalTo(32)
        }
        modeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(textPathModeMainButton.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }

        let buttonStack = UIStackView(arrangedSubviews: [modeButtonContainer, colorButtonContainer, fontButtonContainer, sizeButtonContainer])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 32
        buttonStack.alignment = .top
        buttonStack.distribution = .fill

        textPathDrawingToolbar.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.lessThanOrEqualToSuperview().offset(-20)
        }

        // Setup button actions
        textPathConfirmButton.addTarget(self, action: #selector(textPathConfirmTapped), for: .touchUpInside)
        textPathRedrawButton.addTarget(self, action: #selector(textPathRedrawTapped), for: .touchUpInside)
    }

    func setupTextPathFloatingPanels() {
        let availableColors: [UIColor] = [
            .white, .systemYellow, .systemOrange, .systemPink,
            .systemRed, .systemGreen, .systemBlue, .systemPurple
        ]

        let availableFonts: [(name: String, font: UIFont)] = [
            ("기본", .boldSystemFont(ofSize: 20)),
            ("얇게", .systemFont(ofSize: 20, weight: .light)),
            ("둥글게", .systemFont(ofSize: 20, weight: .medium)),
            ("굵게", .systemFont(ofSize: 20, weight: .black))
        ]

        // Color Panel Content

        let colorScrollView = UIScrollView()
        colorScrollView.showsHorizontalScrollIndicator = false
        colorScrollView.alwaysBounceHorizontal = true
        
        let colorStackView = UIStackView()
        colorStackView.axis = .horizontal
        colorStackView.spacing = 16
        colorStackView.alignment = .center
        
        textPathColorButtons.removeAll()

        for (index, color) in availableColors.enumerated() {
            let button = UIButton(type: .custom)
            button.backgroundColor = color
            button.layer.cornerRadius = 16
            button.layer.borderWidth = 3
            button.layer.borderColor = UIColor.clear.cgColor
            button.tag = index
            button.addTarget(self, action: #selector(textPathColorButtonTapped(_:)), for: .touchUpInside)

            button.snp.makeConstraints { make in
                make.size.equalTo(32)
            }

            textPathColorButtons.append(button)
            colorStackView.addArrangedSubview(button)
        }

        // Add indicators
        let leftIndicator = UIImageView(image: UIImage(systemName: "chevron.left"))
        leftIndicator.tintColor = UIColor.white.withAlphaComponent(0.5)
        leftIndicator.contentMode = .scaleAspectFit
        
        let rightIndicator = UIImageView(image: UIImage(systemName: "chevron.right"))
        rightIndicator.tintColor = UIColor.white.withAlphaComponent(0.5)
        rightIndicator.contentMode = .scaleAspectFit
        
        textPathColorPanel.addSubview(leftIndicator)
        textPathColorPanel.addSubview(rightIndicator)
        textPathColorPanel.addSubview(colorScrollView)
        
        colorScrollView.addSubview(colorStackView)
        
        leftIndicator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(6)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        
        rightIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        
        colorScrollView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(leftIndicator.snp.trailing).offset(4)
            make.trailing.equalTo(rightIndicator.snp.leading).offset(-4)
        }
        
        colorStackView.snp.makeConstraints { make in
            make.edges.equalTo(colorScrollView.contentLayoutGuide)
            make.height.equalTo(colorScrollView.frameLayoutGuide)
            make.leading.trailing.equalToSuperview().inset(4) // Padding inside scroll view
        }

        // Font Panel Content
        let fontStackView = UIStackView()
        fontStackView.axis = .horizontal
        fontStackView.spacing = 8
        fontStackView.alignment = .center
        fontStackView.distribution = .fillEqually
        
        textPathFontButtons.removeAll()

        for (index, fontInfo) in availableFonts.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(fontInfo.name, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            button.layer.cornerRadius = 8
            button.tag = index
            button.addTarget(self, action: #selector(textPathFontButtonTapped(_:)), for: .touchUpInside)

            textPathFontButtons.append(button)
            fontStackView.addArrangedSubview(button)
        }

        textPathFontPanel.addSubview(fontStackView)
        fontStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        // Size Panel Content
        let sliderContainer = UIView()
        let fontSizeSlider = UISlider()
        fontSizeSlider.minimumValue = 8
        fontSizeSlider.maximumValue = 40
        fontSizeSlider.value = Float(textPathSelectedFontSize)
        fontSizeSlider.minimumTrackTintColor = .white
        fontSizeSlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        fontSizeSlider.addTarget(self, action: #selector(textPathFontSizeChanged(_:)), for: .valueChanged)
        
        let fontSizeLabel = UILabel()
        fontSizeLabel.text = "\(Int(textPathSelectedFontSize))"
        fontSizeLabel.textColor = .white
        fontSizeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        fontSizeLabel.textAlignment = .center
        fontSizeLabel.tag = 999

        let sizeIcon = UIImageView(image: UIImage(systemName: "textformat.size"))
        sizeIcon.tintColor = .white
        sizeIcon.contentMode = .scaleAspectFit
        
        sliderContainer.addSubview(sizeIcon)
        sliderContainer.addSubview(fontSizeSlider)
        sliderContainer.addSubview(fontSizeLabel)
        
        sizeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        fontSizeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(30)
        }
        fontSizeSlider.snp.makeConstraints { make in
            make.leading.equalTo(sizeIcon.snp.trailing).offset(12)
            make.trailing.equalTo(fontSizeLabel.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        
        textPathSizePanel.addSubview(sliderContainer)
        sliderContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.height.equalTo(40)
            make.width.equalTo(200)
        }

        // Initial selection
        updateTextPathColorSelection()
        updateTextPathFontSelection()
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

        // 2. Collect ALL widgets (both top-level and inside groups)
        var allWidgets: [UIView] = widgets
        for group in templateGroups {
            allWidgets.append(contentsOf: group.groupedItems)
        }

        // 3. Create SavedWidgetState objects
        let savedWidgets = allWidgets.compactMap { widget -> SavedWidgetState? in
            let frame = widget.frame
            let className = String(describing: type(of: widget))
            
            // Use stable identifier from Selectable if available
            let identifier: String
            if let selectable = widget as? Selectable {
                identifier = selectable.itemIdentifier
            } else {
                identifier = UUID().uuidString // Fallback (shouldn't happen for valid widgets)
            }

            var text: String?
            var fontName: String?
            var fontSize: CGFloat?
            var fontStyle: String?
            var textColor: String?
            var pathPoints: [[CGFloat]]?
            var workoutDate: Date?
            var numericValue: Double?
            var additionalText: String?

            // Extract fontStyle from Selectable widgets
            if let selectable = widget as? Selectable {
                fontStyle = selectable.currentFontStyle.rawValue
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

            // Stat widgets - save color
            if let statWidget = widget as? BaseStatWidget {
                textColor = statWidget.currentColor.toHex()
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
                type: className,
                frame: frame,
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
                numericValue: numericValue,
                additionalText: additionalText
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
    
    @objc dynamic func loadSavedDesign() {
        let workoutId = getWorkoutId()
        
        guard let design = CardPersistenceManager.shared.loadDesign(for: workoutId) else {
            WPLog.debug("No saved design found for \(workoutId)")
            // Reset flag even if no saved design (initial state should be "no changes")
            hasUnsavedChanges = false
            return
        }
        
        WPLog.info("Loading saved design for \(workoutId)")
        
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

        // 1. Build a map of EXISTING widgets by itemIdentifier (if available) or className_index fallback
        // Since we are using stable identifiers now, we should try to match by that first
        var existingWidgetMap: [String: UIView] = [:]
        
        // Check widgets in self.widgets
        for widget in widgets {
            if let selectable = widget as? Selectable {
                existingWidgetMap[selectable.itemIdentifier] = widget
            }
        }
        // Check widgets in groups (in case we are reloading over existing state)
        for group in templateGroups {
            for widget in group.groupedItems {
                if let selectable = widget as? Selectable {
                    existingWidgetMap[selectable.itemIdentifier] = widget
                }
            }
        }

        // 2. Create or Update ALL widgets from save state
        var restoredWidgetsMap: [String: UIView] = [:]
        
        for savedWidget in design.widgets {
            let widget: UIView
            
            // Try to find existing widget
            if let existing = existingWidgetMap[savedWidget.identifier] {
                widget = existing
            } else {
                // Create new
                guard let newWidget = createWidgetFromSavedState(savedWidget) else { continue }
                widget = newWidget
                // Ensure identifier matches saved one
                if var selectable = widget as? Selectable {
                    selectable.itemIdentifier = savedWidget.identifier
                }
            }
            
            // Restore properties
            widget.frame = savedWidget.frame

            // Restore common properties
            if let statWidget = widget as? BaseStatWidget {
                statWidget.initialSize = savedWidget.frame.size
                statWidget.updateFonts()
                if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                    statWidget.applyColor(color)
                }
            } else if let routesWidget = widget as? ClimbingRoutesByColorWidget {
                routesWidget.initialSize = savedWidget.frame.size
                if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                    routesWidget.applyColor(color)
                }
                // Load and apply saved font
                if let savedFont = FontPreferences.shared.loadFont(for: savedWidget.identifier) {
                    routesWidget.applyFont(savedFont)
                }
            }

            // Restore rotation for all Selectable widgets
            if var selectable = widget as? Selectable {
                selectable.rotation = savedWidget.rotation
                widget.transform = CGAffineTransform(rotationAngle: savedWidget.rotation)
            }

            if let routeMap = widget as? RouteMapView {
                routeMap.initialSize = savedWidget.frame.size
            }

            if let textWidget = widget as? TextWidget, let text = savedWidget.text {
                textWidget.updateText(text)
                if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                    textWidget.applyColor(color)
                }
            }

            // Add to map
            restoredWidgetsMap[savedWidget.identifier] = widget
        }
        
        // 3. Clear current state
        // Remove all widgets from view hierarchy first
        widgets.forEach { $0.removeFromSuperview() }
        templateGroups.forEach { $0.removeFromSuperview() } // Groups remove their children too usually, but clean up is safer
        widgets.removeAll()
        templateGroups.removeAll()
        selectionManager.unregisterAllItems()
        
        // 4. Restore GROUPS
        var groupedWidgetIds: Set<String> = []
        
        if let savedGroups = design.groups {
            for savedGroup in savedGroups {
                let groupType = WidgetGroupType(rawValue: savedGroup.type) ?? .myRecord
                
                // Collect widgets for this group
                var groupWidgets: [UIView] = []
                for widgetId in savedGroup.widgetIdentifiers {
                    if let widget = restoredWidgetsMap[widgetId] {
                        groupWidgets.append(widget)
                        groupedWidgetIds.insert(widgetId)
                    }
                }
                
                if !groupWidgets.isEmpty {
                    // Fix: TemplateGroupView assumes items are in GLOBAL coordinates (relative to contentView)
                    // and converts them to local. But saved widgets are already in LOCAL coordinates relative to the group.
                    // So we must convert them back to global by adding the group's origin.
                    for widget in groupWidgets {
                        widget.frame.origin.x += savedGroup.frame.origin.x
                        widget.frame.origin.y += savedGroup.frame.origin.y
                    }

                    let group = TemplateGroupView(
                        items: groupWidgets,
                        frame: savedGroup.frame,
                        groupType: groupType,
                        ownerName: savedGroup.ownerName
                    )
                    
                    group.groupDelegate = self
                    group.selectionDelegate = self
                    selectionManager.registerItem(group)
                    
                    contentView.addSubview(group)
                    templateGroups.append(group)
                }
            }
        }
        
        // 5. Restore UNGROUPED widgets
        for (id, widget) in restoredWidgetsMap {
            if !groupedWidgetIds.contains(id) {
                contentView.addSubview(widget)
                widgets.append(widget)
                
                if var selectable = widget as? Selectable {
                    selectable.selectionDelegate = self
                    selectionManager.registerItem(selectable)
                }
            }
        }

        WPLog.info("Design loaded and restored for \(workoutId)")

        // Update watermark color based on loaded background
        updateWatermarkColorForBackground()

        // Reset unsaved changes flag since we just loaded the saved state
        hasUnsavedChanges = false
    }

    // Create widget from saved state - override in subclasses for specific widgets
    func applyCommonWidgetStyles(to widget: UIView, from savedState: SavedWidgetState) {
        widget.frame = savedState.frame
        if var selectable = widget as? Selectable {
            selectable.initialSize = savedState.frame.size
            if let colorHex = savedState.textColor, let color = UIColor(hex: colorHex) {
                selectable.applyColor(color)
            }
            if let fontStyleRaw = savedState.fontStyle, let fontStyle = FontStyle(rawValue: fontStyleRaw) {
                selectable.applyFont(fontStyle)
            }
        }
    }

    func createWidgetFromSavedState(_ savedWidget: SavedWidgetState) -> UIView? {
        let widgetType = savedWidget.type

        // Common widgets that can be created in base class
        switch widgetType {
        case "TextWidget":
            let widget = TextWidget()
            if let text = savedWidget.text {
                widget.configure(text: text)
            }
            widget.textDelegate = self as? TextWidgetDelegate
            applyCommonWidgetStyles(to: widget, from: savedWidget)
            return widget

        case "TextPathWidget":
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

        case "DateWidget":
            let widget = DateWidget()
            if let date = savedWidget.workoutDate {
                widget.configure(startDate: date)
            } else if let date = getWorkoutDate() {
                widget.configure(startDate: date)
            }
            applyCommonWidgetStyles(to: widget, from: savedWidget)
            return widget

        case "CurrentDateTimeWidget":
            let widget = CurrentDateTimeWidget()
            if let date = savedWidget.workoutDate {
                widget.configure(date: date)
            } else if let date = getWorkoutDate() {
                widget.configure(date: date)
            }
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
    
    /// 현재 배경의 밝기에 따라 워터마크 색상을 자동으로 조정
    private func updateWatermarkColorForBackground() {
        var isBackgroundLight = true // Default to light

        if !backgroundImageView.isHidden, let image = backgroundImageView.image {
            // Image background - calculate average brightness
            isBackgroundLight = image.isLight
        } else if !backgroundTemplateView.isHidden {
            // Gradient background - calculate average brightness of gradient colors
            let colors = backgroundTemplateView.getCurrentColors()
            if !colors.isEmpty {
                let totalBrightness = colors.reduce(0.0) { $0 + $1.perceivedBrightness }
                let averageBrightness = totalBrightness / CGFloat(colors.count)
                isBackgroundLight = averageBrightness > 0.5
            }
        } else {
            // No background (white default)
            isBackgroundLight = true
        }

        // Set watermark tint color based on background brightness
        watermarkImageView.tintColor = isBackgroundLight
            ? UIColor.black.withAlphaComponent(Constants.Layout.watermarkAlpha)
            : UIColor.white.withAlphaComponent(Constants.Layout.watermarkAlpha)
    }

    private func useTemplate() {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
        hasUnsavedChanges = true
        updateWatermarkColorForBackground()
    }

    private func removeBackground() {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = true
        dimOverlay.isHidden = true
        view.backgroundColor = .systemGroupedBackground
        hasUnsavedChanges = true
        updateWatermarkColorForBackground()
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

    internal func enterTextPathDrawingMode() {
        isTextPathDrawingMode = true
        textPathPoints = []

        // Disable all widgets interaction
        for widget in widgets {
            (widget as? UIView)?.isUserInteractionEnabled = false
        }

        // Deselect any selected items
        selectionManager.deselectAll()

        // Show overlay
        textPathDrawingOverlayView.isHidden = false
        contentView.bringSubviewToFront(textPathDrawingOverlayView)

        // Hide normal UI elements
        topRightToolbar.isHidden = true
        bottomFloatingToolbar.isHidden = true
        multiSelectToolbar.isHidden = true
        instructionLabel.text = "👆 드래그하여 텍스트 경로를 그려주세요"

        // Change navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(exitTextPathDrawingMode)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "텍스트 편집",
            style: .plain,
            target: self,
            action: #selector(editTextPathText)
        )

        // Show text path drawing toolbar
        textPathDrawingToolbar.isHidden = false

        // Add pan gesture for drawing on overlay
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTextPathPan(_:)))
        textPathDrawingOverlayView.addGestureRecognizer(panGesture)

        // Add tap gesture to close panel when tapping outside (initially disabled)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTextPathOverlayTap(_:)))
        tapGesture.require(toFail: panGesture)
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        tapGesture.isEnabled = true // Always enabled to handle outside taps
        textPathDrawingOverlayView.addGestureRecognizer(tapGesture)
        textPathOverlayTapGesture = tapGesture

        textPathDrawingOverlayView.isUserInteractionEnabled = true

        // Disable scrolling
        scrollView.isScrollEnabled = false
    }

    @objc func exitTextPathDrawingMode() {
        isTextPathDrawingMode = false
        textPathPoints = []
        isTextPathStraightLineMode = false
        textPathStraightLineStartPoint = .zero

        // Reset mode button icon
        if let modeButton = textPathDrawingToolbar.viewWithTag(9003) as? UIButton {
            modeButton.setImage(UIImage(systemName: "scribble"), for: .normal)
        }

        // Clear drawing view
        textPathDrawingOverlayView.subviews.forEach { $0.removeFromSuperview() }

        // Hide overlay
        textPathDrawingOverlayView.isHidden = true

        // Re-enable all widgets interaction
        for widget in widgets {
            (widget as? UIView)?.isUserInteractionEnabled = true
        }

        // Hide any floating panels
        hideAllTextPathPanels()

        // Show normal UI elements
        topRightToolbar.isHidden = false
        instructionLabel.text = "위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"

        // Restore navigation buttons
        setupNavigationButtons()

        // Hide text path toolbar and buttons
        textPathDrawingToolbar.isHidden = true
        textPathConfirmButton.isHidden = true
        textPathRedrawButton.isHidden = true

        // Remove pan gesture from overlay
        textPathDrawingOverlayView.gestureRecognizers?.forEach { gesture in
            textPathDrawingOverlayView.removeGestureRecognizer(gesture)
        }
        textPathDrawingOverlayView.isUserInteractionEnabled = false

        // Enable scrolling
        scrollView.isScrollEnabled = false // Keep disabled for normal mode

        pendingTextForPath = ""
    }

    @objc func editTextPathText() {
        let alert = UIAlertController(
            title: "텍스트 편집",
            message: "경로를 따라 반복할 텍스트를 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = self.pendingTextForPath.trimmingCharacters(in: .whitespaces)
            textField.placeholder = "반복할 텍스트 입력"
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let text = alert?.textFields?.first?.text,
                  !text.isEmpty else { return }

            self.pendingTextForPath = text + " "
            self.instructionLabel.text = "반복 텍스트: \(self.pendingTextForPath)"

            // Redraw with new text
            self.updateTextPathDrawing()
        })

        present(alert, animated: true)
    }


    @objc func handleTextPathOverlayTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)

        // Check if tap is inside toolbar
        if !textPathDrawingToolbar.isHidden && textPathDrawingToolbar.frame.contains(location) {
            return
        }

        // Check if tap is inside any visible independent floating panel
        if !textPathColorPanel.isHidden && textPathColorPanel.frame.contains(location) {
            return
        }
        if !textPathFontPanel.isHidden && textPathFontPanel.frame.contains(location) {
            return
        }
        if !textPathSizePanel.isHidden && textPathSizePanel.frame.contains(location) {
            return
        }

        // Otherwise close panels
        hideAllTextPathPanels()
    }

    @objc func handleTextPathPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: contentView)

        switch gesture.state {
        case .began:
            textPathStraightLineStartPoint = location
            textPathPoints = [location]
            textPathConfirmButton.isHidden = true
            textPathRedrawButton.isHidden = true
            instructionLabel.isHidden = true
            // Close any open panels when drawing starts
            hideAllTextPathPanels()

        case .changed:
            if isTextPathStraightLineMode {
                // 직선 모드: 시작점과 현재점만 유지
                textPathPoints = [textPathStraightLineStartPoint, location]
            } else {
                // 자유곡선 모드: 계속 추가
                textPathPoints.append(location)
            }
            updateTextPathDrawing()

        case .ended, .cancelled:
            if isTextPathStraightLineMode {
                // 직선 모드: 시작점과 끝점
                textPathPoints = [textPathStraightLineStartPoint, location]
            } else {
                // 자유곡선 모드: 마지막 점 추가
                textPathPoints.append(location)
            }
            if textPathPoints.count >= 2 {
                textPathConfirmButton.isHidden = false
                textPathRedrawButton.isHidden = false
            }
            updateTextPathDrawing()

        default:
            break
        }
    }

    @objc func textPathColorMainButtonTapped(_ sender: UIButton) {
        let shouldShow = textPathColorPanel.isHidden
        if shouldShow {
            hideAllTextPathPanels(except: textPathColorPanel)
            showTextPathPanel(textPathColorPanel, sourceButton: sender)
        } else {
            hideAllTextPathPanels()
        }
    }

    @objc func textPathFontMainButtonTapped(_ sender: UIButton) {
        let shouldShow = textPathFontPanel.isHidden
        if shouldShow {
            hideAllTextPathPanels(except: textPathFontPanel)
            showTextPathPanel(textPathFontPanel, sourceButton: sender)
        } else {
            hideAllTextPathPanels()
        }
    }

    @objc func textPathSizeMainButtonTapped(_ sender: UIButton) {
        let shouldShow = textPathSizePanel.isHidden
        if shouldShow {
            hideAllTextPathPanels(except: textPathSizePanel)
            showTextPathPanel(textPathSizePanel, sourceButton: sender)
        } else {
            hideAllTextPathPanels()
        }
    }

    @objc func textPathModeButtonTapped(_ sender: UIButton) {
        // 모드 토글
        isTextPathStraightLineMode.toggle()

        // 아이콘 업데이트
        let iconName = isTextPathStraightLineMode ? "line.diagonal" : "scribble"
        sender.setImage(UIImage(systemName: iconName), for: .normal)
    }

    func hideAllTextPathPanels(except viewToKeep: UIView? = nil) {
        let panels = [textPathColorPanel, textPathFontPanel, textPathSizePanel]
        
        // Reset button states if all panels are being hidden (or update for the kept one)
        if viewToKeep == nil {
            resetTextPathMainButtonsState()
        }
        
        panels.forEach { panel in
            if panel == viewToKeep { return }
            
            // Only animate if it's currently visible or we want to ensure it's hidden
            if !panel.isHidden {
                UIView.animate(withDuration: 0.2) {
                    panel.alpha = 0
                    panel.transform = CGAffineTransform(translationX: 0, y: 10)
                } completion: { _ in
                    panel.isHidden = true
                }
            } else {
                panel.isHidden = true
            }
        }
    }
    
    func resetTextPathMainButtonsState() {
        let mainButtonTags = [9000, 9001, 9002]
        mainButtonTags.forEach { tag in
            if let button = textPathDrawingToolbar.viewWithTag(tag) as? UIButton {
                button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
                // Keep the color button (9000) background color as selected color
                // Keep the font/size button background as transparent white
            }
        }
    }

    func showTextPathPanel(_ panel: UIView, sourceButton: UIButton) {
        panel.isHidden = false
        panel.alpha = 0
        panel.transform = CGAffineTransform(translationX: 0, y: 10)
        
        // Highlight source button
        resetTextPathMainButtonsState()
        sourceButton.layer.borderColor = UIColor.systemYellow.cgColor
        
        // Remake constraints: Center horizontally with padding, bottom to button top
        panel.snp.remakeConstraints { make in
            make.bottom.equalTo(sourceButton.snp.top).offset(-12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(50)
        }
        
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            panel.alpha = 1
            panel.transform = .identity
            self.view.layoutIfNeeded()
        } completion: { _ in
            // No strict need to re-enable gestures here as we successfully separated the views
        }
    }

    @objc func textPathColorButtonTapped(_ sender: UIButton) {
        textPathSelectedColorIndex = sender.tag
        let availableColors: [UIColor] = [
            .white, .systemYellow, .systemOrange, .systemPink,
            .systemRed, .systemGreen, .systemBlue, .systemPurple
        ]
        textPathSelectedColor = availableColors[sender.tag]
        UIView.animate(withDuration: 0.2) {
            self.updateTextPathColorSelection()
            self.updateTextPathDrawing()
        } completion: { _ in
            // Auto-hide panel and update main button
            if let mainButton = self.textPathDrawingToolbar.viewWithTag(9000) as? UIButton {
                mainButton.backgroundColor = self.textPathSelectedColor
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.hideAllTextPathPanels()
            }
        }
    }

    @objc func textPathFontButtonTapped(_ sender: UIButton) {
        textPathSelectedFontIndex = sender.tag
        let availableFonts: [(name: String, font: UIFont)] = [
            ("기본", .boldSystemFont(ofSize: 20)),
            ("얇게", .systemFont(ofSize: 20, weight: .light)),
            ("둥글게", .systemFont(ofSize: 20, weight: .medium)),
            ("굵게", .systemFont(ofSize: 20, weight: .black))
        ]
        let baseFont = availableFonts[sender.tag].font
        textPathSelectedFont = baseFont.withSize(textPathSelectedFontSize)
        UIView.animate(withDuration: 0.2) {
            self.updateTextPathFontSelection()
            self.updateTextPathDrawing()
        } completion: { _ in
            // Auto-hide panel and update main button
            if let mainButton = self.textPathDrawingToolbar.viewWithTag(9001) as? UIButton {
                mainButton.setTitle(availableFonts[sender.tag].name, for: .normal)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.hideAllTextPathPanels()
            }
        }
    }

    @objc func textPathFontSizeChanged(_ sender: UISlider) {
        textPathSelectedFontSize = CGFloat(sender.value)
        // Update label (in panel)
        if let label = textPathSizePanel.viewWithTag(999) as? UILabel {
            label.text = "\(Int(textPathSelectedFontSize))"
        }
        // Update main button
        if let mainButton = textPathDrawingToolbar.viewWithTag(9002) as? UIButton {
            mainButton.setTitle("\(Int(textPathSelectedFontSize))", for: .normal)
        }
        let availableFonts: [(name: String, font: UIFont)] = [
            ("기본", .boldSystemFont(ofSize: 20)),
            ("얇게", .systemFont(ofSize: 20, weight: .light)),
            ("둥글게", .systemFont(ofSize: 20, weight: .medium)),
            ("굵게", .systemFont(ofSize: 20, weight: .black))
        ]
        let baseFont = availableFonts[textPathSelectedFontIndex].font
        textPathSelectedFont = baseFont.withSize(textPathSelectedFontSize)
        updateTextPathDrawing()
    }

    @objc func textPathConfirmTapped() {
        guard textPathPoints.count >= 2 else { return }

        // Apply the same simplification used in preview
        let simplifiedPoints = simplifyTextPath(textPathPoints, minDistance: 8.0)
        guard simplifiedPoints.count >= 2 else { return }

        // Calculate bounding rect from simplified points
        let boundingRect = calculateTextPathBoundingRect(from: simplifiedPoints)

        // Convert simplified points to local coordinates
        let localPoints = simplifiedPoints.map { point in
            CGPoint(
                x: point.x - boundingRect.origin.x,
                y: point.y - boundingRect.origin.y
            )
        }

        createTextPathWidget(
            pathPoints: localPoints,
            boundingRect: boundingRect,
            canvasSize: contentView.bounds.size,
            color: textPathSelectedColor,
            font: textPathSelectedFont
        )
        exitTextPathDrawingMode()
    }

    @objc func textPathRedrawTapped() {
        textPathPoints = []
        textPathDrawingOverlayView.subviews.forEach { $0.removeFromSuperview() }
        textPathConfirmButton.isHidden = true
        textPathRedrawButton.isHidden = true
        instructionLabel.isHidden = false
    }

    private func updateTextPathColorSelection() {
        for (index, button) in textPathColorButtons.enumerated() {
            button.layer.borderColor = index == textPathSelectedColorIndex ?
                UIColor.white.cgColor : UIColor.clear.cgColor
            button.transform = index == textPathSelectedColorIndex ?
                CGAffineTransform(scaleX: 1.15, y: 1.15) : .identity
        }
        // Update main button
        if let mainButton = textPathDrawingToolbar.viewWithTag(9000) as? UIButton {
            mainButton.backgroundColor = textPathSelectedColor
        }
    }

    private func updateTextPathFontSelection() {
        for (index, button) in textPathFontButtons.enumerated() {
            button.backgroundColor = index == textPathSelectedFontIndex ?
                UIColor.white.withAlphaComponent(0.3) : UIColor.white.withAlphaComponent(0.1)
        }
        // Update main button
        if let mainButton = textPathDrawingToolbar.viewWithTag(9001) as? UIButton {
            let availableFonts: [(name: String, font: UIFont)] = [
                ("기본", .boldSystemFont(ofSize: 20)),
                ("얇게", .systemFont(ofSize: 20, weight: .light)),
                ("둥글게", .systemFont(ofSize: 20, weight: .medium)),
                ("굵게", .systemFont(ofSize: 20, weight: .black))
            ]
            mainButton.setTitle(availableFonts[textPathSelectedFontIndex].name, for: .normal)
        }
    }

    private func updateTextPathDrawing() {
        // Remove old preview view
        textPathDrawingOverlayView.subviews.forEach { $0.removeFromSuperview() }

        guard textPathPoints.count >= 2, !pendingTextForPath.isEmpty else { return }

        let simplifiedPath = simplifyTextPath(textPathPoints, minDistance: 8.0)
        guard simplifiedPath.count >= 2 else { return }

        // Create preview view
        let previewView = TextPathPreviewView(frame: textPathDrawingOverlayView.bounds)
        previewView.backgroundColor = .clear
        previewView.isUserInteractionEnabled = false
        previewView.points = simplifiedPath
        previewView.textToRepeat = pendingTextForPath
        previewView.textFont = textPathSelectedFont
        previewView.textColor = textPathSelectedColor

        textPathDrawingOverlayView.addSubview(previewView)
        previewView.setNeedsDisplay()
    }

    private func simplifyTextPath(_ points: [CGPoint], minDistance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var simplified: [CGPoint] = [points[0]]

        for i in 1..<points.count {
            let lastPoint = simplified.last!
            let currentPoint = points[i]
            let dx = currentPoint.x - lastPoint.x
            let dy = currentPoint.y - lastPoint.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance >= minDistance {
                simplified.append(currentPoint)
            }
        }

        if let last = points.last, simplified.last != last {
            simplified.append(last)
        }

        return simplified.count >= 2 ? simplified : points
    }

    private func calculateTextPathBoundingRect(from points: [CGPoint]? = nil) -> CGRect {
        let pathPoints = points ?? textPathPoints
        guard !pathPoints.isEmpty else { return .zero }

        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude

        for point in pathPoints {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }

        let padding: CGFloat = 30
        return CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + padding * 2,
            height: maxY - minY + padding * 2
        )
    }

    private func createTextPathWidget(
        pathPoints: [CGPoint],
        boundingRect: CGRect,
        canvasSize: CGSize,
        color: UIColor,
        font: UIFont
    ) {
        guard pathPoints.count >= 2 else { return }

        // pathPoints are already in local coordinate system (relative to boundingRect)
        // and already simplified

        // Create widget with color and font
        let widget = TextPathWidget(
            text: pendingTextForPath,
            pathPoints: pathPoints,
            frame: boundingRect,
            color: color,
            font: font,
            alreadySimplified: true
        )

        widget.selectionDelegate = self
        selectionManager.registerItem(widget)
        widgets.append(widget)
        contentView.addSubview(widget)
        contentView.bringSubviewToFront(widget)

        // Select the new widget
        selectionManager.selectItem(widget)
        hasUnsavedChanges = true
        pendingTextForPath = ""
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
            self?.updateWatermarkColorForBackground()
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
        updateWatermarkColorForBackground()
    }

    // MARK: - Template Management

    /// Override in subclasses to create workout-specific widgets
    func createWidget(for item: WidgetItem, frame: CGRect) -> UIView? {
        // Override in subclasses to handle workout-specific widget types
        return nil
    }

    /// Override in subclasses to clear workout-specific widgets (e.g., routeMapView for running)
    func clearCustomWidgets() {
        // Override in subclasses if needed
    }

    func applyWidgetTemplate(_ template: WidgetTemplate) {
        // Clear existing widgets
        widgets.forEach { $0.removeFromSuperview() }
        clearCustomWidgets()
        widgets.removeAll()
        selectionManager.deselectAll()

        WPLog.debug("Applying template '\(template.name)' version \(template.version)")

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

            // Try to create widget using subclass implementation
            if let widget = createWidget(for: item, frame: frame) {
                contentView.addSubview(widget)
                widgets.append(widget)

                if var selectable = widget as? Selectable {
                    selectable.selectionDelegate = self
                    selectionManager.registerItem(selectable)

                    // Apply rotation if available
                    if let rotation = item.rotation {
                        selectable.rotation = rotation
                        widget.transform = CGAffineTransform(rotationAngle: rotation)
                    }
                }
            }
        }

        instructionLabel.text = "위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"
        WPLog.info("Applied template directly: \(template.name)")
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
                WPLog.error("Failed to export template: \(error)")
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
                // Get rotation from Selectable widget
                let rotation: CGFloat?
                if let selectable = widget as? Selectable {
                    rotation = selectable.rotation != 0 ? selectable.rotation : nil
                } else {
                    rotation = nil
                }

                let item = TemplateManager.createRatioBasedItem(
                    type: widgetType,
                    frame: frame,
                    canvasSize: canvasSize,
                    color: color,
                    font: font,
                    rotation: rotation
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

            WPLog.debug("Scaling widgets: \(scaleX) x \(scaleY), uniform: \(uniformScale)")

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

        WPLog.debug("Canvas size updated: \(canvasWidth) x \(canvasHeight) (ratio: \(currentAspectRatio.displayName))")
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
        
        WPLog.debug("Applied Background Frame: \(backgroundImageView.frame)")
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

        // Exit multi-select mode and select the new group
        selectionManager.exitMultiSelectMode()
        
        // Select the new group (will trigger delegate to show toolbar)
        selectionManager.selectItem(group)

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
                        } else if let textWidget = widget as? TextWidget {
                            textWidget.applyFont(fontStyle)
                            FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
                        } else if let routesWidget = widget as? ClimbingRoutesByColorWidget {
                            routesWidget.applyFont(fontStyle)
                            FontPreferences.shared.saveFont(fontStyle, for: routesWidget.itemIdentifier)
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
                } else if let routesWidget = item as? ClimbingRoutesByColorWidget {
                    routesWidget.applyFont(fontStyle)
                    FontPreferences.shared.saveFont(fontStyle, for: routesWidget.itemIdentifier)
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
            } else if let routesWidget = selectedItem as? ClimbingRoutesByColorWidget {
                routesWidget.applyFont(fontStyle)
                FontPreferences.shared.saveFont(fontStyle, for: routesWidget.itemIdentifier)
            } else if let group = selectedItem as? TemplateGroupView {
                for widget in group.groupedItems {
                    if let statWidget = widget as? BaseStatWidget {
                        statWidget.applyFont(fontStyle)
                        FontPreferences.shared.saveFont(fontStyle, for: statWidget.itemIdentifier)
                    } else if let textWidget = widget as? TextWidget {
                        textWidget.applyFont(fontStyle)
                        FontPreferences.shared.saveFont(fontStyle, for: textWidget.itemIdentifier)
                    } else if let routesWidget = widget as? ClimbingRoutesByColorWidget {
                        routesWidget.applyFont(fontStyle)
                        FontPreferences.shared.saveFont(fontStyle, for: routesWidget.itemIdentifier)
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
        // Check both multi-select list and single selection
        var selectedItems = selectionManager.getSelectedItems()
        
        // If empty but there is a single selection, treat it as a list of 1
        if selectedItems.isEmpty, let singleItem = selectionManager.currentlySelectedItem {
            selectedItems = [singleItem]
        }
        
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
        
        // If a group is selected, show toolbar but DO NOT auto-enter multi-select mode
        // This allows user to switch selection by tapping another widget
        if item is TemplateGroupView {
            showMultiSelectToolbar()
            updateMultiSelectToolbarState()
        } else if manager.isMultiSelectMode {
            updateMultiSelectToolbarState()
        } else {
            // Normal widget selected in single mode - hide multi-select toolbar
            hideMultiSelectToolbar()
        }
    }
    
    func selectionManager(_ manager: SelectionManager, didDeselect item: Selectable) {
        updateToolbarItemsState()
        
        // Check current selection state
        let selectedItems = manager.getSelectedItems()
        let hasSelectedGroup = selectedItems.contains { $0 is TemplateGroupView }
        let currentIsGroup = manager.currentlySelectedItem is TemplateGroupView
        
        if selectedItems.isEmpty && !manager.isMultiSelectMode && !currentIsGroup {
            hideMultiSelectToolbar()
        } else if manager.isMultiSelectMode || hasSelectedGroup || currentIsGroup {
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
        Task {
            do {
                let template = try await TemplateManager.shared.importTemplate(from: fileURL)
                await MainActor.run {
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
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "가져오기 실패", message: "오류: \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    present(alert, animated: true)
                }
            }
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

        // Update watermark color based on new background
        updateWatermarkColorForBackground()

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
        updateWatermarkColorForBackground()
    }
}

// MARK: - UIGestureRecognizerDelegate for Text Path
extension BaseWorkoutDetailViewController {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't handle tap gesture if touching a button in the toolbar
        if touch.view is UIButton {
            return false
        }

        // Check if touching inside toolbar
        let location = touch.location(in: textPathDrawingToolbar)
        if textPathDrawingToolbar.bounds.contains(location) {
            return false
        }

        return true
    }
}

// MARK: - TextWidgetDelegate
extension BaseWorkoutDetailViewController {
    func textWidgetDidRequestEdit(_ widget: TextWidget) {
        let currentText = widget.textLabel.text ?? ""

        let alert = UIAlertController(
            title: "텍스트 편집",
            message: "위젯에 표시할 텍스트를 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = currentText
            textField.placeholder = "텍스트 입력"
            textField.clearButtonMode = .whileEditing
        }

        alert.addAction(UIAlertAction(title: "완료", style: .default) { [weak alert, weak widget] _ in
            guard let textField = alert?.textFields?.first,
                  let newText = textField.text,
                  !newText.isEmpty else { return }

            widget?.updateText(newText)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }
}

