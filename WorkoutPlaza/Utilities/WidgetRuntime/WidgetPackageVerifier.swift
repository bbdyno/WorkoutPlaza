//
//  WidgetPackageVerifier.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 2/9/26.
//

import CryptoKit
import Foundation

actor WidgetPackageVerifier {
    static let shared = WidgetPackageVerifier()

    private init() {}

    private var trustedSignatureTokens: Set<String> = []

    func setTrustedSignatureTokens(_ tokens: Set<String>) {
        trustedSignatureTokens = tokens
    }

    func verify(package: WidgetPackage) -> WidgetPackageVerificationReport {
        var messages: [String] = []

        if let minVersion = package.manifest.minimumAppVersion,
           !isCompatible(appVersion: currentAppVersion(), minimumVersion: minVersion) {
            messages.append("Requires app version \(minVersion)+")
            return WidgetPackageVerificationReport(trustLevel: .invalid, messages: messages)
        }

        if let checksums = package.manifest.templateChecksums {
            let checksumResult = verifyTemplateChecksums(package: package, checksums: checksums)
            if !checksumResult.isValid {
                return WidgetPackageVerificationReport(trustLevel: .invalid, messages: checksumResult.messages)
            }
            messages.append(contentsOf: checksumResult.messages)
        } else {
            messages.append("Template checksums are not provided.")
        }

        guard let signature = package.manifest.signature, !signature.isEmpty else {
            messages.append("Unsigned package.")
            return WidgetPackageVerificationReport(trustLevel: .unverified, messages: messages)
        }

        if trustedSignatureTokens.contains(signature) {
            messages.append("Trusted signature token matched.")
            return WidgetPackageVerificationReport(trustLevel: .trusted, messages: messages)
        }

        let manifestDigest = manifestDigestString(for: package.manifest)
        if signature == manifestDigest {
            messages.append("Manifest digest signature matched.")
            return WidgetPackageVerificationReport(trustLevel: .signed, messages: messages)
        }

        messages.append("Unknown signature token.")
        return WidgetPackageVerificationReport(trustLevel: .signed, messages: messages)
    }

    private func verifyTemplateChecksums(
        package: WidgetPackage,
        checksums: [String: String]
    ) -> WidgetPackageVerificationReport {
        var messages: [String] = []

        for template in package.templates {
            guard let expected = checksums[template.id] else {
                continue
            }
            guard let data = try? Self.stableEncoder.encode(template) else {
                return WidgetPackageVerificationReport(
                    trustLevel: .invalid,
                    messages: ["Failed to encode template \(template.id) for checksum verification."]
                )
            }
            let digest = SHA256.hash(data: data).hexString
            if digest != expected {
                return WidgetPackageVerificationReport(
                    trustLevel: .invalid,
                    messages: ["Checksum mismatch for template \(template.id)."]
                )
            }
            messages.append("Checksum verified: \(template.id)")
        }

        return WidgetPackageVerificationReport(trustLevel: .unverified, messages: messages)
    }

    private func manifestDigestString(for manifest: WidgetPackageManifest) -> String {
        guard let data = try? Self.stableEncoder.encode(manifest) else { return "" }
        return SHA256.hash(data: data).hexString
    }

    private func currentAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    private func isCompatible(appVersion: String, minimumVersion: String) -> Bool {
        appVersion.compare(minimumVersion, options: .numeric) != .orderedAscending
    }

    private static let stableEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}

private extension Digest {
    var hexString: String {
        self.map { String(format: "%02x", $0) }.joined()
    }
}
