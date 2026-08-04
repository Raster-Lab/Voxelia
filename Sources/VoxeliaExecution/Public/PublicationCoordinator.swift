// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by result publication.
///
/// Cases deliberately carry no payload; graph, storage and identity
/// failures surface as their own audited typed errors.
public enum PublicationError: Error, Sendable, Equatable {
    case duplicateObjectIdentifier
    case duplicateProvenanceIdentifier
    case publishedRecordLimitExceeded
    case contentClaimMismatch
}

/// The evidence returned by one successful publication.
///
/// A receipt reports what happened — resulting graph authority,
/// resolved ancestry depth, whether the content claim was verified
/// against actually read bytes and whether the cache alias was
/// admitted. It is evidence, not authority.
public struct PublicationReceipt: Sendable, Hashable {
    public let authority: ProvenanceGraphAuthority
    public let ancestryDepth: UInt64
    public let contentClaimVerified: Bool
    public let cachedAlias: Bool

    init(
        authority: ProvenanceGraphAuthority,
        ancestryDepth: UInt64,
        contentClaimVerified: Bool,
        cachedAlias: Bool
    ) {
        self.authority = authority
        self.ancestryDepth = ancestryDepth
        self.contentClaimVerified = contentClaimVerified
        self.cachedAlias = cachedAlias
    }
}

/// The actor-isolated result publication coordinator selected by
/// `ADR-0038` and implemented per `ADR-0067` — Execution's single
/// linearisation point.
///
/// Publication verifies a sample-bytes content claim against actually
/// read bytes under the read budget, then — in one non-suspending
/// actor section — rejects identifier reuse even for equal values,
/// enforces the append-only registry ceiling, admits the record's
/// ancestry closure under the accepted graph admission and registers
/// the bundle. A configured content-tier cache then receives the
/// verified bytes as a best-effort alias whose failure never unwinds a
/// completed publication. Retention and deletion governance remain
/// deferred: nothing published is ever evicted or replaced.
public actor PublicationCoordinator {
    /// The inclusive published-object ceiling.
    public let maximumPublishedObjectCount: UInt64
    /// The graph admission limits applied to every publication.
    public let graphLimits: ProvenanceGraphLimits

    private let readCoordinator: StorageReadCoordinator
    private let resultCache: ContentResultCache?
    private var publishedImages: [DataObjectID: ImageData] = [:]
    private var publishedProvenance: [ProvenanceID: ProvenanceRecord] = [:]

    /// Creates a coordinator with explicit budgets and boundaries;
    /// there are no permissive defaults.
    public init(
        maximumPublishedObjectCount: UInt64,
        graphLimits: ProvenanceGraphLimits,
        readCoordinator: StorageReadCoordinator,
        resultCache: ContentResultCache?
    ) {
        self.maximumPublishedObjectCount = maximumPublishedObjectCount
        self.graphLimits = graphLimits
        self.readCoordinator = readCoordinator
        self.resultCache = resultCache
    }

    /// The currently published object count.
    public var publishedObjectCount: Int {
        publishedImages.count
    }

    /// Returns the published bundle for one object identifier, or
    /// `nil`.
    public func publishedImage(for id: DataObjectID) -> ImageData? {
        publishedImages[id]
    }

    /// Returns the published provenance record for one identifier, or
    /// `nil`.
    public func publishedProvenanceRecord(for id: ProvenanceID) -> ProvenanceRecord? {
        publishedProvenance[id]
    }

    /// Publishes one validated bundle atomically under the explicit
    /// admission mode policy.
    ///
    /// - Throws: ``PublicationError``, or the audited typed errors of
    ///   the storage read and graph admission contracts.
    public func publish(
        _ image: ImageData,
        mode: ProvenanceGraphAdmissionMode
    ) async throws -> PublicationReceipt {
        // Phase one, before the critical section: verify a sample-bytes
        // content claim against actually read bytes. This suspends, so
        // it must not touch or trust registry state.
        var verifiedBytes: [UInt8]?
        var verifiedClaim: ContentID?
        if let claim = image.identity.contentID, claim.scope == .sampleBytes {
            let extents = image.descriptor.shape.extents
            let fullRegion = try ImageRegion(
                lowerBounds: ContiguousArray(repeating: 0, count: extents.count),
                upperBounds: extents
            )
            let read = try await readCoordinator.read(
                from: image.storage,
                region: fullRegion
            )
            let bytes = read.result.bytes
            try await readCoordinator.release(read.retention)
            guard try claim.matchesDigest(ofCanonicalBytes: bytes) else {
                throw PublicationError.contentClaimMismatch
            }
            verifiedBytes = bytes
            verifiedClaim = claim
        }

        // Phase two, the non-suspending critical section: identifier
        // reuse, the ceiling, the ancestry closure, graph admission and
        // the registry mutation linearise together.
        let graph = try admitAndRegister(image, mode: mode)

        // Phase three, after linearisation: the best-effort authorised
        // cache alias. A failed alias never unwinds a completed
        // publication; the receipt reports it honestly.
        var cachedAlias = false
        if let resultCache, let verifiedBytes, let verifiedClaim {
            do {
                try await resultCache.admit(bytes: verifiedBytes, as: verifiedClaim)
                cachedAlias = true
            } catch {
                cachedAlias = false
            }
        }

        return PublicationReceipt(
            authority: graph.authority,
            ancestryDepth: graph.maximumResolvedAncestryDepth,
            contentClaimVerified: verifiedClaim != nil,
            cachedAlias: cachedAlias
        )
    }

    private func admitAndRegister(
        _ image: ImageData,
        mode: ProvenanceGraphAdmissionMode
    ) throws -> ProvenanceGraph {
        guard publishedImages[image.identity.objectID] == nil else {
            throw PublicationError.duplicateObjectIdentifier
        }
        guard publishedProvenance[image.provenance.id] == nil else {
            throw PublicationError.duplicateProvenanceIdentifier
        }
        guard
            UInt64(publishedImages.count) < maximumPublishedObjectCount
        else {
            throw PublicationError.publishedRecordLimitExceeded
        }

        // The ancestry closure of the new record over the published
        // registry, walked through both parent-reference cases; an
        // unpublished local parent stays absent so admission reports it
        // as unresolved.
        var closure = ContiguousArray<ProvenanceRecord>()
        var visited = Set<ProvenanceID>()
        closure.append(image.provenance)
        visited.insert(image.provenance.id)
        var frontier = [image.provenance]
        while let record = frontier.popLast() {
            for input in record.inputs {
                let parentIdentifier: ProvenanceID
                switch input.parent {
                case nil:
                    continue
                case .graphNode(let identifier):
                    parentIdentifier = identifier
                case .externalRecord(let reference):
                    parentIdentifier = reference.id
                }
                guard !visited.contains(parentIdentifier),
                    let parentRecord = publishedProvenance[parentIdentifier]
                else {
                    continue
                }
                visited.insert(parentIdentifier)
                closure.append(parentRecord)
                frontier.append(parentRecord)
            }
        }

        let graph = try ProvenanceGraph.admitGraph(
            records: closure,
            roots: [image.provenance.id],
            limits: graphLimits,
            mode: mode
        )

        publishedImages[image.identity.objectID] = image
        publishedProvenance[image.provenance.id] = image.provenance
        return graph
    }
}
