//
//  TemplateManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

enum TemplateValidationError: LocalizedError {
    case emptyName
    case incompatibleMinimumVersion(required: String)
    case emptyItems
    case tooManyItems(Int)
    case unsupportedWidgetType(widget: WidgetType, sport: SportType)
    case invalidRatioValue(widget: WidgetType)
    case invalidLegacyFrame(widget: WidgetType)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Template name is required."
        case .incompatibleMinimumVersion(let required):
            return "This template requires app version \(required) or later."
        case .emptyItems:
            return "Template must include at least one widget item."
        case .tooManyItems(let count):
            return "Template has too many items (\(count))."
        case .unsupportedWidgetType(let widget, let sport):
            return "Widget type \(widget.rawValue) is not supported for sport \(sport.rawValue)."
        case .invalidRatioValue(let widget):
            return "Template contains invalid ratio values for \(widget.rawValue)."
        case .invalidLegacyFrame(let widget):
            return "Template contains invalid legacy frame values for \(widget.rawValue)."
        }
    }
}

actor TemplateManager {
    static let shared = TemplateManager()

    private init() {}

    // MARK: - Properties
    private var customTemplates: [WidgetTemplate] = []

    private var templatesDirectoryURL: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let templatesURL = documentsURL.appendingPathComponent("Templates")

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: templatesURL.path) {
            try? FileManager.default.createDirectory(at: templatesURL, withIntermediateDirectories: true)
        }

        return templatesURL
    }

    // MARK: - Get Templates
    func getAllTemplates() async -> [WidgetTemplate] {
        await loadCustomTemplates()
        return WidgetTemplate.allBuiltInTemplates + customTemplates
    }

    func getBuiltInTemplates() -> [WidgetTemplate] {
        return WidgetTemplate.allBuiltInTemplates
    }

    func getCustomTemplates() async -> [WidgetTemplate] {
        await loadCustomTemplates()
        return customTemplates
    }

    func getTemplates(for sport: SportType) async -> [WidgetTemplate] {
        await loadCustomTemplates()
        // Get built-in for sport
        let builtIn = WidgetTemplate.templates(for: sport)
        // Get custom for sport
        let custom = customTemplates.filter { $0.sportType == sport }
        return builtIn + custom
    }

    // MARK: - Save Custom Template
    func saveCustomTemplate(_ template: WidgetTemplate) async throws {
        try validate(template)

        let fileURL = templatesDirectoryURL.appendingPathComponent("\(template.id).wptemplate")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(template)
        
        try await Task.detached(priority: .utility) {
            try data.write(to: fileURL)
        }.value

        // Reload custom templates
        await loadCustomTemplates()

        WPLog.info("Template saved: \(template.name) at \(fileURL.path)")
    }

    // MARK: - Delete Custom Template
    func deleteCustomTemplate(_ template: WidgetTemplate) async throws {
        let fileURL = templatesDirectoryURL.appendingPathComponent("\(template.id).wptemplate")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try await Task.detached(priority: .utility) {
                try FileManager.default.removeItem(at: fileURL)
            }.value
            
            await loadCustomTemplates()
            WPLog.info("Template deleted: \(template.name)")
        }
    }

    // MARK: - Load Custom Templates
    private func loadCustomTemplates() async {
        let directoryURL = templatesDirectoryURL
        
        let templates = await Task.detached(priority: .userInitiated) { () -> [WidgetTemplate] in
            var loadedTemplates: [WidgetTemplate] = []
            
            guard let files = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
                return []
            }

            for fileURL in files where fileURL.pathExtension == "wptemplate" || fileURL.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    let template = try decoder.decode(WidgetTemplate.self, from: data)
                    loadedTemplates.append(template)
                } catch {
                    WPLog.warning("Failed to load template from \(fileURL.lastPathComponent): \(error)")
                }
            }
            return loadedTemplates
        }.value
        
        // Update on actor context
        self.customTemplates = templates
        WPLog.info("Loaded \(self.customTemplates.count) custom templates")
    }

    // MARK: - Export Template
    func exportTemplate(_ template: WidgetTemplate) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(template)

        // Create temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "\(template.name.replacingOccurrences(of: " ", with: "_")).wptemplate"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        try data.write(to: fileURL)

        WPLog.info("Template exported: \(fileURL.path)")
        return fileURL
    }

    // MARK: - Import Template
    func importTemplate(from url: URL) async throws -> WidgetTemplate {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let template = try decoder.decode(WidgetTemplate.self, from: data)
        try validate(template)

        // Save as custom template
        try await saveCustomTemplate(template)

        WPLog.info("Template imported: \(template.name)")
        return template
    }

    // MARK: - Create Template from Current Layout
    func createTemplateFromCurrentLayout(
        name: String,
        description: String,
        items: [WidgetItem]
    ) -> WidgetTemplate {
        return WidgetTemplate(
            name: name,
            description: description,
            items: items
        )
    }

    // MARK: - Helper: Convert UIColor to Hex
    static func hexString(from color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06X", rgb)
    }

    // MARK: - Helper: Convert Hex to UIColor
    static func color(from hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }

    // MARK: - Helper: Convert absolute coordinates to ratios
    static func createRatioBasedItem(
        type: WidgetType,
        frame: CGRect,
        canvasSize: CGSize,
        color: String? = nil,
        font: String? = nil,
        payload: String? = nil,
        rotation: CGFloat? = nil
    ) -> WidgetItem {
        let positionRatio = WidgetItem.PositionRatio(
            x: frame.origin.x / canvasSize.width,
            y: frame.origin.y / canvasSize.height
        )

        let sizeRatio = WidgetItem.SizeRatio(
            width: frame.width / canvasSize.width,
            height: frame.height / canvasSize.height
        )

        return WidgetItem(
            type: type,
            positionRatio: positionRatio,
            sizeRatio: sizeRatio,
            color: color,
            font: font,
            payload: payload,
            rotation: rotation
        )
    }

    // MARK: - Helper: Convert ratio to absolute coordinates
    static func absoluteFrame(from item: WidgetItem, canvasSize: CGSize, templateCanvasSize: CGSize? = nil) -> CGRect {
        // Use ratio-based positioning if available (version 2.0+)
        if let positionRatio = item.positionRatio, let sizeRatio = item.sizeRatio {
            let x = positionRatio.x * canvasSize.width
            let y = positionRatio.y * canvasSize.height
            let width = sizeRatio.width * canvasSize.width
            let height = sizeRatio.height * canvasSize.height

            return CGRect(x: x, y: y, width: width, height: height)
        }

        // Fallback to legacy absolute positioning (version 1.0)
        // Scale from template canvas size if available
        if let templateSize = templateCanvasSize {
            let scaleX = canvasSize.width / templateSize.width
            let scaleY = canvasSize.height / templateSize.height
            let scale = min(scaleX, scaleY)

            return CGRect(
                x: item.position.x * scale,
                y: item.position.y * scale,
                width: item.size.width * scale,
                height: item.size.height * scale
            )
        }

        // No scaling information available - use as-is
        return CGRect(
            x: item.position.x,
            y: item.position.y,
            width: item.size.width,
            height: item.size.height
        )
    }

    private func validate(_ template: WidgetTemplate) throws {
        if template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw TemplateValidationError.emptyName
        }

        if let minVersion = template.minimumAppVersion, !template.isCompatible {
            throw TemplateValidationError.incompatibleMinimumVersion(required: minVersion)
        }

        if template.items.isEmpty {
            throw TemplateValidationError.emptyItems
        }

        if template.items.count > 150 {
            throw TemplateValidationError.tooManyItems(template.items.count)
        }

        for item in template.items {
            if !item.type.supportedSports.contains(template.sportType) {
                throw TemplateValidationError.unsupportedWidgetType(widget: item.type, sport: template.sportType)
            }

            if let positionRatio = item.positionRatio, let sizeRatio = item.sizeRatio {
                let ratioValues = [positionRatio.x, positionRatio.y, sizeRatio.width, sizeRatio.height]
                let hasInvalidRatio = ratioValues.contains { !$0.isFinite || $0 < 0 || $0 > 1 }
                let hasInvalidSize = sizeRatio.width <= 0 || sizeRatio.height <= 0
                if hasInvalidRatio || hasInvalidSize {
                    throw TemplateValidationError.invalidRatioValue(widget: item.type)
                }
                continue
            }

            let isLegacyFrameValid = item.size.width > 0
                && item.size.height > 0
                && item.position.x.isFinite
                && item.position.y.isFinite
                && item.size.width.isFinite
                && item.size.height.isFinite
            if !isLegacyFrameValid {
                throw TemplateValidationError.invalidLegacyFrame(widget: item.type)
            }
        }
    }
}
