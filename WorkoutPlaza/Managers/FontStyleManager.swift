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

    // GmarketSans
    case gmarketSansLight = "G마켓 산스 Light"
    case gmarketSansMedium = "G마켓 산스 Medium"
    case gmarketSansBold = "G마켓 산스 Bold"

    // Paperlogy
    case paperlogyThin = "페이퍼로지 Thin"
    case paperlogyExtraLight = "페이퍼로지 ExtraLight"
    case paperlogyLight = "페이퍼로지 Light"
    case paperlogyRegular = "페이퍼로지 Regular"
    case paperlogyMedium = "페이퍼로지 Medium"
    case paperlogySemiBold = "페이퍼로지 SemiBold"
    case paperlogyBold = "페이퍼로지 Bold"
    case paperlogyExtraBold = "페이퍼로지 ExtraBold"
    case paperlogyBlack = "페이퍼로지 Black"

    // RIDIBatang
    case ridiBatang = "리디바탕"

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

        // GmarketSans
        case .gmarketSansLight:
            return "GmarketSansTTFLight"
        case .gmarketSansMedium:
            return "GmarketSansTTFMedium"
        case .gmarketSansBold:
            return "GmarketSansTTFBold"

        // Paperlogy
        case .paperlogyThin:
            return "Paperlogy-1Thin"
        case .paperlogyExtraLight:
            return "Paperlogy-2ExtraLight"
        case .paperlogyLight:
            return "Paperlogy-3Light"
        case .paperlogyRegular:
            return "Paperlogy-4Regular"
        case .paperlogyMedium:
            return "Paperlogy-5Medium"
        case .paperlogySemiBold:
            return "Paperlogy-6SemiBold"
        case .paperlogyBold:
            return "Paperlogy-7Bold"
        case .paperlogyExtraBold:
            return "Paperlogy-8ExtraBold"
        case .paperlogyBlack:
            return "Paperlogy-9Black"

        // RIDIBatang
        case .ridiBatang:
            return "RIDIBatang"
        }
    }

    func font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        switch self {
        case .system:
            return .systemFont(ofSize: size, weight: weight)
        default:
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
