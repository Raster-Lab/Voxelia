// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("ImageSemantic")
struct ImageSemanticTests {
    @Test("[Unit][VOX-DAT-012] distinguishes every canonical image meaning")
    func canonicalSemanticsUseStableStrings() throws {
        let expected: [(ImageSemantic, String)] = [
            (.intensity, "intensity"),
            (.label, "label"),
            (.probability, "probability"),
            (.colour, "colour"),
            (.vectorField, "vectorField"),
            (.deformationField, "deformationField"),
            (.tensor, "tensor"),
            (.parametric, "parametric"),
            (.mask, "mask"),
        ]

        for (semantic, string) in expected {
            let encoded = try JSONEncoder().encode(semantic)
            #expect(String(decoding: encoded, as: UTF8.self) == "\"\(string)\"")

            let decoded = try JSONDecoder().decode(ImageSemantic.self, from: encoded)
            #expect(decoded == semantic)
        }
    }

    @Test("[Unit][VOX-DAT-012][VOX-API-004] generic semantics preserve identity")
    func genericSemanticRoundTrip() throws {
        let semantic = ImageSemantic.generic(
            namespace: "org.voxelia",
            name: "attenuation-corrected"
        )
        let encoded = try JSONEncoder().encode(semantic)
        let decoded = try JSONDecoder().decode(ImageSemantic.self, from: encoded)

        #expect(decoded == semantic)

        let object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: [String: String]]
        )
        #expect(
            object == [
                "generic": [
                    "namespace": "org.voxelia",
                    "name": "attenuation-corrected",
                ]
            ])
    }

    @Test("[Unit][VOX-API-004] rejects unknown or malformed semantics")
    func rejectsInvalidSemanticJSON() {
        let invalidValues = [
            #""unknown""#,
            #"{"generic":{"namespace":"org.voxelia"}}"#,
            #"{"generic":{"namespace":"org.voxelia","name":"custom","extra":"value"}}"#,
            #"{"unexpected":{}}"#,
        ]

        for invalidValue in invalidValues {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    ImageSemantic.self,
                    from: Data(invalidValue.utf8)
                )
            }
        }
    }
}
