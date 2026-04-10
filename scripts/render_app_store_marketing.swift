#!/usr/bin/env swift

import AppKit
import CoreText
import Foundation

enum RenderError: Error {
    case invalidArguments
    case missingSource(URL)
    case failedToLoadImage(URL)
    case failedToCreatePNG
}

enum DeviceKind {
    case phone
    case tablet
}

struct DeviceSpec {
    let label: String
    let canvasSize: CGSize
    let kind: DeviceKind
}

struct CopySpec {
    let eyebrow: String
    let title: String
    let subtitle: String
}

struct Palette {
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let orb: NSColor
    let panel: NSColor
    let accent: NSColor
    let line: NSColor
    let title: NSColor
    let body: NSColor
}

struct ScreenSpec {
    let fileName: String
    let number: String
    let palette: Palette
    let copy: [String: CopySpec]
}

struct HeaderLayout {
    let bottomY: CGFloat
}

let devices = [
    DeviceSpec(label: "iPhone-6.5", canvasSize: CGSize(width: 1284, height: 2778), kind: .phone),
    DeviceSpec(label: "iPad-13", canvasSize: CGSize(width: 2064, height: 2752), kind: .tablet)
]

let screens = [
    ScreenSpec(
        fileName: "01-home.png",
        number: "01",
        palette: Palette(
            backgroundTop: color("#F8F4ED"),
            backgroundBottom: color("#E8E1D5"),
            orb: color("#DCCDB7"),
            panel: color("#F4EFE5", alpha: 0.72),
            accent: color("#B59365"),
            line: color("#D5C4AA"),
            title: color("#121212"),
            body: color("#434343")
        ),
        copy: [
            "ko": CopySpec(
                eyebrow: "홈 대시보드",
                title: "운동 기록을\n카드로 완성",
                subtitle: "러닝과 클라이밍 기록을 저장하고,\n공유 가능한 결과물로 정리하세요."
            ),
            "en": CopySpec(
                eyebrow: "Home Dashboard",
                title: "Turn Workouts Into\nPoster Cards",
                subtitle: "Capture running and climbing sessions,\nthen shape them into shareable output."
            )
        ]
    ),
    ScreenSpec(
        fileName: "02-statistics-all.png",
        number: "02",
        palette: Palette(
            backgroundTop: color("#F3F5F3"),
            backgroundBottom: color("#E0E5E0"),
            orb: color("#C8D0CB"),
            panel: color("#F5F7F5", alpha: 0.74),
            accent: color("#738173"),
            line: color("#C3CCC4"),
            title: color("#151515"),
            body: color("#485048")
        ),
        copy: [
            "ko": CopySpec(
                eyebrow: "전체 통계",
                title: "월간부터 올타임까지\n한눈에 확인",
                subtitle: "기간별 통계와 누적 기록을 같은 흐름 안에서\n깔끔하게 비교할 수 있습니다."
            ),
            "en": CopySpec(
                eyebrow: "Statistics",
                title: "See Progress Across\nEvery Time Range",
                subtitle: "Review monthly, yearly, and all-time stats\nin one consistent system."
            )
        ]
    ),
    ScreenSpec(
        fileName: "03-saved-card-detail.png",
        number: "03",
        palette: Palette(
            backgroundTop: color("#F7F0E7"),
            backgroundBottom: color("#E9DED0"),
            orb: color("#D4B89D"),
            panel: color("#FBF6F0", alpha: 0.74),
            accent: color("#9D6D4A"),
            line: color("#D7BFA6"),
            title: color("#151515"),
            body: color("#4D4640")
        ),
        copy: [
            "ko": CopySpec(
                eyebrow: "저장 카드",
                title: "완성된 카드는\n바로 보관하고 공유",
                subtitle: "저장한 카드의 디테일을 확인하고,\n필요한 순간 바로 꺼내 쓸 수 있습니다."
            ),
            "en": CopySpec(
                eyebrow: "Saved Cards",
                title: "Keep Finished Cards\nReady to Share",
                subtitle: "Saved cards stay polished and accessible,\nso the final output remains the focus."
            )
        ]
    ),
    ScreenSpec(
        fileName: "04-climbing-input.png",
        number: "04",
        palette: Palette(
            backgroundTop: color("#F4F0EA"),
            backgroundBottom: color("#E4DDD4"),
            orb: color("#D1C5B4"),
            panel: color("#F8F3EB", alpha: 0.74),
            accent: color("#85725B"),
            line: color("#CBBEAE"),
            title: color("#171717"),
            body: color("#4E4A45")
        ),
        copy: [
            "ko": CopySpec(
                eyebrow: "클라이밍 입력",
                title: "클라이밍도\n러닝처럼 세밀하게",
                subtitle: "암장, 난이도, 성공 여부까지\n종목에 맞는 입력 흐름으로 기록합니다."
            ),
            "en": CopySpec(
                eyebrow: "Climbing Input",
                title: "Track Climbing With\nSport-Specific Detail",
                subtitle: "Log gym visits, grades, and sends with\nan input flow tailored to the sport."
            )
        ]
    ),
    ScreenSpec(
        fileName: "05-running-detail.png",
        number: "05",
        palette: Palette(
            backgroundTop: color("#F2F3EF"),
            backgroundBottom: color("#DFE2DB"),
            orb: color("#C4CCBF"),
            panel: color("#F6F7F3", alpha: 0.74),
            accent: color("#6F7D68"),
            line: color("#C4CDC0"),
            title: color("#161616"),
            body: color("#4B5048")
        ),
        copy: [
            "ko": CopySpec(
                eyebrow: "러닝 상세",
                title: "루트와 페이스까지\n선명하게 복기",
                subtitle: "세션 요약, 경로, 수치가 한 화면에서 정리돼\n운동 디테일을 빠르게 확인할 수 있습니다."
            ),
            "en": CopySpec(
                eyebrow: "Running Detail",
                title: "Review Route, Pace,\nand Session Details",
                subtitle: "Session summaries, maps, and metrics stay clear\nwithout overwhelming the screen."
            )
        ]
    )
]

let arguments = CommandLine.arguments

do {
    guard let sourcesRoot = argumentValue(flag: "--sources"),
          let outputRoot = argumentValue(flag: "--output") else {
        throw RenderError.invalidArguments
    }

    registerFonts()

    let fileManager = FileManager.default

    for locale in ["ko", "en"] {
        for device in devices {
            let outputDir = URL(fileURLWithPath: outputRoot).appendingPathComponent(locale).appendingPathComponent(device.label)
            try fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)

            for screen in screens {
                let sourceURL = URL(fileURLWithPath: sourcesRoot)
                    .appendingPathComponent(locale)
                    .appendingPathComponent(device.label)
                    .appendingPathComponent(screen.fileName)

                guard fileManager.fileExists(atPath: sourceURL.path) else {
                    throw RenderError.missingSource(sourceURL)
                }

                guard let sourceImage = NSImage(contentsOf: sourceURL) else {
                    throw RenderError.failedToLoadImage(sourceURL)
                }

                let rendered = try renderImage(
                    sourceImage: sourceImage,
                    device: device,
                    screen: screen,
                    copy: screen.copy[locale] ?? screen.copy["en"]!
                )

                let destinationURL = outputDir.appendingPathComponent(screen.fileName)
                try savePNG(rendered, to: destinationURL)
            }
        }
    }
} catch {
    fputs("render_app_store_marketing.swift failed: \(error)\n", stderr)
    exit(1)
}

func renderImage(sourceImage: NSImage, device: DeviceSpec, screen: ScreenSpec, copy: CopySpec) throws -> NSImage {
    let canvas = NSImage(size: device.canvasSize)
    canvas.lockFocusFlipped(true)

    guard let context = NSGraphicsContext.current else {
        canvas.unlockFocus()
        throw RenderError.failedToCreatePNG
    }

    context.imageInterpolation = .high

    let bounds = CGRect(origin: .zero, size: device.canvasSize)
    drawBackground(in: bounds, palette: screen.palette, device: device, number: screen.number)
    let headerLayout = drawHeader(in: bounds, palette: screen.palette, copy: copy, device: device)
    drawDeviceImage(sourceImage, in: bounds, device: device, headerBottomY: headerLayout.bottomY)

    canvas.unlockFocus()
    return canvas
}

func drawBackground(in bounds: CGRect, palette: Palette, device: DeviceSpec, number: String) {
    let gradient = NSGradient(colors: [palette.backgroundTop, palette.backgroundBottom])!
    gradient.draw(in: bounds, angle: 90)

    let orbSize = min(bounds.width, bounds.height) * (device.kind == .phone ? 0.72 : 0.6)
    let orbRect = CGRect(x: -bounds.width * 0.12, y: -bounds.height * 0.06, width: orbSize, height: orbSize)
    palette.orb.withAlphaComponent(0.34).setFill()
    NSBezierPath(ovalIn: orbRect).fill()

    let panelRect = CGRect(
        x: bounds.width * 0.42,
        y: bounds.height * 0.08,
        width: bounds.width * 0.74,
        height: bounds.height * 0.36
    )
    palette.panel.setFill()
    NSBezierPath(roundedRect: panelRect, xRadius: bounds.width * 0.06, yRadius: bounds.width * 0.06).fill()

    let linePath = NSBezierPath()
    linePath.move(to: CGPoint(x: bounds.width * 0.08, y: bounds.height * 0.69))
    linePath.curve(
        to: CGPoint(x: bounds.width * 0.92, y: bounds.height * 0.57),
        controlPoint1: CGPoint(x: bounds.width * 0.26, y: bounds.height * 0.56),
        controlPoint2: CGPoint(x: bounds.width * 0.63, y: bounds.height * 0.48)
    )
    linePath.lineWidth = max(4, bounds.width * 0.0048)
    palette.line.withAlphaComponent(0.78).setStroke()
    linePath.stroke()

    let numberFontSize = device.kind == .phone ? bounds.width * 0.24 : bounds.width * 0.17
    let numberAttributes: [NSAttributedString.Key: Any] = [
        .font: titleFont(size: numberFontSize),
        .foregroundColor: palette.accent.withAlphaComponent(0.15)
    ]
    let numberRect = CGRect(
        x: bounds.width * 0.62,
        y: bounds.height * 0.05,
        width: bounds.width * 0.26,
        height: bounds.height * 0.18
    )
    NSAttributedString(string: number, attributes: numberAttributes).draw(in: numberRect)
}

func drawHeader(in bounds: CGRect, palette: Palette, copy: CopySpec, device: DeviceSpec) -> HeaderLayout {
    let horizontalMargin = device.kind == .phone ? bounds.width * 0.08 : bounds.width * 0.07
    let brandY = device.kind == .phone ? bounds.height * 0.06 : bounds.height * 0.055
    let eyebrowY = brandY + (device.kind == .phone ? 70 : 90)
    let titleY = eyebrowY + (device.kind == .phone ? 100 : 120)

    let brandAttributes: [NSAttributedString.Key: Any] = [
        .font: bodyFont(size: device.kind == .phone ? 28 : 34, weight: .medium),
        .foregroundColor: palette.body.withAlphaComponent(0.82),
        .kern: device.kind == .phone ? 3.8 : 4.4
    ]
    NSAttributedString(string: "WORKOUTPLAZA", attributes: brandAttributes).draw(
        at: CGPoint(x: horizontalMargin, y: brandY)
    )

    drawPill(
        text: copy.eyebrow.uppercased(),
        rect: CGRect(
            x: horizontalMargin,
            y: eyebrowY,
            width: device.kind == .phone ? bounds.width * 0.36 : bounds.width * 0.24,
            height: device.kind == .phone ? 58 : 66
        ),
        fill: palette.accent.withAlphaComponent(0.14),
        textColor: palette.title.withAlphaComponent(0.9),
        font: bodyFont(size: device.kind == .phone ? 22 : 26, weight: .semibold)
    )

    let titleParagraph = NSMutableParagraphStyle()
    titleParagraph.lineBreakMode = .byWordWrapping
    titleParagraph.lineSpacing = device.kind == .phone ? 0 : 2

    let subtitleParagraph = NSMutableParagraphStyle()
    subtitleParagraph.lineBreakMode = .byWordWrapping
    subtitleParagraph.lineSpacing = device.kind == .phone ? 5 : 7

    let titleWidth = device.kind == .phone ? bounds.width * 0.82 : bounds.width * 0.76
    let subtitleWidth = device.kind == .phone ? bounds.width * 0.78 : bounds.width * 0.62
    let titleFontSize = fittedTitleFontSize(
        text: copy.title,
        width: titleWidth,
        maxHeight: device.kind == .phone ? bounds.height * 0.19 : bounds.height * 0.17,
        initialSize: device.kind == .phone ? 104 : 122,
        minimumSize: device.kind == .phone ? 82 : 98,
        paragraphStyle: titleParagraph
    )
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: titleFont(size: titleFontSize),
        .foregroundColor: palette.title,
        .paragraphStyle: titleParagraph
    ]

    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: bodyFont(size: device.kind == .phone ? 34 : 44, weight: .medium),
        .foregroundColor: palette.body,
        .paragraphStyle: subtitleParagraph
    ]
    let titleString = NSAttributedString(string: copy.title, attributes: titleAttributes)
    let subtitleString = NSAttributedString(string: copy.subtitle, attributes: subtitleAttributes)

    let titleHeight = attributedHeight(titleString, width: titleWidth)
    let titleRect = CGRect(
        x: horizontalMargin,
        y: titleY,
        width: titleWidth,
        height: ceil(titleHeight)
    )
    let subtitleY = titleRect.maxY + (device.kind == .phone ? 36 : 44)
    let subtitleHeight = attributedHeight(subtitleString, width: subtitleWidth)
    let subtitleRect = CGRect(
        x: horizontalMargin,
        y: subtitleY,
        width: subtitleWidth,
        height: ceil(subtitleHeight)
    )

    titleString.draw(
        with: titleRect,
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )

    subtitleString.draw(
        with: subtitleRect,
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )

    return HeaderLayout(bottomY: subtitleRect.maxY)
}

func drawDeviceImage(_ sourceImage: NSImage, in bounds: CGRect, device: DeviceSpec, headerBottomY: CGFloat) {
    let sourceSize = pixelSize(for: sourceImage)
    let defaultTopInset = device.kind == .phone ? bounds.height * 0.31 : bounds.height * 0.315
    let topInset = max(defaultTopInset, headerBottomY + (device.kind == .phone ? 72 : 84))
    let bottomInset = device.kind == .phone ? bounds.height * 0.048 : bounds.height * 0.05
    let maxWidth = device.kind == .phone ? bounds.width * 0.76 : bounds.width * 0.72
    let maxHeight = bounds.height - topInset - bottomInset
    let scale = min(maxWidth / sourceSize.width, maxHeight / sourceSize.height)
    let drawSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
    let rect = CGRect(
        x: (bounds.width - drawSize.width) / 2,
        y: topInset + (maxHeight - drawSize.height) / 2,
        width: drawSize.width,
        height: drawSize.height
    )

    let shadow = NSShadow()
    shadow.shadowBlurRadius = device.kind == .phone ? 44 : 52
    shadow.shadowOffset = NSSize(width: 0, height: 22)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    sourceImage.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
}

func drawPill(text: String, rect: CGRect, fill: NSColor, textColor: NSColor, font: NSFont) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2).fill()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: textColor,
        .paragraphStyle: paragraph,
        .kern: 1.6
    ]

    NSAttributedString(string: text, attributes: attributes).draw(
        with: CGRect(x: rect.minX, y: rect.minY + rect.height * 0.18, width: rect.width, height: rect.height),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
}

func attributedHeight(_ attributedString: NSAttributedString, width: CGFloat) -> CGFloat {
    let rect = attributedString.boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
    return ceil(rect.height)
}

func fittedTitleFontSize(
    text: String,
    width: CGFloat,
    maxHeight: CGFloat,
    initialSize: CGFloat,
    minimumSize: CGFloat,
    paragraphStyle: NSParagraphStyle
) -> CGFloat {
    var currentSize = initialSize

    while currentSize >= minimumSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: titleFont(size: currentSize),
            .paragraphStyle: paragraphStyle
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        if attributedHeight(attributed, width: width) <= maxHeight {
            return currentSize
        }
        currentSize -= 2
    }

    return minimumSize
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw RenderError.failedToCreatePNG
    }

    try png.write(to: url)
}

func pixelSize(for image: NSImage) -> CGSize {
    if let representation = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first {
        return CGSize(width: representation.pixelsWide, height: representation.pixelsHigh)
    }
    return image.size
}

func registerFonts() {
    let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fontPaths = [
        "Fonts/Paperlogy/Paperlogy-8ExtraBold.ttf",
        "Fonts/Paperlogy/Paperlogy-6SemiBold.ttf",
        "Fonts/Paperlogy/Paperlogy-5Medium.ttf",
        "Fonts/GmarketSansTTF/GmarketSansTTFBold.ttf",
        "Fonts/GmarketSansTTF/GmarketSansTTFMedium.ttf"
    ]

    for path in fontPaths {
        let fontURL = repoRoot.appendingPathComponent(path)
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}

func titleFont(size: CGFloat) -> NSFont {
    NSFont(name: "Paperlogy-8ExtraBold", size: size)
        ?? NSFont(name: "GmarketSansTTFBold", size: size)
        ?? NSFont.systemFont(ofSize: size, weight: .bold)
}

func bodyFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
    if weight.rawValue >= NSFont.Weight.semibold.rawValue {
        return NSFont(name: "Paperlogy-6SemiBold", size: size)
            ?? NSFont(name: "GmarketSansTTFBold", size: size)
            ?? NSFont.systemFont(ofSize: size, weight: weight)
    }

    return NSFont(name: "Paperlogy-5Medium", size: size)
        ?? NSFont(name: "GmarketSansTTFMedium", size: size)
        ?? NSFont.systemFont(ofSize: size, weight: weight)
}

func color(_ hex: String, alpha: CGFloat = 1.0) -> NSColor {
    let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var value: UInt64 = 0
    Scanner(string: sanitized).scanHexInt64(&value)

    let red = CGFloat((value >> 16) & 0xFF) / 255
    let green = CGFloat((value >> 8) & 0xFF) / 255
    let blue = CGFloat(value & 0xFF) / 255
    return NSColor(red: red, green: green, blue: blue, alpha: alpha)
}

func argumentValue(flag: String) -> String? {
    guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
        return nil
    }
    return arguments[index + 1]
}
