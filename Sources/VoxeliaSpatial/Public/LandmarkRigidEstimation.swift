// SPDX-License-Identifier: MIT

/// The frozen `landmark-rigid/binary64-v1` model, specified by
/// `VOXELIA-ALG-0071` and accepted by `ADR-0369`.
///
/// Horn's quaternion method realised deterministically: the rotation is
/// the leading eigenvector of Horn's symmetric matrix, computed by
/// cyclic Jacobi with exactly 30 sweeps in a frozen pair order — the
/// sweep count is part of the model, which is what makes repeated
/// estimation bit-identical. Exactly collinear or coincident landmark
/// sets refuse on both sides with no epsilon: a degenerate set leaves
/// the rotation about the landmark line unconstrained, and a silently
/// arbitrary rotation would be fabrication.
public enum LandmarkRigidEstimation {
    private static let sweeps = 30
    private static let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]

    /// Estimates the rigid motion mapping `moving` onto `fixed`.
    ///
    /// Coordinate-space attribution is deliberately not checked here —
    /// the registration face in `VoxeliaCore` owns that seam.
    ///
    /// - Throws: ``LandmarkEstimationError`` or ``RigidMotionError``.
    public static func estimate(
        moving: ContiguousArray<Point3D>,
        fixed: ContiguousArray<Point3D>
    ) throws -> RigidMotion {
        guard moving.count == fixed.count else {
            throw LandmarkEstimationError.countMismatch
        }
        guard moving.count >= 3 else {
            throw LandmarkEstimationError.insufficientLandmarks
        }
        let (centredMoving, meanMoving) = centred(moving)
        let (centredFixed, meanFixed) = centred(fixed)
        guard !exactlyCollinear(centredMoving), !exactlyCollinear(centredFixed) else {
            throw LandmarkEstimationError.degenerateLandmarks
        }

        var s = [Double](repeating: 0, count: 9)
        for index in centredMoving.indices {
            let m = centredMoving[index]
            let f = centredFixed[index]
            for row in 0..<3 {
                for column in 0..<3 {
                    s[3 * row + column] += m[row] * f[column]
                }
            }
        }
        let trace = (s[0] + s[4]) + s[8]
        var a: [[Double]] = [
            [trace, s[5] - s[7], s[6] - s[2], s[1] - s[3]],
            [s[5] - s[7], (s[0] - s[4]) - s[8], s[1] + s[3], s[6] + s[2]],
            [s[6] - s[2], s[1] + s[3], (s[4] - s[0]) - s[8], s[5] + s[7]],
            [s[1] - s[3], s[6] + s[2], s[5] + s[7], (s[8] - s[0]) - s[4]],
        ]
        var v: [[Double]] = [
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1],
        ]
        for _ in 0..<sweeps {
            for (p, q) in pairs {
                let offDiagonal = a[p][q]
                if offDiagonal == 0 { continue }
                let theta = (a[q][q] - a[p][p]) / (2 * offDiagonal)
                let sign: Double = theta >= 0 ? 1 : -1
                let t = sign / (abs(theta) + (theta * theta + 1).squareRoot())
                let c = 1 / (t * t + 1).squareRoot()
                let sn = t * c
                for k in 0..<4 {
                    let akp = a[k][p]
                    let akq = a[k][q]
                    a[k][p] = akp * c - akq * sn
                    a[k][q] = akp * sn + akq * c
                }
                for k in 0..<4 {
                    let apk = a[p][k]
                    let aqk = a[q][k]
                    a[p][k] = apk * c - aqk * sn
                    a[q][k] = apk * sn + aqk * c
                }
                for k in 0..<4 {
                    let vkp = v[k][p]
                    let vkq = v[k][q]
                    v[k][p] = vkp * c - vkq * sn
                    v[k][q] = vkp * sn + vkq * c
                }
            }
        }
        var best = 0
        for i in 1..<4 where a[i][i] > a[best][best] {
            best = i
        }
        // The unit-quaternion re-admission canonicalises; the
        // translation composes the ALG-0068 rotation of the moving
        // mean, so it derives from the canonical stored motion.
        let unrotated = try RigidMotion(
            quaternionW: v[0][best],
            quaternionX: v[1][best],
            quaternionY: v[2][best],
            quaternionZ: v[3][best],
            translationX: 0,
            translationY: 0,
            translationZ: 0
        )
        let r = try unrotated.matrix().elements
        var translation = [Double](repeating: 0, count: 3)
        for row in 0..<3 {
            translation[row] =
                meanFixed[row]
                - ((r[4 * row + 0] * meanMoving[0] + r[4 * row + 1] * meanMoving[1])
                    + r[4 * row + 2] * meanMoving[2])
        }
        // The raw eigenvector admits again (not the stored quaternion:
        // re-normalising an already-normalised quaternion could shift
        // its last bits), so the final stored form is bit-identical to
        // `unrotated`'s.
        return try RigidMotion(
            quaternionW: v[0][best],
            quaternionX: v[1][best],
            quaternionY: v[2][best],
            quaternionZ: v[3][best],
            translationX: translation[0],
            translationY: translation[1],
            translationZ: translation[2]
        )
    }

    private static func centred(
        _ points: ContiguousArray<Point3D>
    ) -> ([[Double]], [Double]) {
        let count = Double(points.count)
        var mean = [Double](repeating: 0, count: 3)
        for point in points {
            mean[0] += point.x
            mean[1] += point.y
            mean[2] += point.z
        }
        for c in 0..<3 {
            mean[c] /= count
        }
        let centredPoints = points.map {
            [$0.x - mean[0], $0.y - mean[1], $0.z - mean[2]]
        }
        return (Array(centredPoints), mean)
    }

    private static func exactlyCollinear(_ centredPoints: [[Double]]) -> Bool {
        guard let first = centredPoints.first(where: { $0 != [0, 0, 0] }) else {
            return true
        }
        for p in centredPoints {
            let cross = [
                first[1] * p[2] - first[2] * p[1],
                first[2] * p[0] - first[0] * p[2],
                first[0] * p[1] - first[1] * p[0],
            ]
            if cross != [0, 0, 0] {
                return false
            }
        }
        return true
    }
}
