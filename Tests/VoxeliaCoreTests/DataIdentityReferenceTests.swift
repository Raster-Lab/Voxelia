// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("DataIdentityReference")
struct DataIdentityReferenceTests {
    private let sampleDigestText =
        "6f576e15aac5e4331f74c6e88e84385619eba17d6e86e53a3cdb73694dc42111"

    private func sampleIdentity() throws -> ContentID {
        try ContentID.sampleBytesIdentity(overCanonicalPackedBytes: Array(0..<24))
    }

    @Test("[Unit][VOX-DAT-014][VOX-SEC-011] source fields validate with exact identity")
    func sourceFieldsValidateWithExactIdentity() throws {
        // Opaque foreign locators are admitted without interpretation.
        _ = try SourceIdentity(
            namespace: "dicom.sop-instance-uid",
            identifier: "1.2.840.113619.2.5.1762",
            version: nil,
            contentID: nil
        )
        _ = try SourceIdentity(
            namespace: "https://example.org/store",
            identifier: "études/série 7.dcm",
            version: "2",
            contentID: try sampleIdentity()
        )

        // The byte ceiling is checked before content rules: an oversized
        // field containing a control scalar still fails as a byte limit.
        let long255 = String(repeating: "a", count: 255)
        _ = try SourceIdentity(
            namespace: long255,
            identifier: "x",
            version: nil,
            contentID: nil
        )
        do {
            _ = try SourceIdentity(
                namespace: "\u{0007}" + long255,
                identifier: "x",
                version: nil,
                contentID: nil
            )
            #expect(Bool(false), "Expected the ceiling to precede content rules.")
        } catch SourceIdentityError.fieldByteLimitExceeded {}

        // Control scalars and blank text are rejected typed, without
        // disclosing the field text.
        for invalid in ["Patient\u{0000}Sentinel", "a\u{009F}b", "", "   ", "\u{3000}"] {
            do {
                _ = try SourceIdentity(
                    namespace: invalid,
                    identifier: "x",
                    version: nil,
                    contentID: nil
                )
                #expect(Bool(false), "Expected an invalid field to be rejected.")
            } catch let error as SourceIdentityError {
                #expect(error == .invalidField)
                var rendered = ""
                dump(error, to: &rendered)
                #expect(!rendered.contains("Patient"))
            }
        }
        do {
            _ = try SourceIdentity(
                namespace: "a.b",
                identifier: "x",
                version: "",
                contentID: nil
            )
            #expect(Bool(false), "Expected a blank present version to be rejected.")
        } catch SourceIdentityError.invalidField {}

        // Identity is the exact accepted UTF-8 tuple: byte-distinct
        // canonically equivalent spellings differ, absent and present
        // versions differ, and the content claim participates.
        let precomposed = try SourceIdentity(
            namespace: "a.b",
            identifier: "caf\u{00E9}",
            version: nil,
            contentID: nil
        )
        let decomposed = try SourceIdentity(
            namespace: "a.b",
            identifier: "cafe\u{0301}",
            version: nil,
            contentID: nil
        )
        #expect(precomposed.identifier == decomposed.identifier)
        #expect(precomposed != decomposed)

        let unversioned = try SourceIdentity(
            namespace: "a.b",
            identifier: "x",
            version: nil,
            contentID: nil
        )
        let versioned = try SourceIdentity(
            namespace: "a.b",
            identifier: "x",
            version: "1",
            contentID: nil
        )
        let claimed = try SourceIdentity(
            namespace: "a.b",
            identifier: "x",
            version: nil,
            contentID: try sampleIdentity()
        )
        #expect(unversioned != versioned)
        #expect(unversioned != claimed)
        #expect(Set([unversioned, versioned, claimed]).count == 3)
        #expect(
            unversioned
                == (try SourceIdentity(
                    namespace: "a.b",
                    identifier: "x",
                    version: nil,
                    contentID: nil
                ))
        )

        requireSendable(SourceIdentity.self)
        requireSendable(SourceIdentityError.self)
        requireSendable(DataIdentityReference.self)
        requireSendable(DataIdentityReferenceError.self)
    }

    @Test("[Unit][VOX-API-004][VOX-RGN-007] the tagged wire is exact")
    func taggedWireIsExact() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let object = DataIdentityReference.object(
            try #require(DataObjectID(rawValue: "series-7"))
        )
        let objectWire = String(decoding: try encoder.encode(object), as: UTF8.self)
        #expect(objectWire == #"{"object":{"rawValue":"series-7"}}"#)

        let content = DataIdentityReference.content(try sampleIdentity())
        let contentWire = String(decoding: try encoder.encode(content), as: UTF8.self)
        #expect(
            contentWire
                == #"{"content":{"algorithm":"sha256","digest":"\#(sampleDigestText)","#
                + #""projection":{"identifier":"org.voxelia.sample-bytes","#
                + #""version":{"major":1,"minor":0}},"scope":"sampleBytes"}}"#
        )

        let source = DataIdentityReference.source(
            try SourceIdentity(
                namespace: "dicom.sop-instance-uid",
                identifier: "1.2.840.113619.2.5.1762",
                version: nil,
                contentID: nil
            )
        )
        let sourceWire = String(decoding: try encoder.encode(source), as: UTF8.self)
        #expect(
            sourceWire
                == #"{"source":{"contentID":null,"identifier":"1.2.840.113619.2.5.1762","#
                + #""namespace":"dicom.sop-instance-uid","version":null}}"#
        )

        for (reference, wire) in [
            (object, objectWire), (content, contentWire), (source, sourceWire),
        ] {
            let decoded = try JSONDecoder().decode(
                DataIdentityReference.self,
                from: Data(wire.utf8)
            )
            #expect(decoded == reference)
        }
    }

    @Test("[Unit][VOX-ERR-001][VOX-API-004] decoding rejects malformed references")
    func decodingRejectsMalformedReferences() throws {
        let sourceBody =
            #"{"contentID":null,"identifier":"x","namespace":"a.b","version":null}"#

        // Wrong member counts, unknown tags — including the deferred
        // derivation case — and malformed nested records reject typed.
        let invalidRecords = [
            "{}",
            #"{"object":{"rawValue":"a"},"source":\#(sourceBody)}"#,
            #"{"derivation":{"rawValue":"a"}}"#,
            #"{"object":"a"}"#,
            #"{"object":{"rawValue":"\#(String(repeating: "a", count: 256))"}}"#,
            "[]",
        ]
        for document in invalidRecords {
            do {
                _ = try JSONDecoder().decode(
                    DataIdentityReference.self,
                    from: Data(document.utf8)
                )
                #expect(Bool(false), "Expected a malformed reference to be rejected.")
            } catch let error as DataIdentityReferenceError {
                #expect(error == .invalidRecord)
            }
        }

        // Nested audited project errors are retained.
        do {
            _ = try JSONDecoder().decode(
                DataIdentityReference.self,
                from: Data(
                    #"{"source":{"identifier":"x","namespace":"a.b","version":null}}"#
                        .utf8
                )
            )
            #expect(Bool(false), "Expected a missing field to be rejected.")
        } catch let error as SourceIdentityError {
            #expect(error == .invalidRecord)
        }
        do {
            _ = try JSONDecoder().decode(
                DataIdentityReference.self,
                from: Data(
                    (#"{"source":{"contentID":null,"identifier":"x","namespace":"  ","#
                        + #""version":null}}"#).utf8
                )
            )
            #expect(Bool(false), "Expected a blank namespace to be rejected.")
        } catch let error as SourceIdentityError {
            #expect(error == .invalidField)
        }
        do {
            let crossed =
                #"{"content":{"algorithm":"sha256","digest":"\#(sampleDigestText)","#
                + #""projection":{"identifier":"org.voxelia.sample-bytes","#
                + #""version":{"major":1,"minor":0}},"scope":"serialisedObject"}}"#
            _ = try JSONDecoder().decode(
                DataIdentityReference.self,
                from: Data(crossed.utf8)
            )
            #expect(Bool(false), "Expected a crossed content tuple to be rejected.")
        } catch let error as ContentIdentityError {
            #expect(error == .unsupportedProjection)
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
