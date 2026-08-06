// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while admitting a decode against its payload's declarations.
///
/// Payload-free: a refused decode discloses neither the declared nor the observed
/// figure, because the input that provokes these refusals is exactly the input
/// that should learn nothing.
public enum CompressedDecodeError: Error, Sendable, Equatable {
    /// The declared decoded byte count exceeds the caller's ceiling.
    ///
    /// Raised **before** a decode is attempted, so no allocation is made for a
    /// shape the caller never agreed to hold.
    case declaredByteCountExceedsCeiling
    /// The caller supplied a non-positive ceiling.
    case invalidCeiling
    /// The decode returned a different number of bytes than the declarations imply.
    case decodedByteCountMismatch
    /// The decode reported different extents than were declared.
    case decodedExtentsMismatch
    /// The decode reported a different scalar format than was declared.
    case decodedScalarFormatMismatch
    /// The decode reported a different component count than was declared.
    case decodedComponentCountMismatch
}

/// What a decode reports about the samples it produced.
///
/// A value rather than a codec call, so the validation is testable without a codec
/// — the same source-agnostic shape `ADR-0249` used for the import session. A codec
/// adapter fills this in from whatever its API reports.
public struct DecodedSampleClaim: Sendable, Hashable {
    /// The number of sample bytes the decode produced.
    public let byteCount: Int

    /// The extents the decode reports, in image-axis order.
    public let extents: ContiguousArray<Int>

    /// The scalar format the decode reports.
    public let scalarFormat: ScalarFormat

    /// The components per sample the decode reports.
    public let componentCount: Int

    public init(
        byteCount: Int,
        extents: ContiguousArray<Int>,
        scalarFormat: ScalarFormat,
        componentCount: Int
    ) {
        self.byteCount = byteCount
        self.extents = extents
        self.scalarFormat = scalarFormat
        self.componentCount = componentCount
    }
}

/// Validates a decode against its payload's declarations, per `ADR-0258`
/// (`VOX-CMP-010`).
///
/// ## Two checks at two different times, and the order is the point
///
/// 1. ``admitDestination(for:maximumDecodedByteCount:)`` runs **before** a decode.
///    It is what stops a hostile or corrupt declared shape from causing Voxelia to
///    allocate a destination the caller never agreed to hold.
/// 2. ``admit(_:against:)`` runs **after** a decode, comparing every declared
///    quantity against what came back.
///
/// A caller that only ran the second check would already have allocated.
///
/// ## What this narrows of `VOX-CMP-011`, and what it does not
///
/// `ADR-0255` recorded that `VOX-CMP-011` — bounded failure on malformed or
/// adversarial codestreams — is **not fully achievable adapter-side**, because a
/// codestream cannot be validated without parsing it and parsing is the codec's
/// job.
///
/// The ceiling here is the real, bounded part of that: Voxelia's own allocation is
/// bounded by a figure the caller states, so a declared shape of a terabyte is
/// refused before any buffer exists. **It does not bound the codec.** If a codec
/// allocates from the codestream's own internal headers, or faults on malformed
/// input, nothing in this file prevents it. That residual exposure stays open and
/// stays the owner's to reconcile; it is not narrowed by being unmentioned.
public enum CompressedDecodeValidator {
    /// Admits a payload's declared shape against a caller-stated ceiling, before
    /// any decode.
    ///
    /// - Parameters:
    ///   - payload: the payload about to be decoded.
    ///   - maximumDecodedByteCount: the largest destination the caller will hold.
    /// - Throws: ``CompressedDecodeError/invalidCeiling`` or
    ///   ``CompressedDecodeError/declaredByteCountExceedsCeiling``.
    public static func admitDestination(
        for payload: CompressedPayload,
        maximumDecodedByteCount: Int
    ) throws {
        guard maximumDecodedByteCount >= 1 else {
            throw CompressedDecodeError.invalidCeiling
        }
        guard payload.declaredDecodedByteCount <= maximumDecodedByteCount else {
            throw CompressedDecodeError.declaredByteCountExceedsCeiling
        }
    }

    /// Admits a decode's own report against the payload's declarations.
    ///
    /// Every comparison is **exact equality**. There is no tolerance to apply: a
    /// decoded byte count is a count, extents are counts, and a scalar format and
    /// component count are discrete. A near-miss on any of them is a disagreement
    /// about what the data *is*, not a rounding difference.
    ///
    /// The checks run dimensions first, then component format, then byte count,
    /// so the most specific disagreement is the one reported: a byte-count
    /// mismatch caused by wrong extents should surface as the extents mismatch it
    /// is.
    ///
    /// - Throws: ``CompressedDecodeError``.
    public static func admit(
        _ decoded: DecodedSampleClaim,
        against payload: CompressedPayload
    ) throws {
        guard decoded.extents == payload.declaredExtents else {
            throw CompressedDecodeError.decodedExtentsMismatch
        }
        guard decoded.componentCount == payload.declaredComponentCount else {
            throw CompressedDecodeError.decodedComponentCountMismatch
        }
        guard decoded.scalarFormat == payload.declaredScalarFormat else {
            throw CompressedDecodeError.decodedScalarFormatMismatch
        }
        guard decoded.byteCount == payload.declaredDecodedByteCount else {
            throw CompressedDecodeError.decodedByteCountMismatch
        }
    }
}
