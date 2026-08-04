// SPDX-License-Identifier: MIT

/// An error raised while emitting a canonical provenance document.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// record content, counts or partial output.
public enum ProvenanceJSONEmissionError: Error, Sendable, Equatable {
    case inputCountLimitExceeded
    case warningCountLimitExceeded
    case outputByteLimitExceeded
    case cancelled
}

/// The `VCPJ-1` canonical provenance document emitter selected by
/// `ADR-0060`.
///
/// The profile is a fixed-schema UTF-8 JSON envelope with no
/// whitespace, members in ascending UTF-8 byte order, explicit nulls,
/// one-member tagged unions, the accepted keyed identifier and embedded
/// wire shapes, and the shared `VCMJ-1` RFC 8785 string escaping.
/// Profile-native integers wider than 32 bits encode as decimal string
/// tokens so no binary64 boundary can corrupt exactness. The emitted
/// bytes are the registered `org.voxelia.provenance-record` digest
/// preimage payload; the record's own identity is an envelope claim
/// about these bytes and never a field inside them.
public enum CanonicalProvenanceJSON {
    /// The hard inclusive per-record input ceiling.
    public static let maximumInputCount: UInt64 = 65_536
    /// The hard inclusive per-record warning ceiling.
    public static let maximumWarningCount: UInt64 = 65_536

    private static let cancellationWorkUnitCadence = 4_096

    /// Emits the exact canonical `VCPJ-1` document for one record.
    ///
    /// Count ceilings are validated before any byte is written; the
    /// caller-supplied output ceiling has no permissive default.
    ///
    /// - Throws: ``ProvenanceJSONEmissionError``.
    public static func encodeRecordDocument(
        record: ProvenanceRecord,
        maximumOutputByteCount: UInt64
    ) throws -> [UInt8] {
        guard UInt64(record.inputs.count) <= Self.maximumInputCount else {
            throw ProvenanceJSONEmissionError.inputCountLimitExceeded
        }
        guard UInt64(record.warnings.count) <= Self.maximumWarningCount else {
            throw ProvenanceJSONEmissionError.warningCountLimitExceeded
        }
        if Task.isCancelled {
            throw ProvenanceJSONEmissionError.cancelled
        }

        var sink = EmissionSink(limit: maximumOutputByteCount)
        try sink.write(
            ascii: #"{"documentSchema":{"identifier":"org.voxelia.provenance-record","#
        )
        try sink.write(ascii: #""version":{"major":1,"minor":0}},"payload":"#)
        try emitRecord(record, into: &sink)
        try sink.write(ascii: "}")

        if Task.isCancelled {
            throw ProvenanceJSONEmissionError.cancelled
        }
        return sink.buffer
    }

    // MARK: - Record members

    private static func emitRecord(
        _ record: ProvenanceRecord,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"activity":"#)
        try emitActivity(record.activity, into: &sink)
        try sink.write(ascii: #","createdAt":"#)
        try emitString(record.createdAt.utcString, into: &sink)
        try sink.write(ascii: #","id":"#)
        try emitKeyedIdentifier(record.id.rawValue, into: &sink)
        try sink.write(ascii: #","inputs":["#)
        for (index, input) in record.inputs.enumerated() {
            if index > 0 {
                try sink.write(ascii: ",")
            }
            try emitInput(input, into: &sink)
        }
        try sink.write(ascii: #"],"kind":"#)
        try emitString(record.kind.rawValue, into: &sink)
        try sink.write(ascii: #","software":"#)
        try emitSoftware(record.software, into: &sink)
        try sink.write(ascii: #","subject":"#)
        try emitReference(record.subject, into: &sink)
        try sink.write(ascii: #","validationClaim":"#)
        try emitValidationClaim(record.validationClaim, into: &sink)
        try sink.write(ascii: #","warnings":["#)
        for (index, warning) in record.warnings.enumerated() {
            if index > 0 {
                try sink.write(ascii: ",")
            }
            try emitWarning(warning, into: &sink)
        }
        try sink.write(ascii: "]}")
    }

    private static func emitActivity(
        _ activity: ProvenanceActivity,
        into sink: inout EmissionSink
    ) throws {
        switch activity {
        case .origin:
            try sink.write(ascii: #"{"origin":null}"#)
        case .operation(let operation, let execution):
            try sink.write(ascii: #"{"operation":{"execution":"#)
            try emitExecutionClaim(execution, into: &sink)
            try sink.write(ascii: #","operation":"#)
            try emitOperation(operation, into: &sink)
            try sink.write(ascii: "}}")
        }
    }

    private static func emitOperation(
        _ operation: OperationProvenance,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"implementationID":"#)
        try emitString(operation.implementationID.rawValue, into: &sink)
        try sink.write(ascii: #","implementationVersion":"#)
        try emitSemanticVersion(operation.implementationVersion, into: &sink)
        try sink.write(ascii: #","operationID":"#)
        try emitString(operation.operationID.rawValue, into: &sink)
        try sink.write(ascii: #","operationVersion":"#)
        try emitSemanticVersion(operation.operationVersion, into: &sink)
        try sink.write(ascii: #","parameterDigest":"#)
        try emitContentID(operation.parameterDigest, into: &sink)
        try sink.write(ascii: "}")
    }

    private static func emitExecutionClaim(
        _ claim: ExecutionProvenanceClaim,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"approximationStatus":"#)
        switch claim.approximationStatus {
        case .exact:
            try sink.write(ascii: #""exact""#)
        case .approximate:
            try sink.write(ascii: #""approximate""#)
        }
        try sink.write(ascii: #","backend":"#)
        try emitComponent(claim.backend, into: &sink)
        try sink.write(ascii: #","capabilityClass":"#)
        try emitOptionalString(claim.capabilityClass?.rawValue, into: &sink)
        try sink.write(ascii: #","kernel":"#)
        if let kernel = claim.kernel {
            try emitComponent(kernel, into: &sink)
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","precisionPolicy":"#)
        try emitString(claim.precisionPolicy.rawValue, into: &sink)
        try sink.write(ascii: #","profile":"#)
        try emitComponent(claim.profile, into: &sink)
        try sink.write(ascii: #","qualityPolicy":"#)
        try emitString(claim.qualityPolicy.rawValue, into: &sink)
        try sink.write(ascii: "}")
    }

    private static func emitComponent(
        _ component: ExecutionComponentReference,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"identifier":"#)
        try emitString(component.identifier.rawValue, into: &sink)
        try sink.write(ascii: #","version":"#)
        try emitSemanticVersion(component.version, into: &sink)
        try sink.write(ascii: "}")
    }

    private static func emitInput(
        _ input: ProvenanceInput,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"identity":"#)
        try emitReference(input.identity, into: &sink)
        try sink.write(ascii: #","occurrence":"#)
        try sink.write(Array(String(input.occurrence).utf8))
        try sink.write(ascii: #","parent":"#)
        if let parent = input.parent {
            switch parent {
            case .graphNode(let identifier):
                try sink.write(ascii: #"{"graphNode":"#)
                try emitKeyedIdentifier(identifier.rawValue, into: &sink)
                try sink.write(ascii: "}")
            }
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","role":"#)
        try emitString(input.role.rawValue, into: &sink)
        try sink.write(ascii: "}")
    }

    private static func emitWarning(
        _ warning: ProvenanceWarning,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"code":"#)
        try emitString(warning.code.rawValue, into: &sink)
        try sink.write(ascii: #","occurrenceCount":"#)
        try emitString(String(warning.occurrenceCount), into: &sink)
        try sink.write(ascii: #","schemaVersion":{"major":"#)
        try sink.write(Array(String(warning.schemaVersion.major).utf8))
        try sink.write(ascii: #","minor":"#)
        try sink.write(Array(String(warning.schemaVersion.minor).utf8))
        try sink.write(ascii: #"},"severity":"#)
        switch warning.severity {
        case .informational:
            try sink.write(ascii: #""informational""#)
        case .qualityAffecting:
            try sink.write(ascii: #""qualityAffecting""#)
        case .integrityAffecting:
            try sink.write(ascii: #""integrityAffecting""#)
        }
        try sink.write(ascii: "}")
    }

    private static func emitValidationClaim(
        _ claim: ProvenanceValidationClaim,
        into sink: inout EmissionSink
    ) throws {
        switch claim {
        case .unknown:
            try sink.write(ascii: #"{"unknown":null}"#)
        case .experimental:
            try sink.write(ascii: #"{"experimental":null}"#)
        case .preview:
            try sink.write(ascii: #"{"preview":null}"#)
        case .validated(let evidence):
            try sink.write(ascii: #"{"validated":"#)
            try emitKeyedIdentifier(evidence.rawValue, into: &sink)
            try sink.write(ascii: "}")
        case .diagnosticReady(let evidence):
            try sink.write(ascii: #"{"diagnosticReady":"#)
            try emitKeyedIdentifier(evidence.rawValue, into: &sink)
            try sink.write(ascii: "}")
        case .deprecated:
            try sink.write(ascii: #"{"deprecated":null}"#)
        }
    }

    private static func emitSoftware(
        _ software: SoftwareIdentity,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"buildIdentifier":"#)
        try emitOptionalString(software.buildIdentifier, into: &sink)
        try sink.write(ascii: #","commit":"#)
        try emitOptionalString(software.commit, into: &sink)
        try sink.write(ascii: #","name":"#)
        try emitString(software.name, into: &sink)
        try sink.write(ascii: #","version":"#)
        try emitSemanticVersion(software.version, into: &sink)
        try sink.write(ascii: "}")
    }

    private static func emitSemanticVersion(
        _ version: SemanticVersion,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"buildMetadata":"#)
        try emitOptionalString(version.buildMetadata, into: &sink)
        try sink.write(ascii: #","major":"#)
        try emitString(String(version.major), into: &sink)
        try sink.write(ascii: #","minor":"#)
        try emitString(String(version.minor), into: &sink)
        try sink.write(ascii: #","patch":"#)
        try emitString(String(version.patch), into: &sink)
        try sink.write(ascii: #","prerelease":"#)
        try emitOptionalString(version.prerelease, into: &sink)
        try sink.write(ascii: "}")
    }

    private static func emitReference(
        _ reference: DataIdentityReference,
        into sink: inout EmissionSink
    ) throws {
        switch reference {
        case .object(let objectID):
            try sink.write(ascii: #"{"object":"#)
            try emitKeyedIdentifier(objectID.rawValue, into: &sink)
            try sink.write(ascii: "}")
        case .content(let contentID):
            try sink.write(ascii: #"{"content":"#)
            try emitContentID(contentID, into: &sink)
            try sink.write(ascii: "}")
        case .source(let source):
            try sink.write(ascii: #"{"source":"#)
            try emitSourceIdentity(source, into: &sink)
            try sink.write(ascii: "}")
        }
    }

    private static func emitSourceIdentity(
        _ source: SourceIdentity,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"contentID":"#)
        if let contentID = source.contentID {
            try emitContentID(contentID, into: &sink)
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","identifier":"#)
        try emitString(source.identifier, into: &sink)
        try sink.write(ascii: #","namespace":"#)
        try emitString(source.namespace, into: &sink)
        try sink.write(ascii: #","version":"#)
        try emitOptionalString(source.version, into: &sink)
        try sink.write(ascii: "}")
    }

    private static func emitContentID(
        _ contentID: ContentID,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"algorithm":"#)
        try emitString(contentID.algorithm.rawValue, into: &sink)
        try sink.write(ascii: #","digest":"#)
        try emitString(ContentID.hexDigestText(contentID.digest), into: &sink)
        try sink.write(ascii: #","projection":{"identifier":"#)
        try emitString(contentID.projection.identifier, into: &sink)
        try sink.write(ascii: #","version":{"major":"#)
        try sink.write(Array(String(contentID.projection.version.major).utf8))
        try sink.write(ascii: #","minor":"#)
        try sink.write(Array(String(contentID.projection.version.minor).utf8))
        try sink.write(ascii: #"}},"scope":"#)
        try emitString(contentID.scope.rawValue, into: &sink)
        try sink.write(ascii: "}")
    }

    private static func emitKeyedIdentifier(
        _ rawValue: String,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"rawValue":"#)
        try emitString(rawValue, into: &sink)
        try sink.write(ascii: "}")
    }

    private static func emitString(
        _ value: String,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(CanonicalMetadataJSON.canonicalStringToken(value))
    }

    private static func emitOptionalString(
        _ value: String?,
        into sink: inout EmissionSink
    ) throws {
        if let value {
            try emitString(value, into: &sink)
        } else {
            try sink.write(ascii: "null")
        }
    }

    // MARK: - Bounded sink

    private struct EmissionSink {
        let limit: UInt64
        var count: UInt64 = 0
        var buffer = [UInt8]()
        var workUnits = 0

        init(limit: UInt64) {
            self.limit = limit
        }

        mutating func write(_ byte: UInt8) throws {
            let (candidate, overflow) = count.addingReportingOverflow(1)
            guard !overflow, candidate <= limit else {
                throw ProvenanceJSONEmissionError.outputByteLimitExceeded
            }
            count = candidate
            buffer.append(byte)
            workUnits += 1
            if workUnits >= CanonicalProvenanceJSON.cancellationWorkUnitCadence {
                workUnits = 0
                if Task.isCancelled {
                    throw ProvenanceJSONEmissionError.cancelled
                }
            }
        }

        mutating func write(_ bytes: [UInt8]) throws {
            for byte in bytes {
                try write(byte)
            }
        }

        mutating func write(ascii literal: StaticString) throws {
            var failure: ProvenanceJSONEmissionError?
            literal.withUTF8Buffer { pointer in
                for byte in pointer {
                    do {
                        try write(byte)
                    } catch let error as ProvenanceJSONEmissionError {
                        failure = error
                        return
                    } catch {
                        failure = .outputByteLimitExceeded
                        return
                    }
                }
            }
            if let failure {
                throw failure
            }
        }
    }
}
