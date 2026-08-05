// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@Suite("AffineWorldToIndexMap")
struct AffineWorldToIndexMapTests {
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

    @Test("[Unit][VOX-SPA-004] the exact fixture round-trips through the map")
    func exactFixtureRoundTripsThroughTheMap() throws {
        // The forward image of index (3, 4, 5) under the exact
        // rotation-scale fixture with translation (10, 20, 30) is
        // world (2, 26, 35); the frozen composition recovers the
        // indices exactly.
        let map = try AffineWorldToIndexMap(
            geometry: try geometry(
                spatial: [0, -2, 0, 2, 0, 0, 0, 0, 1],
                translation: [10, 20, 30]
            )
        )
        let point = try Point3D(
            x: 2,
            y: 26,
            z: 35,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: "patient"))
        )
        #expect(try map.continuousSlotIndices(of: point) == [3, 4, 5])
        #expect(try map.continuousIndex(forImageAxis: 2, of: point) == 5)
    }

    @Test("[Unit][VOX-SPA-004] the symmetric fixture matches the frozen spellings")
    func symmetricFixtureMatchesTheFrozenSpellings() throws {
        // Independently computed under the frozen order for the
        // symmetric ALG-0016 fixture with translation (1, 2, 3) and
        // world point (5, -1, 2); the exact rationals are 60/49,
        // -44/49 and 13/98, and the frozen binary64 slot two differs
        // from the nearest-to-exact spelling in its final digit.
        let map = try AffineWorldToIndexMap(
            geometry: try geometry(
                spatial: [4, 1, 0, 1, 5, 2, 0, 2, 6],
                translation: [1, 2, 3]
            )
        )
        let point = try Point3D(
            x: 5,
            y: -1,
            z: 2,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: "patient"))
        )
        let slots = try map.continuousSlotIndices(of: point)
        #expect(slots[0] == 1.2244897959183674)
        #expect(slots[1] == -0.8979591836734694)
        #expect(slots[2] == 0.13265306122448978)
    }

    @Test("[Unit][VOX-SPA-004][VOX-ERR-001] the map admissions reject typed")
    func mapAdmissionsRejectTyped() throws {
        // A point in a foreign coordinate space and an unmapped image
        // axis both reject typed; mapping either silently would
        // fabricate a calibration.
        let map = try AffineWorldToIndexMap(
            geometry: try geometry(
                spatial: [0, -2, 0, 2, 0, 0, 0, 0, 1],
                translation: [10, 20, 30]
            )
        )
        let foreign = try Point3D(
            x: 2,
            y: 26,
            z: 35,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: "device"))
        )
        #expect(throws: AffineWorldToIndexError.coordinateSpaceMismatch) {
            try map.continuousSlotIndices(of: foreign)
        }
        let point = try Point3D(
            x: 2,
            y: 26,
            z: 35,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: "patient"))
        )
        #expect(throws: AffineWorldToIndexError.axisNotSpatiallyMapped) {
            try map.continuousIndex(forImageAxis: 7, of: point)
        }
    }
}
