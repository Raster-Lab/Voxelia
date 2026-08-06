// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while admitting a ``CTValueInterpreter``.
///
/// Cases deliberately carry no payload, so a refusal never discloses sample
/// values or rescale terms in a diagnostic.
public enum CTValueInterpretationError: Error, Sendable, Equatable {
    /// The scalar format declares a byte order this stage does not claim.
    ///
    /// Only little-endian is implemented, because that is what
    /// `DICOMFrameAdapter` records. Another order is refused rather than
    /// reinterpreted.
    case unsupportedByteOrder
    /// The scalar format is not an integer format.
    case unsupportedScalarFormat
    /// The meaningful bit count exceeds the container or is below one.
    case invalidStoredBitCount
    /// A rescale term is not finite.
    case nonFiniteRescaleTerm
}

/// A fact observed about an interpretation's parameters.
public enum CTValueInterpretationFinding: Sendable, Hashable, CaseIterable {
    /// The rescale slope is exactly zero, so every sample maps to the intercept.
    ///
    /// Computed and reported rather than refused. `0 * x + b` is well defined and
    /// yields a constant volume: useless but not undefined. `ADR-0236` decision 6
    /// closes `ADR-0227` decision 5 this way, keeping this stage consistent with
    /// the rest of the arc, which measures and reports.
    case degenerateSlope
}

/// One interpreted CT sample.
///
/// A two-case enum rather than a sentinel: a NaN would propagate silently through
/// later arithmetic, and a magic number would collide with real Hounsfield values.
public enum CTInterpretedValue: Sendable, Hashable {
    /// A measured value in the rescaled output units.
    case measured(Double)
    /// The sample matched the declared pixel padding and carries no measurement.
    case padding
}

/// Converts stored CT samples into measured values, implementing
/// `ct-value-interpretation/binary64-v1` (`VOXELIA-ALG-0051`) for
/// `VOX-DCM-006` and `VOX-DCM-008`.
///
/// This is the stage four accepted records deferred value questions to. It
/// interprets **one sample at a time**: transforming a whole volume is a
/// performance-sensitive concern with its own trade-offs, and binding a
/// volume-wide representation here would decide that by accident.
///
/// Decoding is exact integer work — byte assembly, masking, sign extension — and
/// only the rescale is binary64. **The rescale is governed by
/// `VOXELIA-ALG-0003`**, in its frozen order `(x * scale) + offset` with no fused
/// multiply-add; `ADR-0237` records that `VOXELIA-ALG-0051` duplicated that
/// boundary and narrowed its authority to the decoding stages, which nothing else
/// in the project covers.
public struct CTValueInterpreter: Sendable, Hashable {
    /// Bytes per stored sample.
    public let byteCount: Int
    /// Meaningful bits within the container.
    public let storedBitCount: Int
    /// Whether the stored value is signed.
    public let isSigned: Bool
    /// The rescale slope.
    public let slope: Double
    /// The rescale intercept.
    public let intercept: Double
    /// The stored value denoting padding, when the source declared one.
    public let paddingValue: Int64?
    /// Facts observed about these parameters.
    public let findings: Set<CTValueInterpretationFinding>

    /// Creates an interpreter from a frame description's value terms.
    ///
    /// Admission happens once here, so every subsequent sample costs four integer
    /// operations and two floating-point ones with no re-validation.
    ///
    /// - Throws: ``CTValueInterpretationError``.
    public init(frame: CTFrameDescription) throws {
        try self.init(
            scalarFormat: frame.scalarFormat,
            slope: frame.rescaleSlope,
            intercept: frame.rescaleIntercept,
            paddingValue: frame.pixelPadding?.value
        )
    }

    /// Creates an interpreter from explicit terms.
    ///
    /// - Throws: ``CTValueInterpretationError``.
    public init(
        scalarFormat: ScalarFormat,
        slope: Double,
        intercept: Double,
        paddingValue: Int64?
    ) throws {
        guard scalarFormat.byteOrder == .littleEndian || scalarFormat.byteOrder == .native
        else {
            throw CTValueInterpretationError.unsupportedByteOrder
        }
        guard scalarFormat.type.isInteger else {
            throw CTValueInterpretationError.unsupportedScalarFormat
        }
        let containerBits = scalarFormat.type.bitCount
        let storedBits = scalarFormat.validBitCount ?? containerBits
        guard storedBits >= 1, storedBits <= containerBits else {
            throw CTValueInterpretationError.invalidStoredBitCount
        }
        guard slope.isFinite, intercept.isFinite else {
            throw CTValueInterpretationError.nonFiniteRescaleTerm
        }

        self.byteCount = scalarFormat.type.byteCount
        self.storedBitCount = storedBits
        self.isSigned = scalarFormat.type.isSignedInteger
        self.slope = slope
        self.intercept = intercept
        self.paddingValue = paddingValue
        self.findings = slope == 0 ? [.degenerateSlope] : []
    }

    /// Assembles a little-endian container from a sample's bytes.
    ///
    /// - Returns: `nil` when the collection does not hold exactly
    ///   ``byteCount`` bytes.
    public func container(_ sampleBytes: some Collection<UInt8>) -> UInt64? {
        guard sampleBytes.count == byteCount else { return nil }
        var result: UInt64 = 0
        var shift: UInt64 = 0
        for byte in sampleBytes {
            result |= UInt64(byte) << shift
            shift += 8
        }
        return result
    }

    /// The stored value in a container, masked to ``storedBitCount`` and sign
    /// extended when the format is signed.
    ///
    /// A twelve-bit signed `0x0FFF` is `-1`, not `4095`; the same bits unsigned
    /// are `4095`.
    public func storedValue(container: UInt64) -> Int64 {
        let mask: UInt64 = storedBitCount == 64 ? .max : (1 << UInt64(storedBitCount)) - 1
        let masked = container & mask
        guard isSigned, storedBitCount >= 1 else { return Int64(bitPattern: masked) }
        let signBit: UInt64 = 1 << UInt64(storedBitCount - 1)
        guard masked & signBit != 0 else { return Int64(bitPattern: masked) }
        let span: UInt64 = storedBitCount == 64 ? 0 : (1 << UInt64(storedBitCount))
        return Int64(bitPattern: masked &- span)
    }

    /// Interprets one stored value.
    ///
    /// Padding is compared on the **stored** value, before any rescale. A sample
    /// whose rescaled value happens to equal the padding number is a measured
    /// sample; treating it as padding would delete real signal at exactly one
    /// output value.
    public func interpret(storedValue value: Int64) -> CTInterpretedValue {
        if let paddingValue, value == paddingValue {
            return .padding
        }
        // Written in VOXELIA-ALG-0003's order -- (x * scale) + offset -- because
        // that accepted specification governs the rescale. ADR-0237 records that
        // VOXELIA-ALG-0051 restated the same boundary with the operands swapped,
        // and that the two agree bit-for-bit because IEEE-754 multiplication is
        // commutative, verified over every fixture and two million random cases.
        return .measured((Double(value) * slope) + intercept)
    }

    /// Interprets one sample from its bytes.
    ///
    /// - Returns: `nil` when the collection does not hold exactly ``byteCount``
    ///   bytes.
    public func interpret(sampleBytes: some Collection<UInt8>) -> CTInterpretedValue? {
        guard let raw = container(sampleBytes) else { return nil }
        return interpret(storedValue: storedValue(container: raw))
    }
}
