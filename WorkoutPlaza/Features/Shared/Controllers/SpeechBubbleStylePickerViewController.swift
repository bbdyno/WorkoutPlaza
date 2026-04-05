//
//  SpeechBubbleStylePickerViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/5/26.
//

import UIKit
import SnapKit

// MARK: - Delegate

protocol SpeechBubbleStylePickerDelegate: AnyObject {
    func stylePickerDidSelect(style: SpeechBubbleStyle)
}

// MARK: - View Controller

final class SpeechBubbleStylePickerViewController: UIViewController {

    weak var delegate: SpeechBubbleStylePickerDelegate?

    // MARK: - UI

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 32, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = ColorSystem.background
        cv.register(StyleCell.self, forCellWithReuseIdentifier: StyleCell.reuseID)
        return cv
    }()

    private let styles = SpeechBubbleStyle.allCases

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("bubble.picker.title", comment: "말풍선 선택")
        view.backgroundColor = ColorSystem.background

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    // MARK: - Actions

    @objc private func cancelTapped() { dismiss(animated: true) }

    private func handleSelection(of style: SpeechBubbleStyle) {
        guard !style.isProRequired || PurchaseManager.shared.isEffectivelyPro else {
            showProGate()
            return
        }
        dismiss(animated: true) { [weak self] in
            self?.delegate?.stylePickerDidSelect(style: style)
        }
    }

    private func showProGate() {
        let proVC = ProUpgradeViewController()
        proVC.triggerFeature = "speech_bubble_style"
        let nav = UINavigationController(rootViewController: proVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension SpeechBubbleStylePickerViewController: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        styles.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: StyleCell.reuseID, for: indexPath) as! StyleCell
        cell.configure(style: styles[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension SpeechBubbleStylePickerViewController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        handleSelection(of: styles[indexPath.item])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SpeechBubbleStylePickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let inset: CGFloat = 16
        let spacing: CGFloat = 12
        let width = (cv.bounds.width - inset * 2 - spacing) / 2
        return CGSize(width: width, height: width * 0.80)
    }
}

// MARK: - StyleCell

private final class StyleCell: UICollectionViewCell {
    static let reuseID = "StyleCell"

    // MARK: UI

    private let previewView: SpeechBubbleWidget = {
        let w = SpeechBubbleWidget()
        w.isUserInteractionEnabled = false
        return w
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = ColorSystem.mainText
        l.textAlignment = .center
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        return l
    }()

    private let lockBadge: UILabel = {
        let l = UILabel()
        l.text = "👑"
        l.font = .systemFont(ofSize: 14)
        l.isHidden = true
        return l
    }()

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        v.layer.cornerRadius = 12
        v.isHidden = true
        return v
    }()

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = ColorSystem.cardBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        contentView.addSubview(previewView)
        contentView.addSubview(dimView)
        contentView.addSubview(lockBadge)
        contentView.addSubview(nameLabel)

        previewView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalTo(nameLabel.snp.top).offset(-6)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(6)
            make.bottom.equalToSuperview().inset(8)
            make.height.equalTo(16)
        }

        dimView.snp.makeConstraints { $0.edges.equalTo(previewView) }

        lockBadge.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.trailing.equalToSuperview().inset(6)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Configure

    func configure(style: SpeechBubbleStyle) {
        let sampleText: String = {
            let lang = Locale.current.language.languageCode?.identifier ?? "en"
            switch style {
            case .shoutBubble:
                return lang == "ko" ? "와!" : "Wow!"
            case .thoughtBubble:
                return lang == "ko" ? "오늘도..." : "Hmm..."
            default:
                return lang == "ko" ? "오늘도 달렸다!" : "Great run!"
            }
        }()

        let isPro = style.isProRequired
        let hasAccess = !isPro || PurchaseManager.shared.isEffectivelyPro

        let payload = SpeechBubblePayload(
            text: sampleText,
            style: style,
            bubbleColorHex: "#FFFFFF",
            borderColorHex: "#222222",
            borderWidth: 2,
            textColorHex: "#111111",
            fontStyleRaw: FontStyle.system.rawValue,
            fontSize: 13
        )

        previewView.configure(payload: payload)
        nameLabel.text = style.displayName
        dimView.isHidden = hasAccess
        lockBadge.isHidden = hasAccess
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // initialSize를 레이아웃 후 설정
        if previewView.initialSize == .zero, previewView.bounds.size != .zero {
            previewView.initialSize = previewView.bounds.size
        }
    }
}
