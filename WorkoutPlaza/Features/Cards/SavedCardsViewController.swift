//
//  SavedCardsViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/26/26.
//

import UIKit
import SnapKit

class SavedCardsViewController: UIViewController {
    private enum Constants {
        static let emptyLabelHorizontalPadding: CGFloat = 40
    }

    // MARK: - Properties
    private var cards: [WorkoutCard] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(CardCell.self, forCellWithReuseIdentifier: "CardCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "저장된 카드가 없습니다\n운동 기록에서 공유 버튼을 눌러\n카드를 생성해보세요"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCards()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "저장된 카드"

        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(collectionView)
        view.addSubview(emptyLabel)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.emptyLabelHorizontalPadding)
            make.trailing.equalToSuperview().offset(-Constants.emptyLabelHorizontalPadding)
        }
    }

    private func loadCards() {
        cards = WorkoutCardManager.shared.loadCards()
        collectionView.reloadData()
        emptyLabel.isHidden = !cards.isEmpty
        collectionView.isHidden = cards.isEmpty
    }

    // MARK: - Actions

    private func showCardDetail(_ card: WorkoutCard) {
        guard let image = WorkoutCardManager.shared.loadFullImage(for: card) else { return }

        let detailVC = CardDetailViewController(card: card, image: image)
        detailVC.onDelete = { [weak self] in
            self?.loadCards()
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension SavedCardsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! CardCell
        let card = cards[indexPath.item]
        cell.configure(with: card)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SavedCardsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showCardDetail(cards[indexPath.item])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SavedCardsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 12
        let padding: CGFloat = 16 * 2
        let availableWidth = collectionView.bounds.width - padding - spacing
        let cellWidth = availableWidth / 2

        // 9:16 aspect ratio for thumbnail
        let cellHeight = cellWidth * (16.0 / 9.0) + 50 // Extra space for labels
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

// MARK: - CardCell

private class CardCell: UICollectionViewCell {
    private enum Constants {
        static let thumbnailCornerRadius: CGFloat = 12
        static let iconTopOffset: CGFloat = 8
        static let iconLeadingOffset: CGFloat = 4
        static let iconSize: CGFloat = 16
        static let labelHorizontalPadding: CGFloat = 4
        static let dateLabelTopOffset: CGFloat = 2
    }

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = Constants.thumbnailCornerRadius
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabel
        return label
    }()

    private let sportTypeIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .secondaryLabel
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(sportTypeIcon)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)

        thumbnailImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(thumbnailImageView.snp.width).multipliedBy(16.0/9.0)
        }

        sportTypeIcon.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImageView.snp.bottom).offset(Constants.iconTopOffset)
            make.leading.equalToSuperview().offset(Constants.iconLeadingOffset)
            make.size.equalTo(Constants.iconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(sportTypeIcon)
            make.leading.equalTo(sportTypeIcon.snp.trailing).offset(Constants.labelHorizontalPadding)
            make.trailing.equalToSuperview().offset(-Constants.labelHorizontalPadding)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.dateLabelTopOffset)
            make.leading.equalToSuperview().offset(Constants.labelHorizontalPadding)
            make.trailing.equalToSuperview().offset(-Constants.labelHorizontalPadding)
        }
    }

    func configure(with card: WorkoutCard) {
        if let thumbnail = WorkoutCardManager.shared.loadThumbnail(for: card) {
            thumbnailImageView.image = thumbnail
        } else {
            thumbnailImageView.image = nil
        }

        titleLabel.text = card.workoutTitle

        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        dateLabel.text = formatter.string(from: card.workoutDate)

        let iconName = card.sportType == .running ? "figure.run" : "figure.climbing"
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        sportTypeIcon.image = UIImage(systemName: iconName, withConfiguration: config)
        sportTypeIcon.tintColor = card.sportType == .running ? .systemBlue : .systemOrange
    }
}

// MARK: - CardDetailViewController

class CardDetailViewController: UIViewController {
    private let card: WorkoutCard
    private let cardImage: UIImage
    var onDelete: (() -> Void)?

    private let scrollView = UIScrollView()
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()

    init(card: WorkoutCard, image: UIImage) {
        self.card = card
        self.cardImage = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)

        scrollView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        imageView.image = cardImage

        // Adjust image height based on aspect ratio
        let aspectRatio = cardImage.size.height / cardImage.size.width
        imageView.snp.makeConstraints { make in
            make.height.equalTo(imageView.snp.width).multipliedBy(aspectRatio)
        }
    }

    private func setupNavigationBar() {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        title = formatter.string(from: card.workoutDate)

        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )

        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteTapped)
        )
        deleteButton.tintColor = .systemRed

        navigationItem.rightBarButtonItems = [shareButton, deleteButton]
    }

    @objc private func shareTapped() {
        let activityVC = UIActivityViewController(activityItems: [cardImage], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        present(activityVC, animated: true)
    }

    @objc private func deleteTapped() {
        let alert = UIAlertController(
            title: "카드 삭제",
            message: "이 카드를 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            WorkoutCardManager.shared.deleteCard(self.card)
            self.onDelete?()
            self.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }
}
