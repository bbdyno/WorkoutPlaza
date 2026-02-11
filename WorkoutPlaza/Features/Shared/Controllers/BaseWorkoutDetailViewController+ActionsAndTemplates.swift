//
//  BaseWorkoutDetailViewController+ActionsAndTemplates.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/10/26.
//

import UIKit
import PhotosUI

extension BaseWorkoutDetailViewController {

    @objc func cycleAspectRatio() {
        let allRatios = AspectRatio.allCases
        if let index = allRatios.firstIndex(of: currentAspectRatio) {
            let nextIndex = (index + 1) % allRatios.count
            currentAspectRatio = allRatios[nextIndex]
            aspectRatioButton.setTitle(currentAspectRatio.displayName, for: .normal)
            updateCanvasSize()
            showToast(WorkoutPlazaStrings.Toast.Aspect.ratio(currentAspectRatio.displayName))
        }
    }
    
    // Abstract method to be overridden
    @objc func showAddWidgetMenuBase() {
        let (_, widgets, _) = getToolSheetItems()
        guard !widgets.isEmpty else { return }

        var widgetActions: [ToolSheetHeaderAction] = []
        let marketConfig = FeaturePackManager.shared.widgetMarketButtonConfig(for: getSportType())
        if marketConfig.isEnabled {
            widgetActions.append(
                ToolSheetHeaderAction(title: marketConfig.title, iconName: "storefront") { [weak self] in
                    self?.showWidgetMarket()
                }
            )
        }

        let sections = [ToolSheetSection(title: WorkoutPlazaStrings.Sheet.Widget.add, items: widgets)]
        let sheetVC = ToolSheetViewController(sections: sections, toolbarActions: widgetActions)
        sheetVC.title = WorkoutPlazaStrings.Sheet.Widget.add
        presentAsSheet(sheetVC)
    }

    @objc func showTemplateMenu() {
        let (templates, _, templateActions) = getToolSheetItems()
        guard !templates.isEmpty else { return }

        let sections = [ToolSheetSection(title: WorkoutPlazaStrings.Sheet.Layout.templates, items: templates, columnCount: 2)]
        let sheetVC = ToolSheetViewController(sections: sections, toolbarActions: templateActions)
        sheetVC.title = WorkoutPlazaStrings.Sheet.Layout.templates
        presentAsSheet(sheetVC)
    }

    func presentAsSheet(_ viewController: UIViewController) {
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        present(nav, animated: true)
    }

    func captureContentView() -> UIImage? {
        // Use current aspect ratio for export
        let targetSize = currentAspectRatio.exportSize

        // Use high quality scale (3x for retina displays)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0  // High quality rendering
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // Calculate scale for rendering
        let renderScale = targetSize.width / contentView.bounds.width

        let image = renderer.image { context in
            // Scale context
            context.cgContext.scaleBy(x: renderScale, y: renderScale)

            // Render content view (which includes background, template, widgets, etc.)
            contentView.layer.render(in: context.cgContext)
        }

        return image
    }

    func presentShareSheet(image: UIImage) {
        // 카드 저장
        saveWorkoutCard(image: image)

        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        activityViewController.completionWithItemsHandler = { [weak self] activityType, completed, returnedItems, error in
            if completed && activityType == .saveToCameraRoll {
                // Image was saved to camera roll
                let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.Save.completed, message: WorkoutPlazaStrings.Alert.Image.saved, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
                self?.present(alert, animated: true)
            } else if let error = error {
                let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.Save.failed, message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
                self?.present(alert, animated: true)
            }
        }

        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = shareImageButton
            popover.sourceRect = shareImageButton.bounds
        }

        present(activityViewController, animated: true)
    }

    func presentPhotoPickerDefault() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    /// 현재 배경의 밝기에 따라 워터마크 색상을 자동으로 조정
    func updateWatermarkColorForBackground() {
        var isBackgroundLight = true // Default to light

        if !backgroundImageView.isHidden, let image = backgroundImageView.image {
            // Image background - calculate average brightness
            isBackgroundLight = image.isLight
        } else if !backgroundTemplateView.isHidden {
            // Gradient background - calculate average brightness of gradient colors
            let colors = backgroundTemplateView.getCurrentColors()
            if !colors.isEmpty {
                let totalBrightness = colors.reduce(0.0) { $0 + $1.perceivedBrightness }
                let averageBrightness = totalBrightness / CGFloat(colors.count)
                isBackgroundLight = averageBrightness > 0.5
            }
        } else {
            // No background (white default)
            isBackgroundLight = true
        }

        // Set watermark tint color based on background brightness
        watermarkImageView.tintColor = isBackgroundLight
            ? UIColor.black.withAlphaComponent(Constants.Layout.watermarkAlpha)
            : UIColor.white.withAlphaComponent(Constants.Layout.watermarkAlpha)
    }

    func useTemplateDefault() {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        dimOverlay.isHidden = true
        hasUnsavedChanges = true
        updateWatermarkColorForBackground()
    }

    func removeBackgroundDefault() {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = true
        dimOverlay.isHidden = true
        view.backgroundColor = .systemGroupedBackground
        hasUnsavedChanges = true
        updateWatermarkColorForBackground()
    }


    func presentCustomGradientPickerDefault() {
        let picker = CustomGradientPickerViewController()
        picker.delegate = self

        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.medium()]
        }

        present(picker, animated: true)
    }

    func iconForGradientDefault(colors: [UIColor]) -> UIImage? {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()

            if colors.count > 1 {
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { $0.cgColor } as CFArray, locations: [0, 1])!
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            } else {
                colors.first?.setFill()
                path.fill()

                if colors.first == .white {
                    UIColor.systemGray4.setStroke()
                    path.lineWidth = 1
                    path.stroke()
                }
            }
        }

        return image.withRenderingMode(.alwaysOriginal)
    }

    func applyTemplateDefault(_ style: BackgroundTemplateView.TemplateStyle) {
        backgroundImageView.isHidden = true
        backgroundTemplateView.isHidden = false
        backgroundTemplateView.applyTemplate(style)
        dimOverlay.isHidden = true
        hasUnsavedChanges = true
        updateWatermarkColorForBackground()
    }

}
