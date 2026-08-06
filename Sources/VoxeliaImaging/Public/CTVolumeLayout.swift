// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while admitting a ``CTVolumeLayout``.
///
/// Cases deliberately carry no payload, so a rejected layout never discloses
/// source extents in a diagnostic.
public enum CTVolumeLayoutError: Error, Sendable, Equatable {
    case nonPositiveRowCount
    case nonPositiveColumnCount
    case nonPositiveSliceCount
    /// `rows * columns * sliceCount` is not representable as an `Int`.
    case sampleCountOverflow
    /// The sample count is representable and its byte count is not.
    ///
    /// A distinct case because it is the rule an implementation forgets: fixtures
    /// L4 and L6 of `VOXELIA-ALG-0050` are the same extents differing only in the
    /// scalar format's width, and one is refused while the other is admitted at
    /// exactly `Int.max`.
    case byteCountOverflow
}

/// An error raised while admitting a ``CTFramePlacement``.
public enum CTFramePlacementError: Error, Sendable, Equatable {
    /// The slice index is negative or at least the layout's slice count.
    case sliceIndexOutOfRange
    /// The frame's extents do not match the layout's.
    case extentsMismatch
    /// The frame's scalar format does not match the layout's.
    case scalarFormatMismatch
}

/// The addressing contract for a CT volume's samples, per `VOXELIA-ALG-0050`.
///
/// This type holds no samples and allocates nothing. It exists so that a frame
/// decoder can write **directly** into its slice of a caller-provided
/// destination, which is the ownership model `ADR-0230` decision 10 chose to
/// satisfy the plan's requirement of transfer without unnecessary intermediate
/// copies.
///
/// ## Addressing
///
/// Slice-major, then row-major within a slice, so that a single frame's samples
/// are one contiguous span in the destination. Any other order would make one
/// frame's samples strided, which is the copy this design avoids.
///
/// Note that a row advances by `columns`, not by `rows`. The two agree for every
/// square frame and differ for every other one.
public struct CTVolumeLayout: Sendable, Hashable {
    /// The number of rows in each frame.
    public let rows: Int
    /// The number of columns in each frame.
    public let columns: Int
    /// The number of frames.
    public let sliceCount: Int
    /// The scalar format every sample shares.
    public let scalarFormat: ScalarFormat

    /// The number of samples in one frame.
    public let samplesPerSlice: Int
    /// The number of samples in the whole volume.
    public let sampleCount: Int
    /// The number of bytes in the whole volume.
    public let byteCount: Int

    /// Creates a layout after applying every admission rule in the fixed order
    /// below.
    ///
    /// - Throws: ``CTVolumeLayoutError/nonPositiveRowCount``,
    ///   ``CTVolumeLayoutError/nonPositiveColumnCount`` or
    ///   ``CTVolumeLayoutError/nonPositiveSliceCount`` when an extent is below
    ///   one; ``CTVolumeLayoutError/sampleCountOverflow`` when the extents cannot
    ///   be multiplied; and ``CTVolumeLayoutError/byteCountOverflow`` when the
    ///   sample count cannot be scaled by the format's width.
    public init(
        rows: Int,
        columns: Int,
        sliceCount: Int,
        scalarFormat: ScalarFormat
    ) throws {
        guard rows >= 1 else { throw CTVolumeLayoutError.nonPositiveRowCount }
        guard columns >= 1 else { throw CTVolumeLayoutError.nonPositiveColumnCount }
        guard sliceCount >= 1 else { throw CTVolumeLayoutError.nonPositiveSliceCount }

        let perSlice = rows.multipliedReportingOverflow(by: columns)
        guard !perSlice.overflow else {
            throw CTVolumeLayoutError.sampleCountOverflow
        }
        let total = perSlice.partialValue.multipliedReportingOverflow(by: sliceCount)
        guard !total.overflow else {
            throw CTVolumeLayoutError.sampleCountOverflow
        }

        let bytes = total.partialValue.multipliedReportingOverflow(
            by: scalarFormat.type.byteCount
        )
        guard !bytes.overflow else {
            throw CTVolumeLayoutError.byteCountOverflow
        }

        self.rows = rows
        self.columns = columns
        self.sliceCount = sliceCount
        self.scalarFormat = scalarFormat
        self.samplesPerSlice = perSlice.partialValue
        self.sampleCount = total.partialValue
        self.byteCount = bytes.partialValue
    }

    /// Whether the three indices address a sample in this layout.
    public func contains(sliceIndex: Int, row: Int, column: Int) -> Bool {
        (0..<sliceCount).contains(sliceIndex) && (0..<rows).contains(row)
            && (0..<columns).contains(column)
    }

    /// The linear sample offset of one addressed sample, or `nil` when any index
    /// is out of range.
    ///
    /// The arithmetic cannot overflow once the layout is admitted: the largest
    /// offset this returns is exactly `sampleCount - 1`, and admission already
    /// established that `sampleCount` is representable.
    public func sampleOffset(sliceIndex: Int, row: Int, column: Int) -> Int? {
        guard contains(sliceIndex: sliceIndex, row: row, column: column) else {
            return nil
        }
        return ((sliceIndex * samplesPerSlice) + (row * columns)) + column
    }

    /// The byte offset of one addressed sample, or `nil` when any index is out of
    /// range.
    public func byteOffset(sliceIndex: Int, row: Int, column: Int) -> Int? {
        sampleOffset(sliceIndex: sliceIndex, row: row, column: column)
            .map { $0 * scalarFormat.type.byteCount }
    }

    /// The sample offset at which `sliceIndex`'s contiguous span begins, or `nil`
    /// when the slice index is out of range.
    ///
    /// This is what a direct-write decoder needs: one offset per frame, after
    /// which the frame's samples are contiguous.
    public func sliceSampleOffset(_ sliceIndex: Int) -> Int? {
        guard (0..<sliceCount).contains(sliceIndex) else { return nil }
        return sliceIndex * samplesPerSlice
    }

    /// The byte offset at which `sliceIndex`'s contiguous span begins.
    public func sliceByteOffset(_ sliceIndex: Int) -> Int? {
        sliceSampleOffset(sliceIndex).map { $0 * scalarFormat.type.byteCount }
    }
}

/// One frame's place in a volume, per `ADR-0232`.
///
/// This is deliberately **not** the First Vertical Slice Plan's `CTFrameRecord`,
/// which holds a decoded sample buffer. `ADR-0230` decision 10 chose direct-write
/// into a caller-provided destination, so there is no intermediate owned buffer
/// for a record to hold — the shape became unnecessary rather than pending, and
/// `ADR-0232` records that departure.
public struct CTFramePlacement: Sendable, Hashable {
    /// The frame's neutral description.
    public let frame: CTFrameDescription
    /// The slice this frame occupies.
    public let sliceIndex: Int
    /// The layout the placement was admitted against.
    public let layout: CTVolumeLayout

    /// Creates a placement, admitting it against `layout`.
    ///
    /// - Throws: ``CTFramePlacementError/sliceIndexOutOfRange`` when
    ///   `sliceIndex` is negative or at least the layout's slice count;
    ///   ``CTFramePlacementError/extentsMismatch`` when the frame's extents
    ///   differ from the layout's; and
    ///   ``CTFramePlacementError/scalarFormatMismatch`` when the formats differ.
    public init(
        frame: CTFrameDescription,
        sliceIndex: Int,
        layout: CTVolumeLayout
    ) throws {
        guard (0..<layout.sliceCount).contains(sliceIndex) else {
            throw CTFramePlacementError.sliceIndexOutOfRange
        }
        guard frame.rows == layout.rows, frame.columns == layout.columns else {
            throw CTFramePlacementError.extentsMismatch
        }
        guard frame.scalarFormat == layout.scalarFormat else {
            throw CTFramePlacementError.scalarFormatMismatch
        }

        self.frame = frame
        self.sliceIndex = sliceIndex
        self.layout = layout
    }

    /// The sample offset at which this frame's contiguous span begins.
    ///
    /// Never `nil`: admission established that the slice index is in range.
    public var sampleOffset: Int {
        layout.sliceSampleOffset(sliceIndex) ?? 0
    }

    /// The byte offset at which this frame's contiguous span begins.
    public var byteOffset: Int {
        layout.sliceByteOffset(sliceIndex) ?? 0
    }
}
