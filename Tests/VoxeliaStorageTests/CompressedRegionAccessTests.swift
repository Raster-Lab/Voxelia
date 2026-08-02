// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaStorage

@Suite("CompressedRegionAccess")
struct CompressedRegionAccessTests {
    @Test("[Unit][VOX-API-004] simple modes use exact stable strings")
    func simpleModesUseStableStrings() throws {
        let expected: [(CompressedRegionAccess, String)] = [
            (.completeObject, "completeObject"),
            (.frame, "frame"),
            (.slab, "slab"),
            (.brick, "brick"),
            (.regionOfInterest, "regionOfInterest"),
            (.progressiveResolution, "progressiveResolution"),
        ]

        for (mode, tag) in expected {
            let encoded = try JSONEncoder().encode(mode)
            #expect(String(decoding: encoded, as: UTF8.self) == "\"\(tag)\"")
            #expect(
                try JSONDecoder().decode(CompressedRegionAccess.self, from: encoded)
                    == mode
            )
        }
    }

    @Test("[Unit][VOX-API-004] custom mode uses a strict namespaced object")
    func customModeRoundTrips() throws {
        let mode = CompressedRegionAccess.custom(
            namespace: "org.voxelia.codec",
            name: "wavelet-tile"
        )
        let encoded = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(
            CompressedRegionAccess.self,
            from: encoded
        )

        #expect(decoded == mode)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: [String: String]]
        )
        #expect(
            object == [
                "custom": [
                    "namespace": "org.voxelia.codec",
                    "name": "wavelet-tile",
                ]
            ]
        )
    }

    @Test("[Unit][VOX-API-003] custom values preserve exact opaque spelling")
    func customModePreservesExactSpelling() throws {
        let composed = CompressedRegionAccess.custom(
            namespace: "nam\u{00E9}space",
            name: "nam\u{00E9}"
        )
        let decomposedNamespace = CompressedRegionAccess.custom(
            namespace: "name\u{301}space",
            name: "nam\u{00E9}"
        )
        let decomposedName = CompressedRegionAccess.custom(
            namespace: "nam\u{00E9}space",
            name: "name\u{301}"
        )
        let caseVariant = CompressedRegionAccess.custom(
            namespace: "Nam\u{00E9}space",
            name: "NAM\u{00E9}"
        )
        let emptyValues = CompressedRegionAccess.custom(namespace: "", name: "")

        let values = [
            composed,
            decomposedNamespace,
            decomposedName,
            caseVariant,
            emptyValues,
        ]
        #expect(Set(values).count == values.count)

        for value in values {
            let expected = try #require(customFields(value))
            let encoded = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(
                CompressedRegionAccess.self,
                from: encoded
            )
            let actual = try #require(customFields(decoded))
            #expect(Array(actual.namespace.utf8) == Array(expected.namespace.utf8))
            #expect(Array(actual.name.utf8) == Array(expected.name.utf8))
        }
    }

    @Test("[Unit][VOX-API-004] malformed representations are rejected")
    func malformedRepresentationsAreRejected() {
        let invalidValues = [
            #""unknown""#,
            #"null"#,
            #"1"#,
            #"[]"#,
            #"{}"#,
            #"{"unexpected":{}}"#,
            #"{"custom":{"namespace":"org.voxelia"}}"#,
            #"{"custom":{"namespace":"org.voxelia","name":"codec","extra":true}}"#,
            #"{"custom":{"namespace":"org.voxelia","name":"codec"},"extra":true}"#,
            #"{"custom":{"namespace":1,"name":"codec"}}"#,
        ]

        for invalidValue in invalidValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    CompressedRegionAccess.self,
                    from: Data(invalidValue.utf8)
                )
            }
        }
    }

    @Test("[Unit][VOX-API-003] supports Sendable and Hashable use")
    func supportsValueSemantics() {
        requireSendable(CompressedRegionAccess.self)
        let values: Set<CompressedRegionAccess> = [
            .frame,
            .frame,
            .custom(namespace: "org.example", name: "region"),
        ]
        #expect(values.count == 2)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}

    private func customFields(
        _ value: CompressedRegionAccess
    ) -> (namespace: String, name: String)? {
        guard case .custom(let namespace, let name) = value else {
            return nil
        }
        return (namespace, name)
    }
}
