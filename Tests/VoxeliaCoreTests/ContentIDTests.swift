// SPDX-License-Identifier: MIT

import CryptoKit
import Foundation
import Testing

@testable import VoxeliaCore

@Suite("ContentID")
struct ContentIDTests {
    private let emptyEnvelope =
        #"{"documentSchema":{"identifier":"org.voxelia.metadata-document","#
        + #""version":{"major":1,"minor":0}},"multiplicitySchema":null,"#
        + #""payload":{"entries":[]}}"#

    private let emptyFramedDigestText =
        "8dde6fa088cd4b1e676fca392a6d24fdeed93fc93bdc43c94cfbc75f362e7432"

    private func emptyDocumentIdentity() throws -> ContentID {
        try ContentID.completeMetadataRecordIdentity(
            overCanonicalBytes: Array(emptyEnvelope.utf8)
        )
    }

    @Test("[Unit][CDMS-32.2][VOX-CON-006] golden digests pin the frame")
    func goldenDigestsPinTheFrame() throws {
        // The ADR-0036 fixtures are computed over the exact 148-byte empty
        // VCMJ-1 document, independently cross-checking the accepted
        // canonical emitter byte for byte.
        let empty = try MetadataCollection(entries: [MetadataEntry]())
        let canonical = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: empty,
            maximumOutputByteCount: 4_096
        )
        #expect(canonical.count == 148)
        #expect(canonical == Array(emptyEnvelope.utf8))

        // Raw SHA-256 of the payload matches the registered negative
        // control and differs from the framed identity.
        let rawDigest = SHA256.hash(data: canonical)
        #expect(
            ContentID.hexDigestText(ContiguousArray(rawDigest))
                == "a27e896af6381de3cf78c5b4166851b601b6461d9e2503935b32ab4d6811ee50"
        )

        let identity = try ContentID.completeMetadataRecordIdentity(
            overCanonicalBytes: canonical
        )
        #expect(ContentID.hexDigestText(identity.digest) == emptyFramedDigestText)
        #expect(identity.algorithm == .sha256)
        #expect(identity.scope == .serialisedObject)
        #expect(
            identity.projection.identifier == "org.voxelia.metadata-complete-record"
        )
        #expect(identity.projection.version == ContentProjectionVersion(major: 1, minor: 0))
        #expect(identity.digest.count == 32)

        // The 109-byte header is exact and length-framed.
        let header = ContentID.completeRecordFrameHeader(payloadByteCount: 148)
        #expect(header.count == 109)
        #expect(header[18] == 0)
        #expect(Array(header.prefix(18)) == Array("VOXELIA-CONTENT-ID".utf8))
        #expect(Array(header.suffix(8)) == [0, 0, 0, 0, 0, 0, 0, 148])

        // NIST FIPS 180-4 known-answer vector for the underlying hash.
        #expect(
            ContentID.hexDigestText(ContiguousArray(SHA256.hash(data: Array("abc".utf8))))
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )

        requireSendable(ContentID.self)
        requireSendable(ContentProjectionReference.self)
        requireSendable(ContentIdentityError.self)
    }

    @Test("[Unit][VOX-CON-006][VOX-SEC-011] identity is deterministic and domain-bound")
    func identityIsDeterministicAndDomainBound() throws {
        let bytes = Array(emptyEnvelope.utf8)
        let first = try ContentID.completeMetadataRecordIdentity(overCanonicalBytes: bytes)
        let second = try ContentID.completeMetadataRecordIdentity(overCanonicalBytes: bytes)
        #expect(first == second)
        #expect(Set([first, second]).count == 1)

        // Any payload mutation changes the identity.
        var mutated = bytes
        mutated[mutated.count - 3] = UInt8(ascii: " ")
        let different = try ContentID.completeMetadataRecordIdentity(
            overCanonicalBytes: mutated
        )
        #expect(first != different)

        // Verification recomputes and compares through the timing-safe
        // comparator: a match on the original, a mismatch on mutations.
        #expect(try first.matchesDigest(ofCanonicalBytes: bytes))
        #expect(try !first.matchesDigest(ofCanonicalBytes: mutated))
        #expect(try !first.matchesDigest(ofCanonicalBytes: []))

        // First, middle and last digest-byte mismatches are all detected.
        for flippedIndex in [0, 31, 63] {
            var hex = Array(ContentID.hexDigestText(first.digest).utf8)
            hex[flippedIndex] =
                hex[flippedIndex] == UInt8(ascii: "0")
                ? UInt8(ascii: "1") : UInt8(ascii: "0")
            let alteredJSON =
                #"{"algorithm":"sha256","digest":"\#(String(decoding: hex, as: UTF8.self))","#
                + #""projection":{"identifier":"org.voxelia.metadata-complete-record","#
                + #""version":{"major":1,"minor":0}},"scope":"serialisedObject"}"#
            let altered = try JSONDecoder().decode(
                ContentID.self,
                from: Data(alteredJSON.utf8)
            )
            #expect(try !altered.matchesDigest(ofCanonicalBytes: bytes))
            #expect(altered != first)
        }

        // The digest accessor returns owned value-semantic bytes.
        var copy = first.digest
        copy[0] ^= 0xFF
        #expect(first.digest[0] != copy[0])
    }

    @Test("[Unit][CDMS-32.2][VOX-SEC-011] hashing is chunk-boundary invariant")
    func hashingIsChunkBoundaryInvariant() throws {
        // The production 4,096-byte update boundary and both adjacent
        // sizes must agree with an independent whole-frame SHA-256 oracle.
        for payloadByteCount in [4_095, 4_096, 4_097, 8_191, 8_192, 8_193] {
            let payload = (0..<payloadByteCount).map {
                UInt8(truncatingIfNeeded: $0 &* 31 &+ 17)
            }
            let identity = try ContentID.completeMetadataRecordIdentity(
                overCanonicalBytes: payload
            )
            let frame =
                ContentID.completeRecordFrameHeader(
                    payloadByteCount: UInt64(payload.count)
                ) + payload
            #expect(identity.digest == ContiguousArray(SHA256.hash(data: frame)))
        }

        // Every possible two-part split of this bounded frame produces
        // the same digest as both the whole-frame oracle and production.
        let payload = (0..<97).map { UInt8(truncatingIfNeeded: $0 &* 19) }
        let frame =
            ContentID.completeRecordFrameHeader(
                payloadByteCount: UInt64(payload.count)
            ) + payload
        let expected = ContiguousArray(SHA256.hash(data: frame))
        let identity = try ContentID.completeMetadataRecordIdentity(
            overCanonicalBytes: payload
        )
        #expect(identity.digest == expected)
        for splitIndex in 0...frame.count {
            var hasher = SHA256()
            hasher.update(data: Data(frame[..<splitIndex]))
            hasher.update(data: Data(frame[splitIndex...]))
            #expect(ContiguousArray(hasher.finalize()) == expected)
        }
    }

    @Test("[Unit][CDMS-32.2][VOX-API-004] the four-field wire is exact")
    func fourFieldWireIsExact() throws {
        let identity = try emptyDocumentIdentity()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = String(decoding: try encoder.encode(identity), as: UTF8.self)
        #expect(
            encoded
                == #"{"algorithm":"sha256","digest":"\#(emptyFramedDigestText)","#
                + #""projection":{"identifier":"org.voxelia.metadata-complete-record","#
                + #""version":{"major":1,"minor":0}},"scope":"serialisedObject"}"#
        )
        let decoded = try JSONDecoder().decode(
            ContentID.self,
            from: Data(encoded.utf8)
        )
        #expect(decoded == identity)
    }

    @Test("[Unit][CDMS-32.2][VOX-ERR-001] decoding rejects malformed records")
    func decodingRejectsMalformedRecords() throws {
        func record(
            algorithm: String = "sha256",
            digest: String? = nil,
            projectionIdentifier: String = "org.voxelia.metadata-complete-record",
            major: Int = 1,
            minor: Int = 0,
            scope: String = "serialisedObject"
        ) -> String {
            let digestText = digest ?? emptyFramedDigestText
            return #"{"algorithm":"\#(algorithm)","digest":"\#(digestText)","#
                + #""projection":{"identifier":"\#(projectionIdentifier)","#
                + #""version":{"major":\#(major),"minor":\#(minor)}},"scope":"\#(scope)"}"#
        }

        let cases: [(document: String, expected: ContentIdentityError)] = [
            // A known but unaccepted algorithm is unsupported, never a
            // fallback or downgrade; an unknown token is malformed.
            (record(algorithm: "sha512"), .unsupportedAlgorithm),
            (record(algorithm: "blake3"), .unsupportedAlgorithm),
            (record(algorithm: "custom"), .unsupportedAlgorithm),
            (record(algorithm: "md5"), .invalidRecord),
            // Scope, projection and version must match the compiled tuple.
            (record(scope: "sampleBytes"), .unsupportedProjection),
            (record(projectionIdentifier: "org.example.other"), .unsupportedProjection),
            (record(major: 2), .unsupportedProjection),
            (record(minor: 1), .unsupportedProjection),
            // Digest text boundaries and aliases.
            (record(digest: String(emptyFramedDigestText.dropLast())), .invalidRecord),
            (record(digest: emptyFramedDigestText + "00"), .invalidRecord),
            (record(digest: emptyFramedDigestText.uppercased()), .invalidRecord),
            (record(digest: "0x" + String(emptyFramedDigestText.dropFirst(2))), .invalidRecord),
        ]
        for (document, expected) in cases {
            do {
                _ = try JSONDecoder().decode(ContentID.self, from: Data(document.utf8))
                #expect(Bool(false), "Expected a malformed record to be rejected.")
            } catch let error as ContentIdentityError {
                #expect(error == expected)
            }
        }

        // Missing and extra fields are malformed.
        for document in [
            #"{"algorithm":"sha256","digest":"\#(emptyFramedDigestText)","#
                + #""scope":"serialisedObject"}"#,
            #"{"algorithm":"sha256","digest":"\#(emptyFramedDigestText)","#
                + #""projection":{"identifier":"org.voxelia.metadata-complete-record","#
                + #""version":{"major":1,"minor":0}},"scope":"serialisedObject","#
                + #""extra":true}"#,
        ] {
            do {
                _ = try JSONDecoder().decode(ContentID.self, from: Data(document.utf8))
                #expect(Bool(false), "Expected a malformed field set to be rejected.")
            } catch let error as ContentIdentityError {
                #expect(error == .invalidRecord)
            }
        }
    }

    @Test("[Unit][CDMS-32.2][VOX-SEC-001] projection limits precede grammar")
    func projectionLimitsPrecedeGrammar() throws {
        let version = ContentProjectionVersion(major: 1, minor: 0)
        for valid in ["a.b", "org.voxelia.metadata-complete-record", "0a.b-1.c2"] {
            _ = try ContentProjectionReference(identifier: valid, version: version)
        }
        for invalid in ["", "org", "Org.b", "a..b", "-a.b", "a-.b", "a_b.c"] {
            do {
                _ = try ContentProjectionReference(identifier: invalid, version: version)
                #expect(Bool(false), "Expected an invalid identifier to be rejected.")
            } catch ContentProjectionReferenceError.invalidIdentifier {}
        }

        // Byte limits are checked before grammar: an oversized identifier
        // containing grammar violations still fails as a byte-limit error.
        let label63 = String(repeating: "a", count: 63)
        _ = try ContentProjectionReference(identifier: "\(label63).b", version: version)
        do {
            let oversizedLabel = String(repeating: "A", count: 64) + ".b"
            _ = try ContentProjectionReference(identifier: oversizedLabel, version: version)
            #expect(Bool(false), "Expected the label ceiling to precede grammar.")
        } catch ContentProjectionReferenceError.identifierByteLimitExceeded {}
        let total255 = [String](repeating: label63, count: 4).joined(separator: ".")
        _ = try ContentProjectionReference(identifier: total255, version: version)
        do {
            let total256 = "_" + total255
            #expect(total256.utf8.count == 256)
            _ = try ContentProjectionReference(identifier: total256, version: version)
            #expect(Bool(false), "Expected the total ceiling to precede grammar.")
        } catch ContentProjectionReferenceError.identifierByteLimitExceeded {}

        // Distinct versions are distinct references.
        let left = try ContentProjectionReference(identifier: "a.b", version: version)
        let right = try ContentProjectionReference(
            identifier: "a.b",
            version: ContentProjectionVersion(major: 1, minor: 1)
        )
        #expect(left != right)
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-006] identity failures stay payload-free")
    func identityFailuresStayPayloadFree() throws {
        // Records built under patient-sentinel projection names reject
        // without leaking the sentinel.
        let sentinelJSON =
            #"{"algorithm":"sha256","digest":"\#(emptyFramedDigestText)","#
            + #""projection":{"identifier":"org.patient-sentinel.records","#
            + #""version":{"major":1,"minor":0}},"scope":"serialisedObject"}"#
        do {
            _ = try JSONDecoder().decode(ContentID.self, from: Data(sentinelJSON.utf8))
            #expect(Bool(false), "Expected an unaccepted projection to be rejected.")
        } catch let error as ContentIdentityError {
            #expect(error == .unsupportedProjection)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("patient-sentinel"))
        }

        do {
            _ = try ContentProjectionReference(
                identifier: "Patient Sentinel",
                version: ContentProjectionVersion(major: 1, minor: 0)
            )
            #expect(Bool(false), "Expected an invalid identifier to be rejected.")
        } catch let error as ContentProjectionReferenceError {
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("Patient"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
