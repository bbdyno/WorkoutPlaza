//
//  InAppBrowserViewController+Navigation.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import WebKit

// MARK: - WKNavigationDelegate

extension InAppBrowserViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        errorContainerView.isHidden = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        cookieManager.syncWebViewCookiesToSharedStorage(from: webView, completion: nil)
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        showErrorView()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        showErrorView()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // 웹 콘텐츠 프로세스가 종료된 경우 자동 복구
        WPLog.warning("WKWebView process terminated. Attempting reload.")
        webView.reload()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if AppSchemeManager.shared.canHandle(url) {
            _ = AppSchemeManager.shared.handle(url, rootViewController: view.window?.rootViewController)
            decisionHandler(.cancel)
            return
        }

        if universalLinkShouldOpenExternally(url, navigationType: navigationAction.navigationType) {
            let request = navigationAction.request
            UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { [weak self] success in
                guard let self else { return }
                if success == false {
                    self.webView.load(request)
                }
            }
            decisionHandler(.cancel)
            return
        }

        if canOpenInWebView(url) == false {
            handleExternalLink(url)
            decisionHandler(.cancel)
            return
        }

        if isAllowedHost(for: url) == false {
            showBlockedDomainAlert(host: url.host ?? url.absoluteString)
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }

        if #available(iOS 14.5, *), navigationAction.shouldPerformDownload {
            decisionHandler(.download)
            return
        }

        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse,
           let csp = httpResponse.value(forHTTPHeaderField: "Content-Security-Policy"),
           csp.isEmpty == false {
            // CSP 정책 자체는 WebKit이 준수하므로 여기서는 존재 여부만 로깅
            WPLog.debug("CSP header detected:", csp.prefix(120))
        }

        if #available(iOS 14.5, *), navigationResponse.canShowMIMEType == false {
            decisionHandler(.download)
            return
        }

        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // SSL 인증서는 기본 시스템 검증을 우선 사용한다.
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if browserConfiguration.allowsInvalidSSLCertificates,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
            return
        }

        completionHandler(.performDefaultHandling, nil)
    }

    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
}
