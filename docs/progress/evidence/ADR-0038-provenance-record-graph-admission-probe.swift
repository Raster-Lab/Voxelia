// SPDX-License-Identifier: MIT

// Isolated Swift 6 evidence for proposed ADR-0038. Probe declarations are not
// Voxelia product API, canonical coding, cryptography, a resolver or production
// resource limits.

enum ProbeProvenanceError: Error, Sendable, Equatable {
    case invalidLimits
    case invalidText
    case textByteLimitExceeded
    case incompleteProduction
    case kindActivityMismatch
    case undeclaredZeroInputGenerator
    case inputLimitExceeded
    case warningLimitExceeded
    case duplicateInputSlot
    case duplicateWarning
    case unknownWarningSlot
    case selfReference
    case logicalByteLimitExceeded
    case arithmeticOverflow
    case duplicateRoot
    case missingRoot
    case nodeLimitExceeded
    case historicalRecordLimitExceeded
    case edgeLimitExceeded
    case unresolvedLimitExceeded
    case duplicateRecordID
    case conflictingRecordID
    case missingLocalParent
    case unresolvedExternalParent
    case conflictingExternalClaim
    case parentContentMismatch
    case parentSubjectMismatch
    case cycle
    case unreachableRecord
    case depthLimitExceeded
    case cancelled
    case evidenceDenied
}

enum ProbePublicationError: Error, Sendable, Equatable {
    case alreadyPublished
    case cancelled
    case failed
    case staleGeneration
    case snapshotChanged
    case targetRemoved
    case identityMismatch
    case incompleteGraph
    case validationDenied
    case cacheUnauthorized
    case cacheMismatch
}

protocol ProbeRedactedDiagnostic:
    CustomStringConvertible,
    CustomDebugStringConvertible,
    CustomReflectable
{}

extension ProbeRedactedDiagnostic {
    var description: String { "<redacted-provenance-probe>" }
    var debugDescription: String { "<redacted-provenance-probe>" }
    var customMirror: Mirror {
        Mirror(self, children: ["value": "<redacted-provenance-probe>"])
    }
}

extension ProbeProvenanceError: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String { "provenance probe rejected input" }
    var debugDescription: String { description }
}

extension ProbePublicationError: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String { "provenance probe rejected publication" }
    var debugDescription: String { description }
}

struct ProbeExactText: Sendable, Hashable, Comparable, ProbeRedactedDiagnostic {
    private static let hardMaximumUTF8Bytes = 4_096
    private let bytes: ContiguousArray<UInt8>

    init(_ value: String, maximumUTF8Bytes: Int = 64) throws {
        guard
            maximumUTF8Bytes > 0,
            maximumUTF8Bytes <= Self.hardMaximumUTF8Bytes
        else {
            throw ProbeProvenanceError.invalidLimits
        }
        var acceptedBytes: ContiguousArray<UInt8> = []
        acceptedBytes.reserveCapacity(maximumUTF8Bytes)
        for byte in value.utf8 {
            guard acceptedBytes.count < maximumUTF8Bytes else {
                throw ProbeProvenanceError.textByteLimitExceeded
            }
            acceptedBytes.append(byte)
        }
        // The String already crossed this probe-only typed boundary. Once its
        // UTF-8 count is capped, the Unicode-whitespace scan is likewise bounded.
        guard value.contains(where: { !$0.isWhitespace }) else {
            throw ProbeProvenanceError.invalidText
        }
        bytes = acceptedBytes
    }

    var logicalByteCount: UInt64 { UInt64(bytes.count) }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes.lexicographicallyPrecedes(rhs.bytes)
    }
}

struct ProbeRecordID: Sendable, Hashable, Comparable, ProbeRedactedDiagnostic {
    let value: ProbeExactText

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.value < rhs.value }
}

struct ProbeRoleID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

struct ProbeEvidenceID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

struct ProbePolicyID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

struct ProbeSnapshotID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

struct ProbeOutputID: Sendable, Hashable, ProbeRedactedDiagnostic {
    let value: ProbeExactText
}

struct ProbeContentClaim: Sendable, Hashable, ProbeRedactedDiagnostic {
    let projection: ProbeExactText
    let digest: UInt64

    var logicalByteCount: UInt64 {
        projection.logicalByteCount + UInt64(MemoryLayout<UInt64>.size)
    }
}

struct ProbeDataIdentityReference: Sendable, Hashable, ProbeRedactedDiagnostic {
    let objectID: ProbeExactText
    let contentClaim: ProbeContentClaim?

    var logicalByteCount: UInt64 {
        objectID.logicalByteCount + (contentClaim?.logicalByteCount ?? 0)
    }
}

struct ProbeExactSemanticVersion: Sendable, Hashable, ProbeRedactedDiagnostic {
    let major: UInt64
    let minor: UInt64
    let patch: UInt64
    let prerelease: ProbeExactText?
    let buildMetadata: ProbeExactText?

    func hasSameSemanticPrecedence(as other: Self) -> Bool {
        major == other.major
            && minor == other.minor
            && patch == other.patch
            && prerelease == other.prerelease
    }

    var logicalByteCount: UInt64 {
        UInt64(3 * MemoryLayout<UInt64>.size)
            + (prerelease?.logicalByteCount ?? 0)
            + (buildMetadata?.logicalByteCount ?? 0)
    }
}

struct ProbeSoftwareIdentity: Sendable, Hashable, ProbeRedactedDiagnostic {
    let name: ProbeExactText
    let version: ProbeExactSemanticVersion
    let commit: ProbeExactText?
    let buildIdentifier: ProbeExactText?

    var logicalByteCount: UInt64 {
        name.logicalByteCount + version.logicalByteCount
            + (commit?.logicalByteCount ?? 0)
            + (buildIdentifier?.logicalByteCount ?? 0)
    }
}

struct ProbeOperationClaim: Sendable, Hashable, ProbeRedactedDiagnostic {
    let operationID: ProbeExactText
    let operationVersion: ProbeExactSemanticVersion
    let implementationID: ProbeExactText
    let implementationVersion: ProbeExactSemanticVersion
    let parameterClaim: ProbeContentClaim

    var logicalByteCount: UInt64 {
        operationID.logicalByteCount + operationVersion.logicalByteCount
            + implementationID.logicalByteCount
            + implementationVersion.logicalByteCount
            + parameterClaim.logicalByteCount
    }
}

enum ProbeApproximationClaim: UInt8, Sendable, Hashable {
    case exact
    case bounded
    case approximate
}

struct ProbeExecutionClaim: Sendable, Hashable, ProbeRedactedDiagnostic {
    let profileID: ProbeExactText
    let profileVersion: ProbeExactSemanticVersion
    let backendID: ProbeExactText
    let precisionPolicyID: ProbeExactText
    let qualityPolicyID: ProbeExactText
    let capabilityClassID: ProbeExactText?
    let kernelIdentity: ProbeExactText?
    let approximation: ProbeApproximationClaim

    var logicalByteCount: UInt64 {
        profileID.logicalByteCount + profileVersion.logicalByteCount
            + backendID.logicalByteCount + precisionPolicyID.logicalByteCount
            + qualityPolicyID.logicalByteCount
            + (capabilityClassID?.logicalByteCount ?? 0)
            + (kernelIdentity?.logicalByteCount ?? 0)
            + 1
    }
}

struct ProbeInputSlot: Sendable, Hashable, ProbeRedactedDiagnostic {
    let role: ProbeRoleID
    let occurrence: UInt32

    var logicalByteCount: UInt64 {
        role.value.logicalByteCount + UInt64(MemoryLayout<UInt32>.size)
    }
}

enum ProbeParentReference: Sendable, Hashable, ProbeRedactedDiagnostic {
    case graphNode(ProbeRecordID)
    case externalRecord(id: ProbeRecordID, recordContentClaim: ProbeContentClaim)

    enum Tag: UInt8, Sendable, Equatable {
        case graphNode
        case externalRecord
    }

    var tag: Tag {
        switch self {
        case .graphNode:
            .graphNode
        case .externalRecord:
            .externalRecord
        }
    }

    var recordID: ProbeRecordID {
        switch self {
        case .graphNode(let id):
            id
        case .externalRecord(let id, _):
            id
        }
    }

    var logicalByteCount: UInt64 {
        switch self {
        case .graphNode(let id):
            1 + id.value.logicalByteCount
        case .externalRecord(let id, let claim):
            1 + id.value.logicalByteCount + claim.logicalByteCount
        }
    }
}

struct ProbeInput: Sendable, Hashable, ProbeRedactedDiagnostic {
    let slot: ProbeInputSlot
    let identity: ProbeDataIdentityReference
    let parent: ProbeParentReference?

    var logicalByteCount: UInt64 {
        slot.logicalByteCount + identity.logicalByteCount
            + (parent?.logicalByteCount ?? 0)
    }
}

enum ProbeWarningSeverity: UInt8, Sendable, Hashable {
    case informational
    case interpretationAffecting
    case limitedUse
}

struct ProbeWarning: Sendable, Hashable, ProbeRedactedDiagnostic {
    let code: ProbeExactText
    let severity: ProbeWarningSeverity
    let affectedSlot: ProbeInputSlot?
    let occurrence: UInt32

    var logicalByteCount: UInt64 {
        code.logicalByteCount + 1
            + (affectedSlot?.logicalByteCount ?? 0)
            + UInt64(MemoryLayout<UInt32>.size)
    }
}

private struct ProbeWarningKey: Sendable, Hashable {
    let code: ProbeExactText
    let affectedSlot: ProbeInputSlot?
    let occurrence: UInt32
}

enum ProbeValidationLevel: UInt8, Sendable, Hashable {
    case unknown
    case experimental
    case preview
    case validated
    case diagnosticReady
}

struct ProbeValidationClaim: Sendable, Hashable, ProbeRedactedDiagnostic {
    let level: ProbeValidationLevel
    let evidenceID: ProbeEvidenceID?

    init(level: ProbeValidationLevel, evidenceID: ProbeEvidenceID? = nil) throws {
        switch (level, evidenceID) {
        case (.validated, .some), (.diagnosticReady, .some):
            break
        case (.validated, .none), (.diagnosticReady, .none):
            throw ProbeProvenanceError.incompleteProduction
        case (_, .some):
            throw ProbeProvenanceError.incompleteProduction
        case (_, .none):
            break
        }
        self.level = level
        self.evidenceID = evidenceID
    }

    var logicalByteCount: UInt64 {
        1 + (evidenceID?.value.logicalByteCount ?? 0)
    }
}

enum ProbeLifecycleClaim: Sendable, Hashable, ProbeRedactedDiagnostic {
    case current
    case deprecated(code: ProbeExactText)
}

enum ProbeActivity: Sendable, Hashable, ProbeRedactedDiagnostic {
    case origin
    case operation(ProbeOperationClaim, ProbeExecutionClaim)

    var logicalByteCount: UInt64 {
        switch self {
        case .origin:
            1
        case .operation(let operation, let execution):
            1 + operation.logicalByteCount + execution.logicalByteCount
        }
    }
}

enum ProbeKind: UInt8, Sendable, Hashable, CaseIterable {
    case source
    case imported
    case decoded
    case viewed
    case transformed
    case processed
    case segmented
    case registered
    case rendered
    case materialised
    case cached
}

enum ProbeProductionShape: Sendable, Equatable {
    case sourceRoot
    case operation

    static func validate(
        kind: ProbeKind,
        hasInputs: Bool,
        hasOperation: Bool,
        hasExecution: Bool
    ) throws -> Self {
        if kind == .source {
            guard !hasInputs, !hasOperation, !hasExecution else {
                throw ProbeProvenanceError.kindActivityMismatch
            }
            return .sourceRoot
        }

        guard hasOperation, hasExecution else {
            throw ProbeProvenanceError.incompleteProduction
        }
        guard hasInputs else {
            throw ProbeProvenanceError.undeclaredZeroInputGenerator
        }
        return .operation
    }
}

struct ProbeRecordLimits: Sendable, Equatable {
    private static let hardMaximumInputs: UInt64 = 64
    private static let hardMaximumWarnings: UInt64 = 64
    private static let hardMaximumLogicalBytes: UInt64 = 65_536

    let maximumInputs: UInt64
    let maximumWarnings: UInt64
    let maximumLogicalBytes: UInt64

    init(maximumInputs: UInt64, maximumWarnings: UInt64, maximumLogicalBytes: UInt64)
        throws
    {
        guard maximumInputs > 0,
            maximumInputs <= Self.hardMaximumInputs,
            maximumWarnings > 0,
            maximumWarnings <= Self.hardMaximumWarnings,
            maximumLogicalBytes > 0,
            maximumLogicalBytes <= Self.hardMaximumLogicalBytes
        else {
            throw ProbeProvenanceError.invalidLimits
        }
        self.maximumInputs = maximumInputs
        self.maximumWarnings = maximumWarnings
        self.maximumLogicalBytes = maximumLogicalBytes
    }

    static func probeDefault() throws -> Self {
        try Self(maximumInputs: 8, maximumWarnings: 8, maximumLogicalBytes: 4_096)
    }
}

struct ProbeCheckedBudget: Sendable, Equatable {
    private(set) var value: UInt64

    init(_ initialValue: UInt64 = 0) {
        value = initialValue
    }

    mutating func add(_ amount: UInt64, maximum: UInt64 = .max) throws {
        let (sum, overflow) = value.addingReportingOverflow(amount)
        guard !overflow else { throw ProbeProvenanceError.arithmeticOverflow }
        guard sum <= maximum else {
            throw ProbeProvenanceError.logicalByteLimitExceeded
        }
        value = sum
    }
}

// This probe type is an admitted record envelope. `recordContentClaim` is a
// supplied sidecar claim about canonical record bytes, not a field in those
// bytes and not a digest computed by this non-cryptographic probe.
struct ProbeRecord: Sendable, Hashable, ProbeRedactedDiagnostic {
    let id: ProbeRecordID
    let recordContentClaim: ProbeContentClaim
    let kind: ProbeKind
    let subject: ProbeDataIdentityReference
    let software: ProbeSoftwareIdentity
    let activity: ProbeActivity
    let inputs: ContiguousArray<ProbeInput>
    let warnings: ContiguousArray<ProbeWarning>
    let validationClaim: ProbeValidationClaim
    let logicalByteCount: UInt64

    init(
        id: ProbeRecordID,
        recordContentClaim: ProbeContentClaim,
        kind: ProbeKind,
        subject: ProbeDataIdentityReference,
        software: ProbeSoftwareIdentity,
        activity: ProbeActivity,
        inputs: some Sequence<ProbeInput>,
        warnings: some Sequence<ProbeWarning>,
        validationClaim: ProbeValidationClaim,
        limits: ProbeRecordLimits
    ) throws {
        var acceptedInputs: ContiguousArray<ProbeInput> = []
        for input in inputs {
            guard UInt64(acceptedInputs.count) < limits.maximumInputs else {
                throw ProbeProvenanceError.inputLimitExceeded
            }
            acceptedInputs.append(input)
        }
        var acceptedWarnings: ContiguousArray<ProbeWarning> = []
        for warning in warnings {
            guard UInt64(acceptedWarnings.count) < limits.maximumWarnings else {
                throw ProbeProvenanceError.warningLimitExceeded
            }
            acceptedWarnings.append(warning)
        }

        switch (kind, activity, acceptedInputs.isEmpty) {
        case (.source, .origin, true):
            break
        case (.source, _, _):
            throw ProbeProvenanceError.kindActivityMismatch
        case (_, .operation, false):
            break
        case (_, .origin, _):
            throw ProbeProvenanceError.kindActivityMismatch
        case (_, .operation, true):
            throw ProbeProvenanceError.undeclaredZeroInputGenerator
        }

        var acceptedSlots = Set<ProbeInputSlot>()
        for input in acceptedInputs {
            guard acceptedSlots.insert(input.slot).inserted else {
                throw ProbeProvenanceError.duplicateInputSlot
            }
            if let parent = input.parent, parent.recordID == id {
                throw ProbeProvenanceError.selfReference
            }
        }

        var acceptedWarningKeys = Set<ProbeWarningKey>()
        for warning in acceptedWarnings {
            if let affectedSlot = warning.affectedSlot {
                guard acceptedSlots.contains(affectedSlot) else {
                    throw ProbeProvenanceError.unknownWarningSlot
                }
            }
            let warningKey = ProbeWarningKey(
                code: warning.code,
                affectedSlot: warning.affectedSlot,
                occurrence: warning.occurrence
            )
            guard acceptedWarningKeys.insert(warningKey).inserted else {
                throw ProbeProvenanceError.duplicateWarning
            }
        }

        var bytes = ProbeCheckedBudget()
        for amount in [
            id.value.logicalByteCount,
            recordContentClaim.logicalByteCount,
            UInt64(1),
            subject.logicalByteCount,
            software.logicalByteCount,
            activity.logicalByteCount,
            validationClaim.logicalByteCount,
        ] {
            try bytes.add(amount, maximum: limits.maximumLogicalBytes)
        }
        for input in acceptedInputs {
            try bytes.add(input.logicalByteCount, maximum: limits.maximumLogicalBytes)
        }
        for warning in acceptedWarnings {
            try bytes.add(warning.logicalByteCount, maximum: limits.maximumLogicalBytes)
        }

        self.id = id
        self.recordContentClaim = recordContentClaim
        self.kind = kind
        self.subject = subject
        self.software = software
        self.activity = activity
        self.inputs = acceptedInputs
        self.warnings = acceptedWarnings
        self.validationClaim = validationClaim
        logicalByteCount = bytes.value
    }
}

enum ProbeGraphMode: UInt8, Sendable, Equatable {
    case complete
    case compact
}

enum ProbeGraphResolutionState: UInt8, Sendable, Hashable {
    case complete
    case compact
}

struct ProbeGraphLimits: Sendable, Hashable {
    private static let hardMaximumNodes: UInt64 = 64
    private static let hardMaximumEdges: UInt64 = 256
    private static let hardMaximumUnresolvedExternalReferences: UInt64 = 256
    private static let hardMaximumResolvedDepth: UInt64 = 64
    private static let hardMaximumLogicalBytes: UInt64 = 1_048_576

    let maximumNodes: UInt64
    let maximumEdges: UInt64
    // Counted per input-edge occurrence; repeated references to one external
    // record each consume this separate unresolved-reference budget.
    let maximumUnresolvedExternalReferences: UInt64
    let maximumResolvedDepth: UInt64
    let maximumLogicalBytes: UInt64

    init(
        maximumNodes: UInt64,
        maximumEdges: UInt64,
        maximumUnresolvedExternalReferences: UInt64,
        maximumResolvedDepth: UInt64,
        maximumLogicalBytes: UInt64
    ) throws {
        guard maximumNodes > 0,
            maximumNodes <= Self.hardMaximumNodes,
            maximumEdges > 0,
            maximumEdges <= Self.hardMaximumEdges,
            maximumUnresolvedExternalReferences
                <= Self.hardMaximumUnresolvedExternalReferences,
            maximumResolvedDepth > 0,
            maximumResolvedDepth <= Self.hardMaximumResolvedDepth,
            maximumLogicalBytes > 0,
            maximumLogicalBytes <= Self.hardMaximumLogicalBytes
        else {
            throw ProbeProvenanceError.invalidLimits
        }
        self.maximumNodes = maximumNodes
        self.maximumEdges = maximumEdges
        self.maximumUnresolvedExternalReferences = maximumUnresolvedExternalReferences
        self.maximumResolvedDepth = maximumResolvedDepth
        self.maximumLogicalBytes = maximumLogicalBytes
    }

    static func probeDefault() throws -> Self {
        try Self(
            maximumNodes: 16,
            maximumEdges: 32,
            maximumUnresolvedExternalReferences: 8,
            maximumResolvedDepth: 8,
            maximumLogicalBytes: 32_768
        )
    }
}

struct ProbeGraphAssessment: Sendable, Hashable, ProbeRedactedDiagnostic {
    let admissionMode: ProbeGraphMode
    let resolutionState: ProbeGraphResolutionState
    let admittedLimits: ProbeGraphLimits
    let resolverRevision: UInt64
    let recordCount: UInt64
    let edgeCount: UInt64
    let unresolvedExternalReferenceCount: UInt64
    let maximumResolvedDepth: UInt64
    let visitedRecordCount: UInt64

    var isComplete: Bool { resolutionState == .complete }

    fileprivate init(
        admissionMode: ProbeGraphMode,
        resolutionState: ProbeGraphResolutionState,
        admittedLimits: ProbeGraphLimits,
        resolverRevision: UInt64,
        recordCount: UInt64,
        edgeCount: UInt64,
        unresolvedExternalReferenceCount: UInt64,
        maximumResolvedDepth: UInt64,
        visitedRecordCount: UInt64
    ) {
        self.admissionMode = admissionMode
        self.resolutionState = resolutionState
        self.admittedLimits = admittedLimits
        self.resolverRevision = resolverRevision
        self.recordCount = recordCount
        self.edgeCount = edgeCount
        self.unresolvedExternalReferenceCount = unresolvedExternalReferenceCount
        self.maximumResolvedDepth = maximumResolvedDepth
        self.visitedRecordCount = visitedRecordCount
    }
}

struct ProbeGraphSnapshot: Sendable, Hashable, ProbeRedactedDiagnostic {
    let roots: ContiguousArray<ProbeRecordID>
    let records: ContiguousArray<ProbeRecord>
    let assessment: ProbeGraphAssessment

    private init(
        roots: ContiguousArray<ProbeRecordID>,
        records: ContiguousArray<ProbeRecord>,
        assessment: ProbeGraphAssessment
    ) {
        self.roots = roots
        self.records = records
        self.assessment = assessment
    }

    func record(id: ProbeRecordID) -> ProbeRecord? {
        records.first(where: { $0.id == id })
    }
}

private struct ProbeAdmissionControl {
    let cancelAfterWork: UInt64?
    private(set) var chargedWork: UInt64 = 0

    mutating func charge() throws {
        let (next, overflow) = chargedWork.addingReportingOverflow(1)
        guard !overflow else { throw ProbeProvenanceError.arithmeticOverflow }
        chargedWork = next
        if let cancelAfterWork, chargedWork > cancelAfterWork {
            throw ProbeProvenanceError.cancelled
        }
    }
}

private struct ProbeUnresolvedBinding: Sendable, Equatable {
    let contentClaim: ProbeContentClaim
    let expectedSubject: ProbeDataIdentityReference
}

extension ProbeGraphSnapshot {
    static func admit(
        records: some Sequence<ProbeRecord>,
        roots: some Sequence<ProbeRecordID>,
        mode: ProbeGraphMode,
        limits: ProbeGraphLimits,
        resolverRevision: UInt64 = 0,
        cancelAfterWork: UInt64? = nil
    ) throws -> ProbeGraphSnapshot {
        var control = ProbeAdmissionControl(cancelAfterWork: cancelAfterWork)
        var candidateRecords: ContiguousArray<ProbeRecord> = []
        for record in records {
            try control.charge()
            guard UInt64(candidateRecords.count) < limits.maximumNodes else {
                throw ProbeProvenanceError.nodeLimitExceeded
            }
            candidateRecords.append(record)
        }
        var candidateRoots: ContiguousArray<ProbeRecordID> = []
        for root in roots {
            try control.charge()
            guard UInt64(candidateRoots.count) < limits.maximumNodes else {
                throw ProbeProvenanceError.nodeLimitExceeded
            }
            candidateRoots.append(root)
        }

        var nodes: [ProbeRecordID: ProbeRecord] = [:]
        var totalBytes = ProbeCheckedBudget()
        for record in candidateRecords {
            try control.charge()
            if let existing = nodes[record.id] {
                if existing == record {
                    throw ProbeProvenanceError.duplicateRecordID
                }
                throw ProbeProvenanceError.conflictingRecordID
            }
            nodes[record.id] = record
            try totalBytes.add(
                record.logicalByteCount,
                maximum: limits.maximumLogicalBytes
            )
        }

        var rootSet = Set<ProbeRecordID>()
        for root in candidateRoots {
            try control.charge()
            guard rootSet.insert(root).inserted else {
                throw ProbeProvenanceError.duplicateRoot
            }
            guard nodes[root] != nil else {
                throw ProbeProvenanceError.missingRoot
            }
        }
        guard !candidateRoots.isEmpty else {
            throw ProbeProvenanceError.missingRoot
        }

        var resolvedParents: [ProbeRecordID: ContiguousArray<ProbeRecordID>] = [:]
        var children: [ProbeRecordID: ContiguousArray<ProbeRecordID>] = [:]
        var edgeCount: UInt64 = 0
        var unresolvedCount: UInt64 = 0
        var unresolvedBindings: [ProbeRecordID: ProbeUnresolvedBinding] = [:]

        for record in candidateRecords {
            try control.charge()
            resolvedParents[record.id] = []
            children[record.id] = []
        }

        for record in candidateRecords {
            for input in record.inputs {
                try control.charge()
                guard let parent = input.parent else { continue }
                let (nextEdgeCount, edgeOverflow) = edgeCount.addingReportingOverflow(1)
                guard !edgeOverflow else {
                    throw ProbeProvenanceError.arithmeticOverflow
                }
                guard nextEdgeCount <= limits.maximumEdges else {
                    throw ProbeProvenanceError.edgeLimitExceeded
                }
                edgeCount = nextEdgeCount

                let parentID = parent.recordID
                guard parentID != record.id else {
                    throw ProbeProvenanceError.selfReference
                }

                let resolvedParent: ProbeRecord?
                switch parent {
                case .graphNode:
                    guard let found = nodes[parentID] else {
                        throw ProbeProvenanceError.missingLocalParent
                    }
                    resolvedParent = found
                case .externalRecord(_, let recordContentClaim):
                    if let found = nodes[parentID] {
                        guard found.recordContentClaim == recordContentClaim else {
                            throw ProbeProvenanceError.parentContentMismatch
                        }
                        resolvedParent = found
                    } else {
                        guard mode == .compact else {
                            throw ProbeProvenanceError.unresolvedExternalParent
                        }
                        let binding = ProbeUnresolvedBinding(
                            contentClaim: recordContentClaim,
                            expectedSubject: input.identity
                        )
                        if let existingBinding = unresolvedBindings[parentID] {
                            guard existingBinding == binding else {
                                throw ProbeProvenanceError.conflictingExternalClaim
                            }
                        } else {
                            unresolvedBindings[parentID] = binding
                        }
                        let (nextUnresolved, unresolvedOverflow) =
                            unresolvedCount.addingReportingOverflow(1)
                        guard !unresolvedOverflow else {
                            throw ProbeProvenanceError.arithmeticOverflow
                        }
                        guard
                            nextUnresolved
                                <= limits.maximumUnresolvedExternalReferences
                        else {
                            throw ProbeProvenanceError.unresolvedLimitExceeded
                        }
                        unresolvedCount = nextUnresolved
                        resolvedParent = nil
                    }
                }

                guard let resolvedParent else { continue }
                guard resolvedParent.subject == input.identity else {
                    throw ProbeProvenanceError.parentSubjectMismatch
                }
                resolvedParents[record.id, default: []].append(parentID)
                children[parentID, default: []].append(record.id)
            }
        }

        var pendingParentCounts: [ProbeRecordID: UInt64] = [:]
        var depths: [ProbeRecordID: UInt64] = [:]
        var queue: ContiguousArray<ProbeRecordID> = []
        for record in candidateRecords {
            let count = UInt64(resolvedParents[record.id, default: []].count)
            pendingParentCounts[record.id] = count
            depths[record.id] = 1
            if count == 0 { queue.append(record.id) }
        }

        var queueIndex = 0
        var visitedCount: UInt64 = 0
        var maximumDepth: UInt64 = 0
        while queueIndex < queue.count {
            try control.charge()
            let recordID = queue[queueIndex]
            queueIndex += 1
            let (nextVisitedCount, visitedOverflow) =
                visitedCount.addingReportingOverflow(1)
            guard !visitedOverflow else {
                throw ProbeProvenanceError.arithmeticOverflow
            }
            visitedCount = nextVisitedCount
            let parentDepth = depths[recordID, default: 1]
            maximumDepth = max(maximumDepth, parentDepth)
            guard parentDepth <= limits.maximumResolvedDepth else {
                throw ProbeProvenanceError.depthLimitExceeded
            }

            for childID in children[recordID, default: []] {
                try control.charge()
                let (candidateDepth, depthOverflow) = parentDepth.addingReportingOverflow(1)
                guard !depthOverflow else {
                    throw ProbeProvenanceError.arithmeticOverflow
                }
                depths[childID] = max(depths[childID, default: 1], candidateDepth)
                guard let pending = pendingParentCounts[childID], pending > 0 else {
                    throw ProbeProvenanceError.arithmeticOverflow
                }
                let remaining = pending - 1
                pendingParentCounts[childID] = remaining
                if remaining == 0 { queue.append(childID) }
            }
        }

        guard visitedCount == UInt64(candidateRecords.count) else {
            throw ProbeProvenanceError.cycle
        }

        var reachable = Set(candidateRoots)
        var reachabilityQueue = candidateRoots
        var reachabilityIndex = 0
        while reachabilityIndex < reachabilityQueue.count {
            try control.charge()
            let recordID = reachabilityQueue[reachabilityIndex]
            reachabilityIndex += 1
            for parentID in resolvedParents[recordID, default: []] {
                try control.charge()
                if reachable.insert(parentID).inserted {
                    reachabilityQueue.append(parentID)
                }
            }
        }
        guard reachable.count == candidateRecords.count else {
            throw ProbeProvenanceError.unreachableRecord
        }

        return ProbeGraphSnapshot(
            roots: candidateRoots,
            records: candidateRecords,
            assessment: ProbeGraphAssessment(
                admissionMode: mode,
                resolutionState: unresolvedCount == 0 ? .complete : .compact,
                admittedLimits: limits,
                resolverRevision: resolverRevision,
                recordCount: UInt64(candidateRecords.count),
                edgeCount: edgeCount,
                unresolvedExternalReferenceCount: unresolvedCount,
                maximumResolvedDepth: maximumDepth,
                visitedRecordCount: visitedCount
            )
        )
    }
}

enum ProbeGraphAdmission {
    static func admit(
        records: some Sequence<ProbeRecord>,
        roots: some Sequence<ProbeRecordID>,
        mode: ProbeGraphMode,
        limits: ProbeGraphLimits,
        resolverRevision: UInt64 = 0,
        cancelAfterWork: UInt64? = nil
    ) throws -> ProbeGraphSnapshot {
        try ProbeGraphSnapshot.admit(
            records: records,
            roots: roots,
            mode: mode,
            limits: limits,
            resolverRevision: resolverRevision,
            cancelAfterWork: cancelAfterWork
        )
    }
}

actor ProbeGraphStore {
    private static let hardMaximumHistoricalRecords: UInt64 = 256
    private let maximumHistoricalRecords: UInt64
    private let resolverRevision: UInt64
    private var admittedRecordsByID: [ProbeRecordID: ProbeRecord]
    private var storedSnapshot: ProbeGraphSnapshot

    init(
        _ snapshot: ProbeGraphSnapshot,
        maximumHistoricalRecords: UInt64
    ) throws {
        guard
            maximumHistoricalRecords >= UInt64(snapshot.records.count),
            maximumHistoricalRecords <= Self.hardMaximumHistoricalRecords
        else {
            throw ProbeProvenanceError.invalidLimits
        }
        self.maximumHistoricalRecords = maximumHistoricalRecords
        resolverRevision = snapshot.assessment.resolverRevision
        admittedRecordsByID = Dictionary(
            uniqueKeysWithValues: snapshot.records.map { ($0.id, $0) }
        )
        storedSnapshot = snapshot
    }

    func replace(
        records: some Sequence<ProbeRecord> & Sendable,
        roots: some Sequence<ProbeRecordID> & Sendable,
        mode: ProbeGraphMode,
        limits: ProbeGraphLimits,
        cancelAfterWork: UInt64? = nil
    ) throws {
        let candidate = try ProbeGraphAdmission.admit(
            records: records,
            roots: roots,
            mode: mode,
            limits: limits,
            resolverRevision: resolverRevision,
            cancelAfterWork: cancelAfterWork
        )
        var nextRecordsByID = admittedRecordsByID
        for candidateRecord in candidate.records {
            if let existingRecord = nextRecordsByID[candidateRecord.id],
                existingRecord != candidateRecord
            {
                throw ProbeProvenanceError.conflictingRecordID
            }
            if nextRecordsByID[candidateRecord.id] == nil {
                guard UInt64(nextRecordsByID.count) < maximumHistoricalRecords else {
                    throw ProbeProvenanceError.historicalRecordLimitExceeded
                }
                nextRecordsByID[candidateRecord.id] = candidateRecord
            }
        }
        admittedRecordsByID = nextRecordsByID
        storedSnapshot = candidate
    }

    func snapshot() -> ProbeGraphSnapshot { storedSnapshot }
}

struct ProbeValidationEvidence: Sendable, Hashable, ProbeRedactedDiagnostic {
    let evidenceID: ProbeEvidenceID
    let exactRecord: ProbeRecord
    let recordID: ProbeRecordID
    let recordContentClaim: ProbeContentClaim
    let approvedLevel: ProbeValidationLevel
    let operationID: ProbeExactText
    let implementationVersion: ProbeExactSemanticVersion
    let profileID: ProbeExactText
    let backendID: ProbeExactText
    let capabilityClassID: ProbeExactText?
    let releaseID: ProbeExactText
    let policyID: ProbePolicyID
    let isExpired: Bool
    let isRevoked: Bool
}

struct ProbeAssuranceContext: Sendable, Hashable, ProbeRedactedDiagnostic {
    let releaseID: ProbeExactText
    let policyID: ProbePolicyID
    let requiredCapabilityClassID: ProbeExactText?
}

struct ProbeValidationAssurance: Sendable, Hashable, ProbeRedactedDiagnostic {
    let exactRecord: ProbeRecord
    let recordID: ProbeRecordID
    let recordContentClaim: ProbeContentClaim
    let evidenceID: ProbeEvidenceID
    let level: ProbeValidationLevel
    let context: ProbeAssuranceContext

    fileprivate init(
        exactRecord: ProbeRecord,
        recordID: ProbeRecordID,
        recordContentClaim: ProbeContentClaim,
        evidenceID: ProbeEvidenceID,
        level: ProbeValidationLevel,
        context: ProbeAssuranceContext
    ) {
        self.exactRecord = exactRecord
        self.recordID = recordID
        self.recordContentClaim = recordContentClaim
        self.evidenceID = evidenceID
        self.level = level
        self.context = context
    }
}

enum ProbeAssuranceEvaluator {
    static func evaluate(
        record: ProbeRecord,
        evidence: ProbeValidationEvidence?,
        context: ProbeAssuranceContext
    ) throws -> ProbeValidationAssurance {
        guard
            record.validationClaim.level == .validated
                || record.validationClaim.level == .diagnosticReady,
            let claimedEvidenceID = record.validationClaim.evidenceID,
            let evidence,
            evidence.evidenceID == claimedEvidenceID,
            evidence.exactRecord == record,
            evidence.recordID == record.id,
            evidence.recordContentClaim == record.recordContentClaim,
            evidence.approvedLevel == record.validationClaim.level,
            evidence.approvedLevel == .validated
                || evidence.approvedLevel == .diagnosticReady,
            !evidence.isExpired,
            !evidence.isRevoked,
            evidence.releaseID == context.releaseID,
            evidence.policyID == context.policyID,
            evidence.capabilityClassID == context.requiredCapabilityClassID
        else {
            throw ProbeProvenanceError.evidenceDenied
        }

        guard case .operation(let operation, let execution) = record.activity,
            operation.operationID == evidence.operationID,
            operation.implementationVersion == evidence.implementationVersion,
            execution.profileID == evidence.profileID,
            execution.backendID == evidence.backendID,
            execution.capabilityClassID == evidence.capabilityClassID
        else {
            throw ProbeProvenanceError.evidenceDenied
        }

        return ProbeValidationAssurance(
            exactRecord: record,
            recordID: record.id,
            recordContentClaim: record.recordContentClaim,
            evidenceID: evidence.evidenceID,
            level: evidence.approvedLevel,
            context: context
        )
    }
}

struct ProbePublishedBundle: Sendable, Hashable, ProbeRedactedDiagnostic {
    let outputID: ProbeOutputID
    let identity: ProbeDataIdentityReference
    let provenanceRoot: ProbeRecordID
    let graph: ProbeGraphSnapshot
    let assurance: ProbeValidationAssurance?
    let generation: UInt64
    let snapshotID: ProbeSnapshotID
    let cachePolicyID: ProbePolicyID?

    var cacheAliasPublished: Bool { cachePolicyID != nil }
}

// Runtime sidecars model evidence supplied by the output/cache owner. Their
// construction is intentionally unavailable outside this isolated file.
struct ProbeOutputIdentityEvidence: Sendable, Hashable, ProbeRedactedDiagnostic {
    let outputID: ProbeOutputID
    let identity: ProbeDataIdentityReference
    let generation: UInt64
    let snapshotID: ProbeSnapshotID

    fileprivate init(
        outputID: ProbeOutputID,
        identity: ProbeDataIdentityReference,
        generation: UInt64,
        snapshotID: ProbeSnapshotID
    ) {
        self.outputID = outputID
        self.identity = identity
        self.generation = generation
        self.snapshotID = snapshotID
    }
}

struct ProbeCacheReadEvidence: Sendable, Hashable, ProbeRedactedDiagnostic {
    let policyID: ProbePolicyID
    let output: ProbeOutputIdentityEvidence
    let provenanceRoot: ProbeRecordID
    let rootContentClaim: ProbeContentClaim
    let exactRoot: ProbeRecord
    let exactGraph: ProbeGraphSnapshot
    let resolverRevision: UInt64

    fileprivate init(
        policyID: ProbePolicyID,
        output: ProbeOutputIdentityEvidence,
        provenanceRoot: ProbeRecordID,
        rootContentClaim: ProbeContentClaim,
        exactRoot: ProbeRecord,
        exactGraph: ProbeGraphSnapshot,
        resolverRevision: UInt64
    ) {
        self.policyID = policyID
        self.output = output
        self.provenanceRoot = provenanceRoot
        self.rootContentClaim = rootContentClaim
        self.exactRoot = exactRoot
        self.exactGraph = exactGraph
        self.resolverRevision = resolverRevision
    }
}

struct ProbeCachePublicationAuthorization:
    Sendable,
    Hashable,
    ProbeRedactedDiagnostic
{
    let policyID: ProbePolicyID
    let outputID: ProbeOutputID
    let identity: ProbeDataIdentityReference
    let provenanceRoot: ProbeRecordID
    let rootContentClaim: ProbeContentClaim
    let exactRoot: ProbeRecord
    let exactGraph: ProbeGraphSnapshot
    let generation: UInt64
    let snapshotID: ProbeSnapshotID

    fileprivate init(
        policyID: ProbePolicyID,
        outputID: ProbeOutputID,
        identity: ProbeDataIdentityReference,
        provenanceRoot: ProbeRecordID,
        rootContentClaim: ProbeContentClaim,
        exactRoot: ProbeRecord,
        exactGraph: ProbeGraphSnapshot,
        generation: UInt64,
        snapshotID: ProbeSnapshotID
    ) {
        self.policyID = policyID
        self.outputID = outputID
        self.identity = identity
        self.provenanceRoot = provenanceRoot
        self.rootContentClaim = rootContentClaim
        self.exactRoot = exactRoot
        self.exactGraph = exactGraph
        self.generation = generation
        self.snapshotID = snapshotID
    }
}

struct ProbePublicationCandidate: Sendable, Hashable, ProbeRedactedDiagnostic {
    let outputID: ProbeOutputID
    let identity: ProbeDataIdentityReference
    let outputIdentityEvidence: ProbeOutputIdentityEvidence
    let provenanceRoot: ProbeRecordID
    let graph: ProbeGraphSnapshot
    let assurance: ProbeValidationAssurance?
    let generation: UInt64
    let snapshotID: ProbeSnapshotID
    let cacheAuthorization: ProbeCachePublicationAuthorization?
}

struct ProbePublisherState: Sendable, Hashable, ProbeRedactedDiagnostic {
    let bundle: ProbePublishedBundle?
    let outputCount: UInt64
    let provenanceCount: UInt64
    let cacheAliasCount: UInt64

    static let empty = Self(
        bundle: nil,
        outputCount: 0,
        provenanceCount: 0,
        cacheAliasCount: 0
    )
}

actor ProbePublisher {
    private let currentGeneration: UInt64
    private let currentSnapshotID: ProbeSnapshotID
    private let currentResolverRevision: UInt64
    private let approvedGraphLimits: ProbeGraphLimits
    private let authorizedAssuranceContext: ProbeAssuranceContext?
    private let authorizedCachePolicyID: ProbePolicyID?
    private var state: ProbePublisherState = .empty

    init(
        currentGeneration: UInt64,
        currentSnapshotID: ProbeSnapshotID,
        currentResolverRevision: UInt64,
        approvedGraphLimits: ProbeGraphLimits,
        authorizedAssuranceContext: ProbeAssuranceContext? = nil,
        authorizedCachePolicyID: ProbePolicyID? = nil
    ) {
        self.currentGeneration = currentGeneration
        self.currentSnapshotID = currentSnapshotID
        self.currentResolverRevision = currentResolverRevision
        self.approvedGraphLimits = approvedGraphLimits
        self.authorizedAssuranceContext = authorizedAssuranceContext
        self.authorizedCachePolicyID = authorizedCachePolicyID
    }

    func publish(
        _ candidate: ProbePublicationCandidate,
        cancelled: Bool = false,
        failed: Bool = false,
        targetRemoved: Bool = false,
        requireCompleteGraph: Bool = true,
        requireValidationAssurance: Bool = false
    ) throws -> ProbePublishedBundle {
        guard state.bundle == nil else {
            throw ProbePublicationError.alreadyPublished
        }
        guard !cancelled else { throw ProbePublicationError.cancelled }
        guard !failed else { throw ProbePublicationError.failed }
        guard !targetRemoved else { throw ProbePublicationError.targetRemoved }
        guard candidate.generation == currentGeneration else {
            throw ProbePublicationError.staleGeneration
        }
        guard candidate.snapshotID == currentSnapshotID else {
            throw ProbePublicationError.snapshotChanged
        }
        guard candidate.outputIdentityEvidence.outputID == candidate.outputID,
            candidate.outputIdentityEvidence.identity == candidate.identity,
            candidate.outputIdentityEvidence.generation == currentGeneration,
            candidate.outputIdentityEvidence.snapshotID == currentSnapshotID
        else {
            throw ProbePublicationError.identityMismatch
        }
        guard candidate.graph.assessment.resolverRevision == currentResolverRevision,
            candidate.graph.assessment.admittedLimits == approvedGraphLimits
        else {
            throw ProbePublicationError.snapshotChanged
        }
        guard !requireCompleteGraph || candidate.graph.assessment.isComplete else {
            throw ProbePublicationError.incompleteGraph
        }
        guard let root = candidate.graph.record(id: candidate.provenanceRoot),
            candidate.graph.roots == [candidate.provenanceRoot],
            root.subject == candidate.identity
        else {
            throw ProbePublicationError.identityMismatch
        }
        if let assurance = candidate.assurance {
            guard let authorizedAssuranceContext,
                assurance.exactRecord == root,
                assurance.recordID == root.id,
                assurance.recordContentClaim == root.recordContentClaim,
                assurance.context == authorizedAssuranceContext,
                assurance.level == .validated || assurance.level == .diagnosticReady
            else {
                throw ProbePublicationError.validationDenied
            }
        } else if requireValidationAssurance {
            throw ProbePublicationError.validationDenied
        }
        if let cacheAuthorization = candidate.cacheAuthorization {
            guard let authorizedCachePolicyID,
                cacheAuthorization.policyID == authorizedCachePolicyID,
                cacheAuthorization.outputID == candidate.outputID,
                cacheAuthorization.identity == candidate.identity,
                cacheAuthorization.provenanceRoot == root.id,
                cacheAuthorization.rootContentClaim == root.recordContentClaim,
                cacheAuthorization.exactRoot == root,
                cacheAuthorization.exactGraph == candidate.graph,
                cacheAuthorization.generation == currentGeneration,
                cacheAuthorization.snapshotID == currentSnapshotID
            else {
                throw ProbePublicationError.cacheUnauthorized
            }
        }

        let bundle = ProbePublishedBundle(
            outputID: candidate.outputID,
            identity: candidate.identity,
            provenanceRoot: candidate.provenanceRoot,
            graph: candidate.graph,
            assurance: candidate.assurance,
            generation: currentGeneration,
            snapshotID: currentSnapshotID,
            cachePolicyID: candidate.cacheAuthorization?.policyID
        )
        state = ProbePublisherState(
            bundle: bundle,
            outputCount: 1,
            provenanceCount: 1,
            cacheAliasCount: candidate.cacheAuthorization == nil ? 0 : 1
        )
        return bundle
    }

    func cacheHit(_ evidence: ProbeCacheReadEvidence) throws -> ProbePublishedBundle {
        guard let bundle = state.bundle,
            bundle.cacheAliasPublished,
            evidence.policyID == authorizedCachePolicyID,
            evidence.policyID == bundle.cachePolicyID,
            bundle.outputID == evidence.output.outputID,
            bundle.identity == evidence.output.identity,
            bundle.generation == evidence.output.generation,
            bundle.snapshotID == evidence.output.snapshotID,
            bundle.provenanceRoot == evidence.provenanceRoot,
            bundle.graph.assessment.resolverRevision == evidence.resolverRevision,
            evidence.exactGraph == bundle.graph,
            evidence.exactRoot == bundle.graph.record(id: evidence.provenanceRoot),
            bundle.graph.record(id: evidence.provenanceRoot)?.subject
                == evidence.output.identity,
            bundle.graph.record(id: evidence.provenanceRoot)?.recordContentClaim
                == evidence.rootContentClaim
        else {
            throw ProbePublicationError.cacheMismatch
        }
        return bundle
    }

    func snapshot() -> ProbePublisherState { state }
}

enum ProbeFixtures {
    static func exactText(_ value: String) throws -> ProbeExactText {
        try ProbeExactText(value)
    }

    static func recordID(_ value: String) throws -> ProbeRecordID {
        try ProbeRecordID(value: exactText(value))
    }

    static func role(_ value: String) throws -> ProbeRoleID {
        try ProbeRoleID(value: exactText(value))
    }

    static func version(build: String = "build.1") throws -> ProbeExactSemanticVersion {
        try ProbeExactSemanticVersion(
            major: 1,
            minor: 2,
            patch: 3,
            prerelease: nil,
            buildMetadata: exactText(build)
        )
    }

    static func content(_ digest: UInt64, projection: String = "probe.record.v1") throws
        -> ProbeContentClaim
    {
        try ProbeContentClaim(projection: exactText(projection), digest: digest)
    }

    static func identity(_ object: String, digest: UInt64) throws
        -> ProbeDataIdentityReference
    {
        try ProbeDataIdentityReference(
            objectID: exactText(object),
            contentClaim: content(digest, projection: "probe.data.v1")
        )
    }

    static func software(build: String = "build.1") throws -> ProbeSoftwareIdentity {
        try ProbeSoftwareIdentity(
            name: exactText("org.voxelia.probe"),
            version: version(build: build),
            commit: exactText("0123456789abcdef"),
            buildIdentifier: exactText("probe-build")
        )
    }

    static func operation(build: String = "build.1") throws -> ProbeOperationClaim {
        try ProbeOperationClaim(
            operationID: exactText("org.voxelia.operation.probe"),
            operationVersion: version(build: "operation.1"),
            implementationID: exactText("org.voxelia.implementation.probe"),
            implementationVersion: version(build: build),
            parameterClaim: content(41, projection: "probe.parameters.v1")
        )
    }

    static func execution() throws -> ProbeExecutionClaim {
        try ProbeExecutionClaim(
            profileID: exactText("diagnostic"),
            profileVersion: version(build: "profile.1"),
            backendID: exactText("cpu.reference"),
            precisionPolicyID: exactText("binary64"),
            qualityPolicyID: exactText("diagnostic"),
            capabilityClassID: exactText("apple-silicon-reference"),
            kernelIdentity: exactText("probe-kernel-v1"),
            approximation: .exact
        )
    }

    static func unknownValidation() throws -> ProbeValidationClaim {
        try ProbeValidationClaim(level: .unknown)
    }

    static func source(
        id: String,
        object: String,
        digest: UInt64,
        recordLimits: ProbeRecordLimits
    ) throws -> ProbeRecord {
        try ProbeRecord(
            id: recordID(id),
            recordContentClaim: content(digest),
            kind: .source,
            subject: identity(object, digest: digest + 1_000),
            software: software(),
            activity: .origin,
            inputs: [] as [ProbeInput],
            warnings: [] as [ProbeWarning],
            validationClaim: unknownValidation(),
            limits: recordLimits
        )
    }

    static func input(
        role: String,
        occurrence: UInt32,
        identity: ProbeDataIdentityReference,
        parent: ProbeParentReference?
    ) throws -> ProbeInput {
        try ProbeInput(
            slot: ProbeInputSlot(role: self.role(role), occurrence: occurrence),
            identity: identity,
            parent: parent
        )
    }

    static func derived(
        id: String,
        object: String,
        digest: UInt64,
        inputs: [ProbeInput],
        kind: ProbeKind = .processed,
        build: String = "build.1",
        warnings: [ProbeWarning] = [],
        validation: ProbeValidationClaim? = nil,
        recordLimits: ProbeRecordLimits
    ) throws -> ProbeRecord {
        try ProbeRecord(
            id: recordID(id),
            recordContentClaim: content(digest),
            kind: kind,
            subject: identity(object, digest: digest + 1_000),
            software: software(build: build),
            activity: .operation(operation(build: build), execution()),
            inputs: inputs,
            warnings: warnings,
            validationClaim: validation ?? unknownValidation(),
            limits: recordLimits
        )
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String = "probe failed") {
    precondition(condition(), message)
}

func requireThrows<T: Error & Equatable>(
    _ expected: T,
    _ operation: () throws -> some Any
) {
    do {
        _ = try operation()
        preconditionFailure("probe unexpectedly succeeded")
    } catch let error as T {
        precondition(error == expected, "probe returned a different typed failure")
    } catch {
        preconditionFailure("probe returned an unexpected error type")
    }
}

@main
struct ADR0038ProvenanceRecordGraphAdmissionProbe {
    static func main() async throws {
        try testClosedProductionShape()
        try testExactIdentityAndRecordEquality()
        try testRecordConstructionAndOrdering()
        try testReferenceTagsAndGraphAdmission()
        try await testGraphCyclesLimitsAndTransactions()
        try testClaimsRemainSeparateFromEvidence()
        try await testAtomicPublication()
        try testRedactedDiagnostics()
    }

    private static func testClosedProductionShape() throws {
        for kind in ProbeKind.allCases {
            for hasInputs in [false, true] {
                for hasOperation in [false, true] {
                    for hasExecution in [false, true] {
                        if kind == .source {
                            if !hasInputs, !hasOperation, !hasExecution {
                                let shape = try ProbeProductionShape.validate(
                                    kind: kind,
                                    hasInputs: hasInputs,
                                    hasOperation: hasOperation,
                                    hasExecution: hasExecution
                                )
                                require(shape == .sourceRoot)
                            } else {
                                requireThrows(ProbeProvenanceError.kindActivityMismatch) {
                                    try ProbeProductionShape.validate(
                                        kind: kind,
                                        hasInputs: hasInputs,
                                        hasOperation: hasOperation,
                                        hasExecution: hasExecution
                                    )
                                }
                            }
                        } else if hasInputs, hasOperation, hasExecution {
                            let shape = try ProbeProductionShape.validate(
                                kind: kind,
                                hasInputs: hasInputs,
                                hasOperation: hasOperation,
                                hasExecution: hasExecution
                            )
                            require(shape == .operation)
                        } else if !hasInputs, hasOperation, hasExecution {
                            requireThrows(ProbeProvenanceError.undeclaredZeroInputGenerator) {
                                try ProbeProductionShape.validate(
                                    kind: kind,
                                    hasInputs: hasInputs,
                                    hasOperation: hasOperation,
                                    hasExecution: hasExecution
                                )
                            }
                        } else {
                            requireThrows(ProbeProvenanceError.incompleteProduction) {
                                try ProbeProductionShape.validate(
                                    kind: kind,
                                    hasInputs: hasInputs,
                                    hasOperation: hasOperation,
                                    hasExecution: hasExecution
                                )
                            }
                        }
                    }
                }
            }
        }

        let limits = try ProbeRecordLimits.probeDefault()
        let source = try ProbeFixtures.source(
            id: "record.shape-source",
            object: "object.shape-source",
            digest: 900,
            recordLimits: limits
        )
        let input = try ProbeFixtures.input(
            role: "source",
            occurrence: 0,
            identity: source.subject,
            parent: .graphNode(source.id)
        )
        for kind in ProbeKind.allCases where kind != .source {
            let kindSuffix = String(kind.rawValue)
            let valid = try ProbeFixtures.derived(
                id: "record.shape-valid-" + kindSuffix,
                object: "object.shape-valid-" + kindSuffix,
                digest: 1_000 + UInt64(kind.rawValue),
                inputs: [input],
                kind: kind,
                recordLimits: limits
            )
            require(valid.kind == kind)

            requireThrows(ProbeProvenanceError.kindActivityMismatch) {
                try ProbeRecord(
                    id: ProbeFixtures.recordID("record.shape-origin-" + kindSuffix),
                    recordContentClaim: ProbeFixtures.content(
                        2_000 + UInt64(kind.rawValue)
                    ),
                    kind: kind,
                    subject: valid.subject,
                    software: ProbeFixtures.software(),
                    activity: .origin,
                    inputs: [input],
                    warnings: [] as [ProbeWarning],
                    validationClaim: ProbeFixtures.unknownValidation(),
                    limits: limits
                )
            }
            requireThrows(ProbeProvenanceError.undeclaredZeroInputGenerator) {
                try ProbeRecord(
                    id: ProbeFixtures.recordID("record.shape-empty-" + kindSuffix),
                    recordContentClaim: ProbeFixtures.content(
                        3_000 + UInt64(kind.rawValue)
                    ),
                    kind: kind,
                    subject: valid.subject,
                    software: ProbeFixtures.software(),
                    activity: .operation(
                        ProbeFixtures.operation(),
                        ProbeFixtures.execution()
                    ),
                    inputs: [] as [ProbeInput],
                    warnings: [] as [ProbeWarning],
                    validationClaim: ProbeFixtures.unknownValidation(),
                    limits: limits
                )
            }
        }

        requireThrows(ProbeProvenanceError.kindActivityMismatch) {
            try ProbeRecord(
                id: ProbeFixtures.recordID("record.shape-invalid-source"),
                recordContentClaim: ProbeFixtures.content(4_000),
                kind: .source,
                subject: source.subject,
                software: ProbeFixtures.software(),
                activity: .operation(
                    ProbeFixtures.operation(),
                    ProbeFixtures.execution()
                ),
                inputs: [input],
                warnings: [] as [ProbeWarning],
                validationClaim: ProbeFixtures.unknownValidation(),
                limits: limits
            )
        }
    }

    private static func testExactIdentityAndRecordEquality() throws {
        let composed = try ProbeExactText("\u{00E9}")
        let decomposed = try ProbeExactText("e\u{0301}")
        require(composed != decomposed)

        let maximum = String(repeating: "a", count: 64)
        _ = try ProbeExactText(maximum)
        requireThrows(ProbeProvenanceError.textByteLimitExceeded) {
            try ProbeExactText(maximum + "a")
        }
        requireThrows(ProbeProvenanceError.invalidText) {
            try ProbeExactText(" \t\n")
        }
        requireThrows(ProbeProvenanceError.invalidLimits) {
            try ProbeExactText("a", maximumUTF8Bytes: .max)
        }
        requireThrows(ProbeProvenanceError.invalidLimits) {
            try ProbeRecordLimits(
                maximumInputs: .max,
                maximumWarnings: 1,
                maximumLogicalBytes: 1
            )
        }

        let firstVersion = try ProbeFixtures.version(build: "build.1")
        let secondVersion = try ProbeFixtures.version(build: "build.2")
        require(firstVersion.hasSameSemanticPrecedence(as: secondVersion))
        require(firstVersion != secondVersion)

        let recordLimits = try ProbeRecordLimits.probeDefault()
        let source = try ProbeFixtures.source(
            id: "record.source",
            object: "object.source",
            digest: 1,
            recordLimits: recordLimits
        )
        let input = try ProbeFixtures.input(
            role: "source",
            occurrence: 0,
            identity: source.subject,
            parent: .graphNode(source.id)
        )
        let first = try ProbeFixtures.derived(
            id: "record.result.1",
            object: "object.result",
            digest: 2,
            inputs: [input],
            build: "build.1",
            recordLimits: recordLimits
        )
        let second = try ProbeFixtures.derived(
            id: "record.result.1",
            object: "object.result",
            digest: 2,
            inputs: [input],
            build: "build.2",
            recordLimits: recordLimits
        )
        require(first != second)

        let sameBodyDifferentID = try ProbeFixtures.derived(
            id: "record.result.2",
            object: "object.result",
            digest: 2,
            inputs: [input],
            build: "build.1",
            recordLimits: recordLimits
        )
        require(first != sameBodyDifferentID)
    }

    private static func testRecordConstructionAndOrdering() throws {
        let limits = try ProbeRecordLimits.probeDefault()
        let source = try ProbeFixtures.source(
            id: "record.source",
            object: "object.source",
            digest: 10,
            recordLimits: limits
        )
        let fixed = try ProbeFixtures.input(
            role: "fixed",
            occurrence: 0,
            identity: source.subject,
            parent: .graphNode(source.id)
        )
        let moving = try ProbeFixtures.input(
            role: "moving",
            occurrence: 0,
            identity: source.subject,
            parent: .graphNode(source.id)
        )
        let first = try ProbeFixtures.derived(
            id: "record.registration",
            object: "object.registration",
            digest: 11,
            inputs: [fixed, moving],
            recordLimits: limits
        )
        let reordered = try ProbeFixtures.derived(
            id: "record.registration",
            object: "object.registration",
            digest: 11,
            inputs: [moving, fixed],
            recordLimits: limits
        )
        require(first != reordered)

        requireThrows(ProbeProvenanceError.duplicateInputSlot) {
            try ProbeFixtures.derived(
                id: "record.duplicate-slot",
                object: "object.duplicate-slot",
                digest: 12,
                inputs: [fixed, fixed],
                recordLimits: limits
            )
        }

        let selfInput = try ProbeFixtures.input(
            role: "source",
            occurrence: 0,
            identity: source.subject,
            parent: .graphNode(try ProbeFixtures.recordID("record.self"))
        )
        requireThrows(ProbeProvenanceError.selfReference) {
            try ProbeFixtures.derived(
                id: "record.self",
                object: "object.self",
                digest: 13,
                inputs: [selfInput],
                recordLimits: limits
            )
        }

        let warning = try ProbeWarning(
            code: ProbeFixtures.exactText("org.voxelia.warning.probe"),
            severity: .interpretationAffecting,
            affectedSlot: fixed.slot,
            occurrence: 0
        )
        requireThrows(ProbeProvenanceError.duplicateWarning) {
            try ProbeFixtures.derived(
                id: "record.warning-duplicate",
                object: "object.warning-duplicate",
                digest: 15,
                inputs: [fixed],
                warnings: [warning, warning],
                recordLimits: limits
            )
        }
        let unknownSlotWarning = try ProbeWarning(
            code: ProbeFixtures.exactText("org.voxelia.warning.other-slot"),
            severity: .interpretationAffecting,
            affectedSlot: moving.slot,
            occurrence: 0
        )
        requireThrows(ProbeProvenanceError.unknownWarningSlot) {
            try ProbeFixtures.derived(
                id: "record.warning-unknown-slot",
                object: "object.warning-unknown-slot",
                digest: 151,
                inputs: [fixed],
                warnings: [unknownSlotWarning],
                recordLimits: limits
            )
        }

        let tinyLimits = try ProbeRecordLimits(
            maximumInputs: 1,
            maximumWarnings: 1,
            maximumLogicalBytes: 4_096
        )
        requireThrows(ProbeProvenanceError.inputLimitExceeded) {
            try ProbeFixtures.derived(
                id: "record.too-many-inputs",
                object: "object.too-many-inputs",
                digest: 16,
                inputs: [fixed, moving],
                recordLimits: tinyLimits
            )
        }
    }

    private static func testReferenceTagsAndGraphAdmission() throws {
        let recordLimits = try ProbeRecordLimits.probeDefault()
        let graphLimits = try ProbeGraphLimits.probeDefault()
        requireThrows(ProbeProvenanceError.invalidLimits) {
            try ProbeGraphLimits(
                maximumNodes: .max,
                maximumEdges: 1,
                maximumUnresolvedExternalReferences: 0,
                maximumResolvedDepth: 1,
                maximumLogicalBytes: 1
            )
        }
        let source = try ProbeFixtures.source(
            id: "record.source",
            object: "object.source",
            digest: 20,
            recordLimits: recordLimits
        )
        let localReference = ProbeParentReference.graphNode(source.id)
        let externalReference = ProbeParentReference.externalRecord(
            id: source.id,
            recordContentClaim: source.recordContentClaim
        )
        require(localReference.tag == .graphNode)
        require(externalReference.tag == .externalRecord)

        let localInput = try ProbeFixtures.input(
            role: "source",
            occurrence: 0,
            identity: source.subject,
            parent: localReference
        )
        let derived = try ProbeFixtures.derived(
            id: "record.derived",
            object: "object.derived",
            digest: 21,
            inputs: [localInput],
            recordLimits: recordLimits
        )
        let complete = try ProbeGraphAdmission.admit(
            records: [source, derived],
            roots: [derived.id],
            mode: .complete,
            limits: graphLimits
        )
        require(complete.assessment.isComplete)
        require(complete.assessment.resolutionState == .complete)
        require(complete.assessment.recordCount == 2)
        require(complete.assessment.edgeCount == 1)
        require(complete.assessment.maximumResolvedDepth == 2)
        let permissiveAdmission = try ProbeGraphAdmission.admit(
            records: [source, derived],
            roots: [derived.id],
            mode: .compact,
            limits: graphLimits
        )
        require(permissiveAdmission.assessment.admissionMode == .compact)
        require(permissiveAdmission.assessment.resolutionState == .complete)
        requireThrows(ProbeProvenanceError.duplicateRoot) {
            try ProbeGraphAdmission.admit(
                records: [source, derived],
                roots: [derived.id, derived.id],
                mode: .complete,
                limits: graphLimits
            )
        }
        requireThrows(ProbeProvenanceError.missingRoot) {
            try ProbeGraphAdmission.admit(
                records: [source, derived],
                roots: [] as [ProbeRecordID],
                mode: .complete,
                limits: graphLimits
            )
        }

        let absentID = try ProbeFixtures.recordID("record.external")
        let absentIdentity = try ProbeFixtures.identity("object.external", digest: 2_222)
        let compactInput = try ProbeFixtures.input(
            role: "external",
            occurrence: 0,
            identity: absentIdentity,
            parent: .externalRecord(
                id: absentID,
                recordContentClaim: ProbeFixtures.content(22)
            )
        )
        let compactRoot = try ProbeFixtures.derived(
            id: "record.compact",
            object: "object.compact",
            digest: 23,
            inputs: [compactInput],
            recordLimits: recordLimits
        )
        let compact = try ProbeGraphAdmission.admit(
            records: [compactRoot],
            roots: [compactRoot.id],
            mode: .compact,
            limits: graphLimits
        )
        require(!compact.assessment.isComplete)
        require(compact.assessment.resolutionState == .compact)
        require(compact.assessment.unresolvedExternalReferenceCount == 1)
        let repeatedExternalInput = try ProbeFixtures.input(
            role: "external",
            occurrence: 1,
            identity: absentIdentity,
            parent: .externalRecord(
                id: absentID,
                recordContentClaim: ProbeFixtures.content(22)
            )
        )
        let repeatedExternalRoot = try ProbeFixtures.derived(
            id: "record.repeated-external",
            object: "object.repeated-external",
            digest: 225,
            inputs: [compactInput, repeatedExternalInput],
            recordLimits: recordLimits
        )
        let repeatedExternalGraph = try ProbeGraphAdmission.admit(
            records: [repeatedExternalRoot],
            roots: [repeatedExternalRoot.id],
            mode: .compact,
            limits: graphLimits
        )
        require(repeatedExternalGraph.assessment.unresolvedExternalReferenceCount == 2)
        let oneUnresolvedReferenceLimits = try ProbeGraphLimits(
            maximumNodes: 16,
            maximumEdges: 32,
            maximumUnresolvedExternalReferences: 1,
            maximumResolvedDepth: 8,
            maximumLogicalBytes: 32_768
        )
        requireThrows(ProbeProvenanceError.unresolvedLimitExceeded) {
            try ProbeGraphAdmission.admit(
                records: [repeatedExternalRoot],
                roots: [repeatedExternalRoot.id],
                mode: .compact,
                limits: oneUnresolvedReferenceLimits
            )
        }
        let noUnresolvedLimits = try ProbeGraphLimits(
            maximumNodes: 16,
            maximumEdges: 32,
            maximumUnresolvedExternalReferences: 0,
            maximumResolvedDepth: 8,
            maximumLogicalBytes: 32_768
        )
        requireThrows(ProbeProvenanceError.unresolvedLimitExceeded) {
            try ProbeGraphAdmission.admit(
                records: [compactRoot],
                roots: [compactRoot.id],
                mode: .compact,
                limits: noUnresolvedLimits
            )
        }
        let conflictingCompactRoot = try ProbeFixtures.derived(
            id: "record.conflicting-compact",
            object: "object.conflicting-compact",
            digest: 223,
            inputs: [
                ProbeFixtures.input(
                    role: "first",
                    occurrence: 0,
                    identity: absentIdentity,
                    parent: .externalRecord(
                        id: absentID,
                        recordContentClaim: ProbeFixtures.content(22)
                    )
                ),
                ProbeFixtures.input(
                    role: "second",
                    occurrence: 0,
                    identity: absentIdentity,
                    parent: .externalRecord(
                        id: absentID,
                        recordContentClaim: ProbeFixtures.content(23)
                    )
                ),
            ],
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.conflictingExternalClaim) {
            try ProbeGraphAdmission.admit(
                records: [conflictingCompactRoot],
                roots: [conflictingCompactRoot.id],
                mode: .compact,
                limits: graphLimits
            )
        }
        let conflictingSubjectRoot = try ProbeFixtures.derived(
            id: "record.conflicting-external-subject",
            object: "object.conflicting-external-subject",
            digest: 224,
            inputs: [
                ProbeFixtures.input(
                    role: "first",
                    occurrence: 0,
                    identity: absentIdentity,
                    parent: .externalRecord(
                        id: absentID,
                        recordContentClaim: ProbeFixtures.content(22)
                    )
                ),
                ProbeFixtures.input(
                    role: "second",
                    occurrence: 0,
                    identity: ProbeFixtures.identity("object.other-external", digest: 2_223),
                    parent: .externalRecord(
                        id: absentID,
                        recordContentClaim: ProbeFixtures.content(22)
                    )
                ),
            ],
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.conflictingExternalClaim) {
            try ProbeGraphAdmission.admit(
                records: [conflictingSubjectRoot],
                roots: [conflictingSubjectRoot.id],
                mode: .compact,
                limits: graphLimits
            )
        }
        requireThrows(ProbeProvenanceError.unresolvedExternalParent) {
            try ProbeGraphAdmission.admit(
                records: [compactRoot],
                roots: [compactRoot.id],
                mode: .complete,
                limits: graphLimits
            )
        }

        let missingLocal = try ProbeFixtures.derived(
            id: "record.missing-local",
            object: "object.missing-local",
            digest: 24,
            inputs: [
                ProbeFixtures.input(
                    role: "source",
                    occurrence: 0,
                    identity: absentIdentity,
                    parent: .graphNode(absentID)
                )
            ],
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.missingLocalParent) {
            try ProbeGraphAdmission.admit(
                records: [missingLocal],
                roots: [missingLocal.id],
                mode: .compact,
                limits: graphLimits
            )
        }

        let mismatchedExternalInput = try ProbeFixtures.input(
            role: "source",
            occurrence: 0,
            identity: source.subject,
            parent: .externalRecord(
                id: source.id,
                recordContentClaim: ProbeFixtures.content(999)
            )
        )
        let mismatchedExternal = try ProbeFixtures.derived(
            id: "record.mismatched-external",
            object: "object.mismatched-external",
            digest: 25,
            inputs: [mismatchedExternalInput],
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.parentContentMismatch) {
            try ProbeGraphAdmission.admit(
                records: [source, mismatchedExternal],
                roots: [mismatchedExternal.id],
                mode: .complete,
                limits: graphLimits
            )
        }

        let wrongSubjectInput = try ProbeFixtures.input(
            role: "source",
            occurrence: 0,
            identity: absentIdentity,
            parent: .graphNode(source.id)
        )
        let wrongSubject = try ProbeFixtures.derived(
            id: "record.wrong-subject",
            object: "object.wrong-subject",
            digest: 26,
            inputs: [wrongSubjectInput],
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.parentSubjectMismatch) {
            try ProbeGraphAdmission.admit(
                records: [source, wrongSubject],
                roots: [wrongSubject.id],
                mode: .complete,
                limits: graphLimits
            )
        }
    }

    private static func testGraphCyclesLimitsAndTransactions() async throws {
        let recordLimits = try ProbeRecordLimits.probeDefault()
        let graphLimits = try ProbeGraphLimits.probeDefault()
        let source = try ProbeFixtures.source(
            id: "record.source",
            object: "object.source",
            digest: 30,
            recordLimits: recordLimits
        )
        let aID = try ProbeFixtures.recordID("record.a")
        let bID = try ProbeFixtures.recordID("record.b")
        let aIdentity = try ProbeFixtures.identity("object.a", digest: 1_031)
        let bIdentity = try ProbeFixtures.identity("object.b", digest: 1_032)
        let a = try ProbeFixtures.derived(
            id: "record.a",
            object: "object.a",
            digest: 31,
            inputs: [
                ProbeFixtures.input(
                    role: "b",
                    occurrence: 0,
                    identity: bIdentity,
                    parent: .graphNode(bID)
                )
            ],
            recordLimits: recordLimits
        )
        let b = try ProbeFixtures.derived(
            id: "record.b",
            object: "object.b",
            digest: 32,
            inputs: [
                ProbeFixtures.input(
                    role: "a",
                    occurrence: 0,
                    identity: aIdentity,
                    parent: .graphNode(aID)
                )
            ],
            recordLimits: recordLimits
        )
        require(a.subject == aIdentity)
        require(b.subject == bIdentity)
        requireThrows(ProbeProvenanceError.cycle) {
            try ProbeGraphAdmission.admit(
                records: [source, a, b],
                roots: [source.id],
                mode: .complete,
                limits: graphLimits
            )
        }

        let threeAID = try ProbeFixtures.recordID("record.three-a")
        let threeBID = try ProbeFixtures.recordID("record.three-b")
        let threeCID = try ProbeFixtures.recordID("record.three-c")
        let threeAIdentity = try ProbeFixtures.identity("object.three-a", digest: 1_133)
        let threeBIdentity = try ProbeFixtures.identity("object.three-b", digest: 1_134)
        let threeCIdentity = try ProbeFixtures.identity("object.three-c", digest: 1_135)
        let threeA = try ProbeFixtures.derived(
            id: "record.three-a",
            object: "object.three-a",
            digest: 133,
            inputs: [
                ProbeFixtures.input(
                    role: "previous",
                    occurrence: 0,
                    identity: threeBIdentity,
                    parent: .graphNode(threeBID)
                )
            ],
            recordLimits: recordLimits
        )
        let threeB = try ProbeFixtures.derived(
            id: "record.three-b",
            object: "object.three-b",
            digest: 134,
            inputs: [
                ProbeFixtures.input(
                    role: "previous",
                    occurrence: 0,
                    identity: threeCIdentity,
                    parent: .graphNode(threeCID)
                )
            ],
            recordLimits: recordLimits
        )
        let threeC = try ProbeFixtures.derived(
            id: "record.three-c",
            object: "object.three-c",
            digest: 135,
            inputs: [
                ProbeFixtures.input(
                    role: "previous",
                    occurrence: 0,
                    identity: threeAIdentity,
                    parent: .graphNode(threeAID)
                )
            ],
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.cycle) {
            try ProbeGraphAdmission.admit(
                records: [source, threeA, threeB, threeC],
                roots: [source.id],
                mode: .complete,
                limits: graphLimits
            )
        }

        let firstInput = try ProbeFixtures.input(
            role: "source",
            occurrence: 0,
            identity: source.subject,
            parent: .graphNode(source.id)
        )
        let first = try ProbeFixtures.derived(
            id: "record.first",
            object: "object.first",
            digest: 33,
            inputs: [firstInput],
            recordLimits: recordLimits
        )
        let secondInput = try ProbeFixtures.input(
            role: "first",
            occurrence: 0,
            identity: first.subject,
            parent: .graphNode(first.id)
        )
        let second = try ProbeFixtures.derived(
            id: "record.second",
            object: "object.second",
            digest: 34,
            inputs: [secondInput],
            recordLimits: recordLimits
        )
        let unrelated = try ProbeFixtures.source(
            id: "record.unrelated-sensitive",
            object: "object.unrelated-sensitive",
            digest: 3_399,
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.unreachableRecord) {
            try ProbeGraphAdmission.admit(
                records: [source, first, unrelated],
                roots: [first.id],
                mode: .complete,
                limits: graphLimits
            )
        }

        let shallowLimits = try ProbeGraphLimits(
            maximumNodes: 16,
            maximumEdges: 32,
            maximumUnresolvedExternalReferences: 8,
            maximumResolvedDepth: 2,
            maximumLogicalBytes: 32_768
        )
        requireThrows(ProbeProvenanceError.depthLimitExceeded) {
            try ProbeGraphAdmission.admit(
                records: [source, first, second],
                roots: [second.id],
                mode: .complete,
                limits: shallowLimits
            )
        }

        let nodeLimits = try ProbeGraphLimits(
            maximumNodes: 2,
            maximumEdges: 32,
            maximumUnresolvedExternalReferences: 8,
            maximumResolvedDepth: 8,
            maximumLogicalBytes: 32_768
        )
        requireThrows(ProbeProvenanceError.nodeLimitExceeded) {
            try ProbeGraphAdmission.admit(
                records: [source, first, second],
                roots: [second.id],
                mode: .complete,
                limits: nodeLimits
            )
        }

        let edgeLimits = try ProbeGraphLimits(
            maximumNodes: 16,
            maximumEdges: 1,
            maximumUnresolvedExternalReferences: 8,
            maximumResolvedDepth: 8,
            maximumLogicalBytes: 32_768
        )
        requireThrows(ProbeProvenanceError.edgeLimitExceeded) {
            try ProbeGraphAdmission.admit(
                records: [source, first, second],
                roots: [second.id],
                mode: .complete,
                limits: edgeLimits
            )
        }

        let byteLimits = try ProbeGraphLimits(
            maximumNodes: 16,
            maximumEdges: 32,
            maximumUnresolvedExternalReferences: 8,
            maximumResolvedDepth: 8,
            maximumLogicalBytes: source.logicalByteCount - 1
        )
        requireThrows(ProbeProvenanceError.logicalByteLimitExceeded) {
            try ProbeGraphAdmission.admit(
                records: [source],
                roots: [source.id],
                mode: .complete,
                limits: byteLimits
            )
        }

        requireThrows(ProbeProvenanceError.duplicateRecordID) {
            try ProbeGraphAdmission.admit(
                records: [source, source],
                roots: [source.id],
                mode: .complete,
                limits: graphLimits
            )
        }
        let conflictingSource = try ProbeFixtures.source(
            id: "record.source",
            object: "object.source.changed",
            digest: 35,
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.conflictingRecordID) {
            try ProbeGraphAdmission.admit(
                records: [source, conflictingSource],
                roots: [source.id],
                mode: .complete,
                limits: graphLimits
            )
        }

        let left = try ProbeFixtures.derived(
            id: "record.left",
            object: "object.left",
            digest: 36,
            inputs: [firstInput],
            recordLimits: recordLimits
        )
        let right = try ProbeFixtures.derived(
            id: "record.right",
            object: "object.right",
            digest: 37,
            inputs: [firstInput],
            recordLimits: recordLimits
        )
        let diamond = try ProbeFixtures.derived(
            id: "record.diamond",
            object: "object.diamond",
            digest: 38,
            inputs: [
                ProbeFixtures.input(
                    role: "left",
                    occurrence: 0,
                    identity: left.subject,
                    parent: .graphNode(left.id)
                ),
                ProbeFixtures.input(
                    role: "right",
                    occurrence: 0,
                    identity: right.subject,
                    parent: .graphNode(right.id)
                ),
            ],
            recordLimits: recordLimits
        )
        let diamondGraph = try ProbeGraphAdmission.admit(
            records: [source, left, right, diamond],
            roots: [diamond.id],
            mode: .complete,
            limits: graphLimits
        )
        require(diamondGraph.assessment.visitedRecordCount == 4)
        require(diamondGraph.assessment.edgeCount == 4)
        require(diamondGraph.assessment.maximumResolvedDepth == 3)

        var overflowingBudget = ProbeCheckedBudget(.max)
        requireThrows(ProbeProvenanceError.arithmeticOverflow) {
            try overflowingBudget.add(1)
        }

        let initial = try ProbeGraphAdmission.admit(
            records: [source, first],
            roots: [first.id],
            mode: .complete,
            limits: graphLimits,
            resolverRevision: 23
        )
        let replacementRoot = try ProbeFixtures.source(
            id: "record.replacement-root",
            object: "object.replacement-root",
            digest: 3_040,
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.invalidLimits) {
            try ProbeGraphStore(initial, maximumHistoricalRecords: 1)
        }
        requireThrows(ProbeProvenanceError.invalidLimits) {
            try ProbeGraphStore(initial, maximumHistoricalRecords: .max)
        }
        let limitedStore = try ProbeGraphStore(
            initial,
            maximumHistoricalRecords: 2
        )
        do {
            try await limitedStore.replace(
                records: [replacementRoot],
                roots: [replacementRoot.id],
                mode: .complete,
                limits: graphLimits
            )
            preconditionFailure("historical record limit unexpectedly expanded")
        } catch let error as ProbeProvenanceError {
            require(error == .historicalRecordLimitExceeded)
        }
        let afterHistoricalLimit = await limitedStore.snapshot()
        require(afterHistoricalLimit == initial)

        let store = try ProbeGraphStore(
            initial,
            maximumHistoricalRecords: 16
        )
        let conflictingStoredSource = try ProbeRecord(
            id: source.id,
            recordContentClaim: source.recordContentClaim,
            kind: .source,
            subject: source.subject,
            software: ProbeFixtures.software(build: "replacement-conflict"),
            activity: .origin,
            inputs: [] as [ProbeInput],
            warnings: [] as [ProbeWarning],
            validationClaim: ProbeFixtures.unknownValidation(),
            limits: recordLimits
        )
        do {
            try await store.replace(
                records: [conflictingStoredSource],
                roots: [conflictingStoredSource.id],
                mode: .complete,
                limits: graphLimits
            )
            preconditionFailure("conflicting immutable replacement unexpectedly succeeded")
        } catch let error as ProbeProvenanceError {
            require(error == .conflictingRecordID)
        }
        let afterConflict = await store.snapshot()
        require(afterConflict == initial)

        do {
            try await store.replace(
                records: [source, a, b],
                roots: [source.id],
                mode: .complete,
                limits: graphLimits
            )
            preconditionFailure("cyclic replacement unexpectedly succeeded")
        } catch let error as ProbeProvenanceError {
            require(error == .cycle)
        }
        let afterCycle = await store.snapshot()
        require(afterCycle == initial)

        do {
            try await store.replace(
                records: [source, first, second],
                roots: [second.id],
                mode: .complete,
                limits: graphLimits,
                cancelAfterWork: 2
            )
            preconditionFailure("cancelled replacement unexpectedly succeeded")
        } catch let error as ProbeProvenanceError {
            require(error == .cancelled)
        }
        let afterCancellation = await store.snapshot()
        require(afterCancellation == initial)

        try await store.replace(
            records: [replacementRoot],
            roots: [replacementRoot.id],
            mode: .complete,
            limits: graphLimits
        )
        let afterDrop = await store.snapshot()
        require(afterDrop.roots == [replacementRoot.id])
        do {
            try await store.replace(
                records: [conflictingStoredSource],
                roots: [conflictingStoredSource.id],
                mode: .complete,
                limits: graphLimits
            )
            preconditionFailure("historical ID conflict unexpectedly succeeded")
        } catch let error as ProbeProvenanceError {
            require(error == .conflictingRecordID)
        }
        let afterHistoricalConflict = await store.snapshot()
        require(afterHistoricalConflict == afterDrop)

        try await store.replace(
            records: [source, first, second],
            roots: [second.id],
            mode: .complete,
            limits: graphLimits
        )
        let afterSuccess = await store.snapshot()
        require(afterSuccess.assessment.resolverRevision == 23)
        require(afterSuccess.roots == [second.id])
    }

    private static func testClaimsRemainSeparateFromEvidence() throws {
        let recordLimits = try ProbeRecordLimits.probeDefault()
        let source = try ProbeFixtures.source(
            id: "record.source",
            object: "object.source",
            digest: 40,
            recordLimits: recordLimits
        )
        let evidenceID = try ProbeEvidenceID(value: ProbeFixtures.exactText("evidence.1"))
        let validation = try ProbeValidationClaim(
            level: .diagnosticReady,
            evidenceID: evidenceID
        )
        let input = try ProbeFixtures.input(
            role: "source",
            occurrence: 0,
            identity: source.subject,
            parent: .graphNode(source.id)
        )
        let record = try ProbeFixtures.derived(
            id: "record.validated-claim",
            object: "object.validated-claim",
            digest: 41,
            inputs: [input],
            validation: validation,
            recordLimits: recordLimits
        )
        let context = try ProbeAssuranceContext(
            releaseID: ProbeFixtures.exactText("voxelia.1"),
            policyID: ProbePolicyID(value: ProbeFixtures.exactText("policy.diagnostic")),
            requiredCapabilityClassID: ProbeFixtures.exactText(
                "apple-silicon-reference"
            )
        )

        requireThrows(ProbeProvenanceError.evidenceDenied) {
            try ProbeAssuranceEvaluator.evaluate(
                record: record,
                evidence: nil,
                context: context
            )
        }

        guard case .operation(let operation, let execution) = record.activity else {
            preconditionFailure("fixture was not an operation record")
        }
        let matchingEvidence = ProbeValidationEvidence(
            evidenceID: evidenceID,
            exactRecord: record,
            recordID: record.id,
            recordContentClaim: record.recordContentClaim,
            approvedLevel: .diagnosticReady,
            operationID: operation.operationID,
            implementationVersion: operation.implementationVersion,
            profileID: execution.profileID,
            backendID: execution.backendID,
            capabilityClassID: execution.capabilityClassID,
            releaseID: context.releaseID,
            policyID: context.policyID,
            isExpired: false,
            isRevoked: false
        )
        let assurance = try ProbeAssuranceEvaluator.evaluate(
            record: record,
            evidence: matchingEvidence,
            context: context
        )
        require(assurance.level == .diagnosticReady)
        let changedRecord = try ProbeFixtures.derived(
            id: "record.validated-claim",
            object: "object.changed-subject",
            digest: 41,
            inputs: [input],
            validation: validation,
            recordLimits: recordLimits
        )
        requireThrows(ProbeProvenanceError.evidenceDenied) {
            try ProbeAssuranceEvaluator.evaluate(
                record: changedRecord,
                evidence: matchingEvidence,
                context: context
            )
        }

        let revoked = ProbeValidationEvidence(
            evidenceID: matchingEvidence.evidenceID,
            exactRecord: matchingEvidence.exactRecord,
            recordID: matchingEvidence.recordID,
            recordContentClaim: matchingEvidence.recordContentClaim,
            approvedLevel: matchingEvidence.approvedLevel,
            operationID: matchingEvidence.operationID,
            implementationVersion: matchingEvidence.implementationVersion,
            profileID: matchingEvidence.profileID,
            backendID: matchingEvidence.backendID,
            capabilityClassID: matchingEvidence.capabilityClassID,
            releaseID: matchingEvidence.releaseID,
            policyID: matchingEvidence.policyID,
            isExpired: false,
            isRevoked: true
        )
        requireThrows(ProbeProvenanceError.evidenceDenied) {
            try ProbeAssuranceEvaluator.evaluate(
                record: record,
                evidence: revoked,
                context: context
            )
        }

        let mismatchedEvidence: [ProbeValidationEvidence] = [
            ProbeValidationEvidence(
                evidenceID: matchingEvidence.evidenceID,
                exactRecord: matchingEvidence.exactRecord,
                recordID: matchingEvidence.recordID,
                recordContentClaim: try ProbeFixtures.content(9_999),
                approvedLevel: matchingEvidence.approvedLevel,
                operationID: matchingEvidence.operationID,
                implementationVersion: matchingEvidence.implementationVersion,
                profileID: matchingEvidence.profileID,
                backendID: matchingEvidence.backendID,
                capabilityClassID: matchingEvidence.capabilityClassID,
                releaseID: matchingEvidence.releaseID,
                policyID: matchingEvidence.policyID,
                isExpired: false,
                isRevoked: false
            ),
            ProbeValidationEvidence(
                evidenceID: matchingEvidence.evidenceID,
                exactRecord: matchingEvidence.exactRecord,
                recordID: matchingEvidence.recordID,
                recordContentClaim: matchingEvidence.recordContentClaim,
                approvedLevel: .validated,
                operationID: matchingEvidence.operationID,
                implementationVersion: matchingEvidence.implementationVersion,
                profileID: matchingEvidence.profileID,
                backendID: matchingEvidence.backendID,
                capabilityClassID: matchingEvidence.capabilityClassID,
                releaseID: matchingEvidence.releaseID,
                policyID: matchingEvidence.policyID,
                isExpired: false,
                isRevoked: false
            ),
            ProbeValidationEvidence(
                evidenceID: matchingEvidence.evidenceID,
                exactRecord: matchingEvidence.exactRecord,
                recordID: matchingEvidence.recordID,
                recordContentClaim: matchingEvidence.recordContentClaim,
                approvedLevel: matchingEvidence.approvedLevel,
                operationID: matchingEvidence.operationID,
                implementationVersion: matchingEvidence.implementationVersion,
                profileID: try ProbeFixtures.exactText("preview"),
                backendID: matchingEvidence.backendID,
                capabilityClassID: matchingEvidence.capabilityClassID,
                releaseID: matchingEvidence.releaseID,
                policyID: matchingEvidence.policyID,
                isExpired: false,
                isRevoked: false
            ),
            ProbeValidationEvidence(
                evidenceID: matchingEvidence.evidenceID,
                exactRecord: matchingEvidence.exactRecord,
                recordID: matchingEvidence.recordID,
                recordContentClaim: matchingEvidence.recordContentClaim,
                approvedLevel: matchingEvidence.approvedLevel,
                operationID: matchingEvidence.operationID,
                implementationVersion: matchingEvidence.implementationVersion,
                profileID: matchingEvidence.profileID,
                backendID: try ProbeFixtures.exactText("metal.unreviewed"),
                capabilityClassID: matchingEvidence.capabilityClassID,
                releaseID: matchingEvidence.releaseID,
                policyID: matchingEvidence.policyID,
                isExpired: false,
                isRevoked: false
            ),
            ProbeValidationEvidence(
                evidenceID: matchingEvidence.evidenceID,
                exactRecord: matchingEvidence.exactRecord,
                recordID: matchingEvidence.recordID,
                recordContentClaim: matchingEvidence.recordContentClaim,
                approvedLevel: matchingEvidence.approvedLevel,
                operationID: matchingEvidence.operationID,
                implementationVersion: matchingEvidence.implementationVersion,
                profileID: matchingEvidence.profileID,
                backendID: matchingEvidence.backendID,
                capabilityClassID: try ProbeFixtures.exactText("other-capability"),
                releaseID: matchingEvidence.releaseID,
                policyID: matchingEvidence.policyID,
                isExpired: false,
                isRevoked: false
            ),
            ProbeValidationEvidence(
                evidenceID: matchingEvidence.evidenceID,
                exactRecord: matchingEvidence.exactRecord,
                recordID: matchingEvidence.recordID,
                recordContentClaim: matchingEvidence.recordContentClaim,
                approvedLevel: matchingEvidence.approvedLevel,
                operationID: matchingEvidence.operationID,
                implementationVersion: matchingEvidence.implementationVersion,
                profileID: matchingEvidence.profileID,
                backendID: matchingEvidence.backendID,
                capabilityClassID: matchingEvidence.capabilityClassID,
                releaseID: matchingEvidence.releaseID,
                policyID: matchingEvidence.policyID,
                isExpired: true,
                isRevoked: false
            ),
        ]
        for mismatched in mismatchedEvidence {
            requireThrows(ProbeProvenanceError.evidenceDenied) {
                try ProbeAssuranceEvaluator.evaluate(
                    record: record,
                    evidence: mismatched,
                    context: context
                )
            }
        }

        let wrongPolicy = try ProbeAssuranceContext(
            releaseID: context.releaseID,
            policyID: ProbePolicyID(value: ProbeFixtures.exactText("policy.preview")),
            requiredCapabilityClassID: context.requiredCapabilityClassID
        )
        requireThrows(ProbeProvenanceError.evidenceDenied) {
            try ProbeAssuranceEvaluator.evaluate(
                record: record,
                evidence: matchingEvidence,
                context: wrongPolicy
            )
        }

        let wrongRelease = try ProbeAssuranceContext(
            releaseID: ProbeFixtures.exactText("voxelia.2"),
            policyID: context.policyID,
            requiredCapabilityClassID: context.requiredCapabilityClassID
        )
        requireThrows(ProbeProvenanceError.evidenceDenied) {
            try ProbeAssuranceEvaluator.evaluate(
                record: record,
                evidence: matchingEvidence,
                context: wrongRelease
            )
        }

        let lifecycle = try ProbeLifecycleClaim.deprecated(
            code: ProbeFixtures.exactText("superseded-by-v2")
        )
        require(validation.level == .diagnosticReady)
        if case .deprecated = lifecycle {
            // Validation and lifecycle are intentionally independent axes.
        } else {
            preconditionFailure("lifecycle fixture changed")
        }
    }

    private static func testAtomicPublication() async throws {
        let recordLimits = try ProbeRecordLimits.probeDefault()
        let graphLimits = try ProbeGraphLimits.probeDefault()
        let source = try ProbeFixtures.source(
            id: "record.source",
            object: "object.source",
            digest: 50,
            recordLimits: recordLimits
        )
        let graph = try ProbeGraphAdmission.admit(
            records: [source],
            roots: [source.id],
            mode: .complete,
            limits: graphLimits
        )
        let snapshotID = try ProbeSnapshotID(value: ProbeFixtures.exactText("snapshot.7"))
        let outputID = try ProbeOutputID(value: ProbeFixtures.exactText("output.1"))
        let outputEvidence = ProbeOutputIdentityEvidence(
            outputID: outputID,
            identity: source.subject,
            generation: 7,
            snapshotID: snapshotID
        )
        let cachePolicyID = try ProbePolicyID(
            value: ProbeFixtures.exactText("policy.cache.private")
        )
        let cacheAuthorization = ProbeCachePublicationAuthorization(
            policyID: cachePolicyID,
            outputID: outputID,
            identity: source.subject,
            provenanceRoot: source.id,
            rootContentClaim: source.recordContentClaim,
            exactRoot: source,
            exactGraph: graph,
            generation: 7,
            snapshotID: snapshotID
        )
        let candidate = ProbePublicationCandidate(
            outputID: outputID,
            identity: source.subject,
            outputIdentityEvidence: outputEvidence,
            provenanceRoot: source.id,
            graph: graph,
            assurance: nil,
            generation: 7,
            snapshotID: snapshotID,
            cacheAuthorization: cacheAuthorization
        )

        let changedCacheRoot = try ProbeRecord(
            id: source.id,
            recordContentClaim: source.recordContentClaim,
            kind: .source,
            subject: source.subject,
            software: ProbeFixtures.software(build: "build.changed-cache-root"),
            activity: .origin,
            inputs: [] as [ProbeInput],
            warnings: [] as [ProbeWarning],
            validationClaim: ProbeFixtures.unknownValidation(),
            limits: recordLimits
        )
        let changedCacheGraph = try ProbeGraphAdmission.admit(
            records: [changedCacheRoot],
            roots: [changedCacheRoot.id],
            mode: .complete,
            limits: graphLimits
        )
        let cacheReplayCandidate = ProbePublicationCandidate(
            outputID: outputID,
            identity: changedCacheRoot.subject,
            outputIdentityEvidence: outputEvidence,
            provenanceRoot: changedCacheRoot.id,
            graph: changedCacheGraph,
            assurance: nil,
            generation: 7,
            snapshotID: snapshotID,
            cacheAuthorization: cacheAuthorization
        )
        let cacheReplayPublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits,
            authorizedCachePolicyID: cachePolicyID
        )
        do {
            _ = try await cacheReplayPublisher.publish(cacheReplayCandidate)
            preconditionFailure("changed-graph cache authorization replay succeeded")
        } catch let error as ProbePublicationError {
            require(error == .cacheUnauthorized)
        }
        let cacheReplayState = await cacheReplayPublisher.snapshot()
        require(cacheReplayState == .empty)

        let faultCases: [(Bool, Bool, Bool, UInt64, ProbeSnapshotID, ProbePublicationError)] = [
            (true, false, false, 7, snapshotID, .cancelled),
            (false, true, false, 7, snapshotID, .failed),
            (false, false, true, 7, snapshotID, .targetRemoved),
            (false, false, false, 6, snapshotID, .staleGeneration),
            (
                false,
                false,
                false,
                7,
                try ProbeSnapshotID(value: ProbeFixtures.exactText("snapshot.changed")),
                .snapshotChanged
            ),
        ]

        for fault in faultCases {
            let publisher = ProbePublisher(
                currentGeneration: 7,
                currentSnapshotID: snapshotID,
                currentResolverRevision: 0,
                approvedGraphLimits: graphLimits,
                authorizedCachePolicyID: cachePolicyID
            )
            let faultCandidate = ProbePublicationCandidate(
                outputID: candidate.outputID,
                identity: candidate.identity,
                outputIdentityEvidence: candidate.outputIdentityEvidence,
                provenanceRoot: candidate.provenanceRoot,
                graph: candidate.graph,
                assurance: candidate.assurance,
                generation: fault.3,
                snapshotID: fault.4,
                cacheAuthorization: candidate.cacheAuthorization
            )
            do {
                _ = try await publisher.publish(
                    faultCandidate,
                    cancelled: fault.0,
                    failed: fault.1,
                    targetRemoved: fault.2
                )
                preconditionFailure("fault publication unexpectedly succeeded")
            } catch let error as ProbePublicationError {
                require(error == fault.5)
            }
            let faultState = await publisher.snapshot()
            require(faultState == .empty)
        }

        let validationPublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits,
            authorizedCachePolicyID: cachePolicyID
        )
        do {
            _ = try await validationPublisher.publish(
                candidate,
                requireValidationAssurance: true
            )
            preconditionFailure("unassured publication unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .validationDenied)
        }
        let validationFailureState = await validationPublisher.snapshot()
        require(validationFailureState == .empty)

        let assuredEvidenceID = try ProbeEvidenceID(
            value: ProbeFixtures.exactText("evidence.publication")
        )
        let assuredClaim = try ProbeValidationClaim(
            level: .diagnosticReady,
            evidenceID: assuredEvidenceID
        )
        let assuredInput = try ProbeFixtures.input(
            role: "source",
            occurrence: 0,
            identity: source.subject,
            parent: .graphNode(source.id)
        )
        let assuredRecord = try ProbeFixtures.derived(
            id: "record.assured-publication",
            object: "object.assured-publication",
            digest: 5_053,
            inputs: [assuredInput],
            validation: assuredClaim,
            recordLimits: recordLimits
        )
        let assuredGraph = try ProbeGraphAdmission.admit(
            records: [source, assuredRecord],
            roots: [assuredRecord.id],
            mode: .complete,
            limits: graphLimits
        )
        guard
            case .operation(let assuredOperation, let assuredExecution) =
                assuredRecord.activity
        else {
            preconditionFailure("assured fixture was not an operation record")
        }
        let assuranceContext = try ProbeAssuranceContext(
            releaseID: ProbeFixtures.exactText("voxelia.1"),
            policyID: ProbePolicyID(
                value: ProbeFixtures.exactText("policy.diagnostic")
            ),
            requiredCapabilityClassID: assuredExecution.capabilityClassID
        )
        let assuranceEvidence = ProbeValidationEvidence(
            evidenceID: assuredEvidenceID,
            exactRecord: assuredRecord,
            recordID: assuredRecord.id,
            recordContentClaim: assuredRecord.recordContentClaim,
            approvedLevel: .diagnosticReady,
            operationID: assuredOperation.operationID,
            implementationVersion: assuredOperation.implementationVersion,
            profileID: assuredExecution.profileID,
            backendID: assuredExecution.backendID,
            capabilityClassID: assuredExecution.capabilityClassID,
            releaseID: assuranceContext.releaseID,
            policyID: assuranceContext.policyID,
            isExpired: false,
            isRevoked: false
        )
        let assurance = try ProbeAssuranceEvaluator.evaluate(
            record: assuredRecord,
            evidence: assuranceEvidence,
            context: assuranceContext
        )
        let assuredOutputID = try ProbeOutputID(
            value: ProbeFixtures.exactText("output.assured")
        )
        let assuredCandidate = ProbePublicationCandidate(
            outputID: assuredOutputID,
            identity: assuredRecord.subject,
            outputIdentityEvidence: ProbeOutputIdentityEvidence(
                outputID: assuredOutputID,
                identity: assuredRecord.subject,
                generation: 7,
                snapshotID: snapshotID
            ),
            provenanceRoot: assuredRecord.id,
            graph: assuredGraph,
            assurance: assurance,
            generation: 7,
            snapshotID: snapshotID,
            cacheAuthorization: nil
        )
        let wrongAssuranceContext = try ProbeAssuranceContext(
            releaseID: assuranceContext.releaseID,
            policyID: ProbePolicyID(
                value: ProbeFixtures.exactText("policy.different-purpose")
            ),
            requiredCapabilityClassID: assuranceContext.requiredCapabilityClassID
        )
        let mismatchedAssurancePublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits,
            authorizedAssuranceContext: wrongAssuranceContext
        )
        do {
            _ = try await mismatchedAssurancePublisher.publish(assuredCandidate)
            preconditionFailure("cross-purpose assurance unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .validationDenied)
        }
        let mismatchedAssuranceState = await mismatchedAssurancePublisher.snapshot()
        require(mismatchedAssuranceState == .empty)

        let changedAssuredRecord = try ProbeFixtures.derived(
            id: "record.assured-publication",
            object: "object.changed-after-assurance",
            digest: 5_053,
            inputs: [assuredInput],
            validation: assuredClaim,
            recordLimits: recordLimits
        )
        let changedAssuredGraph = try ProbeGraphAdmission.admit(
            records: [source, changedAssuredRecord],
            roots: [changedAssuredRecord.id],
            mode: .complete,
            limits: graphLimits
        )
        let changedAssuredCandidate = ProbePublicationCandidate(
            outputID: assuredOutputID,
            identity: changedAssuredRecord.subject,
            outputIdentityEvidence: ProbeOutputIdentityEvidence(
                outputID: assuredOutputID,
                identity: changedAssuredRecord.subject,
                generation: 7,
                snapshotID: snapshotID
            ),
            provenanceRoot: changedAssuredRecord.id,
            graph: changedAssuredGraph,
            assurance: assurance,
            generation: 7,
            snapshotID: snapshotID,
            cacheAuthorization: nil
        )
        let replayAssurancePublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits,
            authorizedAssuranceContext: assuranceContext
        )
        do {
            _ = try await replayAssurancePublisher.publish(changedAssuredCandidate)
            preconditionFailure("changed-record assurance replay unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .validationDenied)
        }
        let replayAssuranceState = await replayAssurancePublisher.snapshot()
        require(replayAssuranceState == .empty)

        let assuredPublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits,
            authorizedAssuranceContext: assuranceContext
        )
        let assuredBundle = try await assuredPublisher.publish(
            assuredCandidate,
            requireValidationAssurance: true
        )
        require(assuredBundle.assurance == assurance)

        let staleResolverGraph = try ProbeGraphAdmission.admit(
            records: [source],
            roots: [source.id],
            mode: .complete,
            limits: graphLimits,
            resolverRevision: 1
        )
        let staleResolverCandidate = ProbePublicationCandidate(
            outputID: outputID,
            identity: source.subject,
            outputIdentityEvidence: outputEvidence,
            provenanceRoot: source.id,
            graph: staleResolverGraph,
            assurance: nil,
            generation: 7,
            snapshotID: snapshotID,
            cacheAuthorization: nil
        )
        let staleResolverPublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits
        )
        do {
            _ = try await staleResolverPublisher.publish(staleResolverCandidate)
            preconditionFailure("stale resolver graph unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .snapshotChanged)
        }
        let staleResolverState = await staleResolverPublisher.snapshot()
        require(staleResolverState == .empty)

        let unrelatedRoot = try ProbeFixtures.source(
            id: "record.unrelated-publication-root",
            object: "object.unrelated-publication-root",
            digest: 5_054,
            recordLimits: recordLimits
        )
        let multiRootGraph = try ProbeGraphAdmission.admit(
            records: [source, unrelatedRoot],
            roots: [source.id, unrelatedRoot.id],
            mode: .complete,
            limits: graphLimits
        )
        let multiRootCandidate = ProbePublicationCandidate(
            outputID: outputID,
            identity: source.subject,
            outputIdentityEvidence: outputEvidence,
            provenanceRoot: source.id,
            graph: multiRootGraph,
            assurance: nil,
            generation: 7,
            snapshotID: snapshotID,
            cacheAuthorization: nil
        )
        let multiRootPublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits
        )
        do {
            _ = try await multiRootPublisher.publish(multiRootCandidate)
            preconditionFailure("unmapped extra root unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .identityMismatch)
        }
        let multiRootState = await multiRootPublisher.snapshot()
        require(multiRootState == .empty)

        let externalID = try ProbeFixtures.recordID("record.external")
        let externalIdentity = try ProbeFixtures.identity("object.external", digest: 8_001)
        let compactRoot = try ProbeFixtures.derived(
            id: "record.compact-root",
            object: "object.compact-root",
            digest: 52,
            inputs: [
                ProbeFixtures.input(
                    role: "source",
                    occurrence: 0,
                    identity: externalIdentity,
                    parent: .externalRecord(
                        id: externalID,
                        recordContentClaim: ProbeFixtures.content(51)
                    )
                )
            ],
            recordLimits: recordLimits
        )
        let compactGraph = try ProbeGraphAdmission.admit(
            records: [compactRoot],
            roots: [compactRoot.id],
            mode: .compact,
            limits: graphLimits
        )
        let compactCandidate = ProbePublicationCandidate(
            outputID: outputID,
            identity: compactRoot.subject,
            outputIdentityEvidence: ProbeOutputIdentityEvidence(
                outputID: outputID,
                identity: compactRoot.subject,
                generation: 7,
                snapshotID: snapshotID
            ),
            provenanceRoot: compactRoot.id,
            graph: compactGraph,
            assurance: nil,
            generation: 7,
            snapshotID: snapshotID,
            cacheAuthorization: nil
        )
        let compactPublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits
        )
        do {
            _ = try await compactPublisher.publish(compactCandidate)
            preconditionFailure("incomplete graph publication unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .incompleteGraph)
        }
        let compactFailureState = await compactPublisher.snapshot()
        require(compactFailureState == .empty)

        let wrongIdentityPublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits,
            authorizedCachePolicyID: cachePolicyID
        )
        let wrongIdentityCandidate = ProbePublicationCandidate(
            outputID: candidate.outputID,
            identity: try ProbeFixtures.identity("object.other", digest: 99),
            outputIdentityEvidence: candidate.outputIdentityEvidence,
            provenanceRoot: candidate.provenanceRoot,
            graph: candidate.graph,
            assurance: nil,
            generation: 7,
            snapshotID: snapshotID,
            cacheAuthorization: candidate.cacheAuthorization
        )
        do {
            _ = try await wrongIdentityPublisher.publish(wrongIdentityCandidate)
            preconditionFailure("identity mismatch unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .identityMismatch)
        }
        let identityFailureState = await wrongIdentityPublisher.snapshot()
        require(identityFailureState == .empty)

        let unauthorizedCachePublisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits
        )
        do {
            _ = try await unauthorizedCachePublisher.publish(candidate)
            preconditionFailure("unauthorized cache publication unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .cacheUnauthorized)
        }
        let unauthorizedCacheState = await unauthorizedCachePublisher.snapshot()
        require(unauthorizedCacheState == .empty)

        let publisher = ProbePublisher(
            currentGeneration: 7,
            currentSnapshotID: snapshotID,
            currentResolverRevision: 0,
            approvedGraphLimits: graphLimits,
            authorizedCachePolicyID: cachePolicyID
        )
        let published = try await publisher.publish(candidate)
        require(published.identity == source.subject)
        require(published.provenanceRoot == source.id)
        let state = await publisher.snapshot()
        require(state.outputCount == 1)
        require(state.provenanceCount == 1)
        require(state.cacheAliasCount == 1)

        do {
            _ = try await publisher.publish(candidate)
            preconditionFailure("duplicate publication unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .alreadyPublished)
        }

        let cacheReadEvidence = ProbeCacheReadEvidence(
            policyID: cachePolicyID,
            output: outputEvidence,
            provenanceRoot: source.id,
            rootContentClaim: source.recordContentClaim,
            exactRoot: source,
            exactGraph: graph,
            resolverRevision: graph.assessment.resolverRevision
        )
        _ = try await publisher.cacheHit(cacheReadEvidence)
        do {
            _ = try await publisher.cacheHit(
                ProbeCacheReadEvidence(
                    policyID: cachePolicyID,
                    output: outputEvidence,
                    provenanceRoot: source.id,
                    rootContentClaim: source.recordContentClaim,
                    exactRoot: changedCacheRoot,
                    exactGraph: changedCacheGraph,
                    resolverRevision: graph.assessment.resolverRevision
                )
            )
            preconditionFailure("changed-graph cache read replay succeeded")
        } catch let error as ProbePublicationError {
            require(error == .cacheMismatch)
        }
        do {
            _ = try await publisher.cacheHit(
                ProbeCacheReadEvidence(
                    policyID: ProbePolicyID(
                        value: ProbeFixtures.exactText("policy.cache.other")
                    ),
                    output: outputEvidence,
                    provenanceRoot: source.id,
                    rootContentClaim: source.recordContentClaim,
                    exactRoot: source,
                    exactGraph: graph,
                    resolverRevision: graph.assessment.resolverRevision
                )
            )
            preconditionFailure("cross-policy cache read unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .cacheMismatch)
        }
        do {
            _ = try await publisher.cacheHit(
                ProbeCacheReadEvidence(
                    policyID: cachePolicyID,
                    output: ProbeOutputIdentityEvidence(
                        outputID: try ProbeOutputID(
                            value: ProbeFixtures.exactText("output.substituted")
                        ),
                        identity: source.subject,
                        generation: 7,
                        snapshotID: snapshotID
                    ),
                    provenanceRoot: source.id,
                    rootContentClaim: source.recordContentClaim,
                    exactRoot: source,
                    exactGraph: graph,
                    resolverRevision: graph.assessment.resolverRevision
                ),
            )
            preconditionFailure("cache substitution unexpectedly succeeded")
        } catch let error as ProbePublicationError {
            require(error == .cacheMismatch)
        }
    }

    private static func testRedactedDiagnostics() throws {
        let patientSentinel = "Patient Jane Doe / SOP 1.2.840.113619"
        let sensitive = try ProbeExactText(patientSentinel)
        let sensitiveID = ProbeRecordID(value: sensitive)
        var values = [
            String(describing: sensitive),
            String(reflecting: sensitive),
            String(describing: sensitiveID),
            String(reflecting: sensitiveID),
            String(describing: ProbeProvenanceError.parentContentMismatch),
            String(reflecting: ProbePublicationError.identityMismatch),
        ]
        values.append(
            contentsOf: Mirror(reflecting: sensitive).children.map {
                String(reflecting: $0.value)
            }
        )
        var dumped = ""
        dump(sensitive, to: &dumped)
        values.append(dumped)
        for value in values {
            require(!value.contains(patientSentinel))
            require(!value.contains("Jane Doe"))
            require(!value.contains("1.2.840"))
        }
    }
}
