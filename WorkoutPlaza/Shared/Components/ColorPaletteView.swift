//
//  ColorPaletteView.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit

protocol ColorPaletteDelegate: AnyObject {
    func colorPalette(_ palette: ColorPaletteView, didSelectColor color: UIColor)
    func colorPaletteDidRequestDelete(_ palette: ColorPaletteView)
    func colorPaletteDidRequestFontChange(_ palette: ColorPaletteView)
}

class ColorPaletteView: UIView {

    // MARK: - Properties
    weak var delegate: ColorPaletteDelegate?

    private let presetColors: [UIColor] = [
        .white,
        .black,
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemGreen,
        .systemBlue,
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
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        fontButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Collection view
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -8),

            // More button
            moreButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: fontButton.leadingAnchor, constant: -12),
            moreButton.widthAnchor.constraint(equalToConstant: 60),

            // Font button
            fontButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            fontButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -12),
            fontButton.widthAnchor.constraint(equalToConstant: 44),
            fontButton.heightAnchor.constraint(equalToConstant: 44),

            // Delete button
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
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
        colorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 44),
            colorView.heightAnchor.constraint(equalToConstant: 44)
        ])

        colorView.layer.cornerRadius = 22
        colorView.layer.borderWidth = 2
        colorView.layer.borderColor = UIColor.systemGray4.cgColor
    }

    func configure(with color: UIColor) {
        colorView.backgroundColor = color

        // Add border for light colors
        if color == .white {
            colorView.layer.borderColor = UIColor.systemGray4.cgColor
        } else {
            colorView.layer.borderColor = UIColor.clear.cgColor
        }
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                colorView.layer.borderColor = UIColor.systemBlue.cgColor
                colorView.layer.borderWidth = 3
            } else {
                if colorView.backgroundColor == .white {
                    colorView.layer.borderColor = UIColor.systemGray4.cgColor
                } else {
                    colorView.layer.borderColor = UIColor.clear.cgColor
                }
                colorView.layer.borderWidth = 2
            }
        }
    }
}
