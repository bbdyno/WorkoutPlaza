//
//  CustomAlertViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/6/26.
//

import UIKit
import SnapKit

struct CustomAlertAction {
    let title: String
    let iconName: String?
    let style: Style
    let handler: (() -> Void)?

    enum Style { case primary, secondary, cancel }
}

final class CustomAlertViewController: UIViewController {

    private let alertTitle: String
    private let alertMessage: String
    private let iconName: String?
    private let actions: [CustomAlertAction]
    private let backgroundView = UIView()

    init(title: String, message: String, iconName: String? = nil, actions: [CustomAlertAction]) {
        self.alertTitle = title
        self.alertMessage = message
        self.iconName = iconName
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .clear
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let tapDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissAlert))
        backgroundView.addGestureRecognizer(tapDismiss)

        // 카드 컨테이너
        let card = UIView()
        card.backgroundColor = ColorSystem.cardBackground
        card.layer.cornerRadius = 24
        card.layer.cornerCurve = .continuous
        view.addSubview(card)

        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        card.addSubview(stack)

        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(28)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
        }

        // 아이콘
        if let iconName = iconName {
            let iconView = UIImageView()
            iconView.image = UIImage(named: iconName) ?? UIImage(systemName: iconName)
            iconView.tintColor = .white
            iconView.contentMode = .scaleAspectFit
            stack.addArrangedSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.width.height.equalTo(40)
            }
        }

        // 타이틀
        let titleLabel = UILabel()
        titleLabel.text = alertTitle
        titleLabel.font = AppFont.bodyBold(18)
        titleLabel.textColor = ColorSystem.mainText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        stack.addArrangedSubview(titleLabel)

        // 메시지
        let messageLabel = UILabel()
        messageLabel.text = alertMessage
        messageLabel.font = AppFont.body(14)
        messageLabel.textColor = ColorSystem.subText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        stack.addArrangedSubview(messageLabel)

        stack.setCustomSpacing(20, after: messageLabel)

        // 버튼들
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 10
        buttonStack.distribution = .fillEqually
        stack.addArrangedSubview(buttonStack)

        buttonStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }

        for action in actions {
            let button = UIButton(type: .system)
            button.layer.cornerRadius = 14
            button.layer.cornerCurve = .continuous
            button.titleLabel?.font = AppFont.bodySemiBold(15)

            var config = UIButton.Configuration.filled()
            config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)

            switch action.style {
            case .primary:
                config.baseBackgroundColor = ColorSystem.mainText
                config.baseForegroundColor = ColorSystem.background
            case .secondary:
                config.baseBackgroundColor = ColorSystem.cardBackgroundHighlight
                config.baseForegroundColor = ColorSystem.mainText
            case .cancel:
                config.baseBackgroundColor = .clear
                config.baseForegroundColor = ColorSystem.subText
            }

            if let iconName = action.iconName {
                config.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
                config.imagePadding = 8
                config.imagePlacement = .leading
                config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14)
            }

            config.title = action.title
            button.configuration = config

            let handler = action.handler
            button.addAction(UIAction { [weak self] _ in
                self?.dismiss(animated: true) {
                    handler?()
                }
            }, for: .touchUpInside)

            buttonStack.addArrangedSubview(button)
        }
    }

    @objc private func dismissAlert() {
        dismiss(animated: true)
    }
}
