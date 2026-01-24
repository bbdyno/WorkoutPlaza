//
//  WorkoutDetailViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit
import PhotosUI
import UniformTypeIdentifiers

class WorkoutDetailViewController: UIViewController {

    var workoutData: WorkoutData?
    var importedWorkoutData: ImportedWorkoutData?

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
    private var templateGroups: [TemplateGroupView] = []
    private var isInGroupMode: Bool = false

    // Selection and Color
    private let selectionManager = SelectionManager()

    // Document Picker Purpose Tracking
    private enum DocumentPickerPurpose {
        case templateImport
    }
    private var documentPickerPurpose: DocumentPickerPurpose = .templateImport

    // Multi-select floating toolbar
    private lazy var multiSelectToolbar: UIView = {
        let toolbar = UIView()
        toolbar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        toolbar.layer.cornerRadius = 12
        toolbar.layer.shadowColor = UIColor.black.cgColor
        toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)
        toolbar.layer.shadowOpacity = 0.2
        toolbar.layer.shadowRadius = 8
        toolbar.isHidden = true
        return toolbar
    }()

    private lazy var groupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "rectangle.3.group"), for: .normal)
        button.setTitle(" 그룹", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(groupSelectedWidgets), for: .touchUpInside)
        return button
    }()

    private lazy var ungroupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "rectangle.3.group.slash"), for: .normal)
        button.setTitle(" 해제", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(ungroupSelectedWidget), for: .touchUpInside)
        return button
    }()

    private lazy var cancelMultiSelectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        button.setTitle(" 취소", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.tintColor = .systemRed
        button.addTarget(self, action: #selector(exitMultiSelectMode), for: .touchUpInside)
        return button
    }()

    private let multiSelectCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.text = "0개 선택"
        return label
    }()

    // MARK: - Top Right Floating Toolbar (Instagram Style)
    private lazy var topRightToolbar: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    private lazy var addWidgetButton: UIButton = createToolbarButton(
        systemName: "plus",
        action: #selector(showAddWidgetMenu)
    )

    private lazy var layoutTemplateButton: UIButton = createToolbarButton(
        systemName: "square.grid.2x2",
        action: #selector(showTemplateMenu)
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

    private lazy var textPathButton: UIButton = createToolbarButton(
        systemName: "pencil.and.outline",
        action: #selector(showTextPathInput)
    )

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

    // MARK: - Bottom Floating Toolbar (Selection Tools)
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

    // Aspect ratio
    private var currentAspectRatio: AspectRatio = .portrait9_16
    private var canvasWidthConstraint: Constraint?
    private var canvasHeightConstraint: Constraint?
    private var previousCanvasSize: CGSize = .zero

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
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
        setupMultiSelectToolbar()
        setupLongPressGesture()
        setupNotificationObservers()

        // Configure with workout data if available (from HealthKit)
        if workoutData != nil {
            configureWithWorkoutData()
        }

        // Handle imported workout data if present (independent of health data)
        if let importedData = importedWorkoutData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.addImportedWorkoutGroup(importedData)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set navigation bar to black background style
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReceivedWorkoutInDetail(_:)),
            name: .didReceiveSharedWorkoutInDetail,
            object: nil
        )
    }

    @objc private func handleReceivedWorkoutInDetail(_ notification: Notification) {
        guard let workout = notification.userInfo?["workout"] as? ShareableWorkout else { return }

        // Show options: import as my record or other's record
        let creatorName = workout.creator?.name ?? "알 수 없음"
        let workoutType = workout.workout.type

        let alert = UIAlertController(
            title: "운동 기록 가져오기",
            message: "\(creatorName)님의 \(workoutType) 기록입니다.\n어떻게 가져올까요?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "내 기록으로 가져오기", style: .default) { [weak self] _ in
            self?.importAsMyRecord(workout)
        })

        alert.addAction(UIAlertAction(title: "타인 기록으로 가져오기", style: .default) { [weak self] _ in
            self?.showImportFieldSelectionSheet(for: workout)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCanvasSize()
        bringToolbarsToFront()
    }

    private func setupUI() {
        title = "러닝 기록 카드 생성"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black

        // Custom back button with confirmation
        navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .white
        navigationItem.leftBarButtonItem = backButton

        // Setup top right floating toolbar (Instagram style)
        setupTopRightToolbar()

        // Add instruction label
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
        // Hide default navigation toolbar
        navigationController?.isToolbarHidden = true

        // Setup bottom floating toolbar for selection tools
        setupBottomFloatingToolbar()
    }

    // MARK: - Top Right Floating Toolbar Setup
    private func setupTopRightToolbar() {
        // Add buttons to stack view
        topRightToolbar.addArrangedSubview(aspectRatioButton)
        topRightToolbar.addArrangedSubview(addWidgetButton)
        topRightToolbar.addArrangedSubview(textPathButton)
        topRightToolbar.addArrangedSubview(layoutTemplateButton)
        topRightToolbar.addArrangedSubview(shareImageButton)
        topRightToolbar.addArrangedSubview(selectPhotoButton)
        topRightToolbar.addArrangedSubview(backgroundTemplateButton)

        view.addSubview(topRightToolbar)

        topRightToolbar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().inset(16)
        }

        // Setup toast label
        view.addSubview(toastLabel)
        toastLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(100)
        }

        // Bring toolbar to front
        view.bringSubviewToFront(topRightToolbar)
    }

    // MARK: - Aspect Ratio Cycling
    @objc private func cycleAspectRatio() {
        // Get next aspect ratio in cycle: 1:1 -> 4:5 -> 9:16 -> 1:1 -> ...
        let allRatios = AspectRatio.allCases
        guard let currentIndex = allRatios.firstIndex(of: currentAspectRatio) else { return }
        let nextIndex = (currentIndex + 1) % allRatios.count
        let newRatio = allRatios[nextIndex]

        // Update current ratio
        currentAspectRatio = newRatio

        // Update button title
        aspectRatioButton.setTitle(newRatio.displayName, for: .normal)

        // Update canvas
        updateCanvasSize()

        // Show toast
        showToast("화면 비율: \(newRatio.displayName)")
    }

    private func showToast(_ message: String) {
        toastLabel.text = "  \(message)  "

        // Fade in
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.toastLabel.alpha = 1.0
        } completion: { _ in
            // Stay visible for 2 seconds, then fade out
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut) {
                self.toastLabel.alpha = 0
            }
        }
    }

    // MARK: - Bottom Floating Toolbar Setup
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

        // Initial state: hidden
        bottomFloatingToolbar.isHidden = true

        // Bring toolbar to front
        view.bringSubviewToFront(bottomFloatingToolbar)
    }

    private func bringToolbarsToFront() {
        view.bringSubviewToFront(topRightToolbar)
        view.bringSubviewToFront(bottomFloatingToolbar)
        view.bringSubviewToFront(multiSelectToolbar)
    }

    private func updateToolbarItemsState() {
        let hasSelection = selectionManager.hasSelection
        let selectedItem = selectionManager.currentlySelectedItem

        // Show/hide bottom floating toolbar based on selection
        let shouldShowToolbar = hasSelection

        if shouldShowToolbar != !bottomFloatingToolbar.isHidden {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                self.bottomFloatingToolbar.isHidden = !shouldShowToolbar
                self.bottomFloatingToolbar.alpha = shouldShowToolbar ? 1.0 : 0.0
            }
        }

        // Update button states
        colorPickerButton.isEnabled = hasSelection
        colorPickerButton.alpha = hasSelection ? 1.0 : 0.5

        fontPickerButton.isEnabled = selectedItem is BaseStatWidget
        fontPickerButton.alpha = (selectedItem is BaseStatWidget) ? 1.0 : 0.5

        let canDelete = hasSelection && !(selectedItem is RouteMapView)
        deleteItemButton.isEnabled = canDelete
        deleteItemButton.alpha = canDelete ? 1.0 : 0.5
    }

    @objc private func showColorPicker() {
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

    @objc private func showFontPicker() {
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
            }
        }
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

    // MARK: - Multi-Select Setup
    private func setupMultiSelectToolbar() {
        view.addSubview(multiSelectToolbar)

        // Add buttons to toolbar
        let stackView = UIStackView(arrangedSubviews: [
            multiSelectCountLabel,
            groupButton,
            ungroupButton,
            cancelMultiSelectButton
        ])
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.distribution = .fill

        multiSelectToolbar.addSubview(stackView)

        multiSelectToolbar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-80)
            make.height.equalTo(50)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
    }

    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        contentView.addGestureRecognizer(longPressGesture)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
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

    private func showMultiSelectToolbar() {
        multiSelectToolbar.isHidden = false
        multiSelectToolbar.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.multiSelectToolbar.alpha = 1
        }
        updateMultiSelectToolbarState()
    }

    private func hideMultiSelectToolbar() {
        UIView.animate(withDuration: 0.25, animations: {
            self.multiSelectToolbar.alpha = 0
        }) { _ in
            self.multiSelectToolbar.isHidden = true
        }
    }

    private func updateMultiSelectToolbarState() {
        let selectedItems = selectionManager.getSelectedItems()
        let count = selectedItems.count

        // Check if only a group is selected
        let onlyGroupSelected = count == 1 && selectedItems.first is TemplateGroupView

        if onlyGroupSelected {
            // Group-only mode: hide count label and group button
            multiSelectCountLabel.isHidden = true
            groupButton.isHidden = true
            ungroupButton.isHidden = false
            ungroupButton.isEnabled = true
        } else {
            // Normal multi-select mode
            multiSelectCountLabel.isHidden = false
            multiSelectCountLabel.text = "\(count)개 선택"
            groupButton.isHidden = false
            ungroupButton.isHidden = false

            // Enable group button only if 2+ non-group items selected
            let nonGroupItems = selectedItems.filter { !($0 is TemplateGroupView) }
            groupButton.isEnabled = nonGroupItems.count >= 2

            // Enable ungroup button only if a single group is selected
            let hasGroup = selectedItems.contains { $0 is TemplateGroupView }
            ungroupButton.isEnabled = hasGroup && count == 1
        }
    }

    @objc private func groupSelectedWidgets() {
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

    private func selectedItemIdentifiersClear() {
        // Manually clear the multi-select mode without trying to hide already-hidden items
        selectionManager.exitMultiSelectMode()
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

        // Haptic feedback for error
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    @objc private func ungroupSelectedWidget() {
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

        // Exit multi-select mode
        selectionManager.exitMultiSelectMode()
        hideMultiSelectToolbar()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    @objc private func exitMultiSelectMode() {
        selectionManager.exitMultiSelectMode()
        hideMultiSelectToolbar()
    }

    // MARK: - Import Workout Group
    private func addImportedWorkoutGroup(_ importedData: ImportedWorkoutData) {
        var importedWidgets: [UIView] = []
        let originalData = importedData.originalData

        // Check if we should use current layout
        if importedData.useCurrentLayout {
            importedWidgets = createImportedWidgetsMatchingCurrentLayout(importedData)
        } else {
            importedWidgets = createImportedWidgetsWithDefaultLayout(importedData)
        }

        // Create group from imported widgets if we have more than one
        guard importedWidgets.count > 1 else {
            // If only one widget, just add it to the widgets array
            widgets.append(contentsOf: importedWidgets)
            for widget in importedWidgets {
                if let selectable = widget as? Selectable {
                    selectionManager.registerItem(selectable)
                }
            }
            return
        }

        // Calculate bounding frame for all imported widgets
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude

        for widget in importedWidgets {
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

        // Determine group type: myRecord if no owner name (createNew mode), importedRecord otherwise
        let groupType: WidgetGroupType = importedData.ownerName.isEmpty ? .myRecord : .importedRecord
        let ownerName: String? = importedData.ownerName.isEmpty ? nil : importedData.ownerName

        // Create group
        let group = TemplateGroupView(
            items: importedWidgets,
            frame: groupFrame,
            groupType: groupType,
            ownerName: ownerName
        )
        group.groupDelegate = self
        group.selectionDelegate = self
        selectionManager.registerItem(group)

        contentView.addSubview(group)
        templateGroups.append(group)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        print("✅ Added workout group (type: \(groupType), owner: \(ownerName ?? "self"))")
    }

    // MARK: - Create Imported Widgets with Default Layout
    private func createImportedWidgetsWithDefaultLayout(_ importedData: ImportedWorkoutData) -> [UIView] {
        var importedWidgets: [UIView] = []

        // Get canvas size for boundary calculations
        let canvasSize = contentView.bounds.size
        let margin: CGFloat = 20
        let spacing: CGFloat = 10

        // Calculate scale factor to fit within canvas
        let availableWidth = canvasSize.width - (margin * 2)
        let baseWidgetWidth: CGFloat = 160
        let twoColumnWidth = (baseWidgetWidth * 2) + spacing
        let scaleFactor = min(1.0, availableWidth / twoColumnWidth)

        let widgetSize = CGSize(width: baseWidgetWidth * scaleFactor, height: 80 * scaleFactor)
        let startX: CGFloat = margin

        // Find starting Y position - below existing content but within canvas
        // Start at a lower position so check button is visible (at least 80pt from top)
        let minStartY: CGFloat = 80
        var startY: CGFloat = minStartY
        for widget in widgets {
            startY = max(startY, widget.frame.maxY + spacing)
        }
        for group in templateGroups {
            startY = max(startY, group.frame.maxY + spacing)
        }
        if let routeMap = routeMapView {
            startY = max(startY, routeMap.frame.maxY + spacing)
        }

        // Ensure starting position is within canvas (with room for at least some widgets)
        let minRoomNeeded: CGFloat = 200 * scaleFactor
        if startY + minRoomNeeded > canvasSize.height {
            // Not enough room below - start at a reasonable position
            startY = max(minStartY, canvasSize.height * 0.4)
        }

        var currentY = startY

        // Add owner name label (TextWidget) - only if owner name is provided (for imported records)
        if !importedData.ownerName.isEmpty {
            let ownerWidget = TextWidget()
            ownerWidget.configure(text: "\(importedData.ownerName)의 기록")
            ownerWidget.applyColor(.systemOrange)
            ownerWidget.textDelegate = self
            let ownerSize = CGSize(width: 200 * scaleFactor, height: 40 * scaleFactor)
            ownerWidget.frame = CGRect(x: startX, y: currentY, width: ownerSize.width, height: ownerSize.height)
            ownerWidget.initialSize = ownerSize
            contentView.addSubview(ownerWidget)
            ownerWidget.selectionDelegate = self
            importedWidgets.append(ownerWidget)
            currentY += ownerSize.height + spacing
        }

        let originalData = importedData.originalData

        // Add route widget if selected and has route data
        if importedData.selectedFields.contains(.route) && importedData.hasRoute {
            let routeMap = RouteMapView()
            routeMap.setRoute(importedData.routeLocations)
            // Calculate optimal size based on route aspect ratio, constrained by canvas
            let maxRouteDimension = min(200 * scaleFactor, availableWidth * 0.6)
            let optimalSize = routeMap.calculateOptimalSize(maxDimension: maxRouteDimension)
            routeMap.frame = CGRect(x: startX, y: currentY, width: optimalSize.width, height: optimalSize.height)
            routeMap.initialSize = optimalSize
            contentView.addSubview(routeMap)
            routeMap.selectionDelegate = self
            importedWidgets.append(routeMap)
            currentY += optimalSize.height + spacing
        }

        // Add distance widget if selected
        if importedData.selectedFields.contains(.distance) {
            let w = DistanceWidget()
            w.configure(distance: originalData.distance)
            w.frame = CGRect(x: startX, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        // Add duration widget if selected
        if importedData.selectedFields.contains(.duration) {
            let w = DurationWidget()
            w.configure(duration: originalData.duration)
            w.frame = CGRect(x: startX + widgetSize.width + spacing, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        currentY += widgetSize.height + spacing

        // Add pace widget if selected
        if importedData.selectedFields.contains(.pace) {
            let w = PaceWidget()
            w.configure(pace: originalData.pace)
            w.frame = CGRect(x: startX, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        // Add speed widget if selected
        if importedData.selectedFields.contains(.speed) {
            let w = SpeedWidget()
            w.configure(speed: originalData.avgSpeed)
            w.frame = CGRect(x: startX + widgetSize.width + spacing, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        currentY += widgetSize.height + spacing

        // Add calories widget if selected
        if importedData.selectedFields.contains(.calories) {
            let w = CaloriesWidget()
            w.configure(calories: originalData.calories)
            w.frame = CGRect(x: startX, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        // Add date widget if selected
        if importedData.selectedFields.contains(.date) {
            let w = DateWidget()
            w.configure(startDate: originalData.startDate)
            w.frame = CGRect(x: startX + widgetSize.width + spacing, y: currentY, width: widgetSize.width, height: widgetSize.height)
            w.initialSize = widgetSize
            contentView.addSubview(w)
            w.selectionDelegate = self
            importedWidgets.append(w)
        }

        return importedWidgets
    }

    // MARK: - Create Imported Widgets Matching Current Layout
    private func createImportedWidgetsMatchingCurrentLayout(_ importedData: ImportedWorkoutData) -> [UIView] {
        var importedWidgets: [UIView] = []
        let originalData = importedData.originalData

        // Get canvas size for boundary calculations
        let canvasSize = contentView.bounds.size
        let margin: CGFloat = 20

        // Gather all widgets including those inside groups
        var allWidgets: [UIView] = widgets
        for group in templateGroups {
            allWidgets.append(contentsOf: group.groupedItems)
        }

        // Find position below existing widgets or at a reasonable offset
        var maxY: CGFloat = 0
        for widget in widgets {
            maxY = max(maxY, widget.frame.maxY)
        }
        for group in templateGroups {
            maxY = max(maxY, group.frame.maxY)
        }
        if let routeMap = routeMapView {
            maxY = max(maxY, routeMap.frame.maxY)
        }

        // Calculate offset but ensure it stays within canvas
        var offsetY = maxY + 30
        // If offsetY would place content outside canvas, start at a reasonable position
        if offsetY > canvasSize.height * 0.7 {
            offsetY = max(margin, canvasSize.height * 0.4)
        }

        // Calculate scale factor if content would exceed canvas width
        let availableWidth = canvasSize.width - (margin * 2)
        var scaleFactor: CGFloat = 1.0

        // Check max width of existing widgets to determine if scaling is needed
        var maxWidgetWidth: CGFloat = 0
        for widget in allWidgets {
            maxWidgetWidth = max(maxWidgetWidth, widget.frame.maxX)
        }
        if maxWidgetWidth > availableWidth {
            scaleFactor = availableWidth / maxWidgetWidth
        }

        // Add owner name label at the top - only if owner name is provided (for imported records)
        if !importedData.ownerName.isEmpty {
            let ownerWidget = TextWidget()
            ownerWidget.configure(text: "\(importedData.ownerName)의 기록")
            ownerWidget.applyColor(.systemOrange)
            ownerWidget.textDelegate = self
            let ownerSize = CGSize(width: 200 * scaleFactor, height: 40 * scaleFactor)
            ownerWidget.frame = CGRect(x: margin, y: offsetY, width: ownerSize.width, height: ownerSize.height)
            ownerWidget.initialSize = ownerSize
            contentView.addSubview(ownerWidget)
            ownerWidget.selectionDelegate = self
            importedWidgets.append(ownerWidget)
        }

        // Helper to convert widget frame to contentView coordinates
        func frameInContentView(_ widget: UIView) -> CGRect {
            if let superview = widget.superview, superview != contentView {
                return superview.convert(widget.frame, to: contentView)
            }
            return widget.frame
        }

        // Match each imported field to existing widget positions/sizes
        for widget in allWidgets {
            var newWidget: UIView?
            var shouldAdd = false

            // Create widget based on type if selected
            if widget is RouteMapView && importedData.selectedFields.contains(.route) && importedData.hasRoute {
                let routeMap = RouteMapView()
                routeMap.setRoute(importedData.routeLocations)
                // Calculate optimal size for the imported route (not copy from existing)
                let existingFrame = frameInContentView(widget)
                let maxDimension = max(existingFrame.width, existingFrame.height)
                let optimalSize = routeMap.calculateOptimalSize(maxDimension: maxDimension)
                routeMap.frame = CGRect(origin: .zero, size: optimalSize)
                routeMap.initialSize = optimalSize
                newWidget = routeMap
                shouldAdd = true
            } else if widget is DistanceWidget && importedData.selectedFields.contains(.distance) {
                let w = DistanceWidget()
                w.configure(distance: originalData.distance)
                newWidget = w
                shouldAdd = true
            } else if widget is DurationWidget && importedData.selectedFields.contains(.duration) {
                let w = DurationWidget()
                w.configure(duration: originalData.duration)
                newWidget = w
                shouldAdd = true
            } else if widget is PaceWidget && importedData.selectedFields.contains(.pace) {
                let w = PaceWidget()
                w.configure(pace: originalData.pace)
                newWidget = w
                shouldAdd = true
            } else if widget is SpeedWidget && importedData.selectedFields.contains(.speed) {
                let w = SpeedWidget()
                w.configure(speed: originalData.avgSpeed)
                newWidget = w
                shouldAdd = true
            } else if widget is CaloriesWidget && importedData.selectedFields.contains(.calories) {
                let w = CaloriesWidget()
                w.configure(calories: originalData.calories)
                newWidget = w
                shouldAdd = true
            } else if widget is DateWidget && importedData.selectedFields.contains(.date) {
                let w = DateWidget()
                w.configure(startDate: originalData.startDate)
                newWidget = w
                shouldAdd = true
            }

            if shouldAdd, let newWidget = newWidget {
                // Get original widget's frame in contentView coordinates
                let originalFrame = frameInContentView(widget)
                let ownerOffset: CGFloat = importedData.ownerName.isEmpty ? 0 : 50 * scaleFactor

                // For RouteMapView, use its pre-calculated optimal size, only update position
                if let routeMap = newWidget as? RouteMapView {
                    // Scale and center the route widget
                    let scaledWidth = routeMap.frame.width * scaleFactor
                    let scaledHeight = routeMap.frame.height * scaleFactor
                    let centerX = originalFrame.midX * scaleFactor
                    let centerY = (originalFrame.midY * scaleFactor) + offsetY + ownerOffset

                    var newFrame = CGRect(
                        x: centerX - scaledWidth / 2,
                        y: centerY - scaledHeight / 2,
                        width: scaledWidth,
                        height: scaledHeight
                    )

                    // Ensure within canvas bounds
                    newFrame = constrainFrameToCanvas(newFrame, canvasSize: canvasSize, margin: margin)

                    routeMap.frame = newFrame
                    routeMap.initialSize = newFrame.size
                    routeMap.selectionDelegate = self
                } else {
                    // Copy position and size from existing widget, scaled and offset by Y
                    var newFrame = CGRect(
                        x: originalFrame.origin.x * scaleFactor,
                        y: (originalFrame.origin.y * scaleFactor) + offsetY + ownerOffset,
                        width: originalFrame.width * scaleFactor,
                        height: originalFrame.height * scaleFactor
                    )

                    // Ensure within canvas bounds
                    newFrame = constrainFrameToCanvas(newFrame, canvasSize: canvasSize, margin: margin)

                    newWidget.frame = newFrame

                    if var selectable = newWidget as? Selectable {
                        (newWidget as? BaseStatWidget)?.initialSize = newFrame.size
                        selectable.selectionDelegate = self
                    }
                }

                contentView.addSubview(newWidget)
                importedWidgets.append(newWidget)
            }
        }

        // Also check routeMapView separately
        if let existingRoute = routeMapView, importedData.selectedFields.contains(.route) && importedData.hasRoute {
            // Check if we haven't already added a route widget
            let hasRoute = importedWidgets.contains { $0 is RouteMapView }
            if !hasRoute {
                let routeMap = RouteMapView()
                routeMap.setRoute(importedData.routeLocations)
                // Calculate optimal size for the imported route, scaled
                let maxDimension = max(existingRoute.frame.width, existingRoute.frame.height) * scaleFactor
                let optimalSize = routeMap.calculateOptimalSize(maxDimension: maxDimension)
                let ownerOffset: CGFloat = importedData.ownerName.isEmpty ? 0 : 50 * scaleFactor
                // Center at the same position as original, scaled
                let centerX = existingRoute.frame.midX * scaleFactor
                let centerY = (existingRoute.frame.midY * scaleFactor) + offsetY + ownerOffset

                var newFrame = CGRect(
                    x: centerX - optimalSize.width / 2,
                    y: centerY - optimalSize.height / 2,
                    width: optimalSize.width,
                    height: optimalSize.height
                )

                // Ensure within canvas bounds
                newFrame = constrainFrameToCanvas(newFrame, canvasSize: canvasSize, margin: margin)

                routeMap.frame = newFrame
                routeMap.initialSize = newFrame.size
                routeMap.selectionDelegate = self
                contentView.addSubview(routeMap)
                importedWidgets.append(routeMap)
            }
        }

        return importedWidgets
    }

    /// Constrain a frame to fit within canvas bounds with margin
    private func constrainFrameToCanvas(_ frame: CGRect, canvasSize: CGSize, margin: CGFloat) -> CGRect {
        var constrainedFrame = frame

        // Ensure X is within bounds
        if constrainedFrame.origin.x < margin {
            constrainedFrame.origin.x = margin
        }
        if constrainedFrame.maxX > canvasSize.width - margin {
            // First try to move it left
            constrainedFrame.origin.x = canvasSize.width - margin - constrainedFrame.width
            // If still out of bounds, scale down width
            if constrainedFrame.origin.x < margin {
                constrainedFrame.origin.x = margin
                constrainedFrame.size.width = canvasSize.width - (margin * 2)
            }
        }

        // Ensure Y is within bounds
        if constrainedFrame.origin.y < margin {
            constrainedFrame.origin.y = margin
        }
        if constrainedFrame.maxY > canvasSize.height - margin {
            // First try to move it up
            constrainedFrame.origin.y = canvasSize.height - margin - constrainedFrame.height
            // If still out of bounds, scale down height
            if constrainedFrame.origin.y < margin {
                constrainedFrame.origin.y = margin
                constrainedFrame.size.height = canvasSize.height - (margin * 2)
            }
        }

        return constrainedFrame
    }

    // MARK: - Aspect Ratio Management
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

        // Check if tapped on any template group
        for group in templateGroups {
            if group.frame.contains(location) {
                return // Let the group handle the tap
            }
        }

        // Tapped on background, deselect all
        selectionManager.deselectAll()
    }

    // MARK: - Back Navigation
    @objc private func backButtonTapped() {
        let alert = UIAlertController(
            title: "나가시겠습니까?",
            message: "현재 작업 중인 내용이 모두 사라집니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }

    // MARK: - 이미지 공유
    @objc private func shareImage() {
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
            popover.sourceView = shareImageButton
            popover.sourceRect = shareImageButton.bounds
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
            popover.sourceView = layoutTemplateButton
            popover.sourceRect = layoutTemplateButton.bounds
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

        print("📐 Applying template '\(template.name)' version \(template.version)")

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
        print("   Template canvas size: \(templateCanvasSize.width)x\(templateCanvasSize.height)")
        print("   Detected aspect ratio: \(detectedAspectRatio.displayName)")

        // Update aspect ratio button and canvas size
        currentAspectRatio = detectedAspectRatio
        aspectRatioButton.setTitle(detectedAspectRatio.displayName, for: .normal)
        updateCanvasSize()

        // Force immediate layout update
        view.layoutIfNeeded()

        // STEP 2: Get updated canvas size after aspect ratio change
        let canvasSize = contentView.bounds.size
        print("   New canvas size: \(canvasSize.width)x\(canvasSize.height)")

        // STEP 3: Apply background image aspect ratio if available
        if let aspectRatio = template.backgroundImageAspectRatio {
            print("   Background image aspect ratio: \(aspectRatio)")
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
            print("   Background transform applied: scale=\(transformData.scale)")
        }

        // STEP 5: Create all widgets in the new canvas
        for item in template.items {
            // Use ratio-based positioning (version 2.0+) or fallback to legacy
            let frame = TemplateManager.absoluteFrame(from: item, canvasSize: canvasSize, templateCanvasSize: templateCanvasSize)

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

            case .date:
                let w = DateWidget()
                w.configure(startDate: data.startDate)
                w.frame = frame
                w.initialSize = frame.size
                applyItemStyles(to: w, item: item)
                widget = w

            case .text:
                let w = TextWidget()
                w.configure(text: "텍스트 입력")  // Default text, will be updated from template if available
                w.textDelegate = self
                w.frame = frame
                w.initialSize = frame.size
                applyItemStyles(to: w, item: item)
                widget = w

            case .location:
                guard let firstLocation = data.route.first else {
                    print("⚠️ No GPS data for location widget in template")
                    break
                }

                let w = LocationWidget()
                w.frame = frame
                w.initialSize = frame.size
                applyItemStyles(to: w, item: item)

                // Configure asynchronously
                w.configure(location: firstLocation) { success in
                    print(success ? "✅ Location widget loaded from template" : "⚠️ Location widget geocoding failed")
                }

                widget = w

            case .composite:
                break

            // Climbing widgets are not used in running workout detail view
            case .climbingGym, .climbingDiscipline, .climbingGrade, .climbingAttempts, .climbingTakes, .climbingSession, .climbingHighestGrade:
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
        
        instructionLabel.text = "위젯을 드래그하거나 핀치하여 자유롭게 배치하세요"

        print("✅ Applied template directly: \(template.name)")
    }

    private func applyItemStyles(to widget: any Selectable, item: WidgetItem) {
        if let colorHex = item.color, let color = TemplateManager.color(from: colorHex) {
            widget.applyColor(color)
        }

        if let fontName = item.font, let fontStyle = FontStyle(rawValue: fontName) {
            widget.applyFont(fontStyle)
        }
    }

    private func importTemplate() {
        documentPickerPurpose = .templateImport
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    private func exportCurrentLayout() {
        // Create template from current layout
        let items = createTemplateItemsFromCurrentLayout()
        let canvasSize = contentView.bounds.size

        // Capture background image aspect ratio if present
        var backgroundImageAspectRatio: CGFloat? = nil
        if let image = backgroundImageView.image, !backgroundImageView.isHidden {
            backgroundImageAspectRatio = image.size.width / image.size.height
        }

        // Capture background transform if present
        var backgroundTransformData: BackgroundTransformData? = nil
        if let transform = backgroundTransform {
            backgroundTransformData = BackgroundTransformData(
                scale: transform.scale,
                offsetX: transform.offset.x,
                offsetY: transform.offset.y
            )
        }

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

            // Create template with version 2.0 including canvas size and background info
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

    private func createTemplateItemsFromCurrentLayout() -> [WidgetItem] {
        var items: [WidgetItem] = []
        let canvasSize = contentView.bounds.size

        for widget in widgets {
            let frame = widget.frame

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
            } else if widget is TextWidget {
                type = .text
            } else if widget is LocationWidget {
                type = .location
            }

            if let statWidget = widget as? BaseStatWidget {
                color = TemplateManager.hexString(from: statWidget.currentColor)
                font = statWidget.currentFontStyle.rawValue
            } else if let textWidget = widget as? TextWidget {
                color = TemplateManager.hexString(from: textWidget.currentColor)
                font = textWidget.currentFontStyle.rawValue
            } else if let locationWidget = widget as? LocationWidget {
                color = TemplateManager.hexString(from: locationWidget.currentColor)
                font = locationWidget.currentFontStyle.rawValue
            }

            if let widgetType = type {
                // Create ratio-based item (version 2.0)
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

    private func shareTemplate(fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = layoutTemplateButton
            popover.sourceRect = layoutTemplateButton.bounds
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
        case text = "텍스트"
        case location = "위치"
    }
    
    private func canAddWidget(_ type: SingleWidgetType) -> Bool {
        let hasRoute = workoutData?.hasRoute ?? false

        switch type {
        case .routeMap:
            // GPS 경로 데이터가 없거나 이미 추가된 경우 비활성화
            return routeMapView == nil && hasRoute
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
        case .text:
            return true  // Multiple text widgets allowed
        case .location:
            // GPS 경로 데이터가 없거나 이미 추가된 경우 비활성화
            return !widgets.contains(where: { $0 is LocationWidget }) && hasRoute
        }
    }

    @objc private func showAddWidgetMenu() {
        guard let data = workoutData else { return }

        let actionSheet = UIAlertController(title: "위젯 추가", message: nil, preferredStyle: .actionSheet)
        let hasRoute = data.hasRoute

        // 1. Single Widgets
        for type in SingleWidgetType.allCases {
            let isAdded = !canAddWidget(type)
            var title = type.rawValue

            // GPS 관련 위젯에 상태 표시
            if type == .routeMap || type == .location {
                if !hasRoute {
                    title = "\(type.rawValue) (GPS 없음)"
                } else if isAdded {
                    title = "✓ \(type.rawValue)"
                }
            } else if isAdded {
                title = "✓ \(type.rawValue)"
            }

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.addSingleWidget(type, data: data)
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

    // MARK: - Import Workout Methods

    /// Import as my record - clears existing widgets if any
    private func importAsMyRecord(_ workout: ShareableWorkout) {
        let hasExistingContent = !widgets.isEmpty || !templateGroups.isEmpty || routeMapView != nil

        if hasExistingContent {
            // Show warning
            let alert = UIAlertController(
                title: "기존 내용 삭제",
                message: "내 기록으로 가져오면 현재 작성 중인 내용이 모두 사라집니다. 계속하시겠습니까?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "가져오기", style: .destructive) { [weak self] _ in
                self?.clearAllWidgetsAndImport(workout)
            })

            present(alert, animated: true)
        } else {
            // No existing content, import directly
            importWorkoutAsMyRecord(workout)
        }
    }

    /// Clear all widgets and import as my record
    private func clearAllWidgetsAndImport(_ workout: ShareableWorkout) {
        // Clear all existing content
        for widget in widgets {
            widget.removeFromSuperview()
        }
        widgets.removeAll()

        for group in templateGroups {
            group.removeFromSuperview()
        }
        templateGroups.removeAll()

        routeMapView?.removeFromSuperview()
        routeMapView = nil

        selectionManager.unregisterAllItems()

        // Import as my record
        importWorkoutAsMyRecord(workout)
    }

    /// Import workout as my record (no owner name)
    private func importWorkoutAsMyRecord(_ workout: ShareableWorkout) {
        let importedData = ImportedWorkoutData(
            ownerName: "",  // Empty = my record
            originalData: workout.workout,
            selectedFields: Set(ImportField.allCases),
            useCurrentLayout: false
        )

        addImportedWorkoutGroup(importedData)
    }

    /// Show ImportWorkoutViewController for importing as other's record
    private func showImportFieldSelectionSheet(for workout: ShareableWorkout) {
        let importVC = ImportWorkoutViewController()
        importVC.shareableWorkout = workout
        importVC.importMode = .attachToExisting
        importVC.attachToWorkout = workoutData
        importVC.delegate = self

        let navController = UINavigationController(rootViewController: importVC)
        present(navController, animated: true)
    }

    private func addSingleWidget(_ type: SingleWidgetType, data: WorkoutData) {
        var widget: UIView?
        var size = CGSize(width: 160, height: 80)
        
        switch type {
        case .routeMap:
            // GPS 경로 데이터가 없으면 에러 표시
            guard data.hasRoute else {
                let alert = UIAlertController(
                    title: "경로 정보 없음",
                    message: "이 운동에는 GPS 경로 데이터가 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
                return
            }

            let mapView = RouteMapView()
            mapView.setRoute(data.route)
            routeMapView = mapView
            widget = mapView
            // Calculate optimal size based on route aspect ratio
            size = mapView.calculateOptimalSize(maxDimension: 250)
            
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

        case .text:
            let w = TextWidget()
            w.configure(text: "텍스트 입력")
            w.textDelegate = self
            widget = w
            size = CGSize(width: 200, height: 60)

        case .location:
            guard let firstLocation = data.route.first else {
                // Show error if no GPS data
                let alert = UIAlertController(
                    title: "위치 정보 없음",
                    message: "이 운동에는 GPS 경로 데이터가 없습니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
                return
            }

            let w = LocationWidget()
            widget = w
            size = CGSize(width: 220, height: 50)

            // Configure asynchronously (geocoding takes time)
            w.configure(location: firstLocation) { [weak self] success in
                if success {
                    print("✅ Location widget configured successfully")
                } else {
                    print("⚠️ Location widget configuration failed")
                }
            }
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

    // MARK: - Text Path Drawing

    private var textPathDrawingOverlay: TextPathDrawingOverlay?
    private var pendingTextForPath: String = ""

    @objc private func showTextPathInput() {
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
    }

    // MARK: - 템플릿 변경
    @objc private func changeTemplate() {
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
    }
    
    private func configureWithWorkoutData() {
        guard let data = workoutData else { return }

        // GPS 경로 데이터가 있을 때만 경로 맵 뷰 추가
        if data.hasRoute {
            let mapView = RouteMapView()
            mapView.setRoute(data.route)
            routeMapView = mapView

            // addWidget으로 추가하여 다른 위젯과 동일하게 처리
            contentView.addSubview(mapView)
            widgets.append(mapView)

            // Calculate optimal size based on route aspect ratio
            let mapSize = mapView.calculateOptimalSize(maxDimension: 280)
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
        }

        // 기본 위젯만 생성 (거리, 시간, 평균 페이스)
        createDefaultWidgets(for: data)
    }

    private func createDefaultWidgets(for data: WorkoutData) {
        let widgetSize = CGSize(width: 160, height: 80)

        // GPS 경로가 없으면 위젯을 더 위쪽에 배치
        let startY: CGFloat = data.hasRoute ? 350 : 100

        // 1. 거리 위젯
        let distanceWidget = DistanceWidget()
        distanceWidget.configure(distance: data.distance)
        addWidget(distanceWidget, size: widgetSize, position: CGPoint(x: 30, y: startY))

        // 2. 시간 위젯
        let durationWidget = DurationWidget()
        durationWidget.configure(duration: data.duration)
        addWidget(durationWidget, size: widgetSize, position: CGPoint(x: 210, y: startY))

        // 3. 페이스 위젯
        let paceWidget = PaceWidget()
        paceWidget.configure(pace: data.pace)
        addWidget(paceWidget, size: widgetSize, position: CGPoint(x: 30, y: startY + 120))
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
        contentView.bringSubviewToFront(widget)
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
    }

    func selectionManager(_ manager: SelectionManager, didSelectMultiple items: [Selectable]) {
        updateMultiSelectToolbarState()
    }

    func selectionManager(_ manager: SelectionManager, didEnterMultiSelectMode: Bool) {
        if didEnterMultiSelectMode {
            showMultiSelectToolbar()
        } else {
            hideMultiSelectToolbar()
        }
    }
}

// MARK: - TemplateGroupDelegate
extension WorkoutDetailViewController: TemplateGroupDelegate {
    func templateGroupDidConfirm(_ group: TemplateGroupView) {
        // Group confirmed - deselect it
        selectionManager.deselectItem(group)
    }

    func templateGroupDidRequestUngroup(_ group: TemplateGroupView) {
        // Ungroup the items and add them back to contentView
        let ungroupedItems = group.ungroupItems(to: contentView)

        // Register each item with selection manager
        for item in ungroupedItems {
            if var selectable = item as? Selectable {
                selectable.selectionDelegate = self
                selectionManager.registerItem(selectable)
            }
            // Add to widgets array
            widgets.append(item)
        }

        // Remove the group from templateGroups array
        if let index = templateGroups.firstIndex(where: { $0 === group }) {
            templateGroups.remove(at: index)
        }

        // Unregister and remove the group
        selectionManager.unregisterItem(group)
        group.removeFromSuperview()

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
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

        // Route based on why the picker was opened
        switch documentPickerPurpose {
        case .templateImport:
            handleImportedTemplateFile(at: fileURL)
        }
    }

    private func handleImportedTemplateFile(at fileURL: URL) {
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

// MARK: - ImportWorkoutViewControllerDelegate
extension WorkoutDetailViewController: ImportWorkoutViewControllerDelegate {
    func importWorkoutViewController(_ controller: ImportWorkoutViewController, didImport data: ImportedWorkoutData, mode: ImportMode, attachTo: WorkoutData?) {
        // Add imported workout as a group
        addImportedWorkoutGroup(data)
    }

    func importWorkoutViewControllerDidCancel(_ controller: ImportWorkoutViewController) {
        // Nothing to do
    }
}

// MARK: - TextWidgetDelegate
extension WorkoutDetailViewController: TextWidgetDelegate {
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

// MARK: - CustomGradientPickerDelegate
extension WorkoutDetailViewController: CustomGradientPickerDelegate {
    func customGradientPicker(_ picker: CustomGradientPickerViewController, didSelectColors colors: [UIColor], direction: GradientDirection) {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
        backgroundTemplateView.applyCustomGradient(colors: colors, direction: direction)
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

    // Detect aspect ratio from canvas size
    static func detect(from size: CGSize) -> AspectRatio {
        let calculatedRatio = size.height / size.width
        let epsilon: CGFloat = 0.1  // Tolerance for ratio matching

        // Find the closest matching aspect ratio
        for aspectRatio in AspectRatio.allCases {
            if abs(calculatedRatio - aspectRatio.ratio) < epsilon {
                return aspectRatio
            }
        }

        // Default to 9:16 if no match found
        return .portrait9_16
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
