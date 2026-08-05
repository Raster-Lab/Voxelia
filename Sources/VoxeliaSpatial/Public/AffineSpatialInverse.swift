// SPDX-License-Identifier: MIT

/// An error raised while inverting an affine spatial block.
public enum AffineSpatialInverseError: Error, Sendable, Equatable {
    /// The computed determinant magnitude fell below
    /// `Double.leastNormalMagnitude` — the accepted no-epsilon
    /// admission rule.
    case singularMatrix
}

/// The frozen `affine-inverse/binary64-v1` model selected by accepted
/// `ADR-0136` and specified by `VOXELIA-ALG-0016`.
///
/// The inverse of the upper-left three-by-three spatial block of a
/// validated matrix evaluates through the adjugate: every two-by-two
/// cofactor uses the one frozen form `(a * d) - (b * c)`, the
/// determinant expands along row zero as
/// `((m00 * c0) - (m01 * c1)) + (m02 * c2)`, and each inverse entry
/// is the signed transposed cofactor divided by the computed
/// determinant — one correctly rounded division per entry and no
/// fused multiply-add anywhere. Repeated evaluation is bit-identical.
/// Composition with a world offset is the consuming operation's own
/// frozen step per the specification.
public struct AffineSpatialInverse: Sendable, Hashable {
    /// The nine row-major inverse entries.
    public let elements: ContiguousArray<Double>

    /// The computed determinant of the source spatial block.
    public let determinant: Double

    /// The specification's conservative elementwise error bounds,
    /// computed from the same rounded intermediates for the
    /// measurement harness.
    let elementwiseErrorBounds: ContiguousArray<Double>

    /// Inverts the upper-left three-by-three spatial block of the
    /// validated matrix.
    ///
    /// - Throws: ``AffineSpatialInverseError/singularMatrix`` when
    ///   the computed determinant magnitude falls below the
    ///   no-epsilon `Double.leastNormalMagnitude` threshold.
    public init(spatialPartOf matrix: Matrix4x4Double) throws {
        func cofactor(
            _ a: Double, _ d: Double, _ b: Double, _ c: Double
        ) -> (value: Double, magnitudeSum: Double) {
            let leading = a * d
            let trailing = b * c
            return (leading - trailing, leading.magnitude + trailing.magnitude)
        }

        // Minors are named by the inverse entry their signed
        // transposed cofactor produces, not by their source position.
        let m = matrix.elements
        let minor00 = cofactor(m[5], m[10], m[6], m[9])
        let minor01 = cofactor(m[1], m[10], m[2], m[9])
        let minor02 = cofactor(m[1], m[6], m[2], m[5])
        let minor10 = cofactor(m[4], m[10], m[6], m[8])
        let minor11 = cofactor(m[0], m[10], m[2], m[8])
        let minor12 = cofactor(m[0], m[6], m[2], m[4])
        let minor20 = cofactor(m[4], m[9], m[5], m[8])
        let minor21 = cofactor(m[0], m[9], m[1], m[8])
        let minor22 = cofactor(m[0], m[5], m[1], m[4])

        let det =
            ((m[0] * minor00.value) - (m[1] * minor10.value))
            + (m[2] * minor20.value)
        guard det.magnitude >= Double.leastNormalMagnitude else {
            throw AffineSpatialInverseError.singularMatrix
        }

        let unit = 0x1p-53
        let gamma2 = (2 * unit) / (1 - 2 * unit)
        let gamma4 = (4 * unit) / (1 - 4 * unit)
        let determinantMagnitudeSum =
            (m[0] * minor00.value).magnitude
            + (m[1] * minor10.value).magnitude
            + (m[2] * minor20.value).magnitude
        let determinantBound =
            gamma4 * determinantMagnitudeSum
            + m[0].magnitude * gamma2 * minor00.magnitudeSum
            + m[1].magnitude * gamma2 * minor10.magnitudeSum
            + m[2].magnitude * gamma2 * minor20.magnitudeSum

        let signedMinors: [(value: Double, magnitudeSum: Double)] = [
            (minor00.value, minor00.magnitudeSum),
            (-minor01.value, minor01.magnitudeSum),
            (minor02.value, minor02.magnitudeSum),
            (-minor10.value, minor10.magnitudeSum),
            (minor11.value, minor11.magnitudeSum),
            (-minor12.value, minor12.magnitudeSum),
            (minor20.value, minor20.magnitudeSum),
            (-minor21.value, minor21.magnitudeSum),
            (minor22.value, minor22.magnitudeSum),
        ]
        var inverseElements = ContiguousArray<Double>()
        var bounds = ContiguousArray<Double>()
        inverseElements.reserveCapacity(9)
        bounds.reserveCapacity(9)
        for (signedMinor, magnitudeSum) in signedMinors {
            inverseElements.append(signedMinor / det)
            bounds.append(
                (gamma2 * magnitudeSum
                    + signedMinor.magnitude * (determinantBound / det.magnitude))
                    / det.magnitude * (1 + unit)
                    + unit * (signedMinor / det).magnitude
            )
        }
        elements = inverseElements
        determinant = det
        elementwiseErrorBounds = bounds
    }
}
