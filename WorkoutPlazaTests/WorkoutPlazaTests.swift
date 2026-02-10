//
//  WorkoutPlazaTests.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import Testing
import CoreGraphics
@testable import WorkoutPlaza

struct WorkoutPlazaTests {

    @Test func normalizesCompactRunningStatOnCreation() async throws {
        let normalized = WidgetSizeNormalizer.normalizeRunningCompactStatSize(
            CGSize(width: 160, height: 80),
            widgetType: .distance
        )

        #expect(abs(normalized.width - 160) < 0.001)
        #expect(abs(normalized.height - 60) < 0.001)
    }

    @Test func preservesModernRestoredSizeWhenNotRegressed() async throws {
        let restored = WidgetSizeNormalizer.normalizeRestoredRunningStatSize(
            CGSize(width: 160, height: 80),
            widgetType: .distance,
            forceLegacyMigration: false
        )

        #expect(abs(restored.width - 160) < 0.001)
        #expect(abs(restored.height - 80) < 0.001)
    }

    @Test func expandsHalfScaledCompactRestoredWidget() async throws {
        let restored = WidgetSizeNormalizer.normalizeRestoredRunningStatSize(
            CGSize(width: 80, height: 30),
            widgetType: .distance,
            forceLegacyMigration: false
        )

        #expect(restored.width >= 120)
        #expect(restored.height >= 45)
    }

    @Test func expandsHalfScaledRegularRestoredWidget() async throws {
        let restored = WidgetSizeNormalizer.normalizeRestoredRunningStatSize(
            CGSize(width: 80, height: 40),
            widgetType: .heartRate,
            forceLegacyMigration: false
        )

        #expect(restored.width >= 120)
        #expect(restored.height >= 60)
    }

    @Test func expandsUnreadablySmallRestoredModernWidget() async throws {
        let restored = WidgetSizeNormalizer.normalizeRestoredRunningStatSize(
            CGSize(width: 112, height: 42),
            widgetType: .distance,
            forceLegacyMigration: false
        )

        #expect(restored.width >= 120)
        #expect(restored.height >= 45)
    }

    @Test func migratesCompactizedRegularRunningStat() async throws {
        let restored = WidgetSizeNormalizer.normalizeRestoredRunningStatSize(
            CGSize(width: 160, height: 60),
            widgetType: .heartRate,
            forceLegacyMigration: false
        )

        #expect(abs(restored.width - 160) < 0.001)
        #expect(abs(restored.height - 80) < 0.001)
    }

    @Test func clampsUnreadableExplicitInitialSize() async throws {
        let initial = WidgetSizeNormalizer.normalizeRestoredRunningStatInitialSize(
            CGSize(width: 60, height: 20),
            restoredFrameSize: CGSize(width: 160, height: 60),
            widgetType: .heartRate,
            hasExplicitSavedInitialSize: true
        )

        #expect(initial.width >= 120)
        #expect(initial.height >= 60)
    }

    @Test func restoredMinimumRespectsSmallerCanvasScale() async throws {
        let restored = WidgetSizeNormalizer.normalizeRestoredRunningStatSize(
            CGSize(width: 80, height: 30),
            widgetType: .distance,
            forceLegacyMigration: false,
            canvasScale: 0.7
        )

        #expect(restored.width >= 84)
        #expect(restored.height >= CGFloat(31.5))
        #expect(restored.width < 120)
    }

}
