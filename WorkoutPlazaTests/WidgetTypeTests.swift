//
//  WidgetTypeTests.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/6/26.
//

import Testing
import Foundation
@testable import WorkoutPlaza

struct WidgetTypeTests {

    // MARK: - baseType

    @Test func baseTypeReturnsCorrectBase() {
        #expect(WidgetType.distanceCompact.baseType == .distance)
        #expect(WidgetType.distanceIcon.baseType == .distance)
        #expect(WidgetType.distance.baseType == .distance)
        #expect(WidgetType.heartRateIcon.baseType == .heartRate)
        #expect(WidgetType.routeMap.baseType == .routeMap)
        #expect(WidgetType.text.baseType == .text)
    }

    // MARK: - inherentDisplayMode

    @Test func inherentDisplayModeForTextVariants() {
        #expect(WidgetType.distance.inherentDisplayMode == .text)
        #expect(WidgetType.duration.inherentDisplayMode == .text)
        #expect(WidgetType.routeMap.inherentDisplayMode == .text)
    }

    @Test func inherentDisplayModeForCompactVariants() {
        #expect(WidgetType.distanceCompact.inherentDisplayMode == .textUnified)
        #expect(WidgetType.paceCompact.inherentDisplayMode == .textUnified)
        #expect(WidgetType.heartRateCompact.inherentDisplayMode == .textUnified)
    }

    @Test func inherentDisplayModeForIconVariants() {
        #expect(WidgetType.distanceIcon.inherentDisplayMode == .icon)
        #expect(WidgetType.caloriesIcon.inherentDisplayMode == .icon)
        #expect(WidgetType.dateIcon.inherentDisplayMode == .icon)
    }

    // MARK: - singletonGroup

    @Test func singletonGroupMatchesBaseType() {
        #expect(WidgetType.distanceCompact.singletonGroup == .distance)
        #expect(WidgetType.distanceIcon.singletonGroup == .distance)
        #expect(WidgetType.distance.singletonGroup == .distance)
    }

    // MARK: - displayName / iconName (should resolve via baseType)

    @Test func compactVariantSharesDisplayNameWithBase() {
        #expect(WidgetType.distanceCompact.displayName == WidgetType.distance.displayName)
        #expect(WidgetType.heartRateIcon.displayName == WidgetType.heartRate.displayName)
    }

    @Test func compactVariantSharesIconNameWithBase() {
        #expect(WidgetType.durationCompact.iconName == WidgetType.duration.iconName)
    }

    // MARK: - layoutDescription

    @Test func layoutDescriptionDiffers() {
        #expect(WidgetType.distance.layoutDescription != WidgetType.distanceCompact.layoutDescription)
        #expect(WidgetType.distanceCompact.layoutDescription != WidgetType.distanceIcon.layoutDescription)
    }

    // MARK: - Codable backward compat

    @Test func decodesLegacyWidgetType() throws {
        let json = #"{"type":"Distance"}"#
        struct Wrapper: Codable { let type: WidgetType }
        let decoded = try JSONDecoder().decode(Wrapper.self, from: json.data(using: .utf8)!)
        #expect(decoded.type == .distance)
    }

    @Test func decodesNewCompactType() throws {
        let json = #"{"type":"DistanceCompact"}"#
        struct Wrapper: Codable { let type: WidgetType }
        let decoded = try JSONDecoder().decode(Wrapper.self, from: json.data(using: .utf8)!)
        #expect(decoded.type == .distanceCompact)
    }
}
