// SPDX-License-Identifier: MIT

import CryptoKit
import Foundation
import Testing

@testable import VoxeliaCore

@Suite("ContentID sample bytes")
struct ContentIDSampleBytesTests {
    private let packedFramedDigestText =
        "6f576e15aac5e4331f74c6e88e84385619eba17d6e86e53a3cdb73694dc42111"

    @Test("[Unit][CDMS-32.2][VOX-CON-006] golden digests pin the sample-bytes frame")
    func goldenDigestsPinTheSampleBytesFrame() throws {
        // The ADR-0049 fixtures are computed independently over the
        // 24-byte canonical packed payload 0 through 23.
        let payload: [UInt8] = Array(0..<24)
        let identity = try ContentID.sampleBytesIdentity(
            overCanonicalPackedBytes: payload
        )
        #expect(ContentID.hexDigestText(identity.digest) == packedFramedDigestText)
        #expect(identity.algorithm == .sha256)
        #expect(identity.scope == .sampleBytes)
        #expect(identity.projection == ContentID.sampleBytesProjection)
        #expect(identity.digest.count == 32)

        // Raw SHA-256 of the payload is the registered negative control.
        #expect(
            ContentID.hexDigestText(ContiguousArray(SHA256.hash(data: payload)))
                == "1d64add2a6388367c9bc2d1f1b384b069a6ef382cdaaa89771dd103e28613a25"
        )

        // The identical payload under the complete-record projection
        // matches its own registered fixture and differs from the
        // sample-bytes digest: domain separation is structural.
        let metadataIdentity = try ContentID.completeMetadataRecordIdentity(
            overCanonicalBytes: payload
        )
        #expect(
            ContentID.hexDigestText(metadataIdentity.digest)
                == "8386cecc7804846d22750ebe8ea707814a62f4d39283ebc797def9f2a6c3c9c8"
        )
        #expect(identity != metadataIdentity)
        #expect(identity.digest != metadataIdentity.digest)

        // The 92-byte header is exact and length-framed.
        let header = ContentID.frameHeader(
            scope: .sampleBytes,
            projection: ContentID.sampleBytesProjection,
            payloadByteCount: 24
        )
        #expect(header.count == 92)
        #expect(Array(header.prefix(18)) == Array("VOXELIA-CONTENT-ID".utf8))
        #expect(header[18] == 0)
        #expect(Array(header.suffix(8)) == [0, 0, 0, 0, 0, 0, 0, 24])

        // The empty payload has its own registered fixture, and repeat
        // computation plus verification dispatch under this record's own
        // scope are deterministic and timing-safe.
        let empty = try ContentID.sampleBytesIdentity(overCanonicalPackedBytes: [])
        #expect(
            ContentID.hexDigestText(empty.digest)
                == "f88f7252ab06c52bfc20928e1a1436af70bca32440c76e330656d81bc3f7b42a"
        )
        #expect(try ContentID.sampleBytesIdentity(overCanonicalPackedBytes: payload) == identity)
        #expect(try identity.matchesDigest(ofCanonicalBytes: payload))
        #expect(try metadataIdentity.matchesDigest(ofCanonicalBytes: payload))
        var mutated = payload
        mutated[0] ^= 0xFF
        #expect(try !identity.matchesDigest(ofCanonicalBytes: mutated))
        #expect(try !identity.matchesDigest(ofCanonicalBytes: []))
    }

    @Test("[Unit][CDMS-32.2][VOX-API-004] the wire admits the tuple and rejects crosses")
    func wireAdmitsTheTupleAndRejectsCrosses() throws {
        let identity = try ContentID.sampleBytesIdentity(
            overCanonicalPackedBytes: Array(0..<24)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = String(decoding: try encoder.encode(identity), as: UTF8.self)
        #expect(
            encoded
                == #"{"algorithm":"sha256","digest":"\#(packedFramedDigestText)","#
                + #""projection":{"identifier":"org.voxelia.sample-bytes","#
                + #""version":{"major":1,"minor":0}},"scope":"sampleBytes"}"#
        )
        let decoded = try JSONDecoder().decode(ContentID.self, from: Data(encoded.utf8))
        #expect(decoded == identity)
        #expect(try decoded.matchesDigest(ofCanonicalBytes: Array(0..<24)))

        // Both crossed scope/projection combinations of the two accepted
        // tuples stay rejected as unsupported projections.
        let crossedCases = [
            #"{"algorithm":"sha256","digest":"\#(packedFramedDigestText)","#
                + #""projection":{"identifier":"org.voxelia.metadata-complete-record","#
                + #""version":{"major":1,"minor":0}},"scope":"sampleBytes"}"#,
            #"{"algorithm":"sha256","digest":"\#(packedFramedDigestText)","#
                + #""projection":{"identifier":"org.voxelia.sample-bytes","#
                + #""version":{"major":1,"minor":0}},"scope":"serialisedObject"}"#,
            #"{"algorithm":"sha256","digest":"\#(packedFramedDigestText)","#
                + #""projection":{"identifier":"org.voxelia.sample-bytes","#
                + #""version":{"major":2,"minor":0}},"scope":"sampleBytes"}"#,
            #"{"algorithm":"sha256","digest":"\#(packedFramedDigestText)","#
                + #""projection":{"identifier":"org.voxelia.sample-bytes","#
                + #""version":{"major":1,"minor":0}},"scope":"descriptorAndSamples"}"#,
        ]
        for document in crossedCases {
            do {
                _ = try JSONDecoder().decode(ContentID.self, from: Data(document.utf8))
                #expect(Bool(false), "Expected a crossed tuple to be rejected.")
            } catch let error as ContentIdentityError {
                #expect(error == .unsupportedProjection)
            }
        }
    }
}
