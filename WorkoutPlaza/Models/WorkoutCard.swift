//
//  WorkoutCard.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/26/26.
//

import UIKit

// MARK: - Workout Card Model

struct WorkoutCard: Codable, Identifiable {
    let id: String
    let sportType: SportType
    let workoutId: String           // 원본 운동 기록 ID
    let workoutTitle: String        // 표시용 제목 (예: "클라이밍 - 더클라임 강남")
    let workoutDate: Date           // 운동 날짜
    let createdAt: Date             // 카드 생성 시간
    let imageFileName: String       // 저장된 이미지 파일명
    let thumbnailFileName: String   // 썸네일 파일명

    init(
        id: String = UUID().uuidString,
        sportType: SportType,
        workoutId: String,
        workoutTitle: String,
        workoutDate: Date,
        createdAt: Date = Date(),
        imageFileName: String? = nil,
        thumbnailFileName: String? = nil
    ) {
        self.id = id
        self.sportType = sportType
        self.workoutId = workoutId
        self.workoutTitle = workoutTitle
        self.workoutDate = workoutDate
        self.createdAt = createdAt
        self.imageFileName = imageFileName ?? "\(id)_full.jpg"
        self.thumbnailFileName = thumbnailFileName ?? "\(id)_thumb.jpg"
    }
}

// MARK: - Workout Card Manager

class WorkoutCardManager {
    static let shared = WorkoutCardManager()

    private let userDefaults = UserDefaults.standard
    private let storageKey = "savedWorkoutCards"
    private let fileManager = FileManager.default

    private var cardsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let cardsPath = documentsPath.appendingPathComponent("WorkoutCards", isDirectory: true)

        if !fileManager.fileExists(atPath: cardsPath.path) {
            try? fileManager.createDirectory(at: cardsPath, withIntermediateDirectories: true)
        }

        return cardsPath
    }

    private init() {}

    // MARK: - Card CRUD

    func saveCards(_ cards: [WorkoutCard]) {
        if let encoded = try? JSONEncoder().encode(cards) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }

    func loadCards() -> [WorkoutCard] {
        guard let data = userDefaults.data(forKey: storageKey),
              let cards = try? JSONDecoder().decode([WorkoutCard].self, from: data) else {
            return []
        }
        return cards.sorted { $0.createdAt > $1.createdAt }
    }

    func loadCards(for sportType: SportType) -> [WorkoutCard] {
        return loadCards().filter { $0.sportType == sportType }
    }

    func findCard(forWorkoutId workoutId: String) -> WorkoutCard? {
        return loadCards().first { $0.workoutId == workoutId }
    }

    // MARK: - Create Card with Image

    @discardableResult
    func createCard(
        sportType: SportType,
        workoutId: String,
        workoutTitle: String,
        workoutDate: Date,
        image: UIImage
    ) -> WorkoutCard {
        let card = WorkoutCard(
            sportType: sportType,
            workoutId: workoutId,
            workoutTitle: workoutTitle,
            workoutDate: workoutDate
        )

        // Save full image
        saveImage(image, fileName: card.imageFileName)

        // Save thumbnail
        if let thumbnail = createThumbnail(from: image, maxSize: CGSize(width: 300, height: 300)) {
            saveImage(thumbnail, fileName: card.thumbnailFileName)
        }

        // Add to storage
        var cards = loadCards()

        // Remove existing card for same workout if exists
        cards.removeAll { $0.workoutId == workoutId }

        cards.insert(card, at: 0)
        saveCards(cards)

        return card
    }

    func updateCard(_ card: WorkoutCard, newImage: UIImage) {
        // Delete old images
        deleteImage(fileName: card.imageFileName)
        deleteImage(fileName: card.thumbnailFileName)

        // Save new images
        saveImage(newImage, fileName: card.imageFileName)
        if let thumbnail = createThumbnail(from: newImage, maxSize: CGSize(width: 300, height: 300)) {
            saveImage(thumbnail, fileName: card.thumbnailFileName)
        }

        // Update metadata
        var cards = loadCards()
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
            saveCards(cards)
        }
    }

    func deleteCard(_ card: WorkoutCard) {
        // Delete images
        deleteImage(fileName: card.imageFileName)
        deleteImage(fileName: card.thumbnailFileName)

        // Remove from storage
        var cards = loadCards()
        cards.removeAll { $0.id == card.id }
        saveCards(cards)
    }

    func deleteCard(forWorkoutId workoutId: String) {
        if let card = findCard(forWorkoutId: workoutId) {
            deleteCard(card)
        }
    }

    // MARK: - Image Operations

    private func saveImage(_ image: UIImage, fileName: String) {
        let fileURL = cardsDirectory.appendingPathComponent(fileName)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }

    private func deleteImage(fileName: String) {
        let fileURL = cardsDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }

    func loadImage(fileName: String) -> UIImage? {
        let fileURL = cardsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func loadFullImage(for card: WorkoutCard) -> UIImage? {
        return loadImage(fileName: card.imageFileName)
    }

    func loadThumbnail(for card: WorkoutCard) -> UIImage? {
        return loadImage(fileName: card.thumbnailFileName)
    }

    private func createThumbnail(from image: UIImage, maxSize: CGSize) -> UIImage? {
        let aspectRatio = image.size.width / image.size.height
        var newSize: CGSize

        if aspectRatio > 1 {
            newSize = CGSize(width: maxSize.width, height: maxSize.width / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize.height * aspectRatio, height: maxSize.height)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail
    }

    // MARK: - Statistics

    var totalCardCount: Int {
        return loadCards().count
    }

    func cardCount(for sportType: SportType) -> Int {
        return loadCards(for: sportType).count
    }
}

// MARK: - Shared Aspect Ratio

enum AspectRatio: String, CaseIterable, Codable {
    case square1_1 = "square_1_1"
    case portrait4_5 = "portrait_4_5"
    case portrait9_16 = "portrait_9_16"
    
    var displayName: String {
        switch self {
        case .square1_1: return "1:1"
        case .portrait4_5: return "4:5"
        case .portrait9_16: return "9:16"
        }
    }
    
    /// Height / Width (Standard for UI constraints/calculations)
    var ratio: CGFloat {
        switch self {
        case .square1_1: return 1.0
        case .portrait4_5: return 5.0 / 4.0
        case .portrait9_16: return 16.0 / 9.0
        }
    }
    
    /// Width / Height (Inverse of ratio)
    var sizeRatio: CGFloat {
        switch self {
        case .square1_1: return 1.0
        case .portrait4_5: return 4.0 / 5.0
        case .portrait9_16: return 9.0 / 16.0
        }
    }

    // Base size for export (width is fixed at 1080)
    var exportSize: CGSize {
        switch self {
        case .square1_1: return CGSize(width: 1080, height: 1080)
        case .portrait4_5: return CGSize(width: 1080, height: 1350)
        case .portrait9_16: return CGSize(width: 1080, height: 1920)
        }
    }

    // Detect aspect ratio from canvas size
    static func detect(from size: CGSize) -> AspectRatio {
        let calculatedRatio = size.height / size.width
        let ratios: [(AspectRatio, CGFloat)] = [
            (.square1_1, 1.0),
            (.portrait4_5, 1.25),
            (.portrait9_16, 1.777)
        ]
        
        // Find closest
        return ratios.min(by: { abs($0.1 - calculatedRatio) < abs($1.1 - calculatedRatio) })?.0 ?? .square1_1
    }
}
