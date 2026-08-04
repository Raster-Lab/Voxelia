// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("PlaneAndRayTests")
struct PlaneAndRayTests {
    @Test("[Unit][VOX-SPA-011][VOX-SPA-003] preserves valid non-unit vectors")
    func preservesValidNonUnitVectors() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let origin = try Point3D(x: 1, y: 2, z: 3, coordinateSpace: space)
        let normal = try Vector3D(
            x: Double.greatestFiniteMagnitude,
            y: Double.leastNonzeroMagnitude,
            z: -2,
            coordinateSpace: space
        )
        let direction = try Vector3D(x: 4, y: 5, z: 6, coordinateSpace: space)

        let plane = try Plane3D(origin: origin, normal: normal)
        let ray = try Ray3D(origin: origin, direction: direction)

        #expect(plane.origin == origin)
        #expect(plane.normal == normal)
        #expect(ray.origin == origin)
        #expect(ray.direction == direction)
        #expect(
            plane.normal.x.bitPattern
                == Double.greatestFiniteMagnitude.bitPattern
        )
        #expect(
            plane.normal.y.bitPattern
                == Double.leastNonzeroMagnitude.bitPattern
        )
    }

    @Test("[Unit][VOX-ERR-001] rejects exact-zero normals and directions")
    func rejectsZeroVectors() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let origin = try Point3D(x: 1, y: 2, z: 3, coordinateSpace: space)
        let zero = try Vector3D(x: -0.0, y: 0, z: -0.0, coordinateSpace: space)

        #expect(throws: SpatialPrimitiveError.zeroNormal) {
            try Plane3D(origin: origin, normal: zero)
        }
        #expect(throws: SpatialPrimitiveError.zeroDirection) {
            try Ray3D(origin: origin, direction: zero)
        }
    }

    @Test("[Unit][VOX-SPA-003] accepts any finite vector with a non-zero component")
    func acceptsFiniteNonZeroEdges() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let origin = try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space)
        let subnormal = try Vector3D(
            x: Double.leastNonzeroMagnitude,
            y: 0,
            z: 0,
            coordinateSpace: space
        )
        let extreme = try Vector3D(
            x: Double.greatestFiniteMagnitude,
            y: -Double.greatestFiniteMagnitude,
            z: 0,
            coordinateSpace: space
        )

        #expect(try Plane3D(origin: origin, normal: subnormal).normal == subnormal)
        #expect(try Ray3D(origin: origin, direction: extreme).direction == extreme)
    }

    @Test("[Unit][VOX-SPA-001] rejects exact coordinate-space mismatches")
    func rejectsCoordinateSpaceMismatches() throws {
        let world = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let patient = try CoordinateSpaceID(validating: "org.voxelia.coordinate.patient")
        let origin = try Point3D(x: 1, y: 2, z: 3, coordinateSpace: world)
        let vector = try Vector3D(x: 1, y: 0, z: 0, coordinateSpace: patient)
        let expectedError = SpatialPrimitiveError.coordinateSpaceMismatch(
            expected: world,
            actual: patient
        )

        #expect(throws: expectedError) {
            try Plane3D(origin: origin, normal: vector)
        }
        #expect(throws: expectedError) {
            try Ray3D(origin: origin, direction: vector)
        }
    }

    @Test("[Unit][VOX-API-004] Codable preserves the exact public shape")
    func codableRoundTrips() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let origin = try Point3D(x: 1, y: 2, z: 3, coordinateSpace: space)
        let normal = try Vector3D(x: 0, y: 0, z: 2, coordinateSpace: space)
        let direction = try Vector3D(x: -4, y: 5, z: 0, coordinateSpace: space)
        let plane = try Plane3D(origin: origin, normal: normal)
        let ray = try Ray3D(origin: origin, direction: direction)

        let planeData = try JSONEncoder().encode(plane)
        let rayData = try JSONEncoder().encode(ray)

        #expect(try JSONDecoder().decode(Plane3D.self, from: planeData) == plane)
        #expect(try JSONDecoder().decode(Ray3D.self, from: rayData) == ray)
        let planeObject = try #require(
            JSONSerialization.jsonObject(with: planeData) as? [String: Any]
        )
        let rayObject = try #require(
            JSONSerialization.jsonObject(with: rayData) as? [String: Any]
        )
        #expect(Set(planeObject.keys) == ["origin", "normal"])
        #expect(Set(rayObject.keys) == ["origin", "direction"])
    }

    @Test("[Unit][VOX-ERR-001] decoding revalidates every composite invariant")
    func decodingRevalidatesInvariants() throws {
        expectExactWrongShapeDecoding(
            Plane3D.self,
            extraKeyJSON: #"{"origin":{},"normal":{},"extra":true}"#
        )
        expectExactWrongShapeDecoding(
            Ray3D.self,
            extraKeyJSON: #"{"origin":{},"direction":{},"extra":true}"#
        )

        let zeroPlane =
            #"{"origin":{"x":1,"y":2,"z":3,"coordinateSpace":{"rawValue":"world"}},"normal":{"x":0,"y":0,"z":0,"coordinateSpace":{"rawValue":"world"}}}"#
        let zeroRay =
            #"{"origin":{"x":1,"y":2,"z":3,"coordinateSpace":{"rawValue":"world"}},"direction":{"x":0,"y":0,"z":0,"coordinateSpace":{"rawValue":"world"}}}"#
        let mismatchPlane =
            #"{"origin":{"x":1,"y":2,"z":3,"coordinateSpace":{"rawValue":"world"}},"normal":{"x":1,"y":0,"z":0,"coordinateSpace":{"rawValue":"patient"}}}"#
        let mismatchRay =
            #"{"origin":{"x":1,"y":2,"z":3,"coordinateSpace":{"rawValue":"world"}},"direction":{"x":1,"y":0,"z":0,"coordinateSpace":{"rawValue":"patient"}}}"#

        expectInvalidCompositeDecoding(
            Plane3D.self,
            json: zeroPlane,
            field: "normal",
            underlyingError: .zeroNormal
        )
        expectInvalidCompositeDecoding(
            Ray3D.self,
            json: zeroRay,
            field: "direction",
            underlyingError: .zeroDirection
        )
        let world = try CoordinateSpaceID(validating: "world")
        let patient = try CoordinateSpaceID(validating: "patient")
        let mismatch = SpatialPrimitiveError.coordinateSpaceMismatch(
            expected: world,
            actual: patient
        )
        expectInvalidCompositeDecoding(
            Plane3D.self,
            json: mismatchPlane,
            field: "normal",
            underlyingError: mismatch
        )
        expectInvalidCompositeDecoding(
            Ray3D.self,
            json: mismatchRay,
            field: "direction",
            underlyingError: mismatch
        )

        let nonFinitePlane =
            #"{"origin":{"x":"NaN","y":2,"z":3,"coordinateSpace":{"rawValue":"world"}},"normal":{"x":1,"y":0,"z":0,"coordinateSpace":{"rawValue":"world"}}}"#
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        do {
            _ = try decoder.decode(Plane3D.self, from: Data(nonFinitePlane.utf8))
            #expect(Bool(false), "Expected nested non-finite decoding to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue).suffix(2) == ["origin", "x"])
            #expect(
                context.underlyingError as? SpatialPrimitiveError
                    == .nonFiniteComponent(index: 0)
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    private func expectExactWrongShapeDecoding<Value: Decodable>(
        _ type: Value.Type,
        extraKeyJSON: String
    ) {
        for wrongKeyValue in [#"{"origin":{}}"#, extraKeyJSON] {
            do {
                _ = try JSONDecoder().decode(type, from: Data(wrongKeyValue.utf8))
                #expect(Bool(false), "Expected a wrong-keyed composite to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(type, from: Data(#"[]"#.utf8))
            #expect(Bool(false), "Expected an array-shaped composite to fail decoding.")
        } catch DecodingError.typeMismatch {
            // The keyed-container request rejects the non-object shape.
        } catch {
            #expect(Bool(false), "Expected typeMismatch, received \(error).")
        }
    }

    private func expectInvalidCompositeDecoding<Value: Decodable>(
        _ type: Value.Type,
        json: String,
        field: String,
        underlyingError: SpatialPrimitiveError
    ) {
        do {
            _ = try JSONDecoder().decode(type, from: Data(json.utf8))
            #expect(Bool(false), "Expected composite decoding to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.last?.stringValue == field)
            #expect(context.underlyingError as? SpatialPrimitiveError == underlyingError)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }
}
