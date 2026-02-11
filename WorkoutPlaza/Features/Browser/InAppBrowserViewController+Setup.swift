//
//  InAppBrowserViewController+Setup.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import WebKit
import SnapKit

// MARK: - Setup

extension InAppBrowserViewController {

    func buildWebConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.processPool = browserConfiguration.sharedProcessPool
        config.websiteDataStore = browserConfiguration.websiteDataStore
        config.allowsInlineMediaPlayback = browserConfiguration.allowsInlineMediaPlayback

        config.defaultWebpagePreferences.allowsContentJavaScript = browserConfiguration.allowsJavaScript
        config.preferences.javaScriptCanOpenWindowsAutomatically = browserConfiguration.javaScriptCanOpenWindowsAutomatically

        if let userAgent = browserConfiguration.customUserAgent, userAgent.isEmpty == false {
            config.applicationNameForUserAgent = userAgent
        }

        let userContentController = WKUserContentController()
        browserConfiguration.scriptMessageNames.forEach { name in
            userContentController.add(self, name: name)
        }
        config.userContentController = userContentController

        return config
    }

    func setupUI() {
        view.backgroundColor = .systemBackground
        configureNavigationBarItems()
        if browserConfiguration.showsAddressBar {
            setupTopBarUI()
        }
        if browserConfiguration.showsBottomToolbar {
            setupBottomToolbarUI()
        }
        setupWebViewUI()
        setupErrorViewUI()
        setupActions()
    }

    func setupTopBarUI() {
        topContainerView.backgroundColor = .systemBackground

        view.addSubview(topContainerView)
        topContainerView.addSubview(addressContainerView)
        topContainerView.addSubview(progressView)

        addressContainerView.addSubview(sslIconView)
        addressContainerView.addSubview(addressTextField)
        addressContainerView.addSubview(addressToggleButton)

        topContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }

        addressContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(40)
        }

        sslIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }

        addressToggleButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }

        addressTextField.snp.makeConstraints { make in
            make.leading.equalTo(sslIconView.snp.trailing).offset(8)
            make.trailing.equalTo(addressToggleButton.snp.leading).offset(-6)
            make.top.bottom.equalToSuperview()
        }

        progressView.snp.makeConstraints { make in
            make.top.equalTo(addressContainerView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(2)
        }
    }

    func setupBottomToolbarUI() {
        view.addSubview(bottomToolbarView)
        bottomToolbarView.addSubview(bottomToolbarBackgroundView)
        bottomToolbarView.addSubview(toolbarStackView)

        [backButton, forwardButton, reloadStopButton, shareButton, safariButton].forEach {
            toolbarStackView.addArrangedSubview($0)
        }

        bottomToolbarView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-52)
        }

        bottomToolbarBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        toolbarStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.equalToSuperview().offset(6)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-6)
        }
    }

    func setupWebViewUI() {
        view.addSubview(webView)
        if browserConfiguration.showsAddressBar {
            view.bringSubviewToFront(topContainerView)
        }
        if browserConfiguration.showsBottomToolbar {
            view.bringSubviewToFront(bottomToolbarView)
        }

        webView.snp.makeConstraints { make in
            if browserConfiguration.showsAddressBar {
                make.top.equalTo(topContainerView.snp.bottom)
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }
            make.leading.trailing.equalToSuperview()
            if browserConfiguration.showsBottomToolbar {
                make.bottom.equalTo(bottomToolbarView.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
        }

        if browserConfiguration.enablesPullToRefresh {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
            webView.scrollView.refreshControl = refreshControl
        }
    }

    func setupErrorViewUI() {
        view.addSubview(errorContainerView)
        errorContainerView.addSubview(errorTitleLabel)
        errorContainerView.addSubview(errorDescriptionLabel)
        errorContainerView.addSubview(retryButton)

        errorContainerView.snp.makeConstraints { make in
            if browserConfiguration.showsAddressBar {
                make.top.equalTo(topContainerView.snp.bottom)
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }
            make.leading.trailing.equalToSuperview()
            if browserConfiguration.showsBottomToolbar {
                make.bottom.equalTo(bottomToolbarView.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
        }

        errorTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-32)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        errorDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(errorTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        retryButton.snp.makeConstraints { make in
            make.top.equalTo(errorDescriptionLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
    }

    func setupActions() {
        if browserConfiguration.showsAddressBar {
            addressToggleButton.addTarget(self, action: #selector(addressToggleTapped), for: .touchUpInside)
            addressToggleButton.isHidden = browserConfiguration.enablesAddressEditing == false
            addressTextField.delegate = self
            addressTextField.isUserInteractionEnabled = browserConfiguration.enablesAddressEditing
            addressTextField.alpha = browserConfiguration.enablesAddressEditing ? 1 : 0.7
        }

        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
        reloadStopButton.addTarget(self, action: #selector(reloadStopButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        safariButton.addTarget(self, action: #selector(openInSafariTapped), for: .touchUpInside)
    }

    func setupAccessibility() {
        if browserConfiguration.showsAddressBar {
            sslIconView.accessibilityTraits = .image
            sslIconView.accessibilityLabel = WorkoutPlazaStrings.Browser.Ssl.secure

            addressTextField.accessibilityLabel = WorkoutPlazaStrings.Browser.Address.label
            addressTextField.accessibilityHint = WorkoutPlazaStrings.Browser.Address.hint

            addressToggleButton.accessibilityLabel = WorkoutPlazaStrings.Browser.Address.toggle
            addressToggleButton.accessibilityHint = WorkoutPlazaStrings.Browser.Address.Toggle.hint
        }

        backButton.accessibilityHint = WorkoutPlazaStrings.Browser.Action.Back.hint
        forwardButton.accessibilityHint = WorkoutPlazaStrings.Browser.Action.Forward.hint
        reloadStopButton.accessibilityHint = WorkoutPlazaStrings.Browser.Action.ReloadStop.hint
        shareButton.accessibilityHint = WorkoutPlazaStrings.Browser.Action.Share.hint
        safariButton.accessibilityHint = WorkoutPlazaStrings.Browser.Action.OpenSafari.hint
    }

    func bindViewModel() {
        viewModel.onStateDidChange = { [weak self] state in
            self?.apply(state: state)
        }
    }

    func setupObservers() {
        observers.append(webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.viewModel.updateProgress(webView.estimatedProgress)
        })
        observers.append(webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
            self?.viewModel.updateTitle(webView.title)
        })
        observers.append(webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
            self?.viewModel.updateURL(webView.url)
        })
        observers.append(webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
            self?.viewModel.updateNavigationAvailability(canGoBack: webView.canGoBack, canGoForward: webView.canGoForward)
        })
        observers.append(webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
            self?.viewModel.updateNavigationAvailability(canGoBack: webView.canGoBack, canGoForward: webView.canGoForward)
        })
        observers.append(webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
            self?.viewModel.updateLoading(webView.isLoading)
        })
    }

    func loadInitialRequest() {
        if browserConfiguration.syncCookiesWithSharedStorage {
            cookieManager.syncSharedStorageCookies(to: webView) { [weak self] in
                self?.load(url: self?.initialURL)
            }
            return
        }
        load(url: initialURL)
    }

    func load(url: URL?) {
        guard let url else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = 30
        webView.load(request)
    }

    func apply(state: InAppBrowserViewModel.State) {
        let navigationTitle = state.title.isEmpty
            ? (state.currentURL?.host ?? state.currentURL?.absoluteString ?? "")
            : state.title
        navigationItem.title = navigationTitle

        if browserConfiguration.showsAddressBar, addressTextField.isFirstResponder == false {
            addressTextField.text = viewModel.addressText(showsFullURL: isShowingFullURL)
        }

        if browserConfiguration.showsAddressBar {
            updateSSLIcon(for: state.currentURL)
        }
        updateProgressUI(progress: state.estimatedProgress, isLoading: state.isLoading)
        updateToolbarButtons(state: state)
    }

    func updateSSLIcon(for url: URL?) {
        let isSecure = url?.scheme?.lowercased() == "https"
        sslIconView.image = UIImage(systemName: isSecure ? "lock.fill" : "lock.open.fill")
        sslIconView.tintColor = isSecure ? .systemGreen : .systemOrange
        sslIconView.accessibilityLabel = isSecure ? WorkoutPlazaStrings.Browser.Ssl.secure : WorkoutPlazaStrings.Browser.Ssl.insecure
    }

    func updateProgressUI(progress: Double, isLoading: Bool) {
        progressView.setProgress(Float(progress), animated: true)

        if isLoading {
            if progressView.alpha == 0 {
                UIView.animate(withDuration: 0.2) { [weak self] in
                    self?.progressView.alpha = 1
                }
            }
            return
        }

        webView.scrollView.refreshControl?.endRefreshing()

        UIView.animate(withDuration: 0.25, delay: 0.2) { [weak self] in
            self?.progressView.alpha = 0
        } completion: { [weak self] _ in
            self?.progressView.progress = 0
        }
    }

    func updateToolbarButtons(state: InAppBrowserViewModel.State) {
        backButton.isEnabled = state.canGoBack
        forwardButton.isEnabled = state.canGoForward

        let reloadSymbol = state.isLoading ? "xmark" : "arrow.clockwise"
        let reloadLabel = state.isLoading ? WorkoutPlazaStrings.Browser.Action.stop : WorkoutPlazaStrings.Browser.Action.reload
        reloadStopButton.setImage(UIImage(systemName: reloadSymbol), for: .normal)
        reloadStopButton.accessibilityLabel = reloadLabel
    }

    func makeToolbarButton(systemName: String, label: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = label
        return button
    }

    func configureNavigationBarItems() {
        navigationItem.largeTitleDisplayMode = .never

        let shouldShowCloseButton = (navigationController?.presentingViewController != nil)
            && (navigationController?.viewControllers.first == self)

        if shouldShowCloseButton {
            let closeItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeButtonTapped)
            )
            closeItem.accessibilityLabel = WorkoutPlazaStrings.Browser.close
            closeItem.accessibilityHint = WorkoutPlazaStrings.Browser.Close.hint
            navigationItem.leftBarButtonItem = closeItem
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
}
