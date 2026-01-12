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
        let instructionLabel = UILabel()
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
    }
    
    private func setupGuideLayer() {
        guideLayer.strokeColor = UIColor.white.cgColor
        guideLayer.fillColor = nil
        guideLayer.lineWidth = 2
        guideLayer.lineDashPattern = [6, 4]
        guideView.layer.addSublayer(guideLayer)
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

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        let transform = BackgroundTransform(
            scale: scrollView.zoomScale,
            offset: scrollView.contentOffset
        )

        delegate?.backgroundImageEditor(self, didFinishEditing: originalImage, transform: transform)
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
            height: safeArea.height - 100 // Space for label and buttons
        )
        
        let scaleX = availableSize.width / canvasSize.width
        let scaleY = availableSize.height / canvasSize.height
        let scale = min(1.0, min(scaleX, scaleY))
        
        containerView.transform = CGAffineTransform(scaleX: scale, y: scale)
        containerView.center = CGPoint(x: safeArea.midX, y: safeArea.midY)
        
        centerImage()
    }
}

// MARK: - UIScrollViewDelegate
extension BackgroundImageEditorViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
