// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("ComponentDescriptor")
struct ComponentDescriptorTests {
    @Test("[Unit][VOX-DAT-011] accepts canonical component interpretations")
    func acceptsCanonicalInterpretations() throws {
        let validDescriptors: [(ComponentInterpretation, Int)] = [
            (.scalar, 1),
            (.scalar, 2),
            (.rgb, 3),
            (.rgba, 4),
            (.vector, 3),
            (.tensor, 9),
            (.complex, 2),
            (.labelProbability, 6),
            (.generic(namespace: "org.voxelia", name: "material"), 5),
        ]

        for (interpretation, count) in validDescriptors {
            let descriptor = try ComponentDescriptor(
                count: count,
                interpretation: interpretation,
                layout: .interleaved
            )

            #expect(descriptor.count == count)
            #expect(descriptor.interpretation == interpretation)
            #expect(descriptor.componentNames == nil)
        }
    }

    @Test("[Unit][VOX-DAT-011][VOX-ERR-001] rejects non-positive component counts")
    func rejectsNonPositiveCounts() {
        for count in [0, -1] {
            #expect(throws: DataModelError.invalidComponentDescriptor) {
                try ComponentDescriptor(
                    count: count,
                    interpretation: .vector,
                    layout: .planar
                )
            }
        }
    }

    @Test("[Unit][VOX-DAT-011][VOX-ERR-001] enforces RGB and RGBA component counts")
    func enforcesColourComponentCounts() throws {
        _ = try ComponentDescriptor(count: 3, interpretation: .rgb, layout: .interleaved)
        _ = try ComponentDescriptor(count: 4, interpretation: .rgba, layout: .interleaved)

        for count in [2, 4] {
            #expect(throws: DataModelError.invalidComponentDescriptor) {
                try ComponentDescriptor(
                    count: count,
                    interpretation: .rgb,
                    layout: .interleaved
                )
            }
        }
        for count in [3, 5] {
            #expect(throws: DataModelError.invalidComponentDescriptor) {
                try ComponentDescriptor(
                    count: count,
                    interpretation: .rgba,
                    layout: .interleaved
                )
            }
        }
    }

    @Test("[Unit][VOX-DAT-011][VOX-ERR-001] validates and preserves component names")
    func validatesComponentNames() throws {
        let descriptor = try ComponentDescriptor(
            count: 3,
            interpretation: .vector,
            layout: .planar,
            componentNames: ["x", "", "z"]
        )

        #expect(Array(descriptor.componentNames ?? []) == ["x", "", "z"])

        for names: ContiguousArray<String> in [[], ["x", "y"]] {
            #expect(throws: DataModelError.invalidComponentDescriptor) {
                try ComponentDescriptor(
                    count: 3,
                    interpretation: .vector,
                    layout: .planar,
                    componentNames: names
                )
            }
        }
    }

    @Test("[Unit][VOX-API-004] enum values round trip through Codable")
    func enumCodableRoundTrip() throws {
        let interpretations: [ComponentInterpretation] = [
            .scalar,
            .rgb,
            .rgba,
            .vector,
            .tensor,
            .complex,
            .labelProbability,
            .generic(namespace: "org.voxelia", name: "custom"),
        ]
        let layouts: [ComponentLayout] = [.interleaved, .planar, .storageDefined]

        for interpretation in interpretations {
            let encoded = try JSONEncoder().encode(interpretation)
            let decoded = try JSONDecoder().decode(
                ComponentInterpretation.self,
                from: encoded
            )
            #expect(decoded == interpretation)
        }
        for layout in layouts {
            let encoded = try JSONEncoder().encode(layout)
            let decoded = try JSONDecoder().decode(ComponentLayout.self, from: encoded)
            #expect(decoded == layout)
        }
    }

    @Test("[Unit][VOX-API-004] enums use the documented stable JSON schema")
    func enumJSONSchema() throws {
        let encoder = JSONEncoder()

        #expect(
            String(decoding: try encoder.encode(ComponentInterpretation.scalar), as: UTF8.self)
                == #""scalar""#)
        #expect(
            String(decoding: try encoder.encode(ComponentLayout.interleaved), as: UTF8.self)
                == #""interleaved""#)

        let generic = ComponentInterpretation.generic(
            namespace: "org.voxelia",
            name: "custom"
        )
        let genericObject = try #require(
            JSONSerialization.jsonObject(with: try encoder.encode(generic))
                as? [String: [String: String]]
        )
        #expect(
            genericObject == [
                "generic": ["namespace": "org.voxelia", "name": "custom"]
            ])

        let malformedGeneric = Data(
            #"{"generic":{"namespace":"org.voxelia","name":"custom","extra":"value"}}"#.utf8
        )
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                ComponentInterpretation.self,
                from: malformedGeneric
            )
        }
    }

    @Test("[Unit][VOX-API-004] descriptor round trip preserves metadata")
    func descriptorCodableRoundTrip() throws {
        let descriptor = try ComponentDescriptor(
            count: 3,
            interpretation: .rgb,
            layout: .storageDefined,
            componentNames: ["red", "green", "blue"]
        )

        let encoded = try JSONEncoder().encode(descriptor)
        let decoded = try JSONDecoder().decode(ComponentDescriptor.self, from: encoded)

        #expect(decoded == descriptor)

        let object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        #expect(object["interpretation"] as? String == "rgb")
        #expect(object["layout"] as? String == "storageDefined")
    }

    @Test("[Unit][VOX-DAT-011][VOX-ERR-001] decoding rejects invalid descriptors")
    func decodingRejectsInvalidDescriptors() {
        let invalidDescriptors = [
            #"{"count":0,"interpretation":"vector","layout":"planar"}"#,
            #"{"count":2,"interpretation":"rgb","layout":"interleaved"}"#,
            #"{"count":3,"interpretation":"vector","layout":"planar","componentNames":["x","y"]}"#,
        ]

        for invalidDescriptor in invalidDescriptors {
            do {
                _ = try JSONDecoder().decode(
                    ComponentDescriptor.self,
                    from: Data(invalidDescriptor.utf8)
                )
                #expect(Bool(false), "Expected invalid component metadata to fail.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
                #expect(
                    context.underlyingError as? DataModelError
                        == .invalidComponentDescriptor
                )
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }
    }
}
