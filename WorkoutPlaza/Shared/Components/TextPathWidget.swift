//
//  TextPathWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/21/26.
//

import UIKit
import SnapKit

class TextPathWidget: UIView, Selectable {

    // MARK: - Selectable Properties
    var isSelected: Bool = false
    var currentColor: UIColor = .white {
        didSet {
            textColor = currentColor
            setNeedsDisplay()
        }
    }
    var currentFontStyle: FontStyle = .system
    var itemIdentifier: String = UUID().uuidString
    var resizeHandles: [ResizeHandleView] = []
    var selectionBorderLayer: CAShapeLayer?
    weak var selectionDelegate: SelectionDelegate?
    var initialSize: CGSize = .zero

    // MARK: - Text Path Properties

    /// 경로를 따라 반복할 텍스트
    private(set) var textToRepeat: String

    /// 정규화된 경로 좌표 (0~1 범위, 비율 유지용)
    private var normalizedPathPoints: [CGPoint] = []

    /// 현재 크기에 맞게 스케일된 경로 좌표
    private var scaledPathPoints: [CGPoint] = []

    /// 텍스트 색상
    private var textColor: UIColor = .white

    /// 기본 텍스트 폰트
    private var baseFont: UIFont = .boldSystemFont(ofSize: 20)

    /// 기본 텍스트 폰트 사이즈
    private var baseFontSize: CGFloat = 20

    // MARK: - Public Accessors for Persistence
    var text: String { textToRepeat }
    var normalizedPoints: [CGPoint] { normalizedPathPoints }
    var fontSize: CGFloat { baseFontSize }

    /// 글자 간격
    private let letterSpacing: CGFloat = 2.0

    // MARK: - Initialization

    init(text: String, pathPoints: [CGPoint], frame: CGRect, color: UIColor = .white, font: UIFont = .boldSystemFont(ofSize: 20), alreadySimplified: Bool = false) {
        self.textToRepeat = text
        self.textColor = color
        self.baseFont = font
        self.baseFontSize = font.pointSize
        super.init(frame: frame)
        self.initialSize = frame.size
        self.currentColor = color

        // 경로를 정규화 (0~1 범위로 변환)
        let simplified = alreadySimplified ? pathPoints : Self.simplifyPath(pathPoints, minDistance: 8.0)
        self.normalizedPathPoints = simplified.map { point in
            CGPoint(
                x: point.x / frame.width,
                y: point.y / frame.height
            )
        }
        updateScaledPathPoints()
        setupView()
    }

    // MARK: - Path Simplification

    /// 경로 단순화: 너무 가까운 점들을 제거하여 각도 계산을 안정화
    private static func simplifyPath(_ points: [CGPoint], minDistance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var simplified: [CGPoint] = [points[0]]

        for i in 1..<points.count {
            let lastPoint = simplified.last!
            let currentPoint = points[i]
            let dx = currentPoint.x - lastPoint.x
            let dy = currentPoint.y - lastPoint.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance >= minDistance {
                simplified.append(currentPoint)
            }
        }

        // 마지막 점은 항상 포함
        if let last = points.last, simplified.last != last {
            simplified.append(last)
        }

        return simplified.count >= 2 ? simplified : points
    }

    /// 현재 bounds에 맞게 스케일된 경로 좌표 업데이트
    private func updateScaledPathPoints() {
        scaledPathPoints = normalizedPathPoints.map { point in
            CGPoint(
                x: point.x * bounds.width,
                y: point.y * bounds.height
            )
        }
    }

    /// 현재 스케일에 맞는 폰트 사이즈 계산
    private var currentFontSize: CGFloat {
        guard initialSize.width > 0 else { return baseFontSize }
        let scale = bounds.width / initialSize.width
        return baseFontSize * scale
    }

    /// 현재 스케일에 맞는 폰트 (스타일 유지)
    private var currentFont: UIFont {
        return baseFont.withSize(currentFontSize)
    }

    /// 현재 스케일에 맞는 글자 간격 계산
    private var currentLetterSpacing: CGFloat {
        guard initialSize.width > 0 else { return letterSpacing }
        let scale = bounds.width / initialSize.width
        return letterSpacing * scale
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateScaledPathPoints()
        updateSelectionBorder()
        positionResizeHandles()
        setNeedsDisplay()
    }

    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true

        // Add tap gesture for selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)

        // Add pan gesture for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        selectionDelegate?.itemWasSelected(self)
    }

    private var initialCenter: CGPoint = .zero

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }

        switch gesture.state {
        case .began:
            initialCenter = center
            // Select this widget immediately when drag starts
            if !isSelected {
                selectionDelegate?.itemWasSelected(self)
            }

        case .changed:
            let translation = gesture.translation(in: superview)
            center = CGPoint(
                x: initialCenter.x + translation.x,
                y: initialCenter.y + translation.y
            )
            // 이동 시 핸들 위치 업데이트
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

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              scaledPathPoints.count >= 2 else { return }

        drawTextAlongPath(in: context)
    }

    /// 경로를 따라 텍스트 그리기
    private func drawTextAlongPath(in context: CGContext) {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: currentFont,
            .foregroundColor: textColor
        ]

        // 각 세그먼트의 길이와 누적 거리 계산
        var segmentLengths: [CGFloat] = []
        var cumulativeDistances: [CGFloat] = [0.0]

        for i in 0..<(scaledPathPoints.count - 1) {
            let dx = scaledPathPoints[i + 1].x - scaledPathPoints[i].x
            let dy = scaledPathPoints[i + 1].y - scaledPathPoints[i].y
            let length = sqrt(dx * dx + dy * dy)
            segmentLengths.append(length)
            cumulativeDistances.append(cumulativeDistances.last! + length)
        }

        let totalPathLength = cumulativeDistances.last ?? 0
        guard totalPathLength > 0 else { return }

        // 각 글자의 크기 미리 계산
        let characters = Array(textToRepeat)
        var characterWidths: [CGFloat] = []

        for char in characters {
            let charString = String(char)
            let size = charString.size(withAttributes: textAttributes)
            characterWidths.append(size.width)
        }

        // 전체 경로를 따라 글자 배치
        var currentDistance: CGFloat = 0.0
        var charIndex = 0

        while currentDistance < totalPathLength && charIndex < characters.count * 100 {
            let char = characters[charIndex % characters.count]
            let charString = String(char)
            let charWidth = characterWidths[charIndex % characters.count]
            let charSize = charString.size(withAttributes: textAttributes)

            // 글자 중심의 경로상 위치
            let charCenterDistance = currentDistance + charWidth / 2.0

            if charCenterDistance > totalPathLength {
                break
            }

            // 이 위치가 어느 세그먼트에 해당하는지 찾기
            var segmentIndex = 0
            for i in 0..<segmentLengths.count {
                if charCenterDistance <= cumulativeDistances[i + 1] {
                    segmentIndex = i
                    break
                }
            }

            let startPoint = scaledPathPoints[segmentIndex]
            let endPoint = scaledPathPoints[segmentIndex + 1]
            let segmentLength = segmentLengths[segmentIndex]

            guard segmentLength > 0 else {
                charIndex += 1
                continue
            }

            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y

            // 세그먼트 내에서의 위치 계산
            let distanceWithinSegment = charCenterDistance - cumulativeDistances[segmentIndex]

            let normalizedDx = dx / segmentLength
            let normalizedDy = dy / segmentLength

            let charX = startPoint.x + normalizedDx * distanceWithinSegment
            let charY = startPoint.y + normalizedDy * distanceWithinSegment

            // 각도 계산 (세그먼트 방향 그대로 사용)
            let angle = atan2(dy, dx)

            // 글자 그리기
            context.saveGState()
            context.translateBy(x: charX, y: charY)
            context.rotate(by: angle)

            let drawRect = CGRect(
                x: -charWidth / 2.0,
                y: -charSize.height / 2.0,
                width: charWidth,
                height: charSize.height
            )
            charString.draw(in: drawRect, withAttributes: textAttributes)

            context.restoreGState()

            // 다음 글자 위치로 이동
            currentDistance += charWidth + currentLetterSpacing
            charIndex += 1
        }
    }

    // MARK: - Selectable Methods

    func applyColor(_ color: UIColor) {
        currentColor = color
    }

    func applyFont(_ fontStyle: FontStyle) {
        // TextPathWidget doesn't support font changes
    }
}

// MARK: - Text Path Drawing Overlay View

class TextPathDrawingOverlay: UIView {
    private enum Constants {
        static let bottomToolbarHeight: CGFloat = 80
        static let buttonStackHeight: CGFloat = 40
        static let buttonStackWidth: CGFloat = 292
        static let controlButtonWidth: CGFloat = 60
        static let controlButtonHeight: CGFloat = 40
        static let expandedPanelHorizontalPadding: CGFloat = 20
        static let expandedPanelBottomOffset: CGFloat = 16
        static let expandedPanelHeight: CGFloat = 120
        static let colorStackHeight: CGFloat = 40
        static let fontStackHorizontalPadding: CGFloat = 16
        static let fontStackHeight: CGFloat = 40
        static let sizeContainerHorizontalPadding: CGFloat = 24
        static let sizeContainerHeight: CGFloat = 40
        static let sizeIconSize: CGFloat = 24
        static let sizeIconLeadingOffset: CGFloat = 12
        static let sizeLabelWidth: CGFloat = 30
        static let confirmButtonSize: CGFloat = 50
        static let confirmButtonBottomOffset: CGFloat = 12
        static let confirmButtonTrailingOffset: CGFloat = 20
        static let cancelButtonSize: CGFloat = 50
        static let redrawButtonSize: CGFloat = 40
        static let colorButtonSize: CGFloat = 36
    }

    // MARK: - Drawing State
    enum DrawingState {
        case ready      // 드래그 대기 중
        case drawing    // 드래그 중
        case preview    // 미리보기 (확인 대기)
    }

    enum DrawingMode {
        case freeform       // 자유곡선
        case straightLine   // 직선
    }

    private(set) var currentState: DrawingState = .ready
    private var currentDrawingMode: DrawingMode = .freeform

    /// 사용자가 드래그한 경로의 좌표들
    private(set) var pathPoints: [CGPoint] = []

    /// 직선 모드에서 시작점 저장
    private var straightLineStartPoint: CGPoint = .zero

    /// 반복할 텍스트
    var textToRepeat: String = ""

    /// 드로잉 가능한 캔버스 영역
    var canvasFrame: CGRect = .zero {
        didSet {
            updateGuideLabelPosition()
        }
    }

    /// 드래그 완료 콜백 (색상, 폰트 포함)
    var onDrawingComplete: (([CGPoint], CGRect, UIColor, UIFont) -> Void)?

    /// 드래그 취소 콜백
    var onDrawingCancelled: (() -> Void)?

    // MARK: - Style Properties
    private var selectedColor: UIColor = .white
    private var selectedFont: UIFont = .boldSystemFont(ofSize: 20)
    private var selectedFontSize: CGFloat = 20

    private let availableColors: [UIColor] = [
        .white,
        .systemYellow,
        .systemOrange,
        .systemPink,
        .systemRed,
        .systemGreen,
        .systemBlue,
        .systemPurple
    ]

    private let availableFonts: [(name: String, font: UIFont)] = [
        ("기본", .boldSystemFont(ofSize: 20)),
        ("얇게", .systemFont(ofSize: 20, weight: .light)),
        ("둥글게", .systemFont(ofSize: 20, weight: .medium)),
        ("굵게", .systemFont(ofSize: 20, weight: .black))
    ]

    private var selectedColorIndex: Int = 0
    private var selectedFontIndex: Int = 0

    // MARK: - UI Components
    private let guideLabel: UILabel = {
        let label = UILabel()
        label.text = "화면을 드래그하여\n텍스트 경로를 그려주세요"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }()

    private let bottomToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.layer.cornerRadius = 0
        return view
    }()

    // MARK: - Main Control Buttons
    private let colorButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        return button
    }()

    private let fontButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("기본", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        return button
    }()

    private let sizeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("20", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        return button
    }()

    private let modeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "scribble"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        return button
    }()

    // MARK: - Expanded Panels
    private let expandedPanelContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    private let colorStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .equalSpacing
        return stack
    }()

    private let fontStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fillEqually
        return stack
    }()

    private let fontSizeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 12
        slider.maximumValue = 40
        slider.value = 20
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        return slider
    }()

    private let fontSizeLabel: UILabel = {
        let label = UILabel()
        label.text = "20"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private enum ExpandedPanel {
        case color
        case font
        case size
    }

    private var currentExpandedPanel: ExpandedPanel?

    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.tintColor = .systemGreen
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 25
        button.isHidden = true
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemRed
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 25
        button.isHidden = true
        return button
    }()

    private let redrawButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 20
        button.isHidden = true
        return button
    }()

    private var colorButtons: [UIButton] = []
    private var fontButtons: [UIButton] = []

    private let letterSpacing: CGFloat = 2.0

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupUI()
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        isUserInteractionEnabled = true

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    private func setupUI() {
        // Guide Label
        addSubview(guideLabel)
        guideLabel.translatesAutoresizingMaskIntoConstraints = true
        guideLabel.sizeToFit()
        guideLabel.center = CGPoint(x: bounds.midX, y: bounds.midY)

        // Bottom Toolbar
        addSubview(bottomToolbar)
        bottomToolbar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(Constants.bottomToolbarHeight)
        }

        // Main control buttons in toolbar
        let buttonStack = UIStackView(arrangedSubviews: [modeButton, colorButton, fontButton, sizeButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.alignment = .center
        buttonStack.distribution = .fillEqually

        bottomToolbar.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(Constants.buttonStackHeight)
            make.width.equalTo(Constants.buttonStackWidth)
        }

        // Set button constraints
        [modeButton, colorButton, fontButton, sizeButton].forEach { button in
            button.snp.makeConstraints { make in
                make.width.equalTo(Constants.controlButtonWidth)
                make.height.equalTo(Constants.controlButtonHeight)
            }
        }

        modeButton.addTarget(self, action: #selector(modeButtonTapped), for: .touchUpInside)
        colorButton.addTarget(self, action: #selector(colorButtonMainTapped), for: .touchUpInside)
        fontButton.addTarget(self, action: #selector(fontButtonMainTapped), for: .touchUpInside)
        sizeButton.addTarget(self, action: #selector(sizeButtonMainTapped), for: .touchUpInside)

        // Expanded Panel Container
        addSubview(expandedPanelContainer)
        expandedPanelContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(bottomToolbar.snp.top).offset(-16)
            make.height.equalTo(120)
        }

        // Setup color panel
        expandedPanelContainer.addSubview(colorStackView)
        colorStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(40)
        }

        // Create color buttons
        for (index, color) in availableColors.enumerated() {
            let button = createColorButton(color: color, index: index)
            colorButtons.append(button)
            colorStackView.addArrangedSubview(button)
        }

        // Setup font panel
        expandedPanelContainer.addSubview(fontStackView)
        fontStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }

        // Create font buttons
        for (index, fontInfo) in availableFonts.enumerated() {
            let button = createFontButton(name: fontInfo.name, index: index)
            fontButtons.append(button)
            fontStackView.addArrangedSubview(button)
        }

        // Setup size panel
        let sizeContainer = UIView()
        expandedPanelContainer.addSubview(sizeContainer)
        sizeContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }

        let sizeIcon = UIImageView(image: UIImage(systemName: "textformat.size"))
        sizeIcon.tintColor = .white
        sizeIcon.contentMode = .scaleAspectFit
        sizeContainer.addSubview(sizeIcon)
        sizeIcon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(24)
        }

        sizeContainer.addSubview(fontSizeLabel)
        fontSizeLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(30)
        }

        sizeContainer.addSubview(fontSizeSlider)
        fontSizeSlider.snp.makeConstraints { make in
            make.leading.equalTo(sizeIcon.snp.trailing).offset(12)
            make.trailing.equalTo(fontSizeLabel.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        fontSizeSlider.addTarget(self, action: #selector(fontSizeSliderChanged(_:)), for: .valueChanged)

        updateColorSelection()
        updateFontSelection()
        hidePanelContent()

        // Confirm Button
        addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(bottomToolbar.snp.top).offset(-12)
            make.size.equalTo(50)
        }
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        // Cancel Button
        addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalTo(bottomToolbar.snp.top).offset(-12)
            make.size.equalTo(50)
        }
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        // Redraw Button
        addSubview(redrawButton)
        redrawButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(bottomToolbar.snp.top).offset(-12)
            make.size.equalTo(40)
        }
        redrawButton.addTarget(self, action: #selector(redrawTapped), for: .touchUpInside)
    }

    private func createColorButton(color: UIColor, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = color
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.clear.cgColor
        button.tag = index
        button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)

        button.snp.makeConstraints { make in
            make.size.equalTo(36)
        }

        return button
    }

    private func createFontButton(name: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(name, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.tag = index
        button.addTarget(self, action: #selector(fontButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    // MARK: - Panel Management
    private func hidePanelContent() {
        colorStackView.isHidden = true
        fontStackView.isHidden = true
        fontSizeSlider.superview?.isHidden = true
    }

    private func showPanel(_ panel: ExpandedPanel) {
        if currentExpandedPanel == panel {
            hidePanel()
            return
        }

        currentExpandedPanel = panel
        expandedPanelContainer.isHidden = false
        hidePanelContent()

        switch panel {
        case .color:
            colorStackView.isHidden = false
        case .font:
            fontStackView.isHidden = false
        case .size:
            fontSizeSlider.superview?.isHidden = false
        }

        // Animate panel appearance
        expandedPanelContainer.alpha = 0
        expandedPanelContainer.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.expandedPanelContainer.alpha = 1
            self.expandedPanelContainer.transform = .identity
        }
    }

    private func hidePanel() {
        UIView.animate(withDuration: 0.2) {
            self.expandedPanelContainer.alpha = 0
            self.expandedPanelContainer.transform = CGAffineTransform(translationX: 0, y: 20)
        } completion: { _ in
            self.expandedPanelContainer.isHidden = true
            self.currentExpandedPanel = nil
        }
    }

    // MARK: - Main Button Actions
    @objc private func modeButtonTapped() {
        // Toggle drawing mode
        currentDrawingMode = currentDrawingMode == .freeform ? .straightLine : .freeform
        updateModeButton()
    }

    private func updateModeButton() {
        let iconName = currentDrawingMode == .freeform ? "scribble" : "line.diagonal"
        modeButton.setImage(UIImage(systemName: iconName), for: .normal)
    }

    @objc private func colorButtonMainTapped() {
        showPanel(.color)
    }

    @objc private func fontButtonMainTapped() {
        showPanel(.font)
    }

    @objc private func sizeButtonMainTapped() {
        showPanel(.size)
    }

    // MARK: - Selection Updates
    private func updateColorSelection() {
        for (index, button) in colorButtons.enumerated() {
            button.layer.borderColor = index == selectedColorIndex ?
                UIColor.white.cgColor : UIColor.clear.cgColor
            button.transform = index == selectedColorIndex ?
                CGAffineTransform(scaleX: 1.15, y: 1.15) : .identity
        }
        selectedColor = availableColors[selectedColorIndex]

        // Update main color button
        colorButton.backgroundColor = selectedColor

        setNeedsDisplay()
    }

    private func updateFontSelection() {
        for (index, button) in fontButtons.enumerated() {
            button.backgroundColor = index == selectedFontIndex ?
                UIColor.white.withAlphaComponent(0.3) : UIColor.white.withAlphaComponent(0.1)
        }
        // Apply selected font style with selected size
        let baseFont = availableFonts[selectedFontIndex].font
        selectedFont = baseFont.withSize(selectedFontSize)

        // Update main font button
        fontButton.setTitle(availableFonts[selectedFontIndex].name, for: .normal)

        setNeedsDisplay()
    }

    // MARK: - Button Actions
    @objc private func colorButtonTapped(_ sender: UIButton) {
        selectedColorIndex = sender.tag
        UIView.animate(withDuration: 0.2) {
            self.updateColorSelection()
        } completion: { _ in
            // Auto-hide panel after selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.hidePanel()
            }
        }
    }

    @objc private func fontButtonTapped(_ sender: UIButton) {
        selectedFontIndex = sender.tag
        UIView.animate(withDuration: 0.2) {
            self.updateFontSelection()
        } completion: { _ in
            // Auto-hide panel after selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.hidePanel()
            }
        }
    }

    @objc private func fontSizeSliderChanged(_ sender: UISlider) {
        selectedFontSize = CGFloat(sender.value)
        fontSizeLabel.text = "\(Int(selectedFontSize))"
        sizeButton.setTitle("\(Int(selectedFontSize))", for: .normal)
        updateFontSelection()
    }

    @objc private func confirmTapped() {
        guard pathPoints.count >= 2 else { return }
        let boundingRect = calculateBoundingRect()
        onDrawingComplete?(pathPoints, boundingRect, selectedColor, selectedFont)
    }

    @objc private func cancelTapped() {
        onDrawingCancelled?()
    }

    @objc private func redrawTapped() {
        pathPoints.removeAll()
        currentState = .ready
        updateUIForState()
        setNeedsDisplay()
    }

    // MARK: - State Management
    private func updateUIForState() {
        // Toolbar와 버튼들은 항상 표시
        bottomToolbar.isHidden = false

        switch currentState {
        case .ready:
            guideLabel.isHidden = false
            confirmButton.isHidden = true
            cancelButton.isHidden = true
            redrawButton.isHidden = true

        case .drawing:
            guideLabel.isHidden = true
            confirmButton.isHidden = true
            cancelButton.isHidden = true
            redrawButton.isHidden = true

        case .preview:
            guideLabel.isHidden = true
            confirmButton.isHidden = false
            cancelButton.isHidden = false
            redrawButton.isHidden = false
        }
    }

    private func updateGuideLabelPosition() {
        guard !canvasFrame.isEmpty else { return }
        guideLabel.center = CGPoint(
            x: canvasFrame.midX,
            y: canvasFrame.midY
        )
    }

    // MARK: - Gesture Handlers
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)

        // Check if tap is inside expanded panel or toolbar
        if !expandedPanelContainer.isHidden && expandedPanelContainer.frame.contains(location) {
            return
        }

        if bottomToolbar.frame.contains(location) {
            return
        }

        // Hide panel if it's open
        if !expandedPanelContainer.isHidden {
            hidePanel()
            return
        }

        // 미리보기 상태가 아닐 때만 취소
        if currentState == .ready {
            onDrawingCancelled?()
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)

        // Only allow drawing within canvas frame
        guard canvasFrame.contains(location) || currentState == .drawing else {
            return
        }

        switch gesture.state {
        case .began:
            guard canvasFrame.contains(location) else { return }
            straightLineStartPoint = location
            pathPoints = [location]
            currentState = .drawing
            updateUIForState()

        case .changed:
            if currentDrawingMode == .straightLine {
                // 직선 모드: 시작점과 현재점만 유지
                pathPoints = [straightLineStartPoint, location]
            } else {
                // 자유곡선 모드: 계속 추가
                pathPoints.append(location)
            }
            setNeedsDisplay()

        case .ended, .cancelled:
            if currentDrawingMode == .straightLine {
                // 직선 모드: 시작점과 끝점
                pathPoints = [straightLineStartPoint, location]
            } else {
                // 자유곡선 모드: 마지막 점 추가
                pathPoints.append(location)
            }

            if pathPoints.count >= 2 {
                currentState = .preview
            } else {
                currentState = .ready
            }
            updateUIForState()
            setNeedsDisplay()

        default:
            break
        }
    }

    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              pathPoints.count >= 2 else { return }

        drawTextAlongPath(in: context)
    }

    private var currentTextAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: selectedFont,
            .foregroundColor: selectedColor
        ]
    }

    private func calculateBoundingRect() -> CGRect {
        guard !pathPoints.isEmpty else { return .zero }

        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude

        for point in pathPoints {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }

        let padding: CGFloat = 30
        return CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + padding * 2,
            height: maxY - minY + padding * 2
        )
    }

    private func simplifyPath(_ points: [CGPoint], minDistance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var simplified: [CGPoint] = [points[0]]

        for i in 1..<points.count {
            let lastPoint = simplified.last!
            let currentPoint = points[i]
            let dx = currentPoint.x - lastPoint.x
            let dy = currentPoint.y - lastPoint.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance >= minDistance {
                simplified.append(currentPoint)
            }
        }

        if let last = points.last, simplified.last != last {
            simplified.append(last)
        }

        return simplified.count >= 2 ? simplified : points
    }

    private func drawTextAlongPath(in context: CGContext) {
        guard !textToRepeat.isEmpty else { return }

        let simplifiedPath = simplifyPath(pathPoints, minDistance: 8.0)
        guard simplifiedPath.count >= 2 else { return }

        var segmentLengths: [CGFloat] = []
        var cumulativeDistances: [CGFloat] = [0.0]

        for i in 0..<(simplifiedPath.count - 1) {
            let dx = simplifiedPath[i + 1].x - simplifiedPath[i].x
            let dy = simplifiedPath[i + 1].y - simplifiedPath[i].y
            let length = sqrt(dx * dx + dy * dy)
            segmentLengths.append(length)
            cumulativeDistances.append(cumulativeDistances.last! + length)
        }

        let totalPathLength = cumulativeDistances.last ?? 0
        guard totalPathLength > 0 else { return }

        let characters = Array(textToRepeat)
        var characterWidths: [CGFloat] = []

        for char in characters {
            let charString = String(char)
            let size = charString.size(withAttributes: currentTextAttributes)
            characterWidths.append(size.width)
        }

        var currentDistance: CGFloat = 0.0
        var charIndex = 0

        while currentDistance < totalPathLength && charIndex < characters.count * 100 {
            let char = characters[charIndex % characters.count]
            let charString = String(char)
            let charWidth = characterWidths[charIndex % characters.count]
            let charSize = charString.size(withAttributes: currentTextAttributes)

            let charCenterDistance = currentDistance + charWidth / 2.0

            if charCenterDistance > totalPathLength {
                break
            }

            var segmentIndex = 0
            for i in 0..<segmentLengths.count {
                if charCenterDistance <= cumulativeDistances[i + 1] {
                    segmentIndex = i
                    break
                }
            }

            let startPoint = simplifiedPath[segmentIndex]
            let endPoint = simplifiedPath[segmentIndex + 1]
            let segmentLength = segmentLengths[segmentIndex]

            guard segmentLength > 0 else {
                charIndex += 1
                continue
            }

            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y

            let distanceWithinSegment = charCenterDistance - cumulativeDistances[segmentIndex]

            let normalizedDx = dx / segmentLength
            let normalizedDy = dy / segmentLength

            let charX = startPoint.x + normalizedDx * distanceWithinSegment
            let charY = startPoint.y + normalizedDy * distanceWithinSegment

            let angle = atan2(dy, dx)

            context.saveGState()
            context.translateBy(x: charX, y: charY)
            context.rotate(by: angle)

            let drawRect = CGRect(
                x: -charWidth / 2.0,
                y: -charSize.height / 2.0,
                width: charWidth,
                height: charSize.height
            )
            charString.draw(in: drawRect, withAttributes: currentTextAttributes)

            context.restoreGState()

            currentDistance += charWidth + letterSpacing
            charIndex += 1
        }
    }

    func reset() {
        pathPoints.removeAll()
        straightLineStartPoint = .zero
        currentState = .ready
        currentDrawingMode = .freeform
        selectedColorIndex = 0
        selectedFontIndex = 0
        selectedFontSize = 20
        fontSizeSlider.value = 20
        fontSizeLabel.text = "20"
        sizeButton.setTitle("20", for: .normal)
        updateModeButton()
        hidePanel()
        updateColorSelection()
        updateFontSelection()
        updateUIForState()
        setNeedsDisplay()
    }
}
