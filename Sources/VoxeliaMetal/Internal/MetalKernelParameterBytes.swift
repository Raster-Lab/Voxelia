// SPDX-License-Identifier: MIT

/// One payload-free failure from checked Metal scalar serialization.
enum MetalKernelParameterBytesError: Error, Sendable, Equatable {
    case invalidWordCount
    case byteCountOverflow
}

/// Serializes MSL-compatible 32-bit scalar words without borrowing Swift
/// object or collection storage layouts.
enum MetalKernelParameterBytes {
    static func byteCount(forWordCount wordCount: Int) throws -> Int {
        guard wordCount >= 0 else {
            throw MetalKernelParameterBytesError.invalidWordCount
        }
        let (byteCount, overflow) = wordCount.multipliedReportingOverflow(by: 4)
        guard !overflow else {
            throw MetalKernelParameterBytesError.byteCountOverflow
        }
        return byteCount
    }

    static func littleEndianWords(_ words: [UInt32]) throws -> [UInt8] {
        let byteCount = try byteCount(forWordCount: words.count)
        var bytes = [UInt8]()
        bytes.reserveCapacity(byteCount)
        for word in words {
            bytes.append(UInt8(truncatingIfNeeded: word))
            bytes.append(UInt8(truncatingIfNeeded: word >> 8))
            bytes.append(UInt8(truncatingIfNeeded: word >> 16))
            bytes.append(UInt8(truncatingIfNeeded: word >> 24))
        }
        return bytes
    }
}
