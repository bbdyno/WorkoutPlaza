//
//  BaseWorkoutDetailViewController+TextPathDrawing.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/10/26.
//

import UIKit
import SnapKit

extension BaseWorkoutDetailViewController {

    internal func enterTextPathDrawingMode() {
        isTextPathDrawingMode = true
        textPathPoints = []

        // Disable all widgets interaction
        for widget in widgets {
            widget.isUserInteractionEnabled = false
        }

        // Deselect any selected items
        selectionManager.deselectAll()

        // Show overlay
        textPathDrawingOverlayView.isHidden = false
        contentView.bringSubviewToFront(textPathDrawingOverlayView)

        // Hide normal UI elements
        topRightToolbar.isHidden = true
        bottomFloatingToolbar.isHidden = true
        multiSelectToolbar.isHidden = true
        instructionLabel.text = WorkoutPlazaStrings.Base.Textpath.Draw.instruction

        // Change navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: WorkoutPlazaStrings.Common.cancel,
            style: .plain,
            target: self,
            action: #selector(exitTextPathDrawingMode)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: WorkoutPlazaStrings.Base.Textpath.edit,
            style: .plain,
            target: self,
            action: #selector(editTextPathText)
        )

        // Show text path drawing toolbar
        textPathDrawingToolbar.isHidden = false

        // Add pan gesture for drawing on overlay
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTextPathPan(_:)))
        textPathDrawingOverlayView.addGestureRecognizer(panGesture)

        // Add tap gesture to close panel when tapping outside (initially disabled)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTextPathOverlayTap(_:)))
        tapGesture.require(toFail: panGesture)
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        tapGesture.isEnabled = true // Always enabled to handle outside taps
        textPathDrawingOverlayView.addGestureRecognizer(tapGesture)
        textPathOverlayTapGesture = tapGesture

        textPathDrawingOverlayView.isUserInteractionEnabled = true

        // Disable scrolling
        scrollView.isScrollEnabled = false
    }

    @objc func exitTextPathDrawingMode() {
        isTextPathDrawingMode = false
        textPathPoints = []
        isTextPathStraightLineMode = false
        textPathStraightLineStartPoint = .zero

        // Reset mode button icon
        if let modeButton = textPathDrawingToolbar.viewWithTag(9003) as? UIButton {
            modeButton.setImage(UIImage(systemName: "scribble"), for: .normal)
        }

        // Clear drawing view
        textPathDrawingOverlayView.subviews.forEach { $0.removeFromSuperview() }

        // Hide overlay
        textPathDrawingOverlayView.isHidden = true

        // Re-enable all widgets interaction
        for widget in widgets {
            widget.isUserInteractionEnabled = true
        }

        // Hide any floating panels
        hideAllTextPathPanels()

        // Show normal UI elements
        topRightToolbar.isHidden = false
        instructionLabel.text = WorkoutPlazaStrings.Ui.Drag.Widgets.instruction

        // Restore navigation buttons
        setupNavigationButtons()

        // Hide text path toolbar and buttons
        textPathDrawingToolbar.isHidden = true
        textPathConfirmButton.isHidden = true
        textPathRedrawButton.isHidden = true

        // Remove pan gesture from overlay
        textPathDrawingOverlayView.gestureRecognizers?.forEach { gesture in
            textPathDrawingOverlayView.removeGestureRecognizer(gesture)
        }
        textPathDrawingOverlayView.isUserInteractionEnabled = false

        // Enable scrolling
        scrollView.isScrollEnabled = false // Keep disabled for normal mode

        pendingTextForPath = ""
    }

    @objc func editTextPathText() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Base.Textpath.edit,
            message: WorkoutPlazaStrings.Textpath.message,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = self.pendingTextForPath.trimmingCharacters(in: .whitespaces)
            textField.placeholder = WorkoutPlazaStrings.Textpath.placeholder
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let text = alert?.textFields?.first?.text,
                  !text.isEmpty else { return }

            self.pendingTextForPath = text + " "
            self.instructionLabel.text = WorkoutPlazaStrings.Base.Textpath.repeat(self.pendingTextForPath)

            // Redraw with new text
            self.updateTextPathDrawing()
        })

        present(alert, animated: true)
    }


    @objc func handleTextPathOverlayTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)

        // Check if tap is inside toolbar
        if !textPathDrawingToolbar.isHidden && textPathDrawingToolbar.frame.contains(location) {
            return
        }

        // Check if tap is inside any visible independent floating panel
        if !textPathColorPanel.isHidden && textPathColorPanel.frame.contains(location) {
            return
        }
        if !textPathFontPanel.isHidden && textPathFontPanel.frame.contains(location) {
            return
        }
        if !textPathSizePanel.isHidden && textPathSizePanel.frame.contains(location) {
            return
        }

        // Otherwise close panels
        hideAllTextPathPanels()
    }

    @objc func handleTextPathPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: contentView)

        switch gesture.state {
        case .began:
            textPathStraightLineStartPoint = location
            textPathPoints = [location]
            textPathConfirmButton.isHidden = true
            textPathRedrawButton.isHidden = true
            instructionLabel.isHidden = true
            // Close any open panels when drawing starts
            hideAllTextPathPanels()

        case .changed:
            if isTextPathStraightLineMode {
                // 직선 모드: 시작점과 현재점만 유지
                textPathPoints = [textPathStraightLineStartPoint, location]
            } else {
                // 자유곡선 모드: 계속 추가
                textPathPoints.append(location)
            }
            updateTextPathDrawing()

        case .ended, .cancelled:
            if isTextPathStraightLineMode {
                // 직선 모드: 시작점과 끝점
                textPathPoints = [textPathStraightLineStartPoint, location]
            } else {
                // 자유곡선 모드: 마지막 점 추가
                textPathPoints.append(location)
            }
            if textPathPoints.count >= 2 {
                textPathConfirmButton.isHidden = false
                textPathRedrawButton.isHidden = false
            }
            updateTextPathDrawing()

        default:
            break
        }
    }

    @objc func textPathColorMainButtonTapped(_ sender: UIButton) {
        let shouldShow = textPathColorPanel.isHidden
        if shouldShow {
            hideAllTextPathPanels(except: textPathColorPanel)
            showTextPathPanel(textPathColorPanel, sourceButton: sender)
        } else {
            hideAllTextPathPanels()
        }
    }

    @objc func textPathFontMainButtonTapped(_ sender: UIButton) {
        let shouldShow = textPathFontPanel.isHidden
        if shouldShow {
            hideAllTextPathPanels(except: textPathFontPanel)
            showTextPathPanel(textPathFontPanel, sourceButton: sender)
        } else {
            hideAllTextPathPanels()
        }
    }

    @objc func textPathSizeMainButtonTapped(_ sender: UIButton) {
        let shouldShow = textPathSizePanel.isHidden
        if shouldShow {
            hideAllTextPathPanels(except: textPathSizePanel)
            showTextPathPanel(textPathSizePanel, sourceButton: sender)
        } else {
            hideAllTextPathPanels()
        }
    }

    @objc func textPathModeButtonTapped(_ sender: UIButton) {
        // 모드 토글
        isTextPathStraightLineMode.toggle()

        // 아이콘 업데이트
        let iconName = isTextPathStraightLineMode ? "line.diagonal" : "scribble"
        sender.setImage(UIImage(systemName: iconName), for: .normal)
    }

    func hideAllTextPathPanels(except viewToKeep: UIView? = nil) {
        let panels = [textPathColorPanel, textPathFontPanel, textPathSizePanel]
        
        // Reset button states if all panels are being hidden (or update for the kept one)
        if viewToKeep == nil {
            resetTextPathMainButtonsState()
        }
        
        panels.forEach { panel in
            if panel == viewToKeep { return }
            
            // Only animate if it's currently visible or we want to ensure it's hidden
            if !panel.isHidden {
                UIView.animate(withDuration: 0.2) {
                    panel.alpha = 0
                    panel.transform = CGAffineTransform(translationX: 0, y: 10)
                } completion: { _ in
                    panel.isHidden = true
                }
            } else {
                panel.isHidden = true
            }
        }
    }
    
    func resetTextPathMainButtonsState() {
        let mainButtonTags = [9000, 9001, 9002]
        mainButtonTags.forEach { tag in
            if let button = textPathDrawingToolbar.viewWithTag(tag) as? UIButton {
                button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
                // Keep the color button (9000) background color as selected color
                // Keep the font/size button background as transparent white
            }
        }
    }

    func showTextPathPanel(_ panel: UIView, sourceButton: UIButton) {
        panel.isHidden = false
        panel.alpha = 0
        panel.transform = CGAffineTransform(translationX: 0, y: 10)
        
        // Highlight source button
        resetTextPathMainButtonsState()
        sourceButton.layer.borderColor = UIColor.systemYellow.cgColor
        
        // Remake constraints: Center horizontally with padding, bottom to button top
        panel.snp.remakeConstraints { make in
            make.bottom.equalTo(sourceButton.snp.top).offset(-12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(50)
        }
        
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            panel.alpha = 1
            panel.transform = .identity
            self.view.layoutIfNeeded()
        } completion: { _ in
            // No strict need to re-enable gestures here as we successfully separated the views
        }
    }

    @objc func textPathColorButtonTapped(_ sender: UIButton) {
        textPathSelectedColorIndex = sender.tag
        let availableColors: [UIColor] = [
            .white, .systemYellow, .systemOrange, .systemPink,
            .systemRed, .systemGreen, .systemBlue, .systemPurple
        ]
        textPathSelectedColor = availableColors[sender.tag]
        UIView.animate(withDuration: 0.2) {
            self.updateTextPathColorSelection()
            self.updateTextPathDrawing()
        } completion: { _ in
            // Auto-hide panel and update main button
            if let mainButton = self.textPathDrawingToolbar.viewWithTag(9000) as? UIButton {
                mainButton.backgroundColor = self.textPathSelectedColor
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.hideAllTextPathPanels()
            }
        }
    }

    @objc func textPathFontButtonTapped(_ sender: UIButton) {
        textPathSelectedFontIndex = sender.tag
        let availableFonts: [(name: String, font: UIFont)] = [
            (WorkoutPlazaStrings.Ui.Font.default, .boldSystemFont(ofSize: 20)),
            (WorkoutPlazaStrings.Ui.Font.thin, .systemFont(ofSize: 20, weight: .light)),
            (WorkoutPlazaStrings.Ui.Font.rounded, .systemFont(ofSize: 20, weight: .medium)),
            (WorkoutPlazaStrings.Ui.Font.bold, .systemFont(ofSize: 20, weight: .black))
        ]
        let baseFont = availableFonts[sender.tag].font
        textPathSelectedFont = baseFont.withSize(textPathSelectedFontSize)
        UIView.animate(withDuration: 0.2) {
            self.updateTextPathFontSelection()
            self.updateTextPathDrawing()
        } completion: { _ in
            // Auto-hide panel and update main button
            if let mainButton = self.textPathDrawingToolbar.viewWithTag(9001) as? UIButton {
                mainButton.setTitle(availableFonts[sender.tag].name, for: .normal)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.hideAllTextPathPanels()
            }
        }
    }

    @objc func textPathFontSizeChanged(_ sender: UISlider) {
        textPathSelectedFontSize = CGFloat(sender.value)
        // Update label (in panel)
        if let label = textPathSizePanel.viewWithTag(999) as? UILabel {
            label.text = "\(Int(textPathSelectedFontSize))"
        }
        // Update main button
        if let mainButton = textPathDrawingToolbar.viewWithTag(9002) as? UIButton {
            mainButton.setTitle("\(Int(textPathSelectedFontSize))", for: .normal)
        }
        let availableFonts: [(name: String, font: UIFont)] = [
            (WorkoutPlazaStrings.Ui.Font.default, .boldSystemFont(ofSize: 20)),
            (WorkoutPlazaStrings.Ui.Font.thin, .systemFont(ofSize: 20, weight: .light)),
            (WorkoutPlazaStrings.Ui.Font.rounded, .systemFont(ofSize: 20, weight: .medium)),
            (WorkoutPlazaStrings.Ui.Font.bold, .systemFont(ofSize: 20, weight: .black))
        ]
        let baseFont = availableFonts[textPathSelectedFontIndex].font
        textPathSelectedFont = baseFont.withSize(textPathSelectedFontSize)
        updateTextPathDrawing()
    }

    @objc func textPathConfirmTapped() {
        guard textPathPoints.count >= 2 else { return }

        // Apply the same simplification used in preview
        let simplifiedPoints = simplifyTextPath(textPathPoints, minDistance: 8.0)
        guard simplifiedPoints.count >= 2 else { return }

        // Calculate bounding rect from simplified points
        let boundingRect = calculateTextPathBoundingRect(from: simplifiedPoints)

        // Convert simplified points to local coordinates
        let localPoints = simplifiedPoints.map { point in
            CGPoint(
                x: point.x - boundingRect.origin.x,
                y: point.y - boundingRect.origin.y
            )
        }

        createTextPathWidget(
            pathPoints: localPoints,
            boundingRect: boundingRect,
            canvasSize: contentView.bounds.size,
            color: textPathSelectedColor,
            font: textPathSelectedFont
        )
        exitTextPathDrawingMode()
    }

    @objc func textPathRedrawTapped() {
        textPathPoints = []
        textPathDrawingOverlayView.subviews.forEach { $0.removeFromSuperview() }
        textPathConfirmButton.isHidden = true
        textPathRedrawButton.isHidden = true
        instructionLabel.isHidden = false
    }

    func updateTextPathColorSelection() {
        for (index, button) in textPathColorButtons.enumerated() {
            button.layer.borderColor = index == textPathSelectedColorIndex ?
                UIColor.white.cgColor : UIColor.clear.cgColor
            button.transform = index == textPathSelectedColorIndex ?
                CGAffineTransform(scaleX: 1.15, y: 1.15) : .identity
        }
        // Update main button
        if let mainButton = textPathDrawingToolbar.viewWithTag(9000) as? UIButton {
            mainButton.backgroundColor = textPathSelectedColor
        }
    }

    func updateTextPathFontSelection() {
        for (index, button) in textPathFontButtons.enumerated() {
            button.backgroundColor = index == textPathSelectedFontIndex ?
                UIColor.white.withAlphaComponent(0.3) : UIColor.white.withAlphaComponent(0.1)
        }
        // Update main button
        if let mainButton = textPathDrawingToolbar.viewWithTag(9001) as? UIButton {
            let availableFonts: [(name: String, font: UIFont)] = [
                (WorkoutPlazaStrings.Ui.Font.default, .boldSystemFont(ofSize: 20)),
                (WorkoutPlazaStrings.Ui.Font.thin, .systemFont(ofSize: 20, weight: .light)),
                (WorkoutPlazaStrings.Ui.Font.rounded, .systemFont(ofSize: 20, weight: .medium)),
                (WorkoutPlazaStrings.Ui.Font.bold, .systemFont(ofSize: 20, weight: .black))
            ]
            mainButton.setTitle(availableFonts[textPathSelectedFontIndex].name, for: .normal)
        }
    }

    private func updateTextPathDrawing() {
        // Remove old preview view
        textPathDrawingOverlayView.subviews.forEach { $0.removeFromSuperview() }

        guard textPathPoints.count >= 2, !pendingTextForPath.isEmpty else { return }

        let simplifiedPath = simplifyTextPath(textPathPoints, minDistance: 8.0)
        guard simplifiedPath.count >= 2 else { return }

        // Create preview view
        let previewView = TextPathPreviewView(frame: textPathDrawingOverlayView.bounds)
        previewView.backgroundColor = .clear
        previewView.isUserInteractionEnabled = false
        previewView.points = simplifiedPath
        previewView.textToRepeat = pendingTextForPath
        previewView.textFont = textPathSelectedFont
        previewView.textColor = textPathSelectedColor

        textPathDrawingOverlayView.addSubview(previewView)
        previewView.setNeedsDisplay()
    }

    private func simplifyTextPath(_ points: [CGPoint], minDistance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var simplified: [CGPoint] = [points[0]]

        for i in 1..<points.count {
            let lastPoint = simplified.last!
            let currentPoint = points[i]
            let dx = currentPoint.x - lastPoint.x
            let dy = currentPoint.y - lastPoint.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance >= minDistance {
                simplified.append(currentPoint)
            }
        }

        if let last = points.last, simplified.last != last {
            simplified.append(last)
        }

        return simplified.count >= 2 ? simplified : points
    }

    private func calculateTextPathBoundingRect(from points: [CGPoint]? = nil) -> CGRect {
        let pathPoints = points ?? textPathPoints
        guard !pathPoints.isEmpty else { return .zero }

        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude

        for point in pathPoints {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }

        let padding: CGFloat = 30
        return CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + padding * 2,
            height: maxY - minY + padding * 2
        )
    }

    private func createTextPathWidget(
        pathPoints: [CGPoint],
        boundingRect: CGRect,
        canvasSize: CGSize,
        color: UIColor,
        font: UIFont
    ) {
        guard pathPoints.count >= 2 else { return }

        // pathPoints are already in local coordinate system (relative to boundingRect)
        // and already simplified

        // Create widget with color and font
        let widget = TextPathWidget(
            text: pendingTextForPath,
            pathPoints: pathPoints,
            frame: boundingRect,
            color: color,
            font: font,
            alreadySimplified: true
        )

        widget.selectionDelegate = self
        selectionManager.registerItem(widget)
        widgets.append(widget)
        contentView.addSubview(widget)
        contentView.bringSubviewToFront(widget)

        // Select the new widget
        selectionManager.selectItem(widget)
        hasUnsavedChanges = true
        pendingTextForPath = ""
    }
}
