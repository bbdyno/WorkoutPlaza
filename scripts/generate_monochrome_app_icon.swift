#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

struct IconOutput {
    let filename: String
    let size: Int
}

let outputs: [IconOutput] = [
    .init(filename: "20.png", size: 20),
    .init(filename: "29.png", size: 29),
    .init(filename: "40.png", size: 40),
    .init(filename: "50.png", size: 50),
    .init(filename: "57.png", size: 57),
    .init(filename: "58.png", size: 58),
    .init(filename: "60.png", size: 60),
    .init(filename: "72.png", size: 72),
    .init(filename: "76.png", size: 76),
    .init(filename: "80.png", size: 80),
    .init(filename: "87.png", size: 87),
    .init(filename: "100.png", size: 100),
    .init(filename: "114.png", size: 114),
    .init(filename: "120.png", size: 120),
    .init(filename: "144.png", size: 144),
    .init(filename: "152.png", size: 152),
    .init(filename: "167.png", size: 167),
    .init(filename: "180.png", size: 180),
    .init(filename: "1024.png", size: 1024)
]

func smoothstep(edge0: Double, edge1: Double, value: Double) -> Double {
    guard edge0 != edge1 else { return value < edge0 ? 0 : 1 }
    let t = min(max((value - edge0) / (edge1 - edge0), 0), 1)
    return t * t * (3 - (2 * t))
}

func bitmapContext(width: Int, height: Int) -> CGContext? {
    CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
}

func rgbaBytes(from image: CGImage) -> [UInt8]? {
    guard let context = bitmapContext(width: image.width, height: image.height) else { return nil }
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

    guard let data = context.data else { return nil }
    let count = image.width * image.height * 4
    return Array(UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: count))
}

func writePNG(cgImage: CGImage, to url: URL) throws {
    let representation = NSBitmapImageRep(cgImage: cgImage)
    guard let data = representation.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    try data.write(to: url)
}

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconDirectory = repoRoot.appendingPathComponent("WorkoutPlaza/Assets.xcassets/AppIcon.appiconset")
let sourceURL = iconDirectory.appendingPathComponent("1024.png")

guard let sourceRep = NSBitmapImageRep(data: try Data(contentsOf: sourceURL)),
      let sourceImage = sourceRep.cgImage,
      let sourceBytes = rgbaBytes(from: sourceImage) else {
    fatalError("Unable to load source app icon at \(sourceURL.path)")
}

let width = sourceImage.width
let height = sourceImage.height
let background = (r: 17.0 / 255.0, g: 17.0 / 255.0, b: 17.0 / 255.0)
var outputBytes = [UInt8](repeating: 0, count: width * height * 4)

for y in 0 ..< height {
    for x in 0 ..< width {
        let offset = (y * width + x) * 4
        let red = Double(sourceBytes[offset]) / 255.0
        let green = Double(sourceBytes[offset + 1]) / 255.0
        let blue = Double(sourceBytes[offset + 2]) / 255.0
        let alpha = Double(sourceBytes[offset + 3]) / 255.0

        let minChannel = min(red, green, blue)
        let maxChannel = max(red, green, blue)
        let saturation = maxChannel == 0 ? 0 : (maxChannel - minChannel) / maxChannel
        let brightness = maxChannel

        var mask = smoothstep(edge0: 0.56, edge1: 0.9, value: minChannel)
        mask *= smoothstep(edge0: 0.72, edge1: 0.98, value: brightness)
        mask *= (1.0 - 0.28 * saturation)
        mask *= alpha
        mask = min(max(mask, 0), 1)

        let outRed = background.r * (1 - mask) + mask
        let outGreen = background.g * (1 - mask) + mask
        let outBlue = background.b * (1 - mask) + mask

        outputBytes[offset] = UInt8((outRed * 255.0).rounded())
        outputBytes[offset + 1] = UInt8((outGreen * 255.0).rounded())
        outputBytes[offset + 2] = UInt8((outBlue * 255.0).rounded())
        outputBytes[offset + 3] = 255
    }
}

guard let masterContext = bitmapContext(width: width, height: height) else {
    fatalError("Unable to create output context")
}

let byteCount = outputBytes.count
outputBytes.withUnsafeBytes { bytes in
    guard let baseAddress = bytes.baseAddress, let destination = masterContext.data else { return }
    memcpy(destination, baseAddress, byteCount)
}

guard let masterImage = masterContext.makeImage() else {
    fatalError("Unable to finalize master icon")
}

for output in outputs {
    guard let context = bitmapContext(width: output.size, height: output.size) else {
        fatalError("Unable to create resize context for \(output.filename)")
    }

    context.interpolationQuality = .high
    context.draw(masterImage, in: CGRect(x: 0, y: 0, width: output.size, height: output.size))

    guard let resizedImage = context.makeImage() else {
        fatalError("Unable to render \(output.filename)")
    }

    let destinationURL = iconDirectory.appendingPathComponent(output.filename)
    try writePNG(cgImage: resizedImage, to: destinationURL)
    print("Wrote \(destinationURL.path)")
}
