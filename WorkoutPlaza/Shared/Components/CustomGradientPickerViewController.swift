//
//  CustomGradientPickerViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit

protocol CustomGradientPickerDelegate: AnyObject {
    func customGradientPicker(_ picker: CustomGradientPickerViewController, didSelectColors colors: [UIColor], direction: GradientDirection)
}

enum GradientDirection: Int, CaseIterable {
    case topToBottom = 0      // 상하 수직
    case leftToRight = 1      // 좌우 수평
    case topLeftToBottomRight = 2  // 왼오 대각선
    case topRightToBottomLeft = 3  // 오왼 대각선

    var displayName: String {
        switch self {
        case .topToBottom: return "수직"
        case .leftToRight: return "수평"
        case .topLeftToBottomRight: return "대각선 ↘"
        case .topRightToBottomLeft: return "대각선 ↙"
        }
    }

    var iconName: String {
        switch self {
        case .topToBottom: return "arrow.down"
        case .leftToRight: return "arrow.right"
        case .topLeftToBottomRight: return "arrow.down.right"
        case .topRightToBottomLeft: return "arrow.down.left"
        }
    }

    var startPoint: CGPoint {
        switch self {
        case .topToBottom: return CGPoint(x: 0.5, y: 0)
        case .leftToRight: return CGPoint(x: 0, y: 0.5)
        case .topLeftToBottomRight: return CGPoint(x: 0, y: 0)
        case .topRightToBottomLeft: return CGPoint(x: 1, y: 0)
        }
    }

    var endPoint: CGPoint {
        switch self {
        case .topToBottom: return CGPoint(x: 0.5, y: 1)
        case .leftToRight: return CGPoint(x: 1, y: 0.5)
        case .topLeftToBottomRight: return CGPoint(x: 1, y: 1)
        case .topRightToBottomLeft: return CGPoint(x: 0, y: 1)
        }
    }
}

class CustomGradientPickerViewController: UIViewController {

    weak var delegate: CustomGradientPickerDelegate?

    private var startColor: UIColor = ColorSystem.primaryBlue
    private var endColor: UIColor = ColorSystem.primaryGreen
    private var selectedDirection: GradientDirection = .topLeftToBottomRight

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        return stack
    }()

    private let previewView = BackgroundTemplateView()
    private let previewGradientLayer = CAGradientLayer()

    // Direction Section
    private let directionLabel: UILabel = {
        let label = UILabel()
        label.text = "방향"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let directionStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()

    private var directionButtons: [UIButton] = []

    // Start Color Section
    private let startColorSection: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let startColorSwatch: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 4
        return view
    }()

    private let startLabel: UILabel = {
        let label = UILabel()
        label.text = "시작 색상"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let startColorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("변경", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    // End Color Section
    private let endColorSection: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let endColorSwatch: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 4
        return view
    }()

    private let endLabel: UILabel = {
        let label = UILabel()
        label.text = "종료 색상"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let endColorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("변경", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    // Bottom button container
    private let bottomContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    private let applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("적용", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updatePreview()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewGradientLayer.frame = previewView.bounds
    }

    // MARK: - Setup

    private func setupUI() {
        title = "커스텀 그라데이션"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        // Bottom container (fixed)
        view.addSubview(bottomContainer)
        bottomContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(100)
        }

        bottomContainer.addSubview(applyButton)
        applyButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(50)
        }
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)

        // Scroll view
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomContainer.snp.top)
        }

        scrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }

        // Preview container
        let previewContainer = UIView()
        contentStackView.addArrangedSubview(previewContainer)

        previewContainer.addSubview(previewView)
        previewView.layer.cornerRadius = 16
        previewView.clipsToBounds = true
        previewView.layer.borderWidth = 1
        previewView.layer.borderColor = UIColor.separator.cgColor

        // Add custom gradient layer to preview
        previewView.layer.addSublayer(previewGradientLayer)

        previewView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(140)
            make.height.equalTo(180)
        }

        // Direction Section
        let directionContainer = UIView()
        contentStackView.addArrangedSubview(directionContainer)

        directionContainer.addSubview(directionLabel)
        directionLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        directionContainer.addSubview(directionStackView)
        directionStackView.snp.makeConstraints { make in
            make.top.equalTo(directionLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(44)
        }

        setupDirectionButtons()

        // Start Color Section
        setupStartColorSection()
        contentStackView.addArrangedSubview(startColorSection)
        startColorSection.snp.makeConstraints { make in
            make.height.equalTo(64)
        }

        // End Color Section
        setupEndColorSection()
        contentStackView.addArrangedSubview(endColorSection)
        endColorSection.snp.makeConstraints { make in
            make.height.equalTo(64)
        }
    }

    private func setupDirectionButtons() {
        for direction in GradientDirection.allCases {
            let button = UIButton(type: .system)
            button.tag = direction.rawValue
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.clear.cgColor

            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            button.setImage(UIImage(systemName: direction.iconName, withConfiguration: config), for: .normal)
            button.tintColor = .label

            button.addTarget(self, action: #selector(directionButtonTapped(_:)), for: .touchUpInside)
            directionButtons.append(button)
            directionStackView.addArrangedSubview(button)
        }
        updateDirectionSelection()
    }

    private func setupStartColorSection() {
        startColorSection.addSubview(startColorSwatch)
        startColorSwatch.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }

        startColorSection.addSubview(startLabel)
        startLabel.snp.makeConstraints { make in
            make.leading.equalTo(startColorSwatch.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        startColorSection.addSubview(startColorButton)
        startColorButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(32)
        }

        let startTap = UITapGestureRecognizer(target: self, action: #selector(pickStartColor))
        startColorSection.addGestureRecognizer(startTap)
        startColorButton.addTarget(self, action: #selector(pickStartColor), for: .touchUpInside)
    }

    private func setupEndColorSection() {
        endColorSection.addSubview(endColorSwatch)
        endColorSwatch.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }

        endColorSection.addSubview(endLabel)
        endLabel.snp.makeConstraints { make in
            make.leading.equalTo(endColorSwatch.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        endColorSection.addSubview(endColorButton)
        endColorButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(32)
        }

        let endTap = UITapGestureRecognizer(target: self, action: #selector(pickEndColor))
        endColorSection.addGestureRecognizer(endTap)
        endColorButton.addTarget(self, action: #selector(pickEndColor), for: .touchUpInside)
    }

    private func updateDirectionSelection() {
        for button in directionButtons {
            let isSelected = button.tag == selectedDirection.rawValue
            button.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
            button.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .secondarySystemBackground
            button.tintColor = isSelected ? .systemBlue : .label
        }
    }

    private func updatePreview() {
        // Update gradient layer
        previewGradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        previewGradientLayer.startPoint = selectedDirection.startPoint
        previewGradientLayer.endPoint = selectedDirection.endPoint

        // Update color swatches
        startColorSwatch.backgroundColor = startColor
        endColorSwatch.backgroundColor = endColor
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func directionButtonTapped(_ sender: UIButton) {
        guard let direction = GradientDirection(rawValue: sender.tag) else { return }
        selectedDirection = direction
        updateDirectionSelection()
        updatePreview()
    }

    @objc private func pickStartColor() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = startColor
        picker.delegate = self
        picker.view.tag = 1
        present(picker, animated: true)
    }

    @objc private func pickEndColor() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = endColor
        picker.delegate = self
        picker.view.tag = 2
        present(picker, animated: true)
    }

    @objc private func applyTapped() {
        delegate?.customGradientPicker(self, didSelectColors: [startColor, endColor], direction: selectedDirection)
        dismiss(animated: true)
    }
}

// MARK: - UIColorPickerViewControllerDelegate

extension CustomGradientPickerViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        if viewController.view.tag == 1 {
            startColor = viewController.selectedColor
        } else {
            endColor = viewController.selectedColor
        }
        updatePreview()
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if viewController.view.tag == 1 {
            startColor = viewController.selectedColor
        } else {
            endColor = viewController.selectedColor
        }
        updatePreview()
    }
}
