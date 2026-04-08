//
//  ToastView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/7/26.
//

import UIKit
import SnapKit

final class ToastView: UIView {

    enum Style {
        case success
        case error
        case info
    }

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodySemiBold(14)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    init(message: String, style: Style = .info) {
        super.init(frame: .zero)
        setupUI(message: message, style: style)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(message: String, style: Style) {
        // 블러 배경
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.layer.cornerRadius = 16
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        addSubview(blur)
        blur.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 반투명 오버레이
        let overlay = UIView()
        overlay.backgroundColor = overlayColor(for: style)
        overlay.layer.cornerRadius = 16
        overlay.layer.cornerCurve = .continuous
        overlay.clipsToBounds = true
        addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 아이콘
        iconView.image = icon(for: style)
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        // 메시지
        messageLabel.text = message
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(48)
        }
    }

    private func icon(for style: Style) -> UIImage? {
        switch style {
        case .success: return UIImage(named: "icon.check.circle.fill")
        case .error: return UIImage(named: "icon.x.circle.fill")
        case .info: return UIImage(named: "icon.check")
        }
    }

    private func overlayColor(for style: Style) -> UIColor {
        switch style {
        case .success: return ColorSystem.primaryGreen.withAlphaComponent(0.18)
        case .error: return ColorSystem.error.withAlphaComponent(0.18)
        case .info: return UIColor.white.withAlphaComponent(0.05)
        }
    }

    // MARK: - Present

    static func show(in view: UIView, message: String, style: Style = .info, duration: TimeInterval = 2.0) {
        let toast = ToastView(message: message, style: style)
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: -20)
        view.addSubview(toast)

        toast.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            toast.alpha = 1
            toast.transform = .identity
        }

        UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseIn) {
            toast.alpha = 0
            toast.transform = CGAffineTransform(translationX: 0, y: -20)
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }
}
