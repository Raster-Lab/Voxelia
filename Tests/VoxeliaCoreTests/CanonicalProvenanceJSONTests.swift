// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("CanonicalProvenanceJSON")
struct CanonicalProvenanceJSONTests {
    private let semverFragment =
        #"{"buildMetadata":null,"major":"1","minor":"0","patch":"0","prerelease":null}"#

    private var softwareFragment: String {
        #"{"buildIdentifier":null,"commit":null,"name":"Voxelia","version":"#
            + semverFragment + "}"
    }

    private let envelopePrefix =
        #"{"documentSchema":{"identifier":"org.voxelia.provenance-record","#
        + #""version":{"major":1,"minor":0}},"payload":"#

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
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

    private func operationRecord() throws -> ProvenanceRecord {
        let claimVersion = try SemanticVersion(major: 1, minor: 0, patch: 0)
        let activity = ProvenanceActivity.operation(
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
        return try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-2")),
            kind: .transformed,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: "series-8"))),
            software: try software(),
            activity: activity,
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .object(try #require(DataObjectID(rawValue: "series-7"))),
                    parent: .graphNode(try #require(ProvenanceID(rawValue: "record-1")))
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
    }

    @Test("[Unit][CDMS-32.2][VOX-CON-006] the origin golden pins the profile")
    func originGoldenPinsTheProfile() throws {
        let expected =
            envelopePrefix
            + #"{"activity":{"origin":null},"createdAt":"2026-08-04T12:00:00Z","#
            + #""id":{"rawValue":"record-1"},"inputs":[],"kind":"source","software":"#
            + softwareFragment
            + #","subject":{"object":{"rawValue":"series-7"}},"#
            + #""validationClaim":{"unknown":null},"warnings":[]}}"#
        #expect(expected.utf8.count == 476)

        let emitted = try CanonicalProvenanceJSON.encodeRecordDocument(
            record: try originRecord(),
            maximumOutputByteCount: 4_096
        )
        #expect(emitted == Array(expected.utf8))
        #expect(
            emitted
                == (try CanonicalProvenanceJSON.encodeRecordDocument(
                    record: try originRecord(),
                    maximumOutputByteCount: 4_096
                ))
        )

        // The ADR-0060 framed fixture is computed independently over the
        // exact 476-byte document, and verification dispatches under the
        // registered provenance-record tuple.
        let identity = try ContentID.provenanceRecordIdentity(
            overCanonicalBytes: emitted
        )
        #expect(
            ContentID.hexDigestText(identity.digest)
                == "ed854a6de518a2965127989ee8523f030d58fd1c33acdff6699086ed7afc3fb5"
        )
        #expect(identity.scope == .serialisedObject)
        #expect(identity.projection == ContentID.provenanceRecordProjection)
        #expect(try identity.matchesDigest(ofCanonicalBytes: emitted))
        #expect(try !identity.matchesDigest(ofCanonicalBytes: Array(emitted.dropLast())))

        // The header is 102 bytes and length-framed.
        let header = ContentID.frameHeader(
            scope: .serialisedObject,
            projection: ContentID.provenanceRecordProjection,
            payloadByteCount: 476
        )
        #expect(header.count == 102)
        #expect(Array(header.suffix(8)) == [0, 0, 0, 0, 0, 0, 1, 0xDC])
    }

    @Test("[Unit][CDMS-32.2][VOX-META-009] the operation golden exercises every shape")
    func operationGoldenExercisesEveryShape() throws {
        let parameterDigestFragment =
            #"{"algorithm":"sha256","digest":"#
            + #""2a4c3dfff218ba745f05ea6cb0224eb3f237d5c5b9d582f979346627edf61d89","#
            + #""projection":{"identifier":"org.voxelia.operation-parameters","#
            + #""version":{"major":1,"minor":0}},"scope":"serialisedObject"}"#
        let executionFragment =
            #"{"approximationStatus":"exact","backend":{"identifier":"org.voxelia.backend.cpu","version":"#
            + semverFragment
            + #"},"capabilityClass":null,"kernel":null,"#
            + #""precisionPolicy":"org.voxelia.precision.binary64-strict","#
            + #""profile":{"identifier":"org.voxelia.profile.default","version":"#
            + semverFragment
            + #"},"qualityPolicy":"org.voxelia.quality.full"}"#
        let operationFragment =
            #"{"implementationID":"org.voxelia.impl.window-level.cpu","implementationVersion":"#
            + semverFragment
            + #","operationID":"org.voxelia.op.window-level","operationVersion":"#
            + semverFragment
            + #","parameterDigest":"#
            + parameterDigestFragment + "}"
        let expected =
            envelopePrefix
            + #"{"activity":{"operation":{"execution":"#
            + executionFragment
            + #","operation":"#
            + operationFragment
            + #"}},"createdAt":"2026-08-04T12:00:00Z","id":{"rawValue":"record-2"},"#
            + #""inputs":[{"identity":{"object":{"rawValue":"series-7"}},"occurrence":1,"#
            + #""parent":{"graphNode":{"rawValue":"record-1"}},"role":"input"}],"#
            + #""kind":"transformed","software":"#
            + softwareFragment
            + #","subject":{"object":{"rawValue":"series-8"}},"#
            + #""validationClaim":{"unknown":null},"#
            + #""warnings":[{"code":"org.voxelia.warning.partial-input","#
            + #""occurrenceCount":"3","schemaVersion":{"major":1,"minor":0},"#
            + #""severity":"informational"}]}}"#
        #expect(expected.utf8.count == 1_747)

        let emitted = try CanonicalProvenanceJSON.encodeRecordDocument(
            record: try operationRecord(),
            maximumOutputByteCount: 8_192
        )
        #expect(emitted == Array(expected.utf8))

        let identity = try ContentID.provenanceRecordIdentity(
            overCanonicalBytes: emitted
        )
        #expect(
            ContentID.hexDigestText(identity.digest)
                == "8f4d76c6c7d04a63f8605c118e5128d33a748349460e862def9d68acc257c0e9"
        )

        // The wire admits the fourth tuple and rejects the crossed scope.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = String(decoding: try encoder.encode(identity), as: UTF8.self)
        let decoded = try JSONDecoder().decode(ContentID.self, from: Data(encoded.utf8))
        #expect(decoded == identity)
        do {
            let crossed = encoded.replacingOccurrences(
                of: #""scope":"serialisedObject""#,
                with: #""scope":"sampleBytes""#
            )
            _ = try JSONDecoder().decode(ContentID.self, from: Data(crossed.utf8))
            #expect(Bool(false), "Expected a crossed tuple to be rejected.")
        } catch let error as ContentIdentityError {
            #expect(error == .unsupportedProjection)
        }
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-001] ceilings reject before and during emission")
    func ceilingsRejectBeforeAndDuringEmission() throws {
        // The count ceilings are validated before any byte is written:
        // an over-ceiling input sequence rejects as a count violation
        // even under a one-byte output ceiling.
        let role = try ProvenanceInputRole(rawValue: "input")
        let identity = DataIdentityReference.object(
            try #require(DataObjectID(rawValue: "series-7"))
        )
        var inputs = ContiguousArray<ProvenanceInput>()
        inputs.reserveCapacity(65_537)
        for occurrence in 1...65_537 {
            inputs.append(
                try ProvenanceInput(
                    role: role,
                    occurrence: UInt32(occurrence),
                    identity: identity,
                    parent: nil
                )
            )
        }
        let wide = try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-3")),
            kind: .transformed,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: "series-9"))),
            software: try software(),
            activity: try operationActivityOnly(),
            inputs: inputs,
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
        do {
            _ = try CanonicalProvenanceJSON.encodeRecordDocument(
                record: wide,
                maximumOutputByteCount: 1
            )
            #expect(Bool(false), "Expected the input ceiling to reject first.")
        } catch ProvenanceJSONEmissionError.inputCountLimitExceeded {}

        // The warning ceiling rejects likewise, keyed by distinct schema
        // versions under one code.
        let code = try ProvenanceWarningCode(
            rawValue: "org.voxelia.warning.partial-input"
        )
        var warnings = ContiguousArray<ProvenanceWarning>()
        warnings.reserveCapacity(65_537)
        for minor in 0...65_536 {
            warnings.append(
                try ProvenanceWarning(
                    code: code,
                    schemaVersion: ProvenanceWarningSchemaVersion(
                        major: 1,
                        minor: UInt32(minor)
                    ),
                    severity: .informational,
                    occurrenceCount: 1
                )
            )
        }
        let warned = try ProvenanceRecord(
            id: try #require(ProvenanceID(rawValue: "record-4")),
            kind: .source,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(try #require(DataObjectID(rawValue: "series-9"))),
            software: try software(),
            activity: .origin,
            inputs: [],
            warnings: warnings,
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
        do {
            _ = try CanonicalProvenanceJSON.encodeRecordDocument(
                record: warned,
                maximumOutputByteCount: 1
            )
            #expect(Bool(false), "Expected the warning ceiling to reject first.")
        } catch ProvenanceJSONEmissionError.warningCountLimitExceeded {}

        // The output byte ceiling is exact: one byte under the golden
        // length rejects, the exact length succeeds.
        do {
            _ = try CanonicalProvenanceJSON.encodeRecordDocument(
                record: try originRecord(),
                maximumOutputByteCount: 475
            )
            #expect(Bool(false), "Expected the byte ceiling to reject.")
        } catch ProvenanceJSONEmissionError.outputByteLimitExceeded {}
        let exact = try CanonicalProvenanceJSON.encodeRecordDocument(
            record: try originRecord(),
            maximumOutputByteCount: 476
        )
        #expect(exact.count == 476)

        requireSendable(ProvenanceJSONEmissionError.self)
    }

    private func operationActivityOnly() throws -> ProvenanceActivity {
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

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
