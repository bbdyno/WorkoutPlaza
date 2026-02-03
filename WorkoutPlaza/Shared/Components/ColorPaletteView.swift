//
//  ColorPaletteView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit

protocol ColorPaletteDelegate: AnyObject {
    func colorPalette(_ palette: ColorPaletteView, didSelectColor color: UIColor)
    func colorPaletteDidRequestDelete(_ palette: ColorPaletteView)
    func colorPaletteDidRequestFontChange(_ palette: ColorPaletteView)
}

class ColorPaletteView: UIView {
    private enum Constants {
        static let buttonSpacing: CGFloat = 12
        static let moreButtonWidth: CGFloat = 60
        static let actionButtonSize: CGFloat = 44
        static let actionButtonTrailingOffset: CGFloat = 16
        static let collectionViewTrailingOffset: CGFloat = 8
    }

    // MARK: - Properties
    weak var delegate: ColorPaletteDelegate?

    private let presetColors: [UIColor] = [
        .white,
        .black,
        ColorSystem.primaryBlue,
        ColorSystem.primaryGreen,
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemPurple,
        .systemPink,
        .systemIndigo
    ]

    private var collectionView: UICollectionView!
    private let moreButton = UIButton(type: .system)
    private let fontButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 8

        setupCollectionView()
        setupButtons()
        setupLayout()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ColorSwatchCell.self, forCellWithReuseIdentifier: "ColorSwatchCell")

        addSubview(collectionView)
    }

    private func setupButtons() {
        // More button
        moreButton.setTitle("더보기", for: .normal)
        moreButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
        addSubview(moreButton)

        // Font button
        fontButton.setImage(UIImage(systemName: "textformat"), for: .normal)
        fontButton.tintColor = .label
        fontButton.addTarget(self, action: #selector(fontButtonTapped), for: .touchUpInside)
        addSubview(fontButton)

        // Delete button
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        addSubview(deleteButton)
    }

    private func setupLayout() {
        collectionView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalTo(moreButton.snp.leading).offset(-Constants.collectionViewTrailingOffset)
        }

        moreButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(fontButton.snp.leading).offset(-Constants.buttonSpacing)
            make.width.equalTo(Constants.moreButtonWidth)
        }

        fontButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(deleteButton.snp.leading).offset(-Constants.buttonSpacing)
            make.size.equalTo(Constants.actionButtonSize)
        }

        deleteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.actionButtonTrailingOffset)
            make.size.equalTo(Constants.actionButtonSize)
        }
    }

    // MARK: - Actions
    @objc private func moreButtonTapped() {
        presentColorPicker()
    }

    @objc private func deleteButtonTapped() {
        delegate?.colorPaletteDidRequestDelete(self)
    }

    @objc private func fontButtonTapped() {
        delegate?.colorPaletteDidRequestFontChange(self)
    }

    private func presentColorPicker() {
        guard let viewController = findViewController() else { return }

        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        viewController.present(colorPicker, animated: true)
    }

    // MARK: - Animation
    func show(animated: Bool = true) {
        isHidden = false
        if animated {
            transform = CGAffineTransform(translationX: 0, y: 80)
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut],
                animations: {
                    self.transform = .identity
                },
                completion: nil
            )
        }
    }

    func hide(animated: Bool = true) {
        if animated {
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    self.transform = CGAffineTransform(translationX: 0, y: 80)
                },
                completion: { _ in
                    self.isHidden = true
                    self.transform = .identity
                }
            )
        } else {
            isHidden = true
        }
    }

    // MARK: - Button Visibility
    func setDeleteButtonEnabled(_ enabled: Bool) {
        deleteButton.isEnabled = enabled
        deleteButton.alpha = enabled ? 1.0 : 0.3
    }

    func setFontButtonEnabled(_ enabled: Bool) {
        fontButton.isEnabled = enabled
        fontButton.alpha = enabled ? 1.0 : 0.3
    }
}

// MARK: - UICollectionViewDataSource
extension ColorPaletteView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presetColors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorSwatchCell", for: indexPath) as! ColorSwatchCell
        cell.configure(with: presetColors[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ColorPaletteView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = presetColors[indexPath.item]
        delegate?.colorPalette(self, didSelectColor: color)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ColorPaletteView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 44, height: 44)
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension ColorPaletteView: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        delegate?.colorPalette(self, didSelectColor: color)
    }

    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        if !continuously {
            delegate?.colorPalette(self, didSelectColor: color)
        }
    }
}

// MARK: - Helper
extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

// MARK: - Color Swatch Cell
class ColorSwatchCell: UICollectionViewCell {
    private enum Constants {
        static let swatchSize: CGFloat = 32
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 1.5
        static let selectedBorderWidth: CGFloat = 2
    }

    private let colorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(colorView)
        colorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Constants.swatchSize)
        }

        colorView.layer.cornerRadius = Constants.cornerRadius
        colorView.layer.borderWidth = Constants.borderWidth
        colorView.layer.borderColor = ColorSystem.divider.cgColor
    }

    func configure(with color: UIColor) {
        colorView.backgroundColor = color

        // Add border for light colors
        if color == .white || color.isLight {
            colorView.layer.borderColor = ColorSystem.divider.cgColor
        } else {
            colorView.layer.borderColor = UIColor.clear.cgColor
        }
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                colorView.layer.borderColor = ColorSystem.primaryGreen.cgColor
                colorView.layer.borderWidth = Constants.selectedBorderWidth
            } else {
                if colorView.backgroundColor == .white || colorView.backgroundColor?.isLight == true {
                    colorView.layer.borderColor = ColorSystem.divider.cgColor
                } else {
                    colorView.layer.borderColor = UIColor.clear.cgColor
                }
                colorView.layer.borderWidth = Constants.borderWidth
            }
        }
    }
}
