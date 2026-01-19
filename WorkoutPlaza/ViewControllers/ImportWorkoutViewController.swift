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
    private var useCurrentLayout: Bool = false

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
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let ownerNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "기록 소유자 이름"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.clearButtonMode = .whileEditing
        return textField
    }()

    private let ownerNameLabel: UILabel = {
        let label = UILabel()
        label.text = "기록 소유자 이름"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let fieldsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "가져올 데이터 선택"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let fieldsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()

    private let previewHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "미리보기"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let previewContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let previewStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()

    private var fieldCheckboxes: [ImportField: UISwitch] = [:]

    private let layoutOptionLabel: UILabel = {
        let label = UILabel()
        label.text = "레이아웃 옵션"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let useCurrentLayoutSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = false
        return toggle
    }()

    private let useCurrentLayoutLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 템플릿과 동일하게 가져오기"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private let layoutDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "활성화하면 현재 화면의 위젯 배치와 동일한 위치, 크기로 가져옵니다."
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithWorkout()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "운동 기록 가져오기"

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

        // Add owner name section
        let ownerNameContainer = createSectionContainer()
        ownerNameContainer.addSubview(ownerNameLabel)
        ownerNameContainer.addSubview(ownerNameTextField)

        ownerNameLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }

        ownerNameTextField.snp.makeConstraints { make in
            make.top.equalTo(ownerNameLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
            make.height.equalTo(44)
        }

        contentStackView.addArrangedSubview(ownerNameContainer)

        ownerNameTextField.addTarget(self, action: #selector(ownerNameChanged), for: .editingChanged)

        // Add fields selection section
        contentStackView.addArrangedSubview(fieldsHeaderLabel)

        let fieldsContainer = createSectionContainer()
        fieldsContainer.addSubview(fieldsStackView)

        fieldsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        setupFieldCheckboxes()
        contentStackView.addArrangedSubview(fieldsContainer)

        // Add layout option section
        contentStackView.addArrangedSubview(layoutOptionLabel)

        let layoutContainer = createSectionContainer()
        let layoutStack = UIStackView()
        layoutStack.axis = .vertical
        layoutStack.spacing = 8

        let toggleRow = UIView()
        toggleRow.addSubview(useCurrentLayoutLabel)
        toggleRow.addSubview(useCurrentLayoutSwitch)

        useCurrentLayoutLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(useCurrentLayoutSwitch.snp.leading).offset(-12)
        }

        useCurrentLayoutSwitch.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }

        layoutStack.addArrangedSubview(toggleRow)
        layoutStack.addArrangedSubview(layoutDescriptionLabel)

        layoutContainer.addSubview(layoutStack)
        layoutStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        useCurrentLayoutSwitch.addTarget(self, action: #selector(layoutToggleChanged), for: .valueChanged)
        contentStackView.addArrangedSubview(layoutContainer)

        // Add preview section
        contentStackView.addArrangedSubview(previewHeaderLabel)

        previewContainerView.addSubview(previewStackView)
        previewStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        contentStackView.addArrangedSubview(previewContainerView)

        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func createSectionContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
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
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = field.rawValue
        label.font = .systemFont(ofSize: 16)

        let toggle = UISwitch()
        toggle.isOn = true
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

        // Set header text
        let creatorName = workout.creator?.name ?? "알 수 없음"
        headerLabel.text = "\(creatorName)님의 \(workout.workout.type) 기록"

        // Pre-fill owner name
        if let creator = workout.creator?.name {
            ownerNameTextField.text = creator
            ownerName = creator
        }

        updatePreview()
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        delegate?.importWorkoutViewControllerDidCancel(self)
        dismiss(animated: true)
    }

    @objc private func importTapped() {
        guard let workout = shareableWorkout else { return }

        // Validate owner name
        let finalOwnerName = ownerName.isEmpty ? (workout.creator?.name ?? "알 수 없음") : ownerName

        // Create imported workout data
        let importedData = ImportedWorkoutData(
            ownerName: finalOwnerName,
            originalData: workout.workout,
            selectedFields: selectedFields,
            useCurrentLayout: useCurrentLayout
        )

        delegate?.importWorkoutViewController(self, didImport: importedData, mode: importMode, attachTo: attachToWorkout)
        dismiss(animated: true)
    }

    @objc private func ownerNameChanged() {
        ownerName = ownerNameTextField.text ?? ""
        updatePreview()
    }

    @objc private func layoutToggleChanged(_ sender: UISwitch) {
        useCurrentLayout = sender.isOn
    }

    @objc private func fieldToggleChanged(_ sender: UISwitch) {
        let field = ImportField.allCases[sender.tag]

        if sender.isOn {
            selectedFields.insert(field)
        } else {
            selectedFields.remove(field)
        }

        updatePreview()
        updateImportButtonState()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Preview
    private func updatePreview() {
        guard let workout = shareableWorkout else { return }

        // Clear existing preview
        previewStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Owner name label
        let ownerLabel = UILabel()
        let displayOwnerName = ownerName.isEmpty ? (workout.creator?.name ?? "알 수 없음") : ownerName
        ownerLabel.text = "\(displayOwnerName)의 기록"
        ownerLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        ownerLabel.textColor = .systemOrange
        previewStackView.addArrangedSubview(ownerLabel)

        // Selected fields preview
        let data = workout.workout

        if selectedFields.contains(.distance) {
            addPreviewRow(title: "거리", value: String(format: "%.2f km", data.distance / 1000))
        }

        if selectedFields.contains(.duration) {
            let minutes = Int(data.duration) / 60
            let seconds = Int(data.duration) % 60
            addPreviewRow(title: "시간", value: String(format: "%02d:%02d", minutes, seconds))
        }

        if selectedFields.contains(.pace) {
            let paceMinutes = Int(data.pace)
            let paceSeconds = Int((data.pace - Double(paceMinutes)) * 60)
            addPreviewRow(title: "페이스", value: String(format: "%d'%02d\"/km", paceMinutes, paceSeconds))
        }

        if selectedFields.contains(.speed) {
            addPreviewRow(title: "속도", value: String(format: "%.1f km/h", data.avgSpeed))
        }

        if selectedFields.contains(.calories) {
            addPreviewRow(title: "칼로리", value: String(format: "%.0f kcal", data.calories))
        }

        if selectedFields.contains(.date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd HH:mm"
            addPreviewRow(title: "날짜", value: formatter.string(from: data.startDate))
        }

        if selectedFields.contains(.route) && !data.route.isEmpty {
            addPreviewRow(title: "경로", value: "\(data.route.count)개 포인트")
        }

        // Empty state
        if selectedFields.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "선택된 데이터가 없습니다"
            emptyLabel.font = .systemFont(ofSize: 14)
            emptyLabel.textColor = .tertiaryLabel
            emptyLabel.textAlignment = .center
            previewStackView.addArrangedSubview(emptyLabel)
        }
    }

    private func addPreviewRow(title: String, value: String) {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }

        container.snp.makeConstraints { make in
            make.height.equalTo(28)
        }

        previewStackView.addArrangedSubview(container)
    }

    private func updateImportButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = !selectedFields.isEmpty
    }
}
