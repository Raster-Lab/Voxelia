// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaCore

@testable import VoxeliaGeometry

@Suite("GeometryAttributeDescriptor")
struct GeometryAttributeDescriptorTests {
    @Test("[Unit] accepts two- and three-component positions")
    func acceptsPositionDimensions() throws {
        let format = try scalarFormat()

        for componentCount in [2, 3] {
            let components = try componentDescriptor(count: componentCount)
            for elementCount in [0, Int.max] {
                let descriptor = try GeometryAttributeDescriptor(
                    semantic: .position,
                    scalarFormat: format,
                    components: components,
                    elementCount: elementCount
                )

                #expect(descriptor.semantic == .position)
                #expect(descriptor.scalarFormat == format)
                #expect(descriptor.components == components)
                #expect(descriptor.elementCount == elementCount)
            }
        }
    }

    @Test("[Unit][VOX-GEO-004] leaves non-position component policy to binding")
    func acceptsNonPositionComponentCounts() throws {
        for (semantic, componentCount) in [
            (GeometryAttributeSemantic.normal, 1),
            (.colour, 4),
            (.custom(namespace: "org.example", name: "coefficients"), 7),
        ] {
            let descriptor = try GeometryAttributeDescriptor(
                semantic: semantic,
                scalarFormat: scalarFormat(),
                components: componentDescriptor(count: componentCount),
                elementCount: 1
            )
            #expect(descriptor.components.count == componentCount)
        }
    }

    @Test("[Unit][VOX-ERR-001] rejects negative element counts")
    func rejectsNegativeElementCounts() throws {
        #expect(throws: DataModelError.invalidGeometryAttribute) {
            try GeometryAttributeDescriptor(
                semantic: .label,
                scalarFormat: scalarFormat(),
                components: componentDescriptor(count: 1),
                elementCount: -1
            )
        }
        #expect(throws: DataModelError.invalidGeometryAttribute) {
            try GeometryAttributeDescriptor(
                semantic: .label,
                scalarFormat: scalarFormat(),
                components: componentDescriptor(count: 1),
                elementCount: Int.min
            )
        }
    }

    @Test("[Unit][VOX-ERR-001] rejects invalid position counts")
    func rejectsInvalidPositionComponentCounts() throws {
        for invalidCount in [1, 4, Int.max] {
            #expect(throws: DataModelError.invalidGeometryAttribute) {
                try GeometryAttributeDescriptor(
                    semantic: .position,
                    scalarFormat: scalarFormat(),
                    components: componentDescriptor(count: invalidCount),
                    elementCount: 1
                )
            }
        }
    }

    @Test("[Unit][VOX-API-004] Codable preserves the exact four-field shape")
    func codableRoundTripAndShape() throws {
        let descriptor = try GeometryAttributeDescriptor(
            semantic: .custom(namespace: "org.example", name: "curvature"),
            scalarFormat: scalarFormat(),
            components: componentDescriptor(count: 5),
            elementCount: 42
        )
        let data = try JSONEncoder().encode(descriptor)
        let decoded = try JSONDecoder().decode(
            GeometryAttributeDescriptor.self,
            from: data
        )

        #expect(decoded == descriptor)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(
            Set(object.keys)
                == ["semantic", "scalarFormat", "components", "elementCount"]
        )
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding is strict and revalidating")
    func decodingIsStrictAndRevalidating() throws {
        let validJSON =
            #"{"semantic":"position","scalarFormat":{"type":"float32","byteOrder":"native"},"components":{"count":2,"interpretation":"vector","layout":"interleaved","componentNames":null},"elementCount":4}"#
        let missingFieldJSON =
            #"{"semantic":"position","scalarFormat":{"type":"float32","byteOrder":"native"},"components":{"count":2,"interpretation":"vector","layout":"interleaved","componentNames":null}}"#
        let extraFieldJSON =
            #"{"semantic":"position","scalarFormat":{"type":"float32","byteOrder":"native"},"components":{"count":2,"interpretation":"vector","layout":"interleaved","componentNames":null},"elementCount":4,"extra":true}"#
        let invalidNestedFormatJSON =
            #"{"semantic":"position","scalarFormat":{"type":"float32","validBitCount":33,"byteOrder":"native"},"components":{"count":2,"interpretation":"vector","layout":"interleaved","componentNames":null},"elementCount":4}"#
        let invalidNestedComponentsJSON =
            #"{"semantic":"position","scalarFormat":{"type":"float32","byteOrder":"native"},"components":{"count":0,"interpretation":"vector","layout":"interleaved","componentNames":null},"elementCount":4}"#

        #expect(
            try JSONDecoder().decode(
                GeometryAttributeDescriptor.self,
                from: Data(validJSON.utf8)
            ).elementCount == 4
        )
        let corruptedFixtures: [(json: String, pathPrefix: [String])] = [
            (missingFieldJSON, []),
            (extraFieldJSON, []),
            (invalidNestedFormatJSON, ["scalarFormat"]),
            (invalidNestedComponentsJSON, ["components"]),
        ]
        for corruptedFixture in corruptedFixtures {
            do {
                _ = try JSONDecoder().decode(
                    GeometryAttributeDescriptor.self,
                    from: Data(corruptedFixture.json.utf8)
                )
                #expect(Bool(false), "Expected a malformed descriptor to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(
                    Array(
                        context.codingPath.map(\.stringValue)
                            .prefix(corruptedFixture.pathPrefix.count)
                    ) == corruptedFixture.pathPrefix
                )
                if corruptedFixture.pathPrefix.isEmpty {
                    #expect(context.codingPath.isEmpty)
                }
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        expectRevalidationFailure(
            json:
                #"{"semantic":"label","scalarFormat":{"type":"float32","byteOrder":"native"},"components":{"count":1,"interpretation":"scalar","layout":"interleaved","componentNames":null},"elementCount":-1}"#,
            field: "elementCount"
        )
        expectRevalidationFailure(
            json:
                #"{"semantic":"position","scalarFormat":{"type":"float32","byteOrder":"native"},"components":{"count":1,"interpretation":"vector","layout":"interleaved","componentNames":null},"elementCount":1}"#,
            field: "components"
        )
    }

    @Test("[Unit][VOX-API-003] remains Sendable and Hashable")
    func remainsSendableAndHashable() throws {
        requireSendable(GeometryAttributeDescriptor.self)
        let descriptor = try GeometryAttributeDescriptor(
            semantic: .scalarValue,
            scalarFormat: scalarFormat(),
            components: componentDescriptor(count: 1),
            elementCount: 8
        )
        #expect(Set([descriptor, descriptor]).count == 1)
    }

    private func scalarFormat() throws -> ScalarFormat {
        try ScalarFormat(
            type: .float32,
            validBitCount: nil,
            byteOrder: .native
        )
    }

    private func componentDescriptor(count: Int) throws -> ComponentDescriptor {
        try ComponentDescriptor(
            count: count,
            interpretation: .vector,
            layout: .interleaved
        )
    }

    private func expectRevalidationFailure(json: String, field: String) {
        do {
            _ = try JSONDecoder().decode(
                GeometryAttributeDescriptor.self,
                from: Data(json.utf8)
            )
            #expect(Bool(false), "Expected invalid geometry attribute metadata.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.last?.stringValue == field)
            #expect(
                context.underlyingError as? DataModelError
                    == .invalidGeometryAttribute
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
