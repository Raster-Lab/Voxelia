// SPDX-License-Identifier: MIT

/// An error raised while validating a provenance graph admission.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// identifiers, subjects, digests or record content.
public enum ProvenanceGraphError: Error, Sendable, Equatable {
    case invalidLimits
    case recordCountLimitExceeded
    case edgeCountLimitExceeded
    case ancestryDepthLimitExceeded
    case duplicateRecordIdentifier
    case emptyRootSet
    case duplicateRootIdentifier
    case unknownRootIdentifier
    case selfReference
    case unresolvedParent
    case parentSubjectMismatch
    case unreachableRecord
    case cyclicAncestry
    case unresolvedExternalReference
    case unresolvedExternalReferenceLimitExceeded
    case conflictingExternalClaim
    case externalClaimMismatch
    case externalResolutionLimitExceeded
    case cancelled
}

/// The explicit admission mode policy selected by `ADR-0038`.
///
/// The mode is policy, not the resulting resolution state: a
/// compact-mode admission that retains nothing is classified complete.
public enum ProvenanceGraphAdmissionMode: Sendable, Hashable {
    case complete
    case compact
}

/// The resulting resolution authority of one admitted snapshot.
public enum ProvenanceGraphAuthority: Sendable, Hashable {
    /// The resolved graph is structurally acyclic under the exact
    /// admitted snapshot and limits; scientific and authenticity
    /// assurance remain separate.
    case complete
    /// Only the resolved subgraph is known acyclic; the complete
    /// ancestry must not be described as verified or cycle-free.
    case compact
}

/// The explicit inclusive limits profile for one graph admission.
///
/// Every ceiling is mandatory; there are no permissive defaults, and a
/// caller cannot request an unlimited admission. Zero is permitted only
/// for the unresolved-external-reference cap, where it means none may
/// be admitted.
public struct ProvenanceGraphLimits: Sendable, Hashable {
    public let maximumRecordCount: UInt64
    public let maximumParentEdgeCount: UInt64
    public let maximumAncestryDepth: UInt64
    public let maximumUnresolvedExternalReferenceCount: UInt64
    public let maximumExternalResolutionByteCount: UInt64

    /// Creates a validated limits profile.
    ///
    /// - Throws: ``ProvenanceGraphError/invalidLimits`` when a
    ///   mandatory nonzero ceiling is zero.
    public init(
        maximumRecordCount: UInt64,
        maximumParentEdgeCount: UInt64,
        maximumAncestryDepth: UInt64,
        maximumUnresolvedExternalReferenceCount: UInt64,
        maximumExternalResolutionByteCount: UInt64
    ) throws {
        guard
            maximumRecordCount >= 1, maximumParentEdgeCount >= 1,
            maximumAncestryDepth >= 1, maximumExternalResolutionByteCount >= 1
        else {
            throw ProvenanceGraphError.invalidLimits
        }
        self.maximumRecordCount = maximumRecordCount
        self.maximumParentEdgeCount = maximumParentEdgeCount
        self.maximumAncestryDepth = maximumAncestryDepth
        self.maximumUnresolvedExternalReferenceCount =
            maximumUnresolvedExternalReferenceCount
        self.maximumExternalResolutionByteCount = maximumExternalResolutionByteCount
    }
}

/// One immutable admitted provenance graph snapshot per `ADR-0038`,
/// `ADR-0059` and `ADR-0062`.
///
/// Admission proves structural acyclicity of the resolved subgraph
/// under the exact admitted snapshot and limits only: scientific
/// validity, authenticity and cache suitability remain separate runtime
/// assurance. An unresolved compact parent is resolved only through a
/// new transaction whose candidate table supplies the formerly external
/// record, where the record-content claim and the parent-subject rule
/// are both rechecked; a failed resolution leaves this snapshot
/// unchanged by value semantics.
public struct ProvenanceGraph: Sendable {
    /// The declared root identifiers in accepted order.
    public let roots: ContiguousArray<ProvenanceID>
    /// The maximum resolved ancestry depth; evidence computed during
    /// admission without recursion.
    public let maximumResolvedAncestryDepth: UInt64
    /// The resulting resolution authority: complete exactly when no
    /// unresolved external parent was retained.
    public let authority: ProvenanceGraphAuthority
    /// The retained unresolved external parent occurrences, counted per
    /// input edge; evidence for the compact classification.
    public let unresolvedExternalReferenceOccurrenceCount: UInt64

    private let table: [ProvenanceID: ProvenanceRecord]

    /// The admitted record count.
    public var recordCount: Int {
        table.count
    }

    /// Returns the admitted record for one identifier, or `nil`.
    public func record(for id: ProvenanceID) -> ProvenanceRecord? {
        table[id]
    }

    private init(
        roots: ContiguousArray<ProvenanceID>,
        maximumResolvedAncestryDepth: UInt64,
        authority: ProvenanceGraphAuthority,
        unresolvedExternalReferenceOccurrenceCount: UInt64,
        table: [ProvenanceID: ProvenanceRecord]
    ) {
        self.roots = roots
        self.maximumResolvedAncestryDepth = maximumResolvedAncestryDepth
        self.authority = authority
        self.unresolvedExternalReferenceOccurrenceCount =
            unresolvedExternalReferenceOccurrenceCount
        self.table = table
    }

    /// Admits one complete-mode graph: every parent, local or
    /// external, must resolve within the candidate table.
    public static func admitCompleteGraph(
        records: ContiguousArray<ProvenanceRecord>,
        roots: ContiguousArray<ProvenanceID>,
        limits: ProvenanceGraphLimits
    ) throws -> ProvenanceGraph {
        try admitGraph(records: records, roots: roots, limits: limits, mode: .complete)
    }

    /// Admits one graph transactionally under the explicit mode policy:
    /// the candidate table must equal the resolved ancestry closure of
    /// the declared roots, every local parent must resolve, every
    /// available external parent is verified against its record-content
    /// claim before resolving, compact mode retains unresolved external
    /// parents under the per-occurrence cap with exact repeated-claim
    /// consistency, and the resolved edges must be acyclic within the
    /// depth ceiling. Failure publishes nothing.
    public static func admitGraph(
        records: ContiguousArray<ProvenanceRecord>,
        roots: ContiguousArray<ProvenanceID>,
        limits: ProvenanceGraphLimits,
        mode: ProvenanceGraphAdmissionMode
    ) throws -> ProvenanceGraph {
        guard UInt64(records.count) <= limits.maximumRecordCount else {
            throw ProvenanceGraphError.recordCountLimitExceeded
        }

        var table = [ProvenanceID: ProvenanceRecord]()
        table.reserveCapacity(records.count)
        for record in records {
            guard table.updateValue(record, forKey: record.id) == nil else {
                throw ProvenanceGraphError.duplicateRecordIdentifier
            }
        }

        guard !roots.isEmpty else {
            throw ProvenanceGraphError.emptyRootSet
        }
        var rootSet = Set<ProvenanceID>()
        rootSet.reserveCapacity(roots.count)
        for root in roots {
            guard rootSet.insert(root).inserted else {
                throw ProvenanceGraphError.duplicateRootIdentifier
            }
            guard table[root] != nil else {
                throw ProvenanceGraphError.unknownRootIdentifier
            }
        }

        // One pass over every input edge: the edge ceiling, self-edge
        // rejection regardless of tag, local resolution, verified
        // available-external resolution, compact retention under the
        // occurrence cap with exact repeated-claim consistency, and the
        // parent-subject rule for every resolved parent.
        var parentIdentifiers = [ProvenanceID: ContiguousArray<ProvenanceID>]()
        parentIdentifiers.reserveCapacity(table.count)
        var edgeCount: UInt64 = 0
        var verifiedClaims = Set<VerifiedClaimKey>()
        var unresolvedClaims = [ProvenanceID: UnresolvedClaim]()
        var unresolvedOccurrenceCount: UInt64 = 0
        for record in records {
            var parents = ContiguousArray<ProvenanceID>()
            for input in record.inputs {
                guard let parent = input.parent else {
                    continue
                }
                let (candidate, overflow) = edgeCount.addingReportingOverflow(1)
                guard !overflow, candidate <= limits.maximumParentEdgeCount else {
                    throw ProvenanceGraphError.edgeCountLimitExceeded
                }
                edgeCount = candidate
                switch parent {
                case .graphNode(let parentIdentifier):
                    guard parentIdentifier != record.id else {
                        throw ProvenanceGraphError.selfReference
                    }
                    guard let parentRecord = table[parentIdentifier] else {
                        throw ProvenanceGraphError.unresolvedParent
                    }
                    guard parentRecord.subject == input.identity else {
                        throw ProvenanceGraphError.parentSubjectMismatch
                    }
                    parents.append(parentIdentifier)
                case .externalRecord(let reference):
                    guard reference.id != record.id else {
                        throw ProvenanceGraphError.selfReference
                    }
                    if let parentRecord = table[reference.id] {
                        let key = VerifiedClaimKey(
                            id: reference.id,
                            recordContentID: reference.recordContentID
                        )
                        if !verifiedClaims.contains(key) {
                            try verifyAvailableClaim(
                                reference: reference,
                                parentRecord: parentRecord,
                                limits: limits
                            )
                            verifiedClaims.insert(key)
                        }
                        guard parentRecord.subject == input.identity else {
                            throw ProvenanceGraphError.parentSubjectMismatch
                        }
                        parents.append(reference.id)
                    } else {
                        guard mode == .compact else {
                            throw ProvenanceGraphError.unresolvedExternalReference
                        }
                        let (occurrences, occurrenceOverflow) =
                            unresolvedOccurrenceCount.addingReportingOverflow(1)
                        guard !occurrenceOverflow,
                            occurrences
                                <= limits.maximumUnresolvedExternalReferenceCount
                        else {
                            throw ProvenanceGraphError
                                .unresolvedExternalReferenceLimitExceeded
                        }
                        unresolvedOccurrenceCount = occurrences
                        let claim = UnresolvedClaim(
                            recordContentID: reference.recordContentID,
                            expectedSubject: input.identity
                        )
                        if let existing = unresolvedClaims[reference.id] {
                            guard existing == claim else {
                                throw ProvenanceGraphError.conflictingExternalClaim
                            }
                        } else {
                            unresolvedClaims[reference.id] = claim
                        }
                    }
                }
            }
            parentIdentifiers[record.id] = parents
        }

        // The table must equal the exact resolved closure of the roots:
        // iterative visit-once traversal, then a coverage check.
        var reachable = Set<ProvenanceID>()
        reachable.reserveCapacity(table.count)
        var frontier = ContiguousArray(roots)
        reachable.formUnion(roots)
        while let identifier = frontier.popLast() {
            for parent in parentIdentifiers[identifier] ?? [] {
                if reachable.insert(parent).inserted {
                    frontier.append(parent)
                }
            }
        }
        guard reachable.count == table.count else {
            throw ProvenanceGraphError.unreachableRecord
        }

        // Visit-once iterative cycle detection and depth computation over
        // the resolved edges: parent-free records start at depth one, and
        // each edge propagates exactly once, so diamonds are never
        // re-traversed.
        var childIdentifiers = [ProvenanceID: ContiguousArray<ProvenanceID>]()
        childIdentifiers.reserveCapacity(table.count)
        var pendingParentEdgeCount = [ProvenanceID: Int]()
        pendingParentEdgeCount.reserveCapacity(table.count)
        for (child, parents) in parentIdentifiers {
            pendingParentEdgeCount[child] = parents.count
            for parent in parents {
                childIdentifiers[parent, default: []].append(child)
            }
        }
        var depths = [ProvenanceID: UInt64]()
        depths.reserveCapacity(table.count)
        var ready = ContiguousArray<ProvenanceID>()
        for (identifier, pending) in pendingParentEdgeCount where pending == 0 {
            depths[identifier] = 1
            ready.append(identifier)
        }
        var processedCount = 0
        var maximumDepth: UInt64 = 0
        while let identifier = ready.popLast() {
            processedCount += 1
            let depth = depths[identifier] ?? 1
            guard depth <= limits.maximumAncestryDepth else {
                throw ProvenanceGraphError.ancestryDepthLimitExceeded
            }
            maximumDepth = max(maximumDepth, depth)
            for child in childIdentifiers[identifier] ?? [] {
                let childDepth = max(depths[child] ?? 1, depth + 1)
                depths[child] = childDepth
                let pending = (pendingParentEdgeCount[child] ?? 0) - 1
                pendingParentEdgeCount[child] = pending
                if pending == 0 {
                    ready.append(child)
                }
            }
        }
        guard processedCount == table.count else {
            throw ProvenanceGraphError.cyclicAncestry
        }

        return ProvenanceGraph(
            roots: roots,
            maximumResolvedAncestryDepth: maximumDepth,
            authority: unresolvedOccurrenceCount == 0 ? .complete : .compact,
            unresolvedExternalReferenceOccurrenceCount: unresolvedOccurrenceCount,
            table: table
        )
    }

    /// Verifies one available external record-content claim: the
    /// candidate parent's canonical bytes are re-emitted under the
    /// resolution byte ceiling and compared timing-safe.
    private static func verifyAvailableClaim(
        reference: ExternalProvenanceRecordReference,
        parentRecord: ProvenanceRecord,
        limits: ProvenanceGraphLimits
    ) throws {
        let canonicalBytes: [UInt8]
        do {
            canonicalBytes = try CanonicalProvenanceJSON.encodeRecordDocument(
                record: parentRecord,
                maximumOutputByteCount: limits.maximumExternalResolutionByteCount
            )
        } catch ProvenanceJSONEmissionError.cancelled {
            throw ProvenanceGraphError.cancelled
        } catch {
            throw ProvenanceGraphError.externalResolutionLimitExceeded
        }
        let matches: Bool
        do {
            matches = try reference.recordContentID.matchesDigest(
                ofCanonicalBytes: canonicalBytes
            )
        } catch ContentIdentityError.cancelled {
            throw ProvenanceGraphError.cancelled
        } catch {
            throw ProvenanceGraphError.externalClaimMismatch
        }
        guard matches else {
            throw ProvenanceGraphError.externalClaimMismatch
        }
    }

    private struct VerifiedClaimKey: Hashable {
        let id: ProvenanceID
        let recordContentID: ContentID
    }

    private struct UnresolvedClaim: Hashable {
        let recordContentID: ContentID
        let expectedSubject: DataIdentityReference
    }
}
