// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by canonical record archival admission.
///
/// Cases deliberately carry no payload; emission and persistence
/// failures surface as their own audited typed errors.
public enum CanonicalArchivalError: Error, Sendable, Equatable {
    case missingDerivationName
    case unexpectedDerivationName
}

/// The evidence returned by one successful archival.
///
/// A receipt reports the computed registered record identities;
/// loading a document back through the store requires them. It is
/// evidence, not authority.
public struct ArchivedRecordReceipt: Sendable, Hashable {
    public let provenanceIdentity: ContentID
    public let derivationIdentity: ContentID?

    init(provenanceIdentity: ContentID, derivationIdentity: ContentID?) {
        self.provenanceIdentity = provenanceIdentity
        self.derivationIdentity = derivationIdentity
    }
}

/// The stateless canonical record archival boundary per `ADR-0095`.
///
/// Archival emits a published bundle's provenance record under
/// `VCPJ-1` — and its derivation record under `VCDJ-1` when the bundle
/// carries one — computes each registered record identity and persists
/// each document through the accepted store, inheriting its
/// verify-before-persist, idempotency and never-overwrite discipline.
/// The caller owns both names per the `ADR-0036` digest-sensitivity
/// rule, and name presence must match record presence exactly; the
/// archival interprets no document and authors no history.
public enum CanonicalRecordArchival {
    /// Archives one bundle's canonical records.
    ///
    /// - Throws: ``CanonicalArchivalError``, or the audited typed
    ///   errors of the canonical emission and document store
    ///   contracts.
    public static func archive(
        _ image: ImageData,
        provenanceName: CanonicalDocumentName,
        derivationName: CanonicalDocumentName?,
        store: CanonicalDocumentStore,
        maximumDocumentByteCount: UInt64
    ) async throws -> ArchivedRecordReceipt {
        // Name presence must match record presence exactly — a silent
        // skip in either direction would misreport what was archived.
        switch (image.identity.derivation, derivationName) {
        case (.some, nil):
            throw CanonicalArchivalError.missingDerivationName
        case (nil, .some):
            throw CanonicalArchivalError.unexpectedDerivationName
        default:
            break
        }

        let provenanceBytes = try CanonicalProvenanceJSON.encodeRecordDocument(
            record: image.provenance,
            maximumOutputByteCount: maximumDocumentByteCount
        )
        let provenanceIdentity = try ContentID.provenanceRecordIdentity(
            overCanonicalBytes: provenanceBytes
        )
        try await store.store(
            canonicalBytes: provenanceBytes,
            identity: provenanceIdentity,
            name: provenanceName
        )

        var derivationIdentity: ContentID?
        if let derivation = image.identity.derivation, let derivationName {
            let derivationBytes = try CanonicalDerivationJSON.encodeRecordDocument(
                record: derivation,
                maximumOutputByteCount: maximumDocumentByteCount
            )
            let identity = try ContentID.derivationRecordIdentity(
                overCanonicalBytes: derivationBytes
            )
            try await store.store(
                canonicalBytes: derivationBytes,
                identity: identity,
                name: derivationName
            )
            derivationIdentity = identity
        }

        return ArchivedRecordReceipt(
            provenanceIdentity: provenanceIdentity,
            derivationIdentity: derivationIdentity
        )
    }

    /// Archives one `VCRM-1` manifest over archived record identities
    /// per `ADR-0101`.
    ///
    /// Only the caller knows which records form one history; the
    /// emitter's typed surface governs the set, and signing remains
    /// host-side per the `ADR-0078` verify-only rule.
    ///
    /// - Returns: The registered manifest identity.
    /// - Throws: The audited typed errors of the manifest emission and
    ///   document store contracts.
    public static func archiveManifest(
        over records: [ContentID],
        name: CanonicalDocumentName,
        store: CanonicalDocumentStore,
        maximumDocumentByteCount: UInt64
    ) async throws -> ContentID {
        let manifestBytes = try CanonicalManifest.encodeManifestDocument(
            records: records,
            maximumOutputByteCount: maximumDocumentByteCount
        )
        let manifestIdentity = try ContentID.recordManifestIdentity(
            overCanonicalBytes: manifestBytes
        )
        try await store.store(
            canonicalBytes: manifestBytes,
            identity: manifestIdentity,
            name: name
        )
        return manifestIdentity
    }
}
