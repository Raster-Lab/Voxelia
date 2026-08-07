// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// The landmark-rigid member of the `VOX-REG-005` portfolio: the
/// registration face over `VOXELIA-ALG-0071` estimation, mirroring the
/// affine member's contract.
public enum LandmarkRigidRegistration {
    /// Registers `moving` landmarks onto `fixed` landmarks rigidly.
    ///
    /// Every moving point must be expressed in `sourceSpace` and every
    /// fixed point in `destinationSpace` — a landmark expressed
    /// elsewhere is a typed refusal, not a silent reinterpretation.
    ///
    /// - Throws: ``LandmarkRegistrationError``,
    ///   `LandmarkEstimationError` or `RigidMotionError`.
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
        let motion = try LandmarkRigidEstimation.estimate(moving: moving, fixed: fixed)
        return RegistrationTransform(
            sourceSpace: sourceSpace,
            destinationSpace: destinationSpace,
            category: .rigid(motion)
        )
    }
}
