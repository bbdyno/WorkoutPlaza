//
//  InAppBrowserViewController+Download.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import Foundation
import WebKit

// MARK: - WKDownloadDelegate

@available(iOS 14.5, *)
extension InAppBrowserViewController: WKDownloadDelegate {

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Downloads", isDirectory: true)

        guard let destinationDirectory = directory else {
            completionHandler(nil)
            return
        }

        do {
            try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
            let destination = destinationDirectory.appendingPathComponent(suggestedFilename)
            downloadDestinations[ObjectIdentifier(download)] = destination
            completionHandler(destination)
        } catch {
            WPLog.error("Failed to create download directory:", error.localizedDescription)
            completionHandler(nil)
        }
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        WPLog.error("WKDownload failed:", error.localizedDescription)
    }

    func downloadDidFinish(_ download: WKDownload) {
        if let destination = downloadDestinations.removeValue(forKey: ObjectIdentifier(download)) {
            showDownloadCompletedAlert(fileURL: destination)
        }
    }
}
