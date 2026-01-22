//
//  ClimbingInputViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit
import SnapKit

protocol ClimbingInputDelegate: AnyObject {
    func climbingInput(_ controller: ClimbingInputViewController, didCreateSession session: ClimbingData)
}

class ClimbingInputViewController: UIViewController {

    weak var delegate: ClimbingInputDelegate?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        return stack
    }()

    // Header
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "클라이밍 기록"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        return label
    }()

    // Gym Name Section
    private let gymSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "클라이밍짐"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let gymTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "짐 이름을 입력하세요"
        tf.font = .systemFont(ofSize: 17)
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        tf.returnKeyType = .done
        return tf
    }()

    // Discipline Section
    private let disciplineSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "종목"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let disciplineSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ClimbingDiscipline.allCases.map { $0.displayName })
        sc.selectedSegmentIndex = 0
        return sc
    }()

    // Routes Section
    private let routesSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "루트 기록"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let routesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        return stack
    }()

    private lazy var addRouteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ 루트 추가", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(addRouteTapped), for: .touchUpInside)
        return button
    }()

    // Create Button
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("기록 생성", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()

    // MARK: - Data
    private var routes: [ClimbingRoute] = []
    private var routeViews: [RouteInputView] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardDismissal()
        addInitialRoute()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "클라이밍"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    private func setupKeyboardDismissal() {
        // Tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // ScrollView keyboard dismiss mode
        scrollView.keyboardDismissMode = .onDrag
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }

        // Header
        contentStackView.addArrangedSubview(headerLabel)

        // Gym Section
        let gymContainer = createSectionContainer()
        gymContainer.addArrangedSubview(gymSectionLabel)
        gymContainer.addArrangedSubview(gymTextField)
        gymTextField.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        gymTextField.delegate = self
        contentStackView.addArrangedSubview(gymContainer)

        // Discipline Section
        let disciplineContainer = createSectionContainer()
        disciplineContainer.addArrangedSubview(disciplineSectionLabel)
        disciplineContainer.addArrangedSubview(disciplineSegmentedControl)
        disciplineSegmentedControl.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        disciplineSegmentedControl.addTarget(self, action: #selector(disciplineChanged), for: .valueChanged)
        contentStackView.addArrangedSubview(disciplineContainer)

        // Routes Section
        let routesContainer = createSectionContainer()
        routesContainer.addArrangedSubview(routesSectionLabel)
        routesContainer.addArrangedSubview(routesStackView)
        routesContainer.addArrangedSubview(addRouteButton)
        addRouteButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        contentStackView.addArrangedSubview(routesContainer)

        // Spacer
        let spacer = UIView()
        spacer.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        contentStackView.addArrangedSubview(spacer)

        // Create Button
        contentStackView.addArrangedSubview(createButton)
        createButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }

    private func createSectionContainer() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }

    private func addInitialRoute() {
        addRouteView()
    }

    // MARK: - Route Management

    private func addRouteView() {
        let selectedDiscipline = ClimbingDiscipline.allCases[disciplineSegmentedControl.selectedSegmentIndex]
        let routeView = RouteInputView(discipline: selectedDiscipline)
        routeView.delegate = self
        routeView.tag = routeViews.count

        routesStackView.addArrangedSubview(routeView)
        routeViews.append(routeView)

        updateRouteNumbers()
    }

    private func removeRouteView(_ routeView: RouteInputView) {
        guard routeViews.count > 1 else { return } // Keep at least one

        routeView.removeFromSuperview()
        if let index = routeViews.firstIndex(of: routeView) {
            routeViews.remove(at: index)
        }

        updateRouteNumbers()
    }

    private func updateRouteNumbers() {
        for (index, routeView) in routeViews.enumerated() {
            routeView.routeNumber = index + 1
        }
    }

    private func updateAllRoutesDiscipline(_ discipline: ClimbingDiscipline) {
        for routeView in routeViews {
            routeView.updateDiscipline(discipline)
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func addRouteTapped() {
        addRouteView()
    }

    @objc private func disciplineChanged() {
        let selectedDiscipline = ClimbingDiscipline.allCases[disciplineSegmentedControl.selectedSegmentIndex]
        updateAllRoutesDiscipline(selectedDiscipline)
    }

    @objc private func createTapped() {
        guard let gymName = gymTextField.text, !gymName.isEmpty else {
            showAlert(title: "오류", message: "클라이밍짐 이름을 입력해주세요.")
            return
        }

        // Collect routes from views
        var collectedRoutes: [ClimbingRoute] = []
        for routeView in routeViews {
            if let route = routeView.getRoute() {
                collectedRoutes.append(route)
            }
        }

        guard !collectedRoutes.isEmpty else {
            showAlert(title: "오류", message: "최소 하나의 루트를 기록해주세요.")
            return
        }

        let discipline = ClimbingDiscipline.allCases[disciplineSegmentedControl.selectedSegmentIndex]

        let climbingData = ClimbingData(
            gymName: gymName,
            discipline: discipline,
            routes: collectedRoutes,
            sessionDate: Date()
        )

        // Dismiss first, then call delegate in completion to allow proper presentation
        dismiss(animated: true) { [weak self] in
            self?.delegate?.climbingInput(self!, didCreateSession: climbingData)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - RouteInputViewDelegate

extension ClimbingInputViewController: RouteInputViewDelegate {
    func routeInputViewDidRequestDelete(_ view: RouteInputView) {
        removeRouteView(view)
    }
}

// MARK: - UITextFieldDelegate

extension ClimbingInputViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Route Input View

protocol RouteInputViewDelegate: AnyObject {
    func routeInputViewDidRequestDelete(_ view: RouteInputView)
}

class RouteInputView: UIView {

    weak var delegate: RouteInputViewDelegate?

    var routeNumber: Int = 1 {
        didSet {
            routeNumberLabel.text = "루트 \(routeNumber)"
        }
    }

    private var discipline: ClimbingDiscipline
    private var selectedColor: UIColor? {
        didSet {
            updateColorIndicator()
        }
    }

    // Preset colors for climbing holds
    private let presetColors: [(name: String, color: UIColor)] = [
        ("빨강", .systemRed),
        ("주황", .systemOrange),
        ("노랑", .systemYellow),
        ("초록", .systemGreen),
        ("파랑", .systemBlue),
        ("보라", .systemPurple),
        ("핑크", .systemPink),
        ("흰색", .white),
        ("검정", .black),
        ("회색", .systemGray)
    ]

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let routeNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .systemOrange
        return label
    }()

    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemGray3
        return button
    }()

    // Color Section
    private let colorLabel: UILabel = {
        let label = UILabel()
        label.text = "홀드 색상"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()

    private let colorScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private let colorStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private let selectedColorIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemGray4.cgColor
        view.backgroundColor = .clear
        return view
    }()

    private let colorCheckmark: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    // Grade Section
    private let gradeLabel: UILabel = {
        let label = UILabel()
        label.text = "난이도 (선택)"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()

    private let gradeTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "예: V3, 5.11a"
        tf.font = .systemFont(ofSize: 15)
        tf.backgroundColor = .tertiarySystemBackground
        tf.layer.cornerRadius = 8
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.returnKeyType = .done
        return tf
    }()

    private let metricLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()

    private let metricStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 0
        stepper.maximumValue = 99
        stepper.value = 1
        return stepper
    }()

    private let metricValueLabel: UILabel = {
        let label = UILabel()
        label.text = "1"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let sentSwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = .systemGreen
        return sw
    }()

    private let sentLabel: UILabel = {
        let label = UILabel()
        label.text = "완등"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        return label
    }()

    // MARK: - Initialization

    init(discipline: ClimbingDiscipline) {
        self.discipline = discipline
        super.init(frame: .zero)
        setupUI()
        setupColorButtons()
        updateForDiscipline()
    }

    required init?(coder: NSCoder) {
        self.discipline = .bouldering
        super.init(coder: coder)
        setupUI()
        setupColorButtons()
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Header row
        containerView.addSubview(routeNumberLabel)
        containerView.addSubview(deleteButton)

        routeNumberLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }

        deleteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(12)
            make.width.height.equalTo(24)
        }
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        // Color section
        containerView.addSubview(colorLabel)
        containerView.addSubview(colorScrollView)
        colorScrollView.addSubview(colorStackView)

        colorLabel.snp.makeConstraints { make in
            make.top.equalTo(routeNumberLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
        }

        colorScrollView.snp.makeConstraints { make in
            make.top.equalTo(colorLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        colorStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            make.height.equalToSuperview()
        }

        // Grade row
        containerView.addSubview(gradeLabel)
        containerView.addSubview(gradeTextField)

        gradeLabel.snp.makeConstraints { make in
            make.top.equalTo(colorScrollView.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
        }

        gradeTextField.snp.makeConstraints { make in
            make.top.equalTo(gradeLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        gradeTextField.delegate = self

        // Metric row (attempts or takes)
        containerView.addSubview(metricLabel)
        containerView.addSubview(metricValueLabel)
        containerView.addSubview(metricStepper)

        metricLabel.snp.makeConstraints { make in
            make.top.equalTo(gradeTextField.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
        }

        metricStepper.snp.makeConstraints { make in
            make.centerY.equalTo(metricLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        metricStepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)

        metricValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(metricLabel)
            make.trailing.equalTo(metricStepper.snp.leading).offset(-12)
            make.width.equalTo(30)
        }

        // Sent row
        containerView.addSubview(sentLabel)
        containerView.addSubview(sentSwitch)

        sentLabel.snp.makeConstraints { make in
            make.top.equalTo(metricLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        sentSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(sentLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        routeNumberLabel.text = "루트 \(routeNumber)"
    }

    private func setupColorButtons() {
        // Add preset color buttons
        for (index, preset) in presetColors.enumerated() {
            let button = createColorButton(color: preset.color, tag: index)
            colorStackView.addArrangedSubview(button)
        }

        // Add custom color picker button
        let customButton = UIButton(type: .system)
        customButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        customButton.tintColor = .systemGray
        customButton.tag = 999 // Special tag for custom color button
        customButton.layer.cornerRadius = 18
        customButton.layer.borderWidth = 2
        customButton.layer.borderColor = UIColor.systemGray4.cgColor
        customButton.addTarget(self, action: #selector(showCustomColorPicker), for: .touchUpInside)
        customButton.snp.makeConstraints { make in
            make.width.height.equalTo(36)
        }
        colorStackView.addArrangedSubview(customButton)
    }

    private func createColorButton(color: UIColor, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = color
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.tag = tag
        button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)

        // Add shadow for light colors
        if color == .white || color == .systemYellow {
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            button.layer.shadowOpacity = 0.2
            button.layer.shadowRadius = 2
        }

        button.snp.makeConstraints { make in
            make.width.height.equalTo(36)
        }
        return button
    }

    private func updateColorIndicator() {
        guard let selected = selectedColor else {
            // No color selected - reset all buttons
            for case let button as UIButton in colorStackView.arrangedSubviews {
                if button.tag < presetColors.count {
                    button.layer.borderColor = UIColor.systemGray4.cgColor
                    button.layer.borderWidth = 2
                }
            }
            return
        }

        // Check if selected color matches any preset
        var foundPreset = false
        for preset in presetColors {
            if colorsAreEqual(selected, preset.color) {
                foundPreset = true
                break
            }
        }

        // Update all buttons to show selection state
        for case let button as UIButton in colorStackView.arrangedSubviews {
            if button.tag < presetColors.count {
                let presetColor = presetColors[button.tag].color
                let isSelected = colorsAreEqual(selected, presetColor)
                button.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.systemGray4.cgColor
                button.layer.borderWidth = isSelected ? 3 : 2
            } else if button.tag == 999 {
                // Custom color indicator button
                if !foundPreset {
                    button.backgroundColor = selected
                    button.layer.borderColor = UIColor.systemBlue.cgColor
                    button.layer.borderWidth = 3
                    button.setImage(nil, for: .normal)
                } else {
                    button.backgroundColor = .clear
                    button.layer.borderColor = UIColor.systemGray4.cgColor
                    button.layer.borderWidth = 2
                    button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
                }
            }
        }
    }

    private func colorsAreEqual(_ color1: UIColor, _ color2: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let tolerance: CGFloat = 0.01
        return abs(r1 - r2) < tolerance && abs(g1 - g2) < tolerance && abs(b1 - b2) < tolerance
    }

    private func updateForDiscipline() {
        switch discipline {
        case .bouldering:
            metricLabel.text = "시도 횟수"
        case .leadEndurance:
            metricLabel.text = "테이크 횟수"
        }
    }

    func updateDiscipline(_ newDiscipline: ClimbingDiscipline) {
        discipline = newDiscipline
        updateForDiscipline()
    }

    // MARK: - Actions

    @objc private func deleteTapped() {
        delegate?.routeInputViewDidRequestDelete(self)
    }

    @objc private func stepperChanged() {
        metricValueLabel.text = "\(Int(metricStepper.value))"
    }

    @objc private func colorButtonTapped(_ sender: UIButton) {
        guard sender.tag < presetColors.count else { return }
        selectedColor = presetColors[sender.tag].color
    }

    @objc private func showCustomColorPicker() {
        // Find the parent view controller and present color picker
        guard let viewController = parentViewController else { return }

        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = selectedColor ?? .systemBlue
        colorPicker.supportsAlpha = false
        viewController.present(colorPicker, animated: true)
    }

    private var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let vc = nextResponder as? UIViewController {
                return vc
            }
            responder = nextResponder
        }
        return nil
    }

    // MARK: - Data

    func getRoute() -> ClimbingRoute? {
        // Require either color or grade
        let grade = gradeTextField.text ?? ""
        let hasColor = selectedColor != nil
        let hasGrade = !grade.isEmpty

        guard hasColor || hasGrade else { return nil }

        let metricValue = Int(metricStepper.value)
        let colorHex = selectedColor?.toHexString()

        return ClimbingRoute(
            grade: grade,
            colorHex: colorHex,
            attempts: discipline == .bouldering ? metricValue : nil,
            takes: discipline == .leadEndurance ? metricValue : nil,
            isSent: sentSwitch.isOn
        )
    }
}

// MARK: - UITextFieldDelegate
extension RouteInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension RouteInputView: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        // Update color when picker is dismissed
        selectedColor = viewController.selectedColor
        updateColorIndicator()
    }

    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        // Update color during selection (both continuous and final)
        selectedColor = color
    }
}

// MARK: - UIColor Extension for Hex
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
