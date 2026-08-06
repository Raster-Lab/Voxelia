// SPDX-License-Identifier: MIT

/// An error raised while using a caller-provided decode destination.
public enum DecodeDestinationError: Error, Sendable, Equatable {
    /// The requested capacity is not positive.
    case invalidCapacity
    /// The payload's declared decoded bytes exceed this destination's capacity.
    case capacityExceeded
    /// The bytes offered differ from the length the destination was prepared for.
    case offeredByteCountMismatch
}

/// A caller-owned, reusable destination for decoded samples, per `ADR-0260`
/// (`VOX-CMP-008`).
///
/// ## What "reusable" means here, and what it cannot mean yet
///
/// `VOX-CMP-008` requires the decode path to support caller-provided or reusable
/// destination storage **"where the codec API permits it"**. That qualifier is
/// load-bearing, and this type is built to respect it rather than to assume it away.
///
/// What is built and verified: a destination the caller allocates once, whose
/// capacity is admitted against a payload's declared size **before** any decode, and
/// which can be filled repeatedly without reallocating. A test observes the capacity
/// surviving across fills and the contents being replaced.
///
/// What **cannot** be verified yet: whether any Raster-Lab codec accepts a
/// caller-provided destination at all. No codec is linked (`ADR-0255`), so the
/// question is unanswerable here — and the project already has a precedent for the
/// answer being no. `ADR-0235` found that DICOMKit's pixel surface returns an owned
/// `Data` with no entry point taking a destination, which made `ADR-0230`
/// decision 10's direct-write model unimplementable. **The same may prove true of
/// the codecs**, in which case this destination serves reuse on Voxelia's side of the
/// boundary and one copy per decode remains, exactly as `ADR-0235` concluded for
/// frames.
///
/// Recording that in advance is the point: the alternative is discovering it when a
/// codec is finally linked and having a record that reads as though direct decode
/// into this buffer were established.
///
/// ## Value semantics, deliberately
///
/// This is a `struct`, so "reuse" means the caller keeps and re-prepares one value
/// rather than sharing a mutable buffer across concurrent decodes. A shared mutable
/// destination would need an ownership story the arc has no requirement for, and the
/// project's concurrency policy admits no escape hatch to fake one.
public struct DecodeDestination: Sendable, Hashable {
    /// The bytes this destination can hold.
    public let capacity: Int

    /// The bytes currently held, which is empty until a fill.
    public private(set) var bytes: ContiguousArray<UInt8>

    /// The length the destination is currently prepared for, or `nil` before any
    /// preparation.
    public private(set) var preparedByteCount: Int?

    /// Creates a destination able to hold `capacity` bytes.
    ///
    /// - Throws: ``DecodeDestinationError/invalidCapacity``.
    public init(capacity: Int) throws {
        guard capacity >= 1 else {
            throw DecodeDestinationError.invalidCapacity
        }
        self.capacity = capacity
        self.bytes = []
        self.preparedByteCount = nil
    }

    /// Admits `payload` against this destination's capacity and records the length
    /// the next fill must supply.
    ///
    /// Separate from ``fill(with:)`` so the capacity refusal happens **before** a
    /// decode runs, which is the same ordering `ADR-0258` decision 1 established
    /// for the validator's ceiling.
    ///
    /// - Throws: ``DecodeDestinationError/capacityExceeded``.
    public mutating func prepare(for payload: CompressedPayload) throws {
        guard payload.declaredDecodedByteCount <= capacity else {
            throw DecodeDestinationError.capacityExceeded
        }
        preparedByteCount = payload.declaredDecodedByteCount
        bytes.removeAll(keepingCapacity: true)
    }

    /// Fills the destination with decoded bytes.
    ///
    /// The offered length must equal what ``prepare(for:)`` recorded. A destination
    /// that accepted a different length would be the partial-fill hazard
    /// `VOX-CMP-009` forbids, arriving by a different route.
    ///
    /// - Throws: ``DecodeDestinationError/offeredByteCountMismatch``.
    public mutating func fill(with decoded: some Collection<UInt8>) throws {
        guard decoded.count == preparedByteCount else {
            throw DecodeDestinationError.offeredByteCountMismatch
        }
        bytes.removeAll(keepingCapacity: true)
        bytes.append(contentsOf: decoded)
    }

    /// Whether the destination currently holds exactly what it was prepared for.
    public var isComplete: Bool {
        guard let preparedByteCount else { return false }
        return bytes.count == preparedByteCount
    }
}
