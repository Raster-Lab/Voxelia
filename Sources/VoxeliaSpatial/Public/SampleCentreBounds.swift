// SPDX-License-Identifier: MIT

/// An error raised while computing sample-centre physical bounds.
public enum SampleCentreBoundsError: Error, Sendable, Equatable {
    /// A slot's sample count is below one. Slots 0, 1, and 2 follow the
    /// geometry's index order.
    case nonPositiveSampleCount(slot: Int, count: Int)

    /// A slot's sample count exceeds the exact-representability ceiling, so
    /// its outermost sample centre has no exact binary64 coordinate.
    case sampleCountNotExactlyRepresentable(slot: Int, count: Int)

    /// A transformed corner component was not representable as a finite
    /// binary64 value. Corner ordinals follow the frozen `VOXELIA-ALG-0054`
    /// enumeration; axes 0, 1, and 2 are world X, Y, and Z.
    case cornerNotRepresentable(cornerOrdinal: Int, axis: Int)
}

extension AffineGridGeometry {
    /// The inclusive sample-count ceiling, two to the power fifty-three.
    ///
    /// For admitted counts the outermost sample centre `count - 1` converts
    /// to binary64 exactly, so the published bounds state the centre itself
    /// rather than a rounded neighbour.
    public static let sampleCentreBoundsSampleCountCeiling = 9_007_199_254_740_992

    /// Returns the axis-aligned physical hull of the outermost sample centres.
    ///
    /// Implements `sample-centre-bounds/binary64-v1` (`VOXELIA-ALG-0054`):
    /// all eight corners of the continuous index box spanning `0` to
    /// `count - 1` per slot are transformed through ``indexToWorld`` in the
    /// frozen expression order and folded into componentwise minima and
    /// maxima. The bounds enclose sample centres, not sample extents, per
    /// `ADR-0338` decision 7. A slot with one sample contributes zero width
    /// on its axis through the ordinary fold.
    ///
    /// - Throws: ``SampleCentreBoundsError/nonPositiveSampleCount(slot:count:)``
    ///   for a slot with fewer than one sample,
    ///   ``SampleCentreBoundsError/sampleCountNotExactlyRepresentable(slot:count:)``
    ///   for a count above ``sampleCentreBoundsSampleCountCeiling``, or
    ///   ``SampleCentreBoundsError/cornerNotRepresentable(cornerOrdinal:axis:)``
    ///   for the first non-finite transformed component in frozen order.
    public func sampleCentreBounds(
        slot0SampleCount: Int,
        slot1SampleCount: Int,
        slot2SampleCount: Int
    ) throws -> AxisAlignedBounds3D {
        let counts = [slot0SampleCount, slot1SampleCount, slot2SampleCount]
        for (slot, count) in counts.enumerated() {
            guard count >= 1 else {
                throw SampleCentreBoundsError.nonPositiveSampleCount(
                    slot: slot,
                    count: count
                )
            }
            guard count <= Self.sampleCentreBoundsSampleCountCeiling else {
                throw SampleCentreBoundsError.sampleCountNotExactlyRepresentable(
                    slot: slot,
                    count: count
                )
            }
        }

        let m = indexToWorld.elements
        let outermost = counts.map { Double($0 - 1) }
        var minimum = [0.0, 0.0, 0.0]
        var maximum = [0.0, 0.0, 0.0]
        for cornerOrdinal in 0..<8 {
            let i0 = cornerOrdinal & 1 == 0 ? 0.0 : outermost[0]
            let i1 = (cornerOrdinal >> 1) & 1 == 0 ? 0.0 : outermost[1]
            let i2 = (cornerOrdinal >> 2) & 1 == 0 ? 0.0 : outermost[2]
            var corner = [0.0, 0.0, 0.0]
            for axis in 0..<3 {
                let row = 4 * axis
                let component =
                    ((m[row] * i0 + m[row + 1] * i1) + m[row + 2] * i2) + m[row + 3]
                guard component.isFinite else {
                    throw SampleCentreBoundsError.cornerNotRepresentable(
                        cornerOrdinal: cornerOrdinal,
                        axis: axis
                    )
                }
                corner[axis] = component
            }
            if cornerOrdinal == 0 {
                minimum = corner
                maximum = corner
            } else {
                for axis in 0..<3 {
                    minimum[axis] = min(minimum[axis], corner[axis])
                }
                for axis in 0..<3 {
                    maximum[axis] = max(maximum[axis], corner[axis])
                }
            }
        }

        // The fold guarantees ordered components and the finiteness check
        // precedes construction, so neither admission below can fail.
        let space = coordinateSpace.id
        let minimumPoint = try Point3D(
            x: minimum[0],
            y: minimum[1],
            z: minimum[2],
            coordinateSpace: space
        )
        let maximumPoint = try Point3D(
            x: maximum[0],
            y: maximum[1],
            z: maximum[2],
            coordinateSpace: space
        )
        return try AxisAlignedBounds3D(minimum: minimumPoint, maximum: maximumPoint)
    }
}
