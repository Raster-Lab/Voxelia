// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("ProvenanceRecord")
struct ProvenanceRecordTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func operationActivity() throws -> ProvenanceActivity {
        let token = try DerivationOperationToken(
            rawValue: "org.voxelia.op.window-level"
        )
        let claimVersion = try SemanticVersion(major: 1, minor: 0, patch: 0)
        return .operation(
            try OperationProvenance(
                operationID: token,
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

    private func input(
        _ role: String,
        occurrence: UInt32 = 1
    ) throws -> ProvenanceInput {
        try ProvenanceInput(
            role: try ProvenanceInputRole(rawValue: role),
            occurrence: occurrence,
            identity: .object(try #require(DataObjectID(rawValue: "series-6"))),
            parent: .graphNode(try #require(ProvenanceID(rawValue: "node-1")))
        )
    }

    private func record(
        kind: ProvenanceKind,
        activity: ProvenanceActivity,
        inputs: ContiguousArray<ProvenanceInput> = [],
        warnings: ContiguousArray<ProvenanceWarning> = [],
        declaresZeroInputGenerator: Bool = false
    ) throws -> ProvenanceRecord {
        try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-1")),
            kind: kind,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: "series-7"))),
            software: try software(),
            activity: activity,
            inputs: inputs,
            warnings: warnings,
            validationClaim: .unknown,
            declaresZeroInputGenerator: declaresZeroInputGenerator
        )
    }

    @Test("[Unit][VOX-META-004][VOX-META-006] kind coherence and input rules hold")
    func kindCoherenceAndInputRulesHold() throws {
        // A source origin with no inputs is the valid origin shape.
        let origin = try record(kind: .source, activity: .origin)
        #expect(origin.kind == .source)

        // Kind coherence is enforced in both directions.
        do {
            _ = try record(kind: .transformed, activity: .origin)
            #expect(Bool(false), "Expected a non-source origin to be rejected.")
        } catch ProvenanceRecordError.activityKindMismatch {}
        do {
            _ = try record(
                kind: .source,
                activity: try operationActivity(),
                inputs: [try input("input")]
            )
            #expect(Bool(false), "Expected a source operation to be rejected.")
        } catch ProvenanceRecordError.activityKindMismatch {}

        // An origin cannot carry inputs; an operation needs inputs
        // unless a zero-input generator is declared, and the declaration
        // rejects inputs.
        do {
            _ = try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-1")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "series-7"))),
                software: try software(),
                activity: .origin,
                inputs: [try input("input")],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            )
            #expect(Bool(false), "Expected origin inputs to be rejected.")
        } catch ProvenanceRecordError.unexpectedInputs {}
        do {
            _ = try record(kind: .transformed, activity: try operationActivity())
            #expect(Bool(false), "Expected an undeclared empty sequence to be rejected.")
        } catch ProvenanceRecordError.emptyInputSequence {}
        do {
            _ = try record(
                kind: .transformed,
                activity: try operationActivity(),
                inputs: [try input("input")],
                declaresZeroInputGenerator: true
            )
            #expect(Bool(false), "Expected a declared generator with inputs to be rejected.")
        } catch ProvenanceRecordError.unexpectedInputSequence {}
        _ = try record(
            kind: .transformed,
            activity: try operationActivity(),
            declaresZeroInputGenerator: true
        )

        // Repeated role/occurrence pairs are rejected; distinct
        // occurrences and roles are admitted with order participating.
        do {
            _ = try record(
                kind: .transformed,
                activity: try operationActivity(),
                inputs: [try input("input"), try input("input")]
            )
            #expect(Bool(false), "Expected a repeated occurrence to be rejected.")
        } catch ProvenanceRecordError.duplicateInputOccurrence {}
        let forward = try record(
            kind: .transformed,
            activity: try operationActivity(),
            inputs: [try input("input", occurrence: 1), try input("input", occurrence: 2)]
        )
        let reversed = try record(
            kind: .transformed,
            activity: try operationActivity(),
            inputs: [try input("input", occurrence: 2), try input("input", occurrence: 1)]
        )
        #expect(forward != reversed)
        #expect(Set([forward, reversed]).count == 2)

        requireSendable(ProvenanceRecord.self)
        requireSendable(ProvenanceActivity.self)
        requireSendable(ProvenanceRecordError.self)
    }

    @Test("[Unit][VOX-META-008][VOX-ERR-001] warnings aggregate and claims stay claims")
    func warningsAggregateAndClaimsStayClaims() throws {
        func warning(
            _ code: String,
            severity: ProvenanceWarningSeverity = .informational,
            count: UInt64 = 1
        ) throws -> ProvenanceWarning {
            try ProvenanceWarning(
                code: try ProvenanceWarningCode(rawValue: code),
                schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
                severity: severity,
                occurrenceCount: count
            )
        }

        // A repeated warning key is rejected even when the counts
        // differ — repetition belongs in the occurrence count.
        do {
            _ = try record(
                kind: .source,
                activity: .origin,
                warnings: [
                    try warning("org.voxelia.warning.partial-input"),
                    try warning("org.voxelia.warning.partial-input", count: 2),
                ]
            )
            #expect(Bool(false), "Expected a repeated warning key to be rejected.")
        } catch ProvenanceRecordError.duplicateWarning {}

        // Distinct codes and severities are admitted in order.
        let recorded = try record(
            kind: .source,
            activity: .origin,
            warnings: [
                try warning("org.voxelia.warning.partial-input", count: 3),
                try warning(
                    "org.voxelia.warning.partial-input",
                    severity: .qualityAffecting
                ),
                try warning("org.voxelia.warning.clipped-output"),
            ]
        )
        #expect(recorded.warnings.count == 3)

        // A cached-kind record carries its claims unchanged: the
        // validation claim is whatever was asserted, and construction
        // grants no new authority.
        let cached = try record(
            kind: .cached,
            activity: try operationActivity(),
            inputs: [try input("input")]
        )
        #expect(cached.validationClaim == .unknown)

        // Rejections stay payload-free.
        do {
            _ = try record(
                kind: .source,
                activity: .origin,
                warnings: [
                    try warning("org.voxelia.warning.patient-sentinel"),
                    try warning("org.voxelia.warning.patient-sentinel"),
                ]
            )
            #expect(Bool(false), "Expected a repeated warning key to be rejected.")
        } catch let error as ProvenanceRecordError {
            #expect(error == .duplicateWarning)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("patient-sentinel"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
