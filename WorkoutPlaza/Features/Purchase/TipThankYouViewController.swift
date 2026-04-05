//
//  TipThankYouViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/5/26.
//

import UIKit
import SnapKit

final class TipThankYouViewController: UIViewController {

    // MARK: - Tier

    enum Tier {
        case small   // Recovery Drink
        case medium  // Liquid Chalk
        case large   // New Laces

        var emoji: String {
            switch self {
            case .small:  return "☕"
            case .medium: return "🧴"
            case .large:  return "👟"
            }
        }

        var productName: String {
            switch self {
            case .small:  return NSLocalizedString("tip.product.small", comment: "")
            case .medium: return NSLocalizedString("tip.product.medium", comment: "")
            case .large:  return NSLocalizedString("tip.product.large", comment: "")
            }
        }

        var thanksTitle: String {
            switch self {
            case .small:  return NSLocalizedString("tip.thanks.small.title", comment: "")
            case .medium: return NSLocalizedString("tip.thanks.medium.title", comment: "")
            case .large:  return NSLocalizedString("tip.thanks.large.title", comment: "")
            }
        }

        var thanksMessage: String {
            switch self {
            case .small:  return NSLocalizedString("tip.thanks.small.message", comment: "")
            case .medium: return NSLocalizedString("tip.thanks.medium.message", comment: "")
            case .large:  return NSLocalizedString("tip.thanks.large.message", comment: "")
            }
        }

        /// 파티클 컬러 팔레트
        var particleColors: [UIColor] {
            switch self {
            case .small:
                return [.systemOrange, .systemYellow, UIColor(white: 0.9, alpha: 1)]
            case .medium:
                return [UIColor(white: 0.95, alpha: 1), UIColor(white: 0.85, alpha: 1), .systemGray4]
            case .large:
                return [ColorSystem.primaryBlue, ColorSystem.primaryGreen, .systemYellow, .systemPink, .white]
            }
        }

        var particleCount: Int {
            switch self {
            case .small:  return 40
            case .medium: return 80
            case .large:  return 180
            }
        }
    }

    // MARK: - Properties

    let tier: Tier
    var onDismiss: (() -> Void)?

    // MARK: - UI

    private let emojiLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 80)
        lbl.textAlignment = .center
        return lbl
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 24, weight: .bold)
        lbl.textAlignment = .center
        lbl.textColor = .white
        lbl.numberOfLines = 0
        return lbl
    }()

    private let messageLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 15)
        lbl.textAlignment = .center
        lbl.textColor = UIColor.white.withAlphaComponent(0.85)
        lbl.numberOfLines = 0
        return lbl
    }()

    private let supporterBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        v.isHidden = true
        return v
    }()

    private let supporterLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "🏆 " + NSLocalizedString("tip.supporter.badge", comment: "")
        lbl.font = .systemFont(ofSize: 14, weight: .semibold)
        lbl.textColor = .white
        lbl.textAlignment = .center
        return lbl
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("common.close", comment: ""), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        return btn
    }()

    // MARK: - Init

    init(tier: Tier) {
        self.tier = tier
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupLayout()
        populate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
        spawnParticles()
        if tier == .large { showSupporterBadge() }
    }

    // MARK: - Setup

    private func setupBackground() {
        let gradient = CAGradientLayer()
        gradient.colors = [ColorSystem.primaryBlue.cgColor, ColorSystem.primaryGreen.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [emojiLabel, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center

        supporterBadge.addSubview(supporterLabel)
        supporterLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }

        view.addSubview(stack)
        view.addSubview(supporterBadge)
        view.addSubview(closeButton)

        stack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        supporterBadge.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(stack.snp.bottom).offset(24)
        }

        closeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-32)
            make.width.equalTo(160)
            make.height.equalTo(48)
        }

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // Initial states for animation
        stack.alpha = 0
        stack.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        closeButton.alpha = 0
    }

    private func populate() {
        emojiLabel.text     = tier.emoji
        titleLabel.text     = tier.thanksTitle
        messageLabel.text   = tier.thanksMessage
    }

    // MARK: - Animations

    private func animateIn() {
        let contentViews: [UIView] = [
            view.subviews.compactMap { $0 as? UIStackView }.first,
            closeButton
        ].compactMap { $0 }

        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5) {
            contentViews.forEach { v in
                v.alpha = 1
                v.transform = .identity
            }
        }
    }

    private func showSupporterBadge() {
        supporterBadge.isHidden = false
        supporterBadge.alpha = 0
        supporterBadge.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        UIView.animate(withDuration: 0.6, delay: 0.8, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            self.supporterBadge.alpha = 1
            self.supporterBadge.transform = .identity
        }
    }

    // MARK: - Particle System

    private func spawnParticles() {
        let colors = tier.particleColors
        let count  = tier.particleCount

        for i in 0..<count {
            let delay = Double(i) * 0.015
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.addParticle(colors: colors)
            }
        }
    }

    private func addParticle(colors: [UIColor]) {
        let size   = CGFloat.random(in: 6...14)
        let startX = CGFloat.random(in: 0...view.bounds.width)
        let shapes: [ParticleShape] = [.circle, .rect, .triangle]
        let shape  = shapes.randomElement() ?? .circle

        let particle = makeParticleView(size: size, color: colors.randomElement() ?? .white, shape: shape)
        particle.center = CGPoint(x: startX, y: -size)
        view.addSubview(particle)

        let endY    = view.bounds.height + size
        let endX    = startX + CGFloat.random(in: -80...80)
        let duration = Double.random(in: 1.2...2.5)
        let rotation = CGFloat.random(in: -CGFloat.pi * 2...CGFloat.pi * 2)

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn]) {
            particle.center = CGPoint(x: endX, y: endY)
            particle.transform = CGAffineTransform(rotationAngle: rotation).scaledBy(x: 0.4, y: 0.4)
            particle.alpha = 0
        } completion: { _ in
            particle.removeFromSuperview()
        }
    }

    private enum ParticleShape { case circle, rect, triangle }

    private func makeParticleView(size: CGFloat, color: UIColor, shape: ParticleShape) -> UIView {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        v.backgroundColor = color

        switch shape {
        case .circle:
            v.layer.cornerRadius = size / 2
        case .rect:
            v.layer.cornerRadius = 2
        case .triangle:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: size / 2, y: 0))
            path.addLine(to: CGPoint(x: size, y: size))
            path.addLine(to: CGPoint(x: 0, y: size))
            path.close()

            let mask = CAShapeLayer()
            mask.path = path.cgPath
            v.layer.mask = mask
        }

        return v
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }
}
