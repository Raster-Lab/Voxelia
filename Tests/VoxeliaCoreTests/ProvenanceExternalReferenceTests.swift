// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("ProvenanceExternalReference")
struct ProvenanceExternalReferenceTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func operationActivity() throws -> ProvenanceActivity {
        let claimVersion = try SemanticVersion(major: 1, minor: 0, patch: 0)
        return .operation(
            try OperationProvenance(
                operationID: try DerivationOperationToken(
                    rawValue: "org.voxelia.op.window-level"
                ),
                operationVersion: claimVersion,
                implementationID: try DerivationOperationToken(
                    rawValue: "org.voxelia.impl.window-level.cpu"
                ),
                implementationVersion: claimVersion,
                parameterDigest: try ContentID.operationParametersIdentity(
                    overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
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
                        rawValue: "org.voxelia.backend.cpu"
                    ),
                    version: claimVersion
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
        )
    }

    private func originRecord() throws -> ProvenanceRecord {
        try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-1")),
            kind: .source,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: "series-7"))),
            software: try software(),
            activity: .origin,
            inputs: [],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
    }

    private func originClaim() throws -> ContentID {
        try ContentID.provenanceRecordIdentity(
            overCanonicalBytes: try CanonicalProvenanceJSON.encodeRecordDocument(
                record: try originRecord(),
                maximumOutputByteCount: 4_096
            )
        )
    }

    private func child(
        _ name: String,
        inputs: [(identity: DataIdentityReference, parent: ProvenanceParentReference?)]
    ) throws -> ProvenanceRecord {
        var built = ContiguousArray<ProvenanceInput>()
        for (index, edge) in inputs.enumerated() {
            built.append(
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: UInt32(index + 1),
                    identity: edge.identity,
                    parent: edge.parent
                )
            )
        }
        return try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: name)),
            kind: .transformed,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: "obj-\(name)"))),
            software: try software(),
            activity: try operationActivity(),
            inputs: built,
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
    }

    private func limits(
        cap: UInt64 = 4,
        resolutionBytes: UInt64 = 8_192
    ) throws -> ProvenanceGraphLimits {
        try ProvenanceGraphLimits(
            maximumRecordCount: 16,
            maximumParentEdgeCount: 16,
            maximumAncestryDepth: 16,
            maximumUnresolvedExternalReferenceCount: cap,
            maximumExternalResolutionByteCount: resolutionBytes
        )
    }

    @Test("[Unit][CDMS-32.2][VOX-CON-006] the external golden pins the widened wire")
    func externalGoldenPinsTheWidenedWire() throws {
        // The ADR-0062 fixture is the ADR-0060 operation golden whose
        // parent claim is replaced by an external record claim carrying
        // the registered origin golden digest; matching the
        // independently computed framed digest pins the exact bytes.
        let claim = try originClaim()
        #expect(
            ContentID.hexDigestText(claim.digest)
                == "ed854a6de518a2965127989ee8523f030d58fd1c33acdff6699086ed7afc3fb5"
        )
        let record = try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-2")),
            kind: .transformed,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: "series-8"))),
            software: try software(),
            activity: try operationActivity(),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .object(try #require(DataObjectID(rawValue: "series-7"))),
                    parent: .externalRecord(
                        try ExternalProvenanceRecordReference(
                            id: try #require(ProvenanceID(rawValue: "record-1")),
                            recordContentID: claim
                        )
                    )
                )
            ],
            warnings: [
                try ProvenanceWarning(
                    code: try ProvenanceWarningCode(
                        rawValue: "org.voxelia.warning.partial-input"
                    ),
                    schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
                    severity: .informational,
                    occurrenceCount: 3
                )
            ],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
        let emitted = try CanonicalProvenanceJSON.encodeRecordDocument(
            record: record,
            maximumOutputByteCount: 8_192
        )
        #expect(emitted.count == 1_995)
        let text = String(decoding: emitted, as: UTF8.self)
        #expect(
            text.contains(
                #""parent":{"externalRecord":{"id":{"rawValue":"record-1"},"#
                    + #""recordContentID":{"algorithm":"sha256","#
            )
        )
        let identity = try ContentID.provenanceRecordIdentity(
            overCanonicalBytes: emitted
        )
        #expect(
            ContentID.hexDigestText(identity.digest)
                == "01ae4dcb6673c6db770503656878ce9eddbaf23197b011e707f70232a55fe2af"
        )

        // The widened wire round-trips through strict ingress.
        let decoded = try CanonicalProvenanceJSON.decodeRecordDocument(
            from: emitted,
            maximumInputByteCount: 8_192
        )
        #expect(decoded == record)

        // A record claim can only carry the registered provenance-record
        // tuple, and rejection stays payload-free.
        do {
            _ = try ExternalProvenanceRecordReference(
                id: try #require(ProvenanceID(rawValue: "record-1")),
                recordContentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [1, 2]
                )
            )
            #expect(Bool(false), "Expected a foreign record claim to be rejected.")
        } catch let error as ProvenanceClaimError {
            #expect(error == .unsupportedRecordProjection)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("sample"))
        }
        do {
            let crossed = text.replacingOccurrences(
                of: #""projection":{"identifier":"org.voxelia.provenance-record""#,
                with: #""projection":{"identifier":"org.voxelia.sample-bytes""#
            )
            _ = try CanonicalProvenanceJSON.decodeRecordDocument(
                from: Array(crossed.utf8),
                maximumInputByteCount: 8_192
            )
            #expect(Bool(false), "Expected a crossed record claim to be rejected.")
        } catch let error as ProvenanceJSONIngressError {
            #expect(error == .invalidDocument)
        }

        requireSendable(ExternalProvenanceRecordReference.self)
        requireSendable(ProvenanceGraphAdmissionMode.self)
        requireSendable(ProvenanceGraphAuthority.self)
    }

    @Test("[Unit][VOX-META-009][VOX-META-006] compact admission retains, verifies and resolves")
    func compactAdmissionRetainsVerifiesAndResolves() throws {
        let origin = try originRecord()
        let originSubject = DataIdentityReference.object(
            try #require(DataObjectID(rawValue: "series-7"))
        )
        let external = ProvenanceParentReference.externalRecord(
            try ExternalProvenanceRecordReference(
                id: origin.id,
                recordContentID: try originClaim()
            )
        )
        let resolvedChild = try child("b", inputs: [(originSubject, external)])

        // An available external parent is verified and resolved: both
        // modes admit, the authority is complete and depth counts the
        // resolved edge.
        for mode in [ProvenanceGraphAdmissionMode.complete, .compact] {
            let admitted = try ProvenanceGraph.admitGraph(
                records: [origin, resolvedChild],
                roots: [resolvedChild.id],
                limits: try limits(),
                mode: mode
            )
            #expect(admitted.authority == .complete)
            #expect(admitted.unresolvedExternalReferenceOccurrenceCount == 0)
            #expect(admitted.maximumResolvedAncestryDepth == 2)
        }

        // A wrong available claim and an over-ceiling resolution reject.
        let wrongClaim = ProvenanceParentReference.externalRecord(
            try ExternalProvenanceRecordReference(
                id: origin.id,
                recordContentID: try ContentID.provenanceRecordIdentity(
                    overCanonicalBytes: [1, 2, 3]
                )
            )
        )
        do {
            _ = try ProvenanceGraph.admitGraph(
                records: [origin, try child("b", inputs: [(originSubject, wrongClaim)])],
                roots: [try #require(ProvenanceID(rawValue: "b"))],
                limits: try limits(),
                mode: .complete
            )
            #expect(Bool(false), "Expected a wrong record claim to be rejected.")
        } catch ProvenanceGraphError.externalClaimMismatch {}
        do {
            _ = try ProvenanceGraph.admitGraph(
                records: [origin, resolvedChild],
                roots: [resolvedChild.id],
                limits: try limits(resolutionBytes: 10),
                mode: .complete
            )
            #expect(Bool(false), "Expected the resolution ceiling to reject.")
        } catch ProvenanceGraphError.externalResolutionLimitExceeded {}

        // Unresolved externals: complete mode rejects; compact mode
        // retains under the cap and reports compact authority; a zero
        // cap admits none; and a later transaction supplying the record
        // resolves to complete authority with both bindings rechecked.
        do {
            _ = try ProvenanceGraph.admitGraph(
                records: [resolvedChild],
                roots: [resolvedChild.id],
                limits: try limits(),
                mode: .complete
            )
            #expect(Bool(false), "Expected complete mode to reject an unresolved external.")
        } catch ProvenanceGraphError.unresolvedExternalReference {}
        let compact = try ProvenanceGraph.admitGraph(
            records: [resolvedChild],
            roots: [resolvedChild.id],
            limits: try limits(),
            mode: .compact
        )
        #expect(compact.authority == .compact)
        #expect(compact.unresolvedExternalReferenceOccurrenceCount == 1)
        #expect(compact.recordCount == 1)
        #expect(compact.maximumResolvedAncestryDepth == 1)
        do {
            _ = try ProvenanceGraph.admitGraph(
                records: [resolvedChild],
                roots: [resolvedChild.id],
                limits: try limits(cap: 0),
                mode: .compact
            )
            #expect(Bool(false), "Expected the zero cap to admit none.")
        } catch ProvenanceGraphError.unresolvedExternalReferenceLimitExceeded {}
        let resolved = try ProvenanceGraph.admitGraph(
            records: [origin, resolvedChild],
            roots: [resolvedChild.id],
            limits: try limits(),
            mode: .compact
        )
        #expect(resolved.authority == .complete)

        // Repeated unresolved occurrences of one identifier must agree
        // in both the record-content claim and the expected subject.
        do {
            _ = try ProvenanceGraph.admitGraph(
                records: [
                    try child(
                        "b",
                        inputs: [(originSubject, external), (originSubject, wrongClaim)]
                    )
                ],
                roots: [try #require(ProvenanceID(rawValue: "b"))],
                limits: try limits(),
                mode: .compact
            )
            #expect(Bool(false), "Expected conflicting claims to be rejected.")
        } catch ProvenanceGraphError.conflictingExternalClaim {}
        do {
            let otherSubject = DataIdentityReference.object(
                try #require(DataObjectID(rawValue: "series-6"))
            )
            _ = try ProvenanceGraph.admitGraph(
                records: [
                    try child(
                        "b",
                        inputs: [(originSubject, external), (otherSubject, external)]
                    )
                ],
                roots: [try #require(ProvenanceID(rawValue: "b"))],
                limits: try limits(),
                mode: .compact
            )
            #expect(Bool(false), "Expected conflicting expected subjects to be rejected.")
        } catch ProvenanceGraphError.conflictingExternalClaim {}

        // Self-naming external references and available-subject
        // mismatches reject regardless of tag.
        do {
            let selfClaim = ProvenanceParentReference.externalRecord(
                try ExternalProvenanceRecordReference(
                    id: try #require(ProvenanceID(rawValue: "b")),
                    recordContentID: try originClaim()
                )
            )
            _ = try ProvenanceGraph.admitGraph(
                records: [try child("b", inputs: [(originSubject, selfClaim)])],
                roots: [try #require(ProvenanceID(rawValue: "b"))],
                limits: try limits(),
                mode: .compact
            )
            #expect(Bool(false), "Expected a self-naming external to be rejected.")
        } catch ProvenanceGraphError.selfReference {}
        do {
            let otherSubject = DataIdentityReference.object(
                try #require(DataObjectID(rawValue: "series-6"))
            )
            _ = try ProvenanceGraph.admitGraph(
                records: [origin, try child("b", inputs: [(otherSubject, external)])],
                roots: [try #require(ProvenanceID(rawValue: "b"))],
                limits: try limits(),
                mode: .complete
            )
            #expect(Bool(false), "Expected an available subject mismatch to be rejected.")
        } catch ProvenanceGraphError.parentSubjectMismatch {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
