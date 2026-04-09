//
//  WPDesignSystem.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/9/26.
//

import UIKit
import SnapKit

enum WPDesign {
    enum Spacing {
        static let xxxs: CGFloat = 4
        static let xxs: CGFloat = 8
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let pill: CGFloat = 999
    }

    enum Size {
        static let buttonHeight: CGFloat = 56
        static let segmentedHeight: CGFloat = 36
        static let iconBadge: CGFloat = 40
    }

    static func applyScreenBackground(to view: UIView) {
        view.backgroundColor = ColorSystem.background
        AppChrome.installAmbientBackground(in: view)
    }

    static func makeLabel(style: WPLabelStyle, text: String? = nil, color: UIColor? = nil, lines: Int = 1) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = style.font
        label.textColor = color ?? style.color
        label.numberOfLines = lines
        return label
    }
}

enum WPLabelStyle {
    case displayLarge
    case display
    case title
    case body
    case bodyStrong
    case caption
    case eyebrow
    case metric
    case metricSmall

    var font: UIFont {
        switch self {
        case .displayLarge:
            return AppFont.display(30)
        case .display:
            return AppFont.display(24)
        case .title:
            return AppFont.title(16)
        case .body:
            return AppFont.body(14)
        case .bodyStrong:
            return AppFont.bodySemiBold(14)
        case .caption:
            return AppFont.body(12)
        case .eyebrow:
            return AppFont.micro(12)
        case .metric:
            return AppFont.display(30)
        case .metricSmall:
            return AppFont.display(24)
        }
    }

    var color: UIColor {
        switch self {
        case .eyebrow:
            return ColorSystem.primaryBlue
        case .caption, .body:
            return ColorSystem.subText
        default:
            return ColorSystem.mainText
        }
    }
}

enum WPSurfaceStyle {
    case card
    case muted
    case floating
}

enum WPSurface {
    static func apply(to view: UIView, style: WPSurfaceStyle = .card, cornerRadius: CGFloat = WPDesign.Radius.lg) {
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSystem.divider.cgColor

        switch style {
        case .card:
            view.backgroundColor = ColorSystem.frostedFill
            view.layer.applyCardShadow()
        case .muted:
            view.backgroundColor = ColorSystem.cardBackgroundHighlight
            view.layer.shadowOpacity = 0
        case .floating:
            view.backgroundColor = UIColor.white.withAlphaComponent(0.92)
            view.layer.applyCardShadow()
        }
    }
}

final class WPPrimaryButton: UIButton {
    private let cornerRadiusValue: CGFloat

    init(title: String, cornerRadius: CGFloat = 28) {
        self.cornerRadiusValue = cornerRadius
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        AppChrome.stylePrimaryButton(self, cornerRadius: cornerRadius)
        titleLabel?.font = AppFont.bodyBold(16)
        snp.makeConstraints { make in
            make.height.equalTo(WPDesign.Size.buttonHeight)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        AppChrome.applyPrimaryGradient(to: self, cornerRadius: cornerRadiusValue)
    }
}

final class WPSectionHeaderView: UIView {
    let titleLabel = WPDesign.makeLabel(style: .display)
    let subtitleLabel = WPDesign.makeLabel(style: .body)
    let trailingContainerView = UIView()

    init(title: String, subtitle: String? = nil) {
        super.init(frame: .zero)

        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading

        addSubview(textStack)
        addSubview(trailingContainerView)

        textStack.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(trailingContainerView.snp.leading).offset(-12)
        }

        trailingContainerView.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTrailingView(_ view: UIView?) {
        trailingContainerView.subviews.forEach { $0.removeFromSuperview() }
        guard let view else { return }
        trailingContainerView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

final class WPBadgeView: UIView {
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()

    init(icon: UIImage?, tintColor: UIColor, backgroundColor: UIColor) {
        super.init(frame: .zero)

        iconContainer.backgroundColor = backgroundColor
        iconContainer.layer.cornerRadius = WPDesign.Size.iconBadge / 2
        iconImageView.image = icon
        iconImageView.tintColor = tintColor
        iconImageView.contentMode = .scaleAspectFit

        addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)

        iconContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(WPDesign.Size.iconBadge)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
