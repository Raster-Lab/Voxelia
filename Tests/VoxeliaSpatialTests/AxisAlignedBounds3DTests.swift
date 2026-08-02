// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("AxisAlignedBounds3D")
struct AxisAlignedBounds3DTests {
    @Test("[Unit][VOX-SPA-010][VOX-SPA-003] preserves finite boundary values")
    func preservesFiniteBoundaryValues() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let minimum = try Point3D(
            x: -Double.greatestFiniteMagnitude,
            y: -Double.leastNonzeroMagnitude,
            z: 0,
            coordinateSpace: space
        )
        let maximum = try Point3D(
            x: Double.greatestFiniteMagnitude,
            y: Double.leastNonzeroMagnitude,
            z: Double.leastNormalMagnitude,
            coordinateSpace: space
        )

        let bounds = try AxisAlignedBounds3D(minimum: minimum, maximum: maximum)

        #expect(bounds.minimum == minimum)
        #expect(bounds.maximum == maximum)
        #expect(
            bounds.minimum.x.bitPattern
                == (-Double.greatestFiniteMagnitude).bitPattern
        )
        #expect(
            bounds.maximum.y.bitPattern
                == Double.leastNonzeroMagnitude.bitPattern
        )
    }

    @Test("[Unit] accepts point, line, and plane degeneracy")
    func acceptsDegenerateBounds() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let point = try Point3D(x: -0.0, y: 2, z: 3, coordinateSpace: space)
        let lineMaximum = try Point3D(x: 4, y: 2, z: 3, coordinateSpace: space)
        let planeMaximum = try Point3D(x: 4, y: 5, z: 3, coordinateSpace: space)

        let pointBounds = try AxisAlignedBounds3D(minimum: point, maximum: point)
        let lineBounds = try AxisAlignedBounds3D(minimum: point, maximum: lineMaximum)
        let planeBounds = try AxisAlignedBounds3D(minimum: point, maximum: planeMaximum)

        #expect(pointBounds.minimum == pointBounds.maximum)
        #expect(lineBounds.minimum.y == lineBounds.maximum.y)
        #expect(lineBounds.minimum.z == lineBounds.maximum.z)
        #expect(planeBounds.minimum.z == planeBounds.maximum.z)
        #expect(pointBounds.minimum.x.bitPattern == Double(0).bitPattern)
    }

    @Test("[Unit][VOX-ERR-001] rejects every independently inverted axis")
    func rejectsInvertedAxesDeterministically() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        for axis in 0..<3 {
            var minimumComponents = [0.0, 0.0, 0.0]
            minimumComponents[axis] = Double.leastNonzeroMagnitude
            let minimum = try Point3D(
                x: minimumComponents[0],
                y: minimumComponents[1],
                z: minimumComponents[2],
                coordinateSpace: space
            )
            let maximum = try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space)

            #expect(
                throws: SpatialBoundsError.invertedBounds(
                    axis: axis,
                    minimum: Double.leastNonzeroMagnitude,
                    maximum: 0
                )
            ) {
                try AxisAlignedBounds3D(minimum: minimum, maximum: maximum)
            }
        }

        let first = try Point3D(x: 2, y: 2, z: 0, coordinateSpace: space)
        let second = try Point3D(x: 1, y: 1, z: 0, coordinateSpace: space)
        #expect(
            throws: SpatialBoundsError.invertedBounds(
                axis: 0,
                minimum: 2,
                maximum: 1
            )
        ) {
            try AxisAlignedBounds3D(minimum: first, maximum: second)
        }
    }

    @Test("[Unit][VOX-SPA-001] rejects coordinate-space mismatches")
    func rejectsCoordinateSpaceMismatch() throws {
        let world = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let patient = try CoordinateSpaceID(validating: "org.voxelia.coordinate.patient")
        let minimum = try Point3D(x: 0, y: 0, z: 0, coordinateSpace: world)
        let maximum = try Point3D(x: 1, y: 1, z: 1, coordinateSpace: patient)

        #expect(
            throws: SpatialBoundsError.coordinateSpaceMismatch(
                expected: world,
                actual: patient
            )
        ) {
            try AxisAlignedBounds3D(minimum: minimum, maximum: maximum)
        }
    }

    @Test("[Unit][VOX-API-004] value identity and Codable preserve exact structure")
    func valueIdentityAndCodableRoundTrip() throws {
        let world = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let patient = try CoordinateSpaceID(validating: "org.voxelia.coordinate.patient")
        let worldBounds = try bounds(in: world)
        let patientBounds = try bounds(in: patient)

        #expect(worldBounds != patientBounds)
        #expect(Set([worldBounds, patientBounds]).count == 2)

        let data = try JSONEncoder().encode(worldBounds)
        #expect(
            try JSONDecoder().decode(AxisAlignedBounds3D.self, from: data)
                == worldBounds
        )
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(Set(object.keys) == ["minimum", "maximum"])
    }

    @Test("[Unit][VOX-ERR-001] decoding is strict and revalidates bounds")
    func decodingIsStrictAndRevalidatesBounds() throws {
        let malformedValues = [
            #"{"minimum":{}}"#,
            #"{"minimum":{},"maximum":{},"extra":true}"#,
            #"[]"#,
        ]
        for malformedValue in malformedValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    AxisAlignedBounds3D.self,
                    from: Data(malformedValue.utf8)
                )
            }
        }

        let inverted =
            #"{"minimum":{"x":0,"y":2,"z":0,"coordinateSpace":{"rawValue":"world"}},"maximum":{"x":1,"y":1,"z":1,"coordinateSpace":{"rawValue":"world"}}}"#
        expectInvalidDecoding(
            json: inverted,
            pathSuffix: ["maximum", "y"],
            underlyingError: .invertedBounds(axis: 1, minimum: 2, maximum: 1)
        )

        let mismatched =
            #"{"minimum":{"x":0,"y":0,"z":0,"coordinateSpace":{"rawValue":"world"}},"maximum":{"x":1,"y":1,"z":1,"coordinateSpace":{"rawValue":"patient"}}}"#
        let world = try CoordinateSpaceID(validating: "world")
        let patient = try CoordinateSpaceID(validating: "patient")
        expectInvalidDecoding(
            json: mismatched,
            pathSuffix: ["maximum", "coordinateSpace"],
            underlyingError: .coordinateSpaceMismatch(
                expected: world,
                actual: patient
            )
        )

        let nonFinite =
            #"{"minimum":{"x":"NaN","y":0,"z":0,"coordinateSpace":{"rawValue":"world"}},"maximum":{"x":1,"y":1,"z":1,"coordinateSpace":{"rawValue":"world"}}}"#
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        do {
            _ = try decoder.decode(
                AxisAlignedBounds3D.self,
                from: Data(nonFinite.utf8)
            )
            #expect(Bool(false), "Expected nested non-finite decoding to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue).suffix(2) == ["minimum", "x"])
            #expect(
                context.underlyingError as? SpatialPrimitiveError
                    == .nonFiniteComponent(index: 0)
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    private func bounds(in space: CoordinateSpaceID) throws -> AxisAlignedBounds3D {
        let minimum = try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space)
        let maximum = try Point3D(x: 1, y: 2, z: 3, coordinateSpace: space)
        return try AxisAlignedBounds3D(minimum: minimum, maximum: maximum)
    }

    private func expectInvalidDecoding(
        json: String,
        pathSuffix: [String],
        underlyingError: SpatialBoundsError
    ) {
        do {
            _ = try JSONDecoder().decode(
                AxisAlignedBounds3D.self,
                from: Data(json.utf8)
            )
            #expect(Bool(false), "Expected invalid bounds decoding to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(
                Array(context.codingPath.map(\.stringValue).suffix(pathSuffix.count))
                    == pathSuffix
            )
            #expect(context.underlyingError as? SpatialBoundsError == underlyingError)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }
}
