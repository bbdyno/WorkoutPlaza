//
//  LicensesViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit

class LicensesViewController: UIViewController {

    private static let placeholderCellID = "licensePlaceholderCell"
    private static let libraryCellID = "licenseLibraryCell"

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 88
        return tv
    }()

    private let refreshControl = UIRefreshControl()

    private var libraries: [ThirdPartyLibrary] = []
    private var isLoading = false
    private var loadErrorMessage: String?
    private var loadTask: Task<Void, Never>?

    deinit {
        loadTask?.cancel()
    }

    @objc
    private func refreshLibraries() {
        loadLibraries(forceRefresh: true)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.placeholderCellID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshLibraries), for: .valueChanged)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func loadLibraries(forceRefresh: Bool) {
        loadTask?.cancel()

        isLoading = true
        if forceRefresh == false {
            loadErrorMessage = nil
        }
        tableView.reloadData()

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await OpenSourceLibraryService.shared.fetchLibraries(forceRefresh: forceRefresh)
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    self.libraries = result
                    self.loadErrorMessage = nil
                    self.isLoading = false
                    self.refreshControl.endRefreshing()
                    self.tableView.reloadData()
                }
            } catch {
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    self.isLoading = false
                    self.libraries = []
                    self.loadErrorMessage = error.localizedDescription
                    self.refreshControl.endRefreshing()
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func placeholderTitleText() -> String {
        if isLoading {
            return WorkoutPlazaStrings.More.Open.Source.loading
        }
        if loadErrorMessage != nil {
            return WorkoutPlazaStrings.More.Open.Source.Load.failed
        }
        return WorkoutPlazaStrings.More.Open.Source.empty
    }

    private func placeholderDetailText() -> String? {
        guard isLoading == false else { return nil }
        if let loadErrorMessage {
            return "\(loadErrorMessage)\n\(WorkoutPlazaStrings.More.Open.Source.Retry.hint)"
        }
        return nil
    }

    private func makePlaceholderCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.placeholderCellID, for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = placeholderTitleText()
        config.secondaryText = placeholderDetailText()
        config.textProperties.color = .secondaryLabel
        config.secondaryTextProperties.color = .tertiaryLabel
        config.secondaryTextProperties.numberOfLines = 0
        config.textProperties.alignment = .center
        config.secondaryTextProperties.alignment = .center
        cell.contentConfiguration = config
        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.backgroundColor = .secondarySystemGroupedBackground
        return cell
    }

    private func makeLibraryCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.libraryCellID)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: Self.libraryCellID)

        let library = libraries[indexPath.row]
        cell.textLabel?.text = library.displayName
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.detailTextLabel?.text = "\(library.versionLabel)\n\(library.repositoryDisplayURL)"
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.selectionStyle = library.repositoryURL == nil ? .none : .default
        cell.accessoryType = library.repositoryURL == nil ? .none : .disclosureIndicator
        return cell
    }

    private func openRepository(at indexPath: IndexPath) {
        guard libraries.indices.contains(indexPath.row) else { return }
        guard let url = libraries[indexPath.row].repositoryURL else { return }
        UIApplication.shared.open(url)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = WorkoutPlazaStrings.More.Open.Source.licenses
        setupUI()
        loadLibraries(forceRefresh: false)
    }
}

extension LicensesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return libraries.isEmpty ? 1 : libraries.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return WorkoutPlazaStrings.More.Open.Source.Third.party
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if libraries.isEmpty {
            return makePlaceholderCell(for: indexPath)
        }
        return makeLibraryCell(for: indexPath)
    }
}

extension LicensesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard libraries.isEmpty == false else { return }
        openRepository(at: indexPath)
    }
}

private struct ThirdPartyLibrary: Sendable {
    let identity: String
    let versionLabel: String
    let repositoryDisplayURL: String
    let repositoryURL: URL?

    var displayName: String {
        identity
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

private actor OpenSourceLibraryService {

    static let shared = OpenSourceLibraryService()

    private enum ServiceError: LocalizedError {
        case invalidHTTPResponse
        case badStatusCode(Int)
        case emptyPins

        var errorDescription: String? {
            switch self {
            case .invalidHTTPResponse:
                return WorkoutPlazaStrings.More.Open.Source.Error.Invalid.response
            case .badStatusCode(let statusCode):
                return WorkoutPlazaStrings.More.Open.Source.Error.server(statusCode)
            case .emptyPins:
                return WorkoutPlazaStrings.More.Open.Source.empty
            }
        }
    }

    private struct PackageResolvedDocument: Decodable, Sendable {
        let pins: [PackagePin]
    }

    private struct PackagePin: Decodable, Sendable {
        let identity: String
        let location: String
        let state: PackageState
    }

    private struct PackageState: Decodable, Sendable {
        let version: String?
        let revision: String?
        let branch: String?
    }

    private let decoder = JSONDecoder()
    private var cachedLibraries: [ThirdPartyLibrary]?

    func fetchLibraries(forceRefresh: Bool) async throws -> [ThirdPartyLibrary] {
        if forceRefresh == false, let cachedLibraries {
            return cachedLibraries
        }

        var lastError: Error?
        for endpoint in Self.remoteEndpoints {
            do {
                let request = URLRequest(
                    url: endpoint,
                    cachePolicy: .reloadIgnoringLocalCacheData,
                    timeoutInterval: 12
                )
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ServiceError.invalidHTTPResponse
                }
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw ServiceError.badStatusCode(httpResponse.statusCode)
                }

                let document = try decoder.decode(PackageResolvedDocument.self, from: data)
                guard document.pins.isEmpty == false else {
                    throw ServiceError.emptyPins
                }

                let mappedLibraries = document.pins
                    .map(Self.map(pin:))
                    .sorted { $0.identity.localizedCaseInsensitiveCompare($1.identity) == .orderedAscending }

                cachedLibraries = mappedLibraries
                return mappedLibraries
            } catch {
                lastError = error
            }
        }

        throw lastError ?? ServiceError.invalidHTTPResponse
    }

    private static var remoteEndpoints: [URL] {
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "OPEN_SOURCE_RESOLVED_URL") as? String
        let configuredEndpoint = configuredURL.flatMap(URL.init(string:))
        let fallbackMain = URL(string: "https://raw.githubusercontent.com/bbdyno/WorkoutPlaza/main/Package.resolved")
        let fallbackMaster = URL(string: "https://raw.githubusercontent.com/bbdyno/WorkoutPlaza/master/Package.resolved")

        return [configuredEndpoint, fallbackMain, fallbackMaster]
            .compactMap { $0 }
    }

    private static func map(pin: PackagePin) -> ThirdPartyLibrary {
        let repositoryDisplayURL = normalizeRepositoryDisplayURL(pin.location)
        let repositoryURL = URL(string: repositoryDisplayURL)

        let versionLabel: String
        if let version = pin.state.version, version.isEmpty == false {
            versionLabel = "v\(version)"
        } else if let branch = pin.state.branch, branch.isEmpty == false {
            versionLabel = "branch: \(branch)"
        } else if let revision = pin.state.revision, revision.isEmpty == false {
            versionLabel = "rev: \(revision.prefix(7))"
        } else {
            versionLabel = WorkoutPlazaStrings.More.Open.Source.Version.unknown
        }

        return ThirdPartyLibrary(
            identity: pin.identity,
            versionLabel: versionLabel,
            repositoryDisplayURL: repositoryDisplayURL,
            repositoryURL: repositoryURL
        )
    }

    private static func normalizeRepositoryDisplayURL(_ location: String) -> String {
        guard location.hasSuffix(".git") else { return location }
        return String(location.dropLast(4))
    }
}
