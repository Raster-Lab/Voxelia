// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("StringIdentifier")
struct StringIdentifierTests {
    @Test("[Unit][VOX-API-003] accepts and exactly preserves valid identifiers")
    func preservesValidIdentifiers() throws {
        let values = [
            "org.voxelia.coordinate.world",
            "urn:dicom:uid:1.2.840.10008",
            "患者.空间",
            "org.example.coordinate.e\u{301}",
            "  external value  ",
        ]

        for value in values {
            let coordinateSpace = try identifier(
                CoordinateSpaceID.self,
                validating: value
            )
            let axis = try identifier(AxisID.self, validating: value)
            #expect(coordinateSpace.rawValue == value)
            #expect(axis.rawValue == value)
            #expect(coordinateSpace.rawValue.utf8.elementsEqual(value.utf8))
            #expect(axis.rawValue.utf8.elementsEqual(value.utf8))
        }
    }

    @Test("[Unit] failable raw initializers reject blank identifiers")
    func rawInitializersRejectBlankValues() {
        let blankValues = ["", " ", "\n\t", "\u{00A0}\u{2003}"]

        for value in blankValues {
            #expect(CoordinateSpaceID(rawValue: value) == nil)
            #expect(AxisID(rawValue: value) == nil)
        }
    }

    @Test("[Unit][VOX-ERR-001] throwing initializers report typed errors")
    func validatingInitializersReportTypedErrors() {
        #expect(throws: VoxeliaStringIdentifierError.emptyOrWhitespaceOnly) {
            try CoordinateSpaceID(validating: "")
        }
        #expect(throws: VoxeliaStringIdentifierError.emptyOrWhitespaceOnly) {
            try AxisID(validating: "\u{2003}")
        }
        #expect(throws: VoxeliaStringIdentifierError.emptyOrWhitespaceOnly) {
            try PermissiveIdentifier(validating: " \u{2003}")
        }
    }

    @Test("[Unit][VOX-SPA-005] identity is case-sensitive and type-distinct")
    func preservesCaseSensitiveDistinctness() throws {
        let world = try CoordinateSpaceID(validating: "org.voxelia.coordinate.world")
        let differentlyCased = try CoordinateSpaceID(
            validating: "org.voxelia.coordinate.World"
        )
        let axis = try AxisID(validating: world.rawValue)

        #expect(world != differentlyCased)
        #expect(Set([world, differentlyCased]).count == 2)
        #expect(type(of: world) == CoordinateSpaceID.self)
        #expect(type(of: axis) == AxisID.self)
    }

    @Test("[Unit][VOX-API-004] Codable uses one keyed rawValue field")
    func codableUsesStableKeyedRepresentation() throws {
        let coordinateSpace = try CoordinateSpaceID(
            validating: "org.voxelia.coordinate.patient"
        )
        let axis = try AxisID(validating: "slice")

        let coordinateJSON = try JSONEncoder().encode(coordinateSpace)
        let axisJSON = try JSONEncoder().encode(axis)
        #expect(
            coordinateJSON
                == Data(#"{"rawValue":"org.voxelia.coordinate.patient"}"#.utf8)
        )
        #expect(axisJSON == Data(#"{"rawValue":"slice"}"#.utf8))
        #expect(
            try JSONDecoder().decode(CoordinateSpaceID.self, from: coordinateJSON)
                == coordinateSpace
        )
        #expect(try JSONDecoder().decode(AxisID.self, from: axisJSON) == axis)
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects invalid identifier objects")
    func decodingRejectsInvalidObjects() {
        expectBlankRawValueDecoding(AxisID.self)
        expectBlankRawValueDecoding(PermissiveIdentifier.self)

        for wrongKeyValue in [#"{"rawValue":"axis","extra":true}"#, #"{}"#] {
            do {
                _ = try JSONDecoder().decode(
                    AxisID.self,
                    from: Data(wrongKeyValue.utf8)
                )
                #expect(Bool(false), "Expected a wrong-keyed object to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(AxisID.self, from: Data(#""axis""#.utf8))
            #expect(Bool(false), "Expected a plain string to fail decoding.")
        } catch DecodingError.typeMismatch {
            // The keyed-container request rejects the non-object shape.
        } catch {
            #expect(Bool(false), "Expected typeMismatch, received \(error).")
        }
    }

    private func expectBlankRawValueDecoding<Value: VoxeliaStringIdentifier>(
        _ type: Value.Type
    ) {
        do {
            _ = try JSONDecoder().decode(
                type,
                from: Data(#"{"rawValue":" "}"#.utf8)
            )
            #expect(Bool(false), "Expected a blank raw value to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["rawValue"])
            #expect(
                context.underlyingError as? VoxeliaStringIdentifierError
                    == .emptyOrWhitespaceOnly
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    @Test("[Unit][VOX-SPA-005] representative coordinate spaces remain distinct")
    func distinguishesRepresentativeCoordinateSpaces() throws {
        let rawValues = [
            "org.voxelia.coordinate.index",
            "org.voxelia.coordinate.voxel",
            "org.voxelia.coordinate.image",
            "org.voxelia.coordinate.patient",
            "org.voxelia.coordinate.world",
            "org.voxelia.coordinate.display",
            "com.example.coordinate.application",
        ]
        let identifiers = try rawValues.map(CoordinateSpaceID.init(validating:))

        #expect(Set(identifiers).count == rawValues.count)
    }

    private func identifier<Identifier: VoxeliaStringIdentifier>(
        _ type: Identifier.Type,
        validating rawValue: String
    ) throws -> Identifier {
        try Identifier(validating: rawValue)
    }
}

private struct PermissiveIdentifier: VoxeliaStringIdentifier {
    let rawValue: String

    init?(rawValue: String) {
        self.rawValue = rawValue
    }
}
