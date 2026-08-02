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

    @Test("[Unit][VOX-ERR-007][VOX-SEC-006] decoding failures are value-redacted")
    func decodingFailuresAreValueRedacted() {
        let callerKey = "patient-key-sentinel"
        let rejectedValue = "patient-value-sentinel"
        let payloads = [
            #"{"patient-key-sentinel":"patient-value-sentinel"}"#,
            #"{"patient-key-sentinel":{"private":"patient-value-sentinel"}}"#,
        ]

        for payload in payloads {
            do {
                _ = try JSONDecoder().decode(
                    [String: MetadataPrivacyClass].self,
                    from: Data(payload.utf8)
                )
                #expect(Bool(false), "Expected privacy-class decoding to fail.")
            } catch let error as DecodingError {
                let descriptions = [
                    String(describing: error),
                    String(reflecting: error),
                ]
                for description in descriptions {
                    #expect(!description.contains(callerKey))
                    #expect(!description.contains(rejectedValue))
                }

                guard case .dataCorrupted(let context) = error else {
                    #expect(Bool(false), "Expected a redacted data-corruption error.")
                    continue
                }
                #expect(context.codingPath.isEmpty)
                #expect(context.underlyingError == nil)
            } catch {
                #expect(Bool(false), "Expected a DecodingError.")
            }
        }
    }
}
