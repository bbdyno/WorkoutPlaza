//
//  BaseWorkoutDetailViewController+CanvasGuides.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/10/26.
//

import UIKit
import SnapKit

extension BaseWorkoutDetailViewController {

    func constrainFrameToCanvas(_ frame: CGRect, canvasSize: CGSize, margin: CGFloat) -> CGRect {
        var newFrame = frame
        
        // Horizontal constraints
        if newFrame.minX < margin {
            newFrame.origin.x = margin
        } else if newFrame.maxX > canvasSize.width - margin {
            newFrame.origin.x = canvasSize.width - margin - newFrame.width
        }
        
        // Vertical constraints
        if newFrame.minY < margin {
            newFrame.origin.y = margin
        } else if newFrame.maxY > canvasSize.height - margin {
            newFrame.origin.y = canvasSize.height - margin - newFrame.height
        }
        
        return newFrame
    }

    func updateCanvasSize() {
        // Skip if view is not laid out yet
        guard view.bounds.width > 0 && view.bounds.height > 0 else { return }

        // Calculate canvas size based on available space and aspect ratio
        let availableWidth = view.bounds.width - 40 // 20pt padding on each side
        let maxHeight = view.bounds.height - 300 // Account for navigation, controls, toolbar, and padding

        let targetRatio = currentAspectRatio.ratio
        var canvasWidth: CGFloat
        var canvasHeight: CGFloat

        // Calculate size that fits within available space while maintaining ratio
        canvasWidth = availableWidth
        canvasHeight = canvasWidth * targetRatio

        if canvasHeight > maxHeight {
            canvasHeight = maxHeight
            canvasWidth = canvasHeight / targetRatio
        }

        // Ensure minimum size
        canvasWidth = max(canvasWidth, 200)
        canvasHeight = max(canvasHeight, 200)

        let newCanvasSize = CGSize(width: canvasWidth, height: canvasHeight)

        // Scale existing widgets if canvas size changed
        if previousCanvasSize.width > 0 && previousCanvasSize.height > 0 && previousCanvasSize != newCanvasSize {
            let scaleX = newCanvasSize.width / previousCanvasSize.width
            let scaleY = newCanvasSize.height / previousCanvasSize.height
            // Use area-preserving uniform scale for aspect-ratio-locked widgets (reversible)
            let uniformScale = sqrt(scaleX * scaleY)

            WPLog.debug("Scaling widgets: \(scaleX) x \(scaleY), uniform: \(uniformScale)")

            // Scale individual widgets
            for widget in widgets {
                // Keep widgets aspect-ratio stable while the canvas itself changes aspect ratio.
                let oldCenter = CGPoint(x: widget.frame.midX, y: widget.frame.midY)
                let newCenter = CGPoint(
                    x: oldCenter.x * scaleX,
                    y: oldCenter.y * scaleY
                )

                let newWidth = widget.frame.width * uniformScale
                let newHeight = widget.frame.height * uniformScale
                let unconstrainedFrame = CGRect(
                    x: newCenter.x - (newWidth / 2),
                    y: newCenter.y - (newHeight / 2),
                    width: newWidth,
                    height: newHeight
                )
                let newFrame = constrainFrameToCanvas(
                    unconstrainedFrame,
                    canvasSize: newCanvasSize,
                    margin: 0
                )

                widget.frame = newFrame

                // Re-baseline stat widget fonts to the scaled frame.
                // This avoids compounded down-scaling when restoring older saved cards.
                if let statWidget = widget as? BaseStatWidget {
                    statWidget.initialSize = newFrame.size
                    statWidget.updateFonts()
                    statWidget.setNeedsLayout()
                    statWidget.layoutIfNeeded()
                }

                // Redraw non-text widgets after frame update.
                if let routeMap = widget as? RouteMapView {
                    routeMap.setNeedsLayout()
                    routeMap.layoutIfNeeded()
                }
            }
        }

        // Update constraints
        canvasWidthConstraint?.update(offset: canvasWidth)
        canvasHeightConstraint?.update(offset: canvasHeight)

        // Update background image frame if needed
        if let transform = backgroundTransform {
            applyBackgroundTransform(transform)
        } else if backgroundImageView.image != nil, backgroundImageView.frame == .zero {
            // Initial frame if no transform set yet
            backgroundImageView.frame = CGRect(origin: .zero, size: newCanvasSize)
        }

        // Store current size for next comparison
        previousCanvasSize = newCanvasSize

        WPLog.debug("Canvas size updated: \(canvasWidth) x \(canvasHeight) (ratio: \(currentAspectRatio.displayName))")
    }
    
    func applyBackgroundTransform(_ transform: BackgroundTransform) {
        guard let image = backgroundImageView.image else { return }

        // Reset transform first to ensure frame calculations are correct
        backgroundImageView.transform = .identity
        
        let canvasSize = contentView.bounds.size
        let imageSize = image.size

        // Calculate base scale to fill canvas (Aspect Fill logic)
        let widthRatio = canvasSize.width / imageSize.width
        let heightRatio = canvasSize.height / imageSize.height
        let baseScale = max(widthRatio, heightRatio)

        // Apply user's zoom on top of base scale
        let finalScale = baseScale * transform.scale
        
        // Calculate the final size of the image
        let scaledWidth = imageSize.width * finalScale
        let scaledHeight = imageSize.height * finalScale
        
        // Calculate position
        let x = -transform.offset.x
        let y = -transform.offset.y
        
        // Apply frame
        backgroundImageView.frame = CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
        
        WPLog.debug("Applied Background Frame: \(backgroundImageView.frame)")
    }
    
    
    // MARK: - Notifications
    @objc func handleWidgetDidMove(_ notification: Notification) {
        hasUnsavedChanges = true

        guard let movedView = (notification.object as? UIView) ?? (selectionManager.currentlySelectedItem as UIView?),
              movedView.superview === contentView else { return }

        let phaseRaw = notification.userInfo?[WidgetMoveNotificationUserInfoKey.phase] as? String
        let phase = WidgetMovePhase(rawValue: phaseRaw ?? WidgetMovePhase.ended.rawValue) ?? .ended
        applyCenterStickySnap(to: movedView, phase: phase)
    }

    private func applyCenterStickySnap(to movedView: UIView, phase: WidgetMovePhase) {
        let canvasCenter = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
        var snappedCenter = movedView.center

        let shouldSnapToVertical = abs(movedView.center.x - canvasCenter.x) <= Constants.centerSnapThreshold
        let shouldSnapToHorizontal = abs(movedView.center.y - canvasCenter.y) <= Constants.centerSnapThreshold

        if shouldSnapToVertical {
            snappedCenter.x = canvasCenter.x
        }

        if shouldSnapToHorizontal {
            snappedCenter.y = canvasCenter.y
        }

        if snappedCenter != movedView.center {
            movedView.center = snappedCenter

            if let selectable = movedView as? Selectable, selectable.isSelected {
                selectable.positionResizeHandles()
            }
        }

        updateCenterGuides(
            showVertical: shouldSnapToVertical,
            showHorizontal: shouldSnapToHorizontal,
            phase: phase
        )
    }

    private func updateCenterGuides(showVertical: Bool, showHorizontal: Bool, phase: WidgetMovePhase) {
        centerGuideHideWorkItem?.cancel()
        centerGuideHideWorkItem = nil

        setCenterGuide(verticalCenterGuideView, visible: showVertical, animated: true)
        setCenterGuide(horizontalCenterGuideView, visible: showHorizontal, animated: true)

        guard phase == .ended else { return }

        if showVertical || showHorizontal {
            scheduleCenterGuideHide(after: Constants.centerGuideDisplayDuration)
        }
    }

    private func scheduleCenterGuideHide(after delay: TimeInterval) {
        centerGuideHideWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.hideCenterGuides(animated: true)
        }

        centerGuideHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func hideCenterGuides(animated: Bool) {
        setCenterGuide(verticalCenterGuideView, visible: false, animated: animated)
        setCenterGuide(horizontalCenterGuideView, visible: false, animated: animated)
    }

    private func setCenterGuide(_ guideView: UIView, visible: Bool, animated: Bool) {
        if visible && !guideView.isHidden && guideView.alpha >= 0.99 {
            return
        }

        if !visible && guideView.isHidden {
            return
        }

        if visible {
            contentView.bringSubviewToFront(guideView)
            if guideView.isHidden {
                guideView.alpha = 0
                guideView.isHidden = false
            }
        }

        let animations = {
            guideView.alpha = visible ? 1 : 0
        }

        let completion: (Bool) -> Void = { _ in
            if !visible {
                guideView.isHidden = true
            }
        }

        if animated {
            UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }

}
