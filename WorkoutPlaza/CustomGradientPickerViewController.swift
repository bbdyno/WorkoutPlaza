//
//  CustomGradientPickerViewController.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 1/13/26.
//

import UIKit
import SnapKit

protocol CustomGradientPickerDelegate: AnyObject {
    func customGradientPicker(_ picker: CustomGradientPickerViewController, didSelectColors colors: [UIColor])
}

class CustomGradientPickerViewController: UIViewController {
    
    weak var delegate: CustomGradientPickerDelegate?
    
    private var startColor: UIColor = .systemBlue
    private var endColor: UIColor = .systemPurple
    
    private let previewView = BackgroundTemplateView()
    
    private let startColorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("시작 색상", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let endColorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("종료 색상", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("적용", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updatePreview()
    }
    
    private func setupUI() {
        title = "커스텀 그라데이션"
        view.backgroundColor = .systemBackground
        
        view.addSubview(previewView)
        view.addSubview(startColorButton)
        view.addSubview(endColorButton)
        view.addSubview(applyButton)
        
        previewView.layer.cornerRadius = 12
        previewView.clipsToBounds = true
        
        previewView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(300)
        }
        
        let buttonStack = UIStackView(arrangedSubviews: [startColorButton, endColorButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.distribution = .fillEqually
        
        view.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(previewView.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
        
        applyButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(buttonStack.snp.bottom).offset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.trailing.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
        
        startColorButton.addTarget(self, action: #selector(pickStartColor), for: .touchUpInside)
        endColorButton.addTarget(self, action: #selector(pickEndColor), for: .touchUpInside)
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
    }
    
    private func updatePreview() {
        previewView.applyCustomGradient(colors: [startColor, endColor])
        
        startColorButton.backgroundColor = startColor.withAlphaComponent(0.2)
        startColorButton.setTitleColor(startColor, for: .normal)
        
        endColorButton.backgroundColor = endColor.withAlphaComponent(0.2)
        endColorButton.setTitleColor(endColor, for: .normal)
    }
    
    @objc private func pickStartColor() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = startColor
        picker.delegate = self
        picker.view.tag = 1 // Tag 1 for start color
        present(picker, animated: true)
    }
    
    @objc private func pickEndColor() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = endColor
        picker.delegate = self
        picker.view.tag = 2 // Tag 2 for end color
        present(picker, animated: true)
    }
    
    @objc private func applyTapped() {
        delegate?.customGradientPicker(self, didSelectColors: [startColor, endColor])
        dismiss(animated: true)
    }
}

extension CustomGradientPickerViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if viewController.view.tag == 1 {
            startColor = viewController.selectedColor
        } else {
            endColor = viewController.selectedColor
        }
        updatePreview()
    }
}
