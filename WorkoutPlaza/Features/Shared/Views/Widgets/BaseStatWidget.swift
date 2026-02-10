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
    case textUnified
    case icon
}

// MARK: - Base Stat Widget
class BaseStatWidget: UIView, Selectable, WidgetContentAlignable {

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
    var initialSize: CGSize = .zero {
        didSet {
            updateMinimumSizeOverride()
        }
    }
    var baseFontSizes: [String: CGFloat] = [:]
    var isGroupManaged: Bool = false
    var isResizing: Bool = false
    private var minimumSizeOverride: CGFloat?

    // Movement properties
    private var initialCenter: CGPoint = .zero

    // MARK: - Display Mode
    var displayMode: WidgetDisplayMode = .text
    private(set) var contentAlignment: WidgetContentAlignment = .left
    var minimumSize: CGFloat {
        minimumSizeOverride ?? minimumSizeCandidate(for: bounds.size)
    }

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
        label.minimumScaleFactor = 0.35
        label.numberOfLines = 1
        return label
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: LayoutConstants.valueFontSize, weight: .bold)
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.35
        label.numberOfLines = 1
        return label
    }()

    let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: LayoutConstants.unitFontSize, weight: .regular)
        label.textColor = .white.withAlphaComponent(LayoutConstants.secondaryAlpha)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.55
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

        // Keep unit labels (km, bpm, kcal, etc.) visible in tight layouts.
        valueLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        unitLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        unitLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        valueLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        valueLabel.setContentHuggingPriority(.required, for: .vertical)
        unitLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        unitLabel.setContentHuggingPriority(.required, for: .vertical)

        applyTextModeLayout()
        applyContentAlignment(contentAlignment)
    }

    // MARK: - Display Mode Toggle

    func toggleDisplayMode() {
        guard widgetIconName != nil else { return }
        switch displayMode {
        case .text:
            displayMode = .textUnified
        case .textUnified:
            displayMode = .icon
        case .icon:
            displayMode = .text
        }
        applyDisplayMode()
    }

    func setDisplayMode(_ mode: WidgetDisplayMode) {
        guard widgetIconName != nil else { return }
        displayMode = mode
        applyDisplayMode()
    }

    // 텍스트 모드의 기준 크기 (스케일 1.0일 때의 크기)
    private var textModeBaseSize: CGSize = .zero
    private var cachedHasUnitText: Bool?
    private var unifiedSourceValueText: String?
    private static let textModeTopInset: CGFloat = 3
    private static let textModeBottomInset: CGFloat = 3
    private static let textModeTitleSpacing: CGFloat = 1
    private static let contentSpacing: CGFloat = 4
    private static let compactStatMinimumSize: CGFloat = 45

    private func applyDisplayMode() {
        // 토글 전 폰트 스케일 보존
        let scaleBeforeToggle = calculateScaleFactor()
        let clampedScale = min(max(scaleBeforeToggle, LayoutConstants.statWidgetMinimumScale), LayoutConstants.maximumScaleFactor)

        switch displayMode {
        case .text:
            applyTextModeLayout()
        case .textUnified:
            applyUnifiedTextModeLayout()
        case .icon:
            applyIconModeLayout(scale: clampedScale)
        }
        updateColors()
        applyFontScale(clampedScale)
        applyContentAlignment(contentAlignment)
        setNeedsLayout()
        if isSelected {
            positionResizeHandles()
        }
    }

    private func applyTextModeLayout() {
        restoreValueTextFromUnifiedModeIfNeeded()

        titleLabel.isHidden = false
        iconImageView.isHidden = true
        let hasUnit = usesUnitText
        cachedHasUnitText = hasUnit
        unitLabel.isHidden = !hasUnit

        titleLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(Self.textModeTopInset)
            make.leading.trailing.equalToSuperview().inset(LayoutConstants.standardPadding)
        }

        valueLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Self.textModeTitleSpacing)
            make.leading.equalToSuperview().inset(LayoutConstants.standardPadding)
            if hasUnit {
                make.trailing.lessThanOrEqualTo(unitLabel.snp.leading).offset(-Self.contentSpacing)
            } else {
                make.trailing.lessThanOrEqualToSuperview().inset(LayoutConstants.standardPadding)
            }
            make.bottom.lessThanOrEqualToSuperview().inset(Self.textModeBottomInset)
        }

        if hasUnit {
            unitLabel.snp.remakeConstraints { make in
                make.lastBaseline.equalTo(valueLabel.snp.lastBaseline)
                make.leading.equalTo(valueLabel.snp.trailing).offset(Self.contentSpacing)
                make.trailing.lessThanOrEqualToSuperview().inset(LayoutConstants.standardPadding)
            }
        } else {
            unitLabel.snp.removeConstraints()
        }
    }

    private func applyUnifiedTextModeLayout() {
        titleLabel.isHidden = false
        iconImageView.isHidden = true
        cachedHasUnitText = usesUnitText
        unitLabel.isHidden = true
        applyUnifiedValueText()

        titleLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(Self.textModeTopInset)
            make.leading.trailing.equalToSuperview().inset(LayoutConstants.standardPadding)
        }

        valueLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Self.textModeTitleSpacing)
            make.leading.equalToSuperview().inset(LayoutConstants.standardPadding)
            make.trailing.lessThanOrEqualToSuperview().inset(LayoutConstants.standardPadding)
            make.bottom.lessThanOrEqualToSuperview().inset(Self.textModeBottomInset)
        }

        unitLabel.snp.removeConstraints()
    }

    private static let baseIconSize: CGFloat = 22

    private func applyIconModeLayout(scale: CGFloat = 1.0) {
        guard let iconName = widgetIconName else { return }
        restoreValueTextFromUnifiedModeIfNeeded()

        let iconSize = Self.baseIconSize * scale
        let hasUnit = usesUnitText
        cachedHasUnitText = hasUnit

        titleLabel.isHidden = true
        iconImageView.isHidden = false
        iconImageView.image = UIImage(systemName: iconName)
        unitLabel.isHidden = !hasUnit

        iconImageView.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(LayoutConstants.standardPadding)
            make.width.height.equalTo(iconSize)
        }

        valueLabel.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(6)
            if hasUnit {
                make.trailing.lessThanOrEqualTo(unitLabel.snp.leading).offset(-Self.contentSpacing)
            } else {
                make.trailing.lessThanOrEqualToSuperview().inset(LayoutConstants.standardPadding)
            }
        }

        if hasUnit {
            unitLabel.snp.remakeConstraints { make in
                make.lastBaseline.equalTo(valueLabel.snp.lastBaseline)
                make.leading.equalTo(valueLabel.snp.trailing).offset(Self.contentSpacing)
                make.trailing.lessThanOrEqualToSuperview().inset(LayoutConstants.standardPadding)
            }
        } else {
            unitLabel.snp.removeConstraints()
        }
    }

    private func resizeToFitContent(preservingScale scale: CGFloat) {
        let safeScale = max(scale, 0.001)
        let padding = LayoutConstants.standardPadding

        if textModeBaseSize == .zero {
            textModeBaseSize = resolvedInitialTextModeBaseSize()
        }

        switch displayMode {
        case .text, .textUnified:
            let proposedSize = CGSize(
                width: textModeBaseSize.width * safeScale,
                height: textModeBaseSize.height * safeScale
            )
            let requiredSize = requiredTextModeSize()
            frame.size = CGSize(
                width: max(proposedSize.width, requiredSize.width),
                height: max(proposedSize.height, requiredSize.height)
            )

            // Recalculate base size so mode toggles keep consistent visible bounds.
            textModeBaseSize = CGSize(
                width: frame.size.width / safeScale,
                height: frame.size.height / safeScale
            )
            initialSize = textModeBaseSize
        case .icon:
            let hasUnit = usesUnitText
            let unitSpacing = hasUnit ? Self.contentSpacing : 0
            let valueWidth = valueLabel.intrinsicContentSize.width
            let unitWidth = hasUnit ? unitLabel.intrinsicContentSize.width : 0
            let iconSize = Self.baseIconSize * safeScale
            let neededWidth = padding + iconSize + 6 + valueWidth + unitSpacing + unitWidth + padding

            // Icon mode should never shrink below text baseline width.
            let baseNeededWidth = padding + Self.baseIconSize + 6 + (valueWidth / safeScale) + unitSpacing + (unitWidth / safeScale) + padding
            let baseWidth = max(baseNeededWidth, textModeBaseSize.width)

            frame.size = CGSize(
                width: max(baseWidth * safeScale, neededWidth),
                height: textModeBaseSize.height * safeScale
            )
            initialSize = CGSize(width: baseWidth, height: textModeBaseSize.height)
        }

        if isSelected {
            positionResizeHandles()
        }
    }

    private func applyUnifiedValueText() {
        let unitText = trimmedUnitText
        let expectedText = mergedValueText(
            value: unifiedSourceValueText ?? "",
            unit: unitText
        )

        if let currentText = valueLabel.text, unifiedSourceValueText != nil, currentText != expectedText {
            unifiedSourceValueText = normalizedValueSourceText(currentText, unit: unitText)
        } else if unifiedSourceValueText == nil {
            unifiedSourceValueText = normalizedValueSourceText(valueLabel.text ?? "", unit: unitText)
        }

        let mergedText = mergedValueText(value: unifiedSourceValueText ?? "", unit: unitText)
        if valueLabel.text != mergedText {
            valueLabel.text = mergedText
        }
    }

    private func restoreValueTextFromUnifiedModeIfNeeded() {
        guard let sourceText = unifiedSourceValueText else { return }
        if valueLabel.text != sourceText {
            valueLabel.text = sourceText
        }
        unifiedSourceValueText = nil
    }

    private var trimmedUnitText: String {
        unitLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func mergedValueText(value: String, unit: String) -> String {
        let unitText = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !unitText.isEmpty else { return value }
        guard !value.isEmpty else { return unitText }
        return "\(value) \(unitText)"
    }

    private func normalizedValueSourceText(_ text: String, unit: String) -> String {
        let unitText = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !unitText.isEmpty else { return text }
        let suffix = " \(unitText)"
        guard text.hasSuffix(suffix) else { return text }
        return String(text.dropLast(suffix.count))
    }

    private var usesUnitText: Bool {
        !(unitLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private func resolvedInitialTextModeBaseSize() -> CGSize {
        let fallbackSize = initialSize == .zero ? bounds.size : initialSize
        let requiredSize = requiredTextModeSize()
        let width = max(requiredSize.width, fallbackSize.width, LayoutConstants.minWidth)
        let height = max(requiredSize.height, fallbackSize.height, LayoutConstants.minHeight)
        return CGSize(width: width, height: height)
    }

    private func updateMinimumSizeOverride() {
        guard initialSize.width > 0, initialSize.height > 0 else { return }
        let candidate = minimumSizeCandidate(for: initialSize)
        if let current = minimumSizeOverride {
            minimumSizeOverride = min(current, candidate)
        } else {
            minimumSizeOverride = candidate
        }
    }

    private func minimumSizeCandidate(for size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else {
            return LayoutConstants.minimumWidgetSize
        }
        let minDimension = min(size.width, size.height)
        let targetMinimum = minDimension <= LayoutConstants.minimumWidgetSize
            ? Self.compactStatMinimumSize
            : LayoutConstants.minimumWidgetSize
        return min(
            targetMinimum,
            max(minDimension, LayoutConstants.groupManagedMinimumWidgetSize)
        )
    }

    private func requiredTextModeSize() -> CGSize {
        let padding = LayoutConstants.standardPadding

        let titleWidth = titleLabel.intrinsicContentSize.width
        let valueWidth = valueLabel.intrinsicContentSize.width

        let titleHeight = titleLabel.font.lineHeight
        let valueHeight = valueLabel.font.lineHeight

        let valueLineWidth: CGFloat
        let bodyHeight: CGFloat
        if displayMode == .textUnified {
            valueLineWidth = valueWidth
            bodyHeight = valueHeight
        } else {
            let hasUnit = usesUnitText
            let unitSpacing = hasUnit ? Self.contentSpacing : 0
            let unitWidth = hasUnit ? unitLabel.intrinsicContentSize.width : 0
            let unitHeight = hasUnit ? unitLabel.font.lineHeight : 0
            valueLineWidth = valueWidth + unitSpacing + unitWidth
            bodyHeight = max(valueHeight, unitHeight)
        }

        let width = max(titleWidth, valueLineWidth) + padding * 2
        let height = Self.textModeTopInset + titleHeight + Self.textModeTitleSpacing + bodyHeight + Self.textModeBottomInset
        return CGSize(width: width, height: height)
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

            NotificationCenter.default.post(
                name: .widgetDidMove,
                object: self,
                userInfo: [WidgetMoveNotificationUserInfoKey.phase: WidgetMovePhase.changed.rawValue]
            )

        case .ended, .cancelled:
            NotificationCenter.default.post(
                name: .widgetDidMove,
                object: self,
                userInfo: [WidgetMoveNotificationUserInfoKey.phase: WidgetMovePhase.ended.rawValue]
            )

        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard DevSettings.shared.isPinchToResizeEnabled else { return }
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
        switch displayMode {
        case .text:
            valueLabel.textColor = currentColor
            titleLabel.textColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
            unitLabel.textColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
            iconImageView.tintColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
        case .textUnified:
            valueLabel.textColor = currentColor
            titleLabel.textColor = currentColor
            unitLabel.textColor = currentColor
            iconImageView.tintColor = currentColor
        case .icon:
            valueLabel.textColor = currentColor
            titleLabel.textColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
            unitLabel.textColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
            iconImageView.tintColor = currentColor.withAlphaComponent(LayoutConstants.secondaryAlpha)
        }
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

    func applyContentAlignment(_ alignment: WidgetContentAlignment) {
        contentAlignment = alignment
        titleLabel.textAlignment = alignment.textAlignment
        valueLabel.textAlignment = alignment.textAlignment
        unitLabel.textAlignment = alignment.textAlignment

        setNeedsLayout()
    }

    var alignmentSubjectViews: [UIView] {
        var views: [UIView] = [valueLabel]
        if !unitLabel.isHidden, !(unitLabel.text ?? "").isEmpty {
            views.append(unitLabel)
        }
        if !iconImageView.isHidden {
            views.insert(iconImageView, at: 0)
        }
        return views
    }

    var contentAlignmentPadding: CGFloat {
        LayoutConstants.standardPadding
    }

    private func applyAlignmentLayout() {
        let views = alignmentSubjectViews.filter { !$0.isHidden }
        views.forEach { $0.transform = .identity }

        guard !views.isEmpty else { return }

        let contentBounds = views.map(\.frame).reduce(CGRect.null) { partialResult, frame in
            partialResult.union(frame)
        }
        guard !contentBounds.isNull else { return }

        let minX = contentAlignmentPadding
        let maxX = max(minX, bounds.width - contentAlignmentPadding - contentBounds.width)

        let requestedX: CGFloat
        switch contentAlignment {
        case .left:
            requestedX = minX
        case .center:
            requestedX = (bounds.width - contentBounds.width) / 2
        case .right:
            requestedX = maxX
        }

        let targetX = min(max(requestedX, minX), maxX)
        let deltaX = targetX - contentBounds.minX

        guard abs(deltaX) > 0.1 else { return }

        views.forEach { view in
            view.transform = CGAffineTransform(translationX: deltaX, y: 0)
        }
    }

    func calculateScaleFactor() -> CGFloat {
        guard initialSize.width > 0 && initialSize.height > 0 else {
            return 1.0
        }

        let widthScale = bounds.width / initialSize.width
        let heightScale = bounds.height / initialSize.height
        let minScale = min(widthScale, heightScale)
        let lowerBound = isGroupManaged ? LayoutConstants.groupManagedMinimumScale : LayoutConstants.statWidgetMinimumScale
        let result = min(max(minScale, lowerBound), LayoutConstants.maximumScaleFactor)
        return result
    }

    /// 외부에서 직접 스케일 지정하여 폰트 업데이트 (ResizeHandle에서 사용)
    func updateFontsWithScale(_ scale: CGFloat) {
        if baseFontSizes.isEmpty {
            baseFontSizes["title"] = LayoutConstants.titleFontSize
            baseFontSizes["value"] = LayoutConstants.valueFontSize
            baseFontSizes["unit"] = LayoutConstants.unitFontSize
        }

        let minScale = isGroupManaged ? LayoutConstants.groupManagedMinimumScale : LayoutConstants.statWidgetMinimumScale
        let clampedScale = min(max(scale, minScale), LayoutConstants.maximumScaleFactor)
        applyFontScale(clampedScale)
    }

    private func applyFontScale(_ scale: CGFloat) {
        let titleSize = (baseFontSizes["title"] ?? LayoutConstants.titleFontSize) * scale
        let valueSize = (baseFontSizes["value"] ?? LayoutConstants.valueFontSize) * scale
        let defaultUnitSize = (baseFontSizes["unit"] ?? LayoutConstants.unitFontSize) * scale
        let valueUnitSize = (baseFontSizes["value"] ?? LayoutConstants.valueFontSize) * scale
        let unitSize = displayMode == .textUnified ? valueUnitSize : defaultUnitSize

        titleLabel.font = currentFontStyle.font(size: titleSize, weight: .medium)
        valueLabel.font = currentFontStyle.font(size: valueSize, weight: .bold)
        unitLabel.font = currentFontStyle.font(size: unitSize, weight: displayMode == .textUnified ? .bold : .regular)

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
        if displayMode == .textUnified {
            applyUnifiedValueText()
        }
        syncUnitLayoutIfNeeded()

        applyAlignmentLayout()

        // 리사이즈 중이 아니고, 그룹 관리도 아닐 때만 선택 핸들 업데이트
        if isSelected && !isResizing {
            positionResizeHandles()
        }
    }

    private func syncUnitLayoutIfNeeded() {
        let hasUnit = usesUnitText
        guard cachedHasUnitText != hasUnit else { return }

        switch displayMode {
        case .text:
            applyTextModeLayout()
        case .textUnified:
            applyUnifiedTextModeLayout()
        case .icon:
            applyIconModeLayout(scale: calculateScaleFactor())
        }
        setNeedsLayout()
    }
}
