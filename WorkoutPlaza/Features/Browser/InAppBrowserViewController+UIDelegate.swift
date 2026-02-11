//
//  InAppBrowserViewController+UIDelegate.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import WebKit

// MARK: - WKUIDelegate

extension InAppBrowserViewController: WKUIDelegate {

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // target="_blank" 링크를 새 인앱 브라우저가 아닌 현재 탭에서 열기
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: webView.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(title: webView.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default) { _ in
            completionHandler(true)
        })
        present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alert = UIAlertController(title: webView.title, message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel) { _ in
            completionHandler(nil)
        })
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        present(alert, animated: true)
    }

    @available(iOS 18.4, *)
    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping ([URL]?) -> Void
    ) {
        openPanelCompletionHandler = completionHandler
        openPanelAllowsMultipleSelection = parameters.allowsMultipleSelection

        let sheet = UIAlertController(title: WorkoutPlazaStrings.Browser.Upload.Source.title, message: nil, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Browser.Upload.Source.photos, style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })

        if UIImagePickerController.isSourceTypeAvailable(.camera), parameters.allowsMultipleSelection == false {
            sheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Browser.Upload.Source.camera, style: .default) { [weak self] _ in
                self?.presentCameraPicker()
            })
        }

        sheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Browser.Upload.Source.files, style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        })

        sheet.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel) { [weak self] _ in
            self?.finishOpenPanel(with: nil)
        })

        if let popover = sheet.popoverPresentationController {
            if browserConfiguration.showsAddressBar {
                popover.sourceView = addressContainerView
                popover.sourceRect = addressContainerView.bounds
            } else {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            }
        }

        present(sheet, animated: true)
    }
}

// MARK: - WKScriptMessageHandler

extension InAppBrowserViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        WPLog.debug("JavaScript message:", message.name)
        NotificationCenter.default.post(
            name: .didReceiveInAppBrowserScriptMessage,
            object: nil,
            userInfo: [
                "name": message.name,
                "body": message.body
            ]
        )
    }
}

extension Notification.Name {
    static let didReceiveInAppBrowserScriptMessage = Notification.Name("didReceiveInAppBrowserScriptMessage")
}
