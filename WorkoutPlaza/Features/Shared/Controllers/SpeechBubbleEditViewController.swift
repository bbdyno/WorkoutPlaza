//
//  SpeechBubbleEditViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/5/26.
//

import UIKit
import SnapKit

// MARK: - Delegate

protocol SpeechBubbleEditDelegate: AnyObject {
    func speechBubbleEdit(_ vc: SpeechBubbleEditViewController, didUpdate payload: SpeechBubblePayload)
}

// MARK: - View Controller

final class SpeechBubbleEditViewController: UIViewController {

    // MARK: - Init

    var initialPayload: SpeechBubblePayload = .default
    weak var editDelegate: SpeechBubbleEditDelegate?
    weak var editingWidget: SpeechBubbleWidget?

    private var currentPayload: SpeechBubblePayload = .default {
        didSet { updatePreview() }
    }

    // MARK: - UI

    private let previewWidget: SpeechBubbleWidget = {
        let w = SpeechBubbleWidget()
        w.isUserInteractionEnabled = false
        w.layer.cornerRadius = 8
        w.clipsToBounds = false
        return w
    }()

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 20
        sv.alignment = .fill
        return sv
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.textColor = ColorSystem.mainText
        tv.backgroundColor = ColorSystem.cardBackground
        tv.layer.cornerRadius = 10
        tv.layer.borderWidth = 1
        tv.layer.borderColor = ColorSystem.divider.cgColor
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return tv
    }()

    private let fontButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = ColorSystem.cardBackground
        config.baseForegroundColor = ColorSystem.mainText
        config.cornerStyle = .medium
        config.title = NSLocalizedString("bubble.edit.font", comment: "폰트")
        config.image = UIImage(systemName: "textformat")
        config.imagePadding = 6
        let btn = UIButton(configuration: config)
        return btn
    }()

    // 색상 피커 행들
    private let textColorPicker    = ColorRowView(title: NSLocalizedString("bubble.edit.textColor", comment: "글자 색"))
    private let bubbleColorPicker  = ColorRowView(title: NSLocalizedString("bubble.edit.bgColor", comment: "배경 색"))
    private let borderColorPicker  = ColorRowView(title: NSLocalizedString("bubble.edit.borderColor", comment: "테두리 색"))

    private let borderWidthSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 0
        s.maximumValue = 8
        s.tintColor = ColorSystem.controlTint
        return s
    }()

    private var activePicker: ColorTarget? = nil
    private enum ColorTarget { case text, bubble, border }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("bubble.edit.title", comment: "말풍선 편집")
        view.backgroundColor = ColorSystem.background

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        setupLayout()
        loadPayload()
    }

    // MARK: - Setup

    private func setupLayout() {
        // Preview
        view.addSubview(previewWidget)
        previewWidget.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.55)
            make.height.equalTo(previewWidget.snp.width).multipliedBy(0.65)
        }

        // Scroll
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(previewWidget.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16))
            make.width.equalToSuperview().offset(-32)
        }

        // Text
        contentStack.addArrangedSubview(sectionHeader(NSLocalizedString("bubble.edit.text", comment: "텍스트")))
        contentStack.addArrangedSubview(textView)
        textView.snp.makeConstraints { $0.height.equalTo(80) }
        textView.delegate = self

        // Font
        contentStack.addArrangedSubview(fontButton)
        fontButton.addTarget(self, action: #selector(fontTapped), for: .touchUpInside)

        // Colors
        contentStack.addArrangedSubview(sectionHeader(NSLocalizedString("bubble.edit.colors", comment: "색상")))

        textColorPicker.onTap   = { [weak self] in self?.showColorPicker(for: .text) }
        bubbleColorPicker.onTap = { [weak self] in self?.showColorPicker(for: .bubble) }
        borderColorPicker.onTap = { [weak self] in self?.showColorPicker(for: .border) }

        contentStack.addArrangedSubview(textColorPicker)
        contentStack.addArrangedSubview(bubbleColorPicker)
        contentStack.addArrangedSubview(borderColorPicker)

        // Border width
        contentStack.addArrangedSubview(sectionHeader(NSLocalizedString("bubble.edit.borderWidth", comment: "테두리 굵기")))
        contentStack.addArrangedSubview(borderWidthSlider)
        borderWidthSlider.addTarget(self, action: #selector(borderWidthChanged), for: .valueChanged)

        // Dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func loadPayload() {
        currentPayload = initialPayload

        textView.text = initialPayload.text
        textColorPicker.setColor(initialPayload.textColor)
        bubbleColorPicker.setColor(initialPayload.bubbleColor)
        borderColorPicker.setColor(initialPayload.borderColor)
        borderWidthSlider.value = Float(initialPayload.borderWidth)
        fontButton.configuration?.subtitle = initialPayload.fontStyle.displayName
    }

    private func updatePreview() {
        previewWidget.configure(payload: currentPayload)
        if previewWidget.initialSize == .zero, previewWidget.bounds.size != .zero {
            previewWidget.initialSize = previewWidget.bounds.size
        }
    }

    private func sectionHeader(_ title: String) -> UILabel {
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = ColorSystem.subText
        return l
    }

    // MARK: - Actions

    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func doneTapped() {
        editDelegate?.speechBubbleEdit(self, didUpdate: currentPayload)
        dismiss(animated: true)
    }

    @objc private func borderWidthChanged() {
        currentPayload.borderWidth = CGFloat(borderWidthSlider.value)
    }

    @objc private func fontTapped() {
        showFontPicker()
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    // MARK: - Color Picker

    private func showColorPicker(for target: ColorTarget) {
        activePicker = target
        let initial: UIColor
        switch target {
        case .text:   initial = currentPayload.textColor
        case .bubble: initial = currentPayload.bubbleColor
        case .border: initial = currentPayload.borderColor
        }
        let picker = UIColorPickerViewController()
        picker.selectedColor = initial
        picker.supportsAlpha = false
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Font Picker

    private func showFontPicker() {
        let styles = FontStyle.allCases
        let alert = UIAlertController(
            title: NSLocalizedString("bubble.edit.font", comment: "폰트"),
            message: nil, preferredStyle: .actionSheet)

        for style in styles {
            alert.addAction(UIAlertAction(title: style.displayName, style: .default) { [weak self] _ in
                self?.currentPayload.fontStyleRaw = style.rawValue
                self?.fontButton.configuration?.subtitle = style.displayName
            })
        }
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = fontButton
            popover.sourceRect = fontButton.bounds
        }
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate

extension SpeechBubbleEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        currentPayload.text = textView.text
    }
}

// MARK: - UIColorPickerViewControllerDelegate

extension SpeechBubbleEditViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ vc: UIColorPickerViewController) {
        let hex = vc.selectedColor.toHex() ?? "#000000"
        switch activePicker {
        case .text:
            currentPayload.textColorHex = hex
            textColorPicker.setColor(vc.selectedColor)
        case .bubble:
            currentPayload.bubbleColorHex = hex
            bubbleColorPicker.setColor(vc.selectedColor)
        case .border:
            currentPayload.borderColorHex = hex
            borderColorPicker.setColor(vc.selectedColor)
        case .none:
            break
        }
    }
}

// MARK: - ColorRowView

private final class ColorRowView: UIView {
    var onTap: (() -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15)
        l.textColor = ColorSystem.mainText
        return l
    }()

    private let colorSwatch: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = ColorSystem.divider.cgColor
        return v
    }()

    private let chevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = ColorSystem.subText
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        backgroundColor = ColorSystem.cardBackground
        layer.cornerRadius = 10

        addSubview(titleLabel)
        addSubview(colorSwatch)
        addSubview(chevron)

        snp.makeConstraints { $0.height.equalTo(48) }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        colorSwatch.snp.makeConstraints { make in
            make.trailing.equalTo(chevron.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func setColor(_ color: UIColor) {
        colorSwatch.backgroundColor = color
    }

    @objc private func tapped() { onTap?() }
}
