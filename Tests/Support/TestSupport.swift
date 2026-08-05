// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaValidation

package enum VoxeliaTestSupport {
    package static let scaffoldRequirement = "VOX-REP-001"

    /// Returns one exact lowercase, zero-padded 16-digit hexadecimal word.
    package static func lowercaseHex16(_ value: UInt64) -> String {
        let digits = Array("0123456789abcdef".utf8)
        var bytes = [UInt8](repeating: 0, count: 16)
        var remaining = value
        for index in bytes.indices.reversed() {
            bytes[index] = digits[Int(remaining & 0xF)]
            remaining >>= 4
        }
        return String(decoding: bytes, as: UTF8.self)
    }
}
