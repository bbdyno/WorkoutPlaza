//
//  BackgroundImageEditorViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

protocol BackgroundImageEditorDelegate: AnyObject {
    func backgroundImageEditor(_ editor: BackgroundImageEditorViewController, didFinishEditing image: UIImage, transform: BackgroundTransform)
}

struct BackgroundTransform {
    var scale: CGFloat
    var offset: CGPoint
}

class BackgroundImageEditorViewController: UIViewController {

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
    private let overlayToggle = UISwitch()
    private let overlayLabel: UILabel = {
        let label = UILabel()
        label.text = "색상 오버레이"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        return label
    }()

    private var colorPresetsCollectionView: UICollectionView!
    private let customColorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("커스텀", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .systemGray5
        button.layer.cornerRadius = 8
        return button
    }()

    private let opacitySlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = 0.5
        return slider
    }()

    private let opacityLabel: UILabel = {
        let label = UILabel()
        label.text = "50%"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
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
        title = "배경 편집"
        view.backgroundColor = .black

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
        // Shadow for better visibility against black background
        containerView.layer.shadowColor = UIColor.white.withAlphaComponent(0.3).cgColor
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowRadius = 0
        containerView.layer.shadowOffset = .zero
        
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
        instructionLabel.text = "핀치로 확대/축소, 드래그로 이동하세요"
        instructionLabel.textColor = .white
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textAlignment = .center
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true

        view.addSubview(instructionLabel)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.heightAnchor.constraint(equalToConstant: 32),
            instructionLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40)
        ])

        // Setup overlay controls
        setupOverlayControls()
    }
    
    private func setupGuideLayer() {
        guideLayer.strokeColor = UIColor.white.cgColor
        guideLayer.fillColor = nil
        guideLayer.lineWidth = 2
        guideLayer.lineDashPattern = [6, 4]
        guideView.layer.addSublayer(guideLayer)
    }

    private func setupOverlayControls() {
        // Container setup
        overlayControlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        overlayControlsContainer.layer.cornerRadius = 12
        view.addSubview(overlayControlsContainer)
        overlayControlsContainer.translatesAutoresizingMaskIntoConstraints = false

        // Toggle
        overlayToggle.isOn = false
        overlayToggle.addTarget(self, action: #selector(overlayToggleChanged), for: .valueChanged)
        overlayControlsContainer.addSubview(overlayLabel)
        overlayControlsContainer.addSubview(overlayToggle)
        overlayLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayToggle.translatesAutoresizingMaskIntoConstraints = false

        // Collection view for color presets
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.itemSize = CGSize(width: 36, height: 36)

        colorPresetsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        colorPresetsCollectionView.backgroundColor = .clear
        colorPresetsCollectionView.delegate = self
        colorPresetsCollectionView.dataSource = self
        colorPresetsCollectionView.showsHorizontalScrollIndicator = false
        colorPresetsCollectionView.register(ColorSwatchCell.self, forCellWithReuseIdentifier: "ColorSwatchCell")
        colorPresetsCollectionView.isHidden = true
        overlayControlsContainer.addSubview(colorPresetsCollectionView)
        colorPresetsCollectionView.translatesAutoresizingMaskIntoConstraints = false

        // Custom color button
        customColorButton.addTarget(self, action: #selector(selectCustomColor), for: .touchUpInside)
        customColorButton.isHidden = true
        overlayControlsContainer.addSubview(customColorButton)
        customColorButton.translatesAutoresizingMaskIntoConstraints = false

        // Opacity slider
        opacitySlider.addTarget(self, action: #selector(opacitySliderChanged), for: .valueChanged)
        opacitySlider.isHidden = true
        overlayControlsContainer.addSubview(opacitySlider)
        opacitySlider.translatesAutoresizingMaskIntoConstraints = false

        opacityLabel.isHidden = true
        overlayControlsContainer.addSubview(opacityLabel)
        opacityLabel.translatesAutoresizingMaskIntoConstraints = false

        // Layout constraints
        NSLayoutConstraint.activate([
            // Container
            overlayControlsContainer.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            overlayControlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            overlayControlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            overlayControlsContainer.heightAnchor.constraint(equalToConstant: 140),

            // Toggle row
            overlayLabel.topAnchor.constraint(equalTo: overlayControlsContainer.topAnchor, constant: 12),
            overlayLabel.leadingAnchor.constraint(equalTo: overlayControlsContainer.leadingAnchor, constant: 16),

            overlayToggle.centerYAnchor.constraint(equalTo: overlayLabel.centerYAnchor),
            overlayToggle.trailingAnchor.constraint(equalTo: overlayControlsContainer.trailingAnchor, constant: -16),

            // Color presets row
            colorPresetsCollectionView.topAnchor.constraint(equalTo: overlayLabel.bottomAnchor, constant: 12),
            colorPresetsCollectionView.leadingAnchor.constraint(equalTo: overlayControlsContainer.leadingAnchor, constant: 16),
            colorPresetsCollectionView.heightAnchor.constraint(equalToConstant: 40),
            colorPresetsCollectionView.trailingAnchor.constraint(equalTo: customColorButton.leadingAnchor, constant: -8),

            customColorButton.centerYAnchor.constraint(equalTo: colorPresetsCollectionView.centerYAnchor),
            customColorButton.trailingAnchor.constraint(equalTo: overlayControlsContainer.trailingAnchor, constant: -16),
            customColorButton.widthAnchor.constraint(equalToConstant: 70),
            customColorButton.heightAnchor.constraint(equalToConstant: 36),

            // Opacity row
            opacitySlider.topAnchor.constraint(equalTo: colorPresetsCollectionView.bottomAnchor, constant: 12),
            opacitySlider.leadingAnchor.constraint(equalTo: overlayControlsContainer.leadingAnchor, constant: 16),
            opacitySlider.trailingAnchor.constraint(equalTo: opacityLabel.leadingAnchor, constant: -8),

            opacityLabel.centerYAnchor.constraint(equalTo: opacitySlider.centerYAnchor),
            opacityLabel.trailingAnchor.constraint(equalTo: overlayControlsContainer.trailingAnchor, constant: -16),
            opacityLabel.widthAnchor.constraint(equalToConstant: 50)
        ])

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

        UIView.animate(withDuration: 0.25) {
            self.colorPresetsCollectionView.isHidden = !self.overlayEnabled
            self.customColorButton.isHidden = !self.overlayEnabled
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
        return presetColors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorSwatchCell", for: indexPath) as! ColorSwatchCell
        cell.configure(with: presetColors[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension BackgroundImageEditorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        overlayColor = presetColors[indexPath.item]
        if overlayEnabled {
            updateOverlayView()
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
