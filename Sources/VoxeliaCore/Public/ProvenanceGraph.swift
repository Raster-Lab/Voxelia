// SPDX-License-Identifier: MIT

/// An error raised while validating a provenance graph admission.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// identifiers, subjects or record content.
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
}

/// The explicit inclusive limits profile for one graph admission.
///
/// Every ceiling is mandatory and at least one; there are no permissive
/// defaults, and a caller cannot request an unlimited admission.
public struct ProvenanceGraphLimits: Sendable, Hashable {
    public let maximumRecordCount: UInt64
    public let maximumParentEdgeCount: UInt64
    public let maximumAncestryDepth: UInt64

    /// Creates a validated limits profile.
    ///
    /// - Throws: ``ProvenanceGraphError/invalidLimits`` when any
    ///   ceiling is zero.
    public init(
        maximumRecordCount: UInt64,
        maximumParentEdgeCount: UInt64,
        maximumAncestryDepth: UInt64
    ) throws {
        guard
            maximumRecordCount >= 1, maximumParentEdgeCount >= 1,
            maximumAncestryDepth >= 1
        else {
            throw ProvenanceGraphError.invalidLimits
        }
        self.maximumRecordCount = maximumRecordCount
        self.maximumParentEdgeCount = maximumParentEdgeCount
        self.maximumAncestryDepth = maximumAncestryDepth
    }
}

/// One immutable admitted complete provenance graph snapshot per
/// `ADR-0038` and `ADR-0059`.
///
/// Admission proves structural acyclicity of the exact admitted node
/// table under the exact limits only: scientific validity, authenticity
/// and cache suitability remain separate runtime assurance. Compact
/// graphs, external parents and any mutable graph owner stay deferred
/// with the registered provenance-record projection.
public struct ProvenanceGraph: Sendable {
    /// The declared root identifiers in accepted order.
    public let roots: ContiguousArray<ProvenanceID>
    /// The maximum resolved ancestry depth; evidence computed during
    /// admission without recursion.
    public let maximumResolvedAncestryDepth: UInt64

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
        table: [ProvenanceID: ProvenanceRecord]
    ) {
        self.roots = roots
        self.maximumResolvedAncestryDepth = maximumResolvedAncestryDepth
        self.table = table
    }

    /// Admits one complete graph transactionally: the exact candidate
    /// table must equal the resolved ancestry closure of the declared
    /// roots, every parent must resolve, every resolved parent's subject
    /// must equal the exact input identity, and the resolved edges must
    /// be acyclic within the depth ceiling. Failure publishes nothing.
    public static func admitCompleteGraph(
        records: ContiguousArray<ProvenanceRecord>,
        roots: ContiguousArray<ProvenanceID>,
        limits: ProvenanceGraphLimits
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
        // rejection, parent resolution and the parent-subject rule.
        var parentIdentifiers = [ProvenanceID: ContiguousArray<ProvenanceID>]()
        parentIdentifiers.reserveCapacity(table.count)
        var edgeCount: UInt64 = 0
        for record in records {
            var parents = ContiguousArray<ProvenanceID>()
            for input in record.inputs {
                guard let parent = input.parent else {
                    continue
                }
                switch parent {
                case .graphNode(let parentIdentifier):
                    let (candidate, overflow) = edgeCount.addingReportingOverflow(1)
                    guard !overflow, candidate <= limits.maximumParentEdgeCount
                    else {
                        throw ProvenanceGraphError.edgeCountLimitExceeded
                    }
                    edgeCount = candidate
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
            table: table
        )
    }
}
