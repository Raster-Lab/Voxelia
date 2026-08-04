// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("CanonicalDerivationJSON")
struct CanonicalDerivationJSONTests {
    private func parameterDigest() throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )
    }

    private func fullRecord() throws -> DerivationIdentity {
        try DerivationIdentity(
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
                    identity: .object(try #require(DataObjectID(rawValue: "series-6")))
                )
            ],
            parameterDigest: try parameterDigest(),
            declaresZeroInputGenerator: false
        )
    }

    private func generatorRecord() throws -> DerivationIdentity {
        try DerivationIdentity(
            operationID: try DerivationOperationToken(
                rawValue: "org.voxelia.op.window-level"
            ),
            operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
            implementation: nil,
            inputs: [],
            parameterDigest: try parameterDigest(),
            declaresZeroInputGenerator: true
        )
    }

    @Test("[Unit][CDMS-32.2][VOX-CON-006] the derivation goldens pin the profile")
    func derivationGoldensPinTheProfile() throws {
        // The ADR-0072 fixtures: a full record exercising build
        // metadata and a declared zero-input generator whose canonical
        // form is the empty input array.
        let fullBytes = try CanonicalDerivationJSON.encodeRecordDocument(
            record: try fullRecord(),
            maximumOutputByteCount: 4_096
        )
        #expect(fullBytes.count == 721)
        let fullIdentity = try ContentID.derivationRecordIdentity(
            overCanonicalBytes: fullBytes
        )
        #expect(
            ContentID.hexDigestText(fullIdentity.digest)
                == "3943d56310af994641f708d3fe9ad185d94211f16f9ba571ae9ecdf719302b72"
        )
        #expect(fullIdentity.projection == ContentID.derivationRecordProjection)
        #expect(try fullIdentity.matchesDigest(ofCanonicalBytes: fullBytes))

        let generatorBytes = try CanonicalDerivationJSON.encodeRecordDocument(
            record: try generatorRecord(),
            maximumOutputByteCount: 4_096
        )
        #expect(generatorBytes.count == 522)
        #expect(
            ContentID.hexDigestText(
                try ContentID.derivationRecordIdentity(
                    overCanonicalBytes: generatorBytes
                ).digest
            )
                == "e4e000131cca0d8d350b6d2260f791bf6a94f3ef2c05cbe45249c5fb3e055ccc"
        )
        #expect(
            fullBytes
                == (try CanonicalDerivationJSON.encodeRecordDocument(
                    record: try fullRecord(),
                    maximumOutputByteCount: 4_096
                ))
        )

        // The record claim admits only the registered derivation tuple,
        // and the output byte ceiling is exact.
        _ = try DerivationRecordID(recordContentID: fullIdentity)
        do {
            _ = try DerivationRecordID(
                recordContentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [1, 2]
                )
            )
            #expect(Bool(false), "Expected a foreign record claim to be rejected.")
        } catch DerivationIdentityError.unsupportedRecordProjection {}
        do {
            _ = try CanonicalDerivationJSON.encodeRecordDocument(
                record: try fullRecord(),
                maximumOutputByteCount: 720
            )
            #expect(Bool(false), "Expected the byte ceiling to reject.")
        } catch DerivationJSONEmissionError.outputByteLimitExceeded {}

        requireSendable(DerivationRecordID.self)
        requireSendable(DerivationJSONEmissionError.self)
    }

    @Test("[Unit][VOX-API-004][VOX-DAT-014] the derivation reference completes the union")
    func derivationReferenceCompletesTheUnion() throws {
        let recordID = try DerivationRecordID(
            recordContentID: try ContentID.derivationRecordIdentity(
                overCanonicalBytes: try CanonicalDerivationJSON.encodeRecordDocument(
                    record: try fullRecord(),
                    maximumOutputByteCount: 4_096
                )
            )
        )
        let reference = DataIdentityReference.derivation(recordID)

        // The ADR-0053 strict wire round-trips the widened union and
        // rejects a malformed nested record.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = String(decoding: try encoder.encode(reference), as: UTF8.self)
        #expect(encoded.hasPrefix(#"{"derivation":{"recordContentID":{"algorithm""#))
        let decoded = try JSONDecoder().decode(
            DataIdentityReference.self,
            from: Data(encoded.utf8)
        )
        #expect(decoded == reference)
        do {
            let malformed = encoded.replacingOccurrences(
                of: #"{"recordContentID":"#,
                with: #"{"extra":null,"recordContentID":"#
            )
            _ = try JSONDecoder().decode(
                DataIdentityReference.self,
                from: Data(malformed.utf8)
            )
            #expect(Bool(false), "Expected a malformed nested record to be rejected.")
        } catch let error as DataIdentityReferenceError {
            #expect(error == .invalidRecord)
        }

        // A provenance record whose input identity is a derivation
        // reference round-trips through the accepted VCPJ-1 codec.
        let derived = try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-3")),
            kind: .transformed,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: "series-9"))),
            software: try SoftwareIdentity(
                name: "Voxelia",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: nil,
                buildIdentifier: nil
            ),
            activity: .operation(
                try OperationProvenance(
                    operationID: try DerivationOperationToken(
                        rawValue: "org.voxelia.op.window-level"
                    ),
                    operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
                    implementationID: try DerivationOperationToken(
                        rawValue: "org.voxelia.impl.window-level.cpu"
                    ),
                    implementationVersion: try SemanticVersion(
                        major: 1,
                        minor: 0,
                        patch: 0
                    ),
                    parameterDigest: try parameterDigest()
                ),
                ExecutionProvenanceClaim(
                    profile: try ExecutionComponentReference(
                        identifier: try ExecutionClaimToken(
                            rawValue: "org.voxelia.profile.default"
                        ),
                        version: try SemanticVersion(major: 1, minor: 0, patch: 0)
                    ),
                    backend: try ExecutionComponentReference(
                        identifier: try ExecutionClaimToken(
                            rawValue: "org.voxelia.backend.cpu"
                        ),
                        version: try SemanticVersion(major: 1, minor: 0, patch: 0)
                    ),
                    precisionPolicy: try ExecutionClaimToken(
                        rawValue: "org.voxelia.precision.binary64-strict"
                    ),
                    qualityPolicy: try ExecutionClaimToken(
                        rawValue: "org.voxelia.quality.full"
                    ),
                    approximationStatus: .exact,
                    capabilityClass: nil,
                    kernel: nil
                )
            ),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "recipe"),
                    occurrence: 1,
                    identity: reference,
                    parent: nil
                )
            ],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
        let vcpjBytes = try CanonicalProvenanceJSON.encodeRecordDocument(
            record: derived,
            maximumOutputByteCount: 16_384
        )
        let roundTripped = try CanonicalProvenanceJSON.decodeRecordDocument(
            from: vcpjBytes,
            maximumInputByteCount: 16_384
        )
        #expect(roundTripped == derived)
        #expect(roundTripped.inputs[0].identity == reference)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
