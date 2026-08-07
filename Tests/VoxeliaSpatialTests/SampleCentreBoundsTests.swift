// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@Suite("SampleCentreBounds")
struct SampleCentreBoundsTests {
    private func space(id: String = "patient") throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func geometry(
        spatial: [Double],
        translation: [Double]
    ) throws -> AffineGridGeometry {
        var elements = [Double](repeating: 0, count: 16)
        for row in 0...2 {
            for column in 0...2 {
                elements[4 * row + column] = spatial[3 * row + column]
            }
            elements[4 * row + 3] = translation[row]
        }
        elements[15] = 1
        return try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: elements),
            coordinateSpace: try space()
        )
    }

    private func identity() throws -> AffineGridGeometry {
        try geometry(
            spatial: [1, 0, 0, 0, 1, 0, 0, 0, 1],
            translation: [0, 0, 0]
        )
    }

    private func anisotropic(zSpacing: Double = 2.0) throws -> AffineGridGeometry {
        try geometry(
            spatial: [0.5, 0, 0, 0, 0.25, 0, 0, 0, zSpacing],
            translation: [10.5, -20.25, 0.125]
        )
    }

    private func components(
        _ bounds: AxisAlignedBounds3D
    ) -> (minimum: [Double], maximum: [Double]) {
        (
            [bounds.minimum.x, bounds.minimum.y, bounds.minimum.z],
            [bounds.maximum.x, bounds.maximum.y, bounds.maximum.z]
        )
    }

    @Test("[Unit][VOX-SPA-010] fixture 1: identity bounds are the outermost centres")
    func identityBoundsAreTheOutermostCentres() throws {
        let bounds = try identity().sampleCentreBounds(
            slot0SampleCount: 3,
            slot1SampleCount: 4,
            slot2SampleCount: 5
        )
        let result = components(bounds)
        #expect(result.minimum == [0, 0, 0])
        #expect(result.maximum == [2, 3, 4])
    }

    @Test("[Unit][VOX-SPA-010] fixture 2: anisotropic spacing with a non-zero origin")
    func anisotropicSpacingWithNonZeroOrigin() throws {
        let bounds = try anisotropic().sampleCentreBounds(
            slot0SampleCount: 16,
            slot1SampleCount: 8,
            slot2SampleCount: 4
        )
        let result = components(bounds)
        #expect(result.minimum == [10.5, -20.25, 0.125])
        #expect(result.maximum == [18.0, -18.5, 6.125])
    }

    @Test("[Unit][VOX-SPA-010] fixture 3: a flipped axis reorders through the fold")
    func flippedAxisReordersThroughTheFold() throws {
        let bounds = try anisotropic(zSpacing: -2.0).sampleCentreBounds(
            slot0SampleCount: 16,
            slot1SampleCount: 8,
            slot2SampleCount: 4
        )
        let result = components(bounds)
        #expect(result.minimum == [10.5, -20.25, -5.875])
        #expect(result.maximum == [18.0, -18.5, 0.125])
    }

    @Test("[Unit][VOX-SPA-010] fixture 4: an exact rotation with anisotropic scale")
    func exactRotationWithAnisotropicScale() throws {
        let bounds = try geometry(
            spatial: [0, -0.25, 0, 0.5, 0, 0, 0, 0, 2],
            translation: [1, 2, 3]
        ).sampleCentreBounds(
            slot0SampleCount: 3,
            slot1SampleCount: 5,
            slot2SampleCount: 2
        )
        let result = components(bounds)
        #expect(result.minimum == [0, 2, 3])
        #expect(result.maximum == [1, 3, 5])
    }

    @Test("[Unit][VOX-SPA-010] fixture 5: the hull needs corners the shortcut never visits")
    func hullNeedsCornersTheShortcutNeverVisits() throws {
        // World x is i - j. The registered wrong answer from transforming
        // only the two extreme index corners is the span [0, 1]; the true
        // hull spans [-2, 3] (VOXELIA-ALG-0054 fixture 5).
        let bounds = try geometry(
            spatial: [1, -1, 0, 0, 1, 0, 0, 0, 1],
            translation: [0, 0, 0]
        ).sampleCentreBounds(
            slot0SampleCount: 4,
            slot1SampleCount: 3,
            slot2SampleCount: 1
        )
        let result = components(bounds)
        #expect(result.minimum == [-2, 0, 0])
        #expect(result.maximum == [3, 2, 0])
        #expect(result.minimum[0] != 0, "the two-corner shortcut's lower bound")
        #expect(result.maximum[0] != 1, "the two-corner shortcut's upper bound")
    }

    @Test("[Unit][VOX-SPA-010] fixture 6: a single sample produces point bounds")
    func singleSampleProducesPointBounds() throws {
        let bounds = try anisotropic().sampleCentreBounds(
            slot0SampleCount: 1,
            slot1SampleCount: 1,
            slot2SampleCount: 1
        )
        let result = components(bounds)
        #expect(result.minimum == [10.5, -20.25, 0.125])
        #expect(result.maximum == [10.5, -20.25, 0.125])
    }

    @Test("[Unit][VOX-SPA-010] fixture 7: admission rejections name the slot and count")
    func admissionRejectionsNameTheSlotAndCount() throws {
        let geometry = try identity()
        #expect(throws: SampleCentreBoundsError.nonPositiveSampleCount(slot: 1, count: 0)) {
            try geometry.sampleCentreBounds(
                slot0SampleCount: 4,
                slot1SampleCount: 0,
                slot2SampleCount: 4
            )
        }
        #expect(throws: SampleCentreBoundsError.nonPositiveSampleCount(slot: 0, count: -3)) {
            try geometry.sampleCentreBounds(
                slot0SampleCount: -3,
                slot1SampleCount: 4,
                slot2SampleCount: 4
            )
        }
        let ceiling = AffineGridGeometry.sampleCentreBoundsSampleCountCeiling
        #expect(
            throws: SampleCentreBoundsError.sampleCountNotExactlyRepresentable(
                slot: 2,
                count: ceiling + 1
            )
        ) {
            try geometry.sampleCentreBounds(
                slot0SampleCount: 4,
                slot1SampleCount: 4,
                slot2SampleCount: ceiling + 1
            )
        }
    }

    @Test("[Unit][VOX-SPA-010] fixture 7: the ceiling itself is admitted exactly")
    func ceilingItselfIsAdmittedExactly() throws {
        let ceiling = AffineGridGeometry.sampleCentreBoundsSampleCountCeiling
        let bounds = try identity().sampleCentreBounds(
            slot0SampleCount: ceiling,
            slot1SampleCount: 1,
            slot2SampleCount: 1
        )
        #expect(bounds.maximum.x == 9007199254740991.0)
        #expect(bounds.minimum.x == 0)
    }

    @Test("[Unit][VOX-SPA-010] fixture 8: a product overflow names its corner and axis")
    func productOverflowNamesItsCornerAndAxis() throws {
        let geometry = try geometry(
            spatial: [1e300, 0, 0, 0, 1, 0, 0, 0, 1],
            translation: [0, 0, 0]
        )
        #expect(
            throws: SampleCentreBoundsError.cornerNotRepresentable(cornerOrdinal: 1, axis: 0)
        ) {
            try geometry.sampleCentreBounds(
                slot0SampleCount: AffineGridGeometry.sampleCentreBoundsSampleCountCeiling,
                slot1SampleCount: 2,
                slot2SampleCount: 2
            )
        }
    }

    @Test("[Unit][VOX-SPA-010] fixture 9: an accumulation overflow names its corner and axis")
    func accumulationOverflowNamesItsCornerAndAxis() throws {
        // Every individual product is finite; the sum overflows only at the
        // first corner combining both large terms (VOXELIA-ALG-0054 fixture 9).
        let geometry = try geometry(
            spatial: [1e308, 1e308, 0, 0, 1, 0, 0, 0, 1],
            translation: [0, 0, 0]
        )
        #expect(
            throws: SampleCentreBoundsError.cornerNotRepresentable(cornerOrdinal: 3, axis: 0)
        ) {
            try geometry.sampleCentreBounds(
                slot0SampleCount: 2,
                slot1SampleCount: 2,
                slot2SampleCount: 1
            )
        }
    }
}
