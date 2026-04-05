//
//  GPXParser.swift
//  WorkoutPlaza
//

import Foundation
import CoreLocation

// MARK: - GPX Parse Error

enum GPXParseError: LocalizedError {
    case invalidFile
    case noRouteData
    case insufficientData

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return NSLocalizedString("gpx.error.invalid", comment: "Invalid GPX file")
        case .noRouteData:
            return NSLocalizedString("gpx.error.noRoute", comment: "No route data in GPX file")
        case .insufficientData:
            return NSLocalizedString("gpx.error.insufficient", comment: "Insufficient data in GPX file")
        }
    }
}

// MARK: - GPX Parser

final class GPXParser: NSObject {

    // MARK: - State

    private var routePoints: [RoutePoint] = []
    private var heartRates: [Double] = []
    private var currentElement = ""
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentEle: Double?
    private var currentTime: Date?
    private var currentHR: Double?
    private var inTrackPoint = false
    private var isCollectingHR = false
    private var charBuffer = ""

    // MARK: - Date Formatters

    private let isoFull: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private let isoBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Public

    func parse(data: Data) throws -> ExportableWorkoutData {
        routePoints = []
        heartRates = []

        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()

        if let _ = xmlParser.parserError {
            throw GPXParseError.invalidFile
        }

        guard !routePoints.isEmpty else {
            throw GPXParseError.noRouteData
        }

        guard routePoints.count >= 2,
              let startDate = routePoints.first?.timestamp,
              let endDate = routePoints.last?.timestamp else {
            throw GPXParseError.insufficientData
        }

        let duration = endDate.timeIntervalSince(startDate)
        let distance = totalDistance(from: routePoints)
        let pace = distance > 0 ? (duration / 60.0) / (distance / 1000.0) : 0
        let avgSpeed = duration > 0 ? (distance / 1000.0) / (duration / 3600.0) : 0
        let avgHR: Double? = heartRates.isEmpty ? nil : heartRates.reduce(0, +) / Double(heartRates.count)

        return ExportableWorkoutData(
            type: .running,
            distance: distance,
            duration: max(duration, 0),
            startDate: startDate,
            endDate: endDate,
            pace: pace,
            avgSpeed: avgSpeed,
            calories: 0,
            route: routePoints,
            avgHeartRate: avgHR
        )
    }

    // MARK: - Private Helpers

    private func totalDistance(from points: [RoutePoint]) -> Double {
        var total = 0.0
        for i in 1..<points.count {
            let a = CLLocation(latitude: points[i - 1].lat, longitude: points[i - 1].lon)
            let b = CLLocation(latitude: points[i].lat, longitude: points[i].lon)
            total += a.distance(from: b)
        }
        return total
    }

    private func parseDate(_ string: String) -> Date? {
        isoFull.date(from: string) ?? isoBasic.date(from: string)
    }
}

// MARK: - XMLParserDelegate

extension GPXParser: XMLParserDelegate {

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        currentElement = elementName
        charBuffer = ""

        if elementName == "trkpt" || elementName == "rtept" {
            inTrackPoint = true
            currentLat = Double(attributes["lat"] ?? "")
            currentLon = Double(attributes["lon"] ?? "")
            currentEle = nil
            currentTime = nil
            currentHR = nil
        }

        // Heart-rate extensions from Garmin (various namespace prefixes)
        let hrElements: Set<String> = ["hr", "ns3:hr", "gpxtpx:hr", "cadence"]
        if hrElements.contains(elementName) {
            isCollectingHR = elementName != "cadence"
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        charBuffer += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        let value = charBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        charBuffer = ""

        guard inTrackPoint else {
            return
        }

        switch elementName {
        case "ele":
            currentEle = Double(value)
        case "time":
            currentTime = parseDate(value)
        case "hr", "ns3:hr", "gpxtpx:hr":
            currentHR = Double(value)
            isCollectingHR = false
        case "trkpt", "rtept":
            if let lat = currentLat, let lon = currentLon {
                routePoints.append(RoutePoint(lat: lat, lon: lon, alt: currentEle, timestamp: currentTime))
                if let hr = currentHR {
                    heartRates.append(hr)
                }
            }
            inTrackPoint = false
            currentLat = nil
            currentLon = nil
            currentEle = nil
            currentTime = nil
            currentHR = nil
        default:
            break
        }
    }
}
