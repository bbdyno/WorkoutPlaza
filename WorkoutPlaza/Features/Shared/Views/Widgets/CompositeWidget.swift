//
//  CompositeWidget.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import UIKit

protocol CompositeWidgetDelegate: AnyObject {
    func compositeWidgetDidRequestEdit(_ widget: CompositeWidget)
}

struct CompositeWidgetPayload: Codable, Equatable {
    var title: String
    var primaryText: String
    var secondaryText: String

    static let `default` = CompositeWidgetPayload(
        title: WorkoutPlazaStrings.Widget.composite,
        primaryText: WorkoutPlazaStrings.Text.Input.placeholder,
        secondaryText: ""
    )
}

class CompositeWidget: BaseStatWidget {
    weak var compositeDelegate: CompositeWidgetDelegate?
    private(set) var payload: CompositeWidgetPayload = .default

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDoubleTapGesture()
        configure(payload: .default)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)

        if let tapGesture = gestureRecognizers?.first(where: {
            guard let tap = $0 as? UITapGestureRecognizer else { return false }
            return tap.numberOfTapsRequired == 1
        }) {
            tapGesture.require(toFail: doubleTapGesture)
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        compositeDelegate?.compositeWidgetDidRequestEdit(self)
    }

    func configure(payload: CompositeWidgetPayload) {
        self.payload = payload
        titleLabel.text = payload.title
        valueLabel.text = payload.primaryText
        unitLabel.text = payload.secondaryText
    }

    func updatePayload(_ payload: CompositeWidgetPayload) {
        configure(payload: payload)
    }

    func encodedPayloadString() -> String? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func payload(from rawValue: String?) -> CompositeWidgetPayload? {
        guard let rawValue,
              let data = rawValue.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(CompositeWidgetPayload.self, from: data)
    }
}
