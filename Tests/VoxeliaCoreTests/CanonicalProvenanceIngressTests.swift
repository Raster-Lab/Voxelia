// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("CanonicalProvenanceIngress")
struct CanonicalProvenanceIngressTests {
    private func originRecord() throws -> ProvenanceRecord {
        try ProvenanceRecord(
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
        )
    }

    private func operationRecord() throws -> ProvenanceRecord {
        let claimVersion = try SemanticVersion(major: 1, minor: 0, patch: 0)
        return try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-2")),
            kind: .transformed,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .source(
                try SourceIdentity(
                    namespace: "dicom.sop-instance-uid",
                    identifier: "1.2.840.113619.2",
                    version: "2",
                    contentID: try ContentID.sampleBytesIdentity(
                        overCanonicalPackedBytes: Array(0..<24)
                    )
                )
            ),
            software: try SoftwareIdentity(
                name: "Voxelia",
                version: try SemanticVersion(
                    major: 1,
                    minor: 2,
                    patch: 3,
                    prerelease: "rc1",
                    buildMetadata: "build7"
                ),
                commit: "0abc123",
                buildIdentifier: "ci-42"
            ),
            activity: .operation(
                try OperationProvenance(
                    operationID: try DerivationOperationToken(
                        rawValue: "org.voxelia.op.window-level"
                    ),
                    operationVersion: claimVersion,
                    implementationID: try DerivationOperationToken(
                        rawValue: "org.voxelia.impl.window-level.cpu"
                    ),
                    implementationVersion: try SemanticVersion(
                        major: 2,
                        minor: 0,
                        patch: 0,
                        buildMetadata: "build9"
                    ),
                    parameterDigest: try ContentID.operationParametersIdentity(
                        overCanonicalBytes:
                            try CanonicalMetadataJSON
                            .encodeUniqueDocument(
                                payload: try MetadataCollection(entries: []),
                                maximumOutputByteCount: 4_096
                            )
                    )
                ),
                ExecutionProvenanceClaim(
                    profile: try ExecutionComponentReference(
                        identifier: try ExecutionClaimToken(
                            rawValue: "org.voxelia.profile.default"
                        ),
                        version: claimVersion
                    ),
                    backend: try ExecutionComponentReference(
                        identifier: try ExecutionClaimToken(
                            rawValue: "org.voxelia.backend.metal"
                        ),
                        version: claimVersion
                    ),
                    precisionPolicy: try ExecutionClaimToken(
                        rawValue: "org.voxelia.precision.binary64-strict"
                    ),
                    qualityPolicy: try ExecutionClaimToken(
                        rawValue: "org.voxelia.quality.full"
                    ),
                    approximationStatus: .approximate,
                    capabilityClass: try ExecutionClaimToken(
                        rawValue: "org.voxelia.capability.compute"
                    ),
                    kernel: try ExecutionComponentReference(
                        identifier: try ExecutionClaimToken(
                            rawValue: "org.voxelia.kernel.window-level"
                        ),
                        version: claimVersion
                    )
                )
            ),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .content(
                        try ContentID.sampleBytesIdentity(
                            overCanonicalPackedBytes: Array(0..<24)
                        )
                    ),
                    parent: .graphNode(
                        try #require(ProvenanceID(rawValue: "record-1"))
                    )
                ),
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "mask"),
                    occurrence: 1,
                    identity: .object(
                        try #require(DataObjectID(rawValue: "series-6"))
                    ),
                    parent: nil
                ),
            ],
            warnings: [
                try ProvenanceWarning(
                    code: try ProvenanceWarningCode(
                        rawValue: "org.voxelia.warning.partial-input"
                    ),
                    schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
                    severity: .qualityAffecting,
                    occurrenceCount: 3
                )
            ],
            validationClaim: .validated(
                try #require(ValidationEvidenceID(rawValue: "evidence-7"))
            ),
            declaresZeroInputGenerator: false
        )
    }

    @Test("[Unit][CDMS-32.2][VOX-API-004] canonical documents round-trip exactly")
    func canonicalDocumentsRoundTripExactly() throws {
        // Both a minimal origin record and a maximal operation record —
        // every tagged case, optional presence, embedded digest and
        // decimal string token — decode back to equal records with equal
        // identities.
        for record in [try originRecord(), try operationRecord()] {
            let bytes = try CanonicalProvenanceJSON.encodeRecordDocument(
                record: record,
                maximumOutputByteCount: 16_384
            )
            let decoded = try CanonicalProvenanceJSON.decodeRecordDocument(
                from: bytes,
                maximumInputByteCount: 16_384
            )
            #expect(decoded == record)
            let reEmitted = try CanonicalProvenanceJSON.encodeRecordDocument(
                record: decoded,
                maximumOutputByteCount: 16_384
            )
            #expect(reEmitted == bytes)
            #expect(
                try ContentID.provenanceRecordIdentity(overCanonicalBytes: reEmitted)
                    == (try ContentID.provenanceRecordIdentity(
                        overCanonicalBytes: bytes
                    ))
            )
        }

        // A canonical operation document with an empty input sequence
        // reconstructs as the declared zero-input generator.
        let generator = try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-3")),
            kind: .materialised,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: "series-9"))),
            software: try SoftwareIdentity(
                name: "Voxelia",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: nil,
                buildIdentifier: nil
            ),
            activity: (try operationRecord()).activity,
            inputs: [],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: true
        )
        let generatorBytes = try CanonicalProvenanceJSON.encodeRecordDocument(
            record: generator,
            maximumOutputByteCount: 16_384
        )
        #expect(
            try CanonicalProvenanceJSON.decodeRecordDocument(
                from: generatorBytes,
                maximumInputByteCount: 16_384
            ) == generator
        )

        requireSendable(ProvenanceJSONIngressError.self)
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-001] ingress rejects aliases and hostile input")
    func ingressRejectsAliasesAndHostileInput() throws {
        let bytes = try CanonicalProvenanceJSON.encodeRecordDocument(
            record: try originRecord(),
            maximumOutputByteCount: 4_096
        )
        let text = String(decoding: bytes, as: UTF8.self)

        func expectRejection(
            _ document: String,
            _ expected: ProvenanceJSONIngressError
        ) {
            do {
                _ = try CanonicalProvenanceJSON.decodeRecordDocument(
                    from: Array(document.utf8),
                    maximumInputByteCount: 65_536
                )
                #expect(Bool(false), "Expected the document to be rejected.")
            } catch let error as ProvenanceJSONIngressError {
                #expect(error == expected)
            } catch {
                #expect(Bool(false), "Expected a typed ingress error.")
            }
        }

        // The input ceiling is checked first.
        do {
            _ = try CanonicalProvenanceJSON.decodeRecordDocument(
                from: bytes,
                maximumInputByteCount: UInt64(bytes.count - 1)
            )
            #expect(Bool(false), "Expected the input ceiling to reject.")
        } catch ProvenanceJSONIngressError.inputByteLimitExceeded {}

        // A nesting bomb is rejected by the pre-scan before parsing,
        // even when brackets appear inside strings legitimately.
        expectRejection(
            String(repeating: "[", count: 64),
            .rawDepthLimitExceeded
        )
        _ = try CanonicalProvenanceJSON.decodeRecordDocument(
            from: Array(
                text.replacingOccurrences(
                    of: #""name":"Voxelia""#,
                    with: #""name":"Vox[[[[elia""#
                ).utf8
            ),
            maximumInputByteCount: 65_536
        )

        // Malformed JSON, wrong members and invalid values are typed.
        expectRejection("{", .invalidDocument)
        expectRejection("null", .invalidDocument)
        expectRejection(
            text.replacingOccurrences(of: #""kind":"source""#, with: #""kind":"other""#),
            .invalidDocument
        )
        expectRejection(
            text.replacingOccurrences(
                of: #""validationClaim":{"unknown":null}"#,
                with: #""validationClaim":{"unknown":null,"preview":null}"#
            ),
            .invalidDocument
        )
        expectRejection(
            text.replacingOccurrences(
                of: #""warnings":[]}}"#,
                with: #""warnings":[],"extra":null}}"#
            ),
            .invalidDocument
        )

        // Canonical aliases parse but fail the byte-equality gate:
        // inserted whitespace, escape respelling and number respelling.
        expectRejection(
            text.replacingOccurrences(
                of: #""kind":"source""#,
                with: #""kind": "source""#
            ),
            .noncanonicalDocument
        )
        expectRejection(
            text.replacingOccurrences(
                of: #""name":"Voxelia""#,
                with: #""name":"\u0056oxelia""#
            ),
            .noncanonicalDocument
        )
        expectRejection(
            text.replacingOccurrences(
                of: #""version":{"major":1,"minor":0}"#,
                with: #""version":{"major":1e0,"minor":0}"#
            ),
            .noncanonicalDocument
        )

        // Rejections stay payload-free.
        do {
            _ = try CanonicalProvenanceJSON.decodeRecordDocument(
                from: Array("{\"patient-sentinel\":1}".utf8),
                maximumInputByteCount: 65_536
            )
            #expect(Bool(false), "Expected a wrong envelope to be rejected.")
        } catch let error as ProvenanceJSONIngressError {
            #expect(error == .invalidDocument)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("patient-sentinel"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
