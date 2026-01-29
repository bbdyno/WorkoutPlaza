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
    func loadLogo(for gym: ClimbingGym, completion: @escaping (UIImage?) -> Void) {
        switch gym.logoSource {
        case .assetName(let name):
            completion(UIImage(named: name))

        case .imageData(let data):
            completion(UIImage(data: data))

        case .url(let urlString):
            loadLogoFromURL(urlString, completion: completion)

        case .none:
            completion(placeholderImage)
        }
    }

    private func loadLogoFromURL(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cached = imageCache[urlString] {
            completion(cached)
            return
        }

        // Check if already downloading
        if downloadTasks[urlString] != nil {
            // Already downloading, return placeholder for now
            // In a production app, you might want to queue callbacks
            completion(placeholderImage)
            return
        }

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
                DispatchQueue.main.async { completion(self?.placeholderImage) }
                return
            }

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
