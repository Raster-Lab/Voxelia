// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaSpatial

@Suite("CurvedCentreline")
struct CurvedCentrelineTests {
    private func space(_ id: String = "patient") throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func points(
        _ coordinates: [(Double, Double, Double)],
        space: String = "patient"
    ) throws -> ContiguousArray<Point3D> {
        var out = ContiguousArray<Point3D>()
        for (x, y, z) in coordinates {
            out.append(
                try Point3D(
                    x: x,
                    y: y,
                    z: z,
                    coordinateSpace: try #require(CoordinateSpaceID(rawValue: space))
                )
            )
        }
        return out
    }

    private func elbow() throws -> CurvedCentreline {
        try CurvedCentreline(
            coordinateSpace: try space(),
            points: try points([(0, 0, 0), (3, 0, 0), (3, 4, 0)])
        )
    }

    @Test("[Unit][VOX-MPR-012] the elbow parameterises with exact marks")
    func theElbowParameterisesWithExactMarks() throws {
        let centreline = try elbow()
        #expect(centreline.segmentLengths == [3, 4])
        #expect(centreline.cumulativeArcLengths == [0, 3, 7])
        #expect(centreline.totalArcLength == 7)

        let interior = try centreline.position(atArcLength: 1.5)
        #expect(interior.x == 1.5 && interior.y == 0 && interior.z == 0)

        // A mark hit lands on the vertex exactly, by rule.
        let vertex = try centreline.position(atArcLength: 3)
        #expect(vertex.x == 3 && vertex.y == 0 && vertex.z == 0)

        let second = try centreline.position(atArcLength: 5.5)
        #expect(second.x == 3 && second.y == 2.5 && second.z == 0)

        // The total returns the last point verbatim.
        let end = try centreline.position(atArcLength: 7)
        #expect(end.x == 3 && end.y == 4 && end.z == 0)
    }

    @Test("[Unit][VOX-MPR-012] the diagonal pins the frozen rounding")
    func theDiagonalPinsTheFrozenRounding() throws {
        let centreline = try CurvedCentreline(
            coordinateSpace: try space(),
            points: try points([(0, 0, 0), (1, 1, 0)])
        )
        #expect(centreline.totalArcLength == 0x1.6a09e667f3bcdp+0)
        let position = try centreline.position(atArcLength: 1)
        #expect(position.x == 0x1.6a09e667f3bccp-1)
        #expect(position.y == 0x1.6a09e667f3bccp-1)
        #expect(position.z == 0)
    }

    @Test("[Unit][VOX-MPR-012] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: CurvedCentrelineError.insufficientPoints) {
            _ = try CurvedCentreline(
                coordinateSpace: try space(),
                points: try points([(0, 0, 0)])
            )
        }
        #expect(throws: CurvedCentrelineError.spaceMismatch) {
            _ = try CurvedCentreline(
                coordinateSpace: try space(),
                points: try points([(0, 0, 0), (1, 0, 0)], space: "somewhere-else")
            )
        }
        #expect(throws: CurvedCentrelineError.zeroLengthSegment) {
            _ = try CurvedCentreline(
                coordinateSpace: try space(),
                points: try points([(0, 0, 0), (0, 0, 0), (1, 0, 0)])
            )
        }
        let centreline = try elbow()
        #expect(throws: CurvedCentrelineError.arcLengthOutOfRange) {
            _ = try centreline.position(atArcLength: -0.5)
        }
        #expect(throws: CurvedCentrelineError.arcLengthOutOfRange) {
            _ = try centreline.position(atArcLength: 7.5)
        }
        #expect(throws: CurvedCentrelineError.arcLengthOutOfRange) {
            _ = try centreline.position(atArcLength: .nan)
        }
    }
}
