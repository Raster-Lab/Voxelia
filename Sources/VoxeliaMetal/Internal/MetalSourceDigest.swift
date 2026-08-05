// SPDX-License-Identifier: MIT

import CryptoKit

/// Checked deterministic source-digest text shared by every Metal kernel.
enum MetalSourceDigest {
    /// Returns the lowercase hexadecimal SHA-256 digest of exact UTF-8 text.
    static func sha256HexText(_ source: String) -> String {
        let digits = Array("0123456789abcdef".utf8)
        var text = [UInt8]()
        text.reserveCapacity(64)
        for byte in SHA256.hash(data: Array(source.utf8)) {
            text.append(digits[Int(byte >> 4)])
            text.append(digits[Int(byte & 0xF)])
        }
        return String(decoding: text, as: UTF8.self)
    }
}
