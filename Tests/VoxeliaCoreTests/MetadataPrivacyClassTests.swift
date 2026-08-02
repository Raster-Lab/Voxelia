// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("MetadataPrivacyClass")
struct MetadataPrivacyClassTests {
    @Test("[Unit][VOX-API-003] exposes the exact privacy taxonomy")
    func exposesExactRawValues() {
        let expected: [(privacyClass: MetadataPrivacyClass, rawValue: String)] = [
            (.publicData, "publicData"),
            (.technical, "technical"),
            (.potentiallyIdentifying, "potentiallyIdentifying"),
            (.sensitive, "sensitive"),
            (.hostDefined, "hostDefined"),
        ]

        for value in expected {
            #expect(value.privacyClass.rawValue == value.rawValue)
            #expect(MetadataPrivacyClass(rawValue: value.rawValue) == value.privacyClass)
        }
        #expect(MetadataPrivacyClass(rawValue: "publicdata") == nil)
        #expect(MetadataPrivacyClass(rawValue: "unknown") == nil)
    }

    @Test("[Unit][VOX-API-004] Codable uses exact raw strings")
    func codableUsesExactRawStrings() throws {
        let values: [MetadataPrivacyClass] = [
            .publicData,
            .technical,
            .potentiallyIdentifying,
            .sensitive,
            .hostDefined,
        ]

        for value in values {
            let data = try JSONEncoder().encode(value)
            #expect(String(decoding: data, as: UTF8.self) == #""\#(value.rawValue)""#)
            #expect(try JSONDecoder().decode(MetadataPrivacyClass.self, from: data) == value)
        }
    }

    @Test("[Unit][VOX-API-004] decoding rejects unknown and wrong-shaped values")
    func decodingRejectsInvalidValues() {
        for json in [#""unknown""#, "1", "true", "null", "{}", "[]"] {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    MetadataPrivacyClass.self,
                    from: Data(json.utf8)
                )
            }
        }
    }
}
