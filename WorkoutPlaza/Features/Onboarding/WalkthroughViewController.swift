//
//  WalkthroughViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/19/26.
//

import UIKit
import SnapKit

// MARK: - Model

private enum WalkthroughKind {
    case record
    case design
    case stats
}

private struct WalkthroughPage {
    let kind: WalkthroughKind
    let accentColor: UIColor
    let titleKey: String
    let descriptionKey: String
}

// MARK: - WalkthroughArtworkView

private final class WalkthroughArtworkView: UIView {

    private let containerView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = true
        return v
    }()

    private var contentViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(containerView)
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(kind: WalkthroughKind, accentColor: UIColor) {
        // Clear previous content
        contentViews.forEach { $0.removeFromSuperview() }
        contentViews.removeAll()

        // Container style
        containerView.backgroundColor = accentColor.withAlphaComponent(0.06)
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = accentColor.withAlphaComponent(0.15).cgColor

        switch kind {
        case .record:
            buildRecordArtwork()
        case .design:
            buildDesignArtwork()
        case .stats:
            buildStatsArtwork(accentColor: accentColor)
        }
    }

    // MARK: - Page 1: Record

    private func buildRecordArtwork() {
        let headerLabel = makeLabel("This Week", size: 15, weight: .bold, color: ColorSystem.mainText)
        containerView.addSubview(headerLabel)
        contentViews.append(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(18)
        }

        let cardsStack = UIStackView()
        cardsStack.axis = .horizontal
        cardsStack.spacing = 10
        cardsStack.distribution = .fillEqually
        containerView.addSubview(cardsStack)
        contentViews.append(cardsStack)

        let runningCard = makeStatCard(
            emoji: "🏃",
            title: "Running",
            mainValue: "5.2 km",
            subValue: "3 times · 42 min",
            color: ColorSystem.primaryBlue
        )
        let climbingCard = makeStatCard(
            emoji: "🧗",
            title: "Climbing",
            mainValue: "12 routes",
            subValue: "2 visits · 8 sent",
            color: ColorSystem.primaryGreen
        )
        cardsStack.addArrangedSubview(runningCard)
        cardsStack.addArrangedSubview(climbingCard)

        cardsStack.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        let addButton = UIView()
        addButton.backgroundColor = ColorSystem.primaryBlue.withAlphaComponent(0.12)
        addButton.layer.cornerRadius = 10
        containerView.addSubview(addButton)
        contentViews.append(addButton)

        let plusLabel = makeLabel("+ Add Workout", size: 13, weight: .semibold, color: ColorSystem.primaryBlue)
        plusLabel.textAlignment = .center
        addButton.addSubview(plusLabel)
        plusLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        addButton.snp.makeConstraints { make in
            make.top.equalTo(cardsStack.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(36)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }
    }

    private func makeStatCard(emoji: String, title: String, mainValue: String, subValue: String, color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = ColorSystem.cardBackground
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = ColorSystem.divider.cgColor

        let emojiLabel = makeLabel(emoji, size: 20, weight: .regular, color: .label)
        let titleLabel = makeLabel(title, size: 12, weight: .semibold, color: color)
        let valueLabel = makeLabel(mainValue, size: 20, weight: .bold, color: ColorSystem.mainText)
        let subLabel = makeLabel(subValue, size: 10, weight: .medium, color: ColorSystem.subText)

        let topRow = UIStackView(arrangedSubviews: [emojiLabel, titleLabel])
        topRow.axis = .horizontal
        topRow.spacing = 4
        topRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [topRow, valueLabel, subLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading

        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        }

        return card
    }

    // MARK: - Page 2: Design

    private func buildDesignArtwork() {
        // Canvas
        let canvas = UIView()
        canvas.backgroundColor = ColorSystem.cardBackground
        canvas.layer.cornerRadius = 14
        canvas.layer.borderWidth = 1
        canvas.layer.borderColor = ColorSystem.divider.cgColor
        containerView.addSubview(canvas)
        contentViews.append(canvas)

        // Distance
        let distLabel = makeLabel("5.2 km", size: 26, weight: .bold, color: ColorSystem.mainText)
        canvas.addSubview(distLabel)
        distLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
        }

        // Date
        let dateLabel = makeLabel("2025.01.15", size: 12, weight: .medium, color: ColorSystem.subText)
        canvas.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().inset(16)
        }

        // Location
        let pinAttach = NSTextAttachment()
        pinAttach.image = UIImage(systemName: "mappin.and.ellipse")?.withTintColor(ColorSystem.subText)
        let pinStr = NSMutableAttributedString(attachment: pinAttach)
        pinStr.append(NSAttributedString(string: " Seoul, Korea", attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: ColorSystem.subText
        ]))
        let locLabel = UILabel()
        locLabel.attributedText = pinStr
        canvas.addSubview(locLabel)
        locLabel.snp.makeConstraints { make in
            make.top.equalTo(distLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
        }

        // Map placeholder
        let mapView = UIView()
        mapView.backgroundColor = ColorSystem.divider.withAlphaComponent(0.5)
        mapView.layer.cornerRadius = 8
        canvas.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.top.equalTo(locLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(60)
            make.bottom.equalToSuperview().inset(12)
        }

        // Route line on map
        let routeLine = UIView()
        routeLine.backgroundColor = ColorSystem.primaryBlue.withAlphaComponent(0.4)
        routeLine.layer.cornerRadius = 1.5
        mapView.addSubview(routeLine)
        routeLine.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.6)
            make.height.equalTo(3)
        }
        routeLine.transform = CGAffineTransform(rotationAngle: -.pi / 6)

        canvas.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        // Toolbar
        let toolbar = UIStackView()
        toolbar.axis = .horizontal
        toolbar.distribution = .fillEqually
        toolbar.spacing = 0
        containerView.addSubview(toolbar)
        contentViews.append(toolbar)

        let toolIcons = ["paintpalette.fill", "textformat", "text.alignleft", "trash"]
        for iconName in toolIcons {
            let btn = UIView()
            let img = UIImageView(image: UIImage(systemName: iconName))
            img.tintColor = ColorSystem.subText
            img.contentMode = .scaleAspectFit
            btn.addSubview(img)
            img.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(18)
            }
            toolbar.addArrangedSubview(btn)
        }

        toolbar.snp.makeConstraints { make in
            make.top.equalTo(canvas.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(36)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }
    }

    // MARK: - Page 3: Stats

    private func buildStatsArtwork(accentColor: UIColor) {
        // Summary
        let sumLabel = makeLabel("32.5 km", size: 22, weight: .bold, color: ColorSystem.mainText)
        let periodLabel = makeLabel("  This Month", size: 13, weight: .medium, color: ColorSystem.subText)

        let topStack = UIStackView(arrangedSubviews: [sumLabel, periodLabel])
        topStack.axis = .horizontal
        topStack.alignment = .lastBaseline
        containerView.addSubview(topStack)
        contentViews.append(topStack)
        topStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(18)
        }

        // Chart area
        let chartContainer = UIView()
        chartContainer.backgroundColor = ColorSystem.cardBackground
        chartContainer.layer.cornerRadius = 14
        chartContainer.layer.borderWidth = 1
        chartContainer.layer.borderColor = ColorSystem.divider.cgColor
        containerView.addSubview(chartContainer)
        contentViews.append(chartContainer)

        let barHeights: [CGFloat] = [0.7, 0.85, 0.4, 0.95, 0.6, 0.3, 0.5]
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        let colors = [ColorSystem.primaryBlue, ColorSystem.primaryGreen]

        let barsStack = UIStackView()
        barsStack.axis = .horizontal
        barsStack.distribution = .fillEqually
        barsStack.spacing = 6
        barsStack.alignment = .bottom
        chartContainer.addSubview(barsStack)

        let labelsStack = UIStackView()
        labelsStack.axis = .horizontal
        labelsStack.distribution = .fillEqually
        labelsStack.spacing = 6
        chartContainer.addSubview(labelsStack)

        let maxBarHeight: CGFloat = 90

        for (i, ratio) in barHeights.enumerated() {
            // Bar
            let barWrapper = UIView()
            let bar = UIView()
            bar.backgroundColor = colors[i % 2]
            bar.layer.cornerRadius = 4
            bar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            barWrapper.addSubview(bar)
            bar.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(maxBarHeight * ratio)
            }
            barsStack.addArrangedSubview(barWrapper)

            // Day label
            let dayLabel = makeLabel(days[i], size: 10, weight: .medium, color: ColorSystem.subText)
            dayLabel.textAlignment = .center
            labelsStack.addArrangedSubview(dayLabel)
        }

        barsStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(maxBarHeight)
        }

        labelsStack.snp.makeConstraints { make in
            make.top.equalTo(barsStack.snp.bottom).offset(6)
            make.leading.trailing.equalTo(barsStack)
            make.bottom.equalToSuperview().inset(10)
        }

        chartContainer.snp.makeConstraints { make in
            make.top.equalTo(topStack.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        return label
    }
}

// MARK: - WalkthroughViewController

final class WalkthroughViewController: UIViewController {
    var onFinish: (() -> Void)?

    private let pages: [WalkthroughPage] = [
        WalkthroughPage(
            kind: .record,
            accentColor: ColorSystem.primaryBlue,
            titleKey: "walkthrough.page.record.title",
            descriptionKey: "walkthrough.page.record.description"
        ),
        WalkthroughPage(
            kind: .design,
            accentColor: ColorSystem.primaryGreen,
            titleKey: "walkthrough.page.design.title",
            descriptionKey: "walkthrough.page.design.description"
        ),
        WalkthroughPage(
            kind: .stats,
            accentColor: ColorSystem.info,
            titleKey: "walkthrough.page.stats.title",
            descriptionKey: "walkthrough.page.stats.description"
        )
    ]

    private var currentIndex = 0 {
        didSet {
            updateControlState()
        }
    }

    private let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.backgroundColor = .clear
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceVertical = false
        cv.register(WalkthroughPageCell.self, forCellWithReuseIdentifier: WalkthroughPageCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.setTitleColor(ColorSystem.subText, for: .normal)
        button.setTitle(NSLocalizedString("walkthrough.action.skip", comment: ""), for: .normal)
        return button
    }()

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = ColorSystem.primaryBlue
        control.pageIndicatorTintColor = ColorSystem.divider
        control.isUserInteractionEnabled = false
        return control
    }()

    private let primaryButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = ColorSystem.primaryBlue
        button.layer.cornerRadius = 14
        button.layer.masksToBounds = true
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateControlState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateItemSizeIfNeeded()
    }

    private func setupUI() {
        view.backgroundColor = ColorSystem.background
        isModalInPresentation = true

        skipButton.addTarget(self, action: #selector(didTapSkip), for: .touchUpInside)
        primaryButton.addTarget(self, action: #selector(didTapPrimary), for: .touchUpInside)

        pageControl.numberOfPages = pages.count

        view.addSubview(skipButton)
        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(primaryButton)

        skipButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().inset(20)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(skipButton.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top).offset(-12)
        }

        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(primaryButton.snp.top).offset(-18)
        }

        primaryButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.height.equalTo(52)
        }
    }

    private func updateItemSizeIfNeeded() {
        let targetSize = collectionView.bounds.size
        guard targetSize.width > 0, targetSize.height > 0 else { return }

        if flowLayout.itemSize != targetSize {
            flowLayout.itemSize = targetSize
            flowLayout.invalidateLayout()
            scrollToPage(currentIndex, animated: false)
        }
    }

    private func updateControlState() {
        pageControl.currentPage = currentIndex

        let isLastPage = currentIndex == pages.count - 1
        let primaryKey = isLastPage ? "walkthrough.action.start" : "walkthrough.action.next"
        primaryButton.setTitle(NSLocalizedString(primaryKey, comment: ""), for: .normal)
        skipButton.isHidden = isLastPage
    }

    private func scrollToPage(_ index: Int, animated: Bool) {
        guard pages.indices.contains(index) else { return }

        currentIndex = index
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }

    private func syncCurrentIndexFromContentOffset() {
        let width = max(collectionView.bounds.width, 1)
        let page = Int(round(collectionView.contentOffset.x / width))
        let clamped = min(max(page, 0), pages.count - 1)
        if clamped != currentIndex {
            currentIndex = clamped
        }
    }

    @objc private func didTapSkip() {
        finishWalkthrough()
    }

    @objc private func didTapPrimary() {
        let nextIndex = currentIndex + 1
        if pages.indices.contains(nextIndex) {
            scrollToPage(nextIndex, animated: true)
        } else {
            finishWalkthrough()
        }
    }

    private func finishWalkthrough() {
        if let onFinish {
            onFinish()
        } else {
            dismiss(animated: true)
        }
    }
}

extension WalkthroughViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WalkthroughPageCell.reuseIdentifier,
            for: indexPath
        ) as? WalkthroughPageCell else {
            return UICollectionViewCell()
        }

        cell.configure(page: pages[indexPath.item])
        return cell
    }
}

extension WalkthroughViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncCurrentIndexFromContentOffset()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            syncCurrentIndexFromContentOffset()
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncCurrentIndexFromContentOffset()
    }
}

// MARK: - WalkthroughPageCell

private final class WalkthroughPageCell: UICollectionViewCell {
    static let reuseIdentifier = "WalkthroughPageCell"

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSystem.divider.cgColor
        return view
    }()

    private let artworkView = WalkthroughArtworkView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textColor = ColorSystem.mainText
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = ColorSystem.subText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(page: WalkthroughPage) {
        artworkView.configure(kind: page.kind, accentColor: page.accentColor)
        titleLabel.text = NSLocalizedString(page.titleKey, comment: "")
        descriptionLabel.text = NSLocalizedString(page.descriptionKey, comment: "")
    }

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(artworkView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(descriptionLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        }

        artworkView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(260)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.lessThanOrEqualToSuperview().inset(32)
        }
    }
}
