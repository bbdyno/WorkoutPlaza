//
//  LocationWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

//
//  LocationWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import CoreLocation
import SnapKit

// MARK: - Location Widget
class LocationWidget: UIView, Selectable {

    // MARK: - Selectable Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .label {
        didSet {
            updateColors()
        }
    }
    var currentFontStyle: FontStyle = .system {
        didSet {
            updateFonts()
        }
    }
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?

    // Font scaling properties
    var initialSize: CGSize = .zero
    var baseFontSize: CGFloat = 18
    var isGroupManaged: Bool = false  // Prevents auto font scaling when inside a group

    // Movement properties
    private var initialCenter: CGPoint = .zero

    // MARK: - UI Components
    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        return imageView
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .label
        label.textAlignment = .left
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear

        // Setup icon
        iconImageView.image = UIImage(systemName: "location.fill")

        // Add to stack
        containerStack.addArrangedSubview(iconImageView)
        containerStack.addArrangedSubview(locationLabel)

        addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }

        // Set default text
        locationLabel.text = "위치 로딩중..."
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)

        isUserInteractionEnabled = true
    }

    // MARK: - Configuration
    func configure(location: CLLocation, completion: @escaping (Bool) -> Void) {
        locationLabel.text = "위치 로딩중..."

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Geocoding failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.locationLabel.text = "위치 정보 없음"
                    completion(false)
                }
                return
            }

            guard let placemark = placemarks?.first else {
                DispatchQueue.main.async {
                    self.locationLabel.text = "위치 정보 없음"
                    completion(false)
                }
                return
            }

            let cityName = self.formatKoreanAddress(from: placemark)

            DispatchQueue.main.async {
                self.locationLabel.text = cityName
                self.initialSize = self.bounds.size
                self.updateFonts()
                completion(true)
            }
        }
    }

    // MARK: - Korean Address Formatting
    private func formatKoreanAddress(from placemark: CLPlacemark) -> String {
        // administrativeArea: 경기도, 서울특별시, 부산광역시, etc.
        // locality: 수원시, 서울, 부산, etc.
        // subLocality: 팔달구, 강남구, etc.

        let administrativeArea = placemark.administrativeArea ?? ""
        let locality = placemark.locality ?? ""

        // Special cities (특별시/광역시) - use full name
        let specialCities = ["서울특별시", "부산광역시", "대구광역시", "인천광역시",
                            "광주광역시", "대전광역시", "울산광역시", "세종특별자치시"]

        if specialCities.contains(administrativeArea) {
            return administrativeArea
        }

        // Province + City (도 + 시)
        if administrativeArea.hasSuffix("도") && locality.hasSuffix("시") {
            return "\(administrativeArea) \(locality)"
        }

        // County/smaller units - use province only
        if administrativeArea.hasSuffix("도") {
            return administrativeArea
        }

        // Fallback: use whatever is available
        if !locality.isEmpty {
            return locality
        }

        if !administrativeArea.isEmpty {
            return administrativeArea
        }

        return "위치 정보 없음"
    }

    // MARK: - Gesture Handlers
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view, let superview = view.superview else { return }

        switch gesture.state {
        case .began:
            initialCenter = view.center
            // Select this widget immediately when drag starts
            if !isSelected {
                selectionDelegate?.itemWasSelected(self)
            }

        case .changed:
            let translation = gesture.translation(in: superview)
            let proposedCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )

            let snapStep: CGFloat = 5.0
            let width = view.frame.width
            let height = view.frame.height

            let proposedOriginX = proposedCenter.x - width / 2
            let proposedOriginY = proposedCenter.y - height / 2

            let snappedOriginX = round(proposedOriginX / snapStep) * snapStep
            let snappedOriginY = round(proposedOriginY / snapStep) * snapStep

            let snappedCenter = CGPoint(
                x: snappedOriginX + width / 2,
                y: snappedOriginY + height / 2
            )

            view.center = snappedCenter

            if isSelected {
                positionResizeHandles()
            }

        case .ended, .cancelled:
            NotificationCenter.default.post(name: .widgetDidMove, object: nil)

        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0

            updateFontsFromTransform()

            if isSelected {
                positionResizeHandles()
            }
        }
    }

    private func updateFontsFromTransform() {
        let scaleX = sqrt(transform.a * transform.a + transform.c * transform.c)
        let scaleY = sqrt(transform.b * transform.b + transform.d * transform.d)
        let averageScale = (scaleX + scaleY) / 2.0

        let fontSize = baseFontSize * averageScale
        let clampedSize = min(max(fontSize, baseFontSize * 0.5), baseFontSize * 3.0)

        locationLabel.font = currentFontStyle.font(size: clampedSize, weight: .medium)

        // Scale icon proportionally
        let iconSize = 20 * averageScale
        iconImageView.snp.updateConstraints { make in
            make.width.height.equalTo(iconSize)
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        selectionDelegate?.itemWasSelected(self)
    }

    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        currentColor = color
        updateColors()
    }

    func updateColors() {
        locationLabel.textColor = currentColor
        iconImageView.tintColor = currentColor
    }

    func updateFonts() {
        if initialSize == .zero {
            initialSize = bounds.size
        }

        let scaleFactor = calculateScaleFactor()
        let fontSize = baseFontSize * scaleFactor

        locationLabel.font = currentFontStyle.font(size: fontSize, weight: .medium)

        print("🔤 Location widget font updated: style=\(currentFontStyle.displayName), size=\(fontSize)")
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        if initialSize == .zero {
            initialSize = bounds.size
        }
        updateFonts()
    }

    func calculateScaleFactor() -> CGFloat {
        guard initialSize != .zero else {
            initialSize = bounds.size
            return 1.0
        }

        let widthScale = bounds.width / initialSize.width
        let heightScale = bounds.height / initialSize.height
        let averageScale = (widthScale + heightScale) / 2.0

        return min(max(averageScale, 0.5), 3.0)
    }

    /// Update fonts with a specific scale factor (used by group resize)
    func updateFontsWithScale(_ scale: CGFloat) {
        let clampedScale = min(max(scale, 0.5), 3.0)
        let fontSize = baseFontSize * clampedScale
        locationLabel.font = currentFontStyle.font(size: fontSize, weight: .medium)

        // Scale icon proportionally
        let iconSize = 20 * clampedScale
        iconImageView.snp.updateConstraints { make in
            make.width.height.equalTo(iconSize)
        }
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // Don't auto-update fonts when managed by a group - group handles font scaling
        guard !isGroupManaged else {
            if isSelected {
                updateSelectionBorder()
            }
            return
        }

        if !transform.isIdentity {
            updateFontsFromTransform()
        } else if initialSize != .zero && bounds.size != .zero {
            let scaleFactor = calculateScaleFactor()
            let fontSize = baseFontSize * scaleFactor
            let clampedSize = min(max(fontSize, baseFontSize * 0.5), baseFontSize * 3.0)

            locationLabel.font = currentFontStyle.font(size: clampedSize, weight: .medium)
        }

        if isSelected {
            updateSelectionBorder()
        }
    }

    // MARK: - Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for handle in resizeHandles {
            let handlePoint = convert(point, to: handle)
            if handle.point(inside: handlePoint, with: event) {
                return handle
            }
        }

        return super.hitTest(point, with: event)
    }
}
