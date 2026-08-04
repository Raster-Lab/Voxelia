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

    @Test("[Unit][VOX-API-004][VOX-ERR-001] malformed representations are rejected")
    func malformedRepresentationsAreRejected() {
        let rootCorruptedValues = [
            #""unknown""#,
            #"{}"#,
            #"{"unexpected":{}}"#,
            #"{"custom":{"namespace":"org.voxelia","name":"codec"},"extra":true}"#,
        ]
        for rootCorruptedValue in rootCorruptedValues {
            expectDataCorruptedDecoding(json: rootCorruptedValue, path: [])
        }

        let customCorruptedValues = [
            #"{"custom":{"namespace":"org.voxelia"}}"#,
            #"{"custom":{"namespace":"org.voxelia","name":"codec","extra":true}}"#,
        ]
        for customCorruptedValue in customCorruptedValues {
            expectDataCorruptedDecoding(json: customCorruptedValue, path: ["custom"])
        }

        do {
            _ = try JSONDecoder().decode(
                CompressedRegionAccess.self,
                from: Data("null".utf8)
            )
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // The keyed-container request rejects null after the string branch.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in [#"1"#, #"[]"#] {
            do {
                _ = try JSONDecoder().decode(
                    CompressedRegionAccess.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped value to fail decoding.")
            } catch DecodingError.typeMismatch {
                // The keyed-container request rejects non-object shapes.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(
                CompressedRegionAccess.self,
                from: Data(#"{"custom":{"namespace":1,"name":"codec"}}"#.utf8)
            )
            #expect(Bool(false), "Expected a numeric namespace to fail decoding.")
        } catch DecodingError.typeMismatch(_, let context) {
            #expect(context.codingPath.map(\.stringValue) == ["custom", "namespace"])
        } catch {
            #expect(Bool(false), "Expected typeMismatch, received \(error).")
        }
    }

    private func expectDataCorruptedDecoding(json: String, path: [String]) {
        do {
            _ = try JSONDecoder().decode(
                CompressedRegionAccess.self,
                from: Data(json.utf8)
            )
            #expect(Bool(false), "Expected a malformed representation to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == path)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
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
