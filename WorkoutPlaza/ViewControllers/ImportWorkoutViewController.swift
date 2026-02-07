//
//  ImportWorkoutViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/19/26.
//

import UIKit
import SnapKit

// MARK: - Delegate Protocol
protocol ImportWorkoutViewControllerDelegate: AnyObject {
    func importWorkoutViewController(_ controller: ImportWorkoutViewController, didImport data: ImportedWorkoutData, mode: ImportMode, attachTo: WorkoutData?)
    func importWorkoutViewControllerDidCancel(_ controller: ImportWorkoutViewController)
}

class ImportWorkoutViewController: UIViewController {

    // MARK: - Properties
    var shareableWorkout: ShareableWorkout?
    var importMode: ImportMode = .createNew
    var attachToWorkout: WorkoutData?
    weak var delegate: ImportWorkoutViewControllerDelegate?

    private var selectedFields: Set<ImportField> = Set(ImportField.allCases)
    private var ownerName: String = ""

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        return stack
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = ColorSystem.mainText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let ownerNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "기록 소유자 이름"
        textField.borderStyle = .none
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = ColorSystem.mainText
        textField.clearButtonMode = .whileEditing
        textField.backgroundColor = ColorSystem.background
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = ColorSystem.divider.cgColor

        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        textField.rightViewMode = .unlessEditing

        return textField
    }()

    private let ownerNameLabel: UILabel = {
        let label = UILabel()
        label.text = "기록 소유자 이름"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = ColorSystem.subText
        return label
    }()

    private let fieldsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "가져올 데이터 선택"
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let fieldsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()


    private var fieldCheckboxes: [ImportField: UISwitch] = [:]



    // Template option
    private var useIncludedTemplate: Bool = false

    private let templateSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "포함된 템플릿"
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let templatePreviewCanvas: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    private let templateNameInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let useTemplateSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = false
        toggle.onTintColor = ColorSystem.primaryGreen
        return toggle
    }()

    private let useTemplateLabel: UILabel = {
        let label = UILabel()
        label.text = "이 템플릿으로 가져오기"
        label.font = .systemFont(ofSize: 16)
        label.textColor = ColorSystem.mainText
        label.numberOfLines = 0
        return label
    }()

    private let templateIncompatibleLabel: UILabel = {
        let label = UILabel()
        label.text = "이 템플릿은 최신 버전의 앱이 필요합니다."
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // Containers for conditional display
    private var ownerNameContainer: UIView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithWorkout()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = ColorSystem.background

        // Set title based on mode
        title = importMode == .createNew ? "내 기록으로 가져오기" : "타인 기록 가져오기"

        // Navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "가져오기",
            style: .done,
            target: self,
            action: #selector(importTapped)
        )

        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }

        // Add header
        contentStackView.addArrangedSubview(headerLabel)
        contentStackView.setCustomSpacing(24, after: headerLabel)

        // Add owner name section - ONLY for attachToExisting mode
        if importMode == .attachToExisting {
            let container = createSectionContainer()
            container.addSubview(ownerNameLabel)
            container.addSubview(ownerNameTextField)

            ownerNameLabel.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(12)
            }

            ownerNameTextField.snp.makeConstraints { make in
                make.top.equalTo(ownerNameLabel.snp.bottom).offset(8)
                make.leading.trailing.bottom.equalToSuperview().inset(12)
                make.height.equalTo(44)
            }

            contentStackView.addArrangedSubview(container)
            ownerNameContainer = container

            ownerNameTextField.addTarget(self, action: #selector(ownerNameChanged), for: .editingChanged)
        }

        // Add fields selection section
        contentStackView.addArrangedSubview(fieldsHeaderLabel)

        let fieldsContainer = createSectionContainer()
        fieldsContainer.addSubview(fieldsStackView)

        fieldsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        setupFieldCheckboxes()
        contentStackView.addArrangedSubview(fieldsContainer)

        // Add template section if template is included
        if let template = shareableWorkout?.template {
            contentStackView.addArrangedSubview(templateSectionLabel)

            let templateContainer = createSectionContainer()
            let templateStack = UIStackView()
            templateStack.axis = .vertical
            templateStack.spacing = 12

            // Template name
            templateNameInfoLabel.text = "\(template.name) - \(template.description)"
            templateStack.addArrangedSubview(templateNameInfoLabel)

            // Mini canvas preview
            let canvasWrapper = UIView()
            canvasWrapper.addSubview(templatePreviewCanvas)

            let templateCanvasSize: CGSize
            if let tcs = template.canvasSize {
                templateCanvasSize = CGSize(width: tcs.width, height: tcs.height)
            } else {
                templateCanvasSize = CGSize(width: 414, height: 700)
            }

            let previewWidth: CGFloat = 140
            let aspectRatio = templateCanvasSize.height / templateCanvasSize.width
            let previewHeight = previewWidth * aspectRatio

            templatePreviewCanvas.snp.makeConstraints { make in
                make.centerX.top.bottom.equalToSuperview()
                make.width.equalTo(previewWidth)
                make.height.equalTo(previewHeight)
            }
            templateStack.addArrangedSubview(canvasWrapper)

            // Render widget placeholders in the canvas
            DispatchQueue.main.async { [weak self] in
                self?.renderTemplatePreviewWidgets(template: template, canvasSize: CGSize(width: previewWidth, height: previewHeight))
            }

            // Toggle row
            let toggleRow = UIView()
            toggleRow.addSubview(useTemplateLabel)
            toggleRow.addSubview(useTemplateSwitch)

            useTemplateLabel.snp.makeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.trailing.lessThanOrEqualTo(useTemplateSwitch.snp.leading).offset(-12)
            }

            useTemplateSwitch.snp.makeConstraints { make in
                make.trailing.centerY.equalToSuperview()
            }

            templateStack.addArrangedSubview(toggleRow)

            // Incompatible label
            if !template.isCompatible {
                templateIncompatibleLabel.isHidden = false
                useTemplateSwitch.isEnabled = false
                templateStack.addArrangedSubview(templateIncompatibleLabel)
            }

            useTemplateSwitch.addTarget(self, action: #selector(templateToggleChanged), for: .valueChanged)

            templateContainer.addSubview(templateStack)
            templateStack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(12)
            }
            contentStackView.addArrangedSubview(templateContainer)
        }

        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func createSectionContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous

        // Subtle shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.04
        view.layer.shadowRadius = 8
        view.layer.masksToBounds = false

        return view
    }

    private func setupFieldCheckboxes() {
        for field in ImportField.allCases {
            let rowView = createFieldRow(for: field)
            fieldsStackView.addArrangedSubview(rowView)
        }
    }

    private func createFieldRow(for field: ImportField) -> UIView {
        let container = UIView()

        let iconImageView = UIImageView(image: UIImage(systemName: field.icon))
        iconImageView.tintColor = ColorSystem.controlTint
        iconImageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = field.rawValue
        label.font = .systemFont(ofSize: 16)
        label.textColor = ColorSystem.mainText

        let toggle = UISwitch()
        toggle.isOn = true
        toggle.onTintColor = ColorSystem.controlTint
        toggle.tag = ImportField.allCases.firstIndex(of: field) ?? 0
        toggle.addTarget(self, action: #selector(fieldToggleChanged(_:)), for: .valueChanged)

        fieldCheckboxes[field] = toggle

        container.addSubview(iconImageView)
        container.addSubview(label)
        container.addSubview(toggle)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        toggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        container.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        return container
    }

    private func configureWithWorkout() {
        guard let workout = shareableWorkout else { return }

        // Pre-fill owner name (only for attachToExisting mode)
        if importMode == .attachToExisting, let creator = workout.creator?.name {
            ownerNameTextField.text = creator
            ownerName = creator
        }

        updateHeaderLabel()
    }

    private func updateHeaderLabel() {
        guard let workout = shareableWorkout else { return }

        if importMode == .createNew {
            headerLabel.text = "\(workout.workout.type) 기록"
        } else {
            let displayName = ownerName.isEmpty ? "알 수 없음" : ownerName
            headerLabel.text = "\(displayName)님의 \(workout.workout.type) 기록"
        }
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        delegate?.importWorkoutViewControllerDidCancel(self)
        dismiss(animated: true)
    }

    @objc private func importTapped() {
        guard let workout = shareableWorkout else { return }

        // For createNew mode, owner name is not needed
        let finalOwnerName: String
        if importMode == .createNew {
            finalOwnerName = ""  // Not used for my own record
        } else {
            finalOwnerName = ownerName.isEmpty ? (workout.creator?.name ?? "알 수 없음") : ownerName
        }

        // Determine selected template
        let selectedTemplate: WidgetTemplate? = useIncludedTemplate ? workout.template : nil

        // Create imported workout data
        let importedData = ImportedWorkoutData(
            ownerName: finalOwnerName,
            originalData: workout.workout,
            selectedFields: selectedFields,
            selectedTemplate: selectedTemplate
        )

        delegate?.importWorkoutViewController(self, didImport: importedData, mode: importMode, attachTo: attachToWorkout)
        dismiss(animated: true)
    }

    @objc private func ownerNameChanged() {
        ownerName = ownerNameTextField.text ?? ""
        updateHeaderLabel()
    }

    @objc private func templateToggleChanged(_ sender: UISwitch) {
        useIncludedTemplate = sender.isOn
    }

    @objc private func fieldToggleChanged(_ sender: UISwitch) {
        let field = ImportField.allCases[sender.tag]

        if sender.isOn {
            selectedFields.insert(field)
        } else {
            selectedFields.remove(field)
        }

        updateImportButtonState()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func updateImportButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = !selectedFields.isEmpty
    }

    // MARK: - Template Preview Rendering

    private func renderTemplatePreviewWidgets(template: WidgetTemplate, canvasSize: CGSize) {
        let templateCanvasSize: CGSize
        if let tcs = template.canvasSize {
            templateCanvasSize = CGSize(width: tcs.width, height: tcs.height)
        } else {
            templateCanvasSize = CGSize(width: 414, height: 700)
        }

        for item in template.items {
            let frame = TemplateManager.absoluteFrame(from: item, canvasSize: canvasSize, templateCanvasSize: templateCanvasSize)

            let placeholder = UIView(frame: frame)
            placeholder.backgroundColor = ColorSystem.primaryGreen.withAlphaComponent(0.15)
            placeholder.layer.cornerRadius = 4
            placeholder.layer.borderWidth = 1
            placeholder.layer.borderColor = ColorSystem.primaryGreen.withAlphaComponent(0.3).cgColor

            let iconView = UIImageView(image: UIImage(systemName: item.type.iconName))
            iconView.tintColor = ColorSystem.primaryGreen.withAlphaComponent(0.6)
            iconView.contentMode = .scaleAspectFit
            placeholder.addSubview(iconView)

            let iconSize = min(frame.width, frame.height) * 0.4
            iconView.frame = CGRect(
                x: (frame.width - iconSize) / 2,
                y: (frame.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            templatePreviewCanvas.addSubview(placeholder)
        }
    }
}
