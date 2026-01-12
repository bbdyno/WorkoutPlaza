//
//  TemplateManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

class TemplateManager {
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
    func getAllTemplates() -> [WidgetTemplate] {
        loadCustomTemplates()
        return WidgetTemplate.allBuiltInTemplates + customTemplates
    }

    func getBuiltInTemplates() -> [WidgetTemplate] {
        return WidgetTemplate.allBuiltInTemplates
    }

    func getCustomTemplates() -> [WidgetTemplate] {
        loadCustomTemplates()
        return customTemplates
    }

    // MARK: - Save Custom Template
    func saveCustomTemplate(_ template: WidgetTemplate) throws {
        let fileURL = templatesDirectoryURL.appendingPathComponent("\(template.id).json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(template)
        try data.write(to: fileURL)

        // Reload custom templates
        loadCustomTemplates()

        print("✅ Template saved: \(template.name) at \(fileURL.path)")
    }

    // MARK: - Delete Custom Template
    func deleteCustomTemplate(_ template: WidgetTemplate) throws {
        let fileURL = templatesDirectoryURL.appendingPathComponent("\(template.id).json")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
            loadCustomTemplates()
            print("🗑️ Template deleted: \(template.name)")
        }
    }

    // MARK: - Load Custom Templates
    private func loadCustomTemplates() {
        customTemplates.removeAll()

        guard let files = try? FileManager.default.contentsOfDirectory(at: templatesDirectoryURL, includingPropertiesForKeys: nil) else {
            return
        }

        for fileURL in files where fileURL.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                let template = try decoder.decode(WidgetTemplate.self, from: data)
                customTemplates.append(template)
            } catch {
                print("⚠️ Failed to load template from \(fileURL.lastPathComponent): \(error)")
            }
        }

        print("📂 Loaded \(customTemplates.count) custom templates")
    }

    // MARK: - Export Template
    func exportTemplate(_ template: WidgetTemplate) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(template)

        // Create temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "\(template.name.replacingOccurrences(of: " ", with: "_")).json"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        try data.write(to: fileURL)

        print("📤 Template exported: \(fileURL.path)")
        return fileURL
    }

    // MARK: - Import Template
    func importTemplate(from url: URL) throws -> WidgetTemplate {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let template = try decoder.decode(WidgetTemplate.self, from: data)

        // Save as custom template
        try saveCustomTemplate(template)

        print("📥 Template imported: \(template.name)")
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
}
