//
//  RouteMapView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import CoreLocation

class RouteMapView: UIView, Selectable {

    // MARK: - Selectable Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .systemBlue {
        didSet {
            lineColor = currentColor
            routeLayer.strokeColor = lineColor.cgColor
        }
    }
    var currentFontStyle: FontStyle = .system  // Not used for RouteMapView, but required by protocol
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?
    var initialSize: CGSize = .zero

    // MARK: - Route Properties
    private var routeLocations: [CLLocation] = []
    private let routeLayer = CAShapeLayer()
    
    // Movement properties
    private var initialCenter: CGPoint = .zero

    var lineColor: UIColor = .systemBlue {
        didSet {
            routeLayer.strokeColor = lineColor.cgColor
        }
    }

    var lineWidth: CGFloat = 3.0 {
        didSet {
            routeLayer.lineWidth = lineWidth
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupGestures()
    }
    
    private func setupView() {
        // Background and shadow removed for clean look
        backgroundColor = .clear

        routeLayer.fillColor = UIColor.clear.cgColor
        routeLayer.strokeColor = lineColor.cgColor
        routeLayer.lineWidth = lineWidth
        routeLayer.lineCap = .round
        routeLayer.lineJoin = .round
        layer.addSublayer(routeLayer)
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
    
    // MARK: - 경로 설정
    func setRoute(_ locations: [CLLocation]) {
        routeLocations = locations
        drawRoute()
    }

    /// Calculate the optimal frame size for this route based on its aspect ratio
    /// - Parameter maxDimension: The maximum width or height
    /// - Returns: The recommended size maintaining the route's aspect ratio
    func calculateOptimalSize(maxDimension: CGFloat = 250) -> CGSize {
        guard routeLocations.count >= 2 else {
            return CGSize(width: maxDimension, height: maxDimension)
        }

        // Calculate route's bounding box
        var minLat = routeLocations[0].coordinate.latitude
        var maxLat = minLat
        var minLon = routeLocations[0].coordinate.longitude
        var maxLon = minLon

        for location in routeLocations {
            minLat = min(minLat, location.coordinate.latitude)
            maxLat = max(maxLat, location.coordinate.latitude)
            minLon = min(minLon, location.coordinate.longitude)
            maxLon = max(maxLon, location.coordinate.longitude)
        }

        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon

        // Correct longitude range for latitude (earth curvature)
        let centerLat = (minLat + maxLat) / 2
        let lonRangeCorrected = lonRange * cos(centerLat * .pi / 180)

        // Handle edge case where route is a straight line or very small
        guard latRange > 0.00001 || lonRangeCorrected > 0.00001 else {
            return CGSize(width: maxDimension, height: maxDimension)
        }

        // Calculate aspect ratio (width:height)
        let aspectRatio: CGFloat
        if lonRangeCorrected > 0.00001 {
            aspectRatio = lonRangeCorrected / max(latRange, 0.00001)
        } else {
            aspectRatio = 0.5 // Vertical route
        }

        // Determine optimal size maintaining aspect ratio
        let width: CGFloat
        let height: CGFloat

        if aspectRatio >= 1.0 {
            // Wider than tall
            width = maxDimension
            height = maxDimension / aspectRatio
        } else {
            // Taller than wide
            height = maxDimension
            width = maxDimension * aspectRatio
        }

        // Ensure minimum dimensions
        let minDimension: CGFloat = 100
        return CGSize(
            width: max(width, minDimension),
            height: max(height, minDimension)
        )
    }
    
    private func drawRoute() {
        guard !routeLocations.isEmpty else { return }

        // 경로의 좌표 범위 계산
        var minLat = routeLocations[0].coordinate.latitude
        var maxLat = minLat
        var minLon = routeLocations[0].coordinate.longitude
        var maxLon = minLon

        for location in routeLocations {
            minLat = min(minLat, location.coordinate.latitude)
            maxLat = max(maxLat, location.coordinate.latitude)
            minLon = min(minLon, location.coordinate.longitude)
            maxLon = max(maxLon, location.coordinate.longitude)
        }

        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon

        // 경도를 실제 거리로 보정 (위도의 중간값에서의 경도 보정)
        let centerLat = (minLat + maxLat) / 2
        let lonRangeCorrected = lonRange * cos(centerLat * .pi / 180)

        // 여백 추가
        let padding: CGFloat = 20
        let drawWidth = bounds.width - padding * 2
        let drawHeight = bounds.height - padding * 2

        // 실제 비율을 유지하면서 bounds에 맞추기
        // 위도 범위와 보정된 경도 범위 중 더 큰 비율에 맞춤
        let latToLonRatio = latRange / lonRangeCorrected
        var scale: CGFloat = 1.0
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0

        if latToLonRatio > drawHeight / drawWidth {
            // 위도(남북) 범위가 상대적으로 더 큼 - 높이를 기준으로
            scale = drawHeight / latRange
            let scaledWidth = lonRangeCorrected * scale
            xOffset = (drawWidth - scaledWidth) / 2
        } else {
            // 경도(동서) 범위가 상대적으로 더 큼 - 너비를 기준으로
            scale = drawWidth / lonRangeCorrected
            let scaledHeight = latRange * scale
            yOffset = (drawHeight - scaledHeight) / 2
        }

        // 경로 생성 - 북쪽이 위로 가도록
        let path = UIBezierPath()

        for (index, location) in routeLocations.enumerated() {
            // 경도(동서): 동쪽으로 갈수록 x가 증가
            let normalizedLon = (location.coordinate.longitude - minLon) * cos(centerLat * .pi / 180)
            let x = normalizedLon * scale + padding + xOffset

            // 위도(남북): 북쪽으로 갈수록 y가 감소 (화면 좌표계)
            let normalizedLat = (location.coordinate.latitude - minLat)
            let y = drawHeight - (normalizedLat * scale) + padding - yOffset

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        routeLayer.path = path.cgPath
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawRoute()
        if isSelected {
            positionResizeHandles()
        }
    }

    // MARK: - 제스처 처리
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        selectionDelegate?.itemWasSelected(self)
    }

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
            
            // Calculate new proposed center based on initial center + total translation
            let proposedCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )
            
            // Snap to 5pt grid based on origin
            let snapStep: CGFloat = 5.0
            let width = view.frame.width
            let height = view.frame.height
            
            // Convert center to origin
            let proposedOriginX = proposedCenter.x - width / 2
            let proposedOriginY = proposedCenter.y - height / 2
            
            // Snap origin
            let snappedOriginX = round(proposedOriginX / snapStep) * snapStep
            let snappedOriginY = round(proposedOriginY / snapStep) * snapStep
            
            // Convert snapped origin back to center
            let snappedCenter = CGPoint(
                x: snappedOriginX + width / 2,
                y: snappedOriginY + height / 2
            )
            
            view.center = snappedCenter
            
            // Update handles position
            if isSelected {
                positionResizeHandles()
            }
            
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
            
            if isSelected {
                positionResizeHandles()
            }
        }
    }

    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        currentColor = color
        lineColor = color
        routeLayer.strokeColor = color.cgColor
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        // RouteMapView doesn't use fonts, so this is a no-op
    }

    // MARK: - Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Check if touch is on a resize handle first
        for handle in resizeHandles {
            let handlePoint = convert(point, to: handle)
            if handle.point(inside: handlePoint, with: event) {
                return handle
            }
        }

        // Otherwise, return default behavior
        return super.hitTest(point, with: event)
    }
}
