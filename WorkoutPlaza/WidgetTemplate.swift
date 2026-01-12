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

    init(id: String = UUID().uuidString, name: String, description: String, version: String = "1.0", items: [WidgetItem]) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.items = items
    }
}

struct WidgetItem: Codable {
    let type: WidgetType
    let position: Position
    let size: Size
    let color: String?  // Hex color string
    let font: String?   // Font style name

    struct Position: Codable {
        let x: CGFloat
        let y: CGFloat
    }

    struct Size: Codable {
        let width: CGFloat
        let height: CGFloat
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
        items: [
            WidgetItem(
                type: .routeMap,
                position: WidgetItem.Position(x: 30, y: 70),
                size: WidgetItem.Size(width: 350, height: 250),
                color: "#007AFF",
                font: nil
            ),
            WidgetItem(
                type: .distance,
                position: WidgetItem.Position(x: 30, y: 350),
                size: WidgetItem.Size(width: 160, height: 80),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .duration,
                position: WidgetItem.Position(x: 210, y: 350),
                size: WidgetItem.Size(width: 160, height: 80),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .pace,
                position: WidgetItem.Position(x: 30, y: 470),
                size: WidgetItem.Size(width: 160, height: 80),
                color: nil,
                font: "System"
            )
        ]
    )

    static let detailedStats = WidgetTemplate(
        name: "상세 통계",
        description: "경로 + 거리 + 시간 + 페이스 + 속도 + 칼로리",
        items: [
            WidgetItem(
                type: .routeMap,
                position: WidgetItem.Position(x: 30, y: 70),
                size: WidgetItem.Size(width: 350, height: 200),
                color: "#007AFF",
                font: nil
            ),
            WidgetItem(
                type: .distance,
                position: WidgetItem.Position(x: 30, y: 300),
                size: WidgetItem.Size(width: 110, height: 70),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .duration,
                position: WidgetItem.Position(x: 155, y: 300),
                size: WidgetItem.Size(width: 110, height: 70),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .pace,
                position: WidgetItem.Position(x: 280, y: 300),
                size: WidgetItem.Size(width: 110, height: 70),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .speed,
                position: WidgetItem.Position(x: 30, y: 390),
                size: WidgetItem.Size(width: 110, height: 70),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .calories,
                position: WidgetItem.Position(x: 155, y: 390),
                size: WidgetItem.Size(width: 110, height: 70),
                color: nil,
                font: "System"
            )
        ]
    )

    static let minimal = WidgetTemplate(
        name: "미니멀",
        description: "경로 + 거리 + 시간",
        items: [
            WidgetItem(
                type: .routeMap,
                position: WidgetItem.Position(x: 30, y: 100),
                size: WidgetItem.Size(width: 350, height: 300),
                color: "#007AFF",
                font: nil
            ),
            WidgetItem(
                type: .distance,
                position: WidgetItem.Position(x: 30, y: 430),
                size: WidgetItem.Size(width: 170, height: 90),
                color: nil,
                font: "System"
            ),
            WidgetItem(
                type: .duration,
                position: WidgetItem.Position(x: 220, y: 430),
                size: WidgetItem.Size(width: 170, height: 90),
                color: nil,
                font: "System"
            )
        ]
    )

    // Default built-in templates
    static let allBuiltInTemplates: [WidgetTemplate] = [
        .basicRunning,
        .detailedStats,
        .minimal
    ]
}
