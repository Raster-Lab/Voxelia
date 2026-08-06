// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaSpatial

/// `VOXELIA-ALG-0052` (`VOX-SPA-008`): affine composition, vector and normal
/// transformation, against the five fixtures `ADR-0283` registered.
///
/// Every fixture value is exactly representable in binary64, so every assertion is exact
/// equality. No tolerance appears anywhere in this suite and none is needed.
@Suite("AffineTransformAlgebra")
struct AffineTransformAlgebraTests {
    private func affine(
        _ block: [Double],
        _ translation: [Double]
    ) throws -> Matrix4x4Double {
        try Matrix4x4Double(elements: [
            block[0], block[1], block[2], translation[0],
            block[3], block[4], block[5], translation[1],
            block[6], block[7], block[8], translation[2],
            0, 0, 0, 1,
        ])
    }

    private func scale(_ x: Double, _ y: Double, _ z: Double) throws -> Matrix4x4Double {
        try affine([x, 0, 0, 0, y, 0, 0, 0, z], [0, 0, 0])
    }

    /// Applies a matrix to a point: the vector transformation plus the translation.
    private func transformPoint(
        _ matrix: Matrix4x4Double,
        _ x: Double,
        _ y: Double,
        _ z: Double
    ) throws -> [Double] {
        let directed = try AffineTransformAlgebra.transformVector(matrix, x: x, y: y, z: z)
        let m = matrix.elements
        return [directed[0] + m[3], directed[1] + m[7], directed[2] + m[11]]
    }

    // MARK: - Fixture 1, composition order

    /// `B` scales by two and translates by `(1, 0, 0)`.
    private func fixtureInner() throws -> Matrix4x4Double {
        try affine([2, 0, 0, 0, 2, 0, 0, 0, 2], [1, 0, 0])
    }

    /// `A` rotates minus ninety degrees about Z and translates by `(0, 0, 3)`.
    private func fixtureOuter() throws -> Matrix4x4Double {
        try affine([0, -1, 0, 1, 0, 0, 0, 0, 1], [0, 0, 3])
    }

    @Test("[Unit][VOX-SPA-008] fixture 1: composition produces the registered matrix")
    func fixtureOneProducesTheRegisteredMatrix() throws {
        let composed = try AffineTransformAlgebra.compose(
            try fixtureOuter(),
            after: try fixtureInner()
        )
        #expect(
            Array(composed.elements) == [
                0, -2, 0, 0,
                2, 0, 0, 1,
                0, 0, 2, 3,
                0, 0, 0, 1,
            ]
        )
    }

    @Test("[Unit][VOX-SPA-008] fixture 1: composing equals applying in stages")
    func fixtureOneComposingEqualsApplyingInStages() throws {
        // The property the operation exists for, checked against staged application rather
        // than against a transcribed matrix.
        let outer = try fixtureOuter()
        let inner = try fixtureInner()
        let composed = try AffineTransformAlgebra.compose(outer, after: inner)

        let direct = try transformPoint(composed, 1, 2, 3)
        let staged = try transformPoint(inner, 1, 2, 3)
        let restaged = try transformPoint(outer, staged[0], staged[1], staged[2])

        #expect(direct == [-4, 3, 9])
        #expect(direct == restaged)
    }

    @Test("[Unit][VOX-SPA-008] fixture 1: composition order is not symmetric")
    func fixtureOneCompositionOrderIsNotSymmetric() throws {
        let outer = try fixtureOuter()
        let inner = try fixtureInner()
        let forward = try AffineTransformAlgebra.compose(outer, after: inner)
        let reversed = try AffineTransformAlgebra.compose(inner, after: outer)
        #expect(forward != reversed)
    }

    // MARK: - Fixture 2, a vector ignores translation

    @Test("[Unit][VOX-SPA-008] fixture 2: a vector ignores translation, a point does not")
    func fixtureTwoVectorIgnoresTranslation() throws {
        let composed = try AffineTransformAlgebra.compose(
            try fixtureOuter(),
            after: try fixtureInner()
        )
        let directed = try AffineTransformAlgebra.transformVector(
            composed, x: 1, y: 2, z: 3)
        #expect(Array(directed) == [-4, 2, 6])
        #expect(try transformPoint(composed, 1, 2, 3) == [-4, 3, 9])
    }

    // MARK: - Fixture 3, the distinction the arc exists for

    @Test("[Unit][VOX-SPA-008] fixture 3: a normal differs from a vector under scale")
    func fixtureThreeNormalDiffersFromVectorUnderScale() throws {
        // `ADR-0280`'s finding, made executable. Under an anisotropic scale the two rules
        // give different directions, and treating a normal as a vector is the error.
        let matrix = try scale(1, 1, 5)
        let asVector = try AffineTransformAlgebra.transformVector(
            matrix, x: 0, y: 1, z: 1)
        let asNormal = try AffineTransformAlgebra.transformNormal(
            matrix, x: 0, y: 1, z: 1)
        #expect(Array(asVector) == [0, 1, 5])
        #expect(Array(asNormal) == [0, 1, 0.2])
        #expect(asVector != asNormal)
    }

    // MARK: - Fixture 4, when the two rules agree

    @Test("[Unit][VOX-SPA-008] fixture 4: the two rules agree under a pure rotation")
    func fixtureFourRulesAgreeUnderPureRotation() throws {
        // Because the inverse transpose of a rotation is the rotation itself. Recorded so
        // fixture 3 is not read as "the rules always differ": they differ exactly when the
        // transform is not orthonormal.
        let rotation = try affine([1, 0, 0, 0, 0, -1, 0, 1, 0], [0, 0, 0])
        let asVector = try AffineTransformAlgebra.transformVector(
            rotation, x: 0, y: 0, z: 1)
        let asNormal = try AffineTransformAlgebra.transformNormal(
            rotation, x: 0, y: 0, z: 1)
        #expect(Array(asNormal) == [0, -1, 0])
        #expect(asVector == asNormal)
    }

    // MARK: - Fixture 5, non-associativity

    @Test("[Unit][VOX-SPA-008] fixture 5: composition is not associative")
    func fixtureFiveCompositionIsNotAssociative() throws {
        // A consumer would reasonably assume otherwise, so the witness is a test rather
        // than a sentence in a specification.
        let x = try scale(1e300, 1, 1)
        let y = try scale(1e-300, 1, 1)
        let z = try scale(3, 1, 1)

        let leftGrouped = try AffineTransformAlgebra.compose(
            try AffineTransformAlgebra.compose(x, after: y), after: z)
        let rightGrouped = try AffineTransformAlgebra.compose(
            x, after: try AffineTransformAlgebra.compose(y, after: z))

        #expect(leftGrouped.elements[0] == 3.0)
        #expect(rightGrouped.elements[0] == 3.0000000000000004)
        #expect(leftGrouped != rightGrouped)
    }

    // MARK: - Admission and composition of the accepted inverse

    @Test("[Unit][VOX-SPA-008] a non-affine operand is refused")
    func nonAffineOperandIsRefused() throws {
        let projective = try Matrix4x4Double(elements: [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 1, 1,
        ])
        let identity = try scale(1, 1, 1)

        #expect(throws: AffineTransformError.nonAffineOperand) {
            _ = try AffineTransformAlgebra.compose(projective, after: identity)
        }
        #expect(throws: AffineTransformError.nonAffineOperand) {
            _ = try AffineTransformAlgebra.compose(identity, after: projective)
        }
        #expect(throws: AffineTransformError.nonAffineOperand) {
            _ = try AffineTransformAlgebra.transformVector(projective, x: 1, y: 1, z: 1)
        }
        #expect(throws: AffineTransformError.nonAffineOperand) {
            _ = try AffineTransformAlgebra.transformNormal(projective, x: 1, y: 1, z: 1)
        }
        #expect(!AffineTransformAlgebra.isAffine(projective))
        #expect(AffineTransformAlgebra.isAffine(identity))
    }

    @Test("[Unit][VOX-SPA-008] a normal transformation composes the accepted inverse")
    func normalTransformationComposesTheAcceptedInverse() throws {
        // The specification requires the inverse to be composed rather than
        // reimplemented, so a singular matrix must surface `ALG-0016`'s own error rather
        // than a new one.
        let singular = try scale(0, 1, 1)
        #expect(throws: AffineSpatialInverseError.singularMatrix) {
            _ = try AffineTransformAlgebra.transformNormal(singular, x: 0, y: 1, z: 1)
        }
    }

    @Test("[Unit][VOX-SPA-008] a transformed normal is not normalised")
    func transformedNormalIsNotNormalised() throws {
        // Deliberate: normalisation is `ALG-0030`'s and `ALG-0036`'s rule, and applying it
        // here would break the correspondence between transforming twice and transforming
        // by the composition.
        let matrix = try scale(1, 1, 5)
        let transformed = try AffineTransformAlgebra.transformNormal(
            matrix, x: 0, y: 4, z: 4)
        #expect(Array(transformed) == [0, 4, 0.8])
        let lengthSquared =
            (transformed[0] * transformed[0] + transformed[1] * transformed[1])
            + transformed[2] * transformed[2]
        #expect(lengthSquared != 1)
    }

    @Test("[Unit][VOX-SPA-008] composing with the identity returns the operand exactly")
    func composingWithIdentityReturnsOperandExactly() throws {
        let identity = try scale(1, 1, 1)
        let matrix = try affine([2, 3, 5, 7, 11, 13, 17, 19, 23], [29, 31, 37])
        #expect(try AffineTransformAlgebra.compose(matrix, after: identity) == matrix)
        #expect(try AffineTransformAlgebra.compose(identity, after: matrix) == matrix)
    }
}
