// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("DataIdentity")
struct DataIdentityTests {
    private func objectID() throws -> DataObjectID {
        try #require(DataObjectID(rawValue: "series-7"))
    }

    private func sampleClaim() throws -> ContentID {
        try ContentID.sampleBytesIdentity(overCanonicalPackedBytes: Array(0..<24))
    }

    private func source(
        _ identifier: String,
        version: String? = nil,
        contentID: ContentID? = nil
    ) throws -> SourceIdentity {
        try SourceIdentity(
            namespace: "dicom.sop-instance-uid",
            identifier: identifier,
            version: version,
            contentID: contentID
        )
    }

    private func derivation() throws -> DerivationIdentity {
        try DerivationIdentity(
            operationID: try DerivationOperationToken(
                rawValue: "org.voxelia.op.window-level"
            ),
            operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
            implementation: nil,
            inputs: [
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "input"),
                    identity: .object(try #require(DataObjectID(rawValue: "series-6")))
                )
            ],
            parameterDigest: try ContentID.operationParametersIdentity(
                overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                    payload: try MetadataCollection(entries: []),
                    maximumOutputByteCount: 4_096
                )
            ),
            declaresZeroInputGenerator: false
        )
    }

    @Test("[Unit][VOX-DAT-014][VOX-RGN-007] the state model rejects only object-only")
    func stateModelRejectsOnlyObjectOnly() async throws {
        let contentStates: [ContentID?] = [nil, try sampleClaim()]
        let sourceStates: [ContiguousArray<SourceIdentity>] = [
            [], [try source("1.2.840.113619.2.5.1762")],
        ]
        let derivationStates: [DerivationIdentity?] = [nil, try derivation()]

        for content in contentStates {
            for sources in sourceStates {
                for derivationState in derivationStates {
                    let isObjectOnly =
                        content == nil && sources.isEmpty && derivationState == nil
                    do {
                        let identity = try DataIdentity(
                            objectID: try objectID(),
                            contentID: content,
                            sourceIdentities: sources,
                            derivation: derivationState
                        )
                        #expect(!isObjectOnly, "Expected the object-only state to be rejected.")
                        #expect(identity.objectID == (try objectID()))
                    } catch DataIdentityError.missingClaims {
                        #expect(isObjectOnly, "Expected only the object-only state to be rejected.")
                    }
                }
            }
        }

        // The operation-parameters projection never names an object's own
        // content, while distinct source and top-level scopes are
        // admitted without comparison.
        do {
            _ = try DataIdentity(
                objectID: try objectID(),
                contentID: try ContentID.operationParametersIdentity(
                    overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                        payload: try MetadataCollection(entries: []),
                        maximumOutputByteCount: 4_096
                    )
                ),
                sourceIdentities: [],
                derivation: nil
            )
            #expect(Bool(false), "Expected the parameters projection to be rejected.")
        } catch DataIdentityError.unsupportedContentProjection {}
        let recordClaim = try ContentID.completeMetadataRecordIdentity(
            overCanonicalBytes: [1, 2, 3]
        )
        let mixed = try DataIdentity(
            objectID: try objectID(),
            contentID: try sampleClaim(),
            sourceIdentities: [
                try source("1.2.840.113619.2.5.1762", contentID: recordClaim)
            ],
            derivation: nil
        )
        #expect(mixed.contentID?.scope == .sampleBytes)
        #expect(mixed.sourceIdentities[0].contentID?.scope == .serialisedObject)

        requireSendable(DataIdentity.self)
        requireSendable(DataIdentityError.self)
    }

    @Test("[Unit][VOX-DAT-014][VOX-ERR-001] source rules reject repeats without normalisation")
    func sourceRulesRejectRepeatsWithoutNormalisation() async throws {
        // An exact repeated record is redundant.
        do {
            _ = try DataIdentity(
                objectID: try objectID(),
                contentID: nil,
                sourceIdentities: [try source("x"), try source("x")],
                derivation: nil
            )
            #expect(Bool(false), "Expected an exact repeat to be rejected.")
        } catch DataIdentityError.duplicateSourceLocator {}

        // The same locator carrying two different content claims is a
        // conflict, never last-write-wins.
        do {
            _ = try DataIdentity(
                objectID: try objectID(),
                contentID: nil,
                sourceIdentities: [
                    try source("x"),
                    try source("x", contentID: try sampleClaim()),
                ],
                derivation: nil
            )
            #expect(Bool(false), "Expected a conflicting claim to be rejected.")
        } catch DataIdentityError.conflictingSourceClaim {}

        // Byte-distinct canonically equivalent locators are distinct: no
        // normalisation happens before comparison.
        _ = try DataIdentity(
            objectID: try objectID(),
            contentID: nil,
            sourceIdentities: [
                try source("caf\u{00E9}"), try source("cafe\u{0301}"),
            ],
            derivation: nil
        )

        // An absent version is distinct from every present version, and
        // accepted source order participates in identity.
        _ = try DataIdentity(
            objectID: try objectID(),
            contentID: nil,
            sourceIdentities: [try source("x"), try source("x", version: "1")],
            derivation: nil
        )
        let forward = try DataIdentity(
            objectID: try objectID(),
            contentID: nil,
            sourceIdentities: [try source("x"), try source("y")],
            derivation: nil
        )
        let reversed = try DataIdentity(
            objectID: try objectID(),
            contentID: nil,
            sourceIdentities: [try source("y"), try source("x")],
            derivation: nil
        )
        #expect(forward != reversed)
        #expect(Set([forward, reversed]).count == 2)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
