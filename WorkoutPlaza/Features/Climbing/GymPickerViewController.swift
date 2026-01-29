//
//  GymPickerViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/29/26.
//

import UIKit

protocol GymPickerDelegate: AnyObject {
    func gymPicker(_ picker: GymPickerViewController, didSelect gym: ClimbingGym?)
}

class GymPickerViewController: UIViewController {
    weak var delegate: GymPickerDelegate?
    var selectedGym: ClimbingGym?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let logoManager = ClimbingGymLogoManager.shared

    private var builtInGyms: [ClimbingGym] = []
    private var customGyms: [ClimbingGym] = []

    enum Section: Int, CaseIterable {
        case builtIn    // 프리셋 암장
        case custom     // 내 암장
        case actions    // 추가 옵션

        var title: String? {
            switch self {
            case .builtIn: return "암장"
            case .custom: return "내 암장"
            case .actions: return nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        setupNavigationBar()
        setupTableView()
        loadGyms()
    }

    private func setupNavigationBar() {
        title = "암장 선택"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "완료",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

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
            title: "동기화 중...",
            message: "원격 프리셋을 불러오는 중입니다",
            preferredStyle: .alert
        )
        present(loadingAlert, animated: true)

        ClimbingGymManager.shared.syncRemotePresets { [weak self] result in
            loadingAlert.dismiss(animated: true) {
                switch result {
                case .success():
                    self?.loadGyms()
                    self?.showSuccessAlert()
                case .failure(let error):
                    self?.showErrorAlert(error)
                }
            }
        }
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "동기화 완료",
            message: "최신 암장 데이터를 불러왔습니다",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "동기화 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
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
            cell.backgroundColor = .secondarySystemGroupedBackground

            if indexPath.row == 0 {
                cell.textLabel?.text = "+ 사용자 지정"
                cell.textLabel?.textColor = .systemBlue
                cell.imageView?.image = UIImage(systemName: "plus.circle.fill")
                cell.imageView?.tintColor = .systemBlue
            } else {
                cell.textLabel?.text = "암장 데이터 동기화"
                cell.textLabel?.textColor = .systemBlue
                cell.imageView?.image = UIImage(systemName: "arrow.clockwise.circle.fill")
                cell.imageView?.tintColor = .systemBlue
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
                title: "삭제",
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
