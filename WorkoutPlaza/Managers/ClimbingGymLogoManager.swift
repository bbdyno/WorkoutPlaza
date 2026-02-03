//
//  ClimbingGymLogoManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/29/26.
//

import UIKit

actor ClimbingGymLogoManager {
    static let shared = ClimbingGymLogoManager()

    private let imageCache = NSCache<NSString, UIImage>()
    
    // Keep track of ongoing tasks to avoid duplicate requests
    private var activeTasks: [String: Task<UIImage?, Error>] = [:]

    private init() {
        // Optional: specific limits for cache
        imageCache.countLimit = 100 // Example limit
    }

    /// Load logo for a gym based on its LogoSource (Async)
    /// - Parameters:
    ///   - gym: The gym to load logo for
    ///   - asTemplate: If true, returns image with .alwaysTemplate rendering mode (useful for tinting)
    /// - Returns: Loaded UIImage or nil
    func loadLogo(for gym: ClimbingGym, asTemplate: Bool = false) async -> UIImage? {
        var image: UIImage?

        switch gym.logoSource {
        case .assetName(let name):
            image = UIImage(named: name)

        case .imageData(let data):
            image = UIImage(data: data)

        case .url(let urlString):
            image = await loadLogoFromURL(urlString)

        case .none:
            image = placeholderImage
        }

        if asTemplate, let loadedImage = image {
            return loadedImage.withRenderingMode(.alwaysTemplate)
        }
        
        return image
    }

    private func loadLogoFromURL(_ urlString: String) async -> UIImage? {
        let cacheKey = urlString as NSString

        // 1. Check Memory Cache
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }

        // 2. Check for existing task (deduplication)
        if let existingTask = activeTasks[urlString] {
            return try? await existingTask.value
        }

        // 3. Create new task
        let task = Task<UIImage?, Error> {
            guard let url = URL(string: urlString) else { return nil }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, 
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                return nil
            }
            
            return image
        }
        
        activeTasks[urlString] = task
        
        let loadedImage = try? await task.value
        
        // Cleanup task
        activeTasks.removeValue(forKey: urlString)
        
        if let image = loadedImage {
             // Cache the result
             imageCache.setObject(image, forKey: cacheKey)
        }
        
        return loadedImage ?? placeholderImage
    }

    var placeholderImage: UIImage? {
        UIImage(systemName: "building.2.fill")
    }

    func clearCache() {
        imageCache.removeAllObjects()
    }
}
