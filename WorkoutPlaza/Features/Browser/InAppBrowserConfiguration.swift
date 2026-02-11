//
//  InAppBrowserConfiguration.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import Foundation
import WebKit

/// 인앱 브라우저 동작을 제어하는 설정 객체
struct InAppBrowserConfiguration {

    enum PresentationStyle: String {
        case fullScreen
        case pageSheet
    }

    // MARK: - WebView Core

    var allowsJavaScript: Bool = true
    var javaScriptCanOpenWindowsAutomatically: Bool = true
    var allowsInlineMediaPlayback: Bool = true
    var customUserAgent: String?

    // MARK: - Session & Cookie

    var usesPersistentWebsiteDataStore: Bool = true
    var syncCookiesWithSharedStorage: Bool = true
    var sharedProcessPool: WKProcessPool = WebViewCookieManager.sharedProcessPool

    // MARK: - Navigation & UI

    var allowsBackForwardNavigationGestures: Bool = true
    var enablesPullToRefresh: Bool = true
    var enablesLinkPreview: Bool = true
    var enablesAddressEditing: Bool = true
    var showsAddressBar: Bool = true
    var showsBottomToolbar: Bool = true
    var presentationStyle: PresentationStyle = .fullScreen

    // MARK: - Security

    /// nil이면 모든 도메인을 허용
    var allowedDomains: Set<String>? = nil
    var allowsInsecureHTTP: Bool = true
    var allowsInvalidSSLCertificates: Bool = false

    // MARK: - Deep Link

    /// 유니버설 링크를 외부 앱으로 우선 전환할 호스트 목록
    var universalLinkHosts: Set<String> = []

    // MARK: - JavaScript Bridge

    var scriptMessageNames: [String] = ["browser"]

    // MARK: - Defaults

    static let `default` = InAppBrowserConfiguration()

    // MARK: - Helpers

    var websiteDataStore: WKWebsiteDataStore {
        usesPersistentWebsiteDataStore ? .default() : .nonPersistent()
    }
}
