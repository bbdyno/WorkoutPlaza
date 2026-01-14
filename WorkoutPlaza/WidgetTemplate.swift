//
//  WidgetTemplate.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

// MARK: - Widget Template Models

struct WidgetTemplate: Codable {
    let id: String
    let name: String
    let description: String
    let version: String
    let items: [WidgetItem]

    // Canvas information (for proper scaling)
    let canvasSize: CanvasSize?

    // Background information
    let backgroundImageAspectRatio: CGFloat?
    let backgroundTransform: BackgroundTransformData?

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        version: String = "2.0",
        items: [WidgetItem],
        canvasSize: CanvasSize? = nil,
        backgroundImageAspectRatio: CGFloat? = nil,
        backgroundTransform: BackgroundTransformData? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.items = items
        self.canvasSize = canvasSize
        self.backgroundImageAspectRatio = backgroundImageAspectRatio
        self.backgroundTransform = backgroundTransform
    }

    struct CanvasSize: Codable {
        let width: CGFloat
        let height: CGFloat
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

    // Ratio-based positioning (version 2.0+)
    let positionRatio: PositionRatio?
    let sizeRatio: SizeRatio?

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
        font: String? = nil
    ) {
        self.type = type
        self.positionRatio = positionRatio
        self.sizeRatio = sizeRatio
        self.color = color
        self.font = font

        // Legacy fields (will be calculated when needed)
        self.position = Position(x: 0, y: 0)
        self.size = Size(width: 0, height: 0)
    }

    // Initializer for legacy absolute-positioned items (version 1.0)
    init(
        type: WidgetType,
        position: Position,
        size: Size,
        color: String? = nil,
        font: String? = nil
    ) {
        self.type = type
        self.position = position
        self.size = size
        self.color = color
        self.font = font

        // Ratio fields are nil for legacy templates
        self.positionRatio = nil
        self.sizeRatio = nil
    }
}

enum WidgetType: String, Codable {
    case routeMap = "RouteMap"
    case distance = "Distance"
    case duration = "Duration"
    case pace = "Pace"
    case speed = "Speed"
    case calories = "Calories"
    case date = "Date"
    case composite = "Composite"
}

// MARK: - Built-in Templates

extension WidgetTemplate {

    static let basicRunning = WidgetTemplate(
        name: "기본 러닝",
        description: "경로 + 거리 + 시간 + 페이스",
        version: "2.0",
        items: [
            WidgetItem(
                type: .routeMap,
                positionRatio: WidgetItem.PositionRatio(x: 0.0725, y: 0.10),
                sizeRatio: WidgetItem.SizeRatio(width: 0.845, height: 0.357),
                color: "#007AFF",
                font: nil
            ),
            WidgetItem(
                type: .distance,
                positionRatio: WidgetItem.PositionRatio(x: 0.0725, y: 0.50),
                sizeRatio: WidgetItem.SizeRatio(width: 0.386, height: 0.114),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .duration,
                positionRatio: WidgetItem.PositionRatio(x: 0.507, y: 0.50),
                sizeRatio: WidgetItem.SizeRatio(width: 0.386, height: 0.114),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .pace,
                positionRatio: WidgetItem.PositionRatio(x: 0.0725, y: 0.671),
                sizeRatio: WidgetItem.SizeRatio(width: 0.386, height: 0.114),
                color: nil,
                font: "System"
            )
        ],
        canvasSize: CanvasSize(width: 414, height: 700)
    )

    static let detailedStats = WidgetTemplate(
        name: "상세 통계",
        description: "경로 + 거리 + 시간 + 페이스 + 속도 + 칼로리",
        version: "2.0",
        items: [
            WidgetItem(
                type: .routeMap,
                positionRatio: WidgetItem.PositionRatio(x: 0.0725, y: 0.10),
                sizeRatio: WidgetItem.SizeRatio(width: 0.845, height: 0.286),
                color: "#007AFF",
                font: nil
            ),
            WidgetItem(
                type: .distance,
                positionRatio: WidgetItem.PositionRatio(x: 0.0725, y: 0.429),
                sizeRatio: WidgetItem.SizeRatio(width: 0.266, height: 0.10),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .duration,
                positionRatio: WidgetItem.PositionRatio(x: 0.374, y: 0.429),
                sizeRatio: WidgetItem.SizeRatio(width: 0.266, height: 0.10),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .pace,
                positionRatio: WidgetItem.PositionRatio(x: 0.676, y: 0.429),
                sizeRatio: WidgetItem.SizeRatio(width: 0.266, height: 0.10),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .speed,
                positionRatio: WidgetItem.PositionRatio(x: 0.0725, y: 0.557),
                sizeRatio: WidgetItem.SizeRatio(width: 0.266, height: 0.10),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .calories,
                positionRatio: WidgetItem.PositionRatio(x: 0.374, y: 0.557),
                sizeRatio: WidgetItem.SizeRatio(width: 0.266, height: 0.10),
                color: nil,
                font: "System"
            )
        ],
        canvasSize: CanvasSize(width: 414, height: 700)
    )

    static let minimal = WidgetTemplate(
        name: "미니멀",
        description: "경로 + 거리 + 시간",
        version: "2.0",
        items: [
            WidgetItem(
                type: .routeMap,
                positionRatio: WidgetItem.PositionRatio(x: 0.0725, y: 0.143),
                sizeRatio: WidgetItem.SizeRatio(width: 0.845, height: 0.429),
                color: "#007AFF",
                font: nil
            ),
            WidgetItem(
                type: .distance,
                positionRatio: WidgetItem.PositionRatio(x: 0.0725, y: 0.614),
                sizeRatio: WidgetItem.SizeRatio(width: 0.411, height: 0.129),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .duration,
                positionRatio: WidgetItem.PositionRatio(x: 0.531, y: 0.614),
                sizeRatio: WidgetItem.SizeRatio(width: 0.411, height: 0.129),
                color: nil,
                font: "System"
            )
        ],
        canvasSize: CanvasSize(width: 414, height: 700)
    )

    // Default built-in templates
    static let allBuiltInTemplates: [WidgetTemplate] = [
        .basicRunning,
        .detailedStats,
        .minimal
    ]
}
