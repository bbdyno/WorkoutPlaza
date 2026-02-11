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

    /// Widget factory closure injected from the detail VC for template preview
    var widgetFactory: ((WidgetItem, CGRect) -> UIView?)?
    /// Available built-in templates for selection
    var availableTemplates: [WidgetTemplate] = []

    private var selectedFields: Set<ImportField> = Set(ImportField.allCases)
    private var ownerName: String = ""
    private var selectedTemplate: WidgetTemplate?

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
        textField.placeholder = WorkoutPlazaStrings.Import.Owner.name
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
        label.text = WorkoutPlazaStrings.Import.Owner.name
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = ColorSystem.subText
        return label
    }()

    private let fieldsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Import.Select.data
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



    private let templateSectionLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Import.Select.template
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let selectedTemplateNameLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Import.Default.layout
        label.font = .systemFont(ofSize: 16)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let selectedTemplateDescLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Import.Default.Layout.desc
        label.font = .systemFont(ofSize: 13)
        label.textColor = ColorSystem.subText
        label.numberOfLines = 0
        return label
    }()

    private let templateChevronImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = ColorSystem.subText
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let clearTemplateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = ColorSystem.subText
        button.isHidden = true
        return button
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
        title = importMode == .createNew ? WorkoutPlazaStrings.Import.As.My.record : WorkoutPlazaStrings.Import.As.Other.title

        // Navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: WorkoutPlazaStrings.Import.action,
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

        // Add template section (always shown when we have available templates or included template)
        let hasIncludedTemplate = shareableWorkout?.template != nil
        let hasAvailableTemplates = !availableTemplates.isEmpty
        if hasIncludedTemplate || hasAvailableTemplates {
            contentStackView.addArrangedSubview(templateSectionLabel)

            let templateContainer = createSectionContainer()
            let templateRow = UIView()

            templateRow.addSubview(selectedTemplateNameLabel)
            templateRow.addSubview(selectedTemplateDescLabel)
            templateRow.addSubview(templateChevronImageView)
            templateRow.addSubview(clearTemplateButton)

            selectedTemplateNameLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(4)
                make.leading.equalToSuperview()
                make.trailing.lessThanOrEqualTo(clearTemplateButton.snp.leading).offset(-8)
            }

            selectedTemplateDescLabel.snp.makeConstraints { make in
                make.top.equalTo(selectedTemplateNameLabel.snp.bottom).offset(2)
                make.leading.equalToSuperview()
                make.trailing.lessThanOrEqualTo(templateChevronImageView.snp.leading).offset(-8)
                make.bottom.equalToSuperview().inset(4)
            }

            templateChevronImageView.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalTo(16)
            }

            clearTemplateButton.snp.makeConstraints { make in
                make.trailing.equalTo(templateChevronImageView.snp.leading).offset(-4)
                make.centerY.equalTo(selectedTemplateNameLabel)
                make.width.height.equalTo(20)
            }

            templateContainer.addSubview(templateRow)
            templateRow.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(12)
            }

            let tapGestureTemplate = UITapGestureRecognizer(target: self, action: #selector(templateSelectionTapped))
            templateContainer.addGestureRecognizer(tapGestureTemplate)

            clearTemplateButton.addTarget(self, action: #selector(clearTemplateTapped), for: .touchUpInside)

            contentStackView.addArrangedSubview(templateContainer)

            // If included template exists, pre-select it
            if let included = shareableWorkout?.template, included.isCompatible {
                selectTemplate(included)
            }
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
        label.text = field.displayName
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
            headerLabel.text = WorkoutPlazaStrings.Home.Record.type(workout.workout.type)
        } else {
            let displayName = ownerName.isEmpty ? WorkoutPlazaStrings.Import.Unknown.owner : ownerName
            headerLabel.text = WorkoutPlazaStrings.Home.Record.owner(displayName, workout.workout.type)
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
            finalOwnerName = ownerName.isEmpty ? (workout.creator?.name ?? WorkoutPlazaStrings.Import.Unknown.owner) : ownerName
        }

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

    @objc private func templateSelectionTapped() {
        showTemplateSelectionSheet()
    }

    @objc private func clearTemplateTapped() {
        selectedTemplate = nil
        updateTemplateSelectionUI()
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

    // MARK: - Template Selection

    private func selectTemplate(_ template: WidgetTemplate) {
        selectedTemplate = template
        updateTemplateSelectionUI()
    }

    private func updateTemplateSelectionUI() {
        if let template = selectedTemplate {
            selectedTemplateNameLabel.text = template.name
            selectedTemplateDescLabel.text = template.description
            clearTemplateButton.isHidden = false
        } else {
            selectedTemplateNameLabel.text = WorkoutPlazaStrings.Import.Default.layout
            selectedTemplateDescLabel.text = WorkoutPlazaStrings.Import.Default.Layout.desc
            clearTemplateButton.isHidden = true
        }
    }

    private func showTemplateSelectionSheet() {
        var templateItems: [ToolSheetItem] = []

        // Add included template if available
        if let included = shareableWorkout?.template, included.isCompatible {
            templateItems.append(ToolSheetItem(
                id: "included_\(included.name)",
                title: "📎 \(included.name)",
                description: WorkoutPlazaStrings.Import.Included.template,
                iconName: "doc.badge.arrow.up",
                previewProvider: widgetFactory != nil ? { [weak self] in
                    self?.createTemplatePreview(for: included) ?? UIView()
                } : nil,
                action: { [weak self] in
                    self?.selectTemplate(included)
                }
            ))
        }

        // Add built-in templates
        for template in availableTemplates {
            templateItems.append(ToolSheetItem(
                id: template.name,
                title: template.name,
                description: template.description,
                iconName: "rectangle.3.group",
                previewProvider: widgetFactory != nil ? { [weak self] in
                    self?.createTemplatePreview(for: template) ?? UIView()
                } : nil,
                action: { [weak self] in
                    self?.selectTemplate(template)
                }
            ))
        }

        guard !templateItems.isEmpty else { return }

        let sections = [ToolSheetSection(title: WorkoutPlazaStrings.Import.Template.section, items: templateItems)]
        let sheetVC = ToolSheetViewController(sections: sections)
        sheetVC.title = WorkoutPlazaStrings.Import.Select.template

        let nav = UINavigationController(rootViewController: sheetVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        present(nav, animated: true)
    }

    private func createTemplatePreview(for template: WidgetTemplate) -> UIView? {
        guard let factory = widgetFactory else { return nil }
        return template.thumbnailProvider(widgetFactory: factory)()
    }
}
