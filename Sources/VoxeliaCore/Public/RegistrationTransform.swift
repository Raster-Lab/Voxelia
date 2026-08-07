// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised by registration-transform admission, per `ADR-0365`.
public enum RegistrationTransformError: Error, Sendable, Equatable {
    /// The affine matrix's bottom row was not exactly `0, 0, 0, 1`.
    case nonAffineMatrix
    /// The affine matrix's spatial block is singular.
    case singularAffineMatrix
    /// The displacement field is not a three-component `float32` vector
    /// image with the `deformationField` semantic, or declares no
    /// spatial geometry.
    case invalidDisplacementField
}

/// The affine registration category: a validated invertible affine
/// matrix, admitted through the existing exact machinery.
public struct AffineRegistrationTransform: Sendable, Hashable {
    public let matrix: Matrix4x4Double

    /// Creates an affine category member.
    ///
    /// Admission composes what already exists rather than rebuilding it:
    /// `AffineTransformAlgebra.isAffine` checks the exact bottom row and
    /// `AffineSpatialInverse` — the `VOXELIA-ALG-0016` determinant
    /// authority — proves invertibility.
    ///
    /// - Throws: ``RegistrationTransformError``.
    public init(matrix: Matrix4x4Double) throws {
        guard AffineTransformAlgebra.isAffine(matrix) else {
            throw RegistrationTransformError.nonAffineMatrix
        }
        do {
            _ = try AffineSpatialInverse(spatialPartOf: matrix)
        } catch {
            throw RegistrationTransformError.singularAffineMatrix
        }
        self.matrix = matrix
    }
}

/// The deformable registration category: a reference to a displacement
/// field, structurally admitted.
///
/// Field *evaluation* is deliberately absent here — interpolation of
/// displacements belongs to the operation that consumes the field.
public struct DeformableRegistrationTransform: Sendable {
    /// The displacement field: three `float32` vector components per
    /// sample, with a declared spatial geometry — a field that does not
    /// know where it lives cannot displace anything.
    public let displacementField: ImageData

    /// Creates a deformable category member.
    ///
    /// - Throws: ``RegistrationTransformError/invalidDisplacementField``.
    public init(displacementField: ImageData) throws {
        let descriptor = displacementField.descriptor
        guard
            descriptor.scalarFormat.type == .float32,
            descriptor.components.interpretation == .vector,
            descriptor.components.count == 3,
            descriptor.semantic == .deformationField,
            descriptor.spatialGeometry != nil
        else {
            throw RegistrationTransformError.invalidDisplacementField
        }
        self.displacementField = displacementField
    }
}

/// The closed, defaultless transform category vocabulary of
/// `VOX-REG-001`: rigid, affine and deformable are distinct **by type**,
/// and nothing infers a category from a matrix's numerical shape.
public enum RegistrationTransformCategory: Sendable {
    case rigid(RigidMotion)
    case affine(AffineRegistrationTransform)
    case deformable(DeformableRegistrationTransform)
}

/// One registration transform, per `ADR-0365`: a category plus the
/// source and destination coordinate spaces it maps between
/// (`VOX-REG-003`). Identity registrations within one space are
/// legitimate, so equal spaces are not refused.
public struct RegistrationTransform: Sendable {
    /// The space the transform maps points from.
    public let sourceSpace: CoordinateSpaceDescriptor
    /// The space the transform maps points into.
    public let destinationSpace: CoordinateSpaceDescriptor
    /// The distinct transform category.
    public let category: RegistrationTransformCategory

    public init(
        sourceSpace: CoordinateSpaceDescriptor,
        destinationSpace: CoordinateSpaceDescriptor,
        category: RegistrationTransformCategory
    ) {
        self.sourceSpace = sourceSpace
        self.destinationSpace = destinationSpace
        self.category = category
    }
}
