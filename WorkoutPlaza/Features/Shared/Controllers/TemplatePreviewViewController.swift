//
//  TemplatePreviewViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/7/26.
//

import UIKit
import SnapKit

class TemplatePreviewViewController: UIViewController {

    // MARK: - Properties

    private let template: WidgetTemplate
    private let widgetFactory: (WidgetItem, CGRect) -> UIView?
    private let onApply: () -> Void

    // MARK: - UI Components

    private let scrollView = UIScrollView()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        return stack
    }()

    private let canvasContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 8
        view.layer.masksToBounds = false
        return view
    }()

    private let canvasView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.clipsToBounds = true
        return view
    }()

    private let templateNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = ColorSystem.mainText
        label.textAlignment = .center
        return label
    }()

    private let templateDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = ColorSystem.subText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let widgetListHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "포함된 위젯"
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let widgetListStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()

    private let applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("적용", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = ColorSystem.primaryGreen
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        return button
    }()

    private let incompatibleLabel: UILabel = {
        let label = UILabel()
        label.text = "이 템플릿은 최신 버전의 앱이 필요합니다.\n앱을 업데이트해주세요."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Init

    init(
        template: WidgetTemplate,
        widgetFactory: @escaping (WidgetItem, CGRect) -> UIView?,
        onApply: @escaping () -> Void
    ) {
        self.template = template
        self.widgetFactory = widgetFactory
        self.onApply = onApply
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        renderPreviewWidgets()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "닫기",
            style: .done,
            target: self,
            action: #selector(closeTapped)
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }

        // Template name & description
        contentStackView.addArrangedSubview(templateNameLabel)
        contentStackView.addArrangedSubview(templateDescriptionLabel)
        contentStackView.setCustomSpacing(16, after: templateDescriptionLabel)

        // Canvas preview
        canvasContainerView.addSubview(canvasView)
        contentStackView.addArrangedSubview(canvasContainerView)
        contentStackView.setCustomSpacing(16, after: canvasContainerView)

        // Incompatible message
        contentStackView.addArrangedSubview(incompatibleLabel)

        // Widget list
        contentStackView.addArrangedSubview(widgetListHeaderLabel)

        let widgetListContainer = UIView()
        widgetListContainer.backgroundColor = ColorSystem.cardBackground
        widgetListContainer.layer.cornerRadius = 12
        widgetListContainer.layer.cornerCurve = .continuous
        widgetListContainer.addSubview(widgetListStackView)
        widgetListStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        contentStackView.addArrangedSubview(widgetListContainer)
        contentStackView.setCustomSpacing(24, after: widgetListContainer)

        // Apply button
        contentStackView.addArrangedSubview(applyButton)
        applyButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
    }

    private func configureContent() {
        templateNameLabel.text = template.name
        templateDescriptionLabel.text = template.description

        // Setup canvas size with proper aspect ratio
        let templateCanvasSize: CGSize
        if let tcs = template.canvasSize {
            templateCanvasSize = CGSize(width: tcs.width, height: tcs.height)
        } else {
            templateCanvasSize = CGSize(width: 414, height: 700)
        }

        let previewWidth: CGFloat = 200
        let aspectRatio = templateCanvasSize.height / templateCanvasSize.width
        let previewHeight = previewWidth * aspectRatio

        canvasContainerView.snp.makeConstraints { make in
            make.height.equalTo(previewHeight)
            make.width.equalTo(previewWidth)
            make.centerX.equalToSuperview()
        }

        canvasView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Widget list
        for item in template.items {
            let row = createWidgetRow(for: item)
            widgetListStackView.addArrangedSubview(row)
        }

        // Compatibility check
        if !template.isCompatible {
            incompatibleLabel.isHidden = false
            applyButton.isEnabled = false
            applyButton.backgroundColor = .systemGray3
        }
    }

    private var hasRenderedWidgets = false

    private func renderPreviewWidgets() {
        guard !hasRenderedWidgets else { return }
        let canvasSize = canvasView.bounds.size
        guard canvasSize.width > 0 && canvasSize.height > 0 else { return }

        hasRenderedWidgets = true

        let templateCanvasSize: CGSize
        if let tcs = template.canvasSize {
            templateCanvasSize = CGSize(width: tcs.width, height: tcs.height)
        } else {
            templateCanvasSize = CGSize(width: 414, height: 700)
        }

        for item in template.items {
            let frame = TemplateManager.absoluteFrame(from: item, canvasSize: canvasSize, templateCanvasSize: templateCanvasSize)
            if let widget = widgetFactory(item, frame) {
                widget.isUserInteractionEnabled = false
                canvasView.addSubview(widget)
            }
        }
    }

    private func createWidgetRow(for item: WidgetItem) -> UIView {
        let container = UIView()

        let iconImageView = UIImageView(image: UIImage(systemName: item.type.iconName))
        iconImageView.tintColor = ColorSystem.primaryGreen
        iconImageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = item.type.displayName
        label.font = .systemFont(ofSize: 14)
        label.textColor = ColorSystem.mainText

        container.addSubview(iconImageView)
        container.addSubview(label)

        iconImageView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.centerY.equalToSuperview()
        }

        container.snp.makeConstraints { make in
            make.height.equalTo(32)
        }

        return container
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func applyTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onApply()
        }
    }
}
