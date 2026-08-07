// SPDX-License-Identifier: MIT

/// An error raised by rigid-motion admission.
///
/// Payload-free, like every other failure family in the project.
public enum RigidMotionError: Error, Sendable, Equatable {
    /// A quaternion or translation component was NaN or infinite.
    case nonFiniteComponent
    /// Every quaternion component was zero, so no rotation is described.
    case zeroQuaternion
}

/// The frozen `rigid-motion/binary64-v1` model, specified by
/// `VOXELIA-ALG-0068` and accepted by `ADR-0365`.
///
/// A rigid motion is a canonical unit quaternion plus a translation — a
/// parameterisation that cannot express shear or scale, which is what
/// makes the rigid category of `VOX-REG-001` distinct **by construction**
/// rather than by a tolerance-checked matrix. Admission normalises the
/// quaternion (frozen left-associative squared-norm fold, one correctly
/// rounded square root, one division per component), fixes the canonical
/// sign (the first non-zero component is positive, so `q` and `-q` admit
/// to one stored form) and normalises negative zero to positive zero,
/// exactly as ``Matrix4x4Double`` admission does.
public struct RigidMotion: Sendable, Hashable {
    /// The canonical unit quaternion, stored `w, x, y, z`.
    public let quaternion: ContiguousArray<Double>
    /// The translation, stored `x, y, z`.
    public let translation: ContiguousArray<Double>

    /// Creates a rigid motion from finite quaternion components, not all
    /// zero, and finite translation components.
    ///
    /// - Throws: ``RigidMotionError``.
    public init(
        quaternionW: Double,
        quaternionX: Double,
        quaternionY: Double,
        quaternionZ: Double,
        translationX: Double,
        translationY: Double,
        translationZ: Double
    ) throws {
        let raw = [quaternionW, quaternionX, quaternionY, quaternionZ]
        let shift = [translationX, translationY, translationZ]
        for component in raw where !component.isFinite {
            throw RigidMotionError.nonFiniteComponent
        }
        for component in shift where !component.isFinite {
            throw RigidMotionError.nonFiniteComponent
        }
        let normSquared =
            ((raw[0] * raw[0] + raw[1] * raw[1]) + raw[2] * raw[2]) + raw[3] * raw[3]
        guard normSquared > 0, normSquared.isFinite else {
            throw RigidMotionError.zeroQuaternion
        }
        let norm = normSquared.squareRoot()
        var unit = raw.map { $0 / norm }
        for component in unit where component != 0 {
            if component < 0 {
                unit = unit.map { -$0 }
            }
            break
        }
        self.quaternion = ContiguousArray(unit.map { $0 == 0 ? 0 : $0 })
        self.translation = ContiguousArray(shift.map { $0 == 0 ? 0 : $0 })
    }

    /// The derived homogeneous matrix: the `VOXELIA-ALG-0068` rotation in
    /// the upper-left block, the translation at indices 3, 7 and 11 and
    /// the exact affine bottom row. Repeated derivation is bit-identical.
    public func matrix() throws -> Matrix4x4Double {
        let w = quaternion[0]
        let x = quaternion[1]
        let y = quaternion[2]
        let z = quaternion[3]
        let rotation: [Double] = [
            1 - 2 * ((y * y) + (z * z)),
            2 * ((x * y) - (w * z)),
            2 * ((x * z) + (w * y)),
            2 * ((x * y) + (w * z)),
            1 - 2 * ((x * x) + (z * z)),
            2 * ((y * z) - (w * x)),
            2 * ((x * z) - (w * y)),
            2 * ((y * z) + (w * x)),
            1 - 2 * ((x * x) + (y * y)),
        ]
        return try Matrix4x4Double(elements: [
            rotation[0], rotation[1], rotation[2], translation[0],
            rotation[3], rotation[4], rotation[5], translation[1],
            rotation[6], rotation[7], rotation[8], translation[2],
            0, 0, 0, 1,
        ])
    }
}
