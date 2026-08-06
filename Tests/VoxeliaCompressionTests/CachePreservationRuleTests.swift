// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaCompression

/// `ADR-0270` (`VOX-CMP-012`): generating a toolkit-native cache must never detach
/// the original DICOM instances.
@Suite("CachePreservationRule")
struct CachePreservationRuleTests {
    private func sourceIdentity(_ suffix: String) throws -> SourceIdentity {
        try SourceIdentity(
            namespace: "dicom.sop-instance-uid",
            identifier: "1.2.840.113619.\(suffix)",
            version: nil,
            contentID: nil
        )
    }

    private func derivation(inputObject: String) throws -> DerivationIdentity {
        try DerivationIdentity(
            operationID: try DerivationOperationToken(rawValue: "voxelia.cache.jp3d"),
            operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
            implementation: nil,
            inputs: [
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "source-volume"),
                    identity: .object(try #require(DataObjectID(rawValue: inputObject)))
                )
            ],
            // The parameter digest needs the operation-parameters projection; a
            // sample-bytes identity is refused with unsupportedParameterProjection,
            // which is the accepted model keeping claim kinds distinct.
            parameterDigest: try ContentID.operationParametersIdentity(
                overCanonicalBytes: [1, 2, 3]
            ),
            declaresZeroInputGenerator: false
        )
    }

    private func identity(
        objectID: String,
        sources: [String],
        derivationInput: String?
    ) throws -> DataIdentity {
        try DataIdentity(
            objectID: try #require(DataObjectID(rawValue: objectID)),
            contentID: nil,
            sourceIdentities: ContiguousArray(
                try sources.map { try sourceIdentity($0) }
            ),
            derivation: try derivationInput.map { try derivation(inputObject: $0) }
        )
    }

    /// The original volume, carrying three instance identities.
    private func original() throws -> DataIdentity {
        try identity(
            objectID: "volume",
            sources: ["1", "2", "3"],
            derivationInput: nil
        )
    }

    // MARK: - The admitted shape

    @Test("[Unit][VOX-CMP-012] a derived cache retaining every source identity is admitted")
    func derivedCacheRetainingSourcesIsAdmitted() throws {
        let cache = try identity(
            objectID: "volume.cache",
            sources: ["1", "2", "3"],
            derivationInput: "volume"
        )
        try CachePreservationRule.admit(cache: cache, generatedFrom: try original())
    }

    @Test("[Unit][VOX-CMP-012] a cache spanning more originals is admitted")
    func cacheSpanningMoreOriginalsIsAdmitted() throws {
        // A superset is legitimate: one cache may cover several imported series.
        let cache = try identity(
            objectID: "volume.cache",
            sources: ["1", "2", "3", "4", "5"],
            derivationInput: "volume"
        )
        try CachePreservationRule.admit(cache: cache, generatedFrom: try original())
    }

    // MARK: - The detachment the identity model would otherwise allow

    @Test("[Unit][VOX-CMP-012][VOX-SEC-001] a cache with no source identities is refused")
    func cacheWithoutSourceIdentitiesIsRefused() throws {
        // The case this rule exists for. `DataIdentity`'s admission is an OR, so an
        // identity with a derivation and no source identities is perfectly legal --
        // and it is exactly the detachment VOX-CMP-012 forbids. The identity below
        // constructs successfully; only this rule refuses it.
        let detached = try identity(
            objectID: "volume.cache",
            sources: [],
            derivationInput: "volume"
        )
        // Constructing it succeeded, which is the point.
        #expect(detached.sourceIdentities.isEmpty)
        #expect(detached.derivation != nil)

        #expect(throws: CachePreservationError.originalSourceIdentitiesAbsent) {
            try CachePreservationRule.admit(
                cache: detached,
                generatedFrom: try original()
            )
        }
    }

    @Test("[Unit][VOX-CMP-012] a cache dropping some source identities is refused")
    func cacheDroppingSomeSourcesIsRefused() throws {
        // A subset is the subtler detachment: the cache looks properly attributed
        // until you notice one instance is unaccounted for.
        let partial = try identity(
            objectID: "volume.cache",
            sources: ["1", "2"],
            derivationInput: "volume"
        )
        #expect(throws: CachePreservationError.originalSourceIdentitiesIncomplete) {
            try CachePreservationRule.admit(
                cache: partial,
                generatedFrom: try original()
            )
        }
    }

    @Test("[Unit][VOX-CMP-012][VOX-SEC-001] a cache claiming the original's identifier is refused")
    func cacheClaimingOriginalIdentifierIsRefused() throws {
        // An object published under its source's own name replaces it in the
        // registry. That is the deletion this row exists to prevent, arriving as an
        // update rather than as a delete.
        let replacing = try identity(
            objectID: "volume",
            sources: ["1", "2", "3"],
            derivationInput: "volume"
        )
        #expect(throws: CachePreservationError.cacheReplacesOriginal) {
            try CachePreservationRule.admit(
                cache: replacing,
                generatedFrom: try original()
            )
        }
    }

    @Test("[Unit][VOX-CMP-012] a cache declaring no derivation is refused")
    func cacheWithoutDerivationIsRefused() throws {
        // Source identities alone say which instances it relates to but not that it
        // was generated from them, so what produced the cache is unrecoverable.
        let undeclared = try identity(
            objectID: "volume.cache",
            sources: ["1", "2", "3"],
            derivationInput: nil
        )
        #expect(throws: CachePreservationError.derivationAbsent) {
            try CachePreservationRule.admit(
                cache: undeclared,
                generatedFrom: try original()
            )
        }
    }

    @Test("[Unit][VOX-CMP-012] the original is unchanged by the admission")
    func originalIsUnchangedByAdmission() throws {
        // The rule inspects and never mutates: preservation that altered the thing
        // being preserved would be self-defeating.
        let before = try original()
        let cache = try identity(
            objectID: "volume.cache",
            sources: ["1", "2", "3"],
            derivationInput: "volume"
        )
        try CachePreservationRule.admit(cache: cache, generatedFrom: before)
        #expect(before == (try original()))
        #expect(before.sourceIdentities.count == 3)
        #expect(before.derivation == nil)
    }
}
