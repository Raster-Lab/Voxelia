// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised by registration-transform composition, per
/// `ADR-0367`.
public enum RegistrationCompositionError: Error, Sendable, Equatable {
    /// The inner transform's destination space was not the outer
    /// transform's source space.
    case incompatibleSpaces
    /// A deformable operand cannot compose before field evaluation
    /// exists — a composed field built without evaluating would be
    /// fabrication.
    case unsupportedComposition
}

/// The one place two registration transforms become one, per `ADR-0367`
/// (`VOX-REG-004`): the seam is validated as **full-descriptor** space
/// equality — two spaces sharing an identifier but disagreeing about
/// convention are a lie, not a match.
public enum RegistrationTransformComposition {
    /// Composes `outer` applied after `inner`.
    ///
    /// The result spans the chain: the inner's source to the outer's
    /// destination. Rigid pairs stay rigid (`VOXELIA-ALG-0069`); mixed
    /// rigid/affine pairs lower to `VOXELIA-ALG-0052` matrix composition
    /// and re-admit as affine — the category honestly widens. Deformable
    /// operands are refused.
    ///
    /// - Throws: ``RegistrationCompositionError``.
    public static func compose(
        _ outer: RegistrationTransform,
        after inner: RegistrationTransform
    ) throws -> RegistrationTransform {
        guard inner.destinationSpace == outer.sourceSpace else {
            throw RegistrationCompositionError.incompatibleSpaces
        }
        let category: RegistrationTransformCategory
        switch (outer.category, inner.category) {
        case (.deformable, _), (_, .deformable):
            throw RegistrationCompositionError.unsupportedComposition
        case (.rigid(let outerMotion), .rigid(let innerMotion)):
            category = .rigid(try RigidMotion.composed(outerMotion, after: innerMotion))
        case (.rigid(let outerMotion), .affine(let innerAffine)):
            category = .affine(
                try AffineRegistrationTransform(
                    matrix: try AffineTransformAlgebra.compose(
                        outerMotion.matrix(),
                        after: innerAffine.matrix
                    )
                )
            )
        case (.affine(let outerAffine), .rigid(let innerMotion)):
            category = .affine(
                try AffineRegistrationTransform(
                    matrix: try AffineTransformAlgebra.compose(
                        outerAffine.matrix,
                        after: innerMotion.matrix()
                    )
                )
            )
        case (.affine(let outerAffine), .affine(let innerAffine)):
            category = .affine(
                try AffineRegistrationTransform(
                    matrix: try AffineTransformAlgebra.compose(
                        outerAffine.matrix,
                        after: innerAffine.matrix
                    )
                )
            )
        }
        return RegistrationTransform(
            sourceSpace: inner.sourceSpace,
            destinationSpace: outer.destinationSpace,
            category: category
        )
    }
}
