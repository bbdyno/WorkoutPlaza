//
//  RunningListViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit
import UniformTypeIdentifiers

class RunningListViewController: UIViewController {

    // MARK: - Data Sources
    private var healthKitWorkouts: [WorkoutData] = []
    private var externalWorkouts: [ExternalWorkout] = []

    // Unified list
    private var allWorkouts: [UnifiedWorkoutItem] = []
    private var filteredWorkouts: [UnifiedWorkoutItem] = []
    private var currentFilter: WorkoutType? = nil // nil means "All"
    private var sourceFilter: UnifiedWorkoutSource? = nil // nil means "All Sources"
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(WorkoutCell.self, forCellReuseIdentifier: "WorkoutCell")
        table.rowHeight = 116  // 100 + 16 padding
        table.separatorStyle = .none
        return table
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = WorkoutPlazaStrings.Running.empty
        label.textColor = ColorSystem.subText
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: [WorkoutPlazaStrings.Running.Filter.all, "HealthKit", WorkoutPlazaStrings.Running.Filter.external])
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = ColorSystem.cardBackground
        sc.selectedSegmentTintColor = ColorSystem.primaryGreen
        sc.layer.cornerRadius = 10
        sc.layer.masksToBounds = true

        // Modern styling
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: ColorSystem.subText,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .bold)
        ]
        sc.setTitleTextAttributes(normalAttributes, for: .normal)
        sc.setTitleTextAttributes(selectedAttributes, for: .selected)

        return sc
    }()

    private let importFloatingButton: UIButton = {
        let button = UIButton(type: .system)

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = ColorSystem.primaryGreen
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        config.image = UIImage(systemName: "square.and.arrow.down", withConfiguration: imageConfig)
        config.imagePadding = 8
        config.title = WorkoutPlazaStrings.Import.external

        button.configuration = config

        // Shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 8

        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestHealthKitAuthorization()
        setupNotificationObservers()
        loadExternalWorkouts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure navigation bar is visible (HomeDashboard hides it)
        navigationController?.setNavigationBarHidden(false, animated: animated)

        // Refresh data when returning to this screen
        refreshData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Data Refresh

    private func refreshData() {
        loadWorkouts()
        loadExternalWorkouts()
        mergeAndSortWorkouts()
    }

    @objc private func handleAppDidBecomeActive() {
        refreshData()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReceivedWorkoutFile(_:)),
            name: .didReceiveSharedWorkout,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalWorkoutsChanged),
            name: .externalWorkoutsDidChange,
            object: nil
        )

        // Refresh data when app becomes active (returns from background)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func handleExternalWorkoutsChanged() {
        loadExternalWorkouts()
        mergeAndSortWorkouts()
    }

    @objc private func handleReceivedWorkoutFile(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }

        do {
            let shareableWorkout = try ShareManager.shared.importWorkout(from: url)

            // Check if current top view controller is RunningDetailViewController
            if let topVC = navigationController?.topViewController, topVC is RunningDetailViewController {
                // Forward to RunningDetailViewController
                NotificationCenter.default.post(
                    name: .didReceiveSharedWorkoutInDetail,
                    object: nil,
                    userInfo: ["workout": shareableWorkout]
                )
            } else {
                // On list screen - go directly to import as my record
                openImportWorkoutViewController(with: shareableWorkout, mode: .createNew)
            }
        } catch {
            showImportError(error)
        }
    }

    private func openImportWorkoutViewController(with workout: ShareableWorkout, mode: ImportMode, attachTo: WorkoutData? = nil) {
        let importVC = ImportWorkoutViewController()
        importVC.shareableWorkout = workout
        importVC.importMode = mode
        importVC.attachToWorkout = attachTo
        importVC.delegate = self

        let navController = UINavigationController(rootViewController: importVC)
        present(navController, animated: true)
    }

    private func showWorkoutSelectionForAttachment(workout: ShareableWorkout) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Running.Select.record,
            message: WorkoutPlazaStrings.Running.Select.Record.message,
            preferredStyle: .actionSheet
        )

        // Show recent HealthKit workouts only (can only attach to your own workouts)
        let healthKitItems = allWorkouts.filter { $0.source == .healthKit }

        for unifiedWorkout in healthKitItems.prefix(5) {
            guard let healthKitWorkout = unifiedWorkout.healthKitWorkout else { continue }

            let dateFormatter = DateFormatter()
            dateFormatter.setLocalizedDateFormatFromTemplate("MMddHHmm")
            let dateString = dateFormatter.string(from: unifiedWorkout.startDate)
            let title = "\(unifiedWorkout.workoutType) - \(dateString)"

            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.openImportWorkoutViewController(with: workout, mode: .attachToExisting, attachTo: healthKitWorkout)
            })
        }

        if healthKitItems.isEmpty {
            alert.message = WorkoutPlazaStrings.Running.No.healthkit
        }

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        present(alert, animated: true)
    }

    private func showImportError(_ error: Error) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Alert.Import.failed,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func setupUI() {
        title = WorkoutPlazaStrings.Running.Record.title
        view.backgroundColor = ColorSystem.background
        navigationItem.largeTitleDisplayMode = .never

        // 닫기 버튼 추가
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissSheet)
        )

        // Navigation Bar Style
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ColorSystem.background
        appearance.titleTextAttributes = [.foregroundColor: ColorSystem.mainText]
        appearance.largeTitleTextAttributes = [.foregroundColor: ColorSystem.mainText]
        appearance.shadowColor = nil  // Remove bottom line
        appearance.shadowImage = UIImage()  // Remove shadow

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = ColorSystem.mainText
        navigationController?.navigationBar.prefersLargeTitles = true

        // Segmented Control
        view.addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(sourceFilterChanged), for: .valueChanged)

        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }

        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyLabel)

        tableView.backgroundColor = ColorSystem.background
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }

        // Floating Import Button
        view.addSubview(importFloatingButton)
        importFloatingButton.addTarget(self, action: #selector(showImportRecordPicker), for: .touchUpInside)

        importFloatingButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
    }

    @objc private func dismissSheet() {
        dismiss(animated: true)
    }

    @objc private func sourceFilterChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            sourceFilter = nil // All
        case 1:
            sourceFilter = .healthKit
        case 2:
            sourceFilter = .external
        default:
            sourceFilter = nil
        }
        applyFilter()
    }

    @objc private func showImportRecordPicker() {
        // Use custom UTType for .wplaza files, fallback to json/data for compatibility
        var contentTypes: [UTType] = [.json, .data]
        if let wplazaType = UTType("com.workoutplaza.workout") {
            contentTypes.insert(wplazaType, at: 0)
        }

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        present(documentPicker, animated: true)
    }
    
    private func requestHealthKitAuthorization() {
        loadingIndicator.startAnimating()
        
        WorkoutManager.shared.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.loadWorkouts()
                } else {
                    self?.showAuthorizationError()
                }
            }
        }
    }
    
    private func loadWorkouts() {
        WorkoutManager.shared.fetchWorkouts { [weak self] workouts in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                // Filter only running workouts (GPS 유무와 관계없이 모든 러닝 기록)
                self?.healthKitWorkouts = workouts.filter { $0.workoutType == .running }
                self?.mergeAndSortWorkouts()
            }
        }
    }

    private func loadExternalWorkouts() {
        // Filter only running workouts from external sources
        externalWorkouts = ExternalWorkoutManager.shared.getAllWorkouts().filter { $0.workoutData.type == .running }
    }

    private func mergeAndSortWorkouts() {
        var unified: [UnifiedWorkoutItem] = []

        // Add HealthKit workouts
        for workout in healthKitWorkouts {
            unified.append(UnifiedWorkoutItem(from: workout))
        }

        // Add External workouts
        for external in externalWorkouts {
            unified.append(UnifiedWorkoutItem(from: external))
        }

        // Sort by start date descending (newest first)
        allWorkouts = unified.sorted { $0.startDate > $1.startDate }
        applyFilter()
    }
    
    private func applyFilter() {
        var result = allWorkouts

        // Apply source filter
        if let source = sourceFilter {
            result = result.filter { $0.source == source }
        }

        // Apply type filter
        if let filter = currentFilter {
            result = result.filter { $0.workoutType == filter }
        }

        filteredWorkouts = result
        tableView.reloadData()
        emptyLabel.isHidden = !filteredWorkouts.isEmpty
        updateFilterMenu()
    }
    
    private func updateFilterMenu() {
        // No filter menu needed since we only show running workouts
        // The source filter (HealthKit/External) is handled by segmented control
    }
    
    private func showAuthorizationError() {
        loadingIndicator.stopAnimating()
        
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Permission.Healthkit.title,
            message: WorkoutPlazaStrings.Permission.Healthkit.message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Permission.Open.settings, style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension RunningListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredWorkouts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as! WorkoutCell
        cell.configure(with: filteredWorkouts[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let unifiedWorkout = filteredWorkouts[indexPath.row]
        let detailVC = RunningDetailViewController()

        // Set workout data based on source
        if let healthKitWorkout = unifiedWorkout.healthKitWorkout {
            detailVC.workoutData = healthKitWorkout
        } else if let externalWorkout = unifiedWorkout.externalWorkout {
            // For external workouts, we pass as imported data
            let importedData = ImportedWorkoutData(
                ownerName: externalWorkout.creatorName ?? "",
                originalData: externalWorkout.workoutData,
                selectedFields: Set(ImportField.allCases)
            )
            detailVC.workoutData = nil
            detailVC.importedWorkoutData = importedData
        }

        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Swipe Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let unifiedWorkout = filteredWorkouts[indexPath.row]

        var actions: [UIContextualAction] = []

        // Share action - only for HealthKit workouts
        if let healthKitWorkout = unifiedWorkout.healthKitWorkout {
            let shareAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completionHandler in
                self?.showShareOptions(for: healthKitWorkout, at: indexPath)
                completionHandler(true)
            }
            shareAction.image = UIImage(systemName: "square.and.arrow.up")
            shareAction.backgroundColor = ColorSystem.primaryGreen
            actions.append(shareAction)
        }

        // Delete action - only for external workouts
        if let externalWorkout = unifiedWorkout.externalWorkout {
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completionHandler in
                self?.confirmDeleteExternalWorkout(externalWorkout, at: indexPath)
                completionHandler(true)
            }
            deleteAction.image = UIImage(systemName: "trash")
            actions.append(deleteAction)
        }

        return UISwipeActionsConfiguration(actions: actions)
    }

    private func confirmDeleteExternalWorkout(_ workout: ExternalWorkout, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Running.Delete.record,
            message: WorkoutPlazaStrings.Running.Delete.Record.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.delete, style: .destructive) { _ in
            ExternalWorkoutManager.shared.deleteWorkout(id: workout.id)
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        present(alert, animated: true)
    }

    private func showShareOptions(for workout: WorkoutData, at indexPath: IndexPath) {
        let alert = UIAlertController(title: WorkoutPlazaStrings.Alert.share, message: WorkoutPlazaStrings.Alert.Select.Share.method, preferredStyle: .actionSheet)

        // Share as .wplaza file
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Share.Workout.data, style: .default) { [weak self] _ in
            self?.shareWorkoutAsFile(workout)
        })

        // Share with creator name
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Share.With.name, style: .default) { [weak self] _ in
            self?.showCreatorNameInput(for: workout)
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Button.cancel, style: .cancel))

        // iPad support
        if let popover = alert.popoverPresentationController,
           let cell = tableView.cellForRow(at: indexPath) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }

        present(alert, animated: true)
    }

    private func shareWorkoutAsFile(_ workout: WorkoutData, creatorName: String? = nil) {
        do {
            let fileURL = try ShareManager.shared.exportWorkout(workout, creatorName: creatorName)
            ShareManager.shared.presentShareSheet(for: fileURL, from: self)
        } catch {
            showShareError(error)
        }
    }

    private func showCreatorNameInput(for workout: WorkoutData) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Share.Name.Input.title,
            message: WorkoutPlazaStrings.Share.Name.Input.message,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = WorkoutPlazaStrings.Share.Name.placeholder
        }

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Alert.share, style: .default) { [weak self, weak alert] _ in
            let name = alert?.textFields?.first?.text
            self?.shareWorkoutAsFile(workout, creatorName: name)
        })

        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.cancel, style: .cancel))

        present(alert, animated: true)
    }

    private func showShareError(_ error: Error) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Share.failed,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ImportWorkoutViewControllerDelegate
extension RunningListViewController: ImportWorkoutViewControllerDelegate {
    func importWorkoutViewController(_ controller: ImportWorkoutViewController, didImport data: ImportedWorkoutData, mode: ImportMode, attachTo: WorkoutData?) {
        switch mode {
        case .createNew:
            // Save to ExternalWorkoutManager for persistence
            let externalWorkout = ExternalWorkout(
                importedAt: Date(),
                sourceFileName: nil,
                creatorName: data.ownerName.isEmpty ? nil : data.ownerName,
                workoutData: data.originalData
            )
            ExternalWorkoutManager.shared.saveWorkout(externalWorkout)

            // Show success message (list will auto-update via notification)
            showImportSuccess(workoutType: data.originalData.type)

        case .attachToExisting:
            if let workoutData = attachTo {
                // Open RunningDetailViewController with the workout and imported data
                let detailVC = RunningDetailViewController()
                detailVC.workoutData = workoutData
                detailVC.importedWorkoutData = data
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }

    func importWorkoutViewControllerDidCancel(_ controller: ImportWorkoutViewController) {
        // Nothing to do
    }

    private func showImportSuccess(workoutType: WorkoutType) {
        let typeName = workoutType.sportType?.displayName ?? WorkoutPlazaStrings.Workout.generic
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Import.complete,
            message: WorkoutPlazaStrings.Import.Success.message(typeName),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Workout Cell
class WorkoutCell: UITableViewCell {

    private let cardContainer: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = false

        // Improved shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.06
        view.layer.shadowRadius = 16
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
        return view
    }()

    private let accentBar: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.primaryGreen
        view.layer.cornerRadius = 3
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = ColorSystem.subText
        return label
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        label.textColor = ColorSystem.mainText
        return label
    }()

    private let distanceUnitLabel: UILabel = {
        let label = UILabel()
        label.text = "km"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = ColorSystem.subText
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        label.textColor = ColorSystem.primaryGreen
        return label
    }()

    private let paceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = ColorSystem.subText
        return label
    }()

    private let sourceBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = ColorSystem.background
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardContainer)
        cardContainer.addSubview(accentBar)
        cardContainer.addSubview(dateLabel)
        cardContainer.addSubview(timeLabel)
        cardContainer.addSubview(distanceLabel)
        cardContainer.addSubview(distanceUnitLabel)
        cardContainer.addSubview(durationLabel)
        cardContainer.addSubview(paceLabel)
        cardContainer.addSubview(sourceBadge)

        cardContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-6)
            make.height.equalTo(100)
        }

        accentBar.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(12)
            make.width.equalTo(4)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalTo(accentBar.snp.trailing).offset(16)
        }

        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(dateLabel.snp.trailing).offset(8)
            make.centerY.equalTo(dateLabel)
        }

        sourceBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(50)
        }

        distanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(accentBar.snp.trailing).offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        distanceUnitLabel.snp.makeConstraints { make in
            make.leading.equalTo(distanceLabel.snp.trailing).offset(4)
            make.lastBaseline.equalTo(distanceLabel.snp.lastBaseline)
        }

        durationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        paceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(durationLabel.snp.leading).offset(-12)
            make.centerY.equalTo(durationLabel)
        }
    }

    func configure(with workout: UnifiedWorkoutItem) {
        // Date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd")
        dateLabel.text = dateFormatter.string(from: workout.startDate)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeLabel.text = timeFormatter.string(from: workout.startDate)

        // Distance
        let distanceKm = workout.distance / 1000
        distanceLabel.text = String(format: "%.2f", distanceKm)

        // Duration
        let minutes = Int(workout.duration) / 60
        let seconds = Int(workout.duration) % 60
        durationLabel.text = String(format: "%d:%02d", minutes, seconds)

        // Pace (min/km)
        if workout.distance > 0 {
            let paceSeconds = workout.duration / (workout.distance / 1000)
            let paceMinutes = Int(paceSeconds) / 60
            let paceRemainingSeconds = Int(paceSeconds) % 60
            paceLabel.text = String(format: "%d'%02d\"", paceMinutes, paceRemainingSeconds)
        } else {
            paceLabel.text = "-'--\""
        }

        // Source badge and accent color
        switch workout.source {
        case .healthKit:
            sourceBadge.isHidden = true
            accentBar.backgroundColor = ColorSystem.primaryGreen
        case .external:
            sourceBadge.isHidden = false
            sourceBadge.text = WorkoutPlazaStrings.Running.External.badge
            sourceBadge.backgroundColor = ColorSystem.warning
            accentBar.backgroundColor = ColorSystem.warning
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sourceBadge.isHidden = true
        accentBar.backgroundColor = ColorSystem.primaryGreen
    }
}

// MARK: - UIDocumentPickerDelegate
extension RunningListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }

        let shouldStopAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let shareableWorkout = try ShareManager.shared.importWorkout(from: fileURL)
            // Open ImportWorkoutViewController with createNew mode
            openImportWorkoutViewController(with: shareableWorkout, mode: .createNew)
        } catch {
            showImportError(error)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}
