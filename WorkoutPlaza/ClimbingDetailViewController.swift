//
//  ClimbingDetailViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit
import SnapKit

class ClimbingDetailViewController: UIViewController {

    // MARK: - Properties
    private let climbingData: ClimbingData
    private let canvasSize: CGSize

    private var widgets: [UIView] = []

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backgroundTemplateView = BackgroundTemplateView()

    // Toolbar
    private let toolbar: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        stack.layer.cornerRadius = 12
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()

    private lazy var addWidgetButton: UIButton = createToolbarButton(icon: "plus.circle", action: #selector(showAddWidgetMenu))
    private lazy var colorPickerButton: UIButton = createToolbarButton(icon: "paintpalette", action: #selector(showColorPicker))
    private lazy var fontPickerButton: UIButton = createToolbarButton(icon: "textformat", action: #selector(showFontPicker))
    private lazy var backgroundButton: UIButton = createToolbarButton(icon: "photo", action: #selector(showBackgroundOptions))
    private lazy var saveButton: UIButton = createToolbarButton(icon: "square.and.arrow.down", action: #selector(saveImage))

    // Selection Manager
    private let selectionManager = SelectionManager()

    // MARK: - Initialization
    init(climbingData: ClimbingData, canvasSize: CGSize = CGSize(width: 360, height: 640)) {
        self.climbingData = climbingData
        self.canvasSize = canvasSize
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDefaultWidgets()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "클라이밍 기록"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "완료",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )

        // Scroll View
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-80)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(canvasSize.width)
            make.height.equalTo(canvasSize.height)
        }

        // Center content in scroll view
        scrollView.contentInset = UIEdgeInsets(
            top: 20,
            left: max(0, (view.bounds.width - canvasSize.width) / 2),
            bottom: 20,
            right: max(0, (view.bounds.width - canvasSize.width) / 2)
        )

        // Background
        contentView.addSubview(backgroundTemplateView)
        backgroundTemplateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundTemplateView.applyTemplate(.gradient3) // Orange gradient for climbing

        // Toolbar
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.centerX.equalToSuperview()
            make.height.equalTo(56)
        }

        toolbar.addArrangedSubview(addWidgetButton)
        toolbar.addArrangedSubview(colorPickerButton)
        toolbar.addArrangedSubview(fontPickerButton)
        toolbar.addArrangedSubview(backgroundButton)
        toolbar.addArrangedSubview(saveButton)
    }

    private func createToolbarButton(icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: action, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }
        return button
    }

    private func setupDefaultWidgets() {
        let padding: CGFloat = 20
        let widgetWidth = canvasSize.width - (padding * 2)
        let widgetHeight: CGFloat = 70
        let halfWidth = (widgetWidth - 12) / 2
        var currentY: CGFloat = padding

        // Row 1: Gym Widget (full width)
        let gymWidget = ClimbingGymWidget()
        gymWidget.frame = CGRect(x: padding, y: currentY, width: widgetWidth, height: widgetHeight)
        gymWidget.configure(gymName: climbingData.gymName)
        gymWidget.initialSize = gymWidget.frame.size
        addWidget(gymWidget)
        currentY += widgetHeight + 12

        // Row 2: Discipline + Date (side by side)
        let disciplineWidget = ClimbingDisciplineWidget()
        disciplineWidget.frame = CGRect(x: padding, y: currentY, width: halfWidth, height: widgetHeight)
        disciplineWidget.configure(discipline: climbingData.discipline)
        disciplineWidget.initialSize = disciplineWidget.frame.size
        addWidget(disciplineWidget)

        let dateWidget = DateWidget()
        dateWidget.frame = CGRect(x: padding + halfWidth + 12, y: currentY, width: halfWidth, height: widgetHeight)
        dateWidget.configure(startDate: climbingData.sessionDate)
        dateWidget.initialSize = dateWidget.frame.size
        addWidget(dateWidget)
        currentY += widgetHeight + 12

        // Row 3: Session Summary (full width)
        let sessionWidget = ClimbingSessionWidget()
        sessionWidget.frame = CGRect(x: padding, y: currentY, width: widgetWidth, height: widgetHeight)
        sessionWidget.configure(sent: climbingData.sentRoutes, total: climbingData.totalRoutes)
        sessionWidget.initialSize = sessionWidget.frame.size
        addWidget(sessionWidget)
        currentY += widgetHeight + 12

        // Row 4: Attempts/Takes + Highest Grade (side by side)
        var hasLeftWidget = false

        if climbingData.discipline == .bouldering {
            let attemptsWidget = ClimbingAttemptsWidget()
            attemptsWidget.frame = CGRect(x: padding, y: currentY, width: halfWidth, height: widgetHeight)
            attemptsWidget.configure(attempts: climbingData.totalAttempts)
            attemptsWidget.initialSize = attemptsWidget.frame.size
            addWidget(attemptsWidget)
            hasLeftWidget = true
        } else if climbingData.discipline == .leadEndurance {
            let takesWidget = ClimbingTakesWidget()
            takesWidget.frame = CGRect(x: padding, y: currentY, width: halfWidth, height: widgetHeight)
            takesWidget.configure(takes: climbingData.totalTakes)
            takesWidget.initialSize = takesWidget.frame.size
            addWidget(takesWidget)
            hasLeftWidget = true
        }

        if let highestGrade = climbingData.highestGradeSent, !highestGrade.isEmpty {
            let highestWidget = ClimbingHighestGradeWidget()
            let xPos = hasLeftWidget ? padding + halfWidth + 12 : padding
            let width = hasLeftWidget ? halfWidth : widgetWidth
            highestWidget.frame = CGRect(x: xPos, y: currentY, width: width, height: widgetHeight)
            highestWidget.configure(highestGrade: highestGrade)
            highestWidget.initialSize = highestWidget.frame.size
            addWidget(highestWidget)
        }

        if hasLeftWidget || climbingData.highestGradeSent != nil {
            currentY += widgetHeight + 12
        }

        // Row 5+: Individual route grades (up to 4, 2 per row)
        let routesWithGrades = climbingData.routes.filter { !$0.grade.isEmpty }.prefix(4)
        for (index, route) in routesWithGrades.enumerated() {
            let isLeftColumn = index % 2 == 0
            let xPos = isLeftColumn ? padding : padding + halfWidth + 12

            if isLeftColumn && index > 0 {
                currentY += widgetHeight + 8
            }

            let gradeWidget = ClimbingGradeWidget()
            gradeWidget.frame = CGRect(x: xPos, y: currentY, width: halfWidth, height: widgetHeight)
            gradeWidget.configure(grade: route.grade)
            gradeWidget.initialSize = gradeWidget.frame.size
            addWidget(gradeWidget)
        }
    }

    private func addWidget(_ widget: UIView) {
        contentView.addSubview(widget)
        widgets.append(widget)

        if var selectable = widget as? Selectable {
            selectable.selectionDelegate = self
            selectionManager.registerItem(selectable)
        }
    }

    // MARK: - Actions
    @objc private func doneTapped() {
        navigationController?.popToRootViewController(animated: true)
    }

    @objc private func showAddWidgetMenu() {
        let actionSheet = UIAlertController(title: "위젯 추가", message: nil, preferredStyle: .actionSheet)

        let climbingWidgets: [(String, WidgetType)] = [
            ("클라이밍짐", .climbingGym),
            ("종목", .climbingDiscipline),
            ("난이도", .climbingGrade),
            ("시도 횟수", .climbingAttempts),
            ("테이크", .climbingTakes),
            ("세션 기록", .climbingSession),
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
        let widgetSize = CGSize(width: 160, height: 80)
        let centerX = (canvasSize.width - widgetSize.width) / 2
        let centerY = (canvasSize.height - widgetSize.height) / 2

        var widget: UIView?

        switch type {
        case .climbingGym:
            let w = ClimbingGymWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(gymName: climbingData.gymName)
            w.initialSize = widgetSize
            widget = w

        case .climbingDiscipline:
            let w = ClimbingDisciplineWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(discipline: climbingData.discipline)
            w.initialSize = widgetSize
            widget = w

        case .climbingGrade:
            let w = ClimbingGradeWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(grade: climbingData.routes.first?.grade ?? "V0")
            w.initialSize = widgetSize
            widget = w

        case .climbingAttempts:
            let w = ClimbingAttemptsWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(attempts: climbingData.totalAttempts)
            w.initialSize = widgetSize
            widget = w

        case .climbingTakes:
            let w = ClimbingTakesWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(takes: climbingData.totalTakes)
            w.initialSize = widgetSize
            widget = w

        case .climbingSession:
            let w = ClimbingSessionWidget()
            w.frame = CGRect(origin: CGPoint(x: centerX, y: centerY), size: widgetSize)
            w.configure(sent: climbingData.sentRoutes, total: climbingData.totalRoutes)
            w.initialSize = widgetSize
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
            w.configure(startDate: climbingData.sessionDate)
            w.initialSize = widgetSize
            widget = w

        default:
            break
        }

        if let widget = widget {
            addWidget(widget)
        }
    }

    @objc private func showColorPicker() {
        guard selectionManager.currentlySelectedItem != nil else {
            showAlert(message: "먼저 위젯을 선택해주세요")
            return
        }

        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }

    @objc private func showFontPicker() {
        guard selectionManager.currentlySelectedItem != nil else {
            showAlert(message: "먼저 위젯을 선택해주세요")
            return
        }

        let actionSheet = UIAlertController(title: "폰트 선택", message: nil, preferredStyle: .actionSheet)

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

    @objc private func showBackgroundOptions() {
        let actionSheet = UIAlertController(title: "배경 선택", message: nil, preferredStyle: .actionSheet)

        let templates: [(String, BackgroundTemplateView.TemplateStyle)] = [
            ("오렌지 그라데이션", .gradient3),
            ("블루 그라데이션", .gradient1),
            ("퍼플 그라데이션", .gradient2),
            ("그린 그라데이션", .gradient4),
            ("다크", .dark),
            ("미니멀 화이트", .minimal)
        ]

        for (name, style) in templates {
            actionSheet.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.backgroundTemplateView.applyTemplate(style)
            })
        }

        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = backgroundButton
            popover.sourceRect = backgroundButton.bounds
        }

        present(actionSheet, animated: true)
    }

    @objc private func saveImage() {
        // Deselect all widgets before capture
        selectionManager.deselectAll()

        // Capture content view
        let renderer = UIGraphicsImageRenderer(size: contentView.bounds.size)
        let image = renderer.image { context in
            contentView.drawHierarchy(in: contentView.bounds, afterScreenUpdates: true)
        }

        // Save to photo library
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(message: "저장 실패: \(error.localizedDescription)")
        } else {
            showAlert(message: "이미지가 저장되었습니다!")
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SelectionDelegate
extension ClimbingDetailViewController: SelectionDelegate {
    func itemWasSelected(_ item: Selectable) {
        selectionManager.selectItem(item)
    }

    func itemWasDeselected(_ item: Selectable) {
        selectionManager.deselectItem(item)
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension ClimbingDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        selectionManager.currentlySelectedItem?.applyColor(viewController.selectedColor)
    }
}
