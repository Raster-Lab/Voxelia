// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("PersistentIdentifier")
struct PersistentIdentifierTests {
    @Test("[Unit][CDMS-32][VOX-CON-001] identifier exactness binds both leaves")
    func identifierExactnessBindsBothLeaves() throws {
        // The 255-byte ceiling is inclusive for both leaves.
        let atCeiling = String(repeating: "a", count: 255)
        #expect(DataObjectID(rawValue: atCeiling) != nil)
        #expect(ProvenanceID(rawValue: atCeiling) != nil)
        let overCeiling = String(repeating: "a", count: 256)
        #expect(DataObjectID(rawValue: overCeiling) == nil)
        #expect(ProvenanceID(rawValue: overCeiling) == nil)

        // Exact UTF-8 identity: NFC and NFD spellings are distinct
        // identifiers even though Swift String equality unifies them.
        let composed = "caf\u{E9}"
        let decomposed = "cafe\u{301}"
        #expect(composed == decomposed)
        guard
            let composedObject = DataObjectID(rawValue: composed),
            let decomposedObject = DataObjectID(rawValue: decomposed),
            let composedNode = ProvenanceID(rawValue: composed),
            let decomposedNode = ProvenanceID(rawValue: decomposed)
        else {
            #expect(Bool(false), "Expected the spellings to construct.")
            return
        }
        #expect(composedObject != decomposedObject)
        #expect(Set([composedObject, decomposedObject]).count == 2)
        #expect(composedNode != decomposedNode)
        #expect(Set([composedNode, decomposedNode]).count == 2)

        // The shared strict decoder rejects an over-ceiling value with
        // the redacted concrete-type failure and no raw-value leakage.
        let sentinel = String(repeating: "p", count: 256)
        let document = #"{"rawValue":"\#(sentinel)"}"#
        do {
            _ = try JSONDecoder().decode(DataObjectID.self, from: Data(document.utf8))
            #expect(Bool(false), "Expected an over-ceiling decode to be rejected.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(!context.debugDescription.contains("ppp"))
        }

        // The keyed wire round trips the exact spelling.
        let encoded = try JSONEncoder().encode(composedObject)
        let decoded = try JSONDecoder().decode(DataObjectID.self, from: encoded)
        #expect(decoded == composedObject)
        #expect(decoded.rawValue.utf8.elementsEqual(composed.utf8))
    }
}
