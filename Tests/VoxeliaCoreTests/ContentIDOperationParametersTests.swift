// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("ContentID operation parameters")
struct ContentIDOperationParametersTests {
    private let emptyFramedDigestText =
        "2a4c3dfff218ba745f05ea6cb0224eb3f237d5c5b9d582f979346627edf61d89"

    @Test("[Unit][CDMS-32.2][VOX-CON-006] golden digests pin the parameters frame")
    func goldenDigestsPinTheParametersFrame() throws {
        // The ADR-0054 fixture is computed independently over the exact
        // 148-byte canonical empty parameter document.
        let canonical = try CanonicalMetadataJSON.encodeUniqueDocument(
            payload: try MetadataCollection(entries: []),
            maximumOutputByteCount: 4_096
        )
        let identity = try ContentID.operationParametersIdentity(
            overCanonicalBytes: canonical
        )
        #expect(ContentID.hexDigestText(identity.digest) == emptyFramedDigestText)
        #expect(identity.algorithm == .sha256)
        #expect(identity.scope == .serialisedObject)
        #expect(identity.projection == ContentID.operationParametersProjection)

        // The identical payload under the complete-record projection is
        // the registered ADR-0036 golden: the two serialisedObject
        // projections are structurally domain-separated.
        let record = try ContentID.completeMetadataRecordIdentity(
            overCanonicalBytes: canonical
        )
        #expect(
            ContentID.hexDigestText(record.digest)
                == "8dde6fa088cd4b1e676fca392a6d24fdeed93fc93bdc43c94cfbc75f362e7432"
        )
        #expect(identity != record)
        #expect(identity.digest != record.digest)

        // The 105-byte header is exact and length-framed, and
        // verification dispatches under this record's own tuple.
        let header = ContentID.frameHeader(
            scope: .serialisedObject,
            projection: ContentID.operationParametersProjection,
            payloadByteCount: 148
        )
        #expect(header.count == 105)
        #expect(Array(header.suffix(8)) == [0, 0, 0, 0, 0, 0, 0, 148])
        #expect(try identity.matchesDigest(ofCanonicalBytes: canonical))
        #expect(try !identity.matchesDigest(ofCanonicalBytes: Array(canonical.dropLast())))

        // The wire round-trips the new tuple and rejects the crossed
        // sampleBytes scope.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = String(decoding: try encoder.encode(identity), as: UTF8.self)
        #expect(
            encoded
                == #"{"algorithm":"sha256","digest":"\#(emptyFramedDigestText)","#
                + #""projection":{"identifier":"org.voxelia.operation-parameters","#
                + #""version":{"major":1,"minor":0}},"scope":"serialisedObject"}"#
        )
        let decoded = try JSONDecoder().decode(ContentID.self, from: Data(encoded.utf8))
        #expect(decoded == identity)
        do {
            let crossed =
                #"{"algorithm":"sha256","digest":"\#(emptyFramedDigestText)","#
                + #""projection":{"identifier":"org.voxelia.operation-parameters","#
                + #""version":{"major":1,"minor":0}},"scope":"sampleBytes"}"#
            _ = try JSONDecoder().decode(ContentID.self, from: Data(crossed.utf8))
            #expect(Bool(false), "Expected a crossed tuple to be rejected.")
        } catch let error as ContentIdentityError {
            #expect(error == .unsupportedProjection)
        }
    }
}
