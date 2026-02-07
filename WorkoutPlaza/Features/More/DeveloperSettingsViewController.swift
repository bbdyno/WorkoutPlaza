//
//  DeveloperSettingsViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/7/26.
//

import UIKit
import SnapKit

class DeveloperSettingsViewController: UIViewController {

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    // MARK: - Data

    private struct SettingItem {
        let title: String
        let isOn: () -> Bool
        let onToggle: (Bool) -> Void
    }

    private struct Section {
        let title: String?
        let items: [SettingItem]
    }

    private var sections: [Section] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupUI()
    }

    // MARK: - Setup

    private func setupData() {
        sections = [
            Section(title: "위젯 편집", items: [
                SettingItem(
                    title: "핀치로 크기 조절",
                    isOn: { DevSettings.shared.isPinchToResizeEnabled },
                    onToggle: { DevSettings.shared.isPinchToResizeEnabled = $0 }
                )
            ])
        ]
    }

    private func setupUI() {
        view.backgroundColor = ColorSystem.background
        title = "개발자 설정"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = ColorSystem.background
        tableView.separatorColor = ColorSystem.divider

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource

extension DeveloperSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
        config.textProperties.color = ColorSystem.mainText
        cell.contentConfiguration = config

        let toggle = UISwitch()
        toggle.isOn = item.isOn()
        toggle.tag = indexPath.row
        toggle.onTintColor = ColorSystem.primaryGreen
        toggle.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
        cell.accessoryView = toggle

        cell.selectionStyle = .none
        cell.backgroundColor = .secondarySystemGroupedBackground

        return cell
    }

    @objc private func switchToggled(_ sender: UISwitch) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let item = sections[indexPath.section].items[indexPath.row]
        item.onToggle(sender.isOn)
    }
}

// MARK: - UITableViewDelegate

extension DeveloperSettingsViewController: UITableViewDelegate {}
