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

    /// Composes `outer` applied after `inner` without leaving the rigid
    /// category, per `VOXELIA-ALG-0069`: the Hamilton product with frozen
    /// folds re-admits through ordinary admission (so the stored form
    /// stays canonical), and the translation is the outer rotation
    /// applied to the inner translation plus the outer translation.
    public static func composed(
        _ outer: RigidMotion,
        after inner: RigidMotion
    ) throws -> RigidMotion {
        let w1 = outer.quaternion[0]
        let x1 = outer.quaternion[1]
        let y1 = outer.quaternion[2]
        let z1 = outer.quaternion[3]
        let w2 = inner.quaternion[0]
        let x2 = inner.quaternion[1]
        let y2 = inner.quaternion[2]
        let z2 = inner.quaternion[3]
        let productW = ((w1 * w2 - x1 * x2) - y1 * y2) - z1 * z2
        let productX = ((w1 * x2 + x1 * w2) + y1 * z2) - z1 * y2
        let productY = ((w1 * y2 - x1 * z2) + y1 * w2) + z1 * x2
        let productZ = ((w1 * z2 + x1 * y2) - y1 * x2) + z1 * w2
        let r = try outer.matrix().elements
        var shifted = [Double](repeating: 0, count: 3)
        for row in 0..<3 {
            shifted[row] =
                ((r[4 * row + 0] * inner.translation[0]
                    + r[4 * row + 1] * inner.translation[1])
                    + r[4 * row + 2] * inner.translation[2])
                + outer.translation[row]
        }
        return try RigidMotion(
            quaternionW: productW,
            quaternionX: productX,
            quaternionY: productY,
            quaternionZ: productZ,
            translationX: shifted[0],
            translationY: shifted[1],
            translationZ: shifted[2]
        )
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
