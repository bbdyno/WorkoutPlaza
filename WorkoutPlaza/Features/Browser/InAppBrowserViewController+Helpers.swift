//
//  InAppBrowserViewController+Helpers.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import WebKit

// MARK: - Helpers

extension InAppBrowserViewController {

    func showSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }

    func showBlockedDomainAlert(host: String) {
        let message = WorkoutPlazaStrings.Browser.Blocked.Domain.message(host)
        showSimpleAlert(title: WorkoutPlazaStrings.Browser.Blocked.Domain.title, message: message)
    }

    func showErrorView() {
        errorDescriptionLabel.text = WorkoutPlazaStrings.Browser.Error.description
        errorContainerView.isHidden = false
    }

    func isAllowedHost(for url: URL) -> Bool {
        guard let allowedDomains = browserConfiguration.allowedDomains else { return true }
        guard let host = url.host?.lowercased(), host.isEmpty == false else { return false }

        return allowedDomains.contains { domain in
            let lowered = domain.lowercased()
            return host == lowered || host.hasSuffix(".\(lowered)")
        }
    }

    func canOpenInWebView(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        if ["http", "https", "about", "file", "data", "blob"].contains(scheme) == false {
            return false
        }
        if scheme == "http" && browserConfiguration.allowsInsecureHTTP == false {
            return false
        }
        return true
    }

    func handleExternalLink(_ url: URL) {
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:])
    }

    func universalLinkShouldOpenExternally(_ url: URL, navigationType: WKNavigationType) -> Bool {
        guard navigationType == .linkActivated else { return false }
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return false }
        guard let host = url.host?.lowercased(), host.isEmpty == false else { return false }
        guard browserConfiguration.universalLinkHosts.isEmpty == false else { return false }

        return browserConfiguration.universalLinkHosts.contains { allowedHost in
            let lowered = allowedHost.lowercased()
            return host == lowered || host.hasSuffix(".\(lowered)")
        }
    }

    func showDownloadCompletedAlert(fileURL: URL) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Browser.Download.Completed.title,
            message: WorkoutPlazaStrings.Browser.Download.Completed.message(fileURL.lastPathComponent),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Browser.Download.share, style: .default) { [weak self] _ in
            guard let self else { return }
            let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let popover = activity.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 1, height: 1)
            }
            self.present(activity, animated: true)
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .cancel))
        present(alert, animated: true)
    }

    func finishOpenPanel(with urls: [URL]?) {
        openPanelCompletionHandler?(urls)
        openPanelCompletionHandler = nil
        openPanelAllowsMultipleSelection = false
    }

    func createTemporaryFile(data: Data, preferredExtension: String) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(preferredExtension)
        try data.write(to: tempURL)
        temporaryUploadFiles.append(tempURL)
        return tempURL
    }
}
