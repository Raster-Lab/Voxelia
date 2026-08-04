// SPDX-License-Identifier: MIT

/// An error raised while validating a coordinate space descriptor.
public enum CoordinateSpaceError: Error, Sendable, Equatable {
    case nonLengthUnit
    case duplicateExternalReference
    case handednessContradiction
}

/// An error raised while validating a spatial geometry.
public enum SpatialGeometryError: Error, Sendable, Equatable {
    case nonAffineBottomRow
    case singularTransform
}

/// One ordinary physical coordinate-space descriptor admitted under the
/// accepted `ADR-0043` boundary.
///
/// Version one admits exactly the length-dimension physical space;
/// parametric and other classifications require a future reviewed
/// decision. Identifier equality never implies transform equivalence.
public struct CoordinateSpaceDescriptor: Sendable, Hashable {
    public let id: CoordinateSpaceID
    public let convention: CoordinateConvention
    public let handedness: CoordinateHandedness
    public let unit: MeasurementUnit
    public let externalReferences: ContiguousArray<ExternalFrameReference>

    /// - Throws: ``CoordinateSpaceError/nonLengthUnit`` unless the unit
    ///   carries `UnitDimension.length`;
    ///   ``CoordinateSpaceError/duplicateExternalReference`` for repeated
    ///   exact namespace/identifier pairs; and
    ///   ``CoordinateSpaceError/handednessContradiction`` when a declared
    ///   handedness contradicts the convention's implied handedness.
    public init(
        id: CoordinateSpaceID,
        convention: CoordinateConvention,
        handedness: CoordinateHandedness,
        unit: MeasurementUnit,
        externalReferences: ContiguousArray<ExternalFrameReference>
    ) throws {
        guard unit.dimension == .length else {
            throw CoordinateSpaceError.nonLengthUnit
        }
        var seen = Set<ExternalFrameReference>()
        for reference in externalReferences {
            guard seen.insert(reference).inserted else {
                throw CoordinateSpaceError.duplicateExternalReference
            }
        }
        if let implied = convention.impliedHandedness,
            handedness != .unspecified,
            handedness != implied
        {
            throw CoordinateSpaceError.handednessContradiction
        }
        self.id = id
        self.convention = convention
        self.handedness = handedness
        self.unit = unit
        self.externalReferences = externalReferences
    }
}

/// One validated affine grid geometry.
///
/// Admission follows the accepted `ADR-0043` exact rule: finite elements
/// (guaranteed by `Matrix4x4Double`), the exact homogeneous bottom row
/// `(0, 0, 0, 1)` and an upper-left three-by-three determinant magnitude
/// of at least `Double.leastNormalMagnitude`. No epsilon tolerance
/// parameter exists in version one.
public struct AffineGridGeometry: Sendable, Hashable {
    public let spatialAxes: SpatialAxisMapping
    public let indexToWorld: Matrix4x4Double
    public let coordinateSpace: CoordinateSpaceDescriptor

    public init(
        spatialAxes: SpatialAxisMapping,
        indexToWorld: Matrix4x4Double,
        coordinateSpace: CoordinateSpaceDescriptor
    ) throws {
        let m = indexToWorld.elements
        guard m[12] == 0, m[13] == 0, m[14] == 0, m[15] == 1 else {
            throw SpatialGeometryError.nonAffineBottomRow
        }
        let determinant =
            m[0] * (m[5] * m[10] - m[6] * m[9])
            - m[1] * (m[4] * m[10] - m[6] * m[8])
            + m[2] * (m[4] * m[9] - m[5] * m[8])
        guard determinant.magnitude >= Double.leastNormalMagnitude else {
            throw SpatialGeometryError.singularTransform
        }
        self.spatialAxes = spatialAxes
        self.indexToWorld = indexToWorld
        self.coordinateSpace = coordinateSpace
    }
}

/// The version-one spatial geometry surface.
///
/// The accepted `ADR-0043` boundary admits the affine case; rectilinear
/// and frame-set cases join at their recorded milestone windows under the
/// already-frozen admission rules without reopening this boundary.
public enum SpatialGeometry: Sendable, Hashable {
    case affine(AffineGridGeometry)
}
