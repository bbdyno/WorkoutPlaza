//
//  ClimbingInputViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit

protocol ClimbingInputDelegate: AnyObject {
    func climbingInputDidSave(_ controller: ClimbingInputViewController)
    func climbingInput(_ controller: ClimbingInputViewController, didRequestCardFor session: ClimbingData)
}

class ClimbingInputViewController: UITableViewController {

    weak var delegate: ClimbingInputDelegate?

    // MARK: - Data
    private var gymName: String = ""
    private var selectedDiscipline: ClimbingDiscipline = .bouldering
    private var routes: [RouteData] = [RouteData()]

    struct RouteData {
        var selectedColorIndex: Int?
        var customColor: UIColor?
        var grade: String = ""
        var attempts: Int = 1
        var isSent: Bool = false

        var selectedColor: UIColor? {
            if let custom = customColor {
                return custom
            }
            if let index = selectedColorIndex {
                return RouteData.presetColors[index]
            }
            return nil
        }

        static let presetColors: [UIColor] = [
            .systemRed, .systemOrange, .systemYellow, .systemGreen,
            .systemBlue, .systemPurple, .systemPink, .white, .black, .systemGray
        ]
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "클라이밍"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissTapped)
        )
    }

    private func setupTableView() {
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(SegmentCell.self, forCellReuseIdentifier: "SegmentCell")
        tableView.register(RouteCell.self, forCellReuseIdentifier: "RouteCell")
        tableView.register(ButtonCell.self, forCellReuseIdentifier: "ButtonCell")
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    // MARK: - TableView DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // Gym, Discipline, Routes, Buttons
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Gym name
        case 1: return 1 // Discipline
        case 2: return routes.count // Routes
        case 3: return 2 // Add route + Create button
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "클라이밍짐"
        case 1: return "종목"
        case 2: return "루트 기록"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldCell
            cell.configure(placeholder: "짐 이름을 입력하세요", text: gymName) { [weak self] text in
                self?.gymName = text
            }
            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentCell", for: indexPath) as! SegmentCell
            cell.configure(
                items: ClimbingDiscipline.allCases.map { $0.displayName },
                selectedIndex: ClimbingDiscipline.allCases.firstIndex(of: selectedDiscipline) ?? 0
            ) { [weak self] index in
                self?.selectedDiscipline = ClimbingDiscipline.allCases[index]
                self?.tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
            }
            return cell

        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell", for: indexPath) as! RouteCell
            let route = routes[indexPath.row]
            cell.configure(
                routeNumber: indexPath.row + 1,
                route: route,
                discipline: selectedDiscipline,
                canDelete: routes.count > 1
            )
            cell.delegate = self
            cell.tag = indexPath.row
            return cell

        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonCell
            if indexPath.row == 0 {
                cell.configure(title: "+ 루트 추가", style: .secondary) { [weak self] in
                    self?.addRoute()
                }
            } else {
                cell.configure(title: "기록 생성", style: .primary) { [weak self] in
                    self?.createRecord()
                }
            }
            return cell

        default:
            return UITableViewCell()
        }
    }

    // MARK: - Actions

    private func addRoute() {
        routes.append(RouteData())
        tableView.insertRows(at: [IndexPath(row: routes.count - 1, section: 2)], with: .automatic)
    }

    private func deleteRoute(at index: Int) {
        guard routes.count > 1 else { return }
        routes.remove(at: index)
        tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
    }

    private func createRecord() {
        guard !gymName.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "클라이밍짐 이름을 입력해주세요.")
            return
        }

        var climbingRoutes: [ClimbingRoute] = []
        for route in routes {
            if route.selectedColor != nil || !route.grade.isEmpty {
                climbingRoutes.append(ClimbingRoute(
                    grade: route.grade,
                    colorHex: route.selectedColor?.toHexString(),
                    attempts: selectedDiscipline == .bouldering ? route.attempts : nil,
                    takes: selectedDiscipline == .leadEndurance ? route.attempts : nil,
                    isSent: route.isSent
                ))
            }
        }

        guard !climbingRoutes.isEmpty else {
            showAlert(message: "최소 하나의 루트를 기록해주세요.")
            return
        }

        let climbingData = ClimbingData(
            gymName: gymName,
            discipline: selectedDiscipline,
            routes: climbingRoutes,
            sessionDate: Date()
        )

        // 먼저 저장
        ClimbingDataManager.shared.addSession(climbingData)

        // 카드 생성 여부 묻기
        let alert = UIAlertController(
            title: "저장 완료",
            message: "클라이밍 기록이 저장되었습니다.\n공유용 카드를 만들까요?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "카드 만들기", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.climbingInput(self, didRequestCardFor: climbingData)
        })

        alert.addAction(UIAlertAction(title: "나중에", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.climbingInputDidSave(self)
        })

        present(alert, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - RouteCellDelegate

extension ClimbingInputViewController: RouteCellDelegate {
    func routeCellDidUpdate(_ cell: RouteCell, route: ClimbingInputViewController.RouteData) {
        guard cell.tag < routes.count else { return }
        routes[cell.tag] = route
    }

    func routeCellDidRequestDelete(_ cell: RouteCell) {
        deleteRoute(at: cell.tag)
    }

    func routeCellDidRequestColorPicker(_ cell: RouteCell) {
        let picker = UIColorPickerViewController()
        picker.delegate = self
        picker.selectedColor = routes[cell.tag].customColor ?? .systemBlue
        picker.supportsAlpha = false
        picker.view.tag = cell.tag
        present(picker, animated: true)
    }
}

// MARK: - UIColorPickerViewControllerDelegate

extension ClimbingInputViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let index = viewController.view.tag
        guard index < routes.count else { return }
        routes[index].customColor = viewController.selectedColor
        routes[index].selectedColorIndex = nil
        tableView.reloadRows(at: [IndexPath(row: index, section: 2)], with: .none)
    }
}

// MARK: - TextFieldCell

private class TextFieldCell: UITableViewCell {
    private let textField = UITextField()
    private var onTextChange: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        textField.font = .systemFont(ofSize: 17)
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        textField.delegate = self

        contentView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(placeholder: String, text: String, onChange: @escaping (String) -> Void) {
        textField.placeholder = placeholder
        textField.text = text
        onTextChange = onChange
    }

    @objc private func textChanged() {
        onTextChange?(textField.text ?? "")
    }
}

extension TextFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - SegmentCell

private class SegmentCell: UITableViewCell {
    private let segmentControl = UISegmentedControl()
    private var onSelectionChange: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        segmentControl.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)

        contentView.addSubview(segmentControl)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            segmentControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            segmentControl.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(items: [String], selectedIndex: Int, onChange: @escaping (Int) -> Void) {
        segmentControl.removeAllSegments()
        for (i, item) in items.enumerated() {
            segmentControl.insertSegment(withTitle: item, at: i, animated: false)
        }
        segmentControl.selectedSegmentIndex = selectedIndex
        onSelectionChange = onChange
    }

    @objc private func selectionChanged() {
        onSelectionChange?(segmentControl.selectedSegmentIndex)
    }
}

// MARK: - ButtonCell

private class ButtonCell: UITableViewCell {
    enum Style { case primary, secondary }

    private let button = UIButton(type: .system)
    private var onTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, style: Style, onTap: @escaping () -> Void) {
        button.setTitle(title, for: .normal)
        self.onTap = onTap

        switch style {
        case .primary:
            button.backgroundColor = .systemOrange
            button.setTitleColor(.white, for: .normal)
        case .secondary:
            button.backgroundColor = .secondarySystemBackground
            button.setTitleColor(.systemBlue, for: .normal)
        }
    }

    @objc private func buttonTapped() {
        onTap?()
    }
}

// MARK: - RouteCellDelegate

protocol RouteCellDelegate: AnyObject {
    func routeCellDidUpdate(_ cell: RouteCell, route: ClimbingInputViewController.RouteData)
    func routeCellDidRequestDelete(_ cell: RouteCell)
    func routeCellDidRequestColorPicker(_ cell: RouteCell)
}

// MARK: - RouteCell

class RouteCell: UITableViewCell {
    weak var delegate: RouteCellDelegate?

    private var route = ClimbingInputViewController.RouteData()
    private var discipline: ClimbingDiscipline = .bouldering

    private let containerView = UIView()
    private let headerLabel = UILabel()
    private let deleteButton = UIButton(type: .system)

    // Bouldering only: Color section
    private let colorSectionView = UIView()
    private let colorLabel = UILabel()
    private let colorScrollView = UIScrollView()
    private let colorStack = UIStackView()
    private var colorButtons: [UIButton] = []
    private var customColorButton: UIButton!

    // Common fields
    private let gradeLabel = UILabel()
    private let gradeField = UITextField()
    private let metricLabel = UILabel()
    private let metricValueLabel = UILabel()
    private let stepper = UIStepper()
    private let sentLabel = UILabel()
    private let sentSwitch = UISwitch()

    // Constraints for dynamic layout
    private var gradeTopToHeaderConstraint: NSLayoutConstraint!
    private var gradeTopToColorConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        contentView.addSubview(containerView)

        // Header
        headerLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        headerLabel.textColor = .systemOrange
        containerView.addSubview(headerLabel)

        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemGray3
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        containerView.addSubview(deleteButton)

        // Color section (Bouldering only)
        containerView.addSubview(colorSectionView)

        colorLabel.text = "홀드 색상"
        colorLabel.font = .systemFont(ofSize: 13)
        colorLabel.textColor = .secondaryLabel
        colorSectionView.addSubview(colorLabel)

        colorScrollView.showsHorizontalScrollIndicator = false
        colorSectionView.addSubview(colorScrollView)

        colorStack.axis = .horizontal
        colorStack.spacing = 8
        colorScrollView.addSubview(colorStack)

        // Create color buttons
        for i in 0..<ClimbingInputViewController.RouteData.presetColors.count {
            let btn = createColorButton(color: ClimbingInputViewController.RouteData.presetColors[i], tag: i)
            colorButtons.append(btn)
            colorStack.addArrangedSubview(btn)
        }

        customColorButton = UIButton(type: .system)
        customColorButton.setImage(UIImage(systemName: "plus"), for: .normal)
        customColorButton.tintColor = .systemGray
        customColorButton.layer.cornerRadius = 15
        customColorButton.layer.borderWidth = 2
        customColorButton.layer.borderColor = UIColor.systemGray4.cgColor
        customColorButton.addTarget(self, action: #selector(customColorTapped), for: .touchUpInside)
        colorStack.addArrangedSubview(customColorButton)

        // Grade
        gradeLabel.font = .systemFont(ofSize: 13)
        gradeLabel.textColor = .secondaryLabel
        containerView.addSubview(gradeLabel)

        gradeField.font = .systemFont(ofSize: 15)
        gradeField.backgroundColor = .tertiarySystemBackground
        gradeField.layer.cornerRadius = 8
        gradeField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        gradeField.leftViewMode = .always
        gradeField.returnKeyType = .done
        gradeField.autocorrectionType = .no
        gradeField.autocapitalizationType = .none
        gradeField.spellCheckingType = .no
        gradeField.delegate = self
        gradeField.addTarget(self, action: #selector(gradeChanged), for: .editingChanged)
        containerView.addSubview(gradeField)

        // Metric
        metricLabel.font = .systemFont(ofSize: 13)
        metricLabel.textColor = .secondaryLabel
        containerView.addSubview(metricLabel)

        metricValueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        metricValueLabel.textColor = .label
        metricValueLabel.textAlignment = .center
        containerView.addSubview(metricValueLabel)

        stepper.minimumValue = 0
        stepper.maximumValue = 99
        stepper.value = 1
        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        containerView.addSubview(stepper)

        // Sent
        sentLabel.text = "완등"
        sentLabel.font = .systemFont(ofSize: 15)
        sentLabel.textColor = .label
        containerView.addSubview(sentLabel)

        sentSwitch.onTintColor = .systemGreen
        sentSwitch.addTarget(self, action: #selector(sentChanged), for: .valueChanged)
        containerView.addSubview(sentSwitch)

        setupConstraints()
    }

    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        colorSectionView.translatesAutoresizingMaskIntoConstraints = false
        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        colorScrollView.translatesAutoresizingMaskIntoConstraints = false
        colorStack.translatesAutoresizingMaskIntoConstraints = false
        gradeLabel.translatesAutoresizingMaskIntoConstraints = false
        gradeField.translatesAutoresizingMaskIntoConstraints = false
        metricLabel.translatesAutoresizingMaskIntoConstraints = false
        metricValueLabel.translatesAutoresizingMaskIntoConstraints = false
        stepper.translatesAutoresizingMaskIntoConstraints = false
        sentLabel.translatesAutoresizingMaskIntoConstraints = false
        sentSwitch.translatesAutoresizingMaskIntoConstraints = false
        customColorButton.translatesAutoresizingMaskIntoConstraints = false

        // Dynamic constraints
        gradeTopToHeaderConstraint = gradeLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12)
        gradeTopToColorConstraint = gradeLabel.topAnchor.constraint(equalTo: colorSectionView.bottomAnchor, constant: 12)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            headerLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            deleteButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24),

            // Color section
            colorSectionView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12),
            colorSectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            colorSectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            colorLabel.topAnchor.constraint(equalTo: colorSectionView.topAnchor),
            colorLabel.leadingAnchor.constraint(equalTo: colorSectionView.leadingAnchor, constant: 16),

            colorScrollView.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 8),
            colorScrollView.leadingAnchor.constraint(equalTo: colorSectionView.leadingAnchor),
            colorScrollView.trailingAnchor.constraint(equalTo: colorSectionView.trailingAnchor),
            colorScrollView.heightAnchor.constraint(equalToConstant: 36),
            colorScrollView.bottomAnchor.constraint(equalTo: colorSectionView.bottomAnchor),

            colorStack.topAnchor.constraint(equalTo: colorScrollView.topAnchor),
            colorStack.leadingAnchor.constraint(equalTo: colorScrollView.leadingAnchor, constant: 16),
            colorStack.trailingAnchor.constraint(equalTo: colorScrollView.trailingAnchor, constant: -16),
            colorStack.bottomAnchor.constraint(equalTo: colorScrollView.bottomAnchor),
            colorStack.heightAnchor.constraint(equalTo: colorScrollView.heightAnchor),

            customColorButton.widthAnchor.constraint(equalToConstant: 32),
            customColorButton.heightAnchor.constraint(equalToConstant: 32),

            // Grade
            gradeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            gradeField.topAnchor.constraint(equalTo: gradeLabel.bottomAnchor, constant: 4),
            gradeField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            gradeField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            gradeField.heightAnchor.constraint(equalToConstant: 40),

            metricLabel.topAnchor.constraint(equalTo: gradeField.bottomAnchor, constant: 12),
            metricLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            stepper.centerYAnchor.constraint(equalTo: metricLabel.centerYAnchor),
            stepper.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            metricValueLabel.centerYAnchor.constraint(equalTo: metricLabel.centerYAnchor),
            metricValueLabel.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -12),
            metricValueLabel.widthAnchor.constraint(equalToConstant: 30),

            sentLabel.topAnchor.constraint(equalTo: metricLabel.bottomAnchor, constant: 16),
            sentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            sentLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

            sentSwitch.centerYAnchor.constraint(equalTo: sentLabel.centerYAnchor),
            sentSwitch.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])

        for btn in colorButtons {
            btn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 32),
                btn.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
    }

    private func createColorButton(color: UIColor, tag: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.systemGray4.cgColor
        btn.tag = tag
        btn.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)

        if color == .white || color == .systemYellow {
            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOffset = CGSize(width: 0, height: 1)
            btn.layer.shadowOpacity = 0.2
            btn.layer.shadowRadius = 2
        }
        return btn
    }

    func configure(routeNumber: Int, route: ClimbingInputViewController.RouteData, discipline: ClimbingDiscipline, canDelete: Bool) {
        self.route = route
        self.discipline = discipline

        headerLabel.text = "루트 \(routeNumber)"
        deleteButton.isHidden = !canDelete

        gradeField.text = route.grade
        stepper.value = Double(route.attempts)
        metricValueLabel.text = "\(route.attempts)"
        sentSwitch.isOn = route.isSent

        // Update UI based on discipline
        let isBouldering = discipline == .bouldering
        colorSectionView.isHidden = !isBouldering

        gradeTopToHeaderConstraint.isActive = !isBouldering
        gradeTopToColorConstraint.isActive = isBouldering

        if isBouldering {
            gradeLabel.text = "난이도 (선택)"
            gradeField.placeholder = "예: V3, V5"
            metricLabel.text = "시도 횟수"
            updateColorSelection()
        } else {
            gradeLabel.text = "난이도"
            gradeField.placeholder = "예: 5.11a, 5.12b"
            metricLabel.text = "테이크 횟수"
        }
    }

    private func updateColorSelection() {
        for (i, btn) in colorButtons.enumerated() {
            let isSelected = route.customColor == nil && route.selectedColorIndex == i
            btn.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.systemGray4.cgColor
            btn.layer.borderWidth = isSelected ? 3 : 2
        }

        if let custom = route.customColor {
            customColorButton.backgroundColor = custom
            customColorButton.setImage(nil, for: .normal)
            customColorButton.layer.borderColor = UIColor.systemBlue.cgColor
            customColorButton.layer.borderWidth = 3
        } else {
            customColorButton.backgroundColor = .clear
            customColorButton.setImage(UIImage(systemName: "plus"), for: .normal)
            customColorButton.layer.borderColor = UIColor.systemGray4.cgColor
            customColorButton.layer.borderWidth = 2
        }
    }

    // MARK: - Actions

    @objc private func deleteTapped() {
        delegate?.routeCellDidRequestDelete(self)
    }

    @objc private func colorTapped(_ sender: UIButton) {
        route.selectedColorIndex = sender.tag
        route.customColor = nil
        updateColorSelection()
        delegate?.routeCellDidUpdate(self, route: route)
    }

    @objc private func customColorTapped() {
        delegate?.routeCellDidRequestColorPicker(self)
    }

    @objc private func gradeChanged() {
        route.grade = gradeField.text ?? ""
        delegate?.routeCellDidUpdate(self, route: route)
    }

    @objc private func stepperChanged() {
        route.attempts = Int(stepper.value)
        metricValueLabel.text = "\(route.attempts)"
        delegate?.routeCellDidUpdate(self, route: route)
    }

    @objc private func sentChanged() {
        route.isSent = sentSwitch.isOn
        delegate?.routeCellDidUpdate(self, route: route)
    }
}

// MARK: - RouteCell UITextFieldDelegate

extension RouteCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UIColor Extension

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6 else { return nil }

        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
