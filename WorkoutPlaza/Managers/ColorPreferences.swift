//
//  ColorPreferences.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

class ColorPreferences {

    // MARK: - Singleton
    static let shared = ColorPreferences()

    private init() {}

    // MARK: - Keys
    private func colorKey(for itemIdentifier: String) -> String {
        return "color_\(itemIdentifier)"
    }

    // MARK: - Save
    func saveColor(_ color: UIColor, for itemIdentifier: String) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let colorData: [String: CGFloat] = [
            "red": red,
            "green": green,
            "blue": blue,
            "alpha": alpha
        ]

        UserDefaults.standard.set(colorData, forKey: colorKey(for: itemIdentifier))
    }

    // MARK: - Load
    func loadColor(for itemIdentifier: String) -> UIColor? {
        guard let colorData = UserDefaults.standard.dictionary(forKey: colorKey(for: itemIdentifier)) as? [String: CGFloat],
              let red = colorData["red"],
              let green = colorData["green"],
              let blue = colorData["blue"],
              let alpha = colorData["alpha"] else {
            return nil
        }

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    // MARK: - Delete
    func deleteColor(for itemIdentifier: String) {
        UserDefaults.standard.removeObject(forKey: colorKey(for: itemIdentifier))
    }

    // MARK: - Reset All
    func resetAll() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()

        for key in dictionary.keys {
            if key.hasPrefix("color_") {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
