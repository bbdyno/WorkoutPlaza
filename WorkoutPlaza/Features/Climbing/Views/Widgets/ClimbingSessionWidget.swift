//
//  ClimbingSessionWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/27/26.
//

import UIKit
import SnapKit

// MARK: - Session Summary Widget

class ClimbingSessionWidget: BaseStatWidget {
    private var sentCount: Int = 0
    private var totalCount: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "세션 기록"
        unitLabel.text = "완등"
        itemIdentifier = "climbing_session_\(UUID().uuidString)"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(sent: Int, total: Int) {
        self.sentCount = sent
        self.totalCount = total
        valueLabel.text = "\(sent)/\(total)"
    }

    var idealSize: CGSize {
        layoutIfNeeded()

        let titleSize = titleLabel.intrinsicContentSize
        let valueSize = valueLabel.intrinsicContentSize
        let unitSize = unitLabel.intrinsicContentSize

        let contentWidth = max(titleSize.width, valueSize.width + 4 + unitSize.width)
        let width = contentWidth + 24 // Padding

        let height = 12 + titleSize.height + 4 + valueSize.height + 12

        return CGSize(width: max(width, 100), height: max(height, 60))
    }
}
