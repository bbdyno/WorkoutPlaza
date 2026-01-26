//
//  WorkoutListViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit
import UniformTypeIdentifiers

class WorkoutListViewController: UIViewController {

    // MARK: - Data Sources
    private var healthKitWorkouts: [WorkoutData] = []
    private var externalWorkouts: [ExternalWorkout] = []

    // Unified list
    private var allWorkouts: [UnifiedWorkoutItem] = []
    private var filteredWorkouts: [UnifiedWorkoutItem] = []
    private var currentFilter: String? = nil // nil means "All"
    private var sourceFilter: UnifiedWorkoutSource? = nil // nil means "All Sources"
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(WorkoutCell.self, forCellReuseIdentifier: "WorkoutCell")
        table.rowHeight = 100
        return table
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "러닝 기록이 없습니다"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["전체", "HealthKit", "외부 기록"])
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        sc.selectedSegmentTintColor = .systemBlue
        let normalAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.lightGray]
        let selectedAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white]
        sc.setTitleTextAttributes(normalAttributes, for: .normal)
        sc.setTitleTextAttributes(selectedAttributes, for: .selected)
        return sc
    }()

    private let importFloatingButton: UIButton = {
        let button = UIButton(type: .system)

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        config.image = UIImage(systemName: "square.and.arrow.down", withConfiguration: imageConfig)
        config.imagePadding = 8
        config.title = "외부 기록 가져오기"

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

            // Check if current top view controller is WorkoutDetailViewController
            if let topVC = navigationController?.topViewController, topVC is WorkoutDetailViewController {
                // Forward to WorkoutDetailViewController
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
            title: "기록 선택",
            message: "타인의 기록을 첨부할 내 운동 기록을 선택하세요",
            preferredStyle: .actionSheet
        )

        // Show recent HealthKit workouts only (can only attach to your own workouts)
        let healthKitItems = allWorkouts.filter { $0.source == .healthKit }

        for unifiedWorkout in healthKitItems.prefix(5) {
            guard let healthKitWorkout = unifiedWorkout.healthKitWorkout else { continue }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd HH:mm"
            let dateString = dateFormatter.string(from: unifiedWorkout.startDate)
            let title = "\(unifiedWorkout.workoutType) - \(dateString)"

            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.openImportWorkoutViewController(with: workout, mode: .attachToExisting, attachTo: healthKitWorkout)
            })
        }

        if healthKitItems.isEmpty {
            alert.message = "첨부할 수 있는 HealthKit 기록이 없습니다."
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func showImportError(_ error: Error) {
        let alert = UIAlertController(
            title: "가져오기 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func setupUI() {
        title = "러닝 기록"
        view.backgroundColor = .black
        navigationItem.largeTitleDisplayMode = .never

        // 닫기 버튼 추가
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissSheet)
        )

        // Dark Navigation Bar Style
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
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

        tableView.backgroundColor = .black
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
                self?.healthKitWorkouts = workouts.filter { $0.workoutType == "러닝" }
                self?.mergeAndSortWorkouts()
            }
        }
    }

    private func loadExternalWorkouts() {
        // Filter only running workouts from external sources
        externalWorkouts = ExternalWorkoutManager.shared.getAllWorkouts().filter { $0.workoutData.type == "러닝" }
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
            title: "권한 필요",
            message: "HealthKit 데이터를 읽기 위해 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension WorkoutListViewController: UITableViewDelegate, UITableViewDataSource {
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
        let detailVC = WorkoutDetailViewController()

        // Set workout data based on source
        if let healthKitWorkout = unifiedWorkout.healthKitWorkout {
            detailVC.workoutData = healthKitWorkout
        } else if let externalWorkout = unifiedWorkout.externalWorkout {
            // For external workouts, we pass as imported data
            let importedData = ImportedWorkoutData(
                ownerName: externalWorkout.creatorName ?? "",
                originalData: externalWorkout.workoutData,
                selectedFields: Set(ImportField.allCases),
                useCurrentLayout: false
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
            shareAction.backgroundColor = .systemBlue
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
            title: "기록 삭제",
            message: "이 외부 기록을 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
            ExternalWorkoutManager.shared.deleteWorkout(id: workout.id)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func showShareOptions(for workout: WorkoutData, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "공유", message: "공유 방식을 선택하세요", preferredStyle: .actionSheet)

        // Share as .wplaza file
        alert.addAction(UIAlertAction(title: "운동 데이터 공유 (.wplaza)", style: .default) { [weak self] _ in
            self?.shareWorkoutAsFile(workout)
        })

        // Share with creator name
        alert.addAction(UIAlertAction(title: "이름과 함께 공유 (.wplaza)", style: .default) { [weak self] _ in
            self?.showCreatorNameInput(for: workout)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

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
            title: "이름 입력",
            message: "공유할 때 표시될 이름을 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "이름"
        }

        alert.addAction(UIAlertAction(title: "공유", style: .default) { [weak self, weak alert] _ in
            let name = alert?.textFields?.first?.text
            self?.shareWorkoutAsFile(workout, creatorName: name)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func showShareError(_ error: Error) {
        let alert = UIAlertController(
            title: "공유 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ImportWorkoutViewControllerDelegate
extension WorkoutListViewController: ImportWorkoutViewControllerDelegate {
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
                // Open WorkoutDetailViewController with the workout and imported data
                let detailVC = WorkoutDetailViewController()
                detailVC.workoutData = workoutData
                detailVC.importedWorkoutData = data
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }

    func importWorkoutViewControllerDidCancel(_ controller: ImportWorkoutViewController) {
        // Nothing to do
    }

    private func showImportSuccess(workoutType: String) {
        let alert = UIAlertController(
            title: "가져오기 완료",
            message: "\(workoutType) 기록을 성공적으로 가져왔습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Workout Cell
class WorkoutCell: UITableViewCell {

    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()

    private let sourceBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 4
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
        // Dark theme cell background
        backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        // Selection style
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        selectedBackgroundView = selectedView

        contentView.addSubview(iconImageView)
        contentView.addSubview(typeLabel)
        contentView.addSubview(sourceBadge)
        contentView.addSubview(dateLabel)
        contentView.addSubview(distanceLabel)
        contentView.addSubview(durationLabel)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        typeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
        }

        sourceBadge.snp.makeConstraints { make in
            make.leading.equalTo(typeLabel.snp.trailing).offset(8)
            make.centerY.equalTo(typeLabel)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(40)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(typeLabel.snp.bottom).offset(4)
            make.leading.equalTo(typeLabel)
        }

        distanceLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(typeLabel)
        }

        durationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(dateLabel)
        }
    }

    func configure(with workout: UnifiedWorkoutItem) {
        typeLabel.text = workout.workoutType

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = formatter.string(from: workout.startDate)

        distanceLabel.text = String(format: "%.2f km", workout.distance / 1000)

        let minutes = Int(workout.duration) / 60
        let seconds = Int(workout.duration) % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)

        // Set icon based on workout type
        switch workout.workoutType {
        case "러닝":
            iconImageView.image = UIImage(systemName: "figure.run")
        case "사이클링":
            iconImageView.image = UIImage(systemName: "bicycle")
        case "걷기":
            iconImageView.image = UIImage(systemName: "figure.walk")
        case "하이킹":
            iconImageView.image = UIImage(systemName: "figure.hiking")
        default:
            iconImageView.image = UIImage(systemName: "figure.mixed.cardio")
        }

        // Show source badge for external workouts
        switch workout.source {
        case .healthKit:
            sourceBadge.isHidden = true
            iconImageView.tintColor = .systemBlue
        case .external:
            sourceBadge.isHidden = false
            sourceBadge.text = " 외부 "
            sourceBadge.backgroundColor = .systemOrange
            iconImageView.tintColor = .systemOrange
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sourceBadge.isHidden = true
        iconImageView.tintColor = .systemBlue
    }
}

// MARK: - UIDocumentPickerDelegate
extension WorkoutListViewController: UIDocumentPickerDelegate {
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
