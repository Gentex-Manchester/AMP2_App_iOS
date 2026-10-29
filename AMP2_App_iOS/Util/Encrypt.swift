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

    let key = SymmetricKey(data: Data(keyBytes))
    let plaintextData = Data(password.utf8)

    do {
        let sealedBox = try AES.GCM.seal(plaintextData, using: key)
        return sealedBox.combined
    } catch {
        print("Encryption failed: \(error)")
        return nil
    }
}

private func deriveAES256Key(password: String) -> [UInt8]? {
    let iterations = 600_000
    let keyLength = 32 // 256 bits = 32 bytes

    let salt = [UInt8](repeating: 0, count: 16)
    let passwordBytes = Array(password.utf8)

    var derivedKey = [UInt8](repeating: 0, count: keyLength)

    let status = passwordBytes.withUnsafeBytes { passwordBuffer in
        salt.withUnsafeBytes { saltBuffer in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                password,
                passwordBytes.count,
                saltBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                UInt32(iterations),
                &derivedKey,
                keyLength
            )
        }
    }

    guard status == kCCSuccess else {
        return nil
    }

    return derivedKey
}
