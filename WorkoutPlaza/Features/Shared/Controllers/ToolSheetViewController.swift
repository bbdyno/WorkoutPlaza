//
//  ToolSheetViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/7/26.
//

import UIKit

// MARK: - ToolSheetItem

struct ToolSheetItem {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let isEnabled: Bool
    let isAdded: Bool
    let previewProvider: (() -> UIView)?
    let action: () -> Void

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        iconName: String,
        isEnabled: Bool = true,
        isAdded: Bool = false,
        previewProvider: (() -> UIView)? = nil,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.isEnabled = isEnabled
        self.isAdded = isAdded
        self.previewProvider = previewProvider
        self.action = action
    }
}

// MARK: - ToolSheetHeaderAction

struct ToolSheetHeaderAction {
    let title: String
    let iconName: String
    let action: () -> Void
}

// MARK: - ToolSheetSection

struct ToolSheetSection {
    let title: String
    let items: [ToolSheetItem]
    let headerActions: [ToolSheetHeaderAction]

    init(title: String, items: [ToolSheetItem], headerActions: [ToolSheetHeaderAction] = []) {
        self.title = title
        self.items = items
        self.headerActions = headerActions
    }
}

// MARK: - ToolSheetViewController

class ToolSheetViewController: UIViewController {

    // MARK: - Properties

    private var sections: [ToolSheetSection] = []
    private var collectionView: UICollectionView!

    // MARK: - Lifecycle

    init(sections: [ToolSheetSection]) {
        self.sections = sections
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSheet()
        setupCollectionView()
    }

    // MARK: - Setup

    private func setupSheet() {
        view.backgroundColor = .systemBackground

        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ToolSheetCell.self, forCellWithReuseIdentifier: ToolSheetCell.reuseIdentifier)
        collectionView.register(
            ToolSheetHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ToolSheetHeaderView.reuseIdentifier
        )

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, environment in
            // 3-column grid
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / 3.0),
                heightDimension: .estimated(100)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 3, bottom: 5, trailing: 3)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 6
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 16, trailing: 12)

            // Section header
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(36)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]

            return section
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ToolSheetViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ToolSheetCell.reuseIdentifier, for: indexPath) as! ToolSheetCell
        let item = sections[indexPath.section].items[indexPath.item]
        cell.configure(with: item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: ToolSheetHeaderView.reuseIdentifier,
            for: indexPath
        ) as! ToolSheetHeaderView
        let section = sections[indexPath.section]
        header.configure(title: section.title, actions: section.headerActions) { [weak self] action in
            self?.dismiss(animated: true) {
                action()
            }
        }
        return header
    }
}

// MARK: - UICollectionViewDelegate

extension ToolSheetViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.item]
        guard item.isEnabled && !item.isAdded else { return }

        dismiss(animated: true) {
            item.action()
        }
    }
}

// MARK: - ToolSheetCell

private class ToolSheetCell: UICollectionViewCell {

    static let reuseIdentifier = "ToolSheetCell"

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .label
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    private let previewContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let checkmarkView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = .systemGreen
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14)
        iv.isHidden = true
        return iv
    }()

    // Constraints that change based on preview mode
    private var iconTopConstraint: NSLayoutConstraint!
    private var titleTopToIconConstraint: NSLayoutConstraint!
    private var titleTopToPreviewConstraint: NSLayoutConstraint!
    private var descriptionBottomConstraint: NSLayoutConstraint!
    private var titleBottomConstraint: NSLayoutConstraint!
    private var previewHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(previewContainerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(checkmarkView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        previewContainerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false

        iconTopConstraint = iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12)
        titleTopToIconConstraint = titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 6)
        titleTopToPreviewConstraint = titleLabel.topAnchor.constraint(equalTo: previewContainerView.bottomAnchor, constant: 4)
        descriptionBottomConstraint = descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        titleBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6)
        previewHeightConstraint = previewContainerView.heightAnchor.constraint(equalToConstant: 56)

        titleTopToPreviewConstraint.isActive = false
        titleBottomConstraint.isActive = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconTopConstraint,
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),

            previewContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            previewContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            previewContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            previewHeightConstraint,

            titleTopToIconConstraint,
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            descriptionBottomConstraint,

            checkmarkView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            checkmarkView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6)
        ])
    }

    func configure(with item: ToolSheetItem) {
        titleLabel.text = item.title
        checkmarkView.isHidden = !item.isAdded

        if let previewProvider = item.previewProvider {
            // Preview mode
            iconImageView.isHidden = true
            descriptionLabel.isHidden = true
            previewContainerView.isHidden = false

            // Switch constraints to preview mode
            iconTopConstraint.isActive = false
            titleTopToIconConstraint.isActive = false
            descriptionBottomConstraint.isActive = false
            titleTopToPreviewConstraint.isActive = true
            titleBottomConstraint.isActive = true

            // Clear old preview
            previewContainerView.subviews.forEach { $0.removeFromSuperview() }

            let previewView = previewProvider()
            previewView.isUserInteractionEnabled = false
            previewView.transform = .identity

            // Tint all labels dark for contrast on light cell background
            Self.tintLabelsDark(in: previewView)

            previewContainerView.addSubview(previewView)

            // Scale preview to fit within container
            previewView.translatesAutoresizingMaskIntoConstraints = true
            let previewAreaWidth = previewContainerView.bounds.width > 0
                ? previewContainerView.bounds.width
                : (UIScreen.main.bounds.width / 3.0 - 30)
            let previewAreaHeight: CGFloat = 56
            let previewSize = previewView.frame.size

            if previewSize.width > 0 && previewSize.height > 0 {
                let scaleX = previewAreaWidth / previewSize.width
                let scaleY = previewAreaHeight / previewSize.height
                let scale = min(scaleX, scaleY, 1.0)
                previewView.transform = CGAffineTransform(scaleX: scale, y: scale)
                previewView.center = CGPoint(x: previewAreaWidth / 2, y: previewAreaHeight / 2)
            } else {
                previewView.center = CGPoint(x: previewAreaWidth / 2, y: previewAreaHeight / 2)
            }
        } else {
            // Icon mode (default)
            iconImageView.isHidden = false
            iconImageView.image = UIImage(systemName: item.iconName)
            descriptionLabel.isHidden = false
            descriptionLabel.text = item.description
            previewContainerView.isHidden = true

            // Switch constraints to icon mode
            titleTopToPreviewConstraint.isActive = false
            titleBottomConstraint.isActive = false
            iconTopConstraint.isActive = true
            titleTopToIconConstraint.isActive = true
            descriptionBottomConstraint.isActive = true
        }

        if !item.isEnabled {
            containerView.alpha = 0.4
            isUserInteractionEnabled = false
        } else if item.isAdded {
            containerView.alpha = 0.6
            isUserInteractionEnabled = false
        } else {
            containerView.alpha = 1.0
            isUserInteractionEnabled = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.alpha = 1.0
        isUserInteractionEnabled = true
        checkmarkView.isHidden = true
        previewContainerView.subviews.forEach { $0.removeFromSuperview() }
        previewContainerView.isHidden = true
        iconImageView.isHidden = false
        descriptionLabel.isHidden = false

        // Reset to icon mode constraints
        titleTopToPreviewConstraint.isActive = false
        titleBottomConstraint.isActive = false
        iconTopConstraint.isActive = true
        titleTopToIconConstraint.isActive = true
        descriptionBottomConstraint.isActive = true
    }

    private static func tintLabelsDark(in view: UIView) {
        let darkColor = UIColor.darkGray
        if let label = view as? UILabel {
            label.textColor = darkColor
        }
        if let imageView = view as? UIImageView {
            imageView.tintColor = darkColor
        }
        for subview in view.subviews {
            tintLabelsDark(in: subview)
        }
        // Also tint CAShapeLayer strokes (for RouteMapView)
        if let sublayers = view.layer.sublayers {
            for layer in sublayers where layer is CAShapeLayer {
                (layer as! CAShapeLayer).strokeColor = darkColor.cgColor
            }
        }
    }
}

// MARK: - ToolSheetHeaderView

private class ToolSheetHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "ToolSheetHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private var actionClosures: [() -> Void] = []
    private var dismissHandler: ((@escaping () -> Void) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(buttonStack)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        buttonStack.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            buttonStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            buttonStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            buttonStack.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionClosures.removeAll()
        dismissHandler = nil
    }

    func configure(title: String, actions: [ToolSheetHeaderAction], dismissHandler: @escaping (@escaping () -> Void) -> Void) {
        titleLabel.text = title
        self.dismissHandler = dismissHandler

        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionClosures.removeAll()

        for (index, action) in actions.enumerated() {
            actionClosures.append(action.action)

            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: action.iconName)?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
            )
            config.title = action.title
            config.baseForegroundColor = .label
            config.imagePadding = 3
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11)

            let button = UIButton(configuration: config)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            button.tag = index
            button.addTarget(self, action: #selector(headerButtonTapped(_:)), for: .touchUpInside)
            button.layer.cornerRadius = 6
            button.layer.borderWidth = 0.5
            button.layer.borderColor = UIColor.separator.cgColor
            buttonStack.addArrangedSubview(button)
        }
    }

    @objc private func headerButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < actionClosures.count else { return }
        let action = actionClosures[index]
        dismissHandler?(action)
    }
}
