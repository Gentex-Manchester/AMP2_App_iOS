//
//  QRCodeCrypto.swift
//  AMP2_App_iOS
//
//  AES-256-GCM for QR payloads. Same key and layout as Android
//  `util/Crypto.kt` (docs/qr-contract.md). Unrelated to SQLCipher.
//

import Foundation
import CryptoKit

/// AES-256-GCM with a fixed XOR-obfuscated key, random 12-byte IV prepended,
/// 128-bit tag; output is unpadded URL-safe Base64 of `IV + ciphertext + tag`.
enum QRCodeCrypto {

    // MARK: - Threat Model
    //
    // The key ships in the binary, so this is deterrence only: it stops QR
    // scanner apps, not a decompiler. Accepted; see docs/threat-model.md.

    // MARK: - Constants

    /// Android `GCM_IV_LENGTH`.
    private static let gcmIVLength = 12

    /// Android `MASK`.
    private static let mask: [UInt8] = [0x42, 0x7A, 0x1C, 0x3F]

    /// Android `OBFUSCATED_KEY`.
    private static let obfuscatedKey: [UInt8] = [
        0x05, 0x49, 0x52, 0x53, 0x71, 0x0A, 0x43, 0x7C,
        0x72, 0x18, 0x2F, 0x20, 0x71, 0x16, 0x2D, 0x53,
        0x71, 0x25, 0x58, 0x0C, 0x23, 0x0F, 0x43, 0x6C,
        0x71, 0x19, 0x69, 0x55, 0x73, 0x0A, 0x65, 0x1E
    ]

    private static let secretKey: SymmetricKey = {
        let realKey = (0..<obfuscatedKey.count).map { i in
            obfuscatedKey[i] ^ mask[i % mask.count]
        }
        return SymmetricKey(data: Data(realKey))
    }()

    // MARK: - Public API

    /// Returns unpadded URL-safe Base64 of `IV + ciphertext + tag`.
    static func encrypt(_ plainText: String) throws -> String {
        guard let plainData = plainText.data(using: .utf8) else {
            throw CryptoError.invalidUTF8Input
        }

        let iv = try generateRandomIV()

        let sealedBox = try AES.GCM.seal(plainData, using: secretKey, nonce: AES.GCM.Nonce(data: iv))

        // Android's layout: IV + ciphertext + tag.
        var combined = Data()
        combined.append(iv)
        combined.append(sealedBox.ciphertext)
        combined.append(sealedBox.tag)

        return combined.base64EncodedStringNoPadding()
    }

    /// Reverses `encrypt(_:)`.
    static func decrypt(_ base64String: String) throws -> String {
        guard let combined = Data(base64EncodedStringPadded: base64String) else {
            throw CryptoError.invalidBase64Input
        }

        // IV + at least one ciphertext byte + 16-byte tag.
        guard combined.count >= gcmIVLength + 1 + 16 else {
            throw CryptoError.invalidCiphertextLength
        }

        let iv = combined.prefix(gcmIVLength)
        let tagEnd = combined.count
        let ciphertextEnd = tagEnd - 16
        let ciphertext = combined[gcmIVLength..<ciphertextEnd]
        let tag = combined[ciphertextEnd..<tagEnd]

        guard let nonce = try? AES.GCM.Nonce(data: iv) else {
            throw CryptoError.invalidIV
        }

        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        let decryptedData = try AES.GCM.open(sealedBox, using: secretKey)

        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.invalidUTF8Output
        }

        return decryptedString
    }

    // MARK: - Private Helpers

    private static func generateRandomIV() throws -> Data {
        var iv = Data(count: gcmIVLength)
        let result = iv.withUnsafeMutableBytes { ptr in
            SecRandomCopyBytes(kSecRandomDefault, gcmIVLength, ptr.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw CryptoError.randomIVGenerationFailed
        }
        return iv
    }

    // MARK: - Testing Support

    // Test-only. Never use in production code.
    static var testKey: SymmetricKey {
        secretKey
    }

    static var testObfuscatedKey: [UInt8] {
        obfuscatedKey
    }

    static var testMask: [UInt8] {
        mask
    }
}

// MARK: - Crypto Errors

enum CryptoError: Error, Equatable {
    case invalidUTF8Input
    case invalidBase64Input
    /// Too short to hold IV + ciphertext + tag.
    case invalidCiphertextLength
    case invalidIV
    case invalidUTF8Output
    case randomIVGenerationFailed
    /// Wrong key or tampered data.
    case authenticationFailure
}

extension CryptoError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUTF8Input:
            return "Failed to encode input as UTF-8."
        case .invalidBase64Input:
            return "Invalid QR code data. The code may be corrupted or from an incompatible app version."
        case .invalidCiphertextLength:
            return "QR code data is too short to be valid."
        case .invalidIV:
            return "QR code contains an invalid encryption IV."
        case .invalidUTF8Output:
            return "Decrypted data is not valid UTF-8."
        case .randomIVGenerationFailed:
            return "Failed to generate encryption IV."
        case .authenticationFailure:
            return "QR code decryption failed. The code may be corrupted or from a different app."
        }
    }
}

// MARK: - Base64 Extensions

extension Data {
    /// URL-safe Base64, no padding.
    func base64EncodedStringNoPadding() -> String {
        var encoded = self.base64EncodedString()
        encoded = encoded.replacingOccurrences(of: "+", with: "-")
        encoded = encoded.replacingOccurrences(of: "/", with: "_")
        encoded = encoded.trimmingCharacters(in: CharacterSet(charactersIn: "="))
        return encoded
    }
}

extension Data {
    /// Decodes URL-safe Base64, restoring any stripped padding.
    init?(base64EncodedStringPadded base64String: String) {
        var standard = base64String
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = standard.count % 4
        if remainder > 0 {
            standard.append(String(repeating: "=", count: 4 - remainder))
        }

        guard let data = Data(base64Encoded: standard) else {
            return nil
        }
        self = data
    }
}
