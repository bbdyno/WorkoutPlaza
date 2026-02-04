//
//  BaseStatWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Base Stat Widget
class BaseStatWidget: UIView, Selectable {

    // MARK: - Selectable Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .white {
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
    var rotationIndicatorLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?

    // Font scaling properties
    var initialSize: CGSize = .zero
    var baseFontSizes: [String: CGFloat] = [:]
    var isGroupManaged: Bool = false
    var isResizing: Bool = false

    // Movement properties
    private var initialCenter: CGPoint = .zero

    // MARK: - UI Components
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: LayoutConstants.titleFontSize, weight: .medium)
        label.textColor = .white.withAlphaComponent(LayoutConstants.secondaryAlpha)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 1
        return label
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: LayoutConstants.valueFontSize, weight: .bold)
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 1
        return label
    }()

    let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: LayoutConstants.unitFontSize, weight: .regular)
        label.textColor = .white.withAlphaComponent(LayoutConstants.secondaryAlpha)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 1
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

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LayoutConstants.standardPadding)
            make.leading.trailing.equalToSuperview().inset(LayoutConstants.standardPadding)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(LayoutConstants.standardPadding)
        }

        unitLabel.snp.makeConstraints { make in
            make.bottom.equalTo(valueLabel.snp.bottom).offset(-2)
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualToSuperview().inset(LayoutConstants.standardPadding)
        }
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

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view, let superview = view.superview else { return }

        switch gesture.state {
        case .began:
            initialCenter = view.center
            if !isSelected {
                selectionDelegate?.itemWasSelected(self)
            }

        case .changed:
            let translation = gesture.translation(in: superview)
            let proposedCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )

            // Center 기준 snap (회전된 뷰에서도 안전)
            let snapStep: CGFloat = LayoutConstants.snapStep
            let snappedCenter = CGPoint(
                x: round(proposedCenter.x / snapStep) * snapStep,
                y: round(proposedCenter.y / snapStep) * snapStep
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

            if isSelected {
                positionResizeHandles()
            }
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
        valueLabel.textColor = currentColor
        titleLabel.textColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
        unitLabel.textColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
    }

    func updateFonts() {
        // 기본 폰트 크기 저장
        if baseFontSizes.isEmpty {
            baseFontSizes["title"] = LayoutConstants.titleFontSize
            baseFontSizes["value"] = LayoutConstants.valueFontSize
            baseFontSizes["unit"] = LayoutConstants.unitFontSize
        }

        // initialSize 설정
        if initialSize == .zero && bounds.size != .zero {
            initialSize = bounds.size
        }

        let scaleFactor = calculateScaleFactor()
        applyFontScale(scaleFactor)
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        if initialSize == .zero && bounds.size != .zero {
            initialSize = bounds.size
        }
        updateFonts()
    }

    func calculateScaleFactor() -> CGFloat {
        guard initialSize.width > 0 && initialSize.height > 0 else {
            return 1.0
        }

        let widthScale = bounds.width / initialSize.width
        let heightScale = bounds.height / initialSize.height
        let minScale = min(widthScale, heightScale)

        return min(max(minScale, LayoutConstants.minimumAllowedScale), LayoutConstants.maximumScaleFactor)
    }

    /// 외부에서 직접 스케일 지정하여 폰트 업데이트 (ResizeHandle에서 사용)
    func updateFontsWithScale(_ scale: CGFloat) {
        if baseFontSizes.isEmpty {
            baseFontSizes["title"] = LayoutConstants.titleFontSize
            baseFontSizes["value"] = LayoutConstants.valueFontSize
            baseFontSizes["unit"] = LayoutConstants.unitFontSize
        }

        let clampedScale = min(max(scale, LayoutConstants.minimumAllowedScale), LayoutConstants.maximumScaleFactor)
        applyFontScale(clampedScale)
    }

    private func applyFontScale(_ scale: CGFloat) {
        let titleSize = (baseFontSizes["title"] ?? LayoutConstants.titleFontSize) * scale
        let valueSize = (baseFontSizes["value"] ?? LayoutConstants.valueFontSize) * scale
        let unitSize = (baseFontSizes["unit"] ?? LayoutConstants.unitFontSize) * scale

        titleLabel.font = currentFontStyle.font(size: titleSize, weight: .medium)
        valueLabel.font = currentFontStyle.font(size: valueSize, weight: .bold)
        unitLabel.font = currentFontStyle.font(size: unitSize, weight: .regular)
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

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // 리사이즈 중이 아니고, 그룹 관리도 아닐 때만 선택 핸들 업데이트
        if isSelected && !isResizing {
            positionResizeHandles()
        }
    }
}
