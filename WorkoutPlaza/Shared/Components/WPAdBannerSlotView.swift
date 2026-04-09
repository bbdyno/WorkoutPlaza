//
//  WPAdBannerSlotView.swift
//  WorkoutPlaza
//
//  Created by Codex on 4/9/26.
//

import UIKit
import SnapKit

final class WPAdBannerSlotView: UIView {
    let placement: AdPlacement

    private let cardView: UIView = {
        let view = UIView()
        WPSurface.apply(to: view, style: .muted, cornerRadius: WPDesign.Radius.md)
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodySemiBold(13)
        label.textColor = ColorSystem.mainText
        label.text = NSLocalizedString("ads.slot.title", comment: "")
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body(12)
        label.textColor = ColorSystem.subText
        label.numberOfLines = 2
        return label
    }()

    private let tagLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodyBold(10)
        label.textColor = ColorSystem.background
        label.backgroundColor = ColorSystem.mainText
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.text = "AD"
        return label
    }()

    init(placement: AdPlacement) {
        self.placement = placement
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult
    func refreshState() -> CGFloat {
        let height = AdManager.shared.preferredHeight(for: placement)
        isHidden = height == 0

        guard height > 0 else {
            return 0
        }

        if let debugMessage = AdManager.shared.debugMessage(for: placement) {
            subtitleLabel.text = "\(placement.placeholderSubtitle)\n\(debugMessage)"
        } else {
            subtitleLabel.text = placement.placeholderSubtitle
        }

        return height
    }

    private func setupUI() {
        addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(tagLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tagLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(14)
            make.width.equalTo(34)
            make.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.trailing.lessThanOrEqualTo(tagLabel.snp.leading).offset(-8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(14)
            make.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().inset(14)
        }
    }
}
