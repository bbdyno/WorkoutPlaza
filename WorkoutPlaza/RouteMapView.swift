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
        
        // 여백 추가
        let padding: CGFloat = 20
        let drawWidth = bounds.width - padding * 2
        let drawHeight = bounds.height - padding * 2
        
        // 경로 생성
        let path = UIBezierPath()
        
        for (index, location) in routeLocations.enumerated() {
            let x = CGFloat((location.coordinate.longitude - minLon) / lonRange) * drawWidth + padding
            let y = drawHeight - CGFloat((location.coordinate.latitude - minLat) / latRange) * drawHeight + padding
            
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
