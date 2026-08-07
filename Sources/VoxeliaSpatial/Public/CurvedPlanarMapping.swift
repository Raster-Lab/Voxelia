// SPDX-License-Identifier: MIT

/// An error raised by curved-planar mapping admission or lookup.
public enum CurvedPlanarMappingError: Error, Sendable, Equatable {
    /// The reference direction was not expressed in the centreline's
    /// space.
    case spaceMismatch
    /// The reference direction was exactly zero.
    case zeroReferenceDirection
    /// The reference direction is exactly parallel to a centreline
    /// segment, where the lateral direction would be undefined.
    case referenceParallelToSegment
    /// The lateral offset was NaN or infinite.
    case invalidLateralOffset
}

/// The back-mapping of `VOX-MPR-013`, per `ADR-0376` and the frozen
/// `curved-planar-mapping/binary64-v1` model of `VOXELIA-ALG-0075`:
/// every curved-planar output position — arc length by lateral offset —
/// maps back to source patient coordinates.
///
/// The lateral direction is the normalised rejection of a
/// caller-declared reference direction from the per-segment tangent:
/// the stretched-CPR convention. The frame is piecewise constant,
/// discontinuous at vertices exactly where the polyline's tangent is —
/// honest to the declared input; a consumer needing a smoother frame
/// supplies a finer polyline.
public struct CurvedPlanarMapping: Sendable {
    public let centreline: CurvedCentreline
    /// The declared reference direction: which way "up" is in the
    /// reconstruction — a clinical choice, never a library guess.
    public let referenceDirection: Vector3D

    /// Creates a validated mapping.
    ///
    /// - Throws: ``CurvedPlanarMappingError``.
    public init(
        centreline: CurvedCentreline,
        referenceDirection: Vector3D
    ) throws {
        guard referenceDirection.coordinateSpace == centreline.coordinateSpace.id
        else {
            throw CurvedPlanarMappingError.spaceMismatch
        }
        guard
            referenceDirection.x != 0 || referenceDirection.y != 0
                || referenceDirection.z != 0
        else {
            throw CurvedPlanarMappingError.zeroReferenceDirection
        }
        for index in 0..<(centreline.points.count - 1) {
            let a = centreline.points[index]
            let b = centreline.points[index + 1]
            let dx = b.x - a.x
            let dy = b.y - a.y
            let dz = b.z - a.z
            let crossX = referenceDirection.y * dz - referenceDirection.z * dy
            let crossY = referenceDirection.z * dx - referenceDirection.x * dz
            let crossZ = referenceDirection.x * dy - referenceDirection.y * dx
            guard crossX != 0 || crossY != 0 || crossZ != 0 else {
                throw CurvedPlanarMappingError.referenceParallelToSegment
            }
        }
        self.centreline = centreline
        self.referenceDirection = referenceDirection
    }

    /// Maps one output position back to patient coordinates.
    ///
    /// - Throws: ``CurvedPlanarMappingError`` or
    ///   ``CurvedCentrelineError``.
    public func patientPosition(
        atArcLength arcLength: Double,
        lateralOffset: Double
    ) throws -> Point3D {
        guard lateralOffset.isFinite else {
            throw CurvedPlanarMappingError.invalidLateralOffset
        }
        let centre = try centreline.position(atArcLength: arcLength)

        var index = 0
        if arcLength == centreline.totalArcLength {
            index = centreline.points.count - 2
        } else {
            for candidate in 0..<(centreline.points.count - 1)
            where centreline.cumulativeArcLengths[candidate] <= arcLength {
                index = candidate
            }
        }
        let a = centreline.points[index]
        let b = centreline.points[index + 1]
        let length = centreline.segmentLengths[index]
        let tangentX = (b.x - a.x) / length
        let tangentY = (b.y - a.y) / length
        let tangentZ = (b.z - a.z) / length
        let dot =
            (referenceDirection.x * tangentX + referenceDirection.y * tangentY)
            + referenceDirection.z * tangentZ
        let rejectionX = referenceDirection.x - dot * tangentX
        let rejectionY = referenceDirection.y - dot * tangentY
        let rejectionZ = referenceDirection.z - dot * tangentZ
        let norm =
            ((rejectionX * rejectionX + rejectionY * rejectionY)
            + rejectionZ * rejectionZ).squareRoot()
        let lateralX = rejectionX / norm
        let lateralY = rejectionY / norm
        let lateralZ = rejectionZ / norm
        let x = centre.x + lateralOffset * lateralX
        let y = centre.y + lateralOffset * lateralY
        let z = centre.z + lateralOffset * lateralZ
        guard
            let position = try? Point3D(
                x: x == 0 ? 0 : x,
                y: y == 0 ? 0 : y,
                z: z == 0 ? 0 : z,
                coordinateSpace: centre.coordinateSpace
            )
        else {
            preconditionFailure("Finite frames over finite offsets stay finite.")
        }
        return position
    }
}
