//
//  ClimbingWidgets.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/22/26.
//

import UIKit
import SnapKit

// MARK: - Base Climbing Widget

class BaseClimbingWidget: UIView, Selectable {
    // MARK: - Selectable Protocol Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .white {
        didSet { updateColors() }
    }
    var currentFontStyle: FontStyle = .system {
        didSet { updateFonts() }
    }
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?

    // MARK: - UI Components
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.7)
        label.textAlignment = .center
        return label
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()

    let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.7)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Properties
    var initialSize: CGSize = .zero
    private var initialCenter: CGPoint = .zero

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

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        unitLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
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

    // MARK: - Gesture Handlers
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        selectionDelegate?.itemWasSelected(self)
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

        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        switch gesture.state {
        case .changed:
            let currentWidth = view.frame.width
            let currentHeight = view.frame.height
            let newWidth = currentWidth * gesture.scale
            let newHeight = currentHeight * gesture.scale

            let minSize: CGFloat = 60
            let maxSize: CGFloat = 400

            let clampedWidth = max(minSize, min(maxSize, newWidth))
            let clampedHeight = max(minSize, min(maxSize, newHeight))

            let center = view.center
            view.frame.size = CGSize(width: clampedWidth, height: clampedHeight)
            view.center = center

            updateFonts()
            gesture.scale = 1.0

            if isSelected {
                positionResizeHandles()
            }

        default:
            break
        }
    }

    // MARK: - Selectable Methods
    func applyColor(_ color: UIColor) {
        currentColor = color
    }

    func applyFont(_ fontStyle: FontStyle) {
        currentFontStyle = fontStyle
        updateFonts()
    }

    func showSelectionState() {
        isSelected = true
        createResizeHandles()
        createSelectionBorder()
    }

    func hideSelectionState() {
        isSelected = false
        removeResizeHandles()
        removeSelectionBorder()
    }

    // MARK: - Update Methods
    func updateColors() {
        valueLabel.textColor = currentColor
        titleLabel.textColor = currentColor.withAlphaComponent(0.7)
        unitLabel.textColor = currentColor.withAlphaComponent(0.7)
    }

    func updateFonts() {
        guard initialSize.width > 0 && initialSize.height > 0 else { return }

        let scaleFactor = min(frame.width / initialSize.width, frame.height / initialSize.height)
        let clampedScale = max(0.5, min(3.0, scaleFactor))

        let baseTitleSize: CGFloat = 14
        let baseValueSize: CGFloat = 32
        let baseUnitSize: CGFloat = 12

        titleLabel.font = currentFontStyle.font(size: baseTitleSize * clampedScale, weight: .medium)
        valueLabel.font = currentFontStyle.font(size: baseValueSize * clampedScale, weight: .bold)
        unitLabel.font = currentFontStyle.font(size: baseUnitSize * clampedScale, weight: .regular)
    }

    // MARK: - Resize Handles
    private func createResizeHandles() {
        removeResizeHandles()

        let positions: [ResizeHandlePosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        for position in positions {
            let handle = ResizeHandleView(position: position)
            handle.parentView = self
            superview?.addSubview(handle)
            resizeHandles.append(handle)
        }

        positionResizeHandles()
    }

    private func removeResizeHandles() {
        resizeHandles.forEach { $0.removeFromSuperview() }
        resizeHandles.removeAll()
    }

    func positionResizeHandles() {
        let handleSize: CGFloat = 20
        let offset: CGFloat = handleSize / 2

        for handle in resizeHandles {
            switch handle.position {
            case .topLeft:
                handle.center = CGPoint(x: frame.minX - offset + handleSize/2, y: frame.minY - offset + handleSize/2)
            case .topRight:
                handle.center = CGPoint(x: frame.maxX + offset - handleSize/2, y: frame.minY - offset + handleSize/2)
            case .bottomLeft:
                handle.center = CGPoint(x: frame.minX - offset + handleSize/2, y: frame.maxY + offset - handleSize/2)
            case .bottomRight:
                handle.center = CGPoint(x: frame.maxX + offset - handleSize/2, y: frame.maxY + offset - handleSize/2)
            default:
                break
            }
        }
    }

    // MARK: - Selection Border
    private func createSelectionBorder() {
        removeSelectionBorder()

        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor.systemBlue.cgColor
        borderLayer.fillColor = nil
        borderLayer.lineWidth = 2
        borderLayer.lineDashPattern = [6, 4]
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(rect: bounds).cgPath
        layer.addSublayer(borderLayer)
        selectionBorderLayer = borderLayer
    }

    private func removeSelectionBorder() {
        selectionBorderLayer?.removeFromSuperlayer()
        selectionBorderLayer = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        selectionBorderLayer?.frame = bounds
        selectionBorderLayer?.path = UIBezierPath(rect: bounds).cgPath
        if isSelected {
            positionResizeHandles()
        }
    }
}

// MARK: - Gym Name Widget

class ClimbingGymWidget: BaseClimbingWidget {
    private var gymName: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "클라이밍짐"
        unitLabel.text = ""
        itemIdentifier = "climbing_gym_\(UUID().uuidString)"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(gymName: String) {
        self.gymName = gymName
        valueLabel.text = gymName
        initialSize = bounds.size
        updateFonts()
    }
}

// MARK: - Discipline Widget

class ClimbingDisciplineWidget: BaseClimbingWidget {
    private var discipline: ClimbingDiscipline = .bouldering

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "종목"
        unitLabel.text = ""
        itemIdentifier = "climbing_discipline_\(UUID().uuidString)"
        setupIcon()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupIcon()
    }

    private func setupIcon() {
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.trailing.equalTo(valueLabel.snp.leading).offset(-8)
            make.centerY.equalTo(valueLabel)
            make.width.height.equalTo(24)
        }
    }

    func configure(discipline: ClimbingDiscipline) {
        self.discipline = discipline
        valueLabel.text = discipline.displayName
        iconImageView.image = UIImage(systemName: discipline.iconName)
        initialSize = bounds.size
        updateFonts()
    }

    override func updateColors() {
        super.updateColors()
        iconImageView.tintColor = currentColor
    }
}

// MARK: - Grade Widget

class ClimbingGradeWidget: BaseClimbingWidget {
    private var grade: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "난이도"
        unitLabel.text = ""
        itemIdentifier = "climbing_grade_\(UUID().uuidString)"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(grade: String) {
        self.grade = grade
        valueLabel.text = grade
        initialSize = bounds.size
        updateFonts()
    }
}

// MARK: - Attempts Widget (Bouldering)

class ClimbingAttemptsWidget: BaseClimbingWidget {
    private var attempts: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "시도"
        unitLabel.text = "회"
        itemIdentifier = "climbing_attempts_\(UUID().uuidString)"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(attempts: Int) {
        self.attempts = attempts
        valueLabel.text = "\(attempts)"
        initialSize = bounds.size
        updateFonts()
    }
}

// MARK: - Takes Widget (Lead/Endurance)

class ClimbingTakesWidget: BaseClimbingWidget {
    private var takes: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "테이크"
        unitLabel.text = "회"
        itemIdentifier = "climbing_takes_\(UUID().uuidString)"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(takes: Int) {
        self.takes = takes
        valueLabel.text = "\(takes)"
        initialSize = bounds.size
        updateFonts()
    }
}

// MARK: - Session Summary Widget

class ClimbingSessionWidget: BaseClimbingWidget {
    private var sentCount: Int = 0
    private var totalCount: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "세션 기록"
        unitLabel.text = "완등"
        itemIdentifier = "climbing_session_\(UUID().uuidString)"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(sent: Int, total: Int) {
        self.sentCount = sent
        self.totalCount = total
        valueLabel.text = "\(sent)/\(total)"
        initialSize = bounds.size
        updateFonts()
    }
}

// MARK: - Highest Grade Widget

class ClimbingHighestGradeWidget: BaseClimbingWidget {
    private var highestGrade: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "최고 난이도"
        unitLabel.text = "완등"
        itemIdentifier = "climbing_highest_grade_\(UUID().uuidString)"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(highestGrade: String) {
        self.highestGrade = highestGrade
        valueLabel.text = highestGrade.isEmpty ? "-" : highestGrade
        initialSize = bounds.size
        updateFonts()
    }
}
