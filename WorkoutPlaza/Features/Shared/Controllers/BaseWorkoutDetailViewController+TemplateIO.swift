//
//  BaseWorkoutDetailViewController+TemplateIO.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/10/26.
//

import UIKit
import UniformTypeIdentifiers

extension BaseWorkoutDetailViewController {

    func showTemplatePreview(_ template: WidgetTemplate) {
        let previewVC = TemplatePreviewViewController(
            template: template,
            widgetFactory: { [weak self] item, frame in
                self?.createWidget(for: item, frame: frame)
            },
            onApply: { [weak self] in
                self?.applyWidgetTemplate(template)
            }
        )
        previewVC.title = template.name
        presentAsSheet(previewVC)
    }

    /// Override in subclasses to create workout-specific widgets

    func applyWidgetTemplate(_ template: WidgetTemplate) {
        // Clear existing widgets
        widgets.forEach { $0.removeFromSuperview() }
        clearCustomWidgets()
        widgets.removeAll()
        selectionManager.deselectAll()

        WPLog.debug("Applying template '\(template.name)' version \(template.version)")

        // Get template canvas size
        let templateCanvasSize: CGSize
        if let tCanvasSize = template.canvasSize {
            templateCanvasSize = CGSize(width: tCanvasSize.width, height: tCanvasSize.height)
        } else {
            // For very old templates without canvas size, assume a default
            templateCanvasSize = CGSize(width: 414, height: 700)
        }

        // STEP 1: Change canvas aspect ratio to match template
        let detectedAspectRatio = AspectRatio.detect(from: templateCanvasSize)

        // Update aspect ratio button and canvas size
        currentAspectRatio = detectedAspectRatio
        aspectRatioButton.setTitle(detectedAspectRatio.displayName, for: .normal)
        updateCanvasSize()

        // Force immediate layout update
        view.layoutIfNeeded()

        // STEP 2: Get updated canvas size after aspect ratio change
        let canvasSize = contentView.bounds.size

        // STEP 3: Apply background image aspect ratio if available
        if template.backgroundImageAspectRatio != nil {
            // Note: This will be applied when user selects a background image
            // Store it for later use
        }

        // STEP 4: Apply background transform if available
        if let transformData = template.backgroundTransform {
            let transform = BackgroundTransform(
                scale: transformData.scale,
                offset: CGPoint(x: transformData.offsetX, y: transformData.offsetY)
            )
            backgroundTransform = transform
            if !backgroundImageView.isHidden {
                applyBackgroundTransform(transform)
            }
        }

        // STEP 5: Create all widgets in the new canvas
        for item in template.items {
            // Use ratio-based positioning (version 2.0+) or fallback to legacy
            let frame = TemplateManager.absoluteFrame(from: item, canvasSize: canvasSize, templateCanvasSize: templateCanvasSize)

            // Try to create widget using subclass implementation
            if let widget = createWidget(for: item, frame: frame) {
                contentView.addSubview(widget)
                widgets.append(widget)

                if let selectable = widget as? Selectable {
                    selectable.selectionDelegate = self
                    selectionManager.registerItem(selectable)

                    // Apply rotation if available
                    if let rotation = item.rotation {
                        selectable.rotation = rotation
                        widget.transform = CGAffineTransform(rotationAngle: rotation)
                    }
                }
            }
        }

        instructionLabel.text = WorkoutPlazaStrings.Ui.Drag.Widgets.instruction
        WPLog.info("Applied template directly: \(template.name)")
    }
    
    @objc dynamic func importTemplate() {
        documentPickerPurpose = .templateImport
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json, .data])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @objc dynamic func importWidgetPackage() {
        documentPickerPurpose = .widgetPackageImport
        let packageType = UTType(filenameExtension: "wpwidgetpack") ?? .data
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [packageType, .json, .data])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @objc dynamic func showWidgetPackageManagerSheet() {
        Task {
            let packages = await WidgetPackageManager.shared.installedPackages()
            await MainActor.run {
                let title = "Widget Packages"
                let message = packages.isEmpty ? "No packages installed." : nil
                let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

                for package in packages {
                    let itemTitle = "\(package.name) v\(package.version)"
                    alert.addAction(UIAlertAction(title: itemTitle, style: .destructive) { [weak self] _ in
                        guard let self else { return }
                        Task {
                            try? await WidgetPackageManager.shared.removePackage(
                                packageID: package.packageID,
                                version: package.version
                            )
                            await MainActor.run {
                                self.refreshTemplateLibrary()
                            }
                        }
                    })
                }

                alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

                if let popover = alert.popoverPresentationController {
                    popover.sourceView = self.layoutTemplateButton
                    popover.sourceRect = self.layoutTemplateButton.bounds
                }

                self.present(alert, animated: true)
            }
        }
    }

    @objc dynamic func showTemplateMarket() {
        let config = FeaturePackManager.shared.templateMarketButtonConfig(for: getSportType())
        guard config.isEnabled else { return }
        if handleMarketRoute(.templateMarket, destination: config.destination, targetURLString: config.url) { return }

        showToast(WorkoutPlazaStrings.Toast.Feature.Coming.soon)
    }

    @objc dynamic func showWidgetMarket() {
        let config = FeaturePackManager.shared.widgetMarketButtonConfig(for: getSportType())
        guard config.isEnabled else { return }
        if handleMarketRoute(.widgetMarket, destination: config.destination, targetURLString: config.url) { return }

        showToast(WorkoutPlazaStrings.Toast.Feature.Coming.soon)
    }

    private func handleMarketRoute(
        _ route: AppSchemeManager.Route,
        destination: String?,
        targetURLString: String?
    ) -> Bool {
        let rootViewController = view.window?.rootViewController

        if let routeURL = marketRouteURL(route, destination: destination, targetURLString: targetURLString),
           AppSchemeManager.shared.handle(routeURL, rootViewController: rootViewController) {
            return true
        }

        if let destination,
           let destinationURL = URL(string: destination),
           AppSchemeManager.shared.handle(destinationURL, rootViewController: rootViewController) {
            return true
        }

        return false
    }

    private func marketRouteURL(
        _ route: AppSchemeManager.Route,
        destination: String?,
        targetURLString: String?
    ) -> URL? {
        if let destination,
           let baseURL = URL(string: destination),
           AppSchemeManager.shared.canHandle(baseURL) {
            guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                return baseURL
            }

            if let targetURLString {
                let trimmedTarget = targetURLString.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedTarget.isEmpty == false {
                    var queryItems = components.queryItems ?? []
                    queryItems.removeAll { $0.name == "target_url" || $0.name == "url" }
                    queryItems.append(URLQueryItem(name: "target_url", value: trimmedTarget))
                    components.queryItems = queryItems
                }
            }
            return components.url ?? baseURL
        }

        return AppSchemeManager.shared.makeRouteURL(route, targetURLString: targetURLString)
    }

    @objc dynamic func exportCurrentLayout() {
        let items = createTemplateItemsFromCurrentLayout()
        let canvasSize = contentView.bounds.size

        var backgroundImageAspectRatio: CGFloat? = nil
        if let image = backgroundImageView.image, !backgroundImageView.isHidden {
            backgroundImageAspectRatio = image.size.width / image.size.height
        }

        var backgroundTransformData: BackgroundTransformData? = nil
        if let transform = backgroundTransform {
            backgroundTransformData = BackgroundTransformData(
                scale: transform.scale,
                offsetX: transform.offset.x,
                offsetY: transform.offset.y
            )
        }

        let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.Template.save, message: WorkoutPlazaStrings.Alert.Template.Save.prompt, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = WorkoutPlazaStrings.Base.Template.Name.placeholder }
        alert.addTextField { $0.placeholder = WorkoutPlazaStrings.Base.Template.Desc.placeholder }

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.save, style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty else { return }
            let description = alert.textFields?[1].text ?? ""

            let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

                let template = WidgetTemplate(
                name: name,
                description: description,
                version: "2.0",
                sportType: self?.getSportType() ?? .running,
                items: items,
                canvasSize: WidgetTemplate.CanvasSize(width: canvasSize.width, height: canvasSize.height),
                backgroundImageAspectRatio: backgroundImageAspectRatio,
                backgroundTransform: backgroundTransformData,
                minimumAppVersion: currentAppVersion
            )

                Task { [weak self] in
                    do {
                        let fileURL = try TemplateManager.shared.exportTemplate(template)
                        await MainActor.run {
                            self?.shareTemplate(fileURL: fileURL)
                        }
                } catch {
                    WPLog.error("Failed to export template: \(error)")
                }
            }
        })
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Button.cancel, style: .cancel))
        present(alert, animated: true)
    }
    
    func createTemplateItemsFromCurrentLayout() -> [WidgetItem] {
        var items: [WidgetItem] = []
        let canvasSize = contentView.bounds.size

        for widget in widgets {
            let frame = widget.frame
            var color: String?
            var font: String?
            var payload: String?
            guard let definitionID = WidgetIdentity.definitionID(for: widget) else {
                continue
            }
            // Text-path widgets are not part of template schema yet.
            if definitionID == .textPath {
                continue
            }
            let widgetType = WidgetIdentity.widgetType(for: definitionID)

            if let compositeWidget = widget as? CompositeWidget {
                payload = compositeWidget.encodedPayloadString()
            }

            if let selectable = widget as? Selectable {
                 color = TemplateManager.hexString(from: selectable.currentColor)
                 font = selectable.currentFontStyle.rawValue
            }

            // Get rotation from Selectable widget
            let rotation: CGFloat?
            if let selectable = widget as? Selectable {
                rotation = selectable.rotation != 0 ? selectable.rotation : nil
            } else {
                rotation = nil
            }

            let item = TemplateManager.createRatioBasedItem(
                type: widgetType,
                frame: frame,
                canvasSize: canvasSize,
                color: color,
                font: font,
                payload: payload,
                rotation: rotation
            )
            items.append(item)
        }
        return items
    }
    
    func shareTemplate(fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = layoutTemplateButton
            popover.sourceRect = layoutTemplateButton.bounds
        }
        present(activityViewController, animated: true)
    }

    // MARK: - Helper Methods
    
    func applyItemStyles(to widget: any Selectable, item: WidgetItem) {
        if let colorHex = item.color, let color = TemplateManager.color(from: colorHex) {
            widget.applyColor(color)
        }

        if let fontName = item.font, let fontStyle = FontStyle(rawValue: fontName) {
            widget.applyFont(fontStyle)
        }
    }
}
