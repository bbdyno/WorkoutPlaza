//
//  GymLogoWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/30/26.
//

import UIKit
import SnapKit

class GymLogoWidget: UIView, Selectable {
    
    // MARK: - Selectable Protocol
    var isSelected: Bool = false
    var currentColor: UIColor = .white { // Default to white as requested
        didSet {
            logoImageView.tintColor = currentColor
        }
    }
    var currentFontStyle: FontStyle = .system // Not used for logo but required by protocol
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?
    
    // Scaling
    var initialSize: CGSize = .zero
    
    // UI
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(logoImageView)
        
        logoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinch)
        
        isUserInteractionEnabled = true
    }
    
    func configure(with gym: ClimbingGym) {
        ClimbingGymLogoManager.shared.loadLogo(for: gym, asTemplate: true) { [weak self] image in
            self?.logoImageView.image = image
        }
    }
    
    // MARK: - Actions
    @objc private func handleTap() {
        selectionDelegate?.itemWasSelected(self)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view, let superview = view.superview else { return }
        if gesture.state == .began {
            if !isSelected { selectionDelegate?.itemWasSelected(self) }
        }
        
        let translation = gesture.translation(in: superview)
        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        gesture.setTranslation(.zero, in: superview)
        
        if isSelected && (gesture.state == .changed || gesture.state == .ended) {
            positionResizeHandles()
            NotificationCenter.default.post(name: .widgetDidMove, object: nil)
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        if gesture.state == .began || gesture.state == .changed {
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
            if isSelected { positionResizeHandles() }
        }
    }
    
    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        currentColor = color
    }
    
    func applyFont(_ fontStyle: FontStyle) {}
    
    func updateColors() {
        logoImageView.tintColor = currentColor
    }
    
    func updateFonts() {
        // Logo doesn't use font, but we update handles if needed
    }
    
    func updateFontsWithScale(_ scale: CGFloat) {}
    
    // MARK: - Hit Test
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for handle in resizeHandles {
            let handlePoint = convert(point, to: handle)
            if handle.point(inside: handlePoint, with: event) { return handle }
        }
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isSelected {
            updateSelectionBorder()
        }
    }
}
