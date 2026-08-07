// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("FrameGeometry")
struct FrameGeometryTests {
    private func space(_ id: String = "patient") throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func point(
        _ x: Double, _ y: Double, _ z: Double,
        space: String = "patient"
    ) throws -> Point3D {
        try Point3D(
            x: x,
            y: y,
            z: z,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: space))
        )
    }

    private func vector(
        _ x: Double, _ y: Double, _ z: Double,
        space: String = "patient"
    ) throws -> Vector3D {
        try Vector3D(
            x: x,
            y: y,
            z: z,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: space))
        )
    }

    private func rectilinear(
        slicePositions: ContiguousArray<Double>
    ) throws -> RectilinearGridGeometry {
        try RectilinearGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            coordinateSpace: try space(),
            origin: try point(0, 0, 0),
            rowDirection: try vector(1, 0, 0),
            columnDirection: try vector(0, 1, 0),
            normalDirection: try vector(0, 0, 1),
            rowSpacing: 0.5,
            columnSpacing: 0.5,
            slicePositions: slicePositions
        )
    }

    private func frame(_ z: Double) throws -> FramePlaneGeometry {
        try FramePlaneGeometry(
            origin: try point(0, 0, z),
            rowDirection: try vector(1, 0, 0),
            columnDirection: try vector(0, 1, 0),
            rowSpacing: 0.5,
            columnSpacing: 0.5,
            space: try #require(CoordinateSpaceID(rawValue: "patient"))
        )
    }

    @Test("[Unit][VOX-DCM-011][VOX-SPA-012] irregular geometry admits explicitly")
    func irregularGeometryAdmitsExplicitly() throws {
        // Irregular slice spacing is DATA here, not a defect: the model
        // stores it verbatim instead of regularising it away.
        let irregular = try rectilinear(slicePositions: [0, 1, 1.5, 4])
        #expect(irregular.slicePositions == [0, 1, 1.5, 4])

        // Descending order is monotone too.
        let descending = try rectilinear(slicePositions: [4, 1.5, 1, 0])
        #expect(descending.slicePositions.count == 4)

        let set = try FrameSetGeometry(
            coordinateSpace: try space(),
            frameAxis: 2,
            frames: [try frame(0), try frame(2), try frame(2.25)]
        )
        #expect(set.frames.count == 3)

        // Both enter the geometry vocabulary as their own cases.
        let geometry = SpatialGeometry.rectilinear(irregular)
        guard case .rectilinear = geometry else {
            Issue.record("the rectilinear case was lost")
            return
        }
    }

    @Test("[Unit][VOX-DCM-011] hidden regularisation is refused, not performed")
    func hiddenRegularisationIsRefusedNotPerformed() throws {
        // Exactly equal adjacent positions: deduplicating or averaging
        // would be the prohibited regularisation, so admission refuses.
        #expect(throws: FrameGeometryError.nonMonotoneSlicePositions) {
            _ = try rectilinear(slicePositions: [0, 1, 1, 2])
        }
        #expect(throws: FrameGeometryError.nonMonotoneSlicePositions) {
            _ = try rectilinear(slicePositions: [0, 2, 1])
        }
    }

    @Test("[Unit][VOX-DCM-011][VOX-SPA-012] coding round-trips revalidate")
    func codingRoundTripsRevalidate() throws {
        let original = SpatialGeometry.frameSet(
            try FrameSetGeometry(
                coordinateSpace: try space(),
                frameAxis: 2,
                frames: [try frame(0), try frame(1.25)]
            )
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SpatialGeometry.self, from: encoded)
        #expect(decoded == original)

        let rectilinearCase = SpatialGeometry.rectilinear(
            try rectilinear(slicePositions: [0, 1, 3])
        )
        let rectilinearEncoded = try JSONEncoder().encode(rectilinearCase)
        let rectilinearDecoded = try JSONDecoder().decode(
            SpatialGeometry.self,
            from: rectilinearEncoded
        )
        #expect(rectilinearDecoded == rectilinearCase)
    }

    @Test("[Unit][VOX-DCM-011] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: FrameGeometryError.emptyGeometry) {
            _ = try rectilinear(slicePositions: [])
        }
        #expect(throws: FrameGeometryError.invalidSlicePosition) {
            _ = try rectilinear(slicePositions: [0, .nan])
        }
        #expect(throws: FrameGeometryError.zeroDirection) {
            _ = try FramePlaneGeometry(
                origin: try point(0, 0, 0),
                rowDirection: try vector(0, 0, 0),
                columnDirection: try vector(0, 1, 0),
                rowSpacing: 0.5,
                columnSpacing: 0.5,
                space: try #require(CoordinateSpaceID(rawValue: "patient"))
            )
        }
        #expect(throws: FrameGeometryError.invalidSpacing) {
            _ = try FramePlaneGeometry(
                origin: try point(0, 0, 0),
                rowDirection: try vector(1, 0, 0),
                columnDirection: try vector(0, 1, 0),
                rowSpacing: 0,
                columnSpacing: 0.5,
                space: try #require(CoordinateSpaceID(rawValue: "patient"))
            )
        }
        #expect(throws: FrameGeometryError.spaceMismatch) {
            _ = try FrameSetGeometry(
                coordinateSpace: try space("somewhere-else"),
                frameAxis: 2,
                frames: [try frame(0)]
            )
        }
        #expect(throws: FrameGeometryError.invalidFrameAxis) {
            _ = try FrameSetGeometry(
                coordinateSpace: try space(),
                frameAxis: -1,
                frames: [try frame(0)]
            )
        }
        #expect(throws: FrameGeometryError.emptyGeometry) {
            _ = try FrameSetGeometry(
                coordinateSpace: try space(),
                frameAxis: 2,
                frames: []
            )
        }
    }
}
