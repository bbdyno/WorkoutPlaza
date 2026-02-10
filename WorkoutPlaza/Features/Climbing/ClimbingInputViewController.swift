//
//  ClimbingInputViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit
import SnapKit

protocol ClimbingInputDelegate: AnyObject {
    func climbingInputDidSave(_ controller: ClimbingInputViewController)
    func climbingInput(_ controller: ClimbingInputViewController, didRequestCardFor session: ClimbingData)
    func climbingInputDidRequestCardCreation(_ controller: ClimbingInputViewController, session: ClimbingData)
}

class ClimbingInputViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private enum Constants {
        static let footerTopPadding: CGFloat = 16
        static let footerHorizontalPadding: CGFloat = 20
        static let footerBottomPadding: CGFloat = 16
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    weak var delegate: ClimbingInputDelegate?

    // MARK: - Data
    private var selectedGym: ClimbingGym?
    private var isCustomGym: Bool = false // Start with no selection
    private var customGymName: String = ""
    
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
        setupTableView()
        setupNavigationBar()
        setupKeyboardHandling()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = WorkoutPlazaStrings.Climbing.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissTapped)
        )
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = ColorSystem.background
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
        case 0: return isCustomGym ? 2 : 1  // Selector + (Name if custom)
        case 1: return routes.count // Routes (discipline inside each route)
        case 2: return 2 // Add route + Create button
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return nil // Header inside cell for modern look
        case 1: return WorkoutPlazaStrings.Climbing.Routes.section
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
            label.text = WorkoutPlazaStrings.Climbing.Gym.Select.hint
            label.font = .systemFont(ofSize: 14, weight: .regular)
            label.textColor = ColorSystem.subText
            label.textAlignment = .center
            label.numberOfLines = 0

            footerView.addSubview(label)
            label.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Constants.footerTopPadding)
                make.leading.equalToSuperview().offset(Constants.footerHorizontalPadding)
                make.trailing.equalToSuperview().offset(-Constants.footerHorizontalPadding)
                make.bottom.equalToSuperview().offset(-Constants.footerBottomPadding)
            }

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
                cell.textLabel?.text = WorkoutPlazaStrings.Climbing.Gym.label
                cell.textLabel?.textColor = ColorSystem.mainText
                cell.detailTextLabel?.text = selectedGym?.name ?? (isCustomGym ? WorkoutPlazaStrings.Climbing.Gym.custom : WorkoutPlazaStrings.Gym.Picker.title)
                cell.detailTextLabel?.textColor = selectedGym == nil && !isCustomGym ? ColorSystem.subText : ColorSystem.mainText
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ColorSystem.cardBackground
                return cell
            } else {
                // Custom Name Input
                let cell = tableView.dequeueReusableCell(withIdentifier: "GymNameInputCell") ?? UITableViewCell(style: .default, reuseIdentifier: "GymNameInputCell")
                cell.backgroundColor = ColorSystem.cardBackground
                cell.selectionStyle = .none

                // 기존 서브뷰 제거
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }

                let textField = UITextField()
                textField.placeholder = WorkoutPlazaStrings.Climbing.Gym.Name.placeholder
                textField.text = customGymName
                textField.font = .systemFont(ofSize: 17)
                textField.textColor = ColorSystem.mainText
                textField.clearButtonMode = .whileEditing
                textField.returnKeyType = .done
                textField.tag = 100
//                textField.delegate = self
                textField.addTarget(self, action: #selector(customGymNameChanged(_:)), for: .editingChanged)

                cell.contentView.addSubview(textField)
                textField.snp.makeConstraints { make in
                    make.leading.trailing.equalToSuperview().inset(16)
                    make.centerY.equalToSuperview()
                    make.height.equalTo(44)
                }

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
                cell.configure(title: WorkoutPlazaStrings.Climbing.Add.route, style: .secondary) { [weak self] in
                    self?.addRoute()
                }
            } else {
                cell.configure(title: WorkoutPlazaStrings.Climbing.Create.record, style: .primary) { [weak self] in
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
            showAlert(message: WorkoutPlazaStrings.Climbing.Error.Gym.name)
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
            showAlert(message: WorkoutPlazaStrings.Climbing.Error.Min.route)
            return
        }

        // Save bouldering session if exists
        if !boulderingRoutes.isEmpty {
            let boulderingData = ClimbingData(
                gymName: gymParams.name,
                gymId: gymParams.id,
                gymBranch: gymParams.branch,
                gymRegion: gymParams.region,
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
                gymId: gymParams.id,
                gymBranch: gymParams.branch,
                gymRegion: gymParams.region,
                discipline: .leadEndurance,
                routes: leadRoutes,
                sessionDate: Date()
            )
            ClimbingDataManager.shared.addSession(leadData)
        }

        // Use the first session for card creation
        let climbingData = !boulderingRoutes.isEmpty ?
            ClimbingData(gymName: gymParams.name, gymId: gymParams.id, gymBranch: gymParams.branch, gymRegion: gymParams.region, discipline: .bouldering, routes: boulderingRoutes, sessionDate: Date()) :
            ClimbingData(gymName: gymParams.name, gymId: gymParams.id, gymBranch: gymParams.branch, gymRegion: gymParams.region, discipline: .leadEndurance, routes: leadRoutes, sessionDate: Date())

        // Save custom gym if it's a new custom gym
        if isCustomGym && !gymParams.name.isEmpty {
            // Check if custom gym with this name already exists
            if ClimbingGymManager.shared.findGym(byName: gymParams.name) == nil {
                let newGym = ClimbingGym(
                    name: gymParams.name,
                    logoSource: .none,  // Custom gyms don't use logo images
                    gradeColors: ClimbingGymManager.shared.defaultGradeColors,
                    isBuiltIn: false
                )
                ClimbingGymManager.shared.addGym(newGym)
            }
        }

        // Sessions already saved above (grouped by discipline)

        // Dismiss 후에 delegate를 통해 알림 요청
        delegate?.climbingInputDidRequestCardCreation(self, session: climbingData)
        dismiss(animated: true)
    }

    private func getGymParams() -> (name: String, id: String?, branch: String?, region: String?, logoData: Data?) {
        if let gym = selectedGym {
            return (gym.name, gym.id, gym.metadata?.branch, gym.metadata?.region, nil)
        }
        return (customGymName, nil, nil, nil, nil)
    }

    @objc private func customGymNameChanged(_ textField: UITextField) {
        customGymName = textField.text ?? ""
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - TableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 && indexPath.row == 0 {
            showGymSelector()
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
            // Reload all sections to update colors in route cells
            tableView.reloadSections(IndexSet([0, 1, 2]), with: .automatic)
        }
    }

    private func selectCustomGym() {
        let wasGymSelected = selectedGym != nil || isCustomGym
        self.selectedGym = nil
        self.isCustomGym = true
        self.customGymName = ""

        // If sections changed (1 -> 3), use reloadData
        if !wasGymSelected {
            tableView.reloadData()
        } else {
            // Reload all sections to update colors in route cells
            tableView.reloadSections(IndexSet([0, 1, 2]), with: .automatic)
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
    private enum Constants {
        static let textFieldVerticalPadding: CGFloat = 10
        static let textFieldHorizontalPadding: CGFloat = 20
        static let textFieldMinHeight: CGFloat = 44
    }
    
    private let textField = UITextField()
    private var onTextChange: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        
        textField.font = .systemFont(ofSize: 34, weight: .bold) // Large Title style
        textField.textColor = ColorSystem.mainText
        textField.placeholder = "Gym Name"
        textField.borderStyle = .none
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        textField.delegate = self
        
        contentView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.textFieldVerticalPadding)
            make.leading.equalToSuperview().offset(Constants.textFieldHorizontalPadding)
            make.trailing.equalToSuperview().offset(-Constants.textFieldHorizontalPadding)
            make.bottom.equalToSuperview().offset(-Constants.textFieldVerticalPadding)
            make.height.greaterThanOrEqualTo(Constants.textFieldMinHeight)
        }
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
    private enum Constants {
        static let disciplineButtonVerticalPadding: CGFloat = 5
        static let disciplineButtonHeight: CGFloat = 44
    }
    
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
        container.backgroundColor = ColorSystem.cardBackground
        container.layer.cornerRadius = 10
        container.clipsToBounds = true
        
        contentView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 2
        stackView.backgroundColor = ColorSystem.divider // Separator color
        
        container.addSubview(stackView)

        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.disciplineButtonVerticalPadding)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Constants.disciplineButtonVerticalPadding)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(Constants.disciplineButtonHeight)
        }
        
        setupButtons()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupButtons() {
        stackView.spacing = 6
        stackView.distribution = .fillEqually
        stackView.backgroundColor = .clear // No separator line

        for discipline in ClimbingDiscipline.allCases {
            let btn = UIButton(type: .system)
            btn.setTitle(discipline.displayName, for: .normal)
            btn.setTitleColor(ColorSystem.subText, for: .normal)
            btn.setTitleColor(.white, for: .selected)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)

            // Initial state
            btn.backgroundColor = ColorSystem.background

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
                    btn.backgroundColor = ColorSystem.primaryGreen
                    btn.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    btn.layer.shadowColor = ColorSystem.primaryGreen.cgColor
                    btn.layer.shadowOffset = CGSize(width: 0, height: 2)
                    btn.layer.shadowOpacity = 0.3
                    btn.layer.shadowRadius = 4
                    btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
                } else {
                    btn.backgroundColor = ColorSystem.background
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
    
    private enum Constants {
        static let saveButtonVerticalPadding: CGFloat = 8
        static let saveButtonHorizontalPadding: CGFloat = 20
        static let saveButtonHeight: CGFloat = 50
    }

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
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.saveButtonVerticalPadding)
            make.leading.equalToSuperview().offset(Constants.saveButtonHorizontalPadding)
            make.trailing.equalToSuperview().offset(-Constants.saveButtonHorizontalPadding)
            make.bottom.equalToSuperview().offset(-Constants.saveButtonVerticalPadding)
            make.height.equalTo(Constants.saveButtonHeight)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, style: Style, onTap: @escaping () -> Void) {
        button.setTitle(title, for: .normal)
        self.onTap = onTap

        switch style {
        case .primary:
            button.backgroundColor = ColorSystem.primaryGreen
            button.setTitleColor(.white, for: .normal)
        case .secondary:
            button.backgroundColor = ColorSystem.cardBackground
            button.setTitleColor(ColorSystem.primaryGreen, for: .normal)
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
    private let disciplineSegment = UISegmentedControl(items: [WorkoutPlazaStrings.Climbing.Discipline.bouldering, WorkoutPlazaStrings.Climbing.Discipline.lead])
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
        containerView.backgroundColor = ColorSystem.cardBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.cornerCurve = .continuous
        // containerView.layer.shadowColor = UIColor.black.cgColor
        // containerView.layer.shadowOpacity = 0.05
        // containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        // containerView.layer.shadowRadius = 4
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-6)
        }
        
        // Header
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        
        headerLabel.font = .systemFont(ofSize: 17, weight: .bold)
        headerLabel.textColor = ColorSystem.mainText

        // Discipline Segment
        disciplineSegment.selectedSegmentIndex = 0
        disciplineSegment.addTarget(self, action: #selector(disciplineChanged), for: .valueChanged)

        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = ColorSystem.error
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        headerStack.addArrangedSubview(headerLabel)
        headerStack.addArrangedSubview(disciplineSegment)
        headerStack.addArrangedSubview(UIView()) // Spacer
        headerStack.addArrangedSubview(deleteButton)
        
        containerView.addSubview(headerStack)

        // Color Section Label
        colorSectionLabel.text = WorkoutPlazaStrings.Climbing.Grade.tape
        colorSectionLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        colorSectionLabel.textColor = ColorSystem.subText
        containerView.addSubview(colorSectionLabel)

        // Color Section
        colorScrollView.showsHorizontalScrollIndicator = false
        colorStack.axis = .horizontal
        colorStack.spacing = 10
        colorStack.alignment = .center
        colorScrollView.addSubview(colorStack)

        colorStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalToSuperview()
        }
        
        let defaults = ClimbingGymManager.shared.defaultGradeColors.compactMap { UIColor(climbingHex: $0) }
        for i in 0..<defaults.count {
            let btn = createColorButton(color: defaults[i], tag: i)
            colorButtons.append(btn)
            colorStack.addArrangedSubview(btn)
        }
        
        customColorButton = UIButton(type: .system)
        customColorButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        customColorButton.tintColor = ColorSystem.mainText
        customColorButton.addTarget(self, action: #selector(customColorTapped), for: .touchUpInside)
        colorStack.addArrangedSubview(customColorButton)
        
        containerView.addSubview(colorScrollView)

        // Grade
        gradeLabel.text = WorkoutPlazaStrings.Climbing.Grade.optional
        gradeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        gradeLabel.textColor = ColorSystem.subText

        gradeField.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        gradeField.backgroundColor = ColorSystem.background
        gradeField.textColor = ColorSystem.mainText
        gradeField.layer.cornerRadius = 6
        gradeField.textAlignment = .center
        gradeField.returnKeyType = .done
        gradeField.delegate = self
        gradeField.placeholder = WorkoutPlazaStrings.Climbing.Grade.Placeholder.boulder
        gradeField.addTarget(self, action: #selector(gradeChanged), for: .editingChanged)

        gradeStack.axis = .vertical
        gradeStack.spacing = 4
        gradeStack.addArrangedSubview(gradeLabel)
        gradeStack.addArrangedSubview(gradeField)

        // Attempts
        attemptsLabel.text = "ATTEMPTS"
        attemptsLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        attemptsLabel.textColor = ColorSystem.subText

        attemptsValueLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        attemptsValueLabel.textColor = ColorSystem.mainText
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
        sentLabel.text = WorkoutPlazaStrings.Climbing.sent
        sentLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        sentLabel.textColor = ColorSystem.mainText

        sentSwitch.onTintColor = ColorSystem.success
        sentSwitch.addTarget(self, action: #selector(sentChanged), for: .valueChanged)

        let sentStack = UIStackView(arrangedSubviews: [sentLabel, sentSwitch])
        sentStack.axis = .vertical
        sentStack.alignment = .center
        sentStack.spacing = 8

        // Layout Main Content
        containerView.addSubview(gradeStack)
        containerView.addSubview(attemptsStack)
        containerView.addSubview(sentStack)

        // Create SnapKit constraints
        headerStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        colorSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
        }

        colorScrollView.snp.makeConstraints { make in
            make.top.equalTo(colorSectionLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }
        colorSectionHeightConstraint = colorScrollView.heightAnchor.constraint(equalToConstant: 44)
        colorSectionHeightConstraint.isActive = true

        // Create two different top constraints for gradeStack (kept as NSLayoutConstraint for conditional activation)
        gradeStackTopToColorConstraint = gradeStack.topAnchor.constraint(equalTo: colorScrollView.bottomAnchor, constant: 16)
        gradeStackTopToHeaderConstraint = gradeStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16)
        gradeStackTopToColorConstraint.isActive = true

        gradeStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(80)
            make.bottom.equalToSuperview().offset(-16)
        }

        gradeField.snp.makeConstraints { make in
            make.height.equalTo(36)
        }

        sentStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(gradeStack)
        }

        attemptsStack.snp.makeConstraints { make in
            make.centerY.equalTo(gradeStack)
            make.centerX.equalToSuperview()
        }
    }
    
    // ... helpers and configure ...
    
    private func createColorButton(color: UIColor, tag: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = 0
        btn.tag = tag
        btn.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)

        btn.snp.makeConstraints { make in
            make.size.equalTo(32)
        }

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
            gradeLabel.text = WorkoutPlazaStrings.Climbing.Grade.optional
            gradeField.placeholder = WorkoutPlazaStrings.Climbing.Grade.Placeholder.boulder
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
            customColorButton.tintColor = ColorSystem.mainText
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
            gradeLabel.text = WorkoutPlazaStrings.Climbing.Grade.optional
            gradeField.placeholder = WorkoutPlazaStrings.Climbing.Grade.Placeholder.boulder
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
