//
//  WidgetTemplate.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import SnapKit
import UIKit
import CoreLocation

// MARK: - Widget Template Models

struct WidgetTemplate: Codable {
    let id: String
    let name: String
    let description: String
    let version: String
    let sportType: SportType  // Sport type for filtering
    let items: [WidgetItem]

    // Canvas information (for proper scaling)
    let canvasSize: CanvasSize?

    // Background information
    let backgroundImageAspectRatio: CGFloat?
    let backgroundTransform: BackgroundTransformData?

    // Minimum app version required to use this template
    let minimumAppVersion: String?

    var isCompatible: Bool {
        guard let minVersion = minimumAppVersion else { return true }
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        return current.compare(minVersion, options: .numeric) != .orderedAscending
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        version: String = "2.0",
        sportType: SportType = .running,
        items: [WidgetItem],
        canvasSize: CanvasSize? = nil,
        backgroundImageAspectRatio: CGFloat? = nil,
        backgroundTransform: BackgroundTransformData? = nil,
        minimumAppVersion: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.sportType = sportType
        self.items = items
        self.canvasSize = canvasSize
        self.backgroundImageAspectRatio = backgroundImageAspectRatio
        self.backgroundTransform = backgroundTransform
        self.minimumAppVersion = minimumAppVersion
    }

    struct CanvasSize: Codable {
        let width: CGFloat
        let height: CGFloat
    }

    private var resolvedCanvasSize: CGSize {
        let fallback = CGSize(width: 414, height: 552)
        guard let canvasSize else { return fallback }

        let width = canvasSize.width
        let height = canvasSize.height
        guard width.isFinite, height.isFinite, width > 0, height > 0 else {
            return fallback
        }

        return CGSize(width: width, height: height)
    }

    private func thumbnailRenderCanvasSize(for templateCanvasSize: CGSize) -> CGSize {
        let maxRenderSide: CGFloat = 420
        let maxSide = max(templateCanvasSize.width, templateCanvasSize.height)
        guard maxSide.isFinite, maxSide > 0 else { return templateCanvasSize }

        let scale = min(1.0, maxRenderSide / maxSide)
        return CGSize(
            width: templateCanvasSize.width * scale,
            height: templateCanvasSize.height * scale
        )
    }

    /// Creates a closure that produces a miniature preview of this template's layout.
    func thumbnailProvider(widgetFactory: @escaping (WidgetItem, CGRect) -> UIView?) -> (() -> UIView) {
        return { [self] in
            let canvasView = UIView()
            canvasView.backgroundColor = ColorSystem.cardBackground
            canvasView.clipsToBounds = true
            canvasView.layer.cornerRadius = 8

            let templateCanvasSize = self.resolvedCanvasSize
            let renderCanvasSize = self.thumbnailRenderCanvasSize(for: templateCanvasSize)
            canvasView.frame = CGRect(origin: .zero, size: renderCanvasSize)

            for item in self.items {
                let frame = TemplateManager.absoluteFrame(
                    from: item,
                    canvasSize: renderCanvasSize,
                    templateCanvasSize: templateCanvasSize
                )
                if let widget = widgetFactory(item, frame) {
                    widget.isUserInteractionEnabled = false
                    widget.clipsToBounds = true
                    if let statWidget = widget as? BaseStatWidget {
                        statWidget.forceWhiteForPreview()
                    } else if let selectable = widget as? Selectable {
                        selectable.applyColor(.white)
                    }
                    canvasView.addSubview(widget)
                }
            }
            return canvasView
        }
    }
}

struct BackgroundTransformData: Codable {
    let scale: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat
}

struct WidgetItem: Codable {
    let type: WidgetType
    let position: Position
    let size: Size
    let color: String?  // Hex color string
    let font: String?   // Font style name
    let payload: String? // Widget-specific JSON payload
    let layout: String?  // WidgetDisplayMode rawValue (version 3.0+)

    // Ratio-based positioning (version 2.0+)
    let positionRatio: PositionRatio?
    let sizeRatio: SizeRatio?

    // Group information (version 2.1+)
    let groupId: String?
    let groupType: WidgetGroupType?
    let ownerName: String?  // For imported records

    // Rotation (version 2.2+)
    let rotation: CGFloat?  // Rotation in radians

    /// 위젯의 디스플레이 모드 (구버전 호환: nil이면 .text)
    var displayMode: WidgetDisplayMode {
        guard let layout = layout else { return .text }
        return WidgetDisplayMode(rawValue: layout) ?? .text
    }

    struct Position: Codable {
        let x: CGFloat
        let y: CGFloat
    }

    struct Size: Codable {
        let width: CGFloat
        let height: CGFloat
    }

    struct PositionRatio: Codable {
        let x: CGFloat  // 0.0 ~ 1.0
        let y: CGFloat  // 0.0 ~ 1.0
    }

    struct SizeRatio: Codable {
        let width: CGFloat   // 0.0 ~ 1.0
        let height: CGFloat  // 0.0 ~ 1.0
    }

    // Initializer for ratio-based items (version 2.0)
    init(
        type: WidgetType,
        positionRatio: PositionRatio,
        sizeRatio: SizeRatio,
        color: String? = nil,
        font: String? = nil,
        payload: String? = nil,
        groupId: String? = nil,
        groupType: WidgetGroupType? = nil,
        ownerName: String? = nil,
        rotation: CGFloat? = nil
    ) {
        self.type = type
        self.positionRatio = positionRatio
        self.sizeRatio = sizeRatio
        self.color = color
        self.font = font
        self.payload = payload
        self.groupId = groupId
        self.groupType = groupType
        self.ownerName = ownerName
        self.rotation = rotation
        self.layout = nil

        // Legacy fields (will be calculated when needed)
        self.position = Position(x: 0, y: 0)
        self.size = Size(width: 0, height: 0)
    }

    // Initializer for ratio-based items with layout (version 3.0)
    init(
        type: WidgetType,
        positionRatio: PositionRatio,
        sizeRatio: SizeRatio,
        color: String? = nil,
        font: String? = nil,
        payload: String? = nil,
        layout: String? = nil,
        groupId: String? = nil,
        groupType: WidgetGroupType? = nil,
        ownerName: String? = nil,
        rotation: CGFloat? = nil
    ) {
        self.type = type
        self.positionRatio = positionRatio
        self.sizeRatio = sizeRatio
        self.color = color
        self.font = font
        self.payload = payload
        self.layout = layout
        self.groupId = groupId
        self.groupType = groupType
        self.ownerName = ownerName
        self.rotation = rotation
        self.position = Position(x: 0, y: 0)
        self.size = Size(width: 0, height: 0)
    }

    // Initializer for legacy absolute-positioned items (version 1.0)
    init(
        type: WidgetType,
        position: Position,
        size: Size,
        color: String? = nil,
        font: String? = nil,
        payload: String? = nil,
        groupId: String? = nil,
        groupType: WidgetGroupType? = nil,
        ownerName: String? = nil
    ) {
        self.type = type
        self.position = position
        self.size = size
        self.color = color
        self.font = font
        self.payload = payload
        self.layout = nil
        self.groupId = groupId
        self.groupType = groupType
        self.ownerName = ownerName
        self.rotation = nil

        // Ratio fields are nil for legacy templates
        self.positionRatio = nil
        self.sizeRatio = nil
    }
}

enum WidgetType: String, Codable, CaseIterable {
    // Running Widgets — Text (default)
    case routeMap = "RouteMap"
    case distance = "Distance"
    case duration = "Duration"
    case pace = "Pace"
    case speed = "Speed"
    case calories = "Calories"
    case heartRate = "HeartRate"
    case date = "Date"
    case text = "Text"
    case location = "Location"
    case currentDateTime = "CurrentDateTime"
    case composite = "Composite"

    // Running Widgets — Compact
    case distanceCompact = "DistanceCompact"
    case durationCompact = "DurationCompact"
    case paceCompact = "PaceCompact"
    case speedCompact = "SpeedCompact"
    case caloriesCompact = "CaloriesCompact"
    case heartRateCompact = "HeartRateCompact"
    case dateCompact = "DateCompact"

    // Running Widgets — Icon
    case distanceIcon = "DistanceIcon"
    case durationIcon = "DurationIcon"
    case paceIcon = "PaceIcon"
    case speedIcon = "SpeedIcon"
    case caloriesIcon = "CaloriesIcon"
    case heartRateIcon = "HeartRateIcon"
    case dateIcon = "DateIcon"

    // Shared Decorative Widgets
    case speechBubble = "SpeechBubble"

    // Climbing Widgets
    case climbingGym = "ClimbingGym"
    case climbingDiscipline = "ClimbingDiscipline"
    case climbingSession = "ClimbingSession"
    case climbingRoutesByColor = "ClimbingRoutesByColor"
    case gymLogo = "GymLogo"

    /// 레이아웃 변형의 기본 타입 (e.g. .distanceCompact → .distance)
    var baseType: WidgetType {
        switch self {
        case .distanceCompact, .distanceIcon: return .distance
        case .durationCompact, .durationIcon: return .duration
        case .paceCompact, .paceIcon: return .pace
        case .speedCompact, .speedIcon: return .speed
        case .caloriesCompact, .caloriesIcon: return .calories
        case .heartRateCompact, .heartRateIcon: return .heartRate
        case .dateCompact, .dateIcon: return .date
        default: return self
        }
    }

    /// 타입에 내재된 레이아웃 모드
    var inherentDisplayMode: WidgetDisplayMode {
        switch self {
        case .distanceCompact, .durationCompact, .paceCompact, .speedCompact,
             .caloriesCompact, .heartRateCompact, .dateCompact:
            return .textUnified
        case .distanceIcon, .durationIcon, .paceIcon, .speedIcon,
             .caloriesIcon, .heartRateIcon, .dateIcon:
            return .icon
        default:
            return .text
        }
    }

    /// 같은 데이터를 공유하는 타입 그룹인지 (싱글턴 체크용)
    var singletonGroup: WidgetType {
        return baseType
    }

    var layoutDescription: String {
        switch inherentDisplayMode {
        case .text: return "텍스트"
        case .textUnified: return "컴팩트"
        case .icon: return "아이콘"
        }
    }

    var displayName: String {
        switch baseType {
        case .routeMap: return WorkoutPlazaStrings.Widget.Route.map
        case .distance: return WorkoutPlazaStrings.Widget.distance
        case .duration: return WorkoutPlazaStrings.Widget.duration
        case .pace: return WorkoutPlazaStrings.Widget.pace
        case .speed: return WorkoutPlazaStrings.Widget.speed
        case .calories: return WorkoutPlazaStrings.Widget.calories
        case .heartRate: return WorkoutPlazaStrings.Widget.Heart.rate
        case .date: return WorkoutPlazaStrings.Widget.date
        case .text: return WorkoutPlazaStrings.Widget.text
        case .location: return WorkoutPlazaStrings.Widget.location
        case .currentDateTime: return WorkoutPlazaStrings.Widget.Current.datetime
        case .composite: return WorkoutPlazaStrings.Widget.composite
        case .speechBubble: return NSLocalizedString("widget.speechBubble", comment: "말풍선")
        case .climbingGym: return WorkoutPlazaStrings.Widget.Climbing.gym
        case .climbingDiscipline: return WorkoutPlazaStrings.Widget.Climbing.discipline
        case .climbingSession: return WorkoutPlazaStrings.Widget.Climbing.session
        case .climbingRoutesByColor: return WorkoutPlazaStrings.Widget.Climbing.Routes.By.color
        case .gymLogo: return WorkoutPlazaStrings.Widget.Gym.logo
        default: return baseType.displayName
        }
    }

    var iconName: String {
        switch baseType {
        case .routeMap: return "map"
        case .distance: return "icon.person.run"
        case .duration: return "timer"
        case .pace: return "speedometer"
        case .speed: return "gauge.high"
        case .calories: return "flame"
        case .heartRate: return "heart.fill"
        case .date: return "calendar"
        case .text: return "icon.text.aa"
        case .location: return "location"
        case .currentDateTime: return "clock"
        case .composite: return "icon.grid.four"
        case .speechBubble: return "message.fill"
        case .climbingGym: return "building.2"
        case .climbingDiscipline: return "icon.mountains"
        case .climbingSession: return "checkmark.circle"
        case .climbingRoutesByColor: return "list.bullet.circle"
        case .gymLogo: return "photo.circle"
        default: return baseType.iconName
        }
    }

    var supportedSports: [SportType] {
        switch baseType {
        case .routeMap, .distance, .duration, .pace, .speed, .calories, .heartRate, .location:
            return [.running]
        case .climbingGym, .climbingDiscipline, .climbingSession, .climbingRoutesByColor, .gymLogo:
            return [.climbing]
        case .date, .text, .composite, .currentDateTime, .speechBubble:
            return SportType.allCases
        default:
            return baseType.supportedSports
        }
    }

    private static func gymHasLocalPreviewLogo(_ gym: ClimbingGym) -> Bool {
        switch gym.logoSource {
        case .assetName, .imageData:
            return true
        case .url, .none:
            return false
        }
    }

    private static func gymHasAnyPreviewLogo(_ gym: ClimbingGym) -> Bool {
        switch gym.logoSource {
        case .assetName, .imageData:
            return true
        case .url(let url):
            return !url.isEmpty
        case .none:
            return false
        }
    }

    private static func sampleGymForLogoPreview() -> ClimbingGym {
        let allGyms = ClimbingGymManager.shared.getAllGyms()
        let placeholderSource: ClimbingGym.LogoSource = {
            if let data = UIImage(named: "icon.buildings.fill")?.pngData() {
                return .imageData(data)
            }
            return .none
        }()

        if let localLogoGym = allGyms.first(where: gymHasLocalPreviewLogo) {
            return localLogoGym
        }

        if let anyLogoGym = allGyms.first(where: gymHasAnyPreviewLogo) {
            return anyLogoGym
        }

        if let anyGym = allGyms.first {
            return ClimbingGym(
                id: anyGym.id,
                name: anyGym.name,
                logoSource: placeholderSource,
                gradeColors: anyGym.gradeColors,
                branchColor: anyGym.branchColor,
                isBuiltIn: anyGym.isBuiltIn,
                metadata: anyGym.metadata
            )
        }

        return ClimbingGym(
            id: "preview_gym_logo",
            name: WorkoutPlazaStrings.Widget.Gym.logo,
            logoSource: placeholderSource,
            gradeColors: [],
            isBuiltIn: true,
            metadata: nil
        )
    }

    /// 샘플 데이터로 실제 위젯을 렌더링하는 미리보기 클로저. nil이면 아이콘 모드 유지.
    var previewProvider: (() -> UIView)? {
        let size: CGSize
        switch self.inherentDisplayMode {
        case .icon: size = CGSize(width: 160, height: 50)
        case .textUnified: size = CGSize(width: 140, height: 55)
        case .text: size = CGSize(width: 140, height: 65)
        }

        switch self {
        case .distance, .distanceCompact, .distanceIcon:
            return {
                let w = DistanceWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(distance: 5230)
                w.setDisplayMode(self.inherentDisplayMode)
                w.forceWhiteForPreview()
                return w
            }
        case .duration, .durationCompact, .durationIcon:
            return {
                let w = DurationWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(duration: 1860)
                w.setDisplayMode(self.inherentDisplayMode)
                w.forceWhiteForPreview()
                return w
            }
        case .pace, .paceCompact, .paceIcon:
            return {
                let w = PaceWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(pace: 5.42)
                w.setDisplayMode(self.inherentDisplayMode)
                w.forceWhiteForPreview()
                return w
            }
        case .speed, .speedCompact, .speedIcon:
            return {
                let w = SpeedWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(speed: 11.2)
                w.setDisplayMode(self.inherentDisplayMode)
                w.forceWhiteForPreview()
                return w
            }
        case .calories, .caloriesCompact, .caloriesIcon:
            return {
                let w = CaloriesWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(calories: 320)
                w.setDisplayMode(self.inherentDisplayMode)
                w.forceWhiteForPreview()
                return w
            }
        case .heartRate, .heartRateCompact, .heartRateIcon:
            return {
                let w = HeartRateWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(heartRate: 155)
                w.setDisplayMode(self.inherentDisplayMode)
                w.forceWhiteForPreview()
                return w
            }
        case .date, .dateCompact, .dateIcon:
            return {
                let w = DateWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(startDate: Date())
                w.setDisplayMode(self.inherentDisplayMode)
                w.applyColor(.white)
                if self.inherentDisplayMode == .text {
                    w.titleLabel.isHidden = true
                    w.valueLabel.textAlignment = .center
                    w.valueLabel.snp.remakeConstraints { make in
                        make.center.equalToSuperview()
                        make.leading.trailing.equalToSuperview().inset(LayoutConstants.standardPadding)
                    }
                }
                return w
            }
        case .currentDateTime:
            return {
                let w = CurrentDateTimeWidget()
                w.frame = CGRect(origin: .zero, size: CGSize(width: 160, height: 65))
                w.configure(date: Date())
                w.applyColor(.white)
                w.titleLabel.isHidden = true
                return w
            }
        case .text:
            return {
                let w = TextWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(text: WorkoutPlazaStrings.Widget.text)
                w.applyColor(.white)
                return w
            }
        case .climbingGym:
            return {
                let w = ClimbingGymWidget()
                w.frame = CGRect(origin: .zero, size: size)
                if let sampleGym = ClimbingGymManager.shared.getAllGyms().first {
                    w.configure(
                        gymName: sampleGym.name,
                        gymId: sampleGym.id,
                        gymBranch: sampleGym.metadata?.branch,
                        gymRegion: sampleGym.metadata?.region,
                        displayName: sampleGym.displayName
                    )
                } else {
                    w.configure(gymName: WorkoutPlazaStrings.Widget.Climbing.gym)
                }
                w.forceWhiteForPreview()
                return w
            }
        case .climbingDiscipline:
            return {
                let w = ClimbingDisciplineWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(discipline: .bouldering)
                w.forceWhiteForPreview()
                return w
            }
        case .climbingSession:
            return {
                let w = ClimbingSessionWidget()
                w.frame = CGRect(origin: .zero, size: size)
                w.configure(sent: 8, total: 12)
                w.forceWhiteForPreview()
                return w
            }
        case .routeMap:
            return {
                let w = RouteMapView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 75)))
                // 샘플 GPS: 구불구불한 경로
                let baseLat = 37.5665
                let baseLon = 126.9780
                let sampleLocations: [CLLocation] = [
                    CLLocation(latitude: baseLat, longitude: baseLon),
                    CLLocation(latitude: baseLat + 0.001, longitude: baseLon + 0.0005),
                    CLLocation(latitude: baseLat + 0.0015, longitude: baseLon + 0.0015),
                    CLLocation(latitude: baseLat + 0.0025, longitude: baseLon + 0.001),
                    CLLocation(latitude: baseLat + 0.003, longitude: baseLon + 0.002),
                    CLLocation(latitude: baseLat + 0.004, longitude: baseLon + 0.0015),
                    CLLocation(latitude: baseLat + 0.0045, longitude: baseLon + 0.0025),
                    CLLocation(latitude: baseLat + 0.005, longitude: baseLon + 0.002),
                    CLLocation(latitude: baseLat + 0.006, longitude: baseLon + 0.003),
                    CLLocation(latitude: baseLat + 0.0065, longitude: baseLon + 0.0025),
                    CLLocation(latitude: baseLat + 0.007, longitude: baseLon + 0.0035),
                ]
                w.setRoute(sampleLocations)
                w.applyColor(.white)
                return w
            }
        case .location:
            return {
                let w = LocationWidget(frame: CGRect(origin: .zero, size: size))
                w.configure(withText: "서울특별시")
                w.applyColor(.white)
                return w
            }
        case .climbingRoutesByColor:
            return {
                let w = ClimbingRoutesByColorWidget(frame: CGRect(origin: .zero, size: CGSize(width: 140, height: 90)))
                w.initialSize = CGSize(width: 140, height: 90)
                // 샘플 루트 데이터
                let sampleRoutes: [ClimbingRoute] = {
                    var routes: [ClimbingRoute] = []
                    let colors = [
                        ColorSystem.sampleRouteRed.hexString,
                        ColorSystem.sampleRouteOrange.hexString,
                        ColorSystem.sampleRouteGreen.hexString
                    ]
                    let sentCounts = [3, 2, 1]
                    let totalCounts = [4, 3, 2]
                    for (i, color) in colors.enumerated() {
                        for j in 0..<totalCounts[i] {
                            let route = ClimbingRoute(grade: "", colorHex: color, isSent: j < sentCounts[i])
                            routes.append(route)
                        }
                    }
                    return routes
                }()
                w.configure(routes: sampleRoutes)
                return w
            }
        case .gymLogo:
            return {
                let w = GymLogoWidget(frame: CGRect(origin: .zero, size: size))
                let sampleGym = WidgetType.sampleGymForLogoPreview()
                w.configure(with: sampleGym)
                return w
            }
        case .composite:
            return {
                let compositeSize = CGSize(width: 140, height: 90)
                let w = CompositeWidget()
                w.frame = CGRect(origin: .zero, size: compositeSize)
                w.configure(payload: CompositeWidgetPayload(
                    title: WorkoutPlazaStrings.Widget.composite,
                    primaryText: "5.20 km",
                    secondaryText: "42:30"
                ))
                return w
            }
        case .speechBubble:
            return {
                let bubbleSize = CGSize(width: 140, height: 90)
                let w = SpeechBubbleWidget()
                w.frame = CGRect(origin: .zero, size: bubbleSize)
                w.initialSize = bubbleSize
                let lang = Locale.current.language.languageCode?.identifier ?? "en"
                w.configure(payload: SpeechBubblePayload(
                    text: lang == "ko" ? "오늘도 달렸다!" : "Great run!",
                    style: .roundedBubble,
                    bubbleColorHex: "#FFFFFF",
                    borderColorHex: "#222222",
                    borderWidth: 2,
                    textColorHex: "#111111",
                    fontStyleRaw: FontStyle.system.rawValue,
                    fontSize: 13
                ))
                return w
            }
        }
    }
}

// MARK: - Built-in Templates

extension WidgetTemplate {

    static let basicRunning = WidgetTemplate(
        name: WorkoutPlazaStrings.Template.Default.running,
        description: WorkoutPlazaStrings.Template.Default.Running.description,
        version: "2.0",
        sportType: .running,
        items: [
            WidgetItem(
                type: .routeMap,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.05),
                sizeRatio: WidgetItem.SizeRatio(width: 0.86, height: 0.40),
                color: "#007AFF",
                font: nil
            ),
            WidgetItem(
                type: .distance,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.48),
                sizeRatio: WidgetItem.SizeRatio(width: 0.42, height: 0.15),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .duration,
                positionRatio: WidgetItem.PositionRatio(x: 0.51, y: 0.48),
                sizeRatio: WidgetItem.SizeRatio(width: 0.42, height: 0.15),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .pace,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.66),
                sizeRatio: WidgetItem.SizeRatio(width: 0.42, height: 0.15),
                color: nil,
                font: "System"
            )
        ],
        canvasSize: CanvasSize(width: 414, height: 552)
    )

    static let detailedStats = WidgetTemplate(
        name: WorkoutPlazaStrings.Template.Detailed.stats,
        description: WorkoutPlazaStrings.Template.Detailed.Stats.description,
        version: "2.0",
        sportType: .running,
        items: [
            WidgetItem(
                type: .routeMap,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.05),
                sizeRatio: WidgetItem.SizeRatio(width: 0.86, height: 0.35),
                color: "#007AFF",
                font: nil
            ),
            WidgetItem(
                type: .distance,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.43),
                sizeRatio: WidgetItem.SizeRatio(width: 0.27, height: 0.13),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .duration,
                positionRatio: WidgetItem.PositionRatio(x: 0.37, y: 0.43),
                sizeRatio: WidgetItem.SizeRatio(width: 0.27, height: 0.13),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .pace,
                positionRatio: WidgetItem.PositionRatio(x: 0.67, y: 0.43),
                sizeRatio: WidgetItem.SizeRatio(width: 0.27, height: 0.13),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .speed,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.59),
                sizeRatio: WidgetItem.SizeRatio(width: 0.27, height: 0.13),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .calories,
                positionRatio: WidgetItem.PositionRatio(x: 0.37, y: 0.59),
                sizeRatio: WidgetItem.SizeRatio(width: 0.27, height: 0.13),
                color: nil,
                font: "System"
            )
        ],
        canvasSize: CanvasSize(width: 414, height: 552)
    )

    static let minimal = WidgetTemplate(
        name: WorkoutPlazaStrings.Template.minimal,
        description: WorkoutPlazaStrings.Template.Minimal.description,
        version: "2.0",
        sportType: .running,
        items: [
            WidgetItem(
                type: .routeMap,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.08),
                sizeRatio: WidgetItem.SizeRatio(width: 0.86, height: 0.50),
                color: "#007AFF",
                font: nil
            ),
            WidgetItem(
                type: .distance,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.62),
                sizeRatio: WidgetItem.SizeRatio(width: 0.42, height: 0.16),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .duration,
                positionRatio: WidgetItem.PositionRatio(x: 0.51, y: 0.62),
                sizeRatio: WidgetItem.SizeRatio(width: 0.42, height: 0.16),
                color: nil,
                font: "System"
            )
        ],
        canvasSize: CanvasSize(width: 414, height: 552)
    )

    // MARK: - Climbing Templates

    static let basicClimbing = WidgetTemplate(
        name: WorkoutPlazaStrings.Template.Default.climbing,
        description: WorkoutPlazaStrings.Template.Default.Climbing.description,
        version: "2.0",
        sportType: .climbing,
        items: [
            WidgetItem(
                type: .climbingGym,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.08),
                sizeRatio: WidgetItem.SizeRatio(width: 0.86, height: 0.14),
                color: "#FF9500",
                font: "System"
            ),
            WidgetItem(
                type: .climbingDiscipline,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.25),
                sizeRatio: WidgetItem.SizeRatio(width: 0.42, height: 0.14),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .date,
                positionRatio: WidgetItem.PositionRatio(x: 0.51, y: 0.25),
                sizeRatio: WidgetItem.SizeRatio(width: 0.42, height: 0.14),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .climbingSession,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.42),
                sizeRatio: WidgetItem.SizeRatio(width: 0.86, height: 0.14),
                color: nil,
                font: "System"
            )
        ],
        canvasSize: CanvasSize(width: 414, height: 552)
    )

    static let detailedClimbing = WidgetTemplate(
        name: WorkoutPlazaStrings.Template.Detailed.climbing,
        description: WorkoutPlazaStrings.Template.Detailed.Climbing.description,
        version: "2.0",
        sportType: .climbing,
        items: [
            WidgetItem(
                type: .climbingGym,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.05),
                sizeRatio: WidgetItem.SizeRatio(width: 0.86, height: 0.12),
                color: "#FF9500",
                font: "System"
            ),
            WidgetItem(
                type: .climbingDiscipline,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.20),
                sizeRatio: WidgetItem.SizeRatio(width: 0.42, height: 0.12),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .date,
                positionRatio: WidgetItem.PositionRatio(x: 0.51, y: 0.20),
                sizeRatio: WidgetItem.SizeRatio(width: 0.42, height: 0.12),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .climbingSession,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.35),
                sizeRatio: WidgetItem.SizeRatio(width: 0.86, height: 0.12),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .climbingRoutesByColor,
                positionRatio: WidgetItem.PositionRatio(x: 0.07, y: 0.50),
                sizeRatio: WidgetItem.SizeRatio(width: 0.86, height: 0.25),
                color: nil,
                font: "System"
            )
        ],
        canvasSize: CanvasSize(width: 414, height: 552)
    )

    // Default built-in templates
    static let allBuiltInTemplates: [WidgetTemplate] = [
        .basicRunning,
        .detailedStats,
        .minimal,
        .basicClimbing,
        .detailedClimbing
    ]

    // Running templates
    static let runningTemplates: [WidgetTemplate] = [
        .basicRunning,
        .detailedStats,
        .minimal
    ]

    // Climbing templates
    static let climbingTemplates: [WidgetTemplate] = [
        .basicClimbing,
        .detailedClimbing
    ]

    /// Get templates for a specific sport
    static func templates(for sport: SportType) -> [WidgetTemplate] {
        switch sport {
        case .running:
            return runningTemplates
        case .climbing:
            return climbingTemplates
        }
    }
}
