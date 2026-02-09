//
//  GymPickerViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/29/26.
//

import UIKit
import Combine
import SnapKit

protocol GymPickerDelegate: AnyObject {
    func gymPicker(_ picker: GymPickerViewController, didSelect gym: ClimbingGym?)
}

class GymPickerViewController: UIViewController {
    private enum Constants {
        static let bannerTopOffset: CGFloat = 16
        static let bannerWidthMultiplier: CGFloat = 0.9
        static let bannerHeight: CGFloat = 44
    }

    weak var delegate: GymPickerDelegate?
    var selectedGym: ClimbingGym?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let logoManager = ClimbingGymLogoManager.shared

    private var builtInGyms: [ClimbingGym] = []
    private var customGyms: [ClimbingGym] = []

    private var cancellables = Set<AnyCancellable>()

    enum Section: Int, CaseIterable {
        case builtIn    // 프리셋 암장
        case custom     // 내 암장
        case actions    // 추가 옵션

        var title: String? {
            switch self {
            case .builtIn: return WorkoutPlazaStrings.Gym.Section.builtin
            case .custom: return WorkoutPlazaStrings.Gym.Section.custom
            case .actions: return nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        setupRemoteConfigSubscription()
        loadGyms()
    }

    deinit {
        cancellables.removeAll()
    }

    /// Remote Config 자동 업데이트 구독
    private func setupRemoteConfigSubscription() {
        ClimbingGymRemoteConfigManager.shared.configUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedGyms in
                WPLog.info("Received auto-update: \(updatedGyms.count) gyms")
                self?.loadGyms()
                self?.showAutoUpdateNotification()
            }
            .store(in: &cancellables)
    }

    private func showAutoUpdateNotification() {
        let banner = UILabel()
        banner.text = WorkoutPlazaStrings.Gym.Auto.updated
        banner.textAlignment = .center
        banner.font = .systemFont(ofSize: 14, weight: .medium)
        banner.textColor = .white  // Banner는 배경색 있으므로 흰색 유지
        banner.backgroundColor = ColorSystem.success
        banner.alpha = 0
        banner.layer.cornerRadius = 8
        banner.clipsToBounds = true

        view.addSubview(banner)
        banner.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.bannerTopOffset)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().multipliedBy(Constants.bannerWidthMultiplier)
            make.height.equalTo(Constants.bannerHeight)
        }

        UIView.animate(withDuration: 0.3, animations: {
            banner.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, animations: {
                banner.alpha = 0
            }) { _ in
                banner.removeFromSuperview()
            }
        }
    }

    private func setupNavigationBar() {
        title = WorkoutPlazaStrings.Gym.Picker.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: WorkoutPlazaStrings.Common.done,
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(GymPickerCell.self, forCellReuseIdentifier: "GymPickerCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActionCell")
    }

    private func loadGyms() {
        let manager = ClimbingGymManager.shared
        builtInGyms = manager.getBuiltInGyms() + manager.getRemoteGyms()
        customGyms = manager.getCustomGyms()
        tableView.reloadData()
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }

    private func handleRemoteSync() {
        let loadingAlert = UIAlertController(
            title: WorkoutPlazaStrings.Gym.Sync.loading,
            message: WorkoutPlazaStrings.Gym.Sync.Loading.message,
            preferredStyle: .alert
        )
        present(loadingAlert, animated: true)

        // 새로운 manualRefresh API 사용
        ClimbingGymRemoteConfigManager.shared.manualRefresh { [weak self] result in
            loadingAlert.dismiss(animated: true) {
                switch result {
                case .success(let gyms):
                    WPLog.info("Manual refresh success: \(gyms.count) gyms")
                    self?.loadGyms()
                    self?.showSuccessAlert()
                case .failure(let error):
                    WPLog.error("Manual refresh failed: \(error.localizedDescription)")
                    self?.showErrorAlert(error)
                }
            }
        }
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Gym.Sync.complete,
            message: WorkoutPlazaStrings.Gym.Sync.Complete.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: WorkoutPlazaStrings.Gym.Sync.failed,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: WorkoutPlazaStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension GymPickerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }

        switch sectionType {
        case .builtIn:
            return builtInGyms.count
        case .custom:
            return customGyms.count
        case .actions:
            return 2 // "사용자 지정", "원격 프리셋 동기화"
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }

        // Hide "내 암장" section title if there are no custom gyms
        if sectionType == .custom && customGyms.isEmpty {
            return nil
        }

        return sectionType.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch sectionType {
        case .builtIn:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GymPickerCell", for: indexPath) as! GymPickerCell
            let gym = builtInGyms[indexPath.row]
            cell.configure(with: gym, isSelected: gym.id == selectedGym?.id)
            return cell

        case .custom:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GymPickerCell", for: indexPath) as! GymPickerCell
            let gym = customGyms[indexPath.row]
            cell.configure(with: gym, isSelected: gym.id == selectedGym?.id)
            return cell

        case .actions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath)
            cell.backgroundColor = ColorSystem.cardBackground

            if indexPath.row == 0 {
                cell.textLabel?.text = WorkoutPlazaStrings.Gym.Action.custom
                cell.textLabel?.textColor = ColorSystem.primaryGreen
                cell.imageView?.image = UIImage(systemName: "plus.circle.fill")
                cell.imageView?.tintColor = ColorSystem.primaryGreen
            } else {
                cell.textLabel?.text = WorkoutPlazaStrings.Gym.Action.sync
                cell.textLabel?.textColor = ColorSystem.primaryGreen
                cell.imageView?.image = UIImage(systemName: "arrow.clockwise.circle.fill")
                cell.imageView?.tintColor = ColorSystem.primaryGreen
            }

            cell.textLabel?.font = .systemFont(ofSize: 17, weight: .medium)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension GymPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let sectionType = Section(rawValue: indexPath.section) else { return }

        switch sectionType {
        case .builtIn:
            let gym = builtInGyms[indexPath.row]
            delegate?.gymPicker(self, didSelect: gym)
            dismiss(animated: true)

        case .custom:
            let gym = customGyms[indexPath.row]
            delegate?.gymPicker(self, didSelect: gym)
            dismiss(animated: true)

        case .actions:
            if indexPath.row == 0 {
                // 사용자 지정
                delegate?.gymPicker(self, didSelect: nil)
                dismiss(animated: true)
            } else {
                // 원격 동기화
                handleRemoteSync()
            }
        }
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let sectionType = Section(rawValue: indexPath.section),
              sectionType == .custom else { return nil }

        let gym = customGyms[indexPath.row]

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(
                title: WorkoutPlazaStrings.Common.delete,
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.deleteCustomGym(gym)
            }

            return UIMenu(title: gym.name, children: [deleteAction])
        }
    }

    private func deleteCustomGym(_ gym: ClimbingGym) {
        ClimbingGymManager.shared.deleteGym(id: gym.id)
        loadGyms()
    }
}
