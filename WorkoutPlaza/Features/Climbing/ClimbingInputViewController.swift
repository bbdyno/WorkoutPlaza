//
//  ClimbingInputViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit
import PhotosUI

protocol ClimbingInputDelegate: AnyObject {
    func climbingInputDidSave(_ controller: ClimbingInputViewController)
    func climbingInput(_ controller: ClimbingInputViewController, didRequestCardFor session: ClimbingData)
}

class ClimbingInputViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    weak var delegate: ClimbingInputDelegate?

    // MARK: - Data
    private var selectedGym: ClimbingGym? {
        didSet {
            // Update UI when gym changes (colors might change)
            tableView.reloadData()
        }
    }
    private var isCustomGym: Bool = false // Start with no selection
    private var customGymName: String = ""
    private var customLogoImage: UIImage?
    
    // Gym name is either selected gym's name or custom name
    private var currentGymName: String {
        return selectedGym?.name ?? customGymName
    }
    
    private var currentGradeColors: [UIColor] {
        let hexColors = selectedGym?.gradeColors ?? ClimbingGymManager.shared.defaultGradeColors
        return hexColors.compactMap { UIColor(climbingHex: $0) }
    }

    private var selectedDiscipline: ClimbingDiscipline = .bouldering  // For next route to add
    private var routes: [RouteData] = [RouteData(discipline: .bouldering)]

    struct RouteData {
        var discipline: ClimbingDiscipline  // Each route has its own discipline
        var selectedColorIndex: Int?
        var customColor: UIColor?
        var grade: String = ""
        var attempts: Int = 1
        var isSent: Bool = false

        init(discipline: ClimbingDiscipline = .bouldering) {
            self.discipline = discipline
        }

        // Helper to get color from a provided palette
        func resolveColor(from palette: [UIColor]) -> UIColor? {
            if let custom = customColor { return custom }
            if let index = selectedColorIndex, index < palette.count {
                return palette[index]
            }
            return nil
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark // Force Dark Mode
        setupTableView()
        setupNavigationBar()
        setupKeyboardHandling()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

        // Enable dynamic cell height
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200

        tableView.register(ClimbingHeaderCell.self, forCellReuseIdentifier: "ClimbingHeaderCell") // New Gym Name Cell
        tableView.register(DisciplineSelectionCell.self, forCellReuseIdentifier: "DisciplineSelectionCell") // New Discipline Cell
        tableView.register(RouteCell.self, forCellReuseIdentifier: "RouteCell")
        tableView.register(ButtonCell.self, forCellReuseIdentifier: "ButtonCell")
    }

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height

        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    // MARK: - TableView DataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        // Only show gym selection until a gym is selected
        let hasGymSelected = selectedGym != nil || isCustomGym
        return hasGymSelected ? 3 : 1  // Gym only, or Gym + Routes + Buttons (no discipline section)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return isCustomGym ? 3 : 1  // Selector + (Name + Logo if custom)
        case 1: return routes.count // Routes (discipline inside each route)
        case 2: return 2 // Add route + Create button
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return nil // Header inside cell for modern look
        case 1: return "루트 기록"
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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Show hint message when no gym is selected
        if section == 0 && selectedGym == nil && !isCustomGym {
            let footerView = UIView()
            let label = UILabel()
            label.text = "암장을 선택하면 기록을 시작할 수 있습니다"
            label.font = .systemFont(ofSize: 14, weight: .regular)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.numberOfLines = 0

            footerView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),
                label.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -20),
                label.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -16)
            ])

            return footerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 && selectedGym == nil && !isCustomGym {
            return UITableView.automaticDimension
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                // Gym Selector Cell
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "GymSelectorCell")
                cell.textLabel?.text = "암장"
                cell.detailTextLabel?.text = selectedGym?.name ?? (isCustomGym ? "사용자 지정" : "암장 선택")
                cell.detailTextLabel?.textColor = selectedGym == nil && !isCustomGym ? .secondaryLabel : .label
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .secondarySystemGroupedBackground
                return cell
            } else if indexPath.row == 1 {
                // Custom Name Input
                let cell = tableView.dequeueReusableCell(withIdentifier: "ClimbingHeaderCell", for: indexPath) as! ClimbingHeaderCell
                cell.configure(placeholder: "암장 이름 입력", text: customGymName) { [weak self] text in
                    self?.customGymName = text
                }
                return cell
            } else {
                // Logo Picker
                let cell = UITableViewCell(style: .default, reuseIdentifier: "LogoPickerCell")
                cell.textLabel?.text = "로고 이미지 선택 (선택사항)"
                cell.textLabel?.textColor = .systemBlue
                cell.textLabel?.textAlignment = .center
                if let logo = customLogoImage {
                    cell.imageView?.image = logo
                    cell.textLabel?.text = "이미지 변경"
                } else {
                    cell.imageView?.image = UIImage(systemName: "photo")
                }
                cell.backgroundColor = .secondarySystemGroupedBackground
                return cell
            }

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell", for: indexPath) as! RouteCell
            let route = routes[indexPath.row]
            cell.configure(
                routeNumber: indexPath.row + 1,
                route: route,
                discipline: route.discipline,  // Use route's own discipline
                availableColors: currentGradeColors, // Pass dynamic colors
                canDelete: routes.count > 1
            )
            cell.delegate = self
            cell.tag = indexPath.row
            return cell

        case 2:
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
        routes.append(RouteData(discipline: selectedDiscipline))
        tableView.insertRows(at: [IndexPath(row: routes.count - 1, section: 1)], with: .automatic)
    }

    private func deleteRoute(at index: Int) {
        guard routes.count > 1 else { return }
        routes.remove(at: index)
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }

    private func createRecord() {
        let gymParams = getGymParams()
        guard !gymParams.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "암장 이름을 입력하거나 선택해주세요.")
            return
        }

        // Group routes by discipline
        var boulderingRoutes: [ClimbingRoute] = []
        var leadRoutes: [ClimbingRoute] = []
        let colors = currentGradeColors

        for route in routes {
            let resolvedColor = route.resolveColor(from: colors)

            if resolvedColor != nil || !route.grade.isEmpty {
                let climbingRoute = ClimbingRoute(
                    grade: route.grade,
                    colorHex: resolvedColor?.toClimbingHex(),
                    attempts: route.discipline == .bouldering ? route.attempts : nil,
                    takes: route.discipline == .leadEndurance ? route.attempts : nil,
                    isSent: route.isSent
                )

                if route.discipline == .bouldering {
                    boulderingRoutes.append(climbingRoute)
                } else {
                    leadRoutes.append(climbingRoute)
                }
            }
        }

        guard !boulderingRoutes.isEmpty || !leadRoutes.isEmpty else {
            showAlert(message: "최소 하나의 루트를 기록해주세요.")
            return
        }

        // Save bouldering session if exists
        if !boulderingRoutes.isEmpty {
            let boulderingData = ClimbingData(
                gymName: gymParams.name,
                discipline: .bouldering,
                routes: boulderingRoutes,
                sessionDate: Date()
            )
            ClimbingDataManager.shared.addSession(boulderingData)
        }

        // Save lead session if exists
        if !leadRoutes.isEmpty {
            let leadData = ClimbingData(
                gymName: gymParams.name,
                discipline: .leadEndurance,
                routes: leadRoutes,
                sessionDate: Date()
            )
            ClimbingDataManager.shared.addSession(leadData)
        }

        // Use the first session for card creation
        let climbingData = !boulderingRoutes.isEmpty ?
            ClimbingData(gymName: gymParams.name, discipline: .bouldering, routes: boulderingRoutes, sessionDate: Date()) :
            ClimbingData(gymName: gymParams.name, discipline: .leadEndurance, routes: leadRoutes, sessionDate: Date())

        // Save custom gym if it's a new custom gym
        if isCustomGym && !gymParams.name.isEmpty {
            // Check if custom gym with this name already exists
            if ClimbingGymManager.shared.findGym(byName: gymParams.name) == nil {
                let logoSource: ClimbingGym.LogoSource
                if let logoData = gymParams.logoData {
                    logoSource = .imageData(logoData)
                } else {
                    logoSource = .none
                }

                let newGym = ClimbingGym(
                    name: gymParams.name,
                    logoSource: logoSource,
                    gradeColors: ClimbingGymManager.shared.defaultGradeColors,
                    isBuiltIn: false
                )
                ClimbingGymManager.shared.addGym(newGym)
            }
        }

        // Sessions already saved above (grouped by discipline)

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

    private func getGymParams() -> (name: String, logoData: Data?) {
        if let gym = selectedGym {
            return (gym.name, nil) // Preset uses name-based logo lookup usually
        }
        return (customGymName, customLogoImage?.pngData())
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                showGymSelector()
            } else if indexPath.row == 2 {
                showImagePicker()
            }
        }
    }
    
    // MARK: - Gym Selector

    private func showGymSelector() {
        let picker = GymPickerViewController()
        picker.selectedGym = self.selectedGym
        picker.delegate = self

        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
    
    private func selectGym(_ gym: ClimbingGym) {
        let wasGymSelected = selectedGym != nil || isCustomGym
        self.selectedGym = gym
        self.isCustomGym = false

        // If sections changed (1 -> 3), use reloadData
        if !wasGymSelected {
            tableView.reloadData()
        } else {
            tableView.reloadSections(IndexSet([0, 2]), with: .automatic)
        }
    }

    private func selectCustomGym() {
        let wasGymSelected = selectedGym != nil || isCustomGym
        self.selectedGym = nil
        self.isCustomGym = true
        self.customGymName = ""
        self.customLogoImage = nil

        // If sections changed (1 -> 3), use reloadData
        if !wasGymSelected {
            tableView.reloadData()
        } else {
            tableView.reloadSections(IndexSet([0, 2]), with: .automatic)
        }
    }
    
    // MARK: - Image Picker
    
    private func showImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ClimbingInputViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            DispatchQueue.main.async {
                if let image = image as? UIImage {
                    self?.customLogoImage = image
                    self?.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                }
            }
        }
    }
}

// MARK: - GymPickerDelegate

extension ClimbingInputViewController: GymPickerDelegate {
    func gymPicker(_ picker: GymPickerViewController, didSelect gym: ClimbingGym?) {
        if let gym = gym {
            // 프리셋 또는 커스텀 암장 선택
            selectGym(gym)
        } else {
            // 사용자 지정 선택
            selectCustomGym()
        }
    }
}

// MARK: - RouteCellDelegate

extension ClimbingInputViewController: RouteCellDelegate {
    func routeCellDidUpdate(_ cell: RouteCell, route: ClimbingInputViewController.RouteData) {
        guard cell.tag < routes.count else { return }
        routes[cell.tag] = route

        // Trigger cell height recalculation
        tableView.performBatchUpdates(nil, completion: nil)
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
        tableView.reloadRows(at: [IndexPath(row: index, section: 1)], with: .none)
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
        stackView.spacing = 6
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

            // More rectangular shape
            btn.layer.cornerRadius = 4
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
    private let disciplineSegment = UISegmentedControl(items: ["볼더링", "리드"])
    private let deleteButton = UIButton(type: .system)

    // Bouldering Color Section
    private let colorSectionView = UIView()
    private let colorSectionLabel = UILabel()
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
    private var gradeStackTopConstraint: NSLayoutConstraint!
    private var gradeStackTopToHeaderConstraint: NSLayoutConstraint!
    private var gradeStackTopToColorConstraint: NSLayoutConstraint!

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

        // Discipline Segment
        disciplineSegment.selectedSegmentIndex = 0
        disciplineSegment.addTarget(self, action: #selector(disciplineChanged), for: .valueChanged)

        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        headerStack.addArrangedSubview(headerLabel)
        headerStack.addArrangedSubview(disciplineSegment)
        headerStack.addArrangedSubview(UIView()) // Spacer
        headerStack.addArrangedSubview(deleteButton)
        
        containerView.addSubview(headerStack)
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        // Color Section Label
        colorSectionLabel.text = "난이도 테이프"
        colorSectionLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        colorSectionLabel.textColor = .secondaryLabel
        containerView.addSubview(colorSectionLabel)
        colorSectionLabel.translatesAutoresizingMaskIntoConstraints = false

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
        
        let defaults = ClimbingGymManager.shared.defaultGradeColors.compactMap { UIColor(climbingHex: $0) }
        for i in 0..<defaults.count {
            let btn = createColorButton(color: defaults[i], tag: i)
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
        gradeLabel.text = "GRADE (선택)"
        gradeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        gradeLabel.textColor = .secondaryLabel

        gradeField.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        gradeField.backgroundColor = .tertiarySystemGroupedBackground
        gradeField.layer.cornerRadius = 6
        gradeField.textAlignment = .center
        gradeField.returnKeyType = .done
        gradeField.delegate = self
        gradeField.placeholder = "V3, 파랑..."
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

        // Create two different top constraints for gradeStack
        gradeStackTopToColorConstraint = gradeStack.topAnchor.constraint(equalTo: colorScrollView.bottomAnchor, constant: 16)
        gradeStackTopToHeaderConstraint = gradeStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16)

        NSLayoutConstraint.activate([
            // Header
            headerStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Color Section Label
            colorSectionLabel.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            colorSectionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            // Color Scroll
            colorScrollView.topAnchor.constraint(equalTo: colorSectionLabel.bottomAnchor, constant: 6),
            colorScrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            colorScrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            colorSectionHeightConstraint,

            // Grade - use color constraint initially
            gradeStackTopToColorConstraint,
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
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = 0
        btn.tag = tag
        btn.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)

        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 32).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 32).isActive = true

        // Add subtle shadow for better visibility
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowOpacity = 0.15
        btn.layer.shadowRadius = 2

        return btn
    }

    func configure(routeNumber: Int, route: ClimbingInputViewController.RouteData, discipline: ClimbingDiscipline, availableColors: [UIColor], canDelete: Bool) {
        self.route = route
        self.discipline = discipline
        
        // Rebuild color buttons if palette changed significantly?
        // For simplicity, handle color updates. If count differs, rebuild.
        if colorButtons.count != availableColors.count {
            colorStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            colorButtons.removeAll()
            // Remove custom button to re-add at end
            customColorButton.removeFromSuperview()
            
            for i in 0..<availableColors.count {
                let btn = createColorButton(color: availableColors[i], tag: i)
                colorButtons.append(btn)
                colorStack.addArrangedSubview(btn)
            }
            colorStack.addArrangedSubview(customColorButton)
        } else {
            // Update colors of existing buttons
            for (i, btn) in colorButtons.enumerated() {
                btn.backgroundColor = availableColors[i]
            }
        }

        headerLabel.text = "Route #\(routeNumber)"
        deleteButton.isHidden = !canDelete

        // Update discipline segment
        disciplineSegment.selectedSegmentIndex = route.discipline == .bouldering ? 0 : 1

        gradeField.text = route.grade
        attemptsStepper.value = Double(route.attempts)
        attemptsValueLabel.text = "\(route.attempts)"

        // Init switch state
        sentSwitch.isOn = route.isSent

        updateColorSelection()

        // Hide/Show color section based on discipline
        let isBouldering = route.discipline == .bouldering

        // Switch constraints based on discipline
        if isBouldering {
            gradeStackTopToHeaderConstraint.isActive = false
            gradeStackTopToColorConstraint.isActive = true
        } else {
            gradeStackTopToColorConstraint.isActive = false
            gradeStackTopToHeaderConstraint.isActive = true
        }

        colorSectionLabel.isHidden = !isBouldering
        colorScrollView.isHidden = !isBouldering
        colorSectionHeightConstraint.constant = isBouldering ? 48 : 0

        // Update labels based on discipline
        attemptsLabel.text = isBouldering ? "ATTEMPTS" : "TAKES"

        // Grade label and placeholder
        if isBouldering {
            gradeLabel.text = "GRADE (선택)"
            gradeField.placeholder = "V3, 파랑..."
        } else {
            gradeLabel.text = "GRADE"
            gradeField.placeholder = "5.11a, 6a..."
        }

        // Force layout update to prevent empty space
        containerView.layoutIfNeeded()
    }
    
    // Removed updateSentButton() as we are observing switch
    
    // ... updateColorSelection ...
    
    // MARK: - Actions
    
    @objc private func sentChanged() {
        route.isSent = sentSwitch.isOn
        delegate?.routeCellDidUpdate(self, route: route)
    }

    private func updateColorSelection() {
        for (i, btn) in colorButtons.enumerated() {
            let isSelected = route.customColor == nil && route.selectedColorIndex == i
            UIView.animate(withDuration: 0.2) {
                if isSelected {
                    btn.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                    btn.layer.borderWidth = 3
                    btn.layer.borderColor = UIColor.white.cgColor
                    btn.layer.shadowOpacity = 0.3
                    btn.layer.shadowRadius = 4
                } else {
                    btn.transform = .identity
                    btn.layer.borderWidth = 0
                    btn.layer.shadowOpacity = 0.15
                    btn.layer.shadowRadius = 2
                }
            }
        }

        // Custom color button
        if let custom = route.customColor {
            customColorButton.tintColor = custom
            customColorButton.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        } else {
            customColorButton.tintColor = .label
            customColorButton.transform = .identity
        }
    }

    // MARK: - Actions

    @objc private func deleteTapped() {
        delegate?.routeCellDidRequestDelete(self)
    }

    @objc private func disciplineChanged(_ sender: UISegmentedControl) {
        route.discipline = sender.selectedSegmentIndex == 0 ? .bouldering : .leadEndurance

        // Update UI for new discipline with animation
        let isBouldering = route.discipline == .bouldering

        // Switch constraints
        if isBouldering {
            gradeStackTopToHeaderConstraint.isActive = false
            gradeStackTopToColorConstraint.isActive = true
        } else {
            gradeStackTopToColorConstraint.isActive = false
            gradeStackTopToHeaderConstraint.isActive = true
        }

        UIView.animate(withDuration: 0.3) {
            self.colorSectionLabel.isHidden = !isBouldering
            self.colorScrollView.isHidden = !isBouldering
            self.colorSectionHeightConstraint.constant = isBouldering ? 48 : 0
            self.containerView.layoutIfNeeded()
        }

        // Update labels based on discipline
        attemptsLabel.text = isBouldering ? "ATTEMPTS" : "TAKES"

        if isBouldering {
            gradeLabel.text = "GRADE (선택)"
            gradeField.placeholder = "V3, 파랑..."
        } else {
            gradeLabel.text = "GRADE"
            gradeField.placeholder = "5.11a, 6a..."
        }

        delegate?.routeCellDidUpdate(self, route: route)
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

// MARK: - UIColor Extension (Private to avoid conflicts)

private extension UIColor {
    func toClimbingHex() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    convenience init?(climbingHex: String) {
        var hex = climbingHex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        
        // Handle 6-digit hex only for simplicity as per requirement
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
