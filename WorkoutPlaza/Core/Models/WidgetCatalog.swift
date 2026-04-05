//
//  WidgetCatalog.swift
//  WorkoutPlaza
//
//  JSON 기반 위젯 카탈로그 — 위젯 종류를 데이터로 정의
//

import UIKit

// MARK: - Catalog Data Model

struct WidgetCatalog: Codable {
    let version: String
    let categories: [CatalogCategory]
}

struct CatalogCategory: Codable {
    let id: String
    let name: LocalizedString
    let widgets: [CatalogWidgetItem]
}

struct CatalogWidgetItem: Codable {
    let id: String
    let dataType: String
    let layout: String
    let name: LocalizedString
    let description: LocalizedString
    let iconName: String
    let singletonGroup: String?

    var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return name.localized(for: lang)
    }

    var localizedDescription: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return description.localized(for: lang)
    }

    var widgetType: WidgetType? {
        // Catalog dataType uses camelCase (e.g. "distance") while WidgetType
        // raw values are PascalCase (e.g. "Distance"). Try exact match first,
        // then fall back to case-insensitive lookup.
        if let exact = WidgetType(rawValue: dataType) {
            return exact
        }
        return WidgetType.allCases.first {
            $0.rawValue.caseInsensitiveCompare(dataType) == .orderedSame
        }
    }

    var displayMode: WidgetDisplayMode {
        WidgetDisplayMode(rawValue: layout) ?? .text
    }

    /// 카탈로그 항목의 레이아웃(text/compact/icon)을 반영한 프리뷰 생성
    var previewProvider: (() -> UIView)? {
        guard let type = widgetType else { return nil }
        let mode = displayMode
        let size: CGSize
        switch mode {
        case .icon:
            size = CGSize(width: 160, height: 50)
        case .textUnified:
            size = CGSize(width: 140, height: 55)
        case .text:
            size = CGSize(width: 140, height: 65)
        }

        switch type {
        case .distance:
            return { Self.makeStatPreview(DistanceWidget(), distance: 5230, mode: mode, size: size) }
        case .duration:
            return { Self.makeStatPreview(DurationWidget(), duration: 1860, mode: mode, size: size) }
        case .pace:
            return { Self.makeStatPreview(PaceWidget(), pace: 5.42, mode: mode, size: size) }
        case .speed:
            return { Self.makeStatPreview(SpeedWidget(), speed: 11.2, mode: mode, size: size) }
        case .calories:
            return { Self.makeStatPreview(CaloriesWidget(), calories: 320, mode: mode, size: size) }
        case .heartRate:
            return { Self.makeStatPreview(HeartRateWidget(), heartRate: 155, mode: mode, size: size) }
        case .date:
            return { Self.makeStatPreview(DateWidget(), mode: mode, size: size) }
        default:
            return type.previewProvider
        }
    }

    private static func makeStatPreview(_ widget: DistanceWidget, distance: Double, mode: WidgetDisplayMode, size: CGSize) -> UIView {
        widget.frame = CGRect(origin: .zero, size: size)
        widget.configure(distance: distance)
        widget.setDisplayMode(mode)
        return widget
    }

    private static func makeStatPreview(_ widget: DurationWidget, duration: TimeInterval, mode: WidgetDisplayMode, size: CGSize) -> UIView {
        widget.frame = CGRect(origin: .zero, size: size)
        widget.configure(duration: duration)
        widget.setDisplayMode(mode)
        return widget
    }

    private static func makeStatPreview(_ widget: PaceWidget, pace: Double, mode: WidgetDisplayMode, size: CGSize) -> UIView {
        widget.frame = CGRect(origin: .zero, size: size)
        widget.configure(pace: pace)
        widget.setDisplayMode(mode)
        return widget
    }

    private static func makeStatPreview(_ widget: SpeedWidget, speed: Double, mode: WidgetDisplayMode, size: CGSize) -> UIView {
        widget.frame = CGRect(origin: .zero, size: size)
        widget.configure(speed: speed)
        widget.setDisplayMode(mode)
        return widget
    }

    private static func makeStatPreview(_ widget: CaloriesWidget, calories: Double, mode: WidgetDisplayMode, size: CGSize) -> UIView {
        widget.frame = CGRect(origin: .zero, size: size)
        widget.configure(calories: calories)
        widget.setDisplayMode(mode)
        return widget
    }

    private static func makeStatPreview(_ widget: HeartRateWidget, heartRate: Double, mode: WidgetDisplayMode, size: CGSize) -> UIView {
        widget.frame = CGRect(origin: .zero, size: size)
        widget.configure(heartRate: heartRate)
        widget.setDisplayMode(mode)
        return widget
    }

    private static func makeStatPreview(_ widget: DateWidget, mode: WidgetDisplayMode, size: CGSize) -> UIView {
        widget.frame = CGRect(origin: .zero, size: size)
        widget.configure(startDate: Date())
        widget.setDisplayMode(mode)
        return widget
    }
}

struct LocalizedString: Codable {
    let ko: String
    let en: String

    func localized(for languageCode: String) -> String {
        languageCode.hasPrefix("ko") ? ko : en
    }
}

// MARK: - Catalog Manager

final class WidgetCatalogManager {
    static let shared = WidgetCatalogManager()

    private(set) var catalog: WidgetCatalog?

    private init() {
        loadBundledCatalog()
    }

    private func loadBundledCatalog() {
        guard let url = Bundle.main.url(forResource: "widget_catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            WPLog.error("widget_catalog.json not found in bundle")
            return
        }

        do {
            catalog = try JSONDecoder().decode(WidgetCatalog.self, from: data)
            WPLog.info("Widget catalog loaded: \(catalog?.categories.count ?? 0) categories")
        } catch {
            WPLog.error("Widget catalog parse error: \(error)")
        }
    }

    func widgets(for sportType: SportType) -> [CatalogWidgetItem] {
        let categoryId: String
        switch sportType {
        case .running: categoryId = "running"
        case .climbing: categoryId = "climbing"
        }
        return catalog?.categories.first(where: { $0.id == categoryId })?.widgets ?? []
    }

    func definition(for catalogId: String, sportType: SportType) -> CatalogWidgetItem? {
        widgets(for: sportType).first(where: { $0.id == catalogId })
    }
}
