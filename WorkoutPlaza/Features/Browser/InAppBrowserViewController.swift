//
//  InAppBrowserViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import WebKit

final class InAppBrowserViewController: UIViewController {

    // MARK: - Public

    let initialURL: URL
    let browserConfiguration: InAppBrowserConfiguration

    // MARK: - Dependencies

    let viewModel: InAppBrowserViewModel
    let cookieManager = WebViewCookieManager.shared

    // MARK: - WebView

    lazy var webView: WKWebView = {
        let webConfiguration = buildWebConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = browserConfiguration.allowsBackForwardNavigationGestures
        webView.allowsLinkPreview = browserConfiguration.enablesLinkPreview
        webView.backgroundColor = .systemBackground
        webView.isOpaque = false
        return webView
    }()

    var observers: [NSKeyValueObservation] = []
    var isShowingFullURL = false
    var previousNavigationBarHiddenState: Bool?

    // MARK: - Download / Upload State

    var downloadDestinations: [ObjectIdentifier: URL] = [:]
    var openPanelCompletionHandler: (([URL]?) -> Void)?
    var openPanelAllowsMultipleSelection = false
    var temporaryUploadFiles: [URL] = []

    // MARK: - UI: Top

    let topContainerView = UIView()

    let sslIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock.fill"))
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let addressContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
        return view
    }()

    let addressTextField: UITextField = {
        let field = UITextField()
        field.font = .preferredFont(forTextStyle: .subheadline)
        field.adjustsFontForContentSizeCategory = true
        field.textColor = .label
        field.borderStyle = .none
        field.clearButtonMode = .whileEditing
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.keyboardType = .URL
        field.returnKeyType = .go
        field.placeholder = WorkoutPlazaStrings.Browser.Address.placeholder
        return field
    }()

    let addressToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()

    let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = ColorSystem.primaryBlue
        progressView.trackTintColor = .clear
        progressView.alpha = 0
        return progressView
    }()

    // MARK: - UI: Bottom Toolbar

    let bottomToolbarView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    let bottomToolbarBackgroundView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemChromeMaterial)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.clipsToBounds = true
        return effectView
    }()

    let toolbarStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()

    lazy var backButton = makeToolbarButton(systemName: "chevron.backward", label: WorkoutPlazaStrings.Browser.Action.back)
    lazy var forwardButton = makeToolbarButton(systemName: "chevron.forward", label: WorkoutPlazaStrings.Browser.Action.forward)
    lazy var reloadStopButton = makeToolbarButton(systemName: "arrow.clockwise", label: WorkoutPlazaStrings.Browser.Action.reload)
    lazy var shareButton = makeToolbarButton(systemName: "square.and.arrow.up", label: WorkoutPlazaStrings.Browser.Action.share)
    lazy var safariButton = makeToolbarButton(systemName: "safari", label: WorkoutPlazaStrings.Browser.Action.openSafari)

    // MARK: - UI: Error

    let errorContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.isHidden = true
        return view
    }()

    let errorTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.textAlignment = .center
        label.text = WorkoutPlazaStrings.Browser.Error.title
        return label
    }()

    let errorDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = WorkoutPlazaStrings.Browser.Error.description
        return label
    }()

    lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(WorkoutPlazaStrings.Browser.Action.reload, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = ColorSystem.primaryBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(url: URL, configuration: InAppBrowserConfiguration = .default) {
        self.initialURL = url
        self.browserConfiguration = configuration
        self.viewModel = InAppBrowserViewModel(initialURL: url)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        observers.forEach { $0.invalidate() }
        browserConfiguration.scriptMessageNames.forEach {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: $0)
        }
        temporaryUploadFiles.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAccessibility()
        bindViewModel()
        setupObservers()
        loadInitialRequest()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if previousNavigationBarHiddenState == nil {
            previousNavigationBarHiddenState = navigationController?.isNavigationBarHidden
        }
        navigationController?.setNavigationBarHidden(false, animated: animated)
        configureNavigationBarItems()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let shouldRestoreNavigationBar = isMovingFromParent || isBeingDismissed || (navigationController?.isBeingDismissed ?? false)
        if shouldRestoreNavigationBar, let previousState = previousNavigationBarHiddenState {
            navigationController?.setNavigationBarHidden(previousState, animated: animated)
            previousNavigationBarHiddenState = nil
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cookieManager.syncWebViewCookiesToSharedStorage(from: webView, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        cookieManager.clearCaches(websiteDataStore: webView.configuration.websiteDataStore)
    }
}
