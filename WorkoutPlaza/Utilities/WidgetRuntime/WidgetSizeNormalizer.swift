//
//  WidgetSizeNormalizer.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/10/26.
//

import CoreGraphics

enum WidgetSizeNormalizer {
    private static let normalizeCandidateAspectRatios: [CGFloat] = [
        2.0,   // legacy 160x80
        2.5    // previous compact 160x64
    ]
    private static let compactRunningStatAspectRatio: CGFloat = 160.0 / 60.0
    private static let regularRunningStatAspectRatio: CGFloat = 160.0 / 80.0
    private static let aspectTolerance: CGFloat = 0.08
    private static let legacyAspectTolerance: CGFloat = 0.14
    private static let compactDefaultSize = CGSize(width: 160, height: 60)
    private static let regularDefaultSize = CGSize(width: 160, height: 80)
    private static let regularStatCompactizedHeightThreshold: CGFloat = 64
    private static let regularStatCompactizedWidthThresholdScale: CGFloat = 0.8
    private static let restoredRegressionThresholdScale: CGFloat = 0.60
    private static let restoredMinimumScale: CGFloat = 0.75
    private static let restoredMaximumExpansionScale: CGFloat = 2.0

    static func normalizeRunningCompactStatSize(_ size: CGSize, widgetType: WidgetType) -> CGSize {
        normalizeRunningCompactStatSize(size, widgetType: widgetType, tolerance: aspectTolerance)
    }

    static func normalizeRunningCompactStatSize(
        _ size: CGSize,
        widgetType: WidgetType,
        forceLegacyMigration: Bool
    ) -> CGSize {
        guard forceLegacyMigration else {
            return size
        }
        let tolerance = max(aspectTolerance, legacyAspectTolerance)
        return normalizeRunningCompactStatSize(size, widgetType: widgetType, tolerance: tolerance)
    }

    static func normalizeRestoredRunningStatSize(
        _ size: CGSize,
        widgetType: WidgetType,
        forceLegacyMigration: Bool,
        canvasScale: CGFloat = 1
    ) -> CGSize {
        let effectiveCanvasScale = clampedCanvasScale(canvasScale)
        let normalized = normalizeRunningCompactStatSize(
            size,
            widgetType: widgetType,
            forceLegacyMigration: forceLegacyMigration
        )
        let migratedRegular = migrateCompactizedRegularRunningStatIfNeeded(
            normalized,
            widgetType: widgetType,
            forceLegacyMigration: forceLegacyMigration,
            canvasScale: effectiveCanvasScale
        )
        return migrateUndersizedRunningStatIfNeeded(
            migratedRegular,
            widgetType: widgetType,
            forceLegacyMigration: forceLegacyMigration,
            canvasScale: effectiveCanvasScale
        )
    }

    static func normalizeRestoredRunningStatInitialSize(
        _ initialSize: CGSize,
        restoredFrameSize: CGSize,
        widgetType: WidgetType,
        hasExplicitSavedInitialSize: Bool,
        canvasScale: CGFloat = 1
    ) -> CGSize {
        let effectiveCanvasScale = clampedCanvasScale(canvasScale)
        guard initialSize.width > 0,
              initialSize.height > 0 else {
            return restoredFrameSize
        }
        guard isRunningStat(widgetType) else {
            return initialSize
        }

        // Legacy states did not persist initialSize.
        // In that case, use current restored frame as baseline to avoid compounding scale drift.
        var resolved = hasExplicitSavedInitialSize ? initialSize : restoredFrameSize
        resolved = migrateCompactizedRegularRunningStatIfNeeded(
            resolved,
            widgetType: widgetType,
            forceLegacyMigration: !hasExplicitSavedInitialSize,
            canvasScale: effectiveCanvasScale
        )

        let defaultSize = scaled(defaultRunningStatSize(for: widgetType), by: effectiveCanvasScale)
        let minimumTarget = scaled(defaultSize, by: restoredMinimumScale)
        if resolved.width < minimumTarget.width || resolved.height < minimumTarget.height {
            resolved = CGSize(
                width: max(resolved.width, minimumTarget.width),
                height: max(resolved.height, minimumTarget.height)
            )
        }
        return resolved
    }

    private static func migrateCompactizedRegularRunningStatIfNeeded(
        _ size: CGSize,
        widgetType: WidgetType,
        forceLegacyMigration: Bool,
        canvasScale: CGFloat
    ) -> CGSize {
        guard isRegularRunningStat(widgetType),
              size.width > 0,
              size.height > 0 else {
            return size
        }

        let currentAspectRatio = size.width / max(size.height, 1)
        let tolerance = max(aspectTolerance, legacyAspectTolerance)
        let looksCompactized = abs(currentAspectRatio - compactRunningStatAspectRatio) <= tolerance
        let heightThreshold = regularStatCompactizedHeightThreshold * canvasScale
        let widthThreshold = regularDefaultSize.width * regularStatCompactizedWidthThresholdScale * canvasScale
        let hasCompactLikeHeight = size.height <= heightThreshold
        let hasNearDefaultWidth = size.width >= widthThreshold
        guard looksCompactized,
              hasCompactLikeHeight,
              (forceLegacyMigration || hasNearDefaultWidth) else {
            return size
        }

        return CGSize(
            width: size.width,
            height: size.width / regularRunningStatAspectRatio
        )
    }

    private static func normalizeRunningCompactStatSize(
        _ size: CGSize,
        widgetType: WidgetType,
        tolerance: CGFloat
    ) -> CGSize {
        guard isRunningCompactStat(widgetType),
              size.width > 0,
              size.height > 0 else {
            return size
        }

        let currentAspectRatio = size.width / max(size.height, 1)
        let shouldNormalize = normalizeCandidateAspectRatios.contains { candidate in
            abs(currentAspectRatio - candidate) <= tolerance
        }
        guard shouldNormalize else {
            return size
        }

        return CGSize(
            width: size.width,
            height: size.width / compactRunningStatAspectRatio
        )
    }

    private static func migrateUndersizedRunningStatIfNeeded(
        _ size: CGSize,
        widgetType: WidgetType,
        forceLegacyMigration: Bool,
        canvasScale: CGFloat
    ) -> CGSize {
        guard isRunningStat(widgetType),
              size.width > 0,
              size.height > 0 else {
            return size
        }

        let defaultSize = scaled(defaultRunningStatSize(for: widgetType), by: canvasScale)
        let regressionThreshold = scaled(defaultSize, by: restoredRegressionThresholdScale)
        let minimumTarget = scaled(defaultSize, by: restoredMinimumScale)
        let isBelowReadableMinimum = size.width < minimumTarget.width
            || size.height < minimumTarget.height
        let looksLikeHalfScaleRegression = size.width <= regressionThreshold.width
            && size.height <= regressionThreshold.height

        // Legacy cards, clear half-scale regressions, or unreadably small restored frames
        // should be migrated to a readable minimum.
        guard forceLegacyMigration || looksLikeHalfScaleRegression || isBelowReadableMinimum else {
            return size
        }

        let requiredScale = max(
            minimumTarget.width / max(size.width, 1),
            minimumTarget.height / max(size.height, 1)
        )
        guard requiredScale > 1 else {
            return size
        }

        let scale = min(requiredScale, restoredMaximumExpansionScale)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    private static func clampedCanvasScale(_ scale: CGFloat) -> CGFloat {
        guard scale.isFinite, scale > 0 else { return 1 }
        return min(max(scale, 0.5), 2.0)
    }

    static func isRunningCompactStat(_ widgetType: WidgetType) -> Bool {
        switch widgetType {
        case .distance, .duration, .pace, .calories:
            return true
        default:
            return false
        }
    }

    private static func isRunningStat(_ widgetType: WidgetType) -> Bool {
        switch widgetType {
        case .distance, .duration, .pace, .speed, .calories, .heartRate:
            return true
        default:
            return false
        }
    }

    private static func isRegularRunningStat(_ widgetType: WidgetType) -> Bool {
        switch widgetType {
        case .speed, .heartRate:
            return true
        default:
            return false
        }
    }

    private static func defaultRunningStatSize(for widgetType: WidgetType) -> CGSize {
        switch widgetType {
        case .distance, .duration, .pace, .calories:
            return compactDefaultSize
        case .speed, .heartRate:
            return regularDefaultSize
        default:
            return regularDefaultSize
        }
    }

    private static func scaled(_ size: CGSize, by scale: CGFloat) -> CGSize {
        CGSize(width: size.width * scale, height: size.height * scale)
    }
}
