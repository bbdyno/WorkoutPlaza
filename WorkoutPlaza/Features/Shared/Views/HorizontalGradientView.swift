//
//  HorizontalGradientView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/3/26.
//

import UIKit

/// A reusable view that displays a horizontal gradient overlay
class HorizontalGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    // MARK: - Properties

    /// The gradient colors (default: white transparent to white opaque)
    var colors: [UIColor] = [
        UIColor.white.withAlphaComponent(1.0),
        UIColor.white.withAlphaComponent(0.0)
    ] {
        didSet {
            updateGradient()
        }
    }

    /// The gradient locations (default: [0.6, 1.0])
    var locations: [CGFloat] = [0.6, 1.0] {
        didSet {
            updateGradient()
        }
    }

    /// The start point of the gradient (default: left center)
    var startPoint: CGPoint = CGPoint(x: 0.0, y: 0.5) {
        didSet {
            gradientLayer.startPoint = startPoint
        }
    }

    /// The end point of the gradient (default: right center)
    var endPoint: CGPoint = CGPoint(x: 1.0, y: 0.5) {
        didSet {
            gradientLayer.endPoint = endPoint
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    // MARK: - Setup

    private func setupGradient() {
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        updateGradient()
        layer.addSublayer(gradientLayer)
    }

    private func updateGradient() {
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.locations = locations.map { NSNumber(value: Double($0)) }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
