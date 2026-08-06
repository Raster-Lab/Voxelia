// SPDX-License-Identifier: MIT

/// An error raised while composing or applying an affine transform.
///
/// Payload-free, like every other failure family in the project: a refused matrix is not
/// echoed back.
public enum AffineTransformError: Error, Sendable, Equatable {
    /// An operand's bottom row was not exactly `0, 0, 0, 1`.
    case nonAffineOperand
}

/// The frozen `affine-composition/binary64-v1` model, specified by `VOXELIA-ALG-0052` and
/// accepted by `ADR-0283`.
///
/// `VOX-SPA-008` requires affine transforms to support composition, inversion and point,
/// vector and normal transformation. `VOXELIA-ALG-0016` specifies inversion and `ADR-0138`
/// froze a point transformation for its own consumer; this supplies the three `ADR-0280`
/// found absent.
///
/// ## Coordinate spaces are not attributed here
///
/// `Point3D` and `Vector3D` carry a ``CoordinateSpaceID``, and a transform maps between
/// spaces — so which space a result inhabits is a real question. It is deliberately not
/// answered here. These operations are the arithmetic the specification freezes, and
/// attributing a destination space is the consuming operation's own decision, exactly as
/// `VOXELIA-ALG-0016` left composition with a world offset to its consumers.
///
/// ## Every expression order is fixed
///
/// Sums are left-associative in ascending index order and there is no fused multiply-add,
/// so repeated evaluation of the same admitted inputs is bit-identical.
public enum AffineTransformAlgebra {
    /// The upper-left three-by-three block, row-major.
    private static func block3(_ matrix: Matrix4x4Double) -> ContiguousArray<Double> {
        let m = matrix.elements
        return [m[0], m[1], m[2], m[4], m[5], m[6], m[8], m[9], m[10]]
    }

    /// The translation triple, at indices 3, 7 and 11.
    private static func translation(_ matrix: Matrix4x4Double) -> ContiguousArray<Double> {
        let m = matrix.elements
        return [m[3], m[7], m[11]]
    }

    /// Reports whether the bottom row is exactly `0, 0, 0, 1`.
    ///
    /// Exact equality, not a tolerance. `Matrix4x4Double` already guarantees finiteness and
    /// normalises negative zero on admission, so no separate check is performed here.
    public static func isAffine(_ matrix: Matrix4x4Double) -> Bool {
        let m = matrix.elements
        return m[12] == 0 && m[13] == 0 && m[14] == 0 && m[15] == 1
    }

    /// Composes `outer` after `inner`, so the result applied to a point equals
    /// `outer` applied to (`inner` applied to that point).
    ///
    /// The affine structure is used rather than multiplied through: only the upper
    /// three-by-four is computed and the bottom row is the literal `0, 0, 0, 1`. Computing
    /// it would multiply admitted values by known zeros, contributing signed zeros to sums
    /// that are otherwise exact, and both operands are affine by admission so the literal
    /// is correct by construction.
    ///
    /// **Composition is not associative in binary64.** `VOXELIA-ALG-0052` registers a
    /// witness, and a consumer needing a specific result must fix its own grouping.
    /// `VOXELIA-ALG-0033`'s prohibition on folding an object-to-world with a world-to-view
    /// transform stays in force: this supplies composition, it does not authorise folding a
    /// chain an accepted record keeps separate.
    ///
    /// - Throws: ``AffineTransformError/nonAffineOperand``.
    public static func compose(
        _ outer: Matrix4x4Double,
        after inner: Matrix4x4Double
    ) throws -> Matrix4x4Double {
        guard isAffine(outer), isAffine(inner) else {
            throw AffineTransformError.nonAffineOperand
        }
        let a3 = block3(outer)
        let b3 = block3(inner)
        let at = translation(outer)
        let bt = translation(inner)

        var c3 = ContiguousArray<Double>(repeating: 0, count: 9)
        for row in 0..<3 {
            for column in 0..<3 {
                c3[3 * row + column] =
                    ((a3[3 * row + 0] * b3[0 * 3 + column]
                        + a3[3 * row + 1] * b3[1 * 3 + column])
                        + a3[3 * row + 2] * b3[2 * 3 + column])
            }
        }

        // The translation term is added last, after the three products accumulate.
        var ct = ContiguousArray<Double>(repeating: 0, count: 3)
        for row in 0..<3 {
            ct[row] =
                (((a3[3 * row + 0] * bt[0] + a3[3 * row + 1] * bt[1])
                    + a3[3 * row + 2] * bt[2]) + at[row])
        }

        return try Matrix4x4Double(elements: [
            c3[0], c3[1], c3[2], ct[0],
            c3[3], c3[4], c3[5], ct[1],
            c3[6], c3[7], c3[8], ct[2],
            0, 0, 0, 1,
        ])
    }

    /// Transforms a direction, which takes no translation.
    ///
    /// A **row** traversal of the spatial block, in deliberately the same expression order
    /// `ADR-0138` froze for its world-to-index step, so the two agree where they overlap
    /// rather than merely resembling each other.
    ///
    /// - Returns: the three transformed components, in order.
    /// - Throws: ``AffineTransformError/nonAffineOperand``.
    public static func transformVector(
        _ matrix: Matrix4x4Double,
        x: Double,
        y: Double,
        z: Double
    ) throws -> ContiguousArray<Double> {
        guard isAffine(matrix) else {
            throw AffineTransformError.nonAffineOperand
        }
        let m = block3(matrix)
        var result = ContiguousArray<Double>(repeating: 0, count: 3)
        for row in 0..<3 {
            result[row] =
                ((m[3 * row + 0] * x + m[3 * row + 1] * y) + m[3 * row + 2] * z)
        }
        return result
    }

    /// Transforms a normal, which is a covector and takes the **inverse transpose**.
    ///
    /// The inverse is `VOXELIA-ALG-0016`'s, composed unchanged rather than recomputed, and
    /// the traversal below is by **column** — which is what expresses the transpose. It
    /// must not be rewritten as a row traversal: that would silently compute the inverse
    /// applied to the normal and reintroduce the error this operation exists to prevent.
    ///
    /// ## The result is deliberately not normalised
    ///
    /// This is a linear map and it stops there. `VOXELIA-ALG-0030` publishes unit normals
    /// and `VOXELIA-ALG-0036` renormalises an interpolated direction before use;
    /// normalising here would duplicate that rule and make a chain of transformations
    /// differ from the composition of its matrices. A result that underflows to zero is
    /// therefore a value rather than a failure, and the undefined direction it represents
    /// is handled where normalisation happens.
    ///
    /// - Returns: the three transformed components, in order, unnormalised.
    /// - Throws: ``AffineTransformError/nonAffineOperand`` or
    ///   ``AffineSpatialInverseError/singularMatrix``.
    public static func transformNormal(
        _ matrix: Matrix4x4Double,
        x: Double,
        y: Double,
        z: Double
    ) throws -> ContiguousArray<Double> {
        guard isAffine(matrix) else {
            throw AffineTransformError.nonAffineOperand
        }
        let inverse = try AffineSpatialInverse(spatialPartOf: matrix).elements
        var result = ContiguousArray<Double>(repeating: 0, count: 3)
        for row in 0..<3 {
            result[row] =
                ((inverse[0 * 3 + row] * x + inverse[1 * 3 + row] * y)
                    + inverse[2 * 3 + row] * z)
        }
        return result
    }
}
