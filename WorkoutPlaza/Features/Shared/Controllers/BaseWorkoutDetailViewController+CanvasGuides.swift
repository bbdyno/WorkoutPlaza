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
        applyWidgetAlignmentSnap(to: movedView, phase: phase)
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
            // 점선 path 업데이트
            if let dash = guideView.layer.sublayers?.first(where: { $0.name == "dashLine" }) as? CAShapeLayer {
                let path = UIBezierPath()
                let bounds = guideView.bounds
                if bounds.width <= 2 { // 세로 가이드
                    path.move(to: CGPoint(x: 0.5, y: 0))
                    path.addLine(to: CGPoint(x: 0.5, y: bounds.height))
                } else { // 가로 가이드
                    path.move(to: CGPoint(x: 0, y: 0.5))
                    path.addLine(to: CGPoint(x: bounds.width, y: 0.5))
                }
                dash.path = path.cgPath
                dash.frame = bounds
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

    // MARK: - Widget-to-Widget Alignment Snap

    private static let alignSnapThreshold: CGFloat = 6

    var alignmentGuideViews: [UIView] {
        if let existing = _alignmentGuideViews { return existing }
        let color = Constants.alignGuideColor
        var views: [UIView] = []
        for _ in 0..<6 {
            let v = UIView()
            v.backgroundColor = .clear
            v.isHidden = true
            v.isUserInteractionEnabled = false
            let dash = CAShapeLayer()
            dash.strokeColor = color.cgColor
            dash.lineDashPattern = [3, 3]
            dash.lineWidth = 1
            dash.name = "alignDash"
            v.layer.addSublayer(dash)
            contentView.addSubview(v)
            views.append(v)
        }
        _alignmentGuideViews = views
        return views
    }

    var spacingLabels: [UIView] {
        if let existing = _spacingLabels { return existing }
        let color = Constants.alignGuideColor
        var views: [UIView] = []
        for _ in 0..<4 {
            // 'I' 형태 간격 표시 뷰 (양쪽 세리프 + 중앙선 + 라벨)
            let container = UIView()
            container.backgroundColor = .clear
            container.isHidden = true
            container.isUserInteractionEnabled = false

            let line = CAShapeLayer()
            line.strokeColor = color.cgColor
            line.lineDashPattern = [2, 2]
            line.lineWidth = 1
            line.name = "spacingLine"
            container.layer.addSublayer(line)

            let leftSerif = CAShapeLayer()
            leftSerif.strokeColor = color.cgColor
            leftSerif.lineWidth = 1
            leftSerif.name = "leftSerif"
            container.layer.addSublayer(leftSerif)

            let rightSerif = CAShapeLayer()
            rightSerif.strokeColor = color.cgColor
            rightSerif.lineWidth = 1
            rightSerif.name = "rightSerif"
            container.layer.addSublayer(rightSerif)

            let label = UILabel()
            label.font = AppFont.statRegular(8)
            label.textColor = color
            label.textAlignment = .center
            label.tag = 999
            container.addSubview(label)

            contentView.addSubview(container)
            views.append(container)
        }
        _spacingLabels = views
        return views
    }

    func applyWidgetAlignmentSnap(to movedView: UIView, phase: WidgetMovePhase) {
        let others = widgets.filter { $0 !== movedView && $0.superview === contentView }
        guard !others.isEmpty else {
            hideAlignmentGuides()
            hideSpacingLabels()
            return
        }

        let threshold = Self.alignSnapThreshold
        var snappedCenter = movedView.center
        var snapAppliedX = false
        var snapAppliedY = false

        struct GuideInfo {
            let isVertical: Bool
            let position: CGFloat
            let minExtent: CGFloat
            let maxExtent: CGFloat
        }
        var guides: [GuideInfo] = []

        // 스냅된 위치 기준으로 frame 계산
        let movedFrame = CGRect(
            x: snappedCenter.x - movedView.bounds.width / 2,
            y: snappedCenter.y - movedView.bounds.height / 2,
            width: movedView.bounds.width,
            height: movedView.bounds.height
        )

        for other in others {
            let of = other.frame

            // X축 정렬 (세로 가이드라인) — 아직 X 스냅 안 잡혔을 때만
            if !snapAppliedX {
                let xPairs: [(CGFloat, CGFloat)] = [
                    (movedFrame.minX, of.minX),
                    (movedFrame.midX, of.midX),
                    (movedFrame.maxX, of.maxX),
                ]
                for (moved, target) in xPairs {
                    if abs(moved - target) <= threshold {
                        snappedCenter.x += (target - moved)
                        snapAppliedX = true
                        let minY = min(movedFrame.minY, of.minY) - 4
                        let maxY = max(movedFrame.maxY, of.maxY) + 4
                        guides.append(GuideInfo(isVertical: true, position: target, minExtent: minY, maxExtent: maxY))
                        break
                    }
                }
            }

            // Y축 정렬 (가로 가이드라인) — 아직 Y 스냅 안 잡혔을 때만
            if !snapAppliedY {
                let yPairs: [(CGFloat, CGFloat)] = [
                    (movedFrame.minY, of.minY),
                    (movedFrame.midY, of.midY),
                    (movedFrame.maxY, of.maxY),
                ]
                for (moved, target) in yPairs {
                    if abs(moved - target) <= threshold {
                        snappedCenter.y += (target - moved)
                        snapAppliedY = true
                        let minX = min(movedFrame.minX, of.minX) - 4
                        let maxX = max(movedFrame.maxX, of.maxX) + 4
                        guides.append(GuideInfo(isVertical: false, position: target, minExtent: minX, maxExtent: maxX))
                        break
                    }
                }
            }
        }

        // 스냅 적용
        if snappedCenter != movedView.center {
            movedView.center = snappedCenter
            if let selectable = movedView as? Selectable, selectable.isSelected {
                selectable.positionResizeHandles()
            }
        }

        // 등간격 스냅
        applyEqualSpacingSnap(to: movedView, others: others, phase: phase)

        // 가이드라인 표시/숨김 (점선)
        let guideViews = alignmentGuideViews
        for (i, gv) in guideViews.enumerated() {
            if i < guides.count {
                let g = guides[i]
                if g.isVertical {
                    gv.frame = CGRect(x: g.position - 0.5, y: g.minExtent, width: 1, height: g.maxExtent - g.minExtent)
                } else {
                    gv.frame = CGRect(x: g.minExtent, y: g.position - 0.5, width: g.maxExtent - g.minExtent, height: 1)
                }
                // 점선 path 업데이트
                if let dash = gv.layer.sublayers?.first(where: { $0.name == "alignDash" }) as? CAShapeLayer {
                    let path = UIBezierPath()
                    let b = gv.bounds
                    if g.isVertical {
                        path.move(to: CGPoint(x: 0.5, y: 0))
                        path.addLine(to: CGPoint(x: 0.5, y: b.height))
                    } else {
                        path.move(to: CGPoint(x: 0, y: 0.5))
                        path.addLine(to: CGPoint(x: b.width, y: 0.5))
                    }
                    dash.path = path.cgPath
                    dash.frame = b
                }
                contentView.bringSubviewToFront(gv)
                gv.isHidden = false
                gv.alpha = 1
            } else {
                gv.alpha = 0
                gv.isHidden = true
            }
        }

        // 가이드/라벨 자동 숨김 스케줄
        scheduleAlignGuideHide()
    }

    // MARK: - Equal Spacing Snap

    private func applyEqualSpacingSnap(to movedView: UIView, others: [UIView], phase: WidgetMovePhase) {
        let threshold: CGFloat = 8
        let labels = spacingLabels
        var labelIndex = 0

        // === X축 등간격 ===
        labelIndex = checkEqualSpacing(
            movedView: movedView, others: others, threshold: threshold,
            labels: labels, labelIndex: labelIndex, axis: .horizontal
        )

        // === Y축 등간격 ===
        labelIndex = checkEqualSpacing(
            movedView: movedView, others: others, threshold: threshold,
            labels: labels, labelIndex: labelIndex, axis: .vertical
        )

        for i in labelIndex..<labels.count {
            labels[i].isHidden = true
        }
    }

    private enum SpacingAxis { case horizontal, vertical }

    private func checkEqualSpacing(
        movedView: UIView, others: [UIView], threshold: CGFloat,
        labels: [UIView], labelIndex: Int, axis: SpacingAxis
    ) -> Int {
        var idx = labelIndex
        let snapThreshold = LayoutConstants.snapStep + 1 // 그리드 단위 + 1pt 여유

        // 이동 위젯 포함 전체를 축 기준 정렬
        var allViews = others + [movedView]
        allViews.sort(by: {
            axis == .horizontal ? $0.frame.midX < $1.frame.midX : $0.frame.midY < $1.frame.midY
        })

        guard allViews.count >= 3,
              let movedIdx = allViews.firstIndex(where: { $0 === movedView }) else {
            return idx
        }

        let movedFrame = movedView.frame

        // Case 1: 양쪽에 위젯이 있을 때 — 좌우 gap 균등화
        if movedIdx > 0 && movedIdx < allViews.count - 1 {
            let left = allViews[movedIdx - 1].frame
            let right = allViews[movedIdx + 1].frame

            let leftGap = axis == .horizontal ? movedFrame.minX - left.maxX : movedFrame.minY - left.maxY
            let rightGap = axis == .horizontal ? right.minX - movedFrame.maxX : right.minY - movedFrame.maxY

            if leftGap > 0 && rightGap > 0 && abs(leftGap - rightGap) <= snapThreshold {
                let equalGap = (leftGap + rightGap) / 2
                var c = movedView.center
                if axis == .horizontal {
                    c.x = left.maxX + equalGap + movedFrame.width / 2
                } else {
                    c.y = left.maxY + equalGap + movedFrame.height / 2
                }
                movedView.center = c

                idx = showEqualSpacingLabels(
                    labels: labels, idx: idx, gap: equalGap, axis: axis,
                    leftEdge: axis == .horizontal ? left.maxX : left.maxY,
                    movedView: movedView,
                    rightEdge: axis == .horizontal ? right.minX : right.minY
                )

                if let selectable = movedView as? Selectable, selectable.isSelected {
                    selectable.positionResizeHandles()
                }
                return idx
            }
        }

        // Case 2: 맨 끝에 있을 때 — 다른 인접 쌍의 gap과 일치하는지 체크
        // 이동 위젯 제외한 다른 위젯들의 인접 gap 수집
        let othersSorted = others.sorted(by: {
            axis == .horizontal ? $0.frame.midX < $1.frame.midX : $0.frame.midY < $1.frame.midY
        })

        var referenceGaps: [CGFloat] = []
        for i in 0..<(othersSorted.count - 1) {
            let a = othersSorted[i].frame
            let b = othersSorted[i + 1].frame
            let gap = axis == .horizontal ? b.minX - a.maxX : b.minY - a.maxY
            if gap > 3 { referenceGaps.append(gap) }
        }

        guard !referenceGaps.isEmpty else { return idx }

        // 이동 위젯의 인접 gap과 참조 gap 비교
        if movedIdx > 0 {
            let neighbor = allViews[movedIdx - 1].frame
            let myGap = axis == .horizontal ? movedFrame.minX - neighbor.maxX : movedFrame.minY - neighbor.maxY

            for refGap in referenceGaps {
                if myGap > 0 && abs(myGap - refGap) <= snapThreshold {
                    var c = movedView.center
                    if axis == .horizontal {
                        c.x = neighbor.maxX + refGap + movedFrame.width / 2
                    } else {
                        c.y = neighbor.maxY + refGap + movedFrame.height / 2
                    }
                    movedView.center = c

                    if idx < labels.count {
                        if axis == .horizontal {
                            showSpacingLabel(labels[idx], gap: refGap,
                                             from: neighbor.maxX, to: movedView.frame.minX,
                                             midY: movedView.frame.midY)
                        } else {
                            showSpacingLabelVertical(labels[idx], gap: refGap,
                                                    from: neighbor.maxY, to: movedView.frame.minY,
                                                    midX: movedView.frame.midX)
                        }
                        idx += 1
                    }

                    if let selectable = movedView as? Selectable, selectable.isSelected {
                        selectable.positionResizeHandles()
                    }
                    return idx
                }
            }
        }

        if movedIdx < allViews.count - 1 {
            let neighbor = allViews[movedIdx + 1].frame
            let myGap = axis == .horizontal ? neighbor.minX - movedFrame.maxX : neighbor.minY - movedFrame.maxY

            for refGap in referenceGaps {
                if myGap > 0 && abs(myGap - refGap) <= snapThreshold {
                    var c = movedView.center
                    if axis == .horizontal {
                        c.x = neighbor.minX - refGap - movedFrame.width / 2
                    } else {
                        c.y = neighbor.minY - refGap - movedFrame.height / 2
                    }
                    movedView.center = c

                    if idx < labels.count {
                        if axis == .horizontal {
                            showSpacingLabel(labels[idx], gap: refGap,
                                             from: movedView.frame.maxX, to: neighbor.minX,
                                             midY: movedView.frame.midY)
                        } else {
                            showSpacingLabelVertical(labels[idx], gap: refGap,
                                                    from: movedView.frame.maxY, to: neighbor.minY,
                                                    midX: movedView.frame.midX)
                        }
                        idx += 1
                    }

                    if let selectable = movedView as? Selectable, selectable.isSelected {
                        selectable.positionResizeHandles()
                    }
                    return idx
                }
            }
        }

        return idx
    }

    private func showEqualSpacingLabels(
        labels: [UIView], idx: Int, gap: CGFloat, axis: SpacingAxis,
        leftEdge: CGFloat, movedView: UIView, rightEdge: CGFloat
    ) -> Int {
        var i = idx
        if i < labels.count {
            if axis == .horizontal {
                showSpacingLabel(labels[i], gap: gap,
                                 from: leftEdge, to: movedView.frame.minX,
                                 midY: movedView.frame.midY)
            } else {
                showSpacingLabelVertical(labels[i], gap: gap,
                                        from: leftEdge, to: movedView.frame.minY,
                                        midX: movedView.frame.midX)
            }
            i += 1
        }
        if i < labels.count {
            if axis == .horizontal {
                showSpacingLabel(labels[i], gap: gap,
                                 from: movedView.frame.maxX, to: rightEdge,
                                 midY: movedView.frame.midY)
            } else {
                showSpacingLabelVertical(labels[i], gap: gap,
                                        from: movedView.frame.maxY, to: rightEdge,
                                        midX: movedView.frame.midX)
            }
            i += 1
        }
        return i
    }

    /// 수평 'I' 형태 간격 표시: |---gap---|
    private func showSpacingLabel(_ container: UIView, gap: CGFloat, from: CGFloat, to: CGFloat, midY: CGFloat) {
        let serifH: CGFloat = 8
        container.frame = CGRect(x: from, y: midY - serifH, width: to - from, height: serifH * 2)
        let w = to - from
        let h = serifH * 2

        if let line = container.layer.sublayers?.first(where: { $0.name == "spacingLine" }) as? CAShapeLayer {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 0, y: h / 2))
            p.addLine(to: CGPoint(x: w, y: h / 2))
            line.path = p.cgPath
            line.frame = CGRect(x: 0, y: 0, width: w, height: h)
        }
        if let serif = container.layer.sublayers?.first(where: { $0.name == "leftSerif" }) as? CAShapeLayer {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 0.5, y: 2))
            p.addLine(to: CGPoint(x: 0.5, y: h - 2))
            serif.path = p.cgPath
            serif.frame = CGRect(x: 0, y: 0, width: 1, height: h)
        }
        if let serif = container.layer.sublayers?.first(where: { $0.name == "rightSerif" }) as? CAShapeLayer {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 0.5, y: 2))
            p.addLine(to: CGPoint(x: 0.5, y: h - 2))
            serif.path = p.cgPath
            serif.frame = CGRect(x: w - 1, y: 0, width: 1, height: h)
        }
        if let label = container.viewWithTag(999) as? UILabel {
            label.text = "\(Int(gap))"
            label.frame = CGRect(x: 0, y: 0, width: w, height: h)
        }
        container.isHidden = false
        contentView.bringSubviewToFront(container)
    }

    /// 수직 'I' 형태 간격 표시
    private func showSpacingLabelVertical(_ container: UIView, gap: CGFloat, from: CGFloat, to: CGFloat, midX: CGFloat) {
        let serifW: CGFloat = 8
        container.frame = CGRect(x: midX - serifW, y: from, width: serifW * 2, height: to - from)
        let w = serifW * 2
        let h = to - from

        if let line = container.layer.sublayers?.first(where: { $0.name == "spacingLine" }) as? CAShapeLayer {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: w / 2, y: 0))
            p.addLine(to: CGPoint(x: w / 2, y: h))
            line.path = p.cgPath
            line.frame = CGRect(x: 0, y: 0, width: w, height: h)
        }
        if let serif = container.layer.sublayers?.first(where: { $0.name == "leftSerif" }) as? CAShapeLayer {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 2, y: 0.5))
            p.addLine(to: CGPoint(x: w - 2, y: 0.5))
            serif.path = p.cgPath
            serif.frame = CGRect(x: 0, y: 0, width: w, height: 1)
        }
        if let serif = container.layer.sublayers?.first(where: { $0.name == "rightSerif" }) as? CAShapeLayer {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 2, y: 0.5))
            p.addLine(to: CGPoint(x: w - 2, y: 0.5))
            serif.path = p.cgPath
            serif.frame = CGRect(x: 0, y: h - 1, width: w, height: 1)
        }
        if let label = container.viewWithTag(999) as? UILabel {
            label.text = "\(Int(gap))"
            label.frame = CGRect(x: 0, y: 0, width: w, height: h)
        }
        container.isHidden = false
        contentView.bringSubviewToFront(container)
    }

    private func hideSpacingLabels() {
        spacingLabels.forEach { $0.isHidden = true }
    }

    private func scheduleAlignGuideHide() {
        alignGuideHideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hideAlignmentGuides()
            self?.hideSpacingLabels()
        }
        alignGuideHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func hideAlignmentGuides() {
        UIView.animate(withDuration: 0.15) {
            self.alignmentGuideViews.forEach { $0.alpha = 0 }
        } completion: { _ in
            self.alignmentGuideViews.forEach { $0.isHidden = true }
        }
    }
}
