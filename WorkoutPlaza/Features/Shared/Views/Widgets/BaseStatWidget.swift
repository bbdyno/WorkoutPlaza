//
//  BaseStatWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Display Mode
enum WidgetDisplayMode: String, Codable {
    case text
    case icon
}

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

    // MARK: - Display Mode
    var displayMode: WidgetDisplayMode = .text

    var widgetIconName: String? { nil }

    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.isHidden = true
        return imageView
    }()

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
        addSubview(iconImageView)
        addSubview(valueLabel)
        addSubview(unitLabel)

        applyTextModeLayout()
    }

    // MARK: - Display Mode Toggle

    func toggleDisplayMode() {
        guard widgetIconName != nil else { return }
        displayMode = (displayMode == .text) ? .icon : .text
        applyDisplayMode()
    }

    func setDisplayMode(_ mode: WidgetDisplayMode) {
        guard widgetIconName != nil else { return }
        displayMode = mode
        applyDisplayMode()
    }

    private var textModeSize: CGSize = .zero
    private var textModeInitialSize: CGSize = .zero

    private func applyDisplayMode() {
        // 토글 전 폰트 스케일 보존
        let scaleBeforeToggle = calculateScaleFactor()
        let clampedScale = min(max(scaleBeforeToggle, LayoutConstants.minimumAllowedScale), LayoutConstants.maximumScaleFactor)

        switch displayMode {
        case .text:
            applyTextModeLayout()
        case .icon:
            applyIconModeLayout(scale: clampedScale)
        }
        updateColors()
        resizeToFitContent(preservingScale: scaleBeforeToggle)
        // 토글 후 정확한 폰트·아이콘 크기 보장
        applyFontScale(clampedScale)
    }

    private func applyTextModeLayout() {
        titleLabel.isHidden = false
        iconImageView.isHidden = true

        titleLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(LayoutConstants.standardPadding)
            make.leading.trailing.equalToSuperview().inset(LayoutConstants.standardPadding)
        }

        valueLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(LayoutConstants.standardPadding)
        }

        unitLabel.snp.remakeConstraints { make in
            make.lastBaseline.equalTo(valueLabel.snp.lastBaseline)
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
        }
    }

    private static let baseIconSize: CGFloat = 22

    private func applyIconModeLayout(scale: CGFloat = 1.0) {
        guard let iconName = widgetIconName else { return }

        let iconSize = Self.baseIconSize * scale

        titleLabel.isHidden = true
        iconImageView.isHidden = false
        iconImageView.image = UIImage(systemName: iconName)

        iconImageView.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(LayoutConstants.standardPadding)
            make.width.height.equalTo(iconSize)
        }

        valueLabel.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(6)
        }

        unitLabel.snp.remakeConstraints { make in
            make.lastBaseline.equalTo(valueLabel.snp.lastBaseline)
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
        }
    }

    private func resizeToFitContent(preservingScale scale: CGFloat) {
        let padding = LayoutConstants.standardPadding
        let clampedScale = min(max(scale, LayoutConstants.minimumAllowedScale), LayoutConstants.maximumScaleFactor)

        if displayMode == .text {
            if textModeSize != .zero {
                frame.size = textModeSize
                initialSize = textModeInitialSize
            }
        } else {
            if textModeSize == .zero {
                textModeSize = frame.size
                textModeInitialSize = initialSize
            }

            let iconSize = Self.baseIconSize * clampedScale
            let valueWidth = valueLabel.intrinsicContentSize.width
            let unitWidth = unitLabel.intrinsicContentSize.width
            let neededWidth = padding + iconSize + 6 + valueWidth + 4 + unitWidth + padding
            let newWidth = max(neededWidth, frame.width)

            frame.size.width = newWidth

            // initialSize를 역산하여 calculateScaleFactor()가 토글 전과 동일한 스케일을 반환하도록 설정
            let safeScale = max(scale, 0.01)
            initialSize = CGSize(
                width: frame.size.width / safeScale,
                height: frame.size.height / safeScale
            )
        }

        if isSelected {
            positionResizeHandles()
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
        if isSelected && widgetIconName != nil {
            toggleDisplayMode()
        } else {
            selectionDelegate?.itemWasSelected(self)
        }
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
        iconImageView.tintColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
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

        // 아이콘 모드에서 아이콘 크기도 스케일에 맞게 조정
        if displayMode == .icon {
            iconImageView.snp.updateConstraints { make in
                make.width.height.equalTo(Self.baseIconSize * scale)
            }
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

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // 리사이즈 중이 아니고, 그룹 관리도 아닐 때만 선택 핸들 업데이트
        if isSelected && !isResizing {
            positionResizeHandles()
        }
    }
}
