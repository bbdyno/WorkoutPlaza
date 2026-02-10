//
//  BaseWorkoutDetailViewController+PersistenceRestore.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/10/26.
//

import UIKit

extension BaseWorkoutDetailViewController {

    private func configureRestoreCanvasTransform(savedCanvasSize: CGSize) {
        let currentCanvasSize = contentView.bounds.size
        guard savedCanvasSize.width > 0,
              savedCanvasSize.height > 0,
              currentCanvasSize.width > 0,
              currentCanvasSize.height > 0 else {
            restoreCanvasTransform = .identity
            return
        }

        let scaleX = currentCanvasSize.width / savedCanvasSize.width
        let scaleY = currentCanvasSize.height / savedCanvasSize.height
        let uniformScale = sqrt(scaleX * scaleY)

        restoreCanvasTransform = RestoreCanvasTransform(
            scaleX: scaleX,
            scaleY: scaleY,
            uniformScale: uniformScale
        )
    }

    private func resetRestoreCanvasTransform() {
        restoreCanvasTransform = .identity
    }

    func scaledFrameForCurrentCanvas(_ frame: CGRect) -> CGRect {
        let scale = restoreCanvasTransform
        guard frame.width.isFinite,
              frame.height.isFinite,
              frame.origin.x.isFinite,
              frame.origin.y.isFinite else {
            return frame
        }
        guard scale.scaleX != 1 || scale.scaleY != 1 || scale.uniformScale != 1 else {
            return frame
        }

        let scaled = CGRect(
            x: frame.origin.x * scale.scaleX,
            y: frame.origin.y * scale.scaleY,
            width: frame.width * scale.uniformScale,
            height: frame.height * scale.uniformScale
        )
        return scaled
    }

    func restoreCanvasUniformScale() -> CGFloat {
        restoreCanvasTransform.uniformScale
    }
    
    @objc dynamic func loadSavedDesign() {
        let workoutId = getWorkoutId()
        
        guard let design = CardPersistenceManager.shared.loadDesign(for: workoutId) else {
            WPLog.debug("No saved design found for \(workoutId)")
            // Reset flag even if no saved design (initial state should be "no changes")
            hasUnsavedChanges = false
            return
        }
        
        WPLog.info("Loading saved design for \(workoutId)")
        
        // Restore Aspect Ratio
        currentAspectRatio = design.aspectRatio
        aspectRatioButton.setTitle(design.aspectRatio.displayName, for: .normal)
        updateCanvasSize()
        
        // Force layout update
        view.layoutIfNeeded()
        configureRestoreCanvasTransform(savedCanvasSize: design.canvasSize)
        defer { resetRestoreCanvasTransform() }

        // Restore Background
        if design.backgroundType == .image, let data = design.backgroundImageData {
            backgroundImageView.image = UIImage(data: data)
            backgroundImageView.isHidden = false
            backgroundTemplateView.isHidden = true
        } else if design.backgroundType == .gradient, let styleString = design.gradientStyle {
            backgroundImageView.isHidden = true
            backgroundTemplateView.isHidden = false

            if let style = BackgroundTemplateView.TemplateStyle(rawValue: styleString) {
                if style == .custom, let colorsHex = design.gradientColors {
                    let colors = colorsHex.compactMap { UIColor(hex: $0) }
                    if !colors.isEmpty {
                        backgroundTemplateView.applyCustomGradient(colors: colors, direction: .topToBottom)
                    }
                } else {
                    backgroundTemplateView.applyTemplate(style)
                }
            }
        }

        // 1. Build a map of EXISTING widgets by itemIdentifier (if available) or className_index fallback
        // Since we are using stable identifiers now, we should try to match by that first
        var existingWidgetMap: [String: UIView] = [:]
        
        // Check widgets in self.widgets
        for widget in widgets {
            if let selectable = widget as? Selectable {
                existingWidgetMap[selectable.itemIdentifier] = widget
            }
        }
        // Check widgets in groups (in case we are reloading over existing state)
        for group in templateGroups {
            for widget in group.groupedItems {
                if let selectable = widget as? Selectable {
                    existingWidgetMap[selectable.itemIdentifier] = widget
                }
            }
        }

        // 2. Create or Update ALL widgets from save state
        var restoredWidgetsMap: [String: UIView] = [:]
        
        for savedWidget in design.widgets {
            let widget: UIView
            
            // Try to find existing widget
            if let existing = existingWidgetMap[savedWidget.identifier] {
                widget = existing
            } else {
                // Create new
                guard let newWidget = createWidgetFromSavedState(savedWidget) else { continue }
                widget = newWidget
                // Ensure identifier matches saved one
                if let selectable = widget as? Selectable {
                    selectable.itemIdentifier = savedWidget.identifier
                }
            }
            
            // Restore properties
            let restoredFrame = frameForRestoredWidget(savedWidget, widget: widget)
            widget.frame = restoredFrame
            let restoredInitialSize = resolvedRestoredInitialSize(
                savedWidget,
                widget: widget,
                restoredFrame: restoredFrame
            )

            if let selectable = widget as? Selectable {
                selectable.initialSize = restoredInitialSize
            }

            // Restore common properties
            if let statWidget = widget as? BaseStatWidget {
                if let fontStyleRaw = savedWidget.fontStyle,
                   let fontStyle = FontStyle(rawValue: fontStyleRaw) {
                    statWidget.applyFont(fontStyle)
                }
                applySavedStatTypography(statWidget, from: savedWidget)
                if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                    statWidget.applyColor(color)
                }
            } else if let routesWidget = widget as? ClimbingRoutesByColorWidget {
                routesWidget.initialSize = restoredInitialSize
                if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                    routesWidget.applyColor(color)
                }
                // Load and apply saved font
                if let savedFont = FontPreferences.shared.loadFont(for: savedWidget.identifier) {
                    routesWidget.applyFont(savedFont)
                }
            }

            // Restore rotation for all Selectable widgets
            if let selectable = widget as? Selectable {
                selectable.rotation = savedWidget.rotation
                widget.transform = CGAffineTransform(rotationAngle: savedWidget.rotation)
            }

            if let routeMap = widget as? RouteMapView {
                routeMap.initialSize = restoredInitialSize
            }

            if let textWidget = widget as? TextWidget, let text = savedWidget.text {
                textWidget.updateText(text)
                if let colorHex = savedWidget.textColor, let color = UIColor(hex: colorHex) {
                    textWidget.applyColor(color)
                }
            }

            if let alignmentRaw = savedWidget.contentAlignment,
               let alignment = WidgetContentAlignment(rawValue: alignmentRaw),
               let alignableWidget = widget as? WidgetContentAlignable {
                alignableWidget.applyContentAlignment(alignment)
            }

            // Add to map
            restoredWidgetsMap[savedWidget.identifier] = widget
        }
        
        // 3. Clear current state
        // Remove all widgets from view hierarchy first
        widgets.forEach { $0.removeFromSuperview() }
        templateGroups.forEach { $0.removeFromSuperview() } // Groups remove their children too usually, but clean up is safer
        widgets.removeAll()
        templateGroups.removeAll()
        selectionManager.unregisterAllItems()
        
        // 4. Restore GROUPS
        var groupedWidgetIds: Set<String> = []
        
        if let savedGroups = design.groups {
            for savedGroup in savedGroups {
                let groupType = WidgetGroupType(rawValue: savedGroup.type) ?? .myRecord
                
                // Collect widgets for this group
                var groupWidgets: [UIView] = []
                for widgetId in savedGroup.widgetIdentifiers {
                    if let widget = restoredWidgetsMap[widgetId] {
                        groupWidgets.append(widget)
                        groupedWidgetIds.insert(widgetId)
                    }
                }
                
                if !groupWidgets.isEmpty {
                    let restoredGroupFrame = scaledFrameForCurrentCanvas(savedGroup.frame)
                    // Fix: TemplateGroupView assumes items are in GLOBAL coordinates (relative to contentView)
                    // and converts them to local. But saved widgets are already in LOCAL coordinates relative to the group.
                    // So we must convert them back to global by adding the group's origin.
                    for widget in groupWidgets {
                        widget.frame.origin.x += restoredGroupFrame.origin.x
                        widget.frame.origin.y += restoredGroupFrame.origin.y
                    }

                    let group = TemplateGroupView(
                        items: groupWidgets,
                        frame: restoredGroupFrame,
                        groupType: groupType,
                        ownerName: savedGroup.ownerName
                    )
                    
                    group.groupDelegate = self
                    group.selectionDelegate = self
                    selectionManager.registerItem(group)
                    
                    contentView.addSubview(group)
                    templateGroups.append(group)
                }
            }
        }
        
        // 5. Restore UNGROUPED widgets
        for (id, widget) in restoredWidgetsMap {
            if !groupedWidgetIds.contains(id) {
                contentView.addSubview(widget)
                widgets.append(widget)
                
                if let selectable = widget as? Selectable {
                    selectable.selectionDelegate = self
                    selectionManager.registerItem(selectable)
                }
            }
        }

        WPLog.info("Design loaded and restored for \(workoutId)")

        // Update watermark color based on loaded background
        updateWatermarkColorForBackground()

        // Reset unsaved changes flag since we just loaded the saved state
        hasUnsavedChanges = false
    }


    func applySavedStatTypography(_ widget: BaseStatWidget, from savedState: SavedWidgetState) {
        if let titleBase = savedState.statTitleBaseFontSize, titleBase > 0 {
            widget.baseFontSizes["title"] = titleBase
        }
        if let valueBase = savedState.statValueBaseFontSize, valueBase > 0 {
            widget.baseFontSizes["value"] = valueBase
        }
        if let unitBase = savedState.statUnitBaseFontSize, unitBase > 0 {
            widget.baseFontSizes["unit"] = unitBase
        }

        if let savedScale = savedState.statFontScale, savedScale > 0 {
            let targetScale = min(
                max(savedScale * restoreCanvasUniformScale(), LayoutConstants.groupManagedMinimumScale),
                LayoutConstants.maximumScaleFactor
            )
            widget.updateFontsWithScale(targetScale)
        } else {
            widget.updateFonts()
        }
    }

    func resolvedRestoredInitialSize(_ savedState: SavedWidgetState, widget: UIView, restoredFrame: CGRect) -> CGSize {
        let fallback = restoredFrame.size

        let savedInitialSize: CGSize?
        if let candidate = savedState.initialSize,
           candidate.width > 0,
           candidate.height > 0 {
            savedInitialSize = candidate
        } else {
            savedInitialSize = nil
        }

        let hasSavedInitialSize = savedInitialSize != nil
        var resolved = savedInitialSize ?? fallback

        if widget is BaseStatWidget,
           let persistedScale = savedState.statFontScale,
           persistedScale > 0,
           fallback.width > 0,
           fallback.height > 0 {
            let targetScale = min(
                max(persistedScale * restoreCanvasUniformScale(), LayoutConstants.groupManagedMinimumScale),
                LayoutConstants.maximumScaleFactor
            )
            resolved = CGSize(
                width: fallback.width / max(targetScale, 0.001),
                height: fallback.height / max(targetScale, 0.001)
            )
        }

        let definitionID = WidgetIdentity.definitionID(for: widget)
            ?? WidgetIdentity.resolvedDefinitionID(from: savedState)
        if let definitionID {
            let widgetType = WidgetIdentity.widgetType(for: definitionID)
            resolved = WidgetSizeNormalizer.normalizeRestoredRunningStatInitialSize(
                resolved,
                restoredFrameSize: fallback,
                widgetType: widgetType,
                hasExplicitSavedInitialSize: hasSavedInitialSize || savedState.statFontScale != nil,
                canvasScale: restoreCanvasUniformScale()
            )
        }

        return resolved
    }

    // Create widget from saved state - override in subclasses for specific widgets
    func applyCommonWidgetStyles(to widget: UIView, from savedState: SavedWidgetState) {
        let restoredFrame = frameForRestoredWidget(savedState, widget: widget)
        widget.frame = restoredFrame
        let restoredInitialSize = resolvedRestoredInitialSize(
            savedState,
            widget: widget,
            restoredFrame: restoredFrame
        )
        if let selectable = widget as? Selectable {
            selectable.initialSize = restoredInitialSize
            if let colorHex = savedState.textColor, let color = UIColor(hex: colorHex) {
                selectable.applyColor(color)
            }
            if let fontStyleRaw = savedState.fontStyle, let fontStyle = FontStyle(rawValue: fontStyleRaw) {
                selectable.applyFont(fontStyle)
            }
            if let alignmentRaw = savedState.contentAlignment,
               let alignment = WidgetContentAlignment(rawValue: alignmentRaw),
               let alignableWidget = widget as? WidgetContentAlignable {
                alignableWidget.applyContentAlignment(alignment)
            }
        }
        if let statWidget = widget as? BaseStatWidget,
           let modeRaw = savedState.displayMode,
           let mode = WidgetDisplayMode(rawValue: modeRaw) {
            statWidget.setDisplayMode(mode)
        }
    }


}
