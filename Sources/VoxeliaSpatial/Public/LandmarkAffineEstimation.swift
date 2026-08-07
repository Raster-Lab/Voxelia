// SPDX-License-Identifier: MIT

/// An error raised by landmark-affine estimation admission.
///
/// Payload-free, like every other failure family in the project.
public enum LandmarkEstimationError: Error, Sendable, Equatable {
    /// The moving and fixed landmark counts differ.
    case countMismatch
    /// Fewer than four correspondence pairs were supplied.
    case insufficientLandmarks
    /// The landmark set is degenerate (coplanar or coincident): an
    /// elimination pivot fell below `Double.leastNormalMagnitude`, the
    /// `VOXELIA-ALG-0016` no-epsilon rule.
    case degenerateLandmarks
}

/// The frozen `landmark-affine/binary64-v1` model, specified by
/// `VOXELIA-ALG-0070` and accepted by `ADR-0368`.
///
/// Least-squares affine estimation over paired point correspondences:
/// frozen normal-equation assembly in ascending landmark order, one
/// augmented forward elimination with partial pivoting (largest pivot,
/// ties to the lowest row), and left-associative back substitution.
/// Determinism, not interpolation, is the promise — repeated estimation
/// over the same admitted landmarks is bit-identical, and the fixtures
/// pin the frozen elimination's own rounding.
public enum LandmarkAffineEstimation {
    /// Estimates the affine matrix mapping `moving` onto `fixed`.
    ///
    /// Coordinate-space attribution is deliberately not checked here —
    /// the registration face in `VoxeliaCore` owns that seam, exactly as
    /// `VOXELIA-ALG-0052` left space attribution to its consumers.
    ///
    /// - Throws: ``LandmarkEstimationError``.
    public static func estimate(
        moving: ContiguousArray<Point3D>,
        fixed: ContiguousArray<Point3D>
    ) throws -> Matrix4x4Double {
        guard moving.count == fixed.count else {
            throw LandmarkEstimationError.countMismatch
        }
        guard moving.count >= 4 else {
            throw LandmarkEstimationError.insufficientLandmarks
        }

        var normal = [Double](repeating: 0, count: 16)
        var rightHand = [Double](repeating: 0, count: 12)
        for index in moving.indices {
            let p = [moving[index].x, moving[index].y, moving[index].z, 1]
            let f = [fixed[index].x, fixed[index].y, fixed[index].z]
            for row in 0..<4 {
                for column in 0..<4 {
                    normal[4 * row + column] += p[row] * p[column]
                }
                for column in 0..<3 {
                    rightHand[3 * row + column] += p[row] * f[column]
                }
            }
        }

        // The augmented 4x7 system: normal columns then the three
        // right-hand columns.
        var augmented = [[Double]](repeating: [Double](repeating: 0, count: 7), count: 4)
        for row in 0..<4 {
            for column in 0..<4 {
                augmented[row][column] = normal[4 * row + column]
            }
            for column in 0..<3 {
                augmented[row][4 + column] = rightHand[3 * row + column]
            }
        }

        for column in 0..<4 {
            var pivotRow = column
            for row in (column + 1)..<4
            where abs(augmented[row][column]) > abs(augmented[pivotRow][column]) {
                pivotRow = row
            }
            guard abs(augmented[pivotRow][column]) >= Double.leastNormalMagnitude else {
                throw LandmarkEstimationError.degenerateLandmarks
            }
            if pivotRow != column {
                augmented.swapAt(column, pivotRow)
            }
            for row in (column + 1)..<4 {
                let factor = augmented[row][column] / augmented[column][column]
                for k in column..<7 {
                    augmented[row][k] -= factor * augmented[column][k]
                }
            }
        }

        var solvedRows = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 3)
        for column in 0..<3 {
            var solution = [Double](repeating: 0, count: 4)
            for i in stride(from: 3, through: 0, by: -1) {
                var accumulated = augmented[i][4 + column]
                for j in (i + 1)..<4 {
                    accumulated -= augmented[i][j] * solution[j]
                }
                solution[i] = accumulated / augmented[i][i]
            }
            solvedRows[column] = solution
        }

        return try Matrix4x4Double(elements: [
            solvedRows[0][0], solvedRows[0][1], solvedRows[0][2], solvedRows[0][3],
            solvedRows[1][0], solvedRows[1][1], solvedRows[1][2], solvedRows[1][3],
            solvedRows[2][0], solvedRows[2][1], solvedRows[2][2], solvedRows[2][3],
            0, 0, 0, 1,
        ])
    }
}
