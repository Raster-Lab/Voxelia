// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised while constructing a distance phantom.
///
/// Payload-free, like every other failure family in the project.
public enum DistancePhantomError: Error, Sendable, Equatable {
    /// The extents were not three positive values, or their product overflowed.
    case invalidExtents
    /// A spacing was not a power of two inside the admitted exponent range.
    case spacingNotAdmissible
    /// An origin component was not an integer inside the admitted magnitude.
    case originNotAdmissible
    /// A frozen segment's physical delta is not a whole number of voxels at this spacing.
    case segmentNotVoxelAligned
    /// A frozen segment's far endpoint falls outside the extents.
    case segmentOutsideExtents
}

/// The plan §55.4 distance phantom, per `ADR-0295` (`VOX-VAL-003`).
///
/// Two or more endpoints at known physical distances and oblique orientations, for the
/// patient-space measurement purpose the plan names.
///
/// ## Why the lengths are exact
///
/// `ADR-0293` decision boundary 4 required that the obliqueness not force a tolerance. Every
/// frozen segment's physical delta is a Pythagorean quadruple in whole millimetres, so its
/// length is an integer and the square root `VOXELIA-ALG-0010` takes is exact. The identity
/// `a² + b² + c² = d²` is checked in `Int` rather than certified in binary64, because
/// `fl(√s)² == s` holds for non-squares as small as `s = 11` — a squared length a
/// three-dimensional segment can easily have — and would admit an irrational length as exact.
///
/// ## Why the spacing and the origin are constrained
///
/// A power-of-two spacing makes the division by spacing exact, so testing the quotient for
/// integrality is a real alignment test rather than a rounded one. An integral, bounded
/// origin keeps every coordinate a dyadic rational spanning at most 42 significant bits, so
/// every sum and difference on the path from origin to measured length is exact in binary64.
///
/// The constraints cost nothing: a phantom's geometry is chosen rather than observed, and
/// the realistic anisotropic case survives them — the frozen table's z components are all
/// even, so a 2 mm slice spacing stays voxel-aligned beside 0.5 mm in plane.
public struct DistancePhantom: Sendable, Hashable {
    /// One sample position in the phantom's own index space.
    public struct VoxelIndex: Sendable, Hashable {
        public let column: Int
        public let row: Int
        public let slice: Int

        public init(column: Int, row: Int, slice: Int) {
            self.column = column
            self.row = row
            self.slice = slice
        }
    }

    /// One measurable segment: two endpoints and the physical length between them.
    public struct Segment: Sendable, Hashable {
        /// The near endpoint, shared by every segment.
        public let start: Point3D
        /// The far endpoint.
        public let end: Point3D
        /// The near endpoint's sample position.
        public let startIndex: VoxelIndex
        /// The far endpoint's sample position.
        public let endIndex: VoxelIndex
        /// The exact physical length, in the coordinate space's length unit.
        public let exactLength: Double
    }

    /// The frozen physical deltas, in whole millimetres, with their exact lengths.
    ///
    /// Three of the four have every component non-zero, which is what the plan's "oblique
    /// orientations" asks for; the fourth is in-plane oblique so a reconstructed view has a
    /// segment that lies inside it. Every z component is even so that a realistic 2 mm slice
    /// spacing remains voxel-aligned.
    private struct FrozenSegment: Sendable {
        let deltaX: Double
        let deltaY: Double
        let deltaZ: Double
        let length: Double
    }

    private static let frozenSegments: [FrozenSegment] = [
        FrozenSegment(deltaX: 3, deltaY: 4, deltaZ: 0, length: 5),
        FrozenSegment(deltaX: 1, deltaY: 2, deltaZ: 2, length: 3),
        FrozenSegment(deltaX: 2, deltaY: 3, deltaZ: 6, length: 7),
        FrozenSegment(deltaX: 1, deltaY: 4, deltaZ: 8, length: 9),
    ]

    /// Distinct in each axis on purpose: a shared base at the corner would read correctly
    /// under a transposed addressing mistake, where this one moves.
    private static let frozenBase = VoxelIndex(column: 1, row: 2, slice: 1)

    /// The largest admitted origin component magnitude, `2³⁰`.
    private static let originMagnitudeLimit = 1_073_741_824.0

    /// The admitted spacing exponent range, so a spacing spans `2⁻¹⁰` through `2¹⁰`.
    private static let spacingExponents = -10...10

    /// The value written at an endpoint sample.
    public static let markerValue: Int16 = 1000
    /// The value written everywhere else.
    public static let backgroundValue: Int16 = 0

    public let columns: Int
    public let rows: Int
    public let slices: Int
    public let columnSpacing: Double
    public let rowSpacing: Double
    public let sliceSpacing: Double
    /// The patient-space position of sample `(0, 0, 0)`.
    public let origin: Point3D
    /// The sample position every segment starts from.
    public let baseIndex: VoxelIndex
    /// The segments, in the frozen table's order.
    public let segments: [Segment]

    /// Builds a phantom over the given extents, spacing and origin.
    ///
    /// - Throws: ``DistancePhantomError``.
    public init(
        columns: Int,
        rows: Int,
        slices: Int,
        columnSpacing: Double,
        rowSpacing: Double,
        sliceSpacing: Double,
        origin: Point3D
    ) throws {
        guard columns >= 1, rows >= 1, slices >= 1 else {
            throw DistancePhantomError.invalidExtents
        }
        let (frame, frameOverflowed) = columns.multipliedReportingOverflow(by: rows)
        let (samples, samplesOverflowed) = frame.multipliedReportingOverflow(by: slices)
        guard !frameOverflowed, !samplesOverflowed, samples >= 1 else {
            throw DistancePhantomError.invalidExtents
        }
        for spacing in [columnSpacing, rowSpacing, sliceSpacing] {
            guard Self.isAdmissibleSpacing(spacing) else {
                throw DistancePhantomError.spacingNotAdmissible
            }
        }
        // `Point3D` already refuses NaN and infinity, so rounding here is defined.
        for component in [origin.x, origin.y, origin.z] {
            guard
                component == component.rounded(.towardZero),
                component.magnitude <= Self.originMagnitudeLimit
            else {
                throw DistancePhantomError.originNotAdmissible
            }
        }

        let base = Self.frozenBase
        guard base.column < columns, base.row < rows, base.slice < slices else {
            throw DistancePhantomError.segmentOutsideExtents
        }
        let start = try Point3D(
            x: origin.x + Double(base.column) * columnSpacing,
            y: origin.y + Double(base.row) * rowSpacing,
            z: origin.z + Double(base.slice) * sliceSpacing,
            coordinateSpace: origin.coordinateSpace
        )

        var built: [Segment] = []
        built.reserveCapacity(Self.frozenSegments.count)
        for frozen in Self.frozenSegments {
            // Division by a power of two is exact, so an integral quotient here means the
            // endpoint genuinely lands on a sample rather than nearly on one. The spacing
            // floor of 2⁻¹⁰ and the table's largest component of 8 bound every quotient by
            // 8192, so the conversion below cannot overflow.
            let steps = [
                frozen.deltaX / columnSpacing,
                frozen.deltaY / rowSpacing,
                frozen.deltaZ / sliceSpacing,
            ]
            guard steps.allSatisfy({ $0 == $0.rounded(.towardZero) }) else {
                throw DistancePhantomError.segmentNotVoxelAligned
            }
            let endIndex = VoxelIndex(
                column: base.column + Int(steps[0]),
                row: base.row + Int(steps[1]),
                slice: base.slice + Int(steps[2])
            )
            guard
                endIndex.column < columns, endIndex.row < rows, endIndex.slice < slices
            else {
                throw DistancePhantomError.segmentOutsideExtents
            }
            let end = try Point3D(
                x: start.x + frozen.deltaX,
                y: start.y + frozen.deltaY,
                z: start.z + frozen.deltaZ,
                coordinateSpace: origin.coordinateSpace
            )
            built.append(
                Segment(
                    start: start,
                    end: end,
                    startIndex: base,
                    endIndex: endIndex,
                    exactLength: frozen.length
                )
            )
        }

        self.columns = columns
        self.rows = rows
        self.slices = slices
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
        self.sliceSpacing = sliceSpacing
        self.origin = origin
        self.baseIndex = base
        self.segments = built
    }

    /// A spacing is admitted when it is a power of two inside the frozen exponent range.
    ///
    /// `significandBitPattern == 0` on a normal value means the significand is exactly one,
    /// which is what makes the later division exact.
    private static func isAdmissibleSpacing(_ spacing: Double) -> Bool {
        spacing.isNormal && spacing > 0 && spacing.significandBitPattern == 0
            && spacingExponents.contains(spacing.exponent)
    }

    /// Every marked sample: the shared base first, then each segment's far endpoint in the
    /// frozen table's order.
    public var markerIndices: [VoxelIndex] {
        [baseIndex] + segments.map(\.endIndex)
    }

    /// The number of samples the phantom holds.
    public var sampleCount: Int {
        columns * rows * slices
    }

    /// The materialised samples, little-endian `int16`, in `VOXELIA-ALG-0050` order:
    /// slice-major, then row-major within a slice, so the column index varies fastest.
    ///
    /// Marked samples carry ``markerValue`` and every other sample ``backgroundValue``, so a
    /// consumer can locate the endpoints by scanning rather than by being told where to look.
    public var storedBytes: ContiguousArray<UInt8> {
        let marked = Set(markerIndices)
        var bytes = ContiguousArray<UInt8>()
        bytes.reserveCapacity(sampleCount * 2)
        for slice in 0..<slices {
            for row in 0..<rows {
                for column in 0..<columns {
                    let index = VoxelIndex(column: column, row: row, slice: slice)
                    let sample = marked.contains(index) ? Self.markerValue : Self.backgroundValue
                    let pattern = UInt16(bitPattern: sample)
                    bytes.append(UInt8(truncatingIfNeeded: pattern))
                    bytes.append(UInt8(truncatingIfNeeded: pattern >> 8))
                }
            }
        }
        return bytes
    }
}
