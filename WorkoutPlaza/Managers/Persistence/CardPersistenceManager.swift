//
//  CardPersistenceManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/26/26.
//

import UIKit

// MARK: - Models

struct SavedCardDesign: Codable {
    let backgroundType: BackgroundType
    let backgroundColor: String? // Hex code or identifier
    let backgroundImageData: Data?
    let widgets: [SavedWidgetState]
    let canvasSize: CGSize
    let aspectRatio: AspectRatio
    let gradientColors: [String]? // Hex codes for gradient
    let gradientStyle: Int? // BackgroundTemplateStyle rawValue
}

struct SavedWidgetState: Codable {
    let type: String // Widget type identifier
    let frame: CGRect
    let text: String?
    let fontName: String?
    let fontSize: CGFloat?
    let textColor: String? // Hex code
    let backgroundColor: String? // Hex code
    let rotation: CGFloat
    let zIndex: Int
    // Add specific properties for different widget types if needed
}

enum BackgroundType: String, Codable {
    case solid
    case gradient
    case image
}

// MARK: - Manager

class CardPersistenceManager {
    static let shared = CardPersistenceManager()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var documentsDirectory: URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private func fileURL(for workoutId: String) -> URL {
        return documentsDirectory.appendingPathComponent("card_design_\(workoutId).json")
    }
    
    func saveDesign(_ design: SavedCardDesign, for workoutId: String) throws {
        let data = try encoder.encode(design)
        let url = fileURL(for: workoutId)
        try data.write(to: url)
    }
    
    func loadDesign(for workoutId: String) -> SavedCardDesign? {
        let url = fileURL(for: workoutId)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(SavedCardDesign.self, from: data)
        } catch {
            print("Failed to load design: \(error)")
            return nil
        }
    }
    
    func hasSavedDesign(for workoutId: String) -> Bool {
        let url = fileURL(for: workoutId)
        return fileManager.fileExists(atPath: url.path)
    }
    
    func deleteDesign(for workoutId: String) {
        let url = fileURL(for: workoutId)
        try? fileManager.removeItem(at: url)
    }
}

// MARK: - Extensions

extension UIColor {
    func toHex() -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != 1.0 {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
    
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
            
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
