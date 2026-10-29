//
//  Encrypt.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 10/29/26.
//

import Foundation
import CryptoKit
import CommonCrypto

func encrypt(_ password: String) -> Data? {
    guard let keyBytes = deriveAES256Key(password: password) else {
        return nil
    }

    let derivedKey = Data(keyBytes)
    print("Derived AES key: " + (keyBytes.map {String(format: "%02X", $0)}.joined(separator: " ")))

    return derivedKey
}

private func deriveAES256Key(password: String) -> [UInt8]? {
    let iterations: UInt32 = 600_000
    let keyLength = 32
    let salt = [UInt8](repeating: 0, count: 16)
    let passwordBytes = Array(password.utf8)

    var derivedKey = [UInt8](repeating: 0, count: keyLength)

    let status = passwordBytes.withUnsafeBytes { passwordBuffer in
        salt.withUnsafeBytes { saltBuffer in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                passwordBuffer.baseAddress!
                    .assumingMemoryBound(to: Int8.self),
                passwordBytes.count,
                saltBuffer.baseAddress!
                    .assumingMemoryBound(to: UInt8.self),
                salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                iterations,
                &derivedKey,
                keyLength
            )
        }
    }

    guard status == kCCSuccess else {
        print("PBKDF2 failed with status: \(status)")
        return nil
    }

    return derivedKey
}

