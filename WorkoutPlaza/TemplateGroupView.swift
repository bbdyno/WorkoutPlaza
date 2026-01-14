//
//  TemplateGroupView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

class TemplateGroupView: UIView, Selectable {

    // MARK: - Selectable Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .systemBlue
    var currentFontStyle: FontStyle = .system  // Not directly used, but required by protocol
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?
    var initialSize: CGSize = .zero

    // MARK: - Group Properties
    private(set) var groupedItems: [UIView] = []
    private var originalItemFrames: [UIView: CGRect] = [:]
    private var originalGroupFrame: CGRect = .zero

    private let checkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.tintColor = .systemGreen
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
        return button
    }()

    weak var groupDelegate: TemplateGroupDelegate?

    // MARK: - Initialization
    init(items: [UIView], frame: CGRect) {
        super.init(frame: frame)
        self.groupedItems = items
        self.originalGroupFrame = frame
        self.initialSize = frame.size

        setupView()
        addItemsToGroup()
        setupCheckButton()
        setupPanGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear

        // Add semi-transparent overlay to show group boundary
        let overlayLayer = CAShapeLayer()
        overlayLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.05).cgColor
        overlayLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        overlayLayer.lineWidth = 2
        overlayLayer.lineDashPattern = [8, 4]
        layer.insertSublayer(overlayLayer, at: 0)

        // Update path
        DispatchQueue.main.async {
            overlayLayer.path = UIBezierPath(rect: self.bounds).cgPath
        }
    }

    private func addItemsToGroup() {
        for item in groupedItems {
            // Store original frame (in contentView coordinates)
            let originalFrame = item.frame
            originalItemFrames[item] = originalFrame

            // Convert to group coordinate system (relative to group's origin)
            let frameInGroup = CGRect(
                x: originalFrame.origin.x - self.frame.origin.x,
                y: originalFrame.origin.y - self.frame.origin.y,
                width: originalFrame.width,
                height: originalFrame.height
            )

            // Add to group
            addSubview(item)
            item.frame = frameInGroup
        }
    }

    private func setupCheckButton() {
        addSubview(checkButton)
        checkButton.frame = CGRect(x: bounds.width - 50, y: -50, width: 40, height: 40)
        checkButton.addTarget(self, action: #selector(checkButtonTapped), for: .touchUpInside)
    }

    private func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
    }

    // MARK: - Actions
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }

        let translation = gesture.translation(in: superview)

        switch gesture.state {
        case .changed:
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)

        case .ended, .cancelled:
            // Optionally add boundary constraints here
            break

        default:
            break
        }
    }
    @objc private func checkButtonTapped() {
        groupDelegate?.templateGroupDidConfirm(self)
    }

    // MARK: - Group Resize
    override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size {
                updateItemPositionsAndSizes()
            }

            // Update check button position
            checkButton.frame.origin = CGPoint(x: bounds.width - 50, y: -50)
        }
    }

    private func updateItemPositionsAndSizes() {
        guard originalGroupFrame.width > 0 && originalGroupFrame.height > 0 else { return }

        let scaleX = bounds.width / originalGroupFrame.width
        let scaleY = bounds.height / originalGroupFrame.height

        // Update each item's position and size proportionally
        for (item, originalFrame) in originalItemFrames {
            let newX = originalFrame.origin.x * scaleX
            let newY = originalFrame.origin.y * scaleY
            let newWidth = originalFrame.width * scaleX
            let newHeight = originalFrame.height * scaleY

            item.frame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)

            // Update fonts for text widgets
            if let statWidget = item as? BaseStatWidget {
                statWidget.initialSize = CGSize(width: newWidth, height: newHeight)
                statWidget.updateFonts()  // Directly call updateFonts
                statWidget.layoutSubviews()
            }

            // Redraw route map
            if let routeMap = item as? RouteMapView {
                routeMap.initialSize = CGSize(width: newWidth, height: newHeight)
                routeMap.layoutSubviews()
            }
        }
    }

    // MARK: - Ungroup
    func ungroupItems(to targetView: UIView) -> [UIView] {
        var items: [UIView] = []

        for item in groupedItems {
            // Convert frame back to target view coordinate system
            let frameInTargetView = convert(item.frame, to: targetView)
            item.removeFromSuperview()
            targetView.addSubview(item)
            item.frame = frameInTargetView

            items.append(item)
        }

        return items
    }

    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        // Groups don't change color
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        // Groups don't use fonts, so this is a no-op
    }

    // MARK: - Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Check check button first
        if !checkButton.isHidden {
            let buttonPoint = convert(point, to: checkButton)
            if checkButton.point(inside: buttonPoint, with: event) {
                return checkButton
            }
        }

        // Check resize handles
        for handle in resizeHandles {
            let handlePoint = convert(point, to: handle)
            if handle.point(inside: handlePoint, with: event) {
                return handle
            }
        }

        // Otherwise return self for dragging
        if bounds.contains(point) {
            return self
        }

        return nil
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        if isSelected {
            positionResizeHandles()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TemplateGroupView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Allow touch if it's not on the check button or resize handles
        if touch.view == checkButton {
            return false
        }

        for handle in resizeHandles {
            if touch.view == handle {
                return false
            }
        }

        return true
    }
}

// MARK: - Template Group Delegate
protocol TemplateGroupDelegate: AnyObject {
    func templateGroupDidConfirm(_ group: TemplateGroupView)
}
