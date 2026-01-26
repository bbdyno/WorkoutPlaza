//
//  ClimbingDetailViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//
//  Climbing Photo Editor - Same UI structure as WorkoutDetailViewController (Running module)
//  Reuses: TextPathWidget, BackgroundTemplateView, BackgroundImageEditorViewController,
//          AspectRatio, CustomGradientPickerViewController, SelectionManager
//

import UIKit
import SnapKit
import PhotosUI

class ClimbingDetailViewController: UIViewController {

    // MARK: - Properties
    var climbingData: ClimbingData?

    private let scrollView = UIScrollView()
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    // Background Image
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    // Background Template (Reused from Running module)
    private let backgroundTemplateView = BackgroundTemplateView()

    // Watermark
    private let watermarkLabel: UILabel = {
        let label = UILabel()
        label.text = "Workout Plaza"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.isUserInteractionEnabled = false
        return label
    }()

    // Dim Overlay (Reused concept from Running module)
    private let dimOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.isHidden = true
        return view
    }()

    private var widgets: [UIView] = []

    // Selection Manager (Reused from Running module)
    private let selectionManager = SelectionManager()

    // MARK: - Top Right Floating Toolbar (Same as Running module)
    private lazy var topRightToolbar: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    private lazy var aspectRatioButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("9:16", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 0.3, alpha: 0.8)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(cycleAspectRatio), for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
        return button
    }()

    private lazy var addWidgetButton: UIButton = createToolbarButton(
        systemName: "plus",
        action: #selector(showAddWidgetMenu)
    )

    private lazy var textPathButton: UIButton = createToolbarButton(
        systemName: "pencil.and.outline",
        action: #selector(showTextPathInput)
    )

    private lazy var shareImageButton: UIButton = createToolbarButton(
        systemName: "square.and.arrow.up",
        action: #selector(shareImage)
    )

    private lazy var selectPhotoButton: UIButton = createToolbarButton(
        systemName: "photo",
        action: #selector(selectPhoto)
    )

    private lazy var backgroundTemplateButton: UIButton = createToolbarButton(
        systemName: "paintbrush",
        action: #selector(changeTemplate)
    )

    // MARK: - Toast Label
    private lazy var toastLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        label.textAlignment = .center
        label.layer.cornerRadius = 20
        label.clipsToBounds = true
        label.alpha = 0
        return label
    }()

    // MARK: - Bottom Floating Toolbar (Selection Tools - Same as Running module)
    private lazy var bottomFloatingToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        view.layer.cornerRadius = 25
        view.isHidden = true
        return view
    }()

    private lazy var colorPickerButton: UIButton = createToolbarButton(
        systemName: "paintpalette",
        action: #selector(showColorPicker)
    )

    private lazy var fontPickerButton: UIButton = createToolbarButton(
        systemName: "textformat",
        action: #selector(showFontPicker)
    )

    private lazy var deleteItemButton: UIButton = createToolbarButton(
        systemName: "trash",
        action: #selector(deleteSelectedItem)
    )

    private func createToolbarButton(systemName: String, action: Selector) -> UIButton {
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

    // Background transform
    private var backgroundTransform: BackgroundTransform?

    // Aspect ratio (Reused from Running module)
    private var currentAspectRatio: AspectRatio = .portrait9_16
    private var canvasWidthConstraint: Constraint?
    private var canvasHeightConstraint: Constraint?

    private let canvasContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        return view
    }()

    // Text Path Drawing Overlay (Reused from Running module)
    private var textPathDrawingOverlay: TextPathDrawingOverlay?

    // MARK: - Initialization
    init(climbingData: ClimbingData) {
        self.climbingData = climbingData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTopRightToolbar()
        setupBottomFloatingToolbar()
        setupDefaultWidgets()
    }

    // MARK: - Setup UI (Same structure as Running module)
    private func setupUI() {
        view.backgroundColor = .black
        title = "클라이밍 기록"

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "완료",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )

        // Add instruction label
        let instructionLabel = UILabel()
        instructionLabel.text = "위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0

        view.addSubview(instructionLabel)
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // Add canvas container
        view.addSubview(canvasContainerView)
        canvasContainerView.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(360)
            make.height.equalTo(640)
        }

        // Add scrollView and contentView to canvas container
        canvasContainerView.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Disable scrolling and zooming
        scrollView.isScrollEnabled = false
        scrollView.clipsToBounds = true
        scrollView.layer.cornerRadius = 12

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalToSuperview()
        }

        // Ensure content is clipped to bounds for correct rendering
        contentView.clipsToBounds = true

        // Background layers
        contentView.addSubview(backgroundTemplateView)
        backgroundTemplateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundTemplateView.applyTemplate(.gradient3) // Orange for climbing

        contentView.addSubview(backgroundImageView)
        // backgroundImageView uses manual frame layout
        backgroundImageView.contentMode = .scaleToFill

        contentView.addSubview(dimOverlay)
        dimOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Watermark
        contentView.addSubview(watermarkLabel)
        watermarkLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        // Initial canvas size
        updateCanvasSize()

        // Background tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Top Right Toolbar Setup (Same as Running module)
    private func setupTopRightToolbar() {
        topRightToolbar.addArrangedSubview(aspectRatioButton)
        topRightToolbar.addArrangedSubview(addWidgetButton)
        topRightToolbar.addArrangedSubview(textPathButton)
        topRightToolbar.addArrangedSubview(shareImageButton)
        topRightToolbar.addArrangedSubview(selectPhotoButton)
        topRightToolbar.addArrangedSubview(backgroundTemplateButton)

        view.addSubview(topRightToolbar)
        topRightToolbar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().inset(16)
        }

        // Toast label
        view.addSubview(toastLabel)
        toastLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(100)
        }

        view.bringSubviewToFront(topRightToolbar)
    }

    // MARK: - Bottom Floating Toolbar (Same as Running module)
    private func setupBottomFloatingToolbar() {
        view.addSubview(bottomFloatingToolbar)

        let stackView = UIStackView(arrangedSubviews: [
            colorPickerButton,
            fontPickerButton,
            deleteItemButton
        ])
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.alignment = .center

        bottomFloatingToolbar.addSubview(stackView)

        bottomFloatingToolbar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(60)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
        }

        bottomFloatingToolbar.isHidden = true
        view.bringSubviewToFront(bottomFloatingToolbar)
    }

    private func updateToolbarItemsState() {
        let hasSelection = selectionManager.currentlySelectedItem != nil

        UIView.animate(withDuration: 0.25) {
            self.bottomFloatingToolbar.isHidden = !hasSelection
            self.bottomFloatingToolbar.alpha = hasSelection ? 1.0 : 0.0
        }

        colorPickerButton.isEnabled = hasSelection
        fontPickerButton.isEnabled = hasSelection
        deleteItemButton.isEnabled = hasSelection
    }

    // MARK: - Canvas Size (Reused AspectRatio from Running module)
    private func updateCanvasSize() {
        let canvasWidth: CGFloat = 360
        let height = canvasWidth * currentAspectRatio.ratio

        canvasContainerView.snp.updateConstraints { make in
            make.width.equalTo(canvasWidth)
            make.height.equalTo(height)
        }

        // Update aspect ratio button title
        aspectRatioButton.setTitle(currentAspectRatio.displayName, for: .normal)
    }

    // MARK: - Default Widgets Setup
    private func setupDefaultWidgets() {
        guard let data = climbingData else { return }

        let padding: CGFloat = 20
        let canvasWidth: CGFloat = 360  // 캔버스 고정 크기
        let widgetWidth = canvasWidth - (padding * 2)
        let widgetHeight: CGFloat = 70
        let halfWidth = (widgetWidth - 12) / 2
        var currentY: CGFloat = padding + 40 // Below watermark

        // Row 1: Gym Widget (full width)
        let gymWidget = ClimbingGymWidget()
        gymWidget.frame = CGRect(x: padding, y: currentY, width: widgetWidth, height: widgetHeight)
        gymWidget.configure(gymName: data.gymName)
        gymWidget.initialSize = gymWidget.frame.size
        addWidget(gymWidget)
        currentY += widgetHeight + 12

        // Row 2: Discipline + Date (side by side)
        let disciplineWidget = ClimbingDisciplineWidget()
        disciplineWidget.frame = CGRect(x: padding, y: currentY, width: halfWidth, height: widgetHeight)
        disciplineWidget.configure(discipline: data.discipline)
        disciplineWidget.initialSize = disciplineWidget.frame.size
        addWidget(disciplineWidget)

        let dateWidget = DateWidget()
        dateWidget.frame = CGRect(x: padding + halfWidth + 12, y: currentY, width: halfWidth, height: widgetHeight)
        dateWidget.configure(startDate: data.sessionDate)
        dateWidget.initialSize = dateWidget.frame.size
        addWidget(dateWidget)
        currentY += widgetHeight + 12

        // Row 3: Session Summary (full width)
        let sessionWidget = ClimbingSessionWidget()
        sessionWidget.frame = CGRect(x: padding, y: currentY, width: widgetWidth, height: widgetHeight)
        sessionWidget.configure(sent: data.sentRoutes, total: data.totalRoutes)
        sessionWidget.initialSize = sessionWidget.frame.size
        addWidget(sessionWidget)
    }

    private func addWidget(_ widget: UIView) {
        contentView.addSubview(widget)
        widgets.append(widget)

        if var selectable = widget as? Selectable {
            selectable.selectionDelegate = self
            selectionManager.registerItem(selectable)
        }

        // Keep watermark on top
        contentView.bringSubviewToFront(watermarkLabel)
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        // 이미 ClimbingInputViewController에서 저장됨, 카드 편집 완료 후 닫기
        dismiss(animated: true)
    }

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: contentView)

        for widget in widgets.reversed() {
            if widget.frame.contains(location) {
                return
            }
        }

        selectionManager.deselectAll()
        updateToolbarItemsState()
    }

    // MARK: - Aspect Ratio (Reused from Running module)
    @objc private func cycleAspectRatio() {
        let allRatios = AspectRatio.allCases
        guard let currentIndex = allRatios.firstIndex(of: currentAspectRatio) else { return }
        let nextIndex = (currentIndex + 1) % allRatios.count
        currentAspectRatio = allRatios[nextIndex]

        updateCanvasSize()
        showToast("화면 비율: \(currentAspectRatio.displayName)")
    }

    private func showToast(_ message: String) {
        toastLabel.text = "  \(message)  "

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.toastLabel.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut) {
                self.toastLabel.alpha = 0
            }
        }
    }

    // MARK: - Add Widget Menu
    @objc private func showAddWidgetMenu() {
        let actionSheet = UIAlertController(title: "위젯 추가", message: nil, preferredStyle: .actionSheet)

        let climbingWidgets: [(String, WidgetType)] = [
            ("클라이밍짐", .climbingGym),
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
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(gymName: data.gymName)
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
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(sent: data.sentRoutes, total: data.totalRoutes)
            w.initialSize = widgetSize
            widget = w

        case .climbingRoutesByColor:
            let routesByColorSize = CGSize(width: 180, height: 120)
            let w = ClimbingRoutesByColorWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: routesByColorSize)
            w.configure(routes: data.routes)
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
            addWidget(widget)
        }
    }

    // MARK: - Text Path (Reused from Running module)
    @objc private func showTextPathInput() {
        let alert = UIAlertController(
            title: "텍스트 경로",
            message: "경로를 따라 표시할 텍스트를 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "예: SEND! 완등!"
            textField.text = "SEND!"
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "그리기", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text,
                  !text.isEmpty else { return }

            self.showTextPathDrawingOverlay(with: text)
        })

        present(alert, animated: true)
    }

    private func showTextPathDrawingOverlay(with text: String) {
        let overlay = TextPathDrawingOverlay(frame: view.bounds)
        overlay.textToRepeat = text

        overlay.onDrawingComplete = { [weak self] pathPoints, boundingRect, color, font in
            guard let self = self else { return }

            // Convert path points relative to contentView
            let contentFrame = self.contentView.convert(self.contentView.bounds, to: self.view)
            let adjustedPoints = pathPoints.map { point in
                CGPoint(
                    x: point.x - contentFrame.origin.x,
                    y: point.y - contentFrame.origin.y
                )
            }

            let adjustedRect = CGRect(
                x: boundingRect.origin.x - contentFrame.origin.x,
                y: boundingRect.origin.y - contentFrame.origin.y,
                width: boundingRect.width,
                height: boundingRect.height
            )

            let localPathPoints = adjustedPoints.map { point in
                CGPoint(
                    x: point.x - adjustedRect.origin.x,
                    y: point.y - adjustedRect.origin.y
                )
            }

            let textPathWidget = TextPathWidget(
                text: text,
                pathPoints: localPathPoints,
                frame: adjustedRect,
                color: color,
                font: font
            )

            self.addWidget(textPathWidget)
            overlay.removeFromSuperview()
            self.textPathDrawingOverlay = nil
        }

        overlay.onDrawingCancelled = { [weak self] in
            overlay.removeFromSuperview()
            self?.textPathDrawingOverlay = nil
        }

        view.addSubview(overlay)
        textPathDrawingOverlay = overlay
    }

    // MARK: - Photo Selection (Reused from Running module)
    @objc private func selectPhoto() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Background Template (Reused from Running module)
    @objc private func changeTemplate() {
        let actionSheet = UIAlertController(title: "배경 옵션", message: nil, preferredStyle: .actionSheet)

        let templates: [(name: String, style: BackgroundTemplateView.TemplateStyle, colors: [UIColor])] = [
            ("오렌지 그라데이션", .gradient3, [UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0), UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)]),
            ("블루 그라데이션", .gradient1, [UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0), UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)]),
            ("퍼플 그라데이션", .gradient2, [UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0), UIColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 1.0)]),
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

        actionSheet.addAction(UIAlertAction(title: "랜덤", style: .default) { [weak self] _ in
            self?.backgroundTemplateView.applyRandomTemplate()
            self?.backgroundImageView.isHidden = true
            self?.backgroundTemplateView.isHidden = false
        })

        actionSheet.addAction(UIAlertAction(title: "커스텀 그라데이션...", style: .default) { [weak self] _ in
            self?.presentCustomGradientPicker()
        })

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = backgroundTemplateButton
            popover.sourceRect = backgroundTemplateButton.bounds
        }

        present(actionSheet, animated: true)
    }

    private func applyTemplate(_ style: BackgroundTemplateView.TemplateStyle) {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
        backgroundTemplateView.applyTemplate(style)
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

            if colors.count == 1 {
                colors[0].setFill()
                path.fill()
            } else {
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors.map { $0.cgColor } as CFArray,
                    locations: nil
                )!
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
        }

        return image.withRenderingMode(.alwaysOriginal)
    }

    // MARK: - Share Image
    @objc private func shareImage() {
        selectionManager.deselectAll()
        updateToolbarItemsState()

        let exportSize = currentAspectRatio.exportSize
        let currentSize = contentView.bounds.size
        let scale = exportSize.width / currentSize.width

        let renderer = UIGraphicsImageRenderer(size: exportSize)
        let image = renderer.image { context in
            context.cgContext.scaleBy(x: scale, y: scale)
            contentView.drawHierarchy(in: contentView.bounds, afterScreenUpdates: true)
        }

        // 카드 저장
        if let data = climbingData {
            let title = "\(data.discipline.displayName) - \(data.gymName)"
            WorkoutCardManager.shared.createCard(
                sportType: .climbing,
                workoutId: data.id,
                workoutTitle: title,
                workoutDate: data.sessionDate,
                image: image
            )
        }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareImageButton
            popover.sourceRect = shareImageButton.bounds
        }

        present(activityVC, animated: true)
    }

    // MARK: - Color Picker
    @objc private func showColorPicker() {
        guard let selected = selectionManager.currentlySelectedItem else { return }

        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = selected.currentColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }

    // MARK: - Font Picker
    @objc private func showFontPicker() {
        guard selectionManager.currentlySelectedItem != nil else { return }

        let actionSheet = UIAlertController(title: "폰트 스타일 선택", message: nil, preferredStyle: .actionSheet)

        for fontStyle in FontStyle.allCases {
            actionSheet.addAction(UIAlertAction(title: fontStyle.displayName, style: .default) { [weak self] _ in
                self?.selectionManager.currentlySelectedItem?.applyFont(fontStyle)
            })
        }

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = fontPickerButton
            popover.sourceRect = fontPickerButton.bounds
        }

        present(actionSheet, animated: true)
    }

    // MARK: - Delete Item
    @objc private func deleteSelectedItem() {
        guard let selected = selectionManager.currentlySelectedItem else { return }

        selectionManager.deselectItem(selected)
        selected.removeFromSuperview()

        if let index = widgets.firstIndex(where: { $0 === selected }) {
            widgets.remove(at: index)
        }

        updateToolbarItemsState()
    }
}

// MARK: - UIScrollViewDelegate
extension ClimbingDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // 핀치줌 비활성화
        return nil
    }
}

// MARK: - SelectionDelegate
extension ClimbingDetailViewController: SelectionDelegate {
    func itemWasSelected(_ item: Selectable) {
        selectionManager.selectItem(item)
        updateToolbarItemsState()
    }

    func itemWasDeselected(_ item: Selectable) {
        selectionManager.deselectItem(item)
        updateToolbarItemsState()
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension ClimbingDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        selectionManager.currentlySelectedItem?.applyColor(viewController.selectedColor)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ClimbingDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self, let image = object as? UIImage else { return }

            DispatchQueue.main.async {
                let canvasWidth: CGFloat = 360
                let canvasSize = CGSize(width: canvasWidth, height: canvasWidth * self.currentAspectRatio.ratio)

                let editor = BackgroundImageEditorViewController(
                    image: image,
                    canvasSize: canvasSize
                )
                editor.delegate = self

                let navVC = UINavigationController(rootViewController: editor)
                navVC.modalPresentationStyle = .fullScreen
                self.present(navVC, animated: true)
            }
        }
    }
}

// MARK: - BackgroundImageEditorDelegate
extension ClimbingDetailViewController: BackgroundImageEditorDelegate {
    func backgroundImageEditor(_ editor: BackgroundImageEditorViewController, didFinishEditing image: UIImage, transform: BackgroundTransform) {
        backgroundTransform = transform
        backgroundImageView.image = image
        backgroundImageView.isHidden = false
        backgroundTemplateView.isHidden = true

        let canvasWidth: CGFloat = 360
        let canvasSize = CGSize(width: canvasWidth, height: canvasWidth * currentAspectRatio.ratio)

        let imageSize = image.size
        let widthRatio = canvasSize.width / imageSize.width
        let heightRatio = canvasSize.height / imageSize.height
        let fillScale = max(widthRatio, heightRatio)

        let scaledWidth = imageSize.width * fillScale * transform.scale
        let scaledHeight = imageSize.height * fillScale * transform.scale

        let xOffset = -transform.offset.x * (scaledWidth / (imageSize.width * fillScale))
        let yOffset = -transform.offset.y * (scaledHeight / (imageSize.height * fillScale))

        backgroundImageView.frame = CGRect(
            x: xOffset,
            y: yOffset,
            width: scaledWidth,
            height: scaledHeight
        )
    }
}

// MARK: - CustomGradientPickerDelegate
extension ClimbingDetailViewController: CustomGradientPickerDelegate {
    func customGradientPicker(_ picker: CustomGradientPickerViewController, didSelectColors colors: [UIColor], direction: GradientDirection) {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
        backgroundTemplateView.applyCustomGradient(colors: colors, direction: direction)
    }
}
