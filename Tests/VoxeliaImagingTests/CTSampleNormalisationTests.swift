// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaImaging

/// Verifies `ADR-0239`'s normalisation.
///
/// The central test is **exhaustive**, mirroring the recorded Python verification:
/// every 8-bit and 16-bit container value, every stored-bit width, both signedness
/// choices. Where a space is small enough to enumerate, enumerating it is stronger
/// evidence than sampling it.
@Suite("CTSampleNormalisation")
struct CTSampleNormalisationTests {
    private func format(_ type: ScalarType, _ storedBits: Int?) throws -> ScalarFormat {
        try ScalarFormat(type: type, validBitCount: storedBits, byteOrder: .littleEndian)
    }

    private func bytes(_ container: UInt64, _ byteCount: Int) -> [UInt8] {
        (0..<byteCount).map { UInt8((container >> UInt64(8 * $0)) & 0xFF) }
    }

    private func container(_ raw: some Collection<UInt8>) -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        for byte in raw {
            result |= UInt64(byte) << shift
            shift += 8
        }
        return result
    }

    // MARK: - The exhaustive property

    @Test("[Unit] Normalising then reading at full width preserves every stored value")
    func exhaustiveProperty() throws {
        var checked = 0
        for (type, wideType) in [(ScalarType.uint8, ScalarType.uint8), (.int8, .int8)] {
            _ = wideType
            let containerBits = type.bitCount
            for storedBits in 1...containerBits {
                let narrow = try CTSampleNormalisation(
                    scalarFormat: try format(type, storedBits == containerBits ? nil : storedBits)
                )
                let narrowInterpreter = try CTValueInterpreter(
                    scalarFormat: try format(type, storedBits == containerBits ? nil : storedBits),
                    slope: 1.0,
                    intercept: 0.0,
                    paddingValue: nil
                )
                let wideInterpreter = try CTValueInterpreter(
                    scalarFormat: try format(type, nil),
                    slope: 1.0,
                    intercept: 0.0,
                    paddingValue: nil
                )
                for raw in 0..<(UInt64(1) << UInt64(containerBits)) {
                    let source = bytes(raw, narrow.byteCount)
                    let expected = narrowInterpreter.storedValue(container: raw)
                    let normalised = try #require(narrow.normalise(frameBytes: source))
                    let actual = wideInterpreter.storedValue(
                        container: container(normalised)
                    )
                    #expect(actual == expected)
                    checked += 1
                }
            }
        }
        // 8-bit containers: 8 widths x 256 values x 2 signs.
        #expect(checked == 8 * 256 * 2)
    }

    @Test("[Unit] The same property holds exhaustively for sixteen-bit containers")
    func exhaustiveSixteenBit() throws {
        var checked = 0
        for type in [ScalarType.uint16, ScalarType.int16] {
            let containerBits = type.bitCount
            for storedBits in 1...containerBits {
                let declared = storedBits == containerBits ? nil : storedBits
                let narrow = try CTSampleNormalisation(
                    scalarFormat: try format(type, declared)
                )
                let narrowInterpreter = try CTValueInterpreter(
                    scalarFormat: try format(type, declared),
                    slope: 1.0,
                    intercept: 0.0,
                    paddingValue: nil
                )
                let wideInterpreter = try CTValueInterpreter(
                    scalarFormat: try format(type, nil),
                    slope: 1.0,
                    intercept: 0.0,
                    paddingValue: nil
                )
                for raw in 0..<(UInt64(1) << UInt64(containerBits)) {
                    let expected = narrowInterpreter.storedValue(container: raw)
                    let normalised = try #require(
                        narrow.normalise(frameBytes: bytes(raw, narrow.byteCount))
                    )
                    #expect(
                        wideInterpreter.storedValue(container: container(normalised))
                            == expected
                    )
                    checked += 1
                }
            }
        }
        #expect(checked == 16 * 65536 * 2)
    }

    // MARK: - The identity case, which is the measured corpus

    @Test("[Unit] Normalisation is the identity at full width, for every value")
    func identityAtFullWidth() throws {
        for type in [ScalarType.uint8, .int8, .uint16, .int16] {
            let subject = try CTSampleNormalisation(scalarFormat: try format(type, nil))
            #expect(subject.isIdentity)
            for raw in 0..<(UInt64(1) << UInt64(type.bitCount)) {
                let source = bytes(raw, subject.byteCount)
                #expect(Array(try #require(subject.normalise(frameBytes: source))) == source)
            }
        }
    }

    @Test("[Unit] A narrowed format is not the identity")
    func narrowedIsNotIdentity() throws {
        #expect(!(try CTSampleNormalisation(scalarFormat: try format(.int16, 12)).isIdentity))
        #expect(try CTSampleNormalisation(scalarFormat: try format(.int16, 16)).isIdentity)
    }

    // MARK: - Worked examples from the record

    @Test(
        "[Unit] The record's worked examples",
        arguments: [
            // raw, storedBits, signed, expected container
            (UInt64(0x0FFF), 12, true, UInt64(0xFFFF)),
            (UInt64(0x0FFF), 12, false, UInt64(0x0FFF)),
            (UInt64(0xFFFF), 12, false, UInt64(0x0FFF)),
            (UInt64(0x0800), 12, true, UInt64(0xF800)),
            (UInt64(0x0001), 1, true, UInt64(0xFFFF)),
        ]
    )
    func workedExamples(
        _ raw: UInt64,
        _ storedBits: Int,
        _ signed: Bool,
        _ expected: UInt64
    ) throws {
        let subject = try CTSampleNormalisation(
            scalarFormat: try format(signed ? .int16 : .uint16, storedBits)
        )
        let normalised = try #require(subject.normalise(frameBytes: bytes(raw, 2)))
        #expect(container(normalised) == expected)
    }

    // MARK: - Multi-sample frames and admission

    @Test("[Unit] A multi-sample frame normalises every container independently")
    func multiSampleFrame() throws {
        let subject = try CTSampleNormalisation(scalarFormat: try format(.int16, 12))
        // 0x0FFF -> -1 -> 0xFFFF, 0x0001 -> 1 -> 0x0001, 0x0800 -> -2048 -> 0xF800
        let source: [UInt8] = [0xFF, 0x0F, 0x01, 0x00, 0x00, 0x08]
        let normalised = try #require(subject.normalise(frameBytes: source))
        #expect(Array(normalised) == [0xFF, 0xFF, 0x01, 0x00, 0x00, 0xF8])
    }

    @Test("[Unit] A partial container is refused rather than padded")
    func partialContainerRefused() throws {
        let subject = try CTSampleNormalisation(scalarFormat: try format(.int16, 12))
        #expect(subject.normalise(frameBytes: [0x01] as [UInt8]) == nil)
        #expect(subject.normalise(frameBytes: [0x01, 0x02, 0x03] as [UInt8]) == nil)
        #expect(subject.normalise(frameBytes: [] as [UInt8])?.isEmpty == true)
    }

    @Test("[Unit] The normalised format drops the narrowing, which is what makes nil true")
    func normalisedFormatDropsNarrowing() throws {
        let source = try format(.int16, 12)
        let result = try CTSampleNormalisation.normalisedFormat(from: source)
        #expect(result.validBitCount == nil)
        #expect(result.type == .int16)
        #expect(result.byteOrder == source.byteOrder)
    }

    @Test("[Unit] A floating-point format is refused")
    func refusesFloatingPoint() throws {
        #expect(throws: CTValueInterpretationError.unsupportedScalarFormat) {
            try CTSampleNormalisation(scalarFormat: try format(.float32, nil))
        }
    }
}
