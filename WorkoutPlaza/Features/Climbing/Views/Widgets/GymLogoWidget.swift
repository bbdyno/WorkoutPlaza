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
    private var initialCenter: CGPoint = .zero
    
    // UI
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 4
        return sv
    }()

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()
    
    private let branchLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
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
        addSubview(stackView)
        
        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(branchLabel)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Logo expands to fill available space, label takes intrinsic size
        logoImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        logoImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        branchLabel.setContentHuggingPriority(.required, for: .vertical)
        branchLabel.setContentCompressionResistancePriority(.required, for: .vertical)
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
            guard let self = self else { return }
            self.logoImageView.image = image
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }

        if let branch = gym.metadata?.branch, !branch.isEmpty {
            branchLabel.text = branch
            branchLabel.isHidden = false
        } else {
            branchLabel.text = nil
            branchLabel.isHidden = true
        }
    }
    
    // MARK: - Actions
    @objc private func handleTap() {
        selectionDelegate?.itemWasSelected(self)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view, let superview = view.superview else { return }
        
        switch gesture.state {
        case .began:
            initialCenter = view.center
            if !isSelected { selectionDelegate?.itemWasSelected(self) }
            
        case .changed:
            let translation = gesture.translation(in: superview)
            let proposedCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )
            
            // Snapping Logic
            let snapStep: CGFloat = 5.0
            let width = view.frame.width
            let height = view.frame.height
            
            let proposedOriginX = proposedCenter.x - width / 2
            let proposedOriginY = proposedCenter.y - height / 2
            
            let snappedOriginX = round(proposedOriginX / snapStep) * snapStep
            let snappedOriginY = round(proposedOriginY / snapStep) * snapStep
            
            let snappedCenter = CGPoint(
                x: snappedOriginX + width / 2,
                y: snappedOriginY + height / 2
            )
            
            view.center = snappedCenter
            
            if isSelected {
                positionResizeHandles()
                NotificationCenter.default.post(name: .widgetDidMove, object: nil)
            }
            
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        switch gesture.state {
        case .began:
            if initialSize == .zero {
                initialSize = view.frame.size
            }
            
        case .changed:
            let scale = gesture.scale
            let currentWidth = view.frame.width
            
            // Calculate new width first
            let newWidth = currentWidth * scale
            
            // Determine aspect ratio from current frame (or initial if available/preferred)
            // Using current frame to respect current ratio
            let aspectRatio = view.frame.width / view.frame.height
            
            let minWidth: CGFloat = 60
            let maxWidth: CGFloat = 400
            
            let clampedWidth = max(minWidth, min(maxWidth, newWidth))
            let clampedHeight = clampedWidth / aspectRatio  // Maintain aspect ratio
            
            let center = view.center
            view.frame.size = CGSize(width: clampedWidth, height: clampedHeight)
            view.center = center
            
            updateFontsWithScale(clampedWidth / max(initialSize.width, 1))
            gesture.scale = 1.0
            
            if isSelected { positionResizeHandles() }
            
        default:
            break
        }
    }
    
    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        currentColor = color
        updateColors()
    }
    
    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        updateFonts()
    }
    
    func updateColors() {
        logoImageView.tintColor = currentColor
        branchLabel.textColor = currentColor
    }
    
    func updateFonts() {
        branchLabel.font = currentFontStyle.font(size: branchLabel.font.pointSize)
    }
    
    func updateFontsWithScale(_ scale: CGFloat) {
         let newSize = 14 * scale
         branchLabel.font = currentFontStyle.font(size: newSize)
    }
    
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
