//
//  ClimbingGymLogoManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/29/26.
//

import UIKit

class ClimbingGymLogoManager {
    static let shared = ClimbingGymLogoManager()

    private var imageCache: [String: UIImage] = [:]
    private var downloadTasks: [String: URLSessionDataTask] = [:]

    private init() {}

    /// Load logo for a gym based on its LogoSource
    /// - Parameters:
    ///   - gym: The gym to load logo for
    ///   - asTemplate: If true, returns image with .alwaysTemplate rendering mode (useful for tinting)
    ///   - completion: Callback with loaded image
    func loadLogo(for gym: ClimbingGym, asTemplate: Bool = false, completion: @escaping (UIImage?) -> Void) {
        let handler: (UIImage?) -> Void = { image in
            if asTemplate, let image = image {
                completion(image.withRenderingMode(.alwaysTemplate))
            } else {
                completion(image)
            }
        }

        switch gym.logoSource {
        case .assetName(let name):
            handler(UIImage(named: name))

        case .imageData(let data):
            handler(UIImage(data: data))

        case .url(let urlString):
            loadLogoFromURL(urlString, completion: handler)

        case .none:
            handler(placeholderImage)
        }
    }

    private func loadLogoFromURL(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cached = imageCache[urlString] {
            completion(cached)
            return
        }

        // Check if already downloading
        // Check if already downloading - For now, we'll allow concurrent requests to ensure all cells get a callback.
        // In a clearer implementation, we should queue callbacks. 
        // Removing the blocking check to prevent permanent placeholders.
        
        WPLog.debug("Loading logo from URL: \(urlString)")

        // Start download
        guard let url = URL(string: urlString) else {
            completion(placeholderImage)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            defer { self?.downloadTasks.removeValue(forKey: urlString) }

            guard let data = data,
                  let image = UIImage(data: data)
            else {
                WPLog.warning("Failed to load image from URL: \(urlString)")
                DispatchQueue.main.async { completion(self?.placeholderImage) }
                return
            }

            WPLog.debug("Successfully loaded logo for: \(urlString)")

            self?.imageCache[urlString] = image
            DispatchQueue.main.async { completion(image) }
        }

        downloadTasks[urlString] = task
        task.resume()
    }

    var placeholderImage: UIImage? {
        UIImage(systemName: "building.2.fill")
    }

    func clearCache() {
        imageCache.removeAll()
        downloadTasks.values.forEach { $0.cancel() }
        downloadTasks.removeAll()
    }
}
