//
//  FontStyleManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

// MARK: - Font Style
enum FontStyle: String, CaseIterable {
    case system = "System"
    case alata = "Alata"
    case bebasNeue = "Bebas Neue"
    case explora = "Explora"
    case ooohBaby = "Oooh Baby"

    var displayName: String {
        return rawValue
    }

    var fontName: String {
        switch self {
        case .system:
            return "System"
        case .alata:
            return "Alata-Regular"
        case .bebasNeue:
            return "BebasNeue-Regular"
        case .explora:
            return "Explora-Regular"
        case .ooohBaby:
            return "OoohBaby-Regular"
        }
    }

    func font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        switch self {
        case .system:
            return .systemFont(ofSize: size, weight: weight)
        case .alata, .bebasNeue, .explora, .ooohBaby:
            if let customFont = UIFont(name: fontName, size: size) {
                return customFont
            } else {
                WPLog.warning("Font '\(fontName)' not found, using system font")
                return .systemFont(ofSize: size, weight: weight)
            }
        }
    }
}

// MARK: - Font Preferences
class FontPreferences {
    static let shared = FontPreferences()

    private init() {}

    private func fontKey(for itemIdentifier: String) -> String {
        return "font_\(itemIdentifier)"
    }

    func saveFont(_ fontStyle: FontStyle, for itemIdentifier: String) {
        UserDefaults.standard.set(fontStyle.rawValue, forKey: fontKey(for: itemIdentifier))
    }

    func loadFont(for itemIdentifier: String) -> FontStyle? {
        guard let rawValue = UserDefaults.standard.string(forKey: fontKey(for: itemIdentifier)),
              let fontStyle = FontStyle(rawValue: rawValue) else {
            return nil
        }
        return fontStyle
    }

    func deleteFont(for itemIdentifier: String) {
        UserDefaults.standard.removeObject(forKey: fontKey(for: itemIdentifier))
    }
}
