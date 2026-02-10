//
//  BaseWorkoutDetailViewController+UISetup.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/10/26.
//

import UIKit
import SnapKit

extension BaseWorkoutDetailViewController {

    func setupCommonViews() {
        view.addSubview(instructionLabel)
        view.addSubview(canvasContainerView)
        canvasContainerView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(backgroundTemplateView)
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(dimOverlay)
        contentView.addSubview(watermarkImageView)
        contentView.addSubview(textPathDrawingOverlayView)
        contentView.addSubview(verticalCenterGuideView)
        contentView.addSubview(horizontalCenterGuideView)

        view.addSubview(topRightToolbar)
        view.addSubview(bottomFloatingToolbar)
        view.addSubview(multiSelectToolbar)
        view.addSubview(textPathDrawingToolbar)
        textPathDrawingToolbar.addSubview(textPathConfirmButton)
        textPathDrawingToolbar.addSubview(textPathRedrawButton)
        view.addSubview(toastLabel)
        view.addSubview(textPathColorPanel)
        view.addSubview(textPathFontPanel)
        view.addSubview(textPathSizePanel)

        setupTopRightToolbar()
        setupBottomFloatingToolbar()
        setupTextPathDrawingToolbar()
        setupTextPathFloatingPanels()
        
        // Background tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tapGesture)
        
        updateCanvasSize()
    }
    
    func setupConstraints() {
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.instructionTopOffset)
            make.leading.trailing.equalToSuperview().inset(Constants.Layout.horizontalPadding)
        }
        
        canvasContainerView.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(Constants.Layout.canvasTopOffset)
            make.centerX.equalToSuperview()
            // Initial constraints, will be updated by updateCanvasSize
            canvasWidthConstraint = make.width.equalTo(Constants.Layout.canvasInitialWidth).constraint
            canvasHeightConstraint = make.height.equalTo(Constants.Layout.canvasInitialHeight).constraint
        }
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalToSuperview()
        }
        
        backgroundTemplateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // backgroundImageView frame is set manually in updateCanvasSize
        
        dimOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        watermarkImageView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(Constants.Layout.watermarkInset)
            make.trailing.equalToSuperview().inset(Constants.Layout.watermarkInset)
            make.width.equalTo(Constants.Layout.watermarkSize)
            make.height.equalTo(Constants.Layout.watermarkSize)
        }

        textPathDrawingOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        verticalCenterGuideView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(Constants.centerGuideThickness)
        }

        horizontalCenterGuideView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(Constants.centerGuideThickness)
        }

        topRightToolbar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.topToolbarTopOffset)
            make.trailing.equalToSuperview().inset(Constants.Layout.topToolbarTrailingMargin)
        }
        
        bottomFloatingToolbar.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.bottomToolbarBottomOffset)
            make.centerX.equalToSuperview()
            make.height.equalTo(Constants.Layout.bottomToolbarHeight)
        }
        
        multiSelectToolbar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.multiSelectToolbarBottomOffset)
            make.height.equalTo(Constants.Layout.multiSelectToolbarHeight)
            make.width.equalTo(Constants.Layout.multiSelectToolbarWidth)
        }
        
        toastLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.Layout.toastTopOffset)
            make.width.greaterThanOrEqualTo(100)
            make.height.equalTo(Constants.Layout.toastHeight)
        }

        textPathDrawingToolbar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(Constants.Layout.textPathToolbarHeight)
        }

        textPathConfirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(8)
            make.size.equalTo(40)
        }

        textPathRedrawButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(8)
            make.size.equalTo(40)
        }
    }

    func setupBottomFloatingToolbar() {
        let stack = UIStackView(arrangedSubviews: [colorPickerButton, fontPickerButton, alignmentButton, deleteItemButton])
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .center

        bottomFloatingToolbar.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Constants.Layout.bottomToolbarPadding)
        }
    }

    func setupTextPathDrawingToolbar() {
        // MARK: - Main Control Buttons
        // Color Button (Circle)
        let colorButtonContainer = UIView()
        let colorLabel = UILabel()
        colorLabel.text = NSLocalizedString("ui.color", comment: "")
        colorLabel.textColor = .white
        colorLabel.font = .systemFont(ofSize: 11, weight: .medium)
        colorLabel.textAlignment = .center

        let textPathColorMainButton = UIButton(type: .custom)
        textPathColorMainButton.backgroundColor = .white
        textPathColorMainButton.layer.cornerRadius = 16
        textPathColorMainButton.layer.borderWidth = 2
        textPathColorMainButton.layer.borderColor = UIColor.gray.cgColor
        textPathColorMainButton.tag = 9000
        textPathColorMainButton.addTarget(self, action: #selector(textPathColorMainButtonTapped(_:)), for: .touchUpInside)

        colorButtonContainer.addSubview(textPathColorMainButton)
        colorButtonContainer.addSubview(colorLabel)

        colorButtonContainer.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
        textPathColorMainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.size.equalTo(32)
        }
        colorLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(textPathColorMainButton.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }

        // Font Button
        let fontButtonContainer = UIView()
        let fontLabel = UILabel()
        fontLabel.text = WorkoutPlazaStrings.Ui.font
        fontLabel.textColor = .white
        fontLabel.font = .systemFont(ofSize: 11, weight: .medium)
        fontLabel.textAlignment = .center

        let textPathFontMainButton = UIButton(type: .system)
        textPathFontMainButton.setTitle(WorkoutPlazaStrings.Ui.Font.default, for: .normal)
        textPathFontMainButton.setTitleColor(.white, for: .normal)
        textPathFontMainButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        textPathFontMainButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        textPathFontMainButton.layer.cornerRadius = 8
        textPathFontMainButton.layer.borderWidth = 2
        textPathFontMainButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        textPathFontMainButton.tag = 9001
        textPathFontMainButton.addTarget(self, action: #selector(textPathFontMainButtonTapped(_:)), for: .touchUpInside)

        fontButtonContainer.addSubview(textPathFontMainButton)
        fontButtonContainer.addSubview(fontLabel)

        fontButtonContainer.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
        textPathFontMainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(55)
            make.height.equalTo(32)
        }
        fontLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(textPathFontMainButton.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }

        // Size Button
        let sizeButtonContainer = UIView()
        let sizeLabel = UILabel()
        sizeLabel.text = NSLocalizedString("ui.size", comment: "")
        sizeLabel.textColor = .white
        sizeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        sizeLabel.textAlignment = .center

        let textPathSizeMainButton = UIButton(type: .system)
        textPathSizeMainButton.setTitle("20", for: .normal)
        textPathSizeMainButton.setTitleColor(.white, for: .normal)
        textPathSizeMainButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        textPathSizeMainButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        textPathSizeMainButton.layer.cornerRadius = 8
        textPathSizeMainButton.layer.borderWidth = 2
        textPathSizeMainButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        textPathSizeMainButton.tag = 9002
        textPathSizeMainButton.addTarget(self, action: #selector(textPathSizeMainButtonTapped(_:)), for: .touchUpInside)

        sizeButtonContainer.addSubview(textPathSizeMainButton)
        sizeButtonContainer.addSubview(sizeLabel)

        sizeButtonContainer.snp.makeConstraints { make in
            make.width.equalTo(50)
        }
        textPathSizeMainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(45)
            make.height.equalTo(32)
        }
        sizeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(textPathSizeMainButton.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }

        // Mode Button (자유곡선/직선 토글)
        let modeButtonContainer = UIView()
        let modeLabel = UILabel()
        modeLabel.text = WorkoutPlazaStrings.Ui.mode
        modeLabel.textColor = .white
        modeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        modeLabel.textAlignment = .center

        let textPathModeMainButton = UIButton(type: .system)
        textPathModeMainButton.setImage(UIImage(systemName: "scribble"), for: .normal)
        textPathModeMainButton.tintColor = .white
        textPathModeMainButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        textPathModeMainButton.layer.cornerRadius = 16
        textPathModeMainButton.layer.borderWidth = 2
        textPathModeMainButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        textPathModeMainButton.tag = 9003
        textPathModeMainButton.addTarget(self, action: #selector(textPathModeButtonTapped(_:)), for: .touchUpInside)

        modeButtonContainer.addSubview(textPathModeMainButton)
        modeButtonContainer.addSubview(modeLabel)

        modeButtonContainer.snp.makeConstraints { make in
            make.width.equalTo(50)
        }
        textPathModeMainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.size.equalTo(32)
        }
        modeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(textPathModeMainButton.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }

        let buttonStack = UIStackView(arrangedSubviews: [modeButtonContainer, colorButtonContainer, fontButtonContainer, sizeButtonContainer])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 32
        buttonStack.alignment = .top
        buttonStack.distribution = .fill

        textPathDrawingToolbar.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.lessThanOrEqualToSuperview().offset(-20)
        }

        // Setup button actions
        textPathConfirmButton.addTarget(self, action: #selector(textPathConfirmTapped), for: .touchUpInside)
        textPathRedrawButton.addTarget(self, action: #selector(textPathRedrawTapped), for: .touchUpInside)
    }

    func setupTextPathFloatingPanels() {
        let availableColors: [UIColor] = [
            .white, .systemYellow, .systemOrange, .systemPink,
            .systemRed, .systemGreen, .systemBlue, .systemPurple
        ]

        let availableFonts: [(name: String, font: UIFont)] = [
            (WorkoutPlazaStrings.Ui.Font.default, .boldSystemFont(ofSize: 20)),
            (WorkoutPlazaStrings.Ui.Font.thin, .systemFont(ofSize: 20, weight: .light)),
            (WorkoutPlazaStrings.Ui.Font.rounded, .systemFont(ofSize: 20, weight: .medium)),
            (WorkoutPlazaStrings.Ui.Font.bold, .systemFont(ofSize: 20, weight: .black))
        ]

        // Color Panel Content

        let colorScrollView = UIScrollView()
        colorScrollView.showsHorizontalScrollIndicator = false
        colorScrollView.alwaysBounceHorizontal = true
        
        let colorStackView = UIStackView()
        colorStackView.axis = .horizontal
        colorStackView.spacing = 16
        colorStackView.alignment = .center
        
        textPathColorButtons.removeAll()

        for (index, color) in availableColors.enumerated() {
            let button = UIButton(type: .custom)
            button.backgroundColor = color
            button.layer.cornerRadius = 16
            button.layer.borderWidth = 3
            button.layer.borderColor = UIColor.clear.cgColor
            button.tag = index
            button.addTarget(self, action: #selector(textPathColorButtonTapped(_:)), for: .touchUpInside)

            button.snp.makeConstraints { make in
                make.size.equalTo(32)
            }

            textPathColorButtons.append(button)
            colorStackView.addArrangedSubview(button)
        }

        // Add indicators
        let leftIndicator = UIImageView(image: UIImage(systemName: "chevron.left"))
        leftIndicator.tintColor = UIColor.white.withAlphaComponent(0.5)
        leftIndicator.contentMode = .scaleAspectFit
        
        let rightIndicator = UIImageView(image: UIImage(systemName: "chevron.right"))
        rightIndicator.tintColor = UIColor.white.withAlphaComponent(0.5)
        rightIndicator.contentMode = .scaleAspectFit
        
        textPathColorPanel.addSubview(leftIndicator)
        textPathColorPanel.addSubview(rightIndicator)
        textPathColorPanel.addSubview(colorScrollView)
        
        colorScrollView.addSubview(colorStackView)
        
        leftIndicator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(6)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        
        rightIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        
        colorScrollView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(leftIndicator.snp.trailing).offset(4)
            make.trailing.equalTo(rightIndicator.snp.leading).offset(-4)
        }
        
        colorStackView.snp.makeConstraints { make in
            make.edges.equalTo(colorScrollView.contentLayoutGuide)
            make.height.equalTo(colorScrollView.frameLayoutGuide)
            make.leading.trailing.equalToSuperview().inset(4) // Padding inside scroll view
        }

        // Font Panel Content
        let fontStackView = UIStackView()
        fontStackView.axis = .horizontal
        fontStackView.spacing = 8
        fontStackView.alignment = .center
        fontStackView.distribution = .fillEqually
        
        textPathFontButtons.removeAll()

        for (index, fontInfo) in availableFonts.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(fontInfo.name, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            button.layer.cornerRadius = 8
            button.tag = index
            button.addTarget(self, action: #selector(textPathFontButtonTapped(_:)), for: .touchUpInside)

            textPathFontButtons.append(button)
            fontStackView.addArrangedSubview(button)
        }

        textPathFontPanel.addSubview(fontStackView)
        fontStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        // Size Panel Content
        let sliderContainer = UIView()
        let fontSizeSlider = UISlider()
        fontSizeSlider.minimumValue = 8
        fontSizeSlider.maximumValue = 40
        fontSizeSlider.value = Float(textPathSelectedFontSize)
        fontSizeSlider.minimumTrackTintColor = .white
        fontSizeSlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        fontSizeSlider.addTarget(self, action: #selector(textPathFontSizeChanged(_:)), for: .valueChanged)
        
        let fontSizeLabel = UILabel()
        fontSizeLabel.text = "\(Int(textPathSelectedFontSize))"
        fontSizeLabel.textColor = .white
        fontSizeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        fontSizeLabel.textAlignment = .center
        fontSizeLabel.tag = 999

        let sizeIcon = UIImageView(image: UIImage(systemName: "textformat.size"))
        sizeIcon.tintColor = .white
        sizeIcon.contentMode = .scaleAspectFit
        
        sliderContainer.addSubview(sizeIcon)
        sliderContainer.addSubview(fontSizeSlider)
        sliderContainer.addSubview(fontSizeLabel)
        
        sizeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        fontSizeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(30)
        }
        fontSizeSlider.snp.makeConstraints { make in
            make.leading.equalTo(sizeIcon.snp.trailing).offset(12)
            make.trailing.equalTo(fontSizeLabel.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        
        textPathSizePanel.addSubview(sliderContainer)
        sliderContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.height.equalTo(40)
            make.width.equalTo(200)
        }

        // Initial selection
        updateTextPathColorSelection()
        updateTextPathFontSelection()
    }


    func setupMultiSelectToolbarConfig() {
        let stack = UIStackView(arrangedSubviews: [groupButton, ungroupButton])
        stack.axis = .horizontal
        stack.spacing = 16
        
        multiSelectToolbar.addSubview(multiSelectCountLabel)
        multiSelectToolbar.addSubview(stack)
        multiSelectToolbar.addSubview(cancelMultiSelectButton)
        
        multiSelectCountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        cancelMultiSelectButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(34)
        }
    }
    

    func createToolbarButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.3, alpha: 0.8)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: action, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
        return button
    }
    
    func showToast(_ message: String) {
        toastLabel.text = "  \(message)  "
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.toastLabel.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut) {
                self.toastLabel.alpha = 0
            }
        }
    }
    
    func setupDefaultBackground() {
        backgroundTemplateView.applyTemplate(.gradient1)
        backgroundImageView.isHidden = true
    }

}
