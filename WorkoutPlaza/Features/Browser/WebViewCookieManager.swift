//
//  WebViewCookieManager.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import Foundation
import WebKit

final class WebViewCookieManager {
    static let shared = WebViewCookieManager()
    static let sharedProcessPool = WKProcessPool()

    private init() {}

    // MARK: - Sync: Shared -> WebView

    /// HTTPCookieStorage의 쿠키를 WKHTTPCookieStore로 복사한다.
    func syncSharedStorageCookies(to webView: WKWebView, completion: (() -> Void)? = nil) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let sharedCookies = HTTPCookieStorage.shared.cookies ?? []

        guard sharedCookies.isEmpty == false else {
            completion?()
            return
        }

        let group = DispatchGroup()
        for cookie in sharedCookies {
            group.enter()
            cookieStore.setCookie(cookie) {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion?()
        }
    }

    // MARK: - Sync: WebView -> Shared

    /// WKHTTPCookieStore의 쿠키를 HTTPCookieStorage로 동기화한다.
    func syncWebViewCookiesToSharedStorage(from webView: WKWebView, completion: (() -> Void)? = nil) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            let sharedStorage = HTTPCookieStorage.shared
            cookies.forEach { sharedStorage.setCookie($0) }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    // MARK: - Cache

    /// 메모리 경고 대응: 브라우저 캐시를 정리한다.
    func clearCaches(websiteDataStore: WKWebsiteDataStore = .default(), completion: (() -> Void)? = nil) {
        URLCache.shared.removeAllCachedResponses()

        let types: Set<String> = [
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeDiskCache
        ]

        websiteDataStore.fetchDataRecords(ofTypes: types) { records in
            websiteDataStore.removeData(ofTypes: types, for: records) {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
}
