// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("ScalarFormat")
struct ScalarFormatTests {
    @Test("[Unit][VOX-DAT-009][VOX-DAT-010] exposes exact scalar metadata")
    func exposesScalarMetadata() {
        let expected:
            [(
                type: ScalarType,
                rawValue: String,
                byteCount: Int,
                isSignedInteger: Bool,
                isInteger: Bool,
                range: ScalarValueRange
            )] = [
                (.int8, "int8", 1, true, true, .signedInteger(-128...127)),
                (.uint8, "uint8", 1, false, true, .unsignedInteger(0...255)),
                (.int16, "int16", 2, true, true, .signedInteger(-32_768...32_767)),
                (.uint16, "uint16", 2, false, true, .unsignedInteger(0...65_535)),
                (
                    .int32,
                    "int32",
                    4,
                    true,
                    true,
                    .signedInteger(Int64(Int32.min)...Int64(Int32.max))
                ),
                (
                    .uint32,
                    "uint32",
                    4,
                    false,
                    true,
                    .unsignedInteger(UInt64(UInt32.min)...UInt64(UInt32.max))
                ),
                (.int64, "int64", 8, true, true, .signedInteger(Int64.min...Int64.max)),
                (
                    .uint64,
                    "uint64",
                    8,
                    false,
                    true,
                    .unsignedInteger(UInt64.min...UInt64.max)
                ),
                (
                    .float16,
                    "float16",
                    2,
                    false,
                    false,
                    .floatingPoint(
                        (-Double(Float16.greatestFiniteMagnitude))...Double(
                            Float16.greatestFiniteMagnitude
                        )
                    )
                ),
                (
                    .float32,
                    "float32",
                    4,
                    false,
                    false,
                    .floatingPoint(
                        (-Double(Float.greatestFiniteMagnitude))...Double(
                            Float.greatestFiniteMagnitude
                        )
                    )
                ),
                (
                    .float64,
                    "float64",
                    8,
                    false,
                    false,
                    .floatingPoint(
                        (-Double.greatestFiniteMagnitude)...Double.greatestFiniteMagnitude
                    )
                ),
            ]

        #expect(ScalarType.allCases.count == 11)
        for scalar in expected {
            #expect(scalar.type.rawValue == scalar.rawValue)
            #expect(scalar.type.byteCount == scalar.byteCount)
            #expect(scalar.type.bitCount == scalar.byteCount * 8)
            #expect(scalar.type.isSignedInteger == scalar.isSignedInteger)
            #expect(scalar.type.isInteger == scalar.isInteger)
            #expect(scalar.type.isFloatingPoint == !scalar.isInteger)
            #expect(scalar.type.supportsNonFiniteValues == !scalar.isInteger)
            #expect(scalar.type.validValueRange == scalar.range)
        }
    }

    @Test("[Unit][VOX-DAT-010] accepts valid bit-count boundaries")
    func acceptsValidBitCounts() throws {
        for type in ScalarType.allCases {
            let unspecified = try ScalarFormat(
                type: type,
                validBitCount: nil,
                byteOrder: .native
            )
            let oneBit = try ScalarFormat(
                type: type,
                validBitCount: 1,
                byteOrder: .littleEndian
            )
            let fullWidth = try ScalarFormat(
                type: type,
                validBitCount: type.bitCount,
                byteOrder: .bigEndian
            )

            #expect(unspecified.validBitCount == nil)
            #expect(oneBit.validBitCount == 1)
            #expect(fullWidth.validBitCount == type.bitCount)
        }
    }

    @Test("[Unit][VOX-DAT-010][VOX-ERR-001] rejects invalid bit counts")
    func rejectsInvalidBitCounts() {
        for type in ScalarType.allCases {
            #expect(throws: DataModelError.invalidScalarFormat) {
                try ScalarFormat(type: type, validBitCount: 0, byteOrder: .native)
            }
            #expect(throws: DataModelError.invalidScalarFormat) {
                try ScalarFormat(type: type, validBitCount: -1, byteOrder: .native)
            }
            #expect(throws: DataModelError.invalidScalarFormat) {
                try ScalarFormat(
                    type: type,
                    validBitCount: type.bitCount + 1,
                    byteOrder: .native
                )
            }
        }
    }

    @Test("[Unit][VOX-API-004] preserves explicit format metadata through Codable")
    func codableRoundTrip() throws {
        let formats = [
            try ScalarFormat(type: .int16, validBitCount: nil, byteOrder: .native),
            try ScalarFormat(type: .int16, validBitCount: 16, byteOrder: .littleEndian),
            try ScalarFormat(type: .float32, validBitCount: 24, byteOrder: .bigEndian),
        ]

        for format in formats {
            let encoded = try JSONEncoder().encode(format)
            let decoded = try JSONDecoder().decode(ScalarFormat.self, from: encoded)

            #expect(decoded == format)
        }
    }

    @Test("[Unit][VOX-API-004] ByteOrder has stable raw and Codable values")
    func byteOrderRoundTrip() throws {
        let byteOrders: [ByteOrder] = [.native, .littleEndian, .bigEndian]

        #expect(
            byteOrders.map(\.rawValue) == [
                "native", "littleEndian", "bigEndian",
            ])

        for byteOrder in byteOrders {
            let encoded = try JSONEncoder().encode(byteOrder)
            let decoded = try JSONDecoder().decode(ByteOrder.self, from: encoded)

            #expect(decoded == byteOrder)
        }
    }

    @Test("[Unit][VOX-DAT-010][VOX-ERR-001] decoding rejects an invalid bit count")
    func decodingRejectsInvalidBitCount() {
        let invalidFormat = Data(
            #"{"type":"uint16","validBitCount":17,"byteOrder":"native"}"#.utf8
        )

        do {
            _ = try JSONDecoder().decode(ScalarFormat.self, from: invalidFormat)
            #expect(Bool(false), "Expected invalid validBitCount to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.last?.stringValue == "validBitCount")
            #expect(
                context.underlyingError as? DataModelError
                    == .invalidScalarFormat
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }
}
