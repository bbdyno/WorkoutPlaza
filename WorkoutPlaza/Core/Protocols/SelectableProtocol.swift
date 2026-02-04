//
//  SelectableProtocol.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

// MARK: - Selectable Protocol
protocol Selectable: UIView {
    var isSelected: Bool { get set }
    var currentColor: UIColor { get set }
    var currentFontStyle: FontStyle { get set }
    var itemIdentifier: String { get set }
    var resizeHandles: [ResizeHandleView] { get set }
    var selectionBorderLayer: CAShapeLayer? { get set }
    var rotationIndicatorLayer: CAShapeLayer? { get set }
    var selectionDelegate: SelectionDelegate? { get set }
    var initialSize: CGSize { get set }
    var minimumSize: CGFloat { get }
    var rotation: CGFloat { get set }
    var isRotating: Bool { get set }

    func showSelectionState()
    func hideSelectionState()
    func applyColor(_ color: UIColor)
    func applyFont(_ fontStyle: FontStyle)
    func showRotationIndicator()
    func hideRotationIndicator()
}

// MARK: - Selection Delegate
protocol SelectionDelegate: AnyObject {
    func itemWasSelected(_ item: Selectable)
    func itemWasDeselected(_ item: Selectable)
}

// MARK: - Default Implementation
extension Selectable {
    var minimumSize: CGFloat {
        return LayoutConstants.minimumWidgetSize
    }

    // Default storage for rotation (can be overridden by conforming types)
    var rotation: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.rotation) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.rotation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var isRotating: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isRotating) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isRotating, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func showSelectionState() {
        isSelected = true
        createSelectionBorder()
        createResizeHandles()
        positionResizeHandles()
        bringSubviewsToFront()
    }

    func hideSelectionState() {
        isSelected = false
        removeSelectionBorder()
        removeResizeHandles()
    }

    func createSelectionBorder() {
        guard selectionBorderLayer == nil else { return }

        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = ColorSystem.primaryBlue.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 2
        borderLayer.lineDashPattern = [6, 3]

        layer.insertSublayer(borderLayer, at: 0)
        selectionBorderLayer = borderLayer
    }

    func removeSelectionBorder() {
        selectionBorderLayer?.removeFromSuperlayer()
        selectionBorderLayer = nil
    }

    func createResizeHandles() {
        guard resizeHandles.isEmpty else { return }
        guard let superview = superview else { return }

        let positions: [ResizeHandlePosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight]

        for position in positions {
            let handle = ResizeHandleView(position: position)
            handle.parentView = self
            superview.addSubview(handle)
            resizeHandles.append(handle)
        }
    }

    func removeResizeHandles() {
        for handle in resizeHandles {
            handle.removeFromSuperview()
        }
        resizeHandles.removeAll()
    }

    func positionResizeHandles() {
        for handle in resizeHandles {
            switch handle.position {
            case .topLeft:
                handle.center = frame.origin
            case .topRight:
                handle.center = CGPoint(x: frame.maxX, y: frame.minY)
            case .bottomLeft:
                handle.center = CGPoint(x: frame.minX, y: frame.maxY)
            case .bottomRight:
                handle.center = CGPoint(x: frame.maxX, y: frame.maxY)
            }
        }

        // Update selection border
        updateSelectionBorder()
    }

    func updateSelectionBorder() {
        guard let borderLayer = selectionBorderLayer else { return }

        let borderPath = UIBezierPath(rect: bounds)
        borderLayer.path = borderPath.cgPath
        borderLayer.frame = bounds
    }

    func bringSubviewsToFront() {
        guard let superview = superview else { return }
        for handle in resizeHandles {
            superview.bringSubviewToFront(handle)
        }
    }

    func showRotationIndicator() {
        guard rotationIndicatorLayer == nil else { return }

        let indicatorLayer = CAShapeLayer()
        let radius = min(bounds.width, bounds.height) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let circlePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )

        indicatorLayer.path = circlePath.cgPath
        indicatorLayer.strokeColor = UIColor.systemBlue.cgColor
        indicatorLayer.fillColor = UIColor.clear.cgColor
        indicatorLayer.lineWidth = 2
        indicatorLayer.lineDashPattern = [4, 4]

        layer.addSublayer(indicatorLayer)
        rotationIndicatorLayer = indicatorLayer
    }

    func hideRotationIndicator() {
        rotationIndicatorLayer?.removeFromSuperlayer()
        rotationIndicatorLayer = nil
    }
}

// MARK: - Associated Keys
private struct AssociatedKeys {
    static var rotation: UInt8 = 0
    static var isRotating: UInt8 = 0
}

// MARK: - Resize Handle Position
enum ResizeHandlePosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}
