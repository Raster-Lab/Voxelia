// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("CanonicalDerivationIngress")
struct CanonicalDerivationIngressTests {
    private func parameterDigest() throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )
    }

    private func record(
        implementation: Bool = true,
        inputs: ContiguousArray<DerivationInput>? = nil
    ) throws -> DerivationIdentity {
        let builtInputs: ContiguousArray<DerivationInput>
        if let inputs {
            builtInputs = inputs
        } else {
            builtInputs = [
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "input"),
                    identity: .object(try #require(DataObjectID(rawValue: "series-6")))
                )
            ]
        }
        return try DerivationIdentity(
            operationID: try DerivationOperationToken(
                rawValue: "org.voxelia.op.window-level"
            ),
            operationVersion: try SemanticVersion(
                major: 1,
                minor: 0,
                patch: 0,
                prerelease: "rc1"
            ),
            implementation: implementation
                ? DerivationImplementationReference(
                    identifier: try DerivationOperationToken(
                        rawValue: "org.voxelia.impl.window-level.cpu"
                    ),
                    version: try SemanticVersion(
                        major: 2,
                        minor: 1,
                        patch: 0,
                        buildMetadata: "build7"
                    )
                ) : nil,
            inputs: builtInputs,
            parameterDigest: try parameterDigest(),
            declaresZeroInputGenerator: builtInputs.isEmpty
        )
    }

    private func decode(_ bytes: [UInt8]) throws -> DerivationIdentity {
        try CanonicalDerivationJSON.decodeRecordDocument(
            from: bytes,
            maximumInputByteCount: 16_384
        )
    }

    @Test("[Unit][CDMS-32.2][VOX-API-004] canonical documents round-trip exactly")
    func canonicalDocumentsRoundTripExactly() throws {
        // A full record, a zero-input generator and a record exercising
        // every identity-reference case decode back to equal records
        // with equal identities.
        let everyReference: ContiguousArray<DerivationInput> = [
            DerivationInput(
                role: try DerivationInputRole(rawValue: "object"),
                identity: .object(try #require(DataObjectID(rawValue: "series-6")))
            ),
            DerivationInput(
                role: try DerivationInputRole(rawValue: "content"),
                identity: .content(
                    try ContentID.sampleBytesIdentity(
                        overCanonicalPackedBytes: [1, 2]
                    )
                )
            ),
            DerivationInput(
                role: try DerivationInputRole(rawValue: "source"),
                identity: .source(
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.2",
                        version: "2",
                        contentID: nil
                    )
                )
            ),
            DerivationInput(
                role: try DerivationInputRole(rawValue: "recipe"),
                identity: .derivation(
                    try DerivationRecordID(
                        recordContentID: try ContentID.derivationRecordIdentity(
                            overCanonicalBytes: [1, 2, 3]
                        )
                    )
                )
            ),
        ]
        for fixture in [
            try record(),
            try record(implementation: false, inputs: []),
            try record(inputs: everyReference),
        ] {
            let bytes = try CanonicalDerivationJSON.encodeRecordDocument(
                record: fixture,
                maximumOutputByteCount: 16_384
            )
            let decoded = try decode(bytes)
            #expect(decoded == fixture)
            #expect(
                try ContentID.derivationRecordIdentity(
                    overCanonicalBytes:
                        try CanonicalDerivationJSON
                        .encodeRecordDocument(
                            record: decoded,
                            maximumOutputByteCount: 16_384
                        )
                )
                    == (try ContentID.derivationRecordIdentity(
                        overCanonicalBytes: bytes
                    ))
            )
        }

        requireSendable(DerivationJSONIngressError.self)
    }

    @Test("[Unit][VOX-ERR-001][VOX-SEC-001] ingress rejects aliases and hostile input")
    func ingressRejectsAliasesAndHostileInput() throws {
        let bytes = try CanonicalDerivationJSON.encodeRecordDocument(
            record: try record(),
            maximumOutputByteCount: 16_384
        )
        let text = String(decoding: bytes, as: UTF8.self)

        func expectRejection(
            _ document: String,
            _ expected: DerivationJSONIngressError
        ) {
            do {
                _ = try decode(Array(document.utf8))
                #expect(Bool(false), "Expected the document to be rejected.")
            } catch let error as DerivationJSONIngressError {
                #expect(error == expected)
            } catch {
                #expect(Bool(false), "Expected a typed ingress error.")
            }
        }

        // The input ceiling and the pre-parse nesting bomb.
        do {
            _ = try CanonicalDerivationJSON.decodeRecordDocument(
                from: bytes,
                maximumInputByteCount: UInt64(bytes.count - 1)
            )
            #expect(Bool(false), "Expected the input ceiling to reject.")
        } catch DerivationJSONIngressError.inputByteLimitExceeded {}
        expectRejection(String(repeating: "[", count: 64), .rawDepthLimitExceeded)

        // Malformed JSON, the wrong schema, wrong members and a foreign
        // parameter-digest tuple.
        expectRejection("{", .invalidDocument)
        expectRejection(
            text.replacingOccurrences(
                of: "org.voxelia.derivation-record",
                with: "org.voxelia.provenance-record"
            ),
            .invalidDocument
        )
        expectRejection(
            text.replacingOccurrences(
                of: #""implementation":"#,
                with: #""extra":null,"implementation":"#
            ),
            .invalidDocument
        )
        expectRejection(
            text.replacingOccurrences(
                of: "org.voxelia.operation-parameters",
                with: "org.voxelia.sample-bytes"
            ),
            .invalidDocument
        )

        // Canonical aliases fail the byte-equality gate.
        expectRejection(
            text.replacingOccurrences(
                of: #""operationID":"#,
                with: #""operationID": "#
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
            _ = try decode(Array("{\"patient-sentinel\":1}".utf8))
            #expect(Bool(false), "Expected a wrong envelope to be rejected.")
        } catch let error as DerivationJSONIngressError {
            #expect(error == .invalidDocument)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("patient-sentinel"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
