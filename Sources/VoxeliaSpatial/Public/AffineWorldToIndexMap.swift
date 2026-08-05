// SPDX-License-Identifier: MIT

/// An error raised while mapping a world point to grid indices.
public enum AffineWorldToIndexError: Error, Sendable, Equatable {
    /// The point's coordinate space is not the geometry's — mapping
    /// across spaces silently would fabricate a calibration.
    case coordinateSpaceMismatch

    /// The requested image axis is not spatially mapped by the
    /// geometry's axis mapping.
    case axisNotSpatiallyMapped
}

/// The frozen world-to-index composition per accepted `ADR-0138`,
/// consuming the `VOXELIA-ALG-0016` inverse.
///
/// The frozen step: three correctly rounded subtractions
/// `d[c] = world[c] - translation[c]`, then per matrix slot the
/// ascending left-to-right accumulation
/// `((inverse[3r] * d0) + (inverse[3r+1] * d1)) + (inverse[3r+2] * d2)`
/// with no fused multiply-add — the mirror of the claimed forward
/// evaluation. Slot values map to image axes through the geometry's
/// own axis mapping; repeated evaluation is bit-identical.
public struct AffineWorldToIndexMap: Sendable, Hashable {
    /// The measured frozen inverse of the geometry's spatial block.
    public let inverse: AffineSpatialInverse

    /// The geometry's slot-to-image-axis mapping.
    public let spatialAxes: SpatialAxisMapping

    /// The coordinate space every mapped point must inhabit.
    public let coordinateSpace: CoordinateSpaceID

    private let translation: ContiguousArray<Double>

    /// Builds the map from one validated affine geometry.
    ///
    /// - Throws: ``AffineSpatialInverseError/singularMatrix``, which
    ///   is unreachable for a validated geometry whose own admission
    ///   computes the identical frozen determinant.
    public init(geometry: AffineGridGeometry) throws {
        inverse = try AffineSpatialInverse(spatialPartOf: geometry.indexToWorld)
        spatialAxes = geometry.spatialAxes
        coordinateSpace = geometry.coordinateSpace.id
        let elements = geometry.indexToWorld.elements
        translation = [elements[3], elements[7], elements[11]]
    }

    /// Maps one world point to the three continuous indices in matrix
    /// slot order.
    ///
    /// - Throws: ``AffineWorldToIndexError/coordinateSpaceMismatch``.
    public func continuousSlotIndices(
        of point: Point3D
    ) throws -> ContiguousArray<Double> {
        guard point.coordinateSpace == coordinateSpace else {
            throw AffineWorldToIndexError.coordinateSpaceMismatch
        }
        let d0 = point.x - translation[0]
        let d1 = point.y - translation[1]
        let d2 = point.z - translation[2]
        var slots = ContiguousArray<Double>()
        slots.reserveCapacity(3)
        for row in 0...2 {
            slots.append(
                ((inverse.elements[3 * row] * d0)
                    + (inverse.elements[3 * row + 1] * d1))
                    + (inverse.elements[3 * row + 2] * d2)
            )
        }
        return slots
    }

    /// Maps one world point to the continuous index of one image axis.
    ///
    /// - Throws: ``AffineWorldToIndexError``.
    public func continuousIndex(
        forImageAxis axis: Int,
        of point: Point3D
    ) throws -> Double {
        guard let slot = spatialAxes.imageAxes.firstIndex(of: axis) else {
            throw AffineWorldToIndexError.axisNotSpatiallyMapped
        }
        return try continuousSlotIndices(of: point)[slot]
    }
}
