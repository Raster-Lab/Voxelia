// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised by the landmark registration face, per `ADR-0368`.
public enum LandmarkRegistrationError: Error, Sendable, Equatable {
    /// A moving landmark was not expressed in the source space, or a
    /// fixed landmark was not expressed in the destination space.
    case spaceMismatch
}

/// The landmark-affine member of the `VOX-REG-005` portfolio: the
/// registration face over `VOXELIA-ALG-0070` estimation.
public enum LandmarkAffineRegistration {
    /// Registers `moving` landmarks onto `fixed` landmarks.
    ///
    /// Every moving point must be expressed in `sourceSpace` and every
    /// fixed point in `destinationSpace` — a landmark expressed
    /// elsewhere is a typed refusal, not a silent reinterpretation. The
    /// estimate re-admits through ``AffineRegistrationTransform``, so
    /// the returned transform has proven its own invertibility.
    ///
    /// - Throws: ``LandmarkRegistrationError``,
    ///   ``LandmarkEstimationError`` or ``RegistrationTransformError``.
    public static func register(
        moving: ContiguousArray<Point3D>,
        fixed: ContiguousArray<Point3D>,
        sourceSpace: CoordinateSpaceDescriptor,
        destinationSpace: CoordinateSpaceDescriptor
    ) throws -> RegistrationTransform {
        for point in moving where point.coordinateSpace != sourceSpace.id {
            throw LandmarkRegistrationError.spaceMismatch
        }
        for point in fixed where point.coordinateSpace != destinationSpace.id {
            throw LandmarkRegistrationError.spaceMismatch
        }
        let matrix = try LandmarkAffineEstimation.estimate(moving: moving, fixed: fixed)
        return RegistrationTransform(
            sourceSpace: sourceSpace,
            destinationSpace: destinationSpace,
            category: .affine(try AffineRegistrationTransform(matrix: matrix))
        )
    }
}
