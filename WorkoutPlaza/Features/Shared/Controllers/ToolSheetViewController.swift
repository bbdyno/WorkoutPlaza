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
    let columnCount: Int

    init(title: String, items: [ToolSheetItem], headerActions: [ToolSheetHeaderAction] = [], columnCount: Int = 3) {
        self.title = title
        self.items = items
        self.headerActions = headerActions
        self.columnCount = columnCount
    }
}

// MARK: - ToolSheetViewController

class ToolSheetViewController: UIViewController {

    // MARK: - Properties

    private var sections: [ToolSheetSection] = []
    private var toolbarActions: [ToolSheetHeaderAction] = []
    private var collectionView: UICollectionView!

    // MARK: - Lifecycle

    init(sections: [ToolSheetSection], toolbarActions: [ToolSheetHeaderAction] = []) {
        self.sections = sections
        self.toolbarActions = toolbarActions
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: WorkoutPlazaStrings.Button.close,
            style: .done,
            target: self,
            action: #selector(closeTapped)
        )

        if !toolbarActions.isEmpty {
            navigationItem.leftBarButtonItems = toolbarActions.enumerated().map { index, action in
                let button = UIBarButtonItem(
                    title: action.title,
                    image: UIImage(systemName: action.iconName),
                    target: self,
                    action: #selector(toolbarActionTapped(_:))
                )
                button.tag = index
                return button
            }
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func toolbarActionTapped(_ sender: UIBarButtonItem) {
        let index = sender.tag
        guard index < toolbarActions.count else { return }
        let action = toolbarActions[index].action
        dismiss(animated: true) {
            action()
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
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            let columns = self?.sections[sectionIndex].columnCount ?? 3
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .estimated(columns == 2 ? 190 : 100)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                leading: .fixed(3), top: .fixed(5),
                trailing: .fixed(3), bottom: .fixed(5)
            )

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
        let section = sections[indexPath.section]
        let item = section.items[indexPath.item]
        cell.configure(with: item, columnCount: section.columnCount)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: ToolSheetHeaderView.reuseIdentifier,
            for: indexPath
        ) as! ToolSheetHeaderView
        let section = sections[indexPath.section]
        header.configure(title: section.title)
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
    private static let previewImageCache = NSCache<NSString, UIImage>()

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

    private let previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
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
    private var previewImageTopConstraint: NSLayoutConstraint!
    private var previewImageLeadingConstraint: NSLayoutConstraint!
    private var previewImageTrailingConstraint: NSLayoutConstraint!
    private var previewImageBottomConstraint: NSLayoutConstraint!

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
        previewContainerView.addSubview(previewImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(checkmarkView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        previewContainerView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false

        iconTopConstraint = iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12)
        titleTopToIconConstraint = titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 6)
        titleTopToPreviewConstraint = titleLabel.topAnchor.constraint(equalTo: previewContainerView.bottomAnchor, constant: 4)
        descriptionBottomConstraint = descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        titleBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6)
        previewHeightConstraint = previewContainerView.heightAnchor.constraint(equalToConstant: 56)
        previewImageTopConstraint = previewImageView.topAnchor.constraint(equalTo: previewContainerView.topAnchor)
        previewImageLeadingConstraint = previewImageView.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor)
        previewImageTrailingConstraint = previewImageView.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor)
        previewImageBottomConstraint = previewImageView.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor)

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

            previewImageTopConstraint,
            previewImageLeadingConstraint,
            previewImageTrailingConstraint,
            previewImageBottomConstraint,

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

    func configure(with item: ToolSheetItem, columnCount: Int = 3) {
        titleLabel.text = item.title
        checkmarkView.isHidden = !item.isAdded

        if let previewProvider = item.previewProvider {
            // Preview mode
            iconImageView.isHidden = true
            descriptionLabel.isHidden = true
            previewContainerView.isHidden = false
            previewImageView.isHidden = false

            // 2열일 때 미리보기 영역을 더 크게
            let previewHeight: CGFloat = columnCount == 2 ? 140 : 56
            previewHeightConstraint.constant = previewHeight
            let previewInset: CGFloat = columnCount == 2 ? 18 : 0
            previewImageTopConstraint.constant = previewInset
            previewImageLeadingConstraint.constant = previewInset
            previewImageTrailingConstraint.constant = -previewInset
            previewImageBottomConstraint.constant = -previewInset

            // Switch constraints to preview mode
            iconTopConstraint.isActive = false
            titleTopToIconConstraint.isActive = false
            descriptionBottomConstraint.isActive = false
            titleTopToPreviewConstraint.isActive = true
            titleBottomConstraint.isActive = true

            let cacheKey = Self.previewCacheKey(
                itemID: item.id,
                columnCount: columnCount,
                previewHeight: previewHeight
            )

            if let cachedImage = Self.previewImageCache.object(forKey: cacheKey) {
                previewImageView.image = cachedImage
            } else {
                let previewView = previewProvider()
                previewView.isUserInteractionEnabled = false
                previewView.transform = .identity
                previewView.frame.origin = .zero
                previewView.clipsToBounds = true

                // Tint all labels dark for contrast on light cell background
                Self.tintLabelsDark(in: previewView)

                if let image = Self.snapshotImage(from: previewView) {
                    previewImageView.image = image
                    Self.previewImageCache.setObject(image, forKey: cacheKey)
                } else {
                    previewImageView.image = nil
                }
            }
        } else {
            // Icon mode (default)
            iconImageView.isHidden = false
            iconImageView.image = UIImage(systemName: item.iconName)
            descriptionLabel.isHidden = false
            descriptionLabel.text = item.description
            previewContainerView.isHidden = true
            previewImageView.isHidden = true
            previewImageView.image = nil

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
        previewContainerView.isHidden = true
        previewImageView.isHidden = true
        previewImageView.image = nil
        iconImageView.isHidden = false
        descriptionLabel.isHidden = false
        previewHeightConstraint.constant = 56
        previewImageTopConstraint.constant = 0
        previewImageLeadingConstraint.constant = 0
        previewImageTrailingConstraint.constant = 0
        previewImageBottomConstraint.constant = 0

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

    private static func previewCacheKey(itemID: String, columnCount: Int, previewHeight: CGFloat) -> NSString {
        "\(itemID)|\(columnCount)|\(Int(previewHeight.rounded()))" as NSString
    }

    private static func snapshotImage(from view: UIView) -> UIImage? {
        let size = view.bounds.size
        guard size.width > 0, size.height > 0 else { return nil }

        view.setNeedsLayout()
        view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            view.layer.render(in: context.cgContext)
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
