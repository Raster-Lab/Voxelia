// SPDX-License-Identifier: MIT

/// An error raised while validating a data identity aggregate.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// locators, digests or record content.
public enum DataIdentityError: Error, Sendable, Equatable {
    case missingClaims
    case duplicateSourceLocator
    case conflictingSourceClaim
    case unsupportedContentProjection
}

/// One immutable claim-bearing data identity per `ADR-0037` and
/// `ADR-0056`.
///
/// The aggregate binds the required object identity to an optional
/// top-level content claim, ordered source lineage and an optional
/// derivation recipe. Structural validity follows the accepted closed
/// state model — every content/source/derivation combination except the
/// object-only state — and implies no verification, trust, determinism
/// or cache assurance: those are runtime evidence bound to purpose,
/// snapshot and policy. Accepted source order is lineage record order
/// only. The stable coding and the source-count ceiling belong to the
/// future canonical data-identity projection decision.
public struct DataIdentity: Sendable, Hashable {
    public let objectID: DataObjectID
    public let contentID: ContentID?
    public let sourceIdentities: ContiguousArray<SourceIdentity>
    public let derivation: DerivationIdentity?

    /// Creates a validated aggregate.
    ///
    /// - Throws: ``DataIdentityError/missingClaims`` for the object-only
    ///   state, ``DataIdentityError/duplicateSourceLocator`` for an
    ///   exact repeated source record,
    ///   ``DataIdentityError/conflictingSourceClaim`` for a repeated
    ///   locator carrying a different content claim, or
    ///   ``DataIdentityError/unsupportedContentProjection`` when the
    ///   top-level claim carries the operation-parameters projection.
    public init(
        objectID: DataObjectID,
        contentID: ContentID?,
        sourceIdentities: ContiguousArray<SourceIdentity>,
        derivation: DerivationIdentity?
    ) throws {
        guard contentID != nil || !sourceIdentities.isEmpty || derivation != nil
        else {
            throw DataIdentityError.missingClaims
        }
        if let contentID,
            contentID.projection == ContentID.operationParametersProjection
        {
            throw DataIdentityError.unsupportedContentProjection
        }

        // One linear pass over the exact accepted UTF-8 locator keys; no
        // normalisation, deduplication or last-write-wins.
        var claims = [SourceLocatorKey: ContentID?]()
        claims.reserveCapacity(sourceIdentities.count)
        for source in sourceIdentities {
            let key = SourceLocatorKey(
                namespace: source.namespace,
                identifier: source.identifier,
                version: source.version
            )
            if let existing = claims[key] {
                if existing == source.contentID {
                    throw DataIdentityError.duplicateSourceLocator
                }
                throw DataIdentityError.conflictingSourceClaim
            }
            claims[key] = source.contentID
        }

        self.objectID = objectID
        self.contentID = contentID
        self.sourceIdentities = sourceIdentities
        self.derivation = derivation
    }

    private struct SourceLocatorKey: Hashable {
        let namespace: String
        let identifier: String
        let version: String?

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.namespace.utf8.elementsEqual(rhs.namespace.utf8)
                && lhs.identifier.utf8.elementsEqual(rhs.identifier.utf8)
                && exactOptionalEquals(lhs.version, rhs.version)
        }

        func hash(into hasher: inout Hasher) {
            Self.hashField(namespace, into: &hasher)
            Self.hashField(identifier, into: &hasher)
            if let version {
                hasher.combine(true)
                Self.hashField(version, into: &hasher)
            } else {
                hasher.combine(false)
            }
        }

        private static func exactOptionalEquals(
            _ lhs: String?,
            _ rhs: String?
        ) -> Bool {
            switch (lhs, rhs) {
            case (nil, nil):
                true
            case (let lhsValue?, let rhsValue?):
                lhsValue.utf8.elementsEqual(rhsValue.utf8)
            default:
                false
            }
        }

        private static func hashField(_ field: String, into hasher: inout Hasher) {
            hasher.combine(field.utf8.count)
            for byte in field.utf8 {
                hasher.combine(byte)
            }
        }
    }
}
