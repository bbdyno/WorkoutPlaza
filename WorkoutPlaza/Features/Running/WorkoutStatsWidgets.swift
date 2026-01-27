//
//  WorkoutStatsWidgets.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit
import CoreLocation

// MARK: - Notification Names
extension Notification.Name {
    static let widgetDidMove = Notification.Name("widgetDidMove")
}

// MARK: - Base Stat Widget
class BaseStatWidget: UIView, Selectable {

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
    var baseFontSizes: [String: CGFloat] = [:]  // labelName: baseSize
    var isGroupManaged: Bool = false  // Prevents auto font scaling when inside a group

    // Movement properties
    private var initialCenter: CGPoint = .zero

    // MARK: - UI Components
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1 // Allow significant shrinking for long text like dates
        return label
    }()

    let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
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
        // Background, shadow, and border removed for clean look
        backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(12)
        }
        
        unitLabel.snp.makeConstraints { make in
            make.bottom.equalTo(valueLabel.snp.bottom).offset(-2)
            make.leading.equalTo(valueLabel.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
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

        case .ended, .cancelled:
            // 위젯 이동 완료 알림
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
        titleLabel.textColor = currentColor.withAlphaComponent(0.7)
        unitLabel.textColor = currentColor.withAlphaComponent(0.7)
    }

    func updateFonts() {
        // Store base font sizes if not already stored
        if baseFontSizes.isEmpty {
            baseFontSizes["title"] = 12
            baseFontSizes["value"] = 24
            baseFontSizes["unit"] = 14
        }

        // Calculate scale factor based on current size
        let scaleFactor = calculateScaleFactor()

        let titleSize = (baseFontSizes["title"] ?? 12) * scaleFactor
        let valueSize = (baseFontSizes["value"] ?? 24) * scaleFactor
        let unitSize = (baseFontSizes["unit"] ?? 14) * scaleFactor

        titleLabel.font = currentFontStyle.font(size: titleSize, weight: .medium)
        valueLabel.font = currentFontStyle.font(size: valueSize, weight: .bold)
        unitLabel.font = currentFontStyle.font(size: unitSize, weight: .regular)

        print("🔤 Font updated: style=\(currentFontStyle.displayName), scale=\(scaleFactor), valueSize=\(valueSize)")

        // Auto-resize to fit content if font style changed
        autoResizeToFitContent()
    }

    // MARK: - Auto Resize
    func autoResizeToFitContent() {
        // Force layout to get accurate label sizes
        layoutIfNeeded()

        // Calculate required size based on label content
        let titleHeight = titleLabel.intrinsicContentSize.height
        let valueHeight = valueLabel.intrinsicContentSize.height
        let unitHeight = unitLabel.intrinsicContentSize.height

        let valuePlusUnit = max(valueHeight, unitHeight)

        // Calculate total height needed (with padding)
        let topPadding: CGFloat = 12
        let bottomPadding: CGFloat = 12
        let titleToValueSpacing: CGFloat = 4

        let requiredHeight = topPadding + titleHeight + titleToValueSpacing + valuePlusUnit + bottomPadding

        // Calculate required width based on content
        let titleWidth = titleLabel.intrinsicContentSize.width
        let valueWidth = valueLabel.intrinsicContentSize.width + unitLabel.intrinsicContentSize.width + 4
        let requiredContentWidth = max(titleWidth, valueWidth)

        let sidePadding: CGFloat = 12 * 2
        let requiredWidth = requiredContentWidth + sidePadding

        // Only resize if content doesn't fit in current frame
        let currentWidth = bounds.width
        let currentHeight = bounds.height

        var newWidth = currentWidth
        var newHeight = currentHeight

        // Expand if needed, but don't shrink too much (maintain minimum size)
        let minWidth: CGFloat = 80
        let minHeight: CGFloat = 60

        if requiredWidth > currentWidth || requiredWidth < currentWidth * 0.7 {
            newWidth = max(requiredWidth, minWidth)
        }

        if requiredHeight > currentHeight || requiredHeight < currentHeight * 0.7 {
            newHeight = max(requiredHeight, minHeight)
        }

        // Only update if size changed significantly (more than 2pt)
        if abs(newWidth - currentWidth) > 2 || abs(newHeight - currentHeight) > 2 {
            let newFrame = CGRect(
                x: frame.origin.x,
                y: frame.origin.y,
                width: newWidth,
                height: newHeight
            )

            frame = newFrame

            // Update initial size to prevent scaling issues
            initialSize = newFrame.size

            // Update selection handles if selected
            if isSelected {
                positionResizeHandles()
            }

            print("📏 Auto-resized widget: \(currentWidth)x\(currentHeight) -> \(newWidth)x\(newHeight)")
        }
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        // Store initial size when font is first applied
        if initialSize == .zero {
            initialSize = bounds.size
        }
        updateFonts()
    }

    func calculateScaleFactor() -> CGFloat {
        guard initialSize != .zero else {
            // If initial size not set, use current size as initial
            initialSize = bounds.size
            return 1.0
        }

        // Calculate scale based on average of width and height change
        let widthScale = bounds.width / initialSize.width
        let heightScale = bounds.height / initialSize.height
        let averageScale = (widthScale + heightScale) / 2.0

        // Clamp scale factor between 0.5 and 3.0
        return min(max(averageScale, 0.5), 3.0)
    }

    /// Update fonts with a specific scale factor (used by group resize)
    /// This method doesn't call autoResizeToFitContent to prevent resize feedback loops
    func updateFontsWithScale(_ scale: CGFloat) {
        if baseFontSizes.isEmpty {
            baseFontSizes["title"] = 12
            baseFontSizes["value"] = 24
            baseFontSizes["unit"] = 14
        }

        let clampedScale = min(max(scale, 0.5), 3.0)

        let titleSize = (baseFontSizes["title"] ?? 12) * clampedScale
        let valueSize = (baseFontSizes["value"] ?? 24) * clampedScale
        let unitSize = (baseFontSizes["unit"] ?? 14) * clampedScale

        titleLabel.font = currentFontStyle.font(size: titleSize, weight: .medium)
        valueLabel.font = currentFontStyle.font(size: valueSize, weight: .bold)
        unitLabel.font = currentFontStyle.font(size: unitSize, weight: .regular)
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

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // Update fonts when size changes (during resize)
        // But not when managed by a group - group handles font scaling
        if !isGroupManaged && initialSize != .zero && bounds.size != initialSize {
            updateFonts()
        }

        if isSelected {
            positionResizeHandles()
        }
    }
}

// MARK: - Distance Widget
class DistanceWidget: BaseStatWidget {
    func configure(distance: Double) {
        titleLabel.text = "거리"
        valueLabel.text = String(format: "%.2f", distance / 1000)
        unitLabel.text = "km"
    }
}

// MARK: - Duration Widget
class DurationWidget: BaseStatWidget {
    func configure(duration: TimeInterval) {
        titleLabel.text = "시간"
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            valueLabel.text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            valueLabel.text = String(format: "%02d:%02d", minutes, seconds)
        }
        unitLabel.text = ""
    }
}

// MARK: - Pace Widget
class PaceWidget: BaseStatWidget {
    func configure(pace: Double) {
        titleLabel.text = "평균 페이스"
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        valueLabel.text = String(format: "%d:%02d", minutes, seconds)
        unitLabel.text = "/km"
    }
}

// MARK: - Speed Widget
class SpeedWidget: BaseStatWidget {
    func configure(speed: Double) {
        titleLabel.text = "평균 속도"
        valueLabel.text = String(format: "%.1f", speed)
        unitLabel.text = "km/h"
    }
}

// MARK: - Calories Widget
class CaloriesWidget: BaseStatWidget {
    func configure(calories: Double) {
        titleLabel.text = "칼로리"
        valueLabel.text = String(format: "%.0f", calories)
        unitLabel.text = "kcal"
    }
}

// MARK: - Workout Type Widget
class WorkoutTypeWidget: BaseStatWidget {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupIcon()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupIcon() {
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalTo(valueLabel)
            make.width.height.equalTo(32)
        }
        
        valueLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
        }
    }
    
    func configure(workoutType: String) {
        titleLabel.text = "운동 종류"
        valueLabel.text = workoutType
        unitLabel.text = ""
        
        // 아이콘 설정
        switch workoutType {
        case "러닝":
            iconImageView.image = UIImage(systemName: "figure.run")
        case "사이클링":
            iconImageView.image = UIImage(systemName: "bicycle")
        case "걷기":
            iconImageView.image = UIImage(systemName: "figure.walk")
        case "하이킹":
            iconImageView.image = UIImage(systemName: "figure.hiking")
        default:
            iconImageView.image = UIImage(systemName: "figure.mixed.cardio")
        }
    }
}

// MARK: - Date Widget
class DateWidget: BaseStatWidget {
    func configure(startDate: Date) {
        titleLabel.text = "날짜"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let dateString = formatter.string(from: startDate)
        
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: startDate)
        
        valueLabel.text = dateString
        unitLabel.text = timeString
    }
}

// MARK: - Current Date Time Widget
class CurrentDateTimeWidget: BaseStatWidget {
    func configure(date: Date) {
        // Set smaller base font size for long date string
        baseFontSizes["title"] = 12
        baseFontSizes["value"] = 16 // Much smaller than default 24
        baseFontSizes["unit"] = 14

        titleLabel.text = "운동 일시"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR") // Ensure Korean locale for "오후"
        formatter.dateFormat = "yyyy년 M월 d일 a h시 m분" // 2026년 1월 12일 오후 8시 50분

        let dateTimeString = formatter.string(from: date)

        valueLabel.text = dateTimeString
        unitLabel.text = "" // No unit for combined date/time

        // Force font update with new base sizes
        updateFonts()
    }
}

// MARK: - Text Widget Delegate
protocol TextWidgetDelegate: AnyObject {
    func textWidgetDidRequestEdit(_ widget: TextWidget)
}

// MARK: - Text Widget (for custom text input)
class TextWidget: UIView, Selectable {

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

    // Text widget specific delegate
    weak var textDelegate: TextWidgetDelegate?

    // Font scaling properties
    var initialSize: CGSize = .zero
    var baseFontSize: CGFloat = 20
    var isGroupManaged: Bool = false  // Prevents auto font scaling when inside a group

    // Movement properties
    private var initialCenter: CGPoint = .zero

    // MARK: - UI Components
    let textLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .label
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
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

        addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        // Set default text
        textLabel.text = "텍스트 입력"
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)

        // Single tap should wait for double tap to fail
        tapGesture.require(toFail: doubleTapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)

        isUserInteractionEnabled = true
    }

    func configure(text: String = "텍스트 입력") {
        textLabel.text = text
        initialSize = bounds.size
        updateFonts()
    }

    func updateText(_ text: String) {
        textLabel.text = text
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

            let proposedCenter = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )

            // Snap to 5pt grid
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

            // Update fonts based on transform scale
            updateFontsFromTransform()

            if isSelected {
                positionResizeHandles()
            }
        }
    }

    private func updateFontsFromTransform() {
        // Calculate scale from transform
        let scaleX = sqrt(transform.a * transform.a + transform.c * transform.c)
        let scaleY = sqrt(transform.b * transform.b + transform.d * transform.d)
        let averageScale = (scaleX + scaleY) / 2.0

        // Apply to font size
        let fontSize = baseFontSize * averageScale
        let clampedSize = min(max(fontSize, baseFontSize * 0.5), baseFontSize * 3.0)

        textLabel.font = currentFontStyle.font(size: clampedSize, weight: .bold)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // If already selected, open edit dialog
        if isSelected {
            textDelegate?.textWidgetDidRequestEdit(self)
        } else {
            // Otherwise, select the widget
            selectionDelegate?.itemWasSelected(self)
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        // Double tap also opens edit dialog
        textDelegate?.textWidgetDidRequestEdit(self)
    }

    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        currentColor = color
        updateColors()
    }

    func updateColors() {
        textLabel.textColor = currentColor
    }

    func updateFonts() {
        if initialSize == .zero {
            initialSize = bounds.size
        }

        let scaleFactor = calculateScaleFactor()
        let fontSize = baseFontSize * scaleFactor

        textLabel.font = currentFontStyle.font(size: fontSize, weight: .bold)

        print("🔤 Text widget font updated: style=\(currentFontStyle.displayName), size=\(fontSize)")
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
        textLabel.font = currentFontStyle.font(size: fontSize, weight: .bold)
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

        // Always update fonts when size changes
        if !transform.isIdentity {
            // Transform-based scaling (pinch gesture)
            updateFontsFromTransform()
        } else if initialSize != .zero && bounds.size != .zero {
            // Frame-based scaling (resize handles)
            let scaleFactor = calculateScaleFactor()
            let fontSize = baseFontSize * scaleFactor
            let clampedSize = min(max(fontSize, baseFontSize * 0.5), baseFontSize * 3.0)

            textLabel.font = currentFontStyle.font(size: clampedSize, weight: .bold)
        }

        // Update selection border if selected
        if isSelected {
            updateSelectionBorder()
        }
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

        return super.hitTest(point, with: event)
    }
}

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
