//
//  InAppBrowserViewController+Input.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import WebKit
import PhotosUI
import UniformTypeIdentifiers

// MARK: - UITextFieldDelegate

extension InAppBrowserViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = webView.url?.absoluteString ?? viewModel.addressText(showsFullURL: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let rawInput = textField.text ?? ""
        textField.resignFirstResponder()

        guard let url = viewModel.normalizedURL(from: rawInput, allowsInsecureHTTP: browserConfiguration.allowsInsecureHTTP) else {
            showSimpleAlert(
                title: WorkoutPlazaStrings.Browser.Invalid.Address.title,
                message: WorkoutPlazaStrings.Browser.Invalid.Address.message
            )
            return false
        }

        if isAllowedHost(for: url) == false {
            showBlockedDomainAlert(host: url.host ?? url.absoluteString)
            return false
        }

        load(url: url)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = viewModel.addressText(showsFullURL: isShowingFullURL)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension InAppBrowserViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            guard results.isEmpty == false else {
                self.finishOpenPanel(with: nil)
                return
            }

            let group = DispatchGroup()
            var urls: [URL] = []

            for result in results {
                let provider = result.itemProvider
                guard let typeIdentifier = provider.registeredTypeIdentifiers.first else { continue }

                group.enter()
                provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] sourceURL, _ in
                    defer { group.leave() }
                    guard let self, let sourceURL else { return }

                    let extensionName = sourceURL.pathExtension.isEmpty ? "dat" : sourceURL.pathExtension
                    let destination = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(extensionName)

                    do {
                        if FileManager.default.fileExists(atPath: destination.path) {
                            try FileManager.default.removeItem(at: destination)
                        }
                        try FileManager.default.copyItem(at: sourceURL, to: destination)
                        self.temporaryUploadFiles.append(destination)
                        urls.append(destination)
                    } catch {
                        WPLog.error("Failed to copy picked file:", error.localizedDescription)
                    }
                }
            }

            group.notify(queue: .main) {
                self.finishOpenPanel(with: urls.isEmpty ? nil : urls)
            }
        }
    }
}

// MARK: - UIDocumentPickerDelegate

extension InAppBrowserViewController: UIDocumentPickerDelegate {

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        finishOpenPanel(with: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard urls.isEmpty == false else {
            finishOpenPanel(with: nil)
            return
        }

        let copiedURLs: [URL] = urls.compactMap { sourceURL in
            let extensionName = sourceURL.pathExtension.isEmpty ? "dat" : sourceURL.pathExtension
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(extensionName)

            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: sourceURL, to: destination)
                temporaryUploadFiles.append(destination)
                return destination
            } catch {
                WPLog.error("Failed to copy selected document:", error.localizedDescription)
                return nil
            }
        }

        finishOpenPanel(with: copiedURLs.isEmpty ? nil : copiedURLs)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension InAppBrowserViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.finishOpenPanel(with: nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }

            if let mediaURL = info[.mediaURL] as? URL {
                let destination = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(mediaURL.pathExtension.isEmpty ? "mov" : mediaURL.pathExtension)
                do {
                    try FileManager.default.copyItem(at: mediaURL, to: destination)
                    self.temporaryUploadFiles.append(destination)
                    self.finishOpenPanel(with: [destination])
                    return
                } catch {
                    WPLog.error("Failed to copy camera media:", error.localizedDescription)
                }
            }

            guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.9) else {
                self.finishOpenPanel(with: nil)
                return
            }

            do {
                let tempFile = try self.createTemporaryFile(data: data, preferredExtension: "jpg")
                self.finishOpenPanel(with: [tempFile])
            } catch {
                WPLog.error("Failed to create temporary image file:", error.localizedDescription)
                self.finishOpenPanel(with: nil)
            }
        }
    }
}

// MARK: - Upload Presenters

extension InAppBrowserViewController {

    func presentPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = openPanelAllowsMultipleSelection ? 0 : 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func presentCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            finishOpenPanel(with: nil)
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        present(picker, animated: true)
    }

    func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.allowsMultipleSelection = openPanelAllowsMultipleSelection
        picker.delegate = self
        present(picker, animated: true)
    }
}
