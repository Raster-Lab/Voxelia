// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaImaging

/// Verifies `ct-value-interpretation/binary64-v1` against every frozen fixture of
/// `VOXELIA-ALG-0051`. Measured values are asserted as hexadecimal float
/// literals.
@Suite("CTValueInterpreter")
struct CTValueInterpreterTests {
    private func interpreter(
        _ type: ScalarType,
        storedBits: Int? = nil,
        slope: Double = 1.0,
        intercept: Double = 0.0,
        padding: Int64? = nil
    ) throws -> CTValueInterpreter {
        try CTValueInterpreter(
            scalarFormat: try ScalarFormat(
                type: type,
                validBitCount: storedBits,
                byteOrder: .littleEndian
            ),
            slope: slope,
            intercept: intercept,
            paddingValue: padding
        )
    }

    private func measured(_ value: CTInterpretedValue?) throws -> Double {
        guard case .measured(let real) = try #require(value) else {
            Issue.record("expected a measured value, got \(String(describing: value))")
            return .nan
        }
        return real
    }

    // MARK: - V1, V2: the two scanner conventions reach the same value

    @Test("V1 signed samples with a zero intercept give -1000 HU for air")
    func v1SignedAir() throws {
        let subject = try interpreter(.int16)
        let value = subject.interpret(sampleBytes: [0x18, 0xFC] as [UInt8])
        #expect(subject.storedValue(container: 0xFC18) == -1000)
        #expect(try measured(value) == -0x1.f4p+9)
    }

    @Test("V2 unsigned samples with a -1024 intercept give the same -1000 HU")
    func v2UnsignedAir() throws {
        // ADR-0235's real-data run found this scanner emits unsigned samples, so
        // this is the route the measured corpus actually exercises.
        let subject = try interpreter(.uint16, intercept: -1024.0)
        let value = subject.interpret(sampleBytes: [0x18, 0x00] as [UInt8])
        #expect(subject.storedValue(container: 0x0018) == 24)
        #expect(try measured(value) == -0x1.f4p+9)
    }

    // MARK: - V3 to V7: sign extension and masking

    @Test("V3 a twelve-bit signed 0x0FFF is minus one, not 4095")
    func v3SignExtension() throws {
        let subject = try interpreter(.int16, storedBits: 12)
        #expect(subject.storedValue(container: 0x0FFF) == -1)
        #expect(try measured(subject.interpret(sampleBytes: [0xFF, 0x0F] as [UInt8])) == -0x1p+0)
    }

    @Test("V4 a twelve-bit signed 0x0800 is the most negative value")
    func v4MostNegative() throws {
        let subject = try interpreter(.int16, storedBits: 12)
        #expect(subject.storedValue(container: 0x0800) == -2048)
        #expect(try measured(subject.interpret(sampleBytes: [0x00, 0x08] as [UInt8])) == -0x1p+11)
    }

    @Test("V5 a twelve-bit signed 0x07FF is the most positive value")
    func v5MostPositive() throws {
        let subject = try interpreter(.int16, storedBits: 12)
        #expect(subject.storedValue(container: 0x07FF) == 2047)
        #expect(
            try measured(subject.interpret(sampleBytes: [0xFF, 0x07] as [UInt8]))
                == 0x1.ffcp+10
        )
    }

    @Test("V6 the same bits unsigned are 4095: the boundary V3 exists for")
    func v6UnsignedSameBits() throws {
        let subject = try interpreter(.uint16, storedBits: 12)
        #expect(subject.storedValue(container: 0x0FFF) == 4095)
        #expect(
            try measured(subject.interpret(sampleBytes: [0xFF, 0x0F] as [UInt8]))
                == 0x1.ffep+11
        )
        // Identical bytes, identical depth, opposite representation, 4096 apart.
        let signed = try interpreter(.int16, storedBits: 12)
        #expect(
            subject.storedValue(container: 0x0FFF)
                - signed.storedValue(container: 0x0FFF) == 4096
        )
    }

    @Test("V7 bits above the stored count are masked away")
    func v7Masking() throws {
        let subject = try interpreter(.uint16, storedBits: 12)
        #expect(subject.storedValue(container: 0xFFFF) == 4095)
        #expect(
            try measured(subject.interpret(sampleBytes: [0xFF, 0xFF] as [UInt8]))
                == 0x1.ffep+11
        )
    }

    // MARK: - V8, V14: the rescale

    @Test("V8 a non-unit slope scales before the intercept is added")
    func v8NonUnitSlope() throws {
        let subject = try interpreter(.uint16, slope: 2.5, intercept: -1024.0)
        #expect(
            try measured(subject.interpret(sampleBytes: [0x64, 0x00] as [UInt8]))
                == -0x1.83p+9
        )
    }

    @Test("V14 the rescale is genuinely binary64")
    func v14Binary64() throws {
        let subject = try interpreter(.uint16, slope: 0.1)
        // 0.1 * 3 is 0.30000000000000004, not 0.3.
        #expect(
            try measured(subject.interpret(sampleBytes: [0x03, 0x00] as [UInt8]))
                == 0x1.3333333333334p-2
        )
    }

    // MARK: - V9, V10: padding is compared before the rescale

    @Test("V9 a stored value matching padding is excluded")
    func v9PaddingExcluded() throws {
        let subject = try interpreter(.int16, intercept: -1024.0, padding: -2000)
        #expect(subject.interpret(sampleBytes: [0x30, 0xF8] as [UInt8]) == .padding)
    }

    @Test("V10 a value equal to padding only after rescale stays measured")
    func v10PaddingOrder() throws {
        // Stored 0, intercept -2000, padding -2000: the rescaled value equals the
        // padding number. Comparing after the rescale would delete real signal at
        // exactly one output value.
        let subject = try interpreter(.int16, intercept: -2000.0, padding: -2000)
        let value = subject.interpret(sampleBytes: [0x00, 0x00] as [UInt8])
        #expect(value != .padding)
        #expect(try measured(value) == -0x1.f4p+10)
    }

    // MARK: - V11: the zero slope, closing ADR-0227 decision 5

    @Test("V11 a zero slope is computed and reported, not refused")
    func v11DegenerateSlope() throws {
        let subject = try interpreter(.uint16, slope: 0.0, intercept: -1024.0)
        #expect(subject.findings == [.degenerateSlope])
        // Every value collapses to the intercept, and that is reported as a fact.
        #expect(
            try measured(subject.interpret(sampleBytes: [0x64, 0x00] as [UInt8]))
                == -0x1p+10
        )
        #expect(
            try measured(subject.interpret(sampleBytes: [0x00, 0x00] as [UInt8]))
                == -0x1p+10
        )
    }

    @Test("A non-zero slope reports no finding")
    func nonDegenerateSlope() throws {
        #expect(try interpreter(.uint16, slope: 1.0).findings.isEmpty)
        #expect(try interpreter(.uint16, slope: -1.0).findings.isEmpty)
    }

    // MARK: - V12, V13: eight-bit formats

    @Test("V12 an eight-bit unsigned sample")
    func v12EightBitUnsigned() throws {
        let subject = try interpreter(.uint8)
        #expect(subject.byteCount == 1)
        #expect(try measured(subject.interpret(sampleBytes: [0x7F] as [UInt8])) == 0x1.fcp+6)
    }

    @Test("V13 an eight-bit signed 0xFF is minus one")
    func v13EightBitSigned() throws {
        let subject = try interpreter(.int8)
        #expect(subject.storedValue(container: 0xFF) == -1)
        #expect(try measured(subject.interpret(sampleBytes: [0xFF] as [UInt8])) == -0x1p+0)
    }

    // MARK: - Admission

    @Test("A big-endian format is refused rather than reinterpreted")
    func refusesBigEndian() throws {
        #expect(throws: CTValueInterpretationError.unsupportedByteOrder) {
            try CTValueInterpreter(
                scalarFormat: try ScalarFormat(
                    type: .int16,
                    validBitCount: nil,
                    byteOrder: .bigEndian
                ),
                slope: 1.0,
                intercept: 0.0,
                paddingValue: nil
            )
        }
    }

    @Test("A floating-point format is refused")
    func refusesFloatingPoint() throws {
        #expect(throws: CTValueInterpretationError.unsupportedScalarFormat) {
            try interpreter(.float32)
        }
    }

    @Test("A non-finite rescale term is refused")
    func refusesNonFiniteTerms() throws {
        for slope in [Double.infinity, Double.nan] {
            #expect(throws: CTValueInterpretationError.nonFiniteRescaleTerm) {
                try interpreter(.int16, slope: slope)
            }
        }
        #expect(throws: CTValueInterpretationError.nonFiniteRescaleTerm) {
            try interpreter(.int16, intercept: -Double.infinity)
        }
    }

    @Test("A wrong byte count yields no value rather than a wrong one")
    func refusesWrongByteCount() throws {
        let subject = try interpreter(.int16)
        #expect(subject.interpret(sampleBytes: [0x01] as [UInt8]) == nil)
        #expect(subject.interpret(sampleBytes: [0x01, 0x02, 0x03] as [UInt8]) == nil)
        #expect(subject.container([] as [UInt8]) == nil)
    }

    @Test("An interpreter can be built straight from a frame description")
    func fromFrameDescription() throws {
        // Exercises the path the pipeline actually uses.
        let subject = try interpreter(.uint16, storedBits: 12, intercept: -1024.0)
        #expect(subject.storedBitCount == 12)
        #expect(!subject.isSigned)
        #expect(subject.intercept == -1024.0)
    }
}
