// SPDX-License-Identifier: MIT

import VoxeliaCore

/// Re-encodes narrowed stored samples as full-width containers, per `ADR-0239`.
///
/// ## Why this exists
///
/// When Bits Stored is narrower than Bits Allocated, a published
/// `ImageDescriptor` has two available declarations and both fail. Declaring
/// `validBitCount` accurately is **refused** by accepted operations — nothing in
/// the project masks by it. Declaring `nil` is accepted and is **wrong for signed
/// data**: a raw `0x0FFF` reads as `4095` where the sample means `-1`.
///
/// Normalising the samples resolves it: the bytes are re-encoded so the container
/// really does hold a full-width value, and `nil` becomes a truthful declaration.
///
/// ## What this is not
///
/// A **re-encoding, not an interpretation**. No rescale is applied, no padding is
/// excluded and no real value is produced — the same stored integer is rewritten
/// at the container's width. Value interpretation stays in
/// ``CTValueInterpreter``, and the byte transfer stays ignorant of signedness as
/// `ADR-0235` decision 2 requires.
///
/// ## Evidence
///
/// The defining property — reading a normalised container at full width yields the
/// same stored value as reading the original at its narrower width — is verified
/// **exhaustively** rather than by fixtures: every 8-bit and 16-bit container
/// value, every Bits Stored width, both signedness choices, 2,101,248 cases, zero
/// failures. Where a space is small enough to enumerate, enumerating it is
/// stronger evidence than sampling it.
public struct CTSampleNormalisation: Sendable, Hashable {
    /// Bytes per sample container.
    public let byteCount: Int
    /// Meaningful bits within the container.
    public let storedBitCount: Int
    /// Whether the stored value is signed.
    public let isSigned: Bool

    /// Whether normalisation would leave every sample unchanged.
    ///
    /// True exactly when the stored bit count equals the container width, which is
    /// verified to be a no-op for every value of both supported container widths
    /// and both signedness choices. A full-width series therefore pays nothing:
    /// callers skip the pass entirely.
    public var isIdentity: Bool { storedBitCount == byteCount * 8 }

    /// Creates a normalisation for a scalar format.
    ///
    /// - Throws: ``CTValueInterpretationError/unsupportedScalarFormat`` for a
    ///   non-integer format, and
    ///   ``CTValueInterpretationError/invalidStoredBitCount`` when the meaningful
    ///   bit count does not fit the container.
    public init(scalarFormat: ScalarFormat) throws {
        guard scalarFormat.type.isInteger else {
            throw CTValueInterpretationError.unsupportedScalarFormat
        }
        let containerBits = scalarFormat.type.bitCount
        let storedBits = scalarFormat.validBitCount ?? containerBits
        guard storedBits >= 1, storedBits <= containerBits else {
            throw CTValueInterpretationError.invalidStoredBitCount
        }
        self.byteCount = scalarFormat.type.byteCount
        self.storedBitCount = storedBits
        self.isSigned = scalarFormat.type.isSignedInteger
    }

    /// The scalar format a normalised buffer should be described by.
    ///
    /// The container width is unchanged and the meaningful-bit narrowing is
    /// dropped, because after normalisation it is no longer true. This is the
    /// declaration `ADR-0239` makes truthful.
    public static func normalisedFormat(
        from scalarFormat: ScalarFormat
    ) throws -> ScalarFormat {
        try ScalarFormat(
            type: scalarFormat.type,
            validBitCount: nil,
            byteOrder: scalarFormat.byteOrder
        )
    }

    /// Re-encodes one frame's little-endian sample bytes as full-width containers.
    ///
    /// - Returns: the re-encoded bytes, or `nil` when the input length is not a
    ///   whole number of containers. Returns the input unchanged when
    ///   ``isIdentity``.
    public func normalise(
        frameBytes: some Collection<UInt8>
    ) -> ContiguousArray<UInt8>? {
        guard frameBytes.count % byteCount == 0 else { return nil }
        var result = ContiguousArray<UInt8>()
        result.reserveCapacity(frameBytes.count)
        if isIdentity {
            result.append(contentsOf: frameBytes)
            return result
        }

        let mask: UInt64 = (1 << UInt64(storedBitCount)) - 1
        let signBit: UInt64 = 1 << UInt64(storedBitCount - 1)
        let containerMask: UInt64 =
            byteCount == 8 ? .max : (1 << UInt64(byteCount * 8)) - 1

        var container: UInt64 = 0
        var shift: UInt64 = 0
        var position = 0
        for byte in frameBytes {
            container |= UInt64(byte) << shift
            shift += 8
            position += 1
            guard position == byteCount else { continue }

            var value = container & mask
            if isSigned, value & signBit != 0 {
                // Two's complement truncation to the container width: the sign
                // extension made permanent in the bytes.
                value = (value &- (1 << UInt64(storedBitCount))) & containerMask
            }
            for index in 0..<byteCount {
                result.append(UInt8((value >> UInt64(8 * index)) & 0xFF))
            }
            container = 0
            shift = 0
            position = 0
        }
        return result
    }
}
