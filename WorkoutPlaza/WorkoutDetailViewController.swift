//
//  WorkoutDetailViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit
import PhotosUI

class WorkoutDetailViewController: UIViewController {
    
    var workoutData: WorkoutData?
    
    private let scrollView = UIScrollView()
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    // 배경 이미지
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // 배경 템플릿
    private let backgroundTemplateView = BackgroundTemplateView()
    
    // 워터마크 (Workout Plaza)
    private let watermarkLabel: UILabel = {
        let label = UILabel()
        label.text = "Workout Plaza"
        label.font = .systemFont(ofSize: 14, weight: .bold) // Default to system, update if custom font works
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.isUserInteractionEnabled = false
        return label
    }()
    
    // 오버레이 딤 효과 (선택사항)
    private let dimOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.isHidden = true
        return view
    }()
    
    private var routeMapView: RouteMapView?
    private var widgets: [UIView] = []

    // Template Group
    // private var templateGroup: TemplateGroupView? // Removed
    private var isInGroupMode: Bool = false

    // Selection and Color
    private let selectionManager = SelectionManager()

    // Background transform
    private var backgroundTransform: BackgroundTransform?

    // Aspect ratio
    private var currentAspectRatio: AspectRatio = .portrait9_16
    private var canvasWidthConstraint: Constraint?
    private var canvasHeightConstraint: Constraint?
    private var previousCanvasSize: CGSize = .zero

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "💡 위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let aspectRatioControl: UISegmentedControl = {
        let items = AspectRatio.allCases.map { $0.displayName }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = AspectRatio.allCases.firstIndex(of: .portrait9_16) ?? 0
        return control
    }()

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDefaultBackground()
        setupSelectionAndColorSystem()
        configureWithWorkoutData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCanvasSize()
    }

    private func setupUI() {
        title = "운동 상세"
        view.backgroundColor = .systemGroupedBackground
        
        // 사진 선택 버튼
        let photoButton = UIBarButtonItem(
            image: UIImage(systemName: "photo"),
            style: .plain,
            target: self,
            action: #selector(selectPhoto)
        )
        
        // 템플릿 변경 버튼
        let templateButton = UIBarButtonItem(
            image: UIImage(systemName: "paintpalette"),
            style: .plain,
            target: self,
            action: #selector(changeTemplate)
        )
        
        // 리셋 버튼
        let resetButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.counterclockwise"),
            style: .plain,
            target: self,
            action: #selector(resetLayout)
        )

        // 템플릿 선택 버튼
        let layoutButton = UIBarButtonItem(
            image: UIImage(systemName: "square.grid.2x2"),
            style: .plain,
            target: self,
            action: #selector(showTemplateMenu)
        )

        // 위젯 추가 버튼 (+)
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(showAddWidgetMenu)
        )

        // 공유 버튼 (Export)
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareImage)
        )

        navigationItem.rightBarButtonItems = [addButton, layoutButton, shareButton, photoButton, templateButton]

        // Add instruction label
        view.addSubview(instructionLabel)
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // Add aspect ratio control
        aspectRatioControl.addTarget(self, action: #selector(aspectRatioChanged), for: .valueChanged)
        view.addSubview(aspectRatioControl)
        aspectRatioControl.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // Add canvas container
        view.addSubview(canvasContainerView)
        canvasContainerView.snp.makeConstraints { make in
            make.top.equalTo(aspectRatioControl.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            canvasWidthConstraint = make.width.equalTo(360).constraint
            canvasHeightConstraint = make.height.equalTo(640).constraint
        }

        // Add scrollView and contentView to canvas container
        canvasContainerView.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Disable scrolling
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

        // Add background views to contentView
        contentView.addSubview(backgroundTemplateView)
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(dimOverlay)
        contentView.addSubview(watermarkLabel)

        backgroundTemplateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        watermarkLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        // backgroundImageView uses manual frame layout
        backgroundImageView.contentMode = .scaleToFill

        dimOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Initial aspect ratio setup
        updateCanvasSize()

        // Setup toolbar
        setupToolbar()

        // Background tap gesture to deselect
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tapGesture)
    }

    private func setupToolbar() {
        navigationController?.isToolbarHidden = false

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let colorButton = UIBarButtonItem(
            image: UIImage(systemName: "paintpalette"),
            style: .plain,
            target: self,
            action: #selector(showColorPicker)
        )
        colorButton.tintColor = .systemBlue

        let fontButton = UIBarButtonItem(
            image: UIImage(systemName: "textformat"),
            style: .plain,
            target: self,
            action: #selector(showFontPicker)
        )
        fontButton.tintColor = .systemBlue

        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteSelectedItem)
        )
        deleteButton.tintColor = .systemRed

        toolbarItems = [flexibleSpace, colorButton, flexibleSpace, fontButton, flexibleSpace, deleteButton, flexibleSpace]
        updateToolbarItemsState()
    }

    private func updateToolbarItemsState() {
        guard let items = toolbarItems else { return }
        let hasSelection = selectionManager.hasSelection
        let selectedItem = selectionManager.currentlySelectedItem

        // Color button (index 1)
        items[1].isEnabled = hasSelection

        // Font button (index 3)
        items[3].isEnabled = selectedItem is BaseStatWidget

        // Delete button (index 5)
        items[5].isEnabled = hasSelection && !(selectedItem is RouteMapView)
    }

    @objc private func showColorPicker() {
        guard var selectedItem = selectionManager.currentlySelectedItem else { return }

        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = selectedItem.currentColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }

    @objc private func showFontPicker() {
        guard let selectedItem = selectionManager.currentlySelectedItem as? BaseStatWidget else { return }

        let actionSheet = UIAlertController(title: "폰트 스타일 선택", message: nil, preferredStyle: .actionSheet)

        for fontStyle in FontStyle.allCases {
            actionSheet.addAction(UIAlertAction(title: fontStyle.displayName, style: .default) { [weak self] _ in
                selectedItem.applyFont(fontStyle)
                FontPreferences.shared.saveFont(fontStyle, for: selectedItem.itemIdentifier)
            })
        }

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = toolbarItems?[3]
        }

        present(actionSheet, animated: true)
    }

    @objc private func deleteSelectedItem() {
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

        // Remove from widgets array
        widgets.removeAll { $0 === selectedItem }

        // Remove from view hierarchy
        UIView.animate(withDuration: 0.25, animations: {
            selectedItem.alpha = 0
            selectedItem.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            selectedItem.removeFromSuperview()
        }

        updateToolbarItemsState()
    }

    private func setupDefaultBackground() {
        // 기본 템플릿 적용
        backgroundTemplateView.applyTemplate(.gradient1)
        backgroundImageView.isHidden = true
    }

    // MARK: - Selection and Color System
    private func setupSelectionAndColorSystem() {
        selectionManager.delegate = self
    }

    // MARK: - Aspect Ratio Management
    @objc private func aspectRatioChanged() {
        guard let selectedRatio = AspectRatio.allCases[safe: aspectRatioControl.selectedSegmentIndex] else { return }
        currentAspectRatio = selectedRatio
        updateCanvasSize()
    }

    private func updateCanvasSize() {
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

            print("📐 Scaling widgets: \(scaleX) x \(scaleY)")

            // Scale individual widgets
            for widget in widgets {
                var newWidth = widget.frame.width * scaleX
                var newHeight = widget.frame.height * scaleY
                var newX = widget.frame.origin.x * scaleX
                var newY = widget.frame.origin.y * scaleY
                
                if widget is RouteMapView {
                    // Maintain aspect ratio for Route Map
                    let scale = min(scaleX, scaleY)
                    newWidth = widget.frame.width * scale
                    newHeight = widget.frame.height * scale
                    
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

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: contentView)

        // Check if tapped on any widget or route map
        for widget in widgets {
            if widget.frame.contains(location) {
                return // Let the widget handle the tap
            }
        }

        if let routeMapView = routeMapView, routeMapView.frame.contains(location) {
            return // Let the route map handle the tap
        }

        // Tapped on background, deselect all
        selectionManager.deselectAll()
    }

    // MARK: - 이미지 공유
    @objc private func shareImage() {
        // Hide UI elements that shouldn't be in the final image
        selectionManager.deselectAll()
        instructionLabel.isHidden = true
        aspectRatioControl.isHidden = true

        // Capture after a short delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            if let image = self.captureContentView() {
                self.presentShareSheet(image: image)
            }

            // Restore UI
            self.instructionLabel.isHidden = false
            self.aspectRatioControl.isHidden = false
        }
    }
    
    private func presentShareSheet(image: UIImage) {
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
            // Anchor to the share button (index 2 in rightBarButtonItems)
            popover.barButtonItem = navigationItem.rightBarButtonItems?[2]
        }
        
        present(activityViewController, animated: true)
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

    // MARK: - 사진 선택
    @objc private func selectPhoto() {
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
            popover.barButtonItem = navigationItem.rightBarButtonItems?[1]
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
    }
    
    private func removeBackground() {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = true
        dimOverlay.isHidden = true
        view.backgroundColor = .systemGroupedBackground
    }

    // MARK: - 템플릿 선택
    @objc private func showTemplateMenu() {
        let alert = UIAlertController(title: "레이아웃 템플릿", message: "위젯 배치를 선택하세요", preferredStyle: .actionSheet)

        // Get all templates
        let templates = TemplateManager.shared.getAllTemplates()

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
            popover.barButtonItem = navigationItem.rightBarButtonItems?[0]
        }

        present(alert, animated: true)
    }

    private func applyWidgetTemplate(_ template: WidgetTemplate) {
        guard let data = workoutData else { return }

        // Clear existing widgets
        widgets.forEach { $0.removeFromSuperview() }
        routeMapView?.removeFromSuperview()
        widgets.removeAll()
        selectionManager.deselectAll()

        // Calculate scale factor to fit template into current canvas size
        let templateOriginalWidth: CGFloat = 414
        let templateOriginalHeight: CGFloat = 700

        let canvasSize = contentView.bounds.size
        let scaleX = canvasSize.width / templateOriginalWidth
        let scaleY = canvasSize.height / templateOriginalHeight
        let scale = min(scaleX, scaleY)

        print("📐 Template scale: \(scale) (canvas: \(canvasSize.width)x\(canvasSize.height))")

        // Create all widgets directly
        for item in template.items {
            let position = CGPoint(x: item.position.x * scale, y: item.position.y * scale)
            let size = CGSize(width: item.size.width * scale, height: item.size.height * scale)

            var widget: UIView?

            switch item.type {
            case .routeMap:
                let mapView = RouteMapView()
                mapView.setRoute(data.route)
                routeMapView = mapView
                mapView.frame = CGRect(origin: position, size: size)
                mapView.initialSize = size

                if let colorHex = item.color, let color = TemplateManager.color(from: colorHex) {
                    mapView.applyColor(color)
                }
                widget = mapView

            case .distance:
                let w = DistanceWidget()
                w.configure(distance: data.distance)
                w.frame = CGRect(origin: position, size: size)
                w.initialSize = size
                applyItemStyles(to: w, item: item)
                widget = w

            case .duration:
                let w = DurationWidget()
                w.configure(duration: data.duration)
                w.frame = CGRect(origin: position, size: size)
                w.initialSize = size
                applyItemStyles(to: w, item: item)
                widget = w

            case .pace:
                let w = PaceWidget()
                w.configure(pace: data.pace)
                w.frame = CGRect(origin: position, size: size)
                w.initialSize = size
                applyItemStyles(to: w, item: item)
                widget = w

            case .speed:
                let w = SpeedWidget()
                w.configure(speed: data.avgSpeed)
                w.frame = CGRect(origin: position, size: size)
                w.initialSize = size
                applyItemStyles(to: w, item: item)
                widget = w

            case .calories:
                let w = CaloriesWidget()
                w.configure(calories: data.calories)
                w.frame = CGRect(origin: position, size: size)
                w.initialSize = size
                applyItemStyles(to: w, item: item)
                widget = w

            case .date:
                let w = DateWidget()
                w.configure(startDate: data.startDate)
                w.frame = CGRect(origin: position, size: size)
                w.initialSize = size
                applyItemStyles(to: w, item: item)
                widget = w

            case .composite:
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
        
        // Reset instruction label
        instructionLabel.text = "💡 위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"

        print("✅ Applied template directly: \(template.name)")
    }

    private func applyItemStyles(to widget: BaseStatWidget, item: WidgetItem) {
        if let colorHex = item.color, let color = TemplateManager.color(from: colorHex) {
            widget.applyColor(color)
        }

        if let fontName = item.font, let fontStyle = FontStyle(rawValue: fontName) {
            widget.applyFont(fontStyle)
        }
    }

    private func importTemplate() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    private func exportCurrentLayout() {
        // Create template from current layout
        let items = createTemplateItemsFromCurrentLayout()

        let alert = UIAlertController(title: "템플릿 저장", message: "템플릿 이름과 설명을 입력하세요", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "템플릿 이름"
        }

        alert.addTextField { textField in
            textField.placeholder = "설명 (선택사항)"
        }

        alert.addAction(UIAlertAction(title: "저장", style: .default) { [weak self, weak alert] _ in
            guard let name = alert?.textFields?[0].text, !name.isEmpty else { return }
            let description = alert?.textFields?[1].text ?? ""

            let template = TemplateManager.shared.createTemplateFromCurrentLayout(
                name: name,
                description: description,
                items: items
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

    private func createTemplateItemsFromCurrentLayout() -> [WidgetItem] {
        var items: [WidgetItem] = []

        for widget in widgets {
            let frame = widget.frame
            let position = WidgetItem.Position(x: frame.origin.x, y: frame.origin.y)
            let size = WidgetItem.Size(width: frame.width, height: frame.height)

            var type: WidgetType?
            var color: String?
            var font: String?

            if let routeMap = widget as? RouteMapView {
                type = .routeMap
                color = TemplateManager.hexString(from: routeMap.currentColor)
            } else if widget is DistanceWidget {
                type = .distance
            } else if widget is DurationWidget {
                type = .duration
            } else if widget is PaceWidget {
                type = .pace
            } else if widget is SpeedWidget {
                type = .speed
            } else if widget is CaloriesWidget {
                type = .calories
            } else if widget is DateWidget {
                type = .date
            }

            if let statWidget = widget as? BaseStatWidget {
                color = TemplateManager.hexString(from: statWidget.currentColor)
                font = statWidget.currentFontStyle.rawValue
            }

            if let widgetType = type {
                let item = WidgetItem(
                    type: widgetType,
                    position: position,
                    size: size,
                    color: color,
                    font: font
                )
                items.append(item)
            }
        }

        return items
    }

    private func shareTemplate(fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        if let popover = activityViewController.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?[0]
        }

        present(activityViewController, animated: true)
    }

    // MARK: - 위젯 추가
    
    enum SingleWidgetType: String, CaseIterable {
        case routeMap = "경로 지도"
        case distance = "거리"
        case duration = "시간"
        case pace = "페이스"
        case speed = "속도"
        case calories = "칼로리"
        case date = "날짜"
        case currentDateTime = "현재 날짜 및 시간"
    }
    
    private func canAddWidget(_ type: SingleWidgetType) -> Bool {
        switch type {
        case .routeMap:
            return routeMapView == nil
        case .distance:
            return !widgets.contains(where: { $0 is DistanceWidget })
        case .duration:
            return !widgets.contains(where: { $0 is DurationWidget })
        case .pace:
            return !widgets.contains(where: { $0 is PaceWidget })
        case .speed:
            return !widgets.contains(where: { $0 is SpeedWidget })
        case .calories:
            return !widgets.contains(where: { $0 is CaloriesWidget })
        case .date:
            return !widgets.contains(where: { $0 is DateWidget })
        case .currentDateTime:
            return !widgets.contains(where: { $0 is CurrentDateTimeWidget })
        }
    }

    @objc private func showAddWidgetMenu() {
        guard let data = workoutData else { return }

        let actionSheet = UIAlertController(title: "위젯 추가", message: nil, preferredStyle: .actionSheet)

        // 1. Single Widgets
        for type in SingleWidgetType.allCases {
            let isAdded = !canAddWidget(type)
            let title = isAdded ? "✓ \(type.rawValue)" : type.rawValue
            
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.addSingleWidget(type, data: data)
            }
            
            action.isEnabled = !isAdded
            actionSheet.addAction(action)
        }

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?[1]
        }

        present(actionSheet, animated: true)
    }
    
    private func addSingleWidget(_ type: SingleWidgetType, data: WorkoutData) {
        var widget: UIView?
        var size = CGSize(width: 160, height: 80)
        
        switch type {
        case .routeMap:
            let mapView = RouteMapView()
            mapView.setRoute(data.route)
            routeMapView = mapView
            widget = mapView
            size = CGSize(width: 350, height: 250)
            
        case .distance:
            let w = DistanceWidget()
            w.configure(distance: data.distance)
            widget = w
            
        case .duration:
            let w = DurationWidget()
            w.configure(duration: data.duration)
            widget = w
            
        case .pace:
            let w = PaceWidget()
            w.configure(pace: data.pace)
            widget = w
            
        case .speed:
            let w = SpeedWidget()
            w.configure(speed: data.avgSpeed)
            widget = w
            
        case .calories:
            let w = CaloriesWidget()
            w.configure(calories: data.calories)
            widget = w
            
        case .date:
            let w = DateWidget()
            w.configure(startDate: data.startDate)
            widget = w
            
        case .currentDateTime:
            let w = CurrentDateTimeWidget()
            w.configure(date: data.startDate)
            widget = w
            size = CGSize(width: 300, height: 80)
        }
        
        if let widget = widget {
            // Position in center of visible area
            let centerX = view.bounds.width / 2 - size.width / 2
            let centerY = scrollView.contentOffset.y + view.bounds.height / 2 - size.height / 2
            
            // For route map, use specific initial size logic if needed
            if let map = widget as? RouteMapView {
                map.initialSize = size
            }
            
            addWidget(widget, size: size, position: CGPoint(x: centerX, y: centerY))
            
            if let selectable = widget as? Selectable {
                selectionManager.selectItem(selectable)
            }
        }
    }

    // MARK: - 템플릿 변경
    @objc private func changeTemplate() {
        let actionSheet = UIAlertController(title: "템플릿 선택", message: nil, preferredStyle: .actionSheet)
        
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
        })
        
        // Custom
        actionSheet.addAction(UIAlertAction(title: "커스텀 그라데이션...", style: .default) { [weak self] _ in
            self?.presentCustomGradientPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?[2]
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
    }
    
    private func configureWithWorkoutData() {
        guard let data = workoutData else { return }

        // 경로 맵 뷰 추가 (frame 기반으로 변경)
        let mapView = RouteMapView()
        mapView.setRoute(data.route)
        routeMapView = mapView

        // addWidget으로 추가하여 다른 위젯과 동일하게 처리
        contentView.addSubview(mapView)
        widgets.append(mapView)

        // Frame 설정 (SnapKit 제약조건 대신)
        let mapSize = CGSize(width: 350, height: 250)
        let mapY: CGFloat = 70  // instructionLabel 아래 (16 + 약 34 높이 + 20)
        let mapX = (view.bounds.width - mapSize.width) / 2
        mapView.frame = CGRect(x: mapX, y: mapY, width: mapSize.width, height: mapSize.height)

        // Setup selection
        mapView.selectionDelegate = self
        selectionManager.registerItem(mapView)
        mapView.initialSize = mapSize

        // Load saved color
        if let savedColor = ColorPreferences.shared.loadColor(for: mapView.itemIdentifier) {
            mapView.applyColor(savedColor)
        }

        // 기본 위젯만 생성 (거리, 시간, 평균 페이스)
        createDefaultWidgets(for: data)
    }
    
    private func createDefaultWidgets(for data: WorkoutData) {
        let widgetSize = CGSize(width: 160, height: 80)

        // 1. 거리 위젯
        let distanceWidget = DistanceWidget()
        distanceWidget.configure(distance: data.distance)
        addWidget(distanceWidget, size: widgetSize, position: CGPoint(x: 30, y: 350))

        // 2. 시간 위젯
        let durationWidget = DurationWidget()
        durationWidget.configure(duration: data.duration)
        addWidget(durationWidget, size: widgetSize, position: CGPoint(x: 210, y: 350))

        // 3. 페이스 위젯
        let paceWidget = PaceWidget()
        paceWidget.configure(pace: data.pace)
        addWidget(paceWidget, size: widgetSize, position: CGPoint(x: 30, y: 470))
    }
    
    private func createAdditionalWidgets(for data: WorkoutData) {
        // 8. 평균 심박수 위젯 (데모용)
        let heartRateWidget = createCustomWidget(
            title: "평균 심박수",
            value: "142",
            unit: "bpm",
            icon: "heart.fill",
            color: .systemRed
        )
        addWidget(heartRateWidget, size: CGSize(width: 160, height: 80), position: CGPoint(x: 30, y: 820))
        
        // 9. 고도 변화 위젯 (데모용)
        let elevationWidget = createCustomWidget(
            title: "고도 상승",
            value: "120",
            unit: "m",
            icon: "arrow.up.right",
            color: .systemGreen
        )
        addWidget(elevationWidget, size: CGSize(width: 160, height: 80), position: CGPoint(x: 210, y: 820))
        
        // 10. 케이던스 위젯 (데모용)
        let cadenceWidget = createCustomWidget(
            title: "평균 케이던스",
            value: "165",
            unit: "spm",
            icon: "figure.run",
            color: .systemBlue
        )
        addWidget(cadenceWidget, size: CGSize(width: 160, height: 80), position: CGPoint(x: 30, y: 940))
        
        // 11. 스트라이드 위젯 (데모용)
        let strideWidget = createCustomWidget(
            title: "평균 보폭",
            value: "1.12",
            unit: "m",
            icon: "arrow.left.and.right",
            color: .systemOrange
        )
        addWidget(strideWidget, size: CGSize(width: 160, height: 80), position: CGPoint(x: 210, y: 940))
    }
    
    private func createCustomWidget(title: String, value: String, unit: String, icon: String, color: UIColor) -> UIView {
        let widget = BaseStatWidget()
        widget.titleLabel.text = title
        widget.valueLabel.text = value
        widget.unitLabel.text = unit
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        
        widget.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        return widget
    }
    
    private func addWidget(_ widget: UIView, size: CGSize, position: CGPoint) {
        contentView.addSubview(widget)
        widgets.append(widget)

        widget.frame = CGRect(origin: position, size: size)

        // Setup selection if widget is selectable
        if var selectableWidget = widget as? Selectable {
            selectableWidget.selectionDelegate = self
            selectionManager.registerItem(selectableWidget)

            // Set initial size for BaseStatWidget (for font scaling)
            if let statWidget = widget as? BaseStatWidget {
                statWidget.initialSize = size
            }

            // Load saved color if available
            if let savedColor = ColorPreferences.shared.loadColor(for: selectableWidget.itemIdentifier) {
                selectableWidget.applyColor(savedColor)
            }

            // Load saved font if available (only for BaseStatWidget and subclasses)
            if let statWidget = widget as? BaseStatWidget,
               let savedFont = FontPreferences.shared.loadFont(for: selectableWidget.itemIdentifier) {
                statWidget.applyFont(savedFont)
            }
        }
    }
    
    @objc private func resetLayout() {
        // 원래 위치로 리셋
        guard let data = workoutData else { return }
        
        // 모든 위젯 제거
        widgets.forEach { $0.removeFromSuperview() }
        routeMapView?.removeFromSuperview()
        widgets.removeAll()
        
        // 다시 생성
        configureWithWorkoutData()
        
        // 스크롤을 최상단으로
        scrollView.setContentOffset(.zero, animated: true)
    }
}

/// MARK: - PHPickerViewControllerDelegate
extension WorkoutDetailViewController: PHPickerViewControllerDelegate {
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
    
    private func showDimOverlayOption() {
        let alert = UIAlertController(
            title: "딤 효과",
            message: "위젯이 잘 보이도록 어두운 오버레이를 추가하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            self?.dimOverlay.isHidden = false
        })
        
        alert.addAction(UIAlertAction(title: "추가 안함", style: .cancel) { [weak self] _ in
            self?.dimOverlay.isHidden = true
        })
        
        present(alert, animated: true)
    }
}

// MARK: - BackgroundImageEditorDelegate
extension WorkoutDetailViewController: BackgroundImageEditorDelegate {
    func backgroundImageEditor(_ editor: BackgroundImageEditorViewController, didFinishEditing image: UIImage, transform: BackgroundTransform) {
        backgroundImageView.image = image
        backgroundImageView.isHidden = false
        backgroundTemplateView.isHidden = true
        backgroundTransform = transform

        // Apply transform to background image
        applyBackgroundTransform(transform)

        // Show dim overlay option
        showDimOverlayOption()
    }

    private func applyBackgroundTransform(_ transform: BackgroundTransform) {
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
}

// MARK: - SelectionManagerDelegate
extension WorkoutDetailViewController: SelectionManagerDelegate {
    func selectionManager(_ manager: SelectionManager, didSelect item: Selectable) {
        updateToolbarItemsState()
    }

    func selectionManager(_ manager: SelectionManager, didDeselect item: Selectable) {
        updateToolbarItemsState()
    }

    func selectionManagerDidDeselectAll(_ manager: SelectionManager) {
        updateToolbarItemsState()
    }
}

// MARK: - SelectionDelegate
extension WorkoutDetailViewController: SelectionDelegate {
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
extension WorkoutDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        guard var selectedItem = selectionManager.currentlySelectedItem else { return }

        let selectedColor = viewController.selectedColor
        selectedItem.applyColor(selectedColor)
        ColorPreferences.shared.saveColor(selectedColor, for: selectedItem.itemIdentifier)
    }
}

// MARK: - UIDocumentPickerDelegate
extension WorkoutDetailViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }

        let shouldStopAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Import template
            let template = try TemplateManager.shared.importTemplate(from: fileURL)

            // Show success message and apply template
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
            let alert = UIAlertController(
                title: "가져오기 실패",
                message: "템플릿을 가져오는 중 오류가 발생했습니다: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - CustomGradientPickerDelegate
extension WorkoutDetailViewController: CustomGradientPickerDelegate {
    func customGradientPicker(_ picker: CustomGradientPickerViewController, didSelectColors colors: [UIColor]) {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
        backgroundTemplateView.applyCustomGradient(colors: colors)
    }
}

// MARK: - Aspect Ratio
enum AspectRatio: CaseIterable {
    case square1_1      // 1:1 (Instagram Square)
    case portrait4_5    // 4:5 (Instagram Portrait)
    case portrait9_16   // 9:16 (Instagram Story)

    var displayName: String {
        switch self {
        case .square1_1: return "1:1"
        case .portrait4_5: return "4:5"
        case .portrait9_16: return "9:16"
        }
    }

    var ratio: CGFloat {
        switch self {
        case .square1_1: return 1.0
        case .portrait4_5: return 5.0 / 4.0
        case .portrait9_16: return 16.0 / 9.0
        }
    }

    // Base size for export (width is fixed at 1080)
    var exportSize: CGSize {
        switch self {
        case .square1_1: return CGSize(width: 1080, height: 1080)
        case .portrait4_5: return CGSize(width: 1080, height: 1350)
        case .portrait9_16: return CGSize(width: 1080, height: 1920)
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
