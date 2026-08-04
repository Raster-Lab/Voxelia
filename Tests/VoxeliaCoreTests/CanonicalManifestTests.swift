// SPDX-License-Identifier: MIT

import CryptoKit
import Foundation
import Testing

@testable import VoxeliaCore

@Suite("CanonicalManifest")
struct CanonicalManifestTests {
    private func knownRecords() throws -> (derivation: ContentID, provenance: ContentID) {
        let derivationBytes = try CanonicalDerivationJSON.encodeRecordDocument(
            record: try DerivationIdentity(
                operationID: try DerivationOperationToken(
                    rawValue: "org.voxelia.op.window-level"
                ),
                operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
                implementation: DerivationImplementationReference(
                    identifier: try DerivationOperationToken(
                        rawValue: "org.voxelia.impl.window-level.cpu"
                    ),
                    version: try SemanticVersion(
                        major: 2,
                        minor: 1,
                        patch: 0,
                        buildMetadata: "build7"
                    )
                ),
                inputs: [
                    DerivationInput(
                        role: try DerivationInputRole(rawValue: "input"),
                        identity: .object(
                            try #require(DataObjectID(rawValue: "series-6"))
                        )
                    )
                ],
                parameterDigest: try ContentID.operationParametersIdentity(
                    overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                        payload: try MetadataCollection(entries: []),
                        maximumOutputByteCount: 4_096
                    )
                ),
                declaresZeroInputGenerator: false
            ),
            maximumOutputByteCount: 4_096
        )
        let provenanceBytes = try CanonicalProvenanceJSON.encodeRecordDocument(
            record: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-1")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "series-7"))),
                software: try SoftwareIdentity(
                    name: "Voxelia",
                    version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                    commit: nil,
                    buildIdentifier: nil
                ),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            maximumOutputByteCount: 4_096
        )
        return (
            try ContentID.derivationRecordIdentity(overCanonicalBytes: derivationBytes),
            try ContentID.provenanceRecordIdentity(overCanonicalBytes: provenanceBytes)
        )
    }

    @Test("[Unit][CDMS-32.2][VOX-CON-006] the manifest golden pins one canonical form")
    func manifestGoldenPinsOneCanonicalForm() throws {
        // The ADR-0078 fixture: the registered derivation and
        // provenance goldens in ascending digest order, independently
        // digest-pinned; supplying the records in either order emits
        // identical bytes.
        let (derivation, provenance) = try knownRecords()
        let bytes = try CanonicalManifest.encodeManifestDocument(
            records: [provenance, derivation],
            maximumOutputByteCount: 4_096
        )
        #expect(bytes.count == 555)
        #expect(
            bytes
                == (try CanonicalManifest.encodeManifestDocument(
                    records: [derivation, provenance],
                    maximumOutputByteCount: 4_096
                ))
        )
        let identity = try ContentID.recordManifestIdentity(overCanonicalBytes: bytes)
        #expect(
            ContentID.hexDigestText(identity.digest)
                == "7cc52c692edc9fcb3632584a9da9c97c3b351ce43efc6398a68ff75e0eae991f"
        )
        #expect(identity.projection == ContentID.recordManifestProjection)
        #expect(try identity.matchesDigest(ofCanonicalBytes: bytes))

        // Empty and duplicate record sets reject typed, and the output
        // ceiling binds exactly.
        do {
            _ = try CanonicalManifest.encodeManifestDocument(
                records: [],
                maximumOutputByteCount: 4_096
            )
            #expect(Bool(false), "Expected an empty manifest to be rejected.")
        } catch RecordManifestError.emptyManifest {}
        do {
            _ = try CanonicalManifest.encodeManifestDocument(
                records: [derivation, derivation],
                maximumOutputByteCount: 4_096
            )
            #expect(Bool(false), "Expected a duplicate record to be rejected.")
        } catch RecordManifestError.duplicateManifestRecord {}
        do {
            _ = try CanonicalManifest.encodeManifestDocument(
                records: [provenance, derivation],
                maximumOutputByteCount: 554
            )
            #expect(Bool(false), "Expected the byte ceiling to reject.")
        } catch RecordManifestError.outputByteLimitExceeded {}

        requireSendable(RecordManifestError.self)
    }

    @Test("[Unit][VOX-SEC-010][VOX-SEC-011] signatures verify custody and nothing else")
    func signaturesVerifyCustodyAndNothingElse() throws {
        let (derivation, provenance) = try knownRecords()
        let identity = try ContentID.recordManifestIdentity(
            overCanonicalBytes: try CanonicalManifest.encodeManifestDocument(
                records: [derivation, provenance],
                maximumOutputByteCount: 4_096
            )
        )

        // A host-side key signs the manifest identity's digest bytes;
        // Voxelia verifies with the raw public key.
        let hostKey = Curve25519.Signing.PrivateKey()
        let signature = [UInt8](try hostKey.signature(for: Data(identity.digest)))
        let publicKey = [UInt8](hostKey.publicKey.rawRepresentation)
        #expect(
            try CanonicalManifest.verifySignature(
                signature,
                manifestIdentity: identity,
                publicKeyBytes: publicKey
            )
        )

        // A tampered signature, a different manifest and a different
        // key all fail as boolean results.
        var tampered = signature
        tampered[0] ^= 0xFF
        #expect(
            try CanonicalManifest.verifySignature(
                tampered,
                manifestIdentity: identity,
                publicKeyBytes: publicKey
            ) == false
        )
        let otherIdentity = try ContentID.recordManifestIdentity(
            overCanonicalBytes: try CanonicalManifest.encodeManifestDocument(
                records: [derivation],
                maximumOutputByteCount: 4_096
            )
        )
        #expect(
            try CanonicalManifest.verifySignature(
                signature,
                manifestIdentity: otherIdentity,
                publicKeyBytes: publicKey
            ) == false
        )
        let otherKey = Curve25519.Signing.PrivateKey()
        #expect(
            try CanonicalManifest.verifySignature(
                signature,
                manifestIdentity: identity,
                publicKeyBytes: [UInt8](otherKey.publicKey.rawRepresentation)
            ) == false
        )

        // Malformed encodings reject typed and payload-free.
        do {
            _ = try CanonicalManifest.verifySignature(
                signature,
                manifestIdentity: identity,
                publicKeyBytes: Array(publicKey.dropLast())
            )
            #expect(Bool(false), "Expected a malformed key to be rejected.")
        } catch RecordManifestError.invalidPublicKeyEncoding {}
        do {
            _ = try CanonicalManifest.verifySignature(
                Array(signature.dropLast()),
                manifestIdentity: identity,
                publicKeyBytes: publicKey
            )
            #expect(Bool(false), "Expected a malformed signature to be rejected.")
        } catch let error as RecordManifestError {
            #expect(error == .invalidSignatureEncoding)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("key"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
