//
//  WorkoutListViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit

class WorkoutListViewController: UIViewController {
    
    private var allWorkouts: [WorkoutData] = []
    private var filteredWorkouts: [WorkoutData] = []
    private var currentFilter: String? = nil // nil means "All"
    
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
        label.text = "GPS 기록이 있는 운동이 없습니다"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private let headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 40))
        let label = UILabel()
        label.text = "📍 GPS 정보가 있는 운동만 표시됩니다"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestHealthKitAuthorization()
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReceivedWorkoutFile(_:)),
            name: .didReceiveSharedWorkout,
            object: nil
        )
    }

    @objc private func handleReceivedWorkoutFile(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }

        do {
            let shareableWorkout = try ShareManager.shared.importWorkout(from: url)
            showImportOptions(for: shareableWorkout, fileURL: url)
        } catch {
            showImportError(error)
        }
    }

    private func showImportOptions(for workout: ShareableWorkout, fileURL: URL) {
        let creatorName = workout.creator?.name ?? "알 수 없음"
        let workoutType = workout.workout.type

        let alert = UIAlertController(
            title: "운동 기록 가져오기",
            message: "\(creatorName)님의 \(workoutType) 기록을 가져왔습니다.\n어떻게 처리할까요?",
            preferredStyle: .alert
        )

        // Option 1: Create new record
        alert.addAction(UIAlertAction(title: "내 기록 작성", style: .default) { [weak self] _ in
            self?.openImportWorkoutViewController(with: workout, mode: .createNew)
        })

        // Option 2: Attach to existing record
        alert.addAction(UIAlertAction(title: "기존 기록에 첨부", style: .default) { [weak self] _ in
            self?.showWorkoutSelectionForAttachment(workout: workout)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
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

        // Show recent workouts
        for (index, myWorkout) in allWorkouts.prefix(5).enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd HH:mm"
            let dateString = dateFormatter.string(from: myWorkout.startDate)
            let title = "\(myWorkout.workoutType) - \(dateString)"

            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.openImportWorkoutViewController(with: workout, mode: .attachToExisting, attachTo: myWorkout)
            })
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
        title = "운동 기록"
        view.backgroundColor = .systemGroupedBackground // Modern grouped background
        
        // Modern Navigation Bar
        navigationController?.navigationBar.prefersLargeTitles = true
        
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyLabel)
        
        tableView.tableHeaderView = headerView
        tableView.backgroundColor = .clear // Let system grouped color show
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
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
        WorkoutManager.shared.fetchGPSWorkouts { [weak self] workouts in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                // Sort by date descending (newest first)
                self?.allWorkouts = workouts.sorted(by: { $0.startDate > $1.startDate })
                self?.applyFilter()
            }
        }
    }
    
    private func applyFilter() {
        if let filter = currentFilter {
            filteredWorkouts = allWorkouts.filter { $0.workoutType == filter }
        } else {
            filteredWorkouts = allWorkouts
        }
        
        tableView.reloadData()
        emptyLabel.isHidden = !filteredWorkouts.isEmpty
        updateFilterMenu()
    }
    
    private func updateFilterMenu() {
        // Get unique workout types
        let types = Set(allWorkouts.map { $0.workoutType }).sorted()
        
        var actions: [UIAction] = []
        
        // "All" action
        let allAction = UIAction(title: "모두", state: currentFilter == nil ? .on : .off) { [weak self] _ in
            self?.currentFilter = nil
            self?.applyFilter()
        }
        actions.append(allAction)
        
        // Type actions
        for type in types {
            let action = UIAction(title: type, state: currentFilter == type ? .on : .off) { [weak self] _ in
                self?.currentFilter = type
                self?.applyFilter()
            }
            actions.append(action)
        }
        
        let menu = UIMenu(title: "운동 종류 필터", children: actions)
        
        // Setup/Update filter button
        if navigationItem.rightBarButtonItem == nil {
            let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), menu: menu)
            navigationItem.rightBarButtonItem = filterButton
        } else {
            navigationItem.rightBarButtonItem?.menu = menu
        }
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

        let detailVC = WorkoutDetailViewController()
        detailVC.workoutData = filteredWorkouts[indexPath.row]
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Swipe Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let workout = filteredWorkouts[indexPath.row]

        // Share action
        let shareAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completionHandler in
            self?.showShareOptions(for: workout, at: indexPath)
            completionHandler(true)
        }
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        shareAction.backgroundColor = .systemBlue

        return UISwipeActionsConfiguration(actions: [shareAction])
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
            // Open WorkoutDetailViewController with imported data only (no health data required)
            let detailVC = WorkoutDetailViewController()
            detailVC.workoutData = nil  // No health data
            detailVC.importedWorkoutData = data
            navigationController?.pushViewController(detailVC, animated: true)

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

    private func showImportSuccess(ownerName: String) {
        let alert = UIAlertController(
            title: "가져오기 완료",
            message: "\(ownerName)님의 기록을 성공적으로 가져왔습니다.",
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
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(typeLabel)
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
    
    func configure(with workout: WorkoutData) {
        typeLabel.text = workout.workoutType
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = formatter.string(from: workout.startDate)
        
        distanceLabel.text = String(format: "%.2f km", workout.distance / 1000)
        
        let minutes = Int(workout.duration) / 60
        let seconds = Int(workout.duration) % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
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
    }
}
