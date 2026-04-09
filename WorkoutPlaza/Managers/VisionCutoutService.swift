//
//  VisionCutoutService.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/9/26.
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

enum VisionCutoutMode {
    case person
    case foreground
}

enum VisionCutoutResult {
    case success(UIImage)
    case notFound
}

struct VisionForegroundSelectionResult {
    let cutoutImage: UIImage
    let previewImage: UIImage
}

final class VisionForegroundSelectionSession: @unchecked Sendable {
    let preparedImage: UIImage
    let observation: VNInstanceMaskObservation
    let previewImage: UIImage

    init(preparedImage: UIImage, observation: VNInstanceMaskObservation, previewImage: UIImage) {
        self.preparedImage = preparedImage
        self.observation = observation
        self.previewImage = previewImage
    }
}

final class VisionCutoutService {
    static let shared = VisionCutoutService()

    private enum Constants {
        static let maxProcessingDimension: CGFloat = 2048
        static let minimumMaskCoverage: CGFloat = 0.01
    }

    private init() {}

    nonisolated func extractCutout(from image: UIImage, mode: VisionCutoutMode) async throws -> VisionCutoutResult {
        try await Task.detached(priority: .userInitiated) {
            switch mode {
            case .person:
                return try Self.extractForegroundPersonSynchronously(from: image)
            case .foreground:
                return try Self.extractForegroundSubjectSynchronously(from: image)
            }
        }.value
    }

    nonisolated func prepareForegroundSelection(from image: UIImage) async throws -> VisionForegroundSelectionSession? {
        try await Task.detached(priority: .userInitiated) {
            try Self.prepareForegroundSelectionSynchronously(from: image)
        }.value
    }

    nonisolated func extractForegroundInstance(
        from session: VisionForegroundSelectionSession,
        normalizedPoint: CGPoint
    ) async throws -> VisionForegroundSelectionResult? {
        try await Task.detached(priority: .userInitiated) {
            try Self.extractForegroundInstanceSynchronously(from: session, normalizedPoint: normalizedPoint)
        }.value
    }

    nonisolated private static func extractForegroundPersonSynchronously(from image: UIImage) throws -> VisionCutoutResult {
        let preparedImage = image.preparedForSegmentation(maxDimension: Constants.maxProcessingDimension)
        let ciContext = CIContext()

        guard let cgImage = preparedImage.cgImage else {
            throw NSError(domain: "VisionCutoutService", code: -1)
        }

        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        guard let pixelBuffer = request.results?.first?.pixelBuffer else {
            return .notFound
        }

        let sourceImage = CIImage(cgImage: cgImage)
        let maskImage = CIImage(cvPixelBuffer: pixelBuffer)
        let scaleX = sourceImage.extent.width / maskImage.extent.width
        let scaleY = sourceImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage
            .transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            .cropped(to: sourceImage.extent)

        let maskCoverage = averageIntensity(of: scaledMask, using: ciContext)
        guard maskCoverage >= Constants.minimumMaskCoverage else {
            return .notFound
        }

        let transparentBackground = CIImage(color: CIColor.clear).cropped(to: sourceImage.extent)
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = sourceImage
        blendFilter.backgroundImage = transparentBackground
        blendFilter.maskImage = scaledMask

        guard let outputImage = blendFilter.outputImage,
              let outputCGImage = ciContext.createCGImage(outputImage, from: sourceImage.extent) else {
            throw NSError(domain: "VisionCutoutService", code: -2)
        }

        return .success(UIImage(cgImage: outputCGImage, scale: preparedImage.scale, orientation: .up))
    }

    nonisolated private static func extractForegroundSubjectSynchronously(from image: UIImage) throws -> VisionCutoutResult {
        guard let session = try prepareForegroundSelectionSynchronously(from: image) else {
            return .notFound
        }

        let cutoutImage = try cutoutImage(
            from: session.preparedImage,
            observation: session.observation,
            instances: session.observation.allInstances
        )
        return .success(cutoutImage)
    }

    nonisolated private static func prepareForegroundSelectionSynchronously(from image: UIImage) throws -> VisionForegroundSelectionSession? {
        let preparedImage = image.preparedForSegmentation(maxDimension: Constants.maxProcessingDimension)
        let ciContext = CIContext()

        guard let cgImage = preparedImage.cgImage else {
            throw NSError(domain: "VisionCutoutService", code: -3)
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first,
              !observation.allInstances.isEmpty else {
            return nil
        }

        let scaledMaskBuffer = try observation.generateScaledMaskForImage(
            forInstances: observation.allInstances,
            from: handler
        )
        let maskCoverage = averageIntensity(of: CIImage(cvPixelBuffer: scaledMaskBuffer), using: ciContext)
        guard maskCoverage >= Constants.minimumMaskCoverage else {
            return nil
        }

        let previewImage = try previewImage(
            from: preparedImage,
            observation: observation,
            instances: observation.allInstances
        )

        return VisionForegroundSelectionSession(
            preparedImage: preparedImage,
            observation: observation,
            previewImage: previewImage
        )
    }

    nonisolated private static func extractForegroundInstanceSynchronously(
        from session: VisionForegroundSelectionSession,
        normalizedPoint: CGPoint
    ) throws -> VisionForegroundSelectionResult? {
        let selectedInstances = selectedInstances(
            from: session.observation,
            normalizedPoint: normalizedPoint
        )
        guard !selectedInstances.isEmpty else {
            return nil
        }

        let cutoutImage = try cutoutImage(
            from: session.preparedImage,
            observation: session.observation,
            instances: selectedInstances
        )
        let previewImage = try previewImage(
            from: session.preparedImage,
            observation: session.observation,
            instances: selectedInstances
        )

        return VisionForegroundSelectionResult(
            cutoutImage: cutoutImage,
            previewImage: previewImage
        )
    }

    nonisolated private static func cutoutImage(
        from image: UIImage,
        observation: VNInstanceMaskObservation,
        instances: IndexSet
    ) throws -> UIImage {
        let ciContext = CIContext()
        let sourceImage = try sourceCIImage(from: image)
        let scaledMask = try scaledMaskImage(
            from: observation,
            using: image,
            instances: instances
        )

        let transparentBackground = CIImage(color: CIColor.clear).cropped(to: sourceImage.extent)
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = sourceImage
        blendFilter.backgroundImage = transparentBackground
        blendFilter.maskImage = scaledMask

        guard let outputImage = blendFilter.outputImage,
              let outputCGImage = ciContext.createCGImage(outputImage, from: sourceImage.extent) else {
            throw NSError(domain: "VisionCutoutService", code: -6)
        }

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: .up)
    }

    nonisolated private static func previewImage(
        from image: UIImage,
        observation: VNInstanceMaskObservation,
        instances: IndexSet
    ) throws -> UIImage {
        let ciContext = CIContext()
        let sourceImage = try sourceCIImage(from: image)
        let scaledMask = try scaledMaskImage(
            from: observation,
            using: image,
            instances: instances
        )

        let highlightColor = CIImage(
            color: CIColor(red: 1, green: 1, blue: 1, alpha: 0.45)
        ).cropped(to: sourceImage.extent)
        let transparentBackground = CIImage(color: CIColor.clear).cropped(to: sourceImage.extent)
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = highlightColor
        blendFilter.backgroundImage = transparentBackground
        blendFilter.maskImage = scaledMask

        guard let outputImage = blendFilter.outputImage,
              let outputCGImage = ciContext.createCGImage(outputImage, from: sourceImage.extent) else {
            throw NSError(domain: "VisionCutoutService", code: -7)
        }

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: .up)
    }

    nonisolated private static func scaledMaskImage(
        from observation: VNInstanceMaskObservation,
        using image: UIImage,
        instances: IndexSet
    ) throws -> CIImage {
        let ciContext = CIContext()
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionCutoutService", code: -8)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        let scaledMaskBuffer = try observation.generateScaledMaskForImage(
            forInstances: instances,
            from: handler
        )
        let scaledMask = CIImage(cvPixelBuffer: scaledMaskBuffer)
        let maskCoverage = averageIntensity(of: scaledMask, using: ciContext)
        guard maskCoverage >= Constants.minimumMaskCoverage else {
            throw NSError(domain: "VisionCutoutService", code: -9)
        }

        return scaledMask
    }

    nonisolated private static func sourceCIImage(from image: UIImage) throws -> CIImage {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionCutoutService", code: -10)
        }
        return CIImage(cgImage: cgImage)
    }

    nonisolated private static func selectedInstances(
        from observation: VNInstanceMaskObservation,
        normalizedPoint: CGPoint
    ) -> IndexSet {
        let clampedPoint = CGPoint(
            x: min(max(normalizedPoint.x, 0), 1),
            y: min(max(normalizedPoint.y, 0), 1)
        )

        let maskBuffer = observation.instanceMask
        let directLabel = dominantInstanceLabel(
            in: maskBuffer,
            normalizedPoint: clampedPoint,
            flipY: false
        )
        let flippedLabel = dominantInstanceLabel(
            in: maskBuffer,
            normalizedPoint: clampedPoint,
            flipY: true
        )

        let resolvedLabel: Int
        if directLabel > 0 {
            resolvedLabel = directLabel
        } else {
            resolvedLabel = flippedLabel
        }

        guard resolvedLabel > 0 else { return [] }
        return IndexSet(integer: resolvedLabel)
    }

    nonisolated private static func dominantInstanceLabel(
        in pixelBuffer: CVPixelBuffer,
        normalizedPoint: CGPoint,
        flipY: Bool
    ) -> Int {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return 0 }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

        let pointX = min(max(Int(normalizedPoint.x * CGFloat(width - 1)), 0), max(width - 1, 0))
        let rawY = min(max(Int(normalizedPoint.y * CGFloat(height - 1)), 0), max(height - 1, 0))
        let pointY = flipY ? (height - 1 - rawY) : rawY

        var counts: [Int: Int] = [:]
        let radius = max(1, min(width, height) / 80)

        for y in max(0, pointY - radius)...min(height - 1, pointY + radius) {
            for x in max(0, pointX - radius)...min(width - 1, pointX + radius) {
                let label = instanceLabel(
                    atX: x,
                    y: y,
                    baseAddress: baseAddress,
                    bytesPerRow: bytesPerRow,
                    pixelFormat: pixelFormat
                )
                guard label > 0 else { continue }
                counts[label, default: 0] += 1
            }
        }

        return counts.max(by: { $0.value < $1.value })?.key ?? 0
    }

    nonisolated private static func instanceLabel(
        atX x: Int,
        y: Int,
        baseAddress: UnsafeMutableRawPointer,
        bytesPerRow: Int,
        pixelFormat: OSType
    ) -> Int {
        let rowPointer = baseAddress.advanced(by: y * bytesPerRow)

        switch pixelFormat {
        case kCVPixelFormatType_OneComponent8:
            let pointer = rowPointer.assumingMemoryBound(to: UInt8.self)
            return Int(pointer[x])

        case kCVPixelFormatType_OneComponent16Half, kCVPixelFormatType_OneComponent16:
            let pointer = rowPointer.assumingMemoryBound(to: UInt16.self)
            return Int(pointer[x])

        case kCVPixelFormatType_OneComponent32Float:
            let pointer = rowPointer.assumingMemoryBound(to: Float.self)
            return Int(pointer[x].rounded())

        default:
            return 0
        }
    }

    nonisolated private static func averageIntensity(of image: CIImage, using ciContext: CIContext) -> CGFloat {
        let filter = CIFilter.areaAverage()
        filter.inputImage = image
        filter.extent = image.extent

        guard let outputImage = filter.outputImage else { return 0 }

        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        return CGFloat(bitmap[0]) / 255.0
    }
}

private extension UIImage {
    func preparedForSegmentation(maxDimension: CGFloat) -> UIImage {
        let normalizedSize = size
        let longestEdge = max(normalizedSize.width, normalizedSize.height)
        guard longestEdge > maxDimension else { return normalizedImage() }

        let scaleRatio = maxDimension / longestEdge
        let targetSize = CGSize(
            width: normalizedSize.width * scaleRatio,
            height: normalizedSize.height * scaleRatio
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            normalizedImage().draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func normalizedImage() -> UIImage {
        guard imageOrientation == .up else {
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = scale
            format.opaque = false

            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { _ in
                draw(in: CGRect(origin: .zero, size: size))
            }
        }

        return self
    }
}
