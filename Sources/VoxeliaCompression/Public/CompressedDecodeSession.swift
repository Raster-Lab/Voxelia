// SPDX-License-Identifier: MIT

import VoxeliaCore

/// One named cancellation site in a decode, frozen by `ADR-0259`.
///
/// The sites are the stages this session actually performs, in order. No
/// checkpoint is claimed for work the session does not do — the same discipline
/// `ADR-0249` decision 5 applied to the import session.
public enum CompressedDecodeCheckpoint: Sendable, Equatable {
    /// Before the destination ceiling is admitted.
    case destination
    /// Before the codec is asked to decode.
    ///
    /// The last site at which cancellation costs nothing: past here, the decode
    /// has already run and its work is spent whether or not the result is used.
    case decode
    /// After the decode returns, before its report is validated.
    case validation
    /// The last site, immediately before the samples are returned.
    ///
    /// `ADR-0249` decision 7's shape: a caller cannot publish what it never
    /// receives, so checking here is what makes "no partial data published as
    /// complete" structural rather than a rule the caller must remember.
    case final
}

/// The injected cancellation probe for a decode.
///
/// A probe rather than a direct `Task.isCancelled` read, so a test can cancel
/// deterministically at one checkpoint instead of racing. This is `ADR-0249`'s
/// accepted shape, reused rather than reinvented.
public typealias CompressedDecodeCancellationProbe =
    @Sendable (CompressedDecodeCheckpoint) -> Bool

/// An error raised while running a decode session.
///
/// Payload-free, for the reason `ADR-0258` gives: the input that provokes these
/// refusals should learn nothing.
public enum CompressedDecodeSessionError: Error, Sendable, Equatable {
    /// The probe reported cancellation at one of the named checkpoints.
    case cancelled

    /// The decode reported a byte count that disagrees with the bytes it returned.
    ///
    /// Distinct from ``CompressedDecodeError/decodedByteCountMismatch``, which
    /// compares a *report* against a payload's declarations. This case catches a
    /// report that disagrees with **itself** — a decode claiming forty-eight bytes
    /// while returning forty. `ADR-0259` records why the validator alone could not
    /// catch it.
    case reportedByteCountDisagreesWithBytes
}

/// One decode's samples and the report that was admitted with them.
///
/// Returned only when every check passed and no checkpoint cancelled, so holding
/// this value is itself the evidence that the decode was complete.
public struct DecodedSamples: Sendable, Hashable {
    /// The decoded sample bytes.
    public let bytes: ContiguousArray<UInt8>

    /// The decode's own admitted report.
    public let claim: DecodedSampleClaim
}

/// A cancellable, validating decode session per `ADR-0259` (`VOX-CMP-009`).
///
/// It is **source-agnostic**: the decode itself is a caller-supplied closure, so
/// the session is testable with and without a real codec — the shape `ADR-0249`
/// used for the import session and `ADR-0258` used for the validator.
///
/// **The closure is `async`, and that was a correction rather than foresight.**
/// `ADR-0259` first declared it synchronous, because the tests that shaped it
/// supplied bytes synchronously. Reading `J2KSwift`'s API before declaring the
/// dependency showed `JP3DDecoder.decode(_:)` is `async throws`, so a synchronous
/// closure could not host a real codec at all. `ADR-0267` records the correction.
/// A synchronous closure still satisfies an `async` parameter, so no caller had to
/// change its closure — but every call site now awaits, which the existing tests
/// did have to adopt. Stated precisely because the first version of this note
/// claimed nothing changed, and that was wrong.
///
/// Cancellation is honoured at every ``CompressedDecodeCheckpoint`` and always by
/// the same rule: throw ``CompressedDecodeSessionError/cancelled`` and return
/// nothing. **A cancelled decode publishes nothing because it produces nothing to
/// publish**, which is the half of `VOX-CMP-009` that says partial data must never
/// be published as complete output.
public enum CompressedDecodeSession {
    /// Decodes one payload, cancellably, validating the result before returning it.
    ///
    /// - Parameters:
    ///   - payload: the payload to decode.
    ///   - maximumDecodedByteCount: the largest destination the caller will hold.
    ///   - decode: performs the decode, returning the bytes and the codec's report.
    ///   - cancellation: the probe consulted at every checkpoint.
    /// - Throws: ``CompressedDecodeSessionError``, ``CompressedDecodeError``, or
    ///   whatever `decode` throws.
    public static func decode(
        payload: CompressedPayload,
        maximumDecodedByteCount: Int,
        decode: (CompressedPayload) async throws -> DecodedSamples,
        cancellation: CompressedDecodeCancellationProbe
    ) async throws -> DecodedSamples {
        // Stage: the destination ceiling, before any allocation.
        if cancellation(.destination) {
            throw CompressedDecodeSessionError.cancelled
        }
        try CompressedDecodeValidator.admitDestination(
            for: payload,
            maximumDecodedByteCount: maximumDecodedByteCount
        )

        // Stage: the decode. This is the last checkpoint at which cancellation
        // costs nothing, so it is checked immediately before the call rather than
        // after it.
        if cancellation(.decode) {
            throw CompressedDecodeSessionError.cancelled
        }
        let produced = try await decode(payload)

        // Stage: validation. The decode's report is checked against itself first,
        // then against the payload's declarations.
        if cancellation(.validation) {
            throw CompressedDecodeSessionError.cancelled
        }
        guard produced.claim.byteCount == produced.bytes.count else {
            throw CompressedDecodeSessionError.reportedByteCountDisagreesWithBytes
        }
        try CompressedDecodeValidator.admit(produced.claim, against: payload)

        // The last checkpoint, before the caller receives anything usable.
        if cancellation(.final) {
            throw CompressedDecodeSessionError.cancelled
        }
        return produced
    }
}
