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

class ClimbingInputViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

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
            .systemBlue, .systemIndigo, .systemPurple, .systemPink,
            .brown, .systemGray, .black
        ]
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark // Force Dark Mode
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
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.register(ClimbingHeaderCell.self, forCellReuseIdentifier: "ClimbingHeaderCell") // New Gym Name Cell
        tableView.register(DisciplineSelectionCell.self, forCellReuseIdentifier: "DisciplineSelectionCell") // New Discipline Cell
        tableView.register(RouteCell.self, forCellReuseIdentifier: "RouteCell")
        tableView.register(ButtonCell.self, forCellReuseIdentifier: "ButtonCell")
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    // MARK: - TableView DataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // Gym, Discipline, Routes, Buttons
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Gym name
        case 1: return 1 // Discipline
        case 2: return routes.count // Routes
        case 3: return 2 // Add route + Create button
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return nil // Header inside cell for modern look
        case 1: return "종목"
        case 2: return "루트 기록"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Hide header for first section to look like a title
        if section == 0 { return nil }
        return nil // Default behavior for others
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return 10 } // Small spacer
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ClimbingHeaderCell", for: indexPath) as! ClimbingHeaderCell
            cell.configure(placeholder: "클라이밍짐 이름", text: gymName) { [weak self] text in
                self?.gymName = text
            }
            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DisciplineSelectionCell", for: indexPath) as! DisciplineSelectionCell
            cell.configure(
                selectedDiscipline: selectedDiscipline
            ) { [weak self] discipline in
                self?.selectedDiscipline = discipline
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

// MARK: - ClimbingHeaderCell

class ClimbingHeaderCell: UITableViewCell {
    private let textField = UITextField()
    private var onTextChange: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        
        textField.font = .systemFont(ofSize: 34, weight: .bold) // Large Title style
        textField.placeholder = "Gym Name"
        textField.borderStyle = .none
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        textField.delegate = self
        
        contentView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
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

extension ClimbingHeaderCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - DisciplineSelectionCell

class DisciplineSelectionCell: UITableViewCell {
    private var onSelectionChange: ((ClimbingDiscipline) -> Void)?
    private var currentDiscipline: ClimbingDiscipline = .bouldering
    private let stackView = UIStackView()
    private var buttons: [UIButton] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear // Transparent in grouped table
        contentView.backgroundColor = .clear
        
        // Card container
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 10
        container.clipsToBounds = true
        
        contentView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 2
        stackView.backgroundColor = .systemGray5 // Separator color
        
        container.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0), // Edge to edge in cell content
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            stackView.topAnchor.constraint(equalTo: container.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        setupButtons()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupButtons() {
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.backgroundColor = .clear // No separator line
        
        for (index, discipline) in ClimbingDiscipline.allCases.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(discipline.displayName, for: .normal)
            btn.setTitleColor(.secondaryLabel, for: .normal)
            btn.setTitleColor(.white, for: .selected)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            
            // Initial state
            btn.backgroundColor = .tertiarySystemGroupedBackground
            
            // Fix shape: rounded rect
            btn.layer.cornerRadius = 8
            btn.layer.masksToBounds = true
            
            btn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            btn.tag = discipline.hashValue
            buttons.append(btn)
            stackView.addArrangedSubview(btn)
        }
    }
    
    func configure(selectedDiscipline: ClimbingDiscipline, onChange: @escaping (ClimbingDiscipline) -> Void) {
        self.currentDiscipline = selectedDiscipline
        self.onSelectionChange = onChange
        updateSelection()
    }
    
    private func updateSelection() {
        for (index, discipline) in ClimbingDiscipline.allCases.enumerated() {
            guard index < buttons.count else { continue }
            let btn = buttons[index]
            let isSelected = discipline == currentDiscipline
            btn.isSelected = isSelected
            
            // Visual update
            UIView.animate(withDuration: 0.2) {
                if isSelected {
                    btn.backgroundColor = .systemBlue
                    btn.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    btn.layer.shadowColor = UIColor.systemBlue.cgColor
                    btn.layer.shadowOffset = CGSize(width: 0, height: 2)
                    btn.layer.shadowOpacity = 0.3
                    btn.layer.shadowRadius = 4
                    btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
                } else {
                    btn.backgroundColor = .tertiarySystemGroupedBackground
                    btn.transform = .identity
                    btn.layer.shadowOpacity = 0
                    btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
                }
            }
        }
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        // Find discipline by index
        guard let index = buttons.firstIndex(of: sender) else { return }
        let discipline = ClimbingDiscipline.allCases[index]
        currentDiscipline = discipline
        onSelectionChange?(discipline)
        updateSelection()
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

    // Container for card look
    private let containerView = UIView()
    
    // Header
    private let headerStack = UIStackView()
    private let headerLabel = UILabel()
    private let deleteButton = UIButton(type: .system)

    // Bouldering Color Section
    private let colorSectionView = UIView()
    private let colorScrollView = UIScrollView()
    private let colorStack = UIStackView()
    private var colorButtons: [UIButton] = []
    private var customColorButton: UIButton!
    
    // Grade & Attempts
    private let gradeStack = UIStackView()
    private let gradeLabel = UILabel()
    private let gradeField = UITextField()
    
    private let attemptsStack = UIStackView()
    private let attemptsLabel = UILabel()
    private let attemptsValueLabel = UILabel()
    private let attemptsStepper = UIStepper()

    // Sent Status
    private let sentSwitch = UISwitch()
    private let sentLabel = UILabel()
    
    // Constraints
    private var colorSectionHeightConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        // Card Container
        contentView.addSubview(containerView)
        containerView.backgroundColor = .secondarySystemGroupedBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.cornerCurve = .continuous
        // containerView.layer.shadowColor = UIColor.black.cgColor
        // containerView.layer.shadowOpacity = 0.05
        // containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        // containerView.layer.shadowRadius = 4
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0), // Grouped style handles inset usually, but if we want card in card... let's stick to 0 if native inset used
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
        
        // Header
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        
        headerLabel.font = .systemFont(ofSize: 17, weight: .bold)
        headerLabel.textColor = .label
        
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        
        headerStack.addArrangedSubview(headerLabel)
        headerStack.addArrangedSubview(UIView()) // Spacer
        headerStack.addArrangedSubview(deleteButton)
        
        containerView.addSubview(headerStack)
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Color Section
        colorScrollView.showsHorizontalScrollIndicator = false
        colorStack.axis = .horizontal
        colorStack.spacing = 10
        colorScrollView.addSubview(colorStack)
        colorStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            colorStack.topAnchor.constraint(equalTo: colorScrollView.topAnchor),
            colorStack.leadingAnchor.constraint(equalTo: colorScrollView.leadingAnchor, constant: 16),
            colorStack.trailingAnchor.constraint(equalTo: colorScrollView.trailingAnchor, constant: -16),
            colorStack.bottomAnchor.constraint(equalTo: colorScrollView.bottomAnchor),
            colorStack.heightAnchor.constraint(equalTo: colorScrollView.heightAnchor)
        ])
        
        for i in 0..<ClimbingInputViewController.RouteData.presetColors.count {
            let btn = createColorButton(color: ClimbingInputViewController.RouteData.presetColors[i], tag: i)
            colorButtons.append(btn)
            colorStack.addArrangedSubview(btn)
        }
        
        customColorButton = UIButton(type: .system)
        customColorButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        customColorButton.tintColor = .label
        customColorButton.addTarget(self, action: #selector(customColorTapped), for: .touchUpInside)
        colorStack.addArrangedSubview(customColorButton)
        
        containerView.addSubview(colorScrollView)
        colorScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Grade
        gradeLabel.text = "GRADE"
        gradeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        gradeLabel.textColor = .secondaryLabel
        
        gradeField.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        gradeField.backgroundColor = .tertiarySystemGroupedBackground
        gradeField.layer.cornerRadius = 6
        gradeField.textAlignment = .center
        gradeField.returnKeyType = .done
        gradeField.delegate = self
        gradeField.addTarget(self, action: #selector(gradeChanged), for: .editingChanged)
        
        gradeStack.axis = .vertical
        gradeStack.spacing = 4
        gradeStack.addArrangedSubview(gradeLabel)
        gradeStack.addArrangedSubview(gradeField)
        
        // Attempts
        attemptsLabel.text = "ATTEMPTS"
        attemptsLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        attemptsLabel.textColor = .secondaryLabel
        
        attemptsValueLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        attemptsValueLabel.textAlignment = .center
        
        attemptsStepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        attemptsStepper.minimumValue = 1
        
        attemptsStack.axis = .vertical
        attemptsStack.spacing = 4
        attemptsStack.alignment = .center
        attemptsStack.addArrangedSubview(attemptsLabel)
        
        let attemptsControlStack = UIStackView(arrangedSubviews: [attemptsValueLabel, attemptsStepper])
        attemptsControlStack.spacing = 8
        attemptsControlStack.alignment = .center
        attemptsStack.addArrangedSubview(attemptsControlStack)
        
        // Sent Switch
        sentLabel.text = "완등"
        sentLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        sentLabel.textColor = .label
        
        sentSwitch.onTintColor = .systemGreen
        sentSwitch.addTarget(self, action: #selector(sentChanged), for: .valueChanged)
        
        let sentStack = UIStackView(arrangedSubviews: [sentLabel, sentSwitch])
        sentStack.axis = .vertical
        sentStack.alignment = .center
        sentStack.spacing = 8
        
        // Layout Main Content
        containerView.addSubview(gradeStack)
        containerView.addSubview(attemptsStack)
        containerView.addSubview(sentStack)
        
        gradeStack.translatesAutoresizingMaskIntoConstraints = false
        attemptsStack.translatesAutoresizingMaskIntoConstraints = false
        sentStack.translatesAutoresizingMaskIntoConstraints = false
        
        colorSectionHeightConstraint = colorScrollView.heightAnchor.constraint(equalToConstant: 44)
        
        NSLayoutConstraint.activate([
            // Header
            headerStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Color Scroll
            colorScrollView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            colorScrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            colorScrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            colorSectionHeightConstraint,
            
            // Grade
            gradeStack.topAnchor.constraint(equalTo: colorScrollView.bottomAnchor, constant: 16),
            gradeStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            gradeStack.widthAnchor.constraint(equalToConstant: 80),
            
            gradeField.heightAnchor.constraint(equalToConstant: 36),
            
            // Sent Switch (Replacing Button)
            sentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            sentStack.centerYAnchor.constraint(equalTo: gradeStack.centerYAnchor),
            // sentStack.heightAnchor.constraint(equalToConstant: 36),
            
            // Attempts (Between Grade and Send)
            attemptsStack.centerYAnchor.constraint(equalTo: gradeStack.centerYAnchor),
            attemptsStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Bottom constraint
            gradeStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // ... helpers and configure ...
    
    private func createColorButton(color: UIColor, tag: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 0
        // btn.layer.borderColor = UIColor.systemGray4.cgColor
        btn.tag = tag
        btn.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        
        if color == .white || color == .systemYellow {
            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOffset = CGSize(width: 0, height: 1)
            btn.layer.shadowOpacity = 0.1
            btn.layer.shadowRadius = 2
        }
        
        return btn
    }

    func configure(routeNumber: Int, route: ClimbingInputViewController.RouteData, discipline: ClimbingDiscipline, canDelete: Bool) {
        self.route = route
        self.discipline = discipline

        headerLabel.text = "Route #\(routeNumber)"
        deleteButton.isHidden = !canDelete

        gradeField.text = route.grade
        attemptsStepper.value = Double(route.attempts)
        attemptsValueLabel.text = "\(route.attempts)"
        
        // Init switch state
        sentSwitch.isOn = route.isSent
        
        updateColorSelection()

        // Hide/Show color section based on discipline
        let isBouldering = discipline == .bouldering
        colorScrollView.isHidden = !isBouldering
        colorSectionHeightConstraint.constant = isBouldering ? 44 : 0
        
        // Update labels
        attemptsLabel.text = isBouldering ? "ATTEMPTS" : "TAKES"
    }
    
    // Removed updateSentButton() as we are observing switch
    
    // ... updateColorSelection ...
    
    // MARK: - Actions
    
    @objc private func sentChanged() {
        route.isSent = sentSwitch.isOn
        delegate?.routeCellDidUpdate(self, route: route)
    }

    private func updateColorSelection() {
        // ... (Similar specific logic for highlight selected)
        for (i, btn) in colorButtons.enumerated() {
             let isSelected = route.customColor == nil && route.selectedColorIndex == i
             if isSelected {
                 btn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                 btn.layer.borderWidth = 2
                 btn.layer.borderColor = UIColor.label.cgColor
             } else {
                 btn.transform = .identity
                 btn.layer.borderWidth = 0
             }
        }
        
        if let custom = route.customColor {
             customColorButton.tintColor = custom
             // Highlight custom button logic...
        } else {
             customColorButton.tintColor = .label
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
        route.attempts = Int(attemptsStepper.value)
        attemptsValueLabel.text = "\(route.attempts)"
        delegate?.routeCellDidUpdate(self, route: route)
    }

    // Removed sentTapped action
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
