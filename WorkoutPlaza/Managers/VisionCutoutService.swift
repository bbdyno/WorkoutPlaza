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
            return .notFound
        }

        let scaledMaskBuffer = try observation.generateScaledMaskForImage(
            forInstances: observation.allInstances,
            from: handler
        )
        let maskCoverage = averageIntensity(of: CIImage(cvPixelBuffer: scaledMaskBuffer), using: ciContext)
        guard maskCoverage >= Constants.minimumMaskCoverage else {
            return .notFound
        }

        let maskedImageBuffer = try observation.generateMaskedImage(
            ofInstances: observation.allInstances,
            from: handler,
            croppedToInstancesExtent: false
        )
        let outputImage = CIImage(cvPixelBuffer: maskedImageBuffer)
        let outputExtent = outputImage.extent

        guard let outputCGImage = ciContext.createCGImage(outputImage, from: outputExtent) else {
            throw NSError(domain: "VisionCutoutService", code: -4)
        }

        return .success(UIImage(cgImage: outputCGImage, scale: preparedImage.scale, orientation: .up))
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
