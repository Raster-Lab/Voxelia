// SPDX-License-Identifier: MIT

/// An error raised while validating a provenance record aggregate.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// identifiers, roles, codes or record content.
public enum ProvenanceRecordError: Error, Sendable, Equatable {
    case activityKindMismatch
    case unexpectedInputs
    case emptyInputSequence
    case unexpectedInputSequence
    case duplicateInputOccurrence
    case duplicateWarning
}

/// The closed activity state of one provenance record per `ADR-0038`
/// and `ADR-0058`.
///
/// An execution claim without an operation claim — and an origin
/// silently carrying an execution — are structurally impossible.
public enum ProvenanceActivity: Sendable, Hashable {
    case origin
    case operation(OperationProvenance, ExecutionProvenanceClaim)
}

/// One immutable subject-bound provenance record claim per `ADR-0038`
/// and `ADR-0058`.
///
/// The record asserts that its subject snapshot is an origin or the
/// completed result of an asserted operation and execution, with
/// ordered role-bearing input claims, aggregated warnings and a
/// validation claim. Successful construction proves structural validity
/// only: no verification, trust, graph completeness or cache
/// suitability is encoded or implied. Provenance is sensitive-derived
/// even without pixel values and must not be logged, exported or
/// deduplicated across privacy domains by default. The stable coding is
/// owned by the future canonical provenance-record projection decision,
/// and graph admission is a separate contract.
public struct ProvenanceRecord: Sendable, Hashable {
    public let id: ProvenanceID
    public let kind: ProvenanceKind
    public let createdAt: CanonicalInstant
    public let subject: DataIdentityReference
    public let software: SoftwareIdentity
    public let activity: ProvenanceActivity
    public let inputs: ContiguousArray<ProvenanceInput>
    public let warnings: ContiguousArray<ProvenanceWarning>
    public let validationClaim: ProvenanceValidationClaim

    /// Creates a validated record.
    ///
    /// - Throws: ``ProvenanceRecordError/activityKindMismatch`` when
    ///   `kind == .source` and the activity disagree in either
    ///   direction, ``ProvenanceRecordError/unexpectedInputs`` for an
    ///   origin with inputs,
    ///   ``ProvenanceRecordError/emptyInputSequence`` for an undeclared
    ///   empty operation input sequence,
    ///   ``ProvenanceRecordError/unexpectedInputSequence`` for a
    ///   declared zero-input generator carrying inputs,
    ///   ``ProvenanceRecordError/duplicateInputOccurrence`` for a
    ///   repeated role/occurrence pair, or
    ///   ``ProvenanceRecordError/duplicateWarning`` for a repeated
    ///   warning key.
    public init(
        id: ProvenanceID,
        kind: ProvenanceKind,
        createdAt: CanonicalInstant,
        subject: DataIdentityReference,
        software: SoftwareIdentity,
        activity: ProvenanceActivity,
        inputs: ContiguousArray<ProvenanceInput>,
        warnings: ContiguousArray<ProvenanceWarning>,
        validationClaim: ProvenanceValidationClaim,
        declaresZeroInputGenerator: Bool
    ) throws {
        switch activity {
        case .origin:
            guard kind == .source else {
                throw ProvenanceRecordError.activityKindMismatch
            }
            guard inputs.isEmpty else {
                throw ProvenanceRecordError.unexpectedInputs
            }
        case .operation:
            guard kind != .source else {
                throw ProvenanceRecordError.activityKindMismatch
            }
            if inputs.isEmpty && !declaresZeroInputGenerator {
                throw ProvenanceRecordError.emptyInputSequence
            }
            if !inputs.isEmpty && declaresZeroInputGenerator {
                throw ProvenanceRecordError.unexpectedInputSequence
            }
        }

        var occurrenceKeys = Set<InputOccurrenceKey>()
        occurrenceKeys.reserveCapacity(inputs.count)
        for input in inputs {
            let key = InputOccurrenceKey(
                role: input.role,
                occurrence: input.occurrence
            )
            guard occurrenceKeys.insert(key).inserted else {
                throw ProvenanceRecordError.duplicateInputOccurrence
            }
        }

        var warningKeys = Set<WarningKey>()
        warningKeys.reserveCapacity(warnings.count)
        for warning in warnings {
            let key = WarningKey(
                code: warning.code,
                schemaVersion: warning.schemaVersion,
                severity: warning.severity
            )
            guard warningKeys.insert(key).inserted else {
                throw ProvenanceRecordError.duplicateWarning
            }
        }

        self.id = id
        self.kind = kind
        self.createdAt = createdAt
        self.subject = subject
        self.software = software
        self.activity = activity
        self.inputs = inputs
        self.warnings = warnings
        self.validationClaim = validationClaim
    }

    private struct InputOccurrenceKey: Hashable {
        let role: ProvenanceInputRole
        let occurrence: UInt32
    }

    private struct WarningKey: Hashable {
        let code: ProvenanceWarningCode
        let schemaVersion: ProvenanceWarningSchemaVersion
        let severity: ProvenanceWarningSeverity
    }
}
