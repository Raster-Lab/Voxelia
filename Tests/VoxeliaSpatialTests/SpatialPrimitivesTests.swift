// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("SpatialPrimitives")
struct SpatialPrimitivesTests {
    @Test("[Unit][VOX-SPA-003] preserves finite Double point and vector values")
    func preservesFiniteValues() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let point = try Point3D(
            x: Double.greatestFiniteMagnitude,
            y: Double.leastNonzeroMagnitude,
            z: -Double.leastNormalMagnitude,
            coordinateSpace: space
        )
        let vector = try Vector3D(
            x: -Double.greatestFiniteMagnitude,
            y: Double.leastNormalMagnitude,
            z: Double.leastNonzeroMagnitude,
            coordinateSpace: space
        )

        #expect(point.x.bitPattern == Double.greatestFiniteMagnitude.bitPattern)
        #expect(point.y.bitPattern == Double.leastNonzeroMagnitude.bitPattern)
        #expect(point.z.bitPattern == (-Double.leastNormalMagnitude).bitPattern)
        #expect(vector.x.bitPattern == (-Double.greatestFiniteMagnitude).bitPattern)
        #expect(vector.y.bitPattern == Double.leastNormalMagnitude.bitPattern)
        #expect(vector.z.bitPattern == Double.leastNonzeroMagnitude.bitPattern)
    }

    @Test("[Unit][VOX-ERR-001] rejects every non-finite component by index")
    func rejectsNonFiniteComponents() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        for value in [Double.nan, Double.infinity, -Double.infinity] {
            for index in 0..<3 {
                var components = [1.0, 2.0, 3.0]
                components[index] = value
                #expect(throws: SpatialPrimitiveError.nonFiniteComponent(index: index)) {
                    try Point3D(
                        x: components[0],
                        y: components[1],
                        z: components[2],
                        coordinateSpace: space
                    )
                }
                #expect(throws: SpatialPrimitiveError.nonFiniteComponent(index: index)) {
                    try Vector3D(
                        x: components[0],
                        y: components[1],
                        z: components[2],
                        coordinateSpace: space
                    )
                }
            }
        }
    }

    @Test("[Unit] permits a general zero vector without implicit normalization")
    func permitsZeroVector() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let vector = try Vector3D(x: 0, y: 0, z: 0, coordinateSpace: space)

        #expect(vector.x == 0)
        #expect(vector.y == 0)
        #expect(vector.z == 0)
    }

    @Test("[Unit][VOX-API-004] canonicalizes signed zero only")
    func canonicalizesSignedZero() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let point = try Point3D(
            x: -0.0,
            y: Double.leastNonzeroMagnitude,
            z: -0.0,
            coordinateSpace: space
        )
        let vector = try Vector3D(
            x: -0.0,
            y: -0.0,
            z: Double.leastNormalMagnitude,
            coordinateSpace: space
        )

        #expect(point.x.bitPattern == Double(0).bitPattern)
        #expect(point.z.bitPattern == Double(0).bitPattern)
        #expect(vector.x.bitPattern == Double(0).bitPattern)
        #expect(vector.y.bitPattern == Double(0).bitPattern)
        #expect(point.y.bitPattern == Double.leastNonzeroMagnitude.bitPattern)
        #expect(vector.z.bitPattern == Double.leastNormalMagnitude.bitPattern)
        #expect(!String(decoding: try JSONEncoder().encode(point), as: UTF8.self).contains("-0"))
        #expect(!String(decoding: try JSONEncoder().encode(vector), as: UTF8.self).contains("-0"))
    }

    @Test("[Unit][VOX-SPA-001] coordinate space participates in value identity")
    func distinguishesCoordinateSpaces() throws {
        let world = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let patient = try CoordinateSpaceID(validating: "org.voxelia.coordinate.patient")
        let worldPoint = try Point3D(x: 1, y: 2, z: 3, coordinateSpace: world)
        let patientPoint = try Point3D(x: 1, y: 2, z: 3, coordinateSpace: patient)
        let worldVector = try Vector3D(x: 1, y: 2, z: 3, coordinateSpace: world)
        let patientVector = try Vector3D(x: 1, y: 2, z: 3, coordinateSpace: patient)

        #expect(worldPoint != patientPoint)
        #expect(Set([worldPoint, patientPoint]).count == 2)
        #expect(worldVector != patientVector)
        #expect(Set([worldVector, patientVector]).count == 2)
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] Codable preserves structure and revalidates input")
    func codableRoundTripAndValidation() throws {
        let space = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let point = try Point3D(x: 1, y: 2, z: 3, coordinateSpace: space)
        let vector = try Vector3D(x: -1, y: -2, z: -3, coordinateSpace: space)

        let pointData = try JSONEncoder().encode(point)
        let vectorData = try JSONEncoder().encode(vector)
        #expect(try JSONDecoder().decode(Point3D.self, from: pointData) == point)
        #expect(try JSONDecoder().decode(Vector3D.self, from: vectorData) == vector)
        let pointObject = try #require(
            JSONSerialization.jsonObject(with: pointData) as? [String: Any]
        )
        #expect(Set(pointObject.keys) == ["x", "y", "z", "coordinateSpace"])

        expectExactInvalidPrimitiveDecoding(Point3D.self)
        expectExactInvalidPrimitiveDecoding(Vector3D.self)

        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        let nonFiniteValues = [
            (
                field: "x",
                index: 0,
                json: #"{"x":"NaN","y":2,"z":3,"coordinateSpace":{"rawValue":"world"}}"#
            ),
            (
                field: "y",
                index: 1,
                json: #"{"x":1,"y":"NaN","z":3,"coordinateSpace":{"rawValue":"world"}}"#
            ),
            (
                field: "z",
                index: 2,
                json: #"{"x":1,"y":2,"z":"NaN","coordinateSpace":{"rawValue":"world"}}"#
            ),
        ]
        for nonFiniteValue in nonFiniteValues {
            let data = Data(nonFiniteValue.json.utf8)
            expectNonFiniteDecoding(
                Point3D.self,
                from: data,
                using: decoder,
                field: nonFiniteValue.field,
                index: nonFiniteValue.index
            )
            expectNonFiniteDecoding(
                Vector3D.self,
                from: data,
                using: decoder,
                field: nonFiniteValue.field,
                index: nonFiniteValue.index
            )
        }
    }

    private func expectExactInvalidPrimitiveDecoding<Value: Decodable>(
        _ type: Value.Type
    ) {
        for wrongKeyValue in [
            #"{"x":1,"y":2,"z":3}"#,
            #"{"x":1,"y":2,"z":3,"coordinateSpace":{"rawValue":"world"},"extra":true}"#,
        ] {
            do {
                _ = try JSONDecoder().decode(type, from: Data(wrongKeyValue.utf8))
                #expect(Bool(false), "Expected a wrong-keyed primitive to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(
                type,
                from: Data(#"{"x":1,"y":2,"z":3,"coordinateSpace":{"rawValue":" "}}"#.utf8)
            )
            #expect(Bool(false), "Expected a blank coordinate space to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(
                context.codingPath.map(\.stringValue) == ["coordinateSpace", "rawValue"]
            )
            #expect(
                context.underlyingError as? VoxeliaStringIdentifierError
                    == .emptyOrWhitespaceOnly
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        do {
            _ = try JSONDecoder().decode(type, from: Data(#"[1,2,3]"#.utf8))
            #expect(Bool(false), "Expected an array-shaped primitive to fail decoding.")
        } catch DecodingError.typeMismatch {
            // The keyed-container request rejects the non-object shape.
        } catch {
            #expect(Bool(false), "Expected typeMismatch, received \(error).")
        }
    }

    private func expectNonFiniteDecoding<Value: Decodable>(
        _ type: Value.Type,
        from data: Data,
        using decoder: JSONDecoder,
        field: String,
        index: Int
    ) {
        do {
            _ = try decoder.decode(type, from: data)
            #expect(Bool(false), "Expected non-finite decoding to fail.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.last?.stringValue == field)
            #expect(
                context.underlyingError as? SpatialPrimitiveError
                    == .nonFiniteComponent(index: index)
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }
}
