//
//  TextWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  TextWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Text Widget Delegate
protocol TextWidgetDelegate: AnyObject {
    func textWidgetDidRequestEdit(_ widget: TextWidget)
}

// MARK: - Text Widget (for custom text input)
class TextWidget: UIView, Selectable {

    // MARK: - Selectable Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .label {
        didSet {
            updateColors()
        }
    }
    var currentFontStyle: FontStyle = .system {
        didSet {
            updateFonts()
        }
    }
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?

    // Text widget specific delegate
    weak var textDelegate: TextWidgetDelegate?

    // Font scaling properties
    var initialSize: CGSize = .zero
    var baseFontSize: CGFloat = 20
    var isGroupManaged: Bool = false  // Prevents auto font scaling when inside a group

    // Movement properties
    private var initialCenter: CGPoint = .zero

    // MARK: - UI Components
    let textLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .label
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
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

        addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        // Set default text
        textLabel.text = "텍스트 입력"
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)

        // Single tap should wait for double tap to fail
        tapGesture.require(toFail: doubleTapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)

        isUserInteractionEnabled = true
    }

    func configure(text: String = "텍스트 입력") {
        textLabel.text = text
        initialSize = bounds.size
        updateFonts()
    }

    func updateText(_ text: String) {
        textLabel.text = text
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view, let superview = view.superview else { return }

        switch gesture.state {
        case .began:
            initialCenter = view.center
            // Select this widget immediately when drag starts
            if !isSelected {
                selectionDelegate?.itemWasSelected(self)
            }

        case .changed:
            let translation = gesture.translation(in: superview)

            let proposedCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )

            // Snap to 5pt grid
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
            }

        case .ended, .cancelled:
            NotificationCenter.default.post(name: .widgetDidMove, object: nil)

        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0

            // Update fonts based on transform scale
            updateFontsFromTransform()

            if isSelected {
                positionResizeHandles()
            }
        }
    }

    private func updateFontsFromTransform() {
        // Calculate scale from transform
        let scaleX = sqrt(transform.a * transform.a + transform.c * transform.c)
        let scaleY = sqrt(transform.b * transform.b + transform.d * transform.d)
        let averageScale = (scaleX + scaleY) / 2.0

        // Apply to font size
        let fontSize = baseFontSize * averageScale
        let clampedSize = min(max(fontSize, baseFontSize * 0.5), baseFontSize * 3.0)

        textLabel.font = currentFontStyle.font(size: clampedSize, weight: .bold)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // If already selected, open edit dialog
        if isSelected {
            textDelegate?.textWidgetDidRequestEdit(self)
        } else {
            // Otherwise, select the widget
            selectionDelegate?.itemWasSelected(self)
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        // Double tap also opens edit dialog
        textDelegate?.textWidgetDidRequestEdit(self)
    }

    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        currentColor = color
        updateColors()
    }

    func updateColors() {
        textLabel.textColor = currentColor
    }

    func updateFonts() {
        if initialSize == .zero {
            initialSize = bounds.size
        }

        let scaleFactor = calculateScaleFactor()
        let fontSize = baseFontSize * scaleFactor

        textLabel.font = currentFontStyle.font(size: fontSize, weight: .bold)

        print("🔤 Text widget font updated: style=\(currentFontStyle.displayName), size=\(fontSize)")
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        if initialSize == .zero {
            initialSize = bounds.size
        }
        updateFonts()
    }

    func calculateScaleFactor() -> CGFloat {
        guard initialSize != .zero else {
            initialSize = bounds.size
            return 1.0
        }

        let widthScale = bounds.width / initialSize.width
        let heightScale = bounds.height / initialSize.height
        let averageScale = (widthScale + heightScale) / 2.0

        return min(max(averageScale, 0.5), 3.0)
    }

    /// Update fonts with a specific scale factor (used by group resize)
    func updateFontsWithScale(_ scale: CGFloat) {
        let clampedScale = min(max(scale, 0.5), 3.0)
        let fontSize = baseFontSize * clampedScale
        textLabel.font = currentFontStyle.font(size: fontSize, weight: .bold)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // Don't auto-update fonts when managed by a group - group handles font scaling
        guard !isGroupManaged else {
            if isSelected {
                updateSelectionBorder()
            }
            return
        }

        // Always update fonts when size changes
        if !transform.isIdentity {
            // Transform-based scaling (pinch gesture)
            updateFontsFromTransform()
        } else if initialSize != .zero && bounds.size != .zero {
            // Frame-based scaling (resize handles)
            let scaleFactor = calculateScaleFactor()
            let fontSize = baseFontSize * scaleFactor
            let clampedSize = min(max(fontSize, baseFontSize * 0.5), baseFontSize * 3.0)

            textLabel.font = currentFontStyle.font(size: clampedSize, weight: .bold)
        }

        // Update selection border if selected
        if isSelected {
            updateSelectionBorder()
        }
    }

    // MARK: - Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Check if touch is on a resize handle first
        for handle in resizeHandles {
            let handlePoint = convert(point, to: handle)
            if handle.point(inside: handlePoint, with: event) {
                return handle
            }
        }

        return super.hitTest(point, with: event)
    }
}
