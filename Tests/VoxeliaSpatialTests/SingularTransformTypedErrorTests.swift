// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaSpatial

/// `ADR-0281` (`VOX-SPA-009`): singular or non-invertible transforms produce typed
/// errors, and the two admissions that compute the determinant never disagree.
///
/// The typed errors themselves already existed and were already tested — by
/// `AffineSpatialInverseTests` and `SpatialGeometryTests` — but no test carried this row,
/// and one claim they rest on had never been checked.
///
/// `AffineWorldToIndexMap.init` documents its `singularMatrix` throw as "unreachable for a
/// validated geometry whose own admission computes the identical frozen determinant". Two
/// separately written expressions are claimed to agree bit-for-bit, and nothing verified
/// it. If they ever diverge, a geometry admitted by one layer would be refused by the
/// next, and the "unreachable" branch would fire in production.
@Suite("SingularTransformTypedError")
struct SingularTransformTypedErrorTests {
    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func matrix(_ elements: [Double]) throws -> Matrix4x4Double {
        try Matrix4x4Double(elements: elements)
    }

    /// A diagonal spatial block, which makes the determinant exactly the product.
    private func diagonal(_ a: Double, _ b: Double, _ c: Double) throws -> Matrix4x4Double {
        try matrix([
            a, 0, 0, 0,
            0, b, 0, 0,
            0, 0, c, 0,
            0, 0, 0, 1,
        ])
    }

    // MARK: - The typed errors

    @Test("[Unit][VOX-SPA-009] a singular spatial block is refused with a typed error")
    func singularBlockIsRefusedWithATypedError() throws {
        // Not a trap, not a `nil`, not a silent NaN: a named case a caller can switch on.
        #expect(throws: AffineSpatialInverseError.singularMatrix) {
            _ = try AffineSpatialInverse(spatialPartOf: try diagonal(0, 1, 1))
        }
        #expect(throws: AffineSpatialInverseError.singularMatrix) {
            _ = try AffineSpatialInverse(spatialPartOf: try diagonal(1, 1, 0))
        }
    }

    @Test("[Unit][VOX-SPA-009] a singular geometry is refused with a typed error")
    func singularGeometryIsRefusedWithATypedError() throws {
        let axes = try SpatialAxisMapping(imageAxes: [0, 1, 2])
        #expect(throws: SpatialGeometryError.singularTransform) {
            _ = try AffineGridGeometry(
                spatialAxes: axes,
                indexToWorld: try diagonal(0, 1, 1),
                coordinateSpace: try space()
            )
        }
    }

    @Test("[Unit][VOX-SPA-009] a non-invertible rank-deficient block is refused")
    func rankDeficientBlockIsRefused() throws {
        // Singular without a zero on the diagonal: the third row is the sum of the first
        // two, so the determinant is exactly zero in binary64 for these small integers.
        let dependent = try matrix([
            1, 2, 3, 0,
            4, 5, 6, 0,
            5, 7, 9, 0,
            0, 0, 0, 1,
        ])
        #expect(throws: AffineSpatialInverseError.singularMatrix) {
            _ = try AffineSpatialInverse(spatialPartOf: dependent)
        }
    }

    // MARK: - The claim the layering rests on

    @Test("[Unit][VOX-SPA-009] both admissions agree on every boundary case")
    func bothAdmissionsAgreeOnEveryBoundaryCase() throws {
        // `AffineWorldToIndexMap` calls its own singular throw unreachable because the
        // geometry's admission is claimed to compute the identical determinant. This
        // checks the two never disagree, which is the falsifiable form of that claim and
        // needs neither determinant to be exposed.
        let axes = try SpatialAxisMapping(imageAxes: [0, 1, 2])
        let descriptor = try space()
        let tiny = Double.leastNormalMagnitude

        let cases: [(String, Matrix4x4Double)] = [
            ("identity", try diagonal(1, 1, 1)),
            ("determinant exactly at the threshold", try diagonal(tiny, 1, 1)),
            ("determinant one ulp below the threshold", try diagonal(tiny.nextDown, 1, 1)),
            ("determinant exactly zero", try diagonal(0, 1, 1)),
            ("subnormal factor", try diagonal(Double.leastNonzeroMagnitude, 1, 1)),
            // A product that underflows to a subnormal even though no factor is small.
            ("underflowing product", try diagonal(tiny, 0.5, 0.5)),
            // Cancellation, where a different summation order would be visible.
            (
                "near-cancelling cofactors",
                try matrix([
                    1, 2, 3, 0,
                    4, 5, 6, 0,
                    7, 8, 9.000000000000002, 0,
                    0, 0, 0, 1,
                ])
            ),
            (
                "rank deficient",
                try matrix([
                    1, 2, 3, 0,
                    4, 5, 6, 0,
                    5, 7, 9, 0,
                    0, 0, 0, 1,
                ])
            ),
        ]

        var admittedCount = 0
        var refusedCount = 0
        for (label, candidate) in cases {
            let geometryAdmitted: Bool
            do {
                _ = try AffineGridGeometry(
                    spatialAxes: axes,
                    indexToWorld: candidate,
                    coordinateSpace: descriptor
                )
                geometryAdmitted = true
            } catch SpatialGeometryError.singularTransform {
                geometryAdmitted = false
            }

            let inverseAdmitted: Bool
            do {
                _ = try AffineSpatialInverse(spatialPartOf: candidate)
                inverseAdmitted = true
            } catch AffineSpatialInverseError.singularMatrix {
                inverseAdmitted = false
            }

            #expect(
                geometryAdmitted == inverseAdmitted,
                "\(label): geometry admitted \(geometryAdmitted) but inverse \(inverseAdmitted)"
            )
            if geometryAdmitted { admittedCount += 1 } else { refusedCount += 1 }
        }

        // Non-vacuity: the set must exercise both outcomes, or agreement is trivial.
        #expect(admittedCount > 0, "no case was admitted, so agreement proves nothing")
        #expect(refusedCount > 0, "no case was refused, so agreement proves nothing")
        #expect(admittedCount + refusedCount == cases.count)
    }

    @Test("[Unit][VOX-SPA-009] the threshold is exact, with no epsilon either side")
    func thresholdIsExactWithNoEpsilon() throws {
        // The admission is `magnitude >= Double.leastNormalMagnitude`, so the threshold
        // value itself admits and the value one ulp below refuses. Asserting both sides
        // is what makes this a boundary test rather than a smoke test.
        let tiny = Double.leastNormalMagnitude
        let atThreshold = try AffineSpatialInverse(spatialPartOf: try diagonal(tiny, 1, 1))
        #expect(atThreshold.determinant == tiny)

        #expect(throws: AffineSpatialInverseError.singularMatrix) {
            _ = try AffineSpatialInverse(spatialPartOf: try diagonal(tiny.nextDown, 1, 1))
        }
    }
}
