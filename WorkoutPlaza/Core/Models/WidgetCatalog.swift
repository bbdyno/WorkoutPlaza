//
//  WidgetCatalog.swift
//  WorkoutPlaza
//
//  JSON 기반 위젯 카탈로그 — 위젯 종류를 데이터로 정의
//

import Foundation

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
