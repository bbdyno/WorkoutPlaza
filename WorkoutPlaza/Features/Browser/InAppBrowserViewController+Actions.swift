//
//  InAppBrowserViewController+Actions.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import WebKit

// MARK: - Actions

extension InAppBrowserViewController {

    @objc func closeButtonTapped() {
        if presentingViewController != nil {
            dismiss(animated: true)
            return
        }
        navigationController?.popViewController(animated: true)
    }

    @objc func retryButtonTapped() {
        errorContainerView.isHidden = true
        webView.reload()
    }

    @objc func addressToggleTapped() {
        isShowingFullURL.toggle()
        if addressTextField.isFirstResponder == false {
            addressTextField.text = viewModel.addressText(showsFullURL: isShowingFullURL)
        }
    }

    @objc func backButtonTapped() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @objc func forwardButtonTapped() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    @objc func reloadStopButtonTapped() {
        if webView.isLoading {
            webView.stopLoading()
        } else {
            webView.reload()
        }
    }

    @objc func shareButtonTapped() {
        guard let url = webView.url else { return }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        present(activityViewController, animated: true)
    }

    @objc func openInSafariTapped() {
        guard let url = webView.url else { return }
        UIApplication.shared.open(url, options: [:])
    }

    @objc func handlePullToRefresh() {
        webView.reload()
    }
}
