// SPDX-License-Identifier: MIT

/// An error raised while writing a frame's samples into a volume buffer.
///
/// Cases deliberately carry no payload, so a refused write never discloses
/// extents or offsets in a diagnostic.
public enum CTVolumeByteBufferError: Error, Sendable, Equatable {
    /// The placement was admitted against a different layout than the buffer's.
    case layoutMismatch
    /// The supplied frame does not hold exactly one slice's worth of bytes.
    case frameByteCountMismatch
    /// The destination range would fall outside the buffer.
    ///
    /// Unreachable when the two checks above pass, and retained anyway: it is the
    /// one check standing between a wrong layout and an out-of-range write, and a
    /// write is where being wrong is unrecoverable. `ADR-0235` decision 5 records
    /// why this one is checked rather than argued.
    case destinationOutOfRange
}

/// A volume's sample bytes, filled one frame at a time.
///
/// The buffer is **byte-level and interprets nothing**. Moving a frame's bytes
/// into its slice needs no endianness decision, no signedness decision and no
/// rescale: each of those is a value-transformation question belonging to the
/// stage `VOX-DCM-006` requires, and `ADR-0235` decision 2 keeps them out of the
/// transfer rather than pulling them into the wrong increment for a fourth time.
///
/// No pointer API is used: `-strict-memory-safety` diagnoses them, and the Swift
/// safety policy reserves the corresponding marker keyword outright — including
/// in comments, which is why this note describes the rule without spelling it.
///
/// The copy is a single `replaceSubrange` against the destination range, **not** a
/// hand-written element-wise loop. `ADR-0264` measured the difference: the loop ran
/// at about `120 MiB/s` and cost `9.2x` more when a caller supplied
/// `ContiguousArray` rather than `Data`, because neither generic context
/// specialised; `replaceSubrange` reaches about `3,650 MiB/s` on the same data
/// because the standard library's own implementation is already specialised. That
/// is a `30x` improvement with no pointer API, no `@inlinable` and no change to
/// this type's encapsulation — so `ADR-0235`'s framing, that the only options were
/// an upstream decode entry point or a governed safety exception, was mistaken.
///
/// Verified byte-for-byte: all 899 slices of the real series match DICOMKit's own
/// frame bytes exactly.
public struct CTVolumeByteBuffer: Sendable, Hashable {
    /// The layout describing the buffer's extents and scalar format.
    public let layout: CTVolumeLayout

    /// The sample bytes, exactly `layout.byteCount` of them.
    public private(set) var bytes: ContiguousArray<UInt8>

    /// The slice indices written so far, in ascending order.
    ///
    /// A volume assembled from a series must have every slice filled, and "the
    /// bytes look plausible" is not a check.
    public private(set) var writtenSlices: Set<Int>

    /// The number of bytes one frame occupies.
    public var bytesPerSlice: Int {
        layout.samplesPerSlice * layout.scalarFormat.type.byteCount
    }

    /// How many distinct slices have been written.
    public var writtenSliceCount: Int { writtenSlices.count }

    /// Whether every slice has been written.
    public var isComplete: Bool { writtenSlices.count == layout.sliceCount }

    /// Creates a zero-filled buffer for `layout`.
    ///
    /// Zero-filling means a frame that is never written leaves zeros rather than
    /// arbitrary memory, so a partially assembled volume is deterministic —
    /// and ``isComplete`` rather than an inspection of those zeros is how a
    /// caller detects the gap.
    public init(layout: CTVolumeLayout) {
        self.layout = layout
        self.bytes = ContiguousArray(repeating: 0, count: layout.byteCount)
        self.writtenSlices = []
    }

    /// Writes one frame's bytes into the slice its placement names.
    ///
    /// Re-writing a slice overwrites and is not an error: a caller retrying a
    /// failed decode is legitimate, and ``writtenSlices`` makes the outcome
    /// observable either way.
    ///
    /// - Parameters:
    ///   - frameBytes: exactly ``bytesPerSlice`` bytes for one frame.
    ///   - placement: the frame's admitted place in this volume.
    /// - Throws: ``CTVolumeByteBufferError``.
    public mutating func write(
        frameBytes: some Collection<UInt8>,
        at placement: CTFramePlacement
    ) throws {
        guard placement.layout == layout else {
            throw CTVolumeByteBufferError.layoutMismatch
        }
        guard frameBytes.count == bytesPerSlice else {
            throw CTVolumeByteBufferError.frameByteCountMismatch
        }

        let start = placement.byteOffset
        let end = start + bytesPerSlice
        guard start >= 0, end <= bytes.count else {
            throw CTVolumeByteBufferError.destinationOutOfRange
        }

        // One standard-library range replacement rather than a byte loop. Both
        // are memory-safe; this one is about thirty times faster because the
        // stdlib's implementation is specialised where a generic loop in this
        // module is not. `ADR-0264` records the measurement and the verification.
        bytes.replaceSubrange(start..<end, with: frameBytes)
        writtenSlices.insert(placement.sliceIndex)
    }

    /// The bytes of one slice, or `nil` when the slice index is out of range.
    ///
    /// Provided so a caller can verify a transfer without reaching into
    /// ``bytes`` and recomputing an offset that the layout already owns.
    public func sliceBytes(_ sliceIndex: Int) -> ArraySlice<UInt8>? {
        guard let start = layout.sliceByteOffset(sliceIndex) else { return nil }
        let end = start + bytesPerSlice
        guard end <= bytes.count else { return nil }
        return bytes[start..<end]
    }
}
