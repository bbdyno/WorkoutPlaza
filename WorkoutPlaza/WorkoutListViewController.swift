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
