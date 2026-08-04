// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCore

@Suite("ProvenanceGraph")
struct ProvenanceGraphTests {
    private func limits(
        records: UInt64 = 16,
        edges: UInt64 = 16,
        depth: UInt64 = 16
    ) throws -> ProvenanceGraphLimits {
        try ProvenanceGraphLimits(
            maximumRecordCount: records,
            maximumParentEdgeCount: edges,
            maximumAncestryDepth: depth,
            maximumUnresolvedExternalReferenceCount: 0,
            maximumExternalResolutionByteCount: 4_096
        )
    }

    private func operationActivity() throws -> ProvenanceActivity {
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

    private func identifier(_ name: String) throws -> ProvenanceID {
        try #require(ProvenanceID(rawValue: name))
    }

    private func subject(_ name: String) throws -> DataIdentityReference {
        .object(try #require(DataObjectID(rawValue: name)))
    }

    private func origin(_ name: String) throws -> ProvenanceRecord {
        try ProvenanceRecord(
            id: try identifier(name),
            kind: .source,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: try subject("obj-\(name)"),
            software: try SoftwareIdentity(
                name: "Voxelia",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: nil,
                buildIdentifier: nil
            ),
            activity: .origin,
            inputs: [],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
    }

    private func derived(
        _ name: String,
        from parents: [(role: String, parent: String, identity: String)]
    ) throws -> ProvenanceRecord {
        var inputs = ContiguousArray<ProvenanceInput>()
        for (index, edge) in parents.enumerated() {
            inputs.append(
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: edge.role),
                    occurrence: UInt32(index + 1),
                    identity: try subject(edge.identity),
                    parent: .graphNode(try identifier(edge.parent))
                )
            )
        }
        return try ProvenanceRecord(
            id: try identifier(name),
            kind: .transformed,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: try subject("obj-\(name)"),
            software: try SoftwareIdentity(
                name: "Voxelia",
                version: try SemanticVersion(major: 1, minor: 0, patch: 0),
                commit: nil,
                buildIdentifier: nil
            ),
            activity: try operationActivity(),
            inputs: inputs,
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
    }

    @Test("[Unit][VOX-META-004][VOX-META-009] chains and diamonds admit with exact depth")
    func chainsAndDiamondsAdmitWithExactDepth() throws {
        // A three-record chain admits with depth evidence three.
        let chain: ContiguousArray = [
            try origin("a"),
            try derived("b", from: [("input", "a", "obj-a")]),
            try derived("c", from: [("input", "b", "obj-b")]),
        ]
        let admitted = try ProvenanceGraph.admitCompleteGraph(
            records: chain,
            roots: [try identifier("c")],
            limits: try limits()
        )
        #expect(admitted.recordCount == 3)
        #expect(admitted.maximumResolvedAncestryDepth == 3)
        #expect(admitted.roots == [try identifier("c")])
        #expect(admitted.record(for: try identifier("b"))?.kind == .transformed)
        #expect(admitted.record(for: try identifier("missing")) == nil)

        // A diamond is visited once per node and edge, not once per
        // path, and its depth is three.
        let diamond: ContiguousArray = [
            try origin("a"),
            try derived("l", from: [("input", "a", "obj-a")]),
            try derived("r", from: [("input", "a", "obj-a")]),
            try derived(
                "d",
                from: [("left", "l", "obj-l"), ("right", "r", "obj-r")]
            ),
        ]
        let admittedDiamond = try ProvenanceGraph.admitCompleteGraph(
            records: diamond,
            roots: [try identifier("d")],
            limits: try limits(edges: 4)
        )
        #expect(admittedDiamond.recordCount == 4)
        #expect(admittedDiamond.maximumResolvedAncestryDepth == 3)

        // Root rules: empty, duplicate, unknown and non-closure tables
        // reject typed.
        let rootCases: [(ContiguousArray<ProvenanceID>, ProvenanceGraphError)] = [
            (ContiguousArray<ProvenanceID>(), .emptyRootSet),
            (
                [try identifier("c"), try identifier("c")],
                .duplicateRootIdentifier
            ),
            ([try identifier("missing")], .unknownRootIdentifier),
            ([try identifier("b")], .unreachableRecord),
        ]
        for (roots, expected) in rootCases {
            do {
                _ = try ProvenanceGraph.admitCompleteGraph(
                    records: chain,
                    roots: roots,
                    limits: try limits()
                )
                #expect(Bool(false), "Expected a root-rule violation to be rejected.")
            } catch let error as ProvenanceGraphError {
                #expect(error == expected)
            }
        }

        requireSendable(ProvenanceGraph.self)
        requireSendable(ProvenanceGraphLimits.self)
        requireSendable(ProvenanceGraphError.self)
    }

    @Test("[Unit][VOX-META-006][VOX-ERR-001] admission rejects structural violations")
    func admissionRejectsStructuralViolations() throws {
        // Two nodes with one identifier are rejected even when their
        // values are equal.
        do {
            _ = try ProvenanceGraph.admitCompleteGraph(
                records: [try origin("a"), try origin("a")],
                roots: [try identifier("a")],
                limits: try limits()
            )
            #expect(Bool(false), "Expected a duplicate identifier to be rejected.")
        } catch ProvenanceGraphError.duplicateRecordIdentifier {}

        // A self-edge is rejected before resolution.
        do {
            _ = try ProvenanceGraph.admitCompleteGraph(
                records: [try derived("x", from: [("input", "x", "obj-x")])],
                roots: [try identifier("x")],
                limits: try limits()
            )
            #expect(Bool(false), "Expected a self-reference to be rejected.")
        } catch ProvenanceGraphError.selfReference {}

        // Unresolved parents and subject mismatches reject typed.
        do {
            _ = try ProvenanceGraph.admitCompleteGraph(
                records: [try derived("b", from: [("input", "a", "obj-a")])],
                roots: [try identifier("b")],
                limits: try limits()
            )
            #expect(Bool(false), "Expected an unresolved parent to be rejected.")
        } catch ProvenanceGraphError.unresolvedParent {}
        do {
            _ = try ProvenanceGraph.admitCompleteGraph(
                records: [
                    try origin("a"),
                    try derived("b", from: [("input", "a", "obj-other")]),
                ],
                roots: [try identifier("b")],
                limits: try limits()
            )
            #expect(Bool(false), "Expected a subject mismatch to be rejected.")
        } catch ProvenanceGraphError.parentSubjectMismatch {}

        // A two-node cycle is caught by visit-once detection.
        do {
            _ = try ProvenanceGraph.admitCompleteGraph(
                records: [
                    try derived("x", from: [("input", "y", "obj-y")]),
                    try derived("y", from: [("input", "x", "obj-x")]),
                ],
                roots: [try identifier("x")],
                limits: try limits()
            )
            #expect(Bool(false), "Expected a two-node cycle to be rejected.")
        } catch ProvenanceGraphError.cyclicAncestry {}

        // Every ceiling rejects, and zero limits are invalid.
        let chain: ContiguousArray = [
            try origin("a"),
            try derived("b", from: [("input", "a", "obj-a")]),
            try derived("c", from: [("input", "b", "obj-b")]),
        ]
        do {
            _ = try ProvenanceGraph.admitCompleteGraph(
                records: chain,
                roots: [try identifier("c")],
                limits: try limits(records: 2)
            )
            #expect(Bool(false), "Expected the record ceiling to reject.")
        } catch ProvenanceGraphError.recordCountLimitExceeded {}
        do {
            _ = try ProvenanceGraph.admitCompleteGraph(
                records: chain,
                roots: [try identifier("c")],
                limits: try limits(edges: 1)
            )
            #expect(Bool(false), "Expected the edge ceiling to reject.")
        } catch ProvenanceGraphError.edgeCountLimitExceeded {}
        do {
            _ = try ProvenanceGraph.admitCompleteGraph(
                records: chain,
                roots: [try identifier("c")],
                limits: try limits(depth: 2)
            )
            #expect(Bool(false), "Expected the depth ceiling to reject.")
        } catch ProvenanceGraphError.ancestryDepthLimitExceeded {}
        do {
            _ = try ProvenanceGraphLimits(
                maximumRecordCount: 0,
                maximumParentEdgeCount: 1,
                maximumAncestryDepth: 1,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 1
            )
            #expect(Bool(false), "Expected a zero limit to be rejected.")
        } catch let error as ProvenanceGraphError {
            #expect(error == .invalidLimits)
            var rendered = ""
            dump(error, to: &rendered)
            #expect(!rendered.contains("obj-"))
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
