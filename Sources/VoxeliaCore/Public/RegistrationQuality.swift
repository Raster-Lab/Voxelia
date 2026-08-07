// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised by quality-report admission, per `ADR-0373`.
public enum RegistrationQualityError: Error, Sendable, Equatable {
    /// The moving and fixed landmark counts differ.
    case countMismatch
    /// No landmarks were supplied.
    case emptyLandmarks
    /// A landmark was not expressed in the transform's declared space.
    case spaceMismatch
    /// A deformable transform's quality cannot be measured by a matrix
    /// it does not have — field evaluation does not exist yet.
    case unsupportedCategory
}

/// One host-facing quality report, per `ADR-0373` (`VOX-REG-009`):
/// per-landmark residual distances under the transform, in landmark
/// order, with their root mean square and maximum.
///
/// Which landmarks measure quality is the caller's declaration — the
/// fitting set measures fit, a held-out set measures target
/// registration error, and the report records numbers, not the claim.
public struct RegistrationQualityReport: Sendable, Hashable {
    public let residuals: ContiguousArray<Double>
    public let rootMeanSquare: Double
    public let maximum: Double

    public init(
        residuals: ContiguousArray<Double>,
        rootMeanSquare: Double,
        maximum: Double
    ) {
        self.residuals = residuals
        self.rootMeanSquare = rootMeanSquare
        self.maximum = maximum
    }
}

/// The geometric quality surface of the registration architecture, per
/// `VOXELIA-ALG-0073`.
public enum RegistrationQuality {
    /// Evaluates landmark residuals under an admitted transform.
    ///
    /// - Throws: ``RegistrationQualityError`` or the matrix
    ///   derivation's own typed errors.
    public static func evaluate(
        transform: RegistrationTransform,
        moving: ContiguousArray<Point3D>,
        fixed: ContiguousArray<Point3D>
    ) throws -> RegistrationQualityReport {
        guard moving.count == fixed.count else {
            throw RegistrationQualityError.countMismatch
        }
        guard !moving.isEmpty else {
            throw RegistrationQualityError.emptyLandmarks
        }
        for point in moving where point.coordinateSpace != transform.sourceSpace.id {
            throw RegistrationQualityError.spaceMismatch
        }
        for point in fixed where point.coordinateSpace != transform.destinationSpace.id {
            throw RegistrationQualityError.spaceMismatch
        }
        let matrix: ContiguousArray<Double>
        switch transform.category {
        case .rigid(let motion):
            matrix = try motion.matrix().elements
        case .affine(let affine):
            matrix = affine.matrix.elements
        case .deformable:
            throw RegistrationQualityError.unsupportedCategory
        }

        var residuals = ContiguousArray<Double>()
        residuals.reserveCapacity(moving.count)
        var total = 0.0
        for index in moving.indices {
            let m = moving[index]
            let f = fixed[index]
            let px = ((matrix[0] * m.x + matrix[1] * m.y) + matrix[2] * m.z) + matrix[3]
            let py = ((matrix[4] * m.x + matrix[5] * m.y) + matrix[6] * m.z) + matrix[7]
            let pz = ((matrix[8] * m.x + matrix[9] * m.y) + matrix[10] * m.z) + matrix[11]
            let dx = f.x - px
            let dy = f.y - py
            let dz = f.z - pz
            let squared = (dx * dx + dy * dy) + dz * dz
            let residual = squared.squareRoot()
            residuals.append(residual == 0 ? 0 : residual)
            total = total + squared
        }
        let meanSquared = total / Double(residuals.count)
        let rootMeanSquare = meanSquared.squareRoot()
        var maximum = residuals[0]
        for residual in residuals.dropFirst() where residual > maximum {
            maximum = residual
        }
        return RegistrationQualityReport(
            residuals: residuals,
            rootMeanSquare: rootMeanSquare == 0 ? 0 : rootMeanSquare,
            maximum: maximum
        )
    }
}
