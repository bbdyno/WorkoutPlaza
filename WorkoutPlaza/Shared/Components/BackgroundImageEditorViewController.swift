//
//  BackgroundImageEditorViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit

protocol BackgroundImageEditorDelegate: AnyObject {
    func backgroundImageEditor(_ editor: BackgroundImageEditorViewController, didFinishEditing image: UIImage, transform: BackgroundTransform)
}

struct BackgroundTransform {
    var scale: CGFloat
    var offset: CGPoint
}

class BackgroundImageEditorViewController: UIViewController {
    private enum Constants {
        static let instructionLabelTopOffset: CGFloat = 8
        static let instructionLabelHeight: CGFloat = 32
        static let instructionLabelHorizontalPadding: CGFloat = 40
        static let overlayControlsTopOffset: CGFloat = 8
        static let overlayControlsHorizontalPadding: CGFloat = 20
        static let overlayControlsHeightExpanded: CGFloat = 128
        static let overlayControlsHeightCollapsed: CGFloat = 52
        static let overlayLabelTopOffset: CGFloat = 16
        static let overlayLabelLeadingOffset: CGFloat = 16
        static let overlayToggleTrailingOffset: CGFloat = 16
        static let colorPresetsTopOffset: CGFloat = 10
        static let colorPresetsHeight: CGFloat = 32
        static let colorPresetsLeadingOffset: CGFloat = 16
        static let colorPresetsTrailingOffset: CGFloat = 16
        static let opacitySliderTopOffset: CGFloat = 10
        static let opacityLabelWidth: CGFloat = 50
        static let colorSwatchSize: CGFloat = 32
    }

    // MARK: - Properties
    weak var delegate: BackgroundImageEditorDelegate?
    private let originalImage: UIImage
    private let canvasSize: CGSize

    private let containerView = UIView()
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let guideView = UIView()
    private let guideLayer = CAShapeLayer()

    private var initialTransform: BackgroundTransform?

    // MARK: - Overlay Controls
    private let overlayControlsContainer = UIView()
    private var overlayControlsHeightConstraint: Constraint?
    private let overlayToggle = UISwitch()
    private let overlayLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Background.Editor.overlay
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private var colorPresetsCollectionView: UICollectionView!

    private let opacitySlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = 0.5
        slider.minimumTrackTintColor = ColorSystem.primaryGreen
        slider.maximumTrackTintColor = ColorSystem.divider
        return slider
    }()

    private let opacityLabel: UILabel = {
        let label = UILabel()
        label.text = "50%"
        label.font = .systemFont(ofSize: 14)
        label.textColor = ColorSystem.subText
        label.textAlignment = .center
        return label
    }()

    // Overlay state
    private let overlayView = UIView()
    private var overlayEnabled = false
    private var overlayColor: UIColor = .black
    private var overlayOpacity: CGFloat = 0.5

    private let presetColors: [UIColor] = [
        .black, .white, .systemBlue, .systemRed,
        .systemGreen, .systemYellow, .systemPurple, .systemOrange
    ]

    private var instructionLabel: UILabel!

    // MARK: - Initialization
    init(image: UIImage, initialTransform: BackgroundTransform? = nil, canvasSize: CGSize = CGSize(width: 360, height: 640)) {
        self.originalImage = image
        self.initialTransform = initialTransform
        self.canvasSize = canvasSize
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImage()
    }

    // MARK: - Setup
    private func setupUI() {
        title = WorkoutPlazaStrings.Background.Editor.title
        view.backgroundColor = ColorSystem.background

        // Cancel button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        // Done button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )

        // Container View (Logic Size = Canvas Size)
        view.addSubview(containerView)
        containerView.frame = CGRect(origin: .zero, size: canvasSize)
        containerView.center = view.center
        containerView.clipsToBounds = true
        containerView.backgroundColor = .clear
        
        // Scroll View
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
        containerView.addSubview(scrollView)
        scrollView.frame = containerView.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Image view setup
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)
        
        // Guide View (Dashed Border)
        containerView.addSubview(guideView)
        guideView.frame = containerView.bounds
        guideView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        guideView.isUserInteractionEnabled = false // Pass touches to scroll view
        
        setupGuideLayer()

        // Instructions label
        instructionLabel = UILabel()
        instructionLabel.text = WorkoutPlazaStrings.Background.Editor.instruction
        instructionLabel.textColor = ColorSystem.subText
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textAlignment = .center
//        instructionLabel.backgroundColor = ColorSystem.cardBackground.withAlphaComponent(0.95)
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true

        view.addSubview(instructionLabel)
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.instructionLabelTopOffset)
            make.centerX.equalToSuperview()
            make.height.equalTo(Constants.instructionLabelHeight)
            make.width.lessThanOrEqualToSuperview().offset(-Constants.instructionLabelHorizontalPadding)
        }

        // Setup overlay controls
        setupOverlayControls()
    }
    
    private func setupGuideLayer() {
        guideLayer.strokeColor = ColorSystem.primaryGreen.cgColor
        guideLayer.fillColor = nil
        guideLayer.lineWidth = 2
        guideLayer.lineDashPattern = [6, 4]
        guideView.layer.addSublayer(guideLayer)
    }

    private func setupOverlayControls() {
        // Container setup
        overlayControlsContainer.backgroundColor = ColorSystem.cardBackground.withAlphaComponent(0.95)
        overlayControlsContainer.layer.cornerRadius = 16
        view.addSubview(overlayControlsContainer)

        // Toggle
        overlayToggle.isOn = false
        overlayToggle.onTintColor = ColorSystem.primaryGreen
        overlayToggle.addTarget(self, action: #selector(overlayToggleChanged), for: .valueChanged)
        overlayControlsContainer.addSubview(overlayLabel)
        overlayControlsContainer.addSubview(overlayToggle)

        // Collection view for color presets
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.itemSize = CGSize(width: Constants.colorSwatchSize, height: Constants.colorSwatchSize)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        colorPresetsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        colorPresetsCollectionView.backgroundColor = .clear
        colorPresetsCollectionView.delegate = self
        colorPresetsCollectionView.dataSource = self
        colorPresetsCollectionView.showsHorizontalScrollIndicator = false
        colorPresetsCollectionView.register(ColorSwatchCell.self, forCellWithReuseIdentifier: "ColorSwatchCell")
        colorPresetsCollectionView.register(CustomColorCell.self, forCellWithReuseIdentifier: "CustomColorCell")
        colorPresetsCollectionView.isHidden = true
        colorPresetsCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        overlayControlsContainer.addSubview(colorPresetsCollectionView)

        // Opacity slider
        opacitySlider.addTarget(self, action: #selector(opacitySliderChanged), for: .valueChanged)
        opacitySlider.isHidden = true
        overlayControlsContainer.addSubview(opacitySlider)

        opacityLabel.isHidden = true
        overlayControlsContainer.addSubview(opacityLabel)

        // Layout constraints
        overlayControlsContainer.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(Constants.overlayControlsTopOffset)
            make.leading.equalToSuperview().offset(Constants.overlayControlsHorizontalPadding)
            make.trailing.equalToSuperview().offset(-Constants.overlayControlsHorizontalPadding)
            overlayControlsHeightConstraint = make.height.equalTo(Constants.overlayControlsHeightCollapsed).constraint
        }

        overlayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.overlayLabelTopOffset)
            make.leading.equalToSuperview().offset(Constants.overlayLabelLeadingOffset)
        }

        overlayToggle.snp.makeConstraints { make in
            make.centerY.equalTo(overlayLabel)
            make.trailing.equalToSuperview().offset(-Constants.overlayToggleTrailingOffset)
        }

        colorPresetsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(overlayLabel.snp.bottom).offset(Constants.colorPresetsTopOffset)
            make.leading.equalToSuperview().offset(Constants.colorPresetsLeadingOffset)
            make.trailing.equalToSuperview().offset(-Constants.colorPresetsTrailingOffset)
            make.height.equalTo(Constants.colorPresetsHeight)
        }

        opacitySlider.snp.makeConstraints { make in
            make.top.equalTo(colorPresetsCollectionView.snp.bottom).offset(Constants.opacitySliderTopOffset)
            make.leading.equalToSuperview().offset(Constants.overlayLabelLeadingOffset)
            make.trailing.equalTo(opacityLabel.snp.leading).offset(-8)
        }

        opacityLabel.snp.makeConstraints { make in
            make.centerY.equalTo(opacitySlider)
            make.trailing.equalToSuperview().offset(-Constants.overlayToggleTrailingOffset)
            make.width.equalTo(Constants.opacityLabelWidth)
        }

        // Setup overlay view
        overlayView.isHidden = true
        overlayView.isUserInteractionEnabled = false
        scrollView.addSubview(overlayView)
    }

    private func setupImage() {
        imageView.image = originalImage

        // Calculate image size to fill the canvas
        let imageSize = originalImage.size

        let widthRatio = canvasSize.width / imageSize.width
        let heightRatio = canvasSize.height / imageSize.height
        let scale = max(widthRatio, heightRatio)

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        imageView.frame = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        scrollView.contentSize = CGSize(width: scaledWidth, height: scaledHeight)

        // Center the image
        centerImage()

        // Apply initial transform if provided
        if let initialTransform = initialTransform {
            scrollView.zoomScale = initialTransform.scale
            scrollView.contentOffset = initialTransform.offset
        } else {
            scrollView.zoomScale = 1.0
        }

        updateOverlayView()
    }

    private func centerImage() {
        let scrollViewSize = scrollView.bounds.size
        let imageSize = imageView.frame.size

        let horizontalInset = max(0, (scrollViewSize.width - imageSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageSize.height) / 2)

        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }

    // MARK: - Overlay Methods
    @objc private func overlayToggleChanged() {
        overlayEnabled = overlayToggle.isOn

        // Update height constraint
        let newHeight = overlayEnabled ? Constants.overlayControlsHeightExpanded : Constants.overlayControlsHeightCollapsed
        overlayControlsHeightConstraint?.update(offset: newHeight)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.colorPresetsCollectionView.alpha = self.overlayEnabled ? 1.0 : 0.0
            self.opacitySlider.alpha = self.overlayEnabled ? 1.0 : 0.0
            self.opacityLabel.alpha = self.overlayEnabled ? 1.0 : 0.0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.colorPresetsCollectionView.isHidden = !self.overlayEnabled
            self.opacitySlider.isHidden = !self.overlayEnabled
            self.opacityLabel.isHidden = !self.overlayEnabled
        }

        updateOverlayView()
    }

    @objc private func opacitySliderChanged(_ slider: UISlider) {
        overlayOpacity = CGFloat(slider.value)
        opacityLabel.text = "\(Int(slider.value * 100))%"

        if overlayEnabled {
            updateOverlayView()
        }
    }

    @objc private func selectCustomColor() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = overlayColor
        picker.delegate = self
        present(picker, animated: true)
    }

    private func updateOverlayView() {
        guard overlayEnabled else {
            overlayView.isHidden = true
            return
        }

        overlayView.isHidden = false
        overlayView.backgroundColor = overlayColor.withAlphaComponent(overlayOpacity)
        overlayView.frame = imageView.frame
    }

    private func composeImageWithOverlay() -> UIImage? {
        let imageSize = originalImage.size

        let format = UIGraphicsImageRendererFormat()
        format.scale = originalImage.scale
        format.opaque = false // Allow transparency for overlay

        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)

        let composedImage = renderer.image { rendererContext in
            let cgContext = rendererContext.cgContext

            // Draw original image
            originalImage.draw(at: .zero)

            // Draw overlay with specified color and opacity
            cgContext.setFillColor(overlayColor.withAlphaComponent(overlayOpacity).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: imageSize))
        }

        return composedImage
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        let transform = BackgroundTransform(
            scale: scrollView.zoomScale,
            offset: scrollView.contentOffset
        )

        // Compose final image with overlay if enabled
        let finalImage: UIImage
        if overlayEnabled {
            finalImage = composeImageWithOverlay() ?? originalImage
        } else {
            finalImage = originalImage
        }

        delegate?.backgroundImageEditor(self, didFinishEditing: finalImage, transform: transform)
        dismiss(animated: true)
    }

    // MARK: - Layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update guide layer frame
        guideLayer.frame = guideView.bounds
        guideLayer.path = UIBezierPath(rect: guideView.bounds).cgPath
        
        // Scale container to fit screen if needed
        let safeArea = view.safeAreaLayoutGuide.layoutFrame
        let availableSize = CGSize(
            width: safeArea.width - 40,
            height: safeArea.height - 200 // Increased space for overlay controls
        )

        let scaleX = availableSize.width / canvasSize.width
        let scaleY = availableSize.height / canvasSize.height
        let scale = min(1.0, min(scaleX, scaleY))

        containerView.transform = CGAffineTransform(scaleX: scale, y: scale)
        containerView.center = CGPoint(x: safeArea.midX, y: safeArea.midY + 60) // Offset for overlay controls

        centerImage()
        updateOverlayView()
    }
}

// MARK: - UIScrollViewDelegate
extension BackgroundImageEditorViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
        updateOverlayView()
    }
}

// MARK: - UICollectionViewDataSource
extension BackgroundImageEditorViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presetColors.count + 1 // +1 for custom color button
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Last item is the custom color button
        if indexPath.item == presetColors.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomColorCell", for: indexPath) as! CustomColorCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorSwatchCell", for: indexPath) as! ColorSwatchCell
            cell.configure(with: presetColors[indexPath.item])
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension BackgroundImageEditorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Last item is the custom color button
        if indexPath.item == presetColors.count {
            selectCustomColor()
        } else {
            overlayColor = presetColors[indexPath.item]
            if overlayEnabled {
                updateOverlayView()
            }
        }
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension BackgroundImageEditorViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        overlayColor = viewController.selectedColor
        if overlayEnabled {
            updateOverlayView()
        }
    }
}

// MARK: - CustomColorCell
class CustomColorCell: UICollectionViewCell {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "eyedropper.halffull")
        imageView.tintColor = ColorSystem.primaryGreen
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.backgroundColor = ColorSystem.cardBackgroundHighlight
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1.5
        contentView.layer.borderColor = ColorSystem.divider.cgColor

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.layer.borderColor = ColorSystem.primaryGreen.cgColor
                contentView.layer.borderWidth = 2
            } else {
                contentView.layer.borderColor = ColorSystem.divider.cgColor
                contentView.layer.borderWidth = 1.5
            }
        }
    }
}
