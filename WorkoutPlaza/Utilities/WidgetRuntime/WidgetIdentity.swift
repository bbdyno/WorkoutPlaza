//
//  WidgetIdentity.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import UIKit

enum WidgetDefinitionID: String, Codable, CaseIterable {
    case routeMap = "builtin.running.route_map"
    case distance = "builtin.running.distance"
    case duration = "builtin.running.duration"
    case pace = "builtin.running.pace"
    case speed = "builtin.running.speed"
    case calories = "builtin.running.calories"
    case heartRate = "builtin.running.heart_rate"
    case location = "builtin.running.location"

    case date = "builtin.shared.date"
    case currentDateTime = "builtin.shared.current_date_time"
    case text = "builtin.shared.text"
    case textPath = "builtin.shared.text_path"
    case composite = "builtin.shared.composite"

    case climbingGym = "builtin.climbing.gym"
    case climbingDiscipline = "builtin.climbing.discipline"
    case climbingSession = "builtin.climbing.session"
    case climbingRoutesByColor = "builtin.climbing.routes_by_color"
    case gymLogo = "builtin.climbing.gym_logo"
}

enum WidgetIdentity {
    static func definitionID(for widgetType: WidgetType) -> WidgetDefinitionID {
        switch widgetType {
        case .routeMap: return .routeMap
        case .distance: return .distance
        case .duration: return .duration
        case .pace: return .pace
        case .speed: return .speed
        case .calories: return .calories
        case .heartRate: return .heartRate
        case .location: return .location
        case .date: return .date
        case .currentDateTime: return .currentDateTime
        case .text: return .text
        case .composite: return .composite
        case .climbingGym: return .climbingGym
        case .climbingDiscipline: return .climbingDiscipline
        case .climbingSession: return .climbingSession
        case .climbingRoutesByColor: return .climbingRoutesByColor
        case .gymLogo: return .gymLogo
        }
    }

    static func widgetType(for definitionID: WidgetDefinitionID) -> WidgetType {
        switch definitionID {
        case .routeMap: return .routeMap
        case .distance: return .distance
        case .duration: return .duration
        case .pace: return .pace
        case .speed: return .speed
        case .calories: return .calories
        case .heartRate: return .heartRate
        case .location: return .location
        case .date: return .date
        case .currentDateTime: return .currentDateTime
        case .text: return .text
        case .textPath: return .text
        case .composite: return .composite
        case .climbingGym: return .climbingGym
        case .climbingDiscipline: return .climbingDiscipline
        case .climbingSession: return .climbingSession
        case .climbingRoutesByColor: return .climbingRoutesByColor
        case .gymLogo: return .gymLogo
        }
    }

    static func definitionID(for widget: UIView) -> WidgetDefinitionID? {
        switch widget {
        case is RouteMapView: return .routeMap
        case is DistanceWidget: return .distance
        case is DurationWidget: return .duration
        case is PaceWidget: return .pace
        case is SpeedWidget: return .speed
        case is CaloriesWidget: return .calories
        case is HeartRateWidget: return .heartRate
        case is LocationWidget: return .location
        case is DateWidget: return .date
        case is CurrentDateTimeWidget: return .currentDateTime
        case is TextWidget: return .text
        case is TextPathWidget: return .textPath
        case is CompositeWidget: return .composite
        case is ClimbingGymWidget: return .climbingGym
        case is ClimbingDisciplineWidget: return .climbingDiscipline
        case is ClimbingSessionWidget: return .climbingSession
        case is ClimbingRoutesByColorWidget: return .climbingRoutesByColor
        case is GymLogoWidget: return .gymLogo
        default: return nil
        }
    }

    static func legacyTypeName(for definitionID: WidgetDefinitionID) -> String {
        switch definitionID {
        case .routeMap: return "RouteMapView"
        case .distance: return "DistanceWidget"
        case .duration: return "DurationWidget"
        case .pace: return "PaceWidget"
        case .speed: return "SpeedWidget"
        case .calories: return "CaloriesWidget"
        case .heartRate: return "HeartRateWidget"
        case .location: return "LocationWidget"
        case .date: return "DateWidget"
        case .currentDateTime: return "CurrentDateTimeWidget"
        case .text: return "TextWidget"
        case .textPath: return "TextPathWidget"
        case .composite: return "CompositeWidget"
        case .climbingGym: return "ClimbingGymWidget"
        case .climbingDiscipline: return "ClimbingDisciplineWidget"
        case .climbingSession: return "ClimbingSessionWidget"
        case .climbingRoutesByColor: return "ClimbingRoutesByColorWidget"
        case .gymLogo: return "GymLogoWidget"
        }
    }

    static func definitionID(fromLegacyTypeName legacyTypeName: String) -> WidgetDefinitionID? {
        switch legacyTypeName {
        case "RouteMapView": return .routeMap
        case "DistanceWidget": return .distance
        case "DurationWidget": return .duration
        case "PaceWidget": return .pace
        case "SpeedWidget": return .speed
        case "CaloriesWidget": return .calories
        case "HeartRateWidget": return .heartRate
        case "LocationWidget": return .location
        case "DateWidget": return .date
        case "CurrentDateTimeWidget": return .currentDateTime
        case "TextWidget": return .text
        case "TextPathWidget": return .textPath
        case "CompositeWidget": return .composite
        case "ClimbingGymWidget": return .climbingGym
        case "ClimbingDisciplineWidget": return .climbingDiscipline
        case "ClimbingSessionWidget": return .climbingSession
        case "ClimbingRoutesByColorWidget": return .climbingRoutesByColor
        case "GymLogoWidget": return .gymLogo
        default: return nil
        }
    }

    static func resolvedDefinitionID(from savedWidget: SavedWidgetState) -> WidgetDefinitionID? {
        if let idRaw = savedWidget.definitionID, let id = WidgetDefinitionID(rawValue: idRaw) {
            return id
        }
        return definitionID(fromLegacyTypeName: savedWidget.type)
    }
}
