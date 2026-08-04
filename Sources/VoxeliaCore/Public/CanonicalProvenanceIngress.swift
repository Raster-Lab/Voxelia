// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaSpatial

/// An error raised while decoding a canonical provenance document.
///
/// Cases deliberately carry no payload, and no underlying error that
/// could carry value text is retained: ingress crosses many error
/// domains, so a uniform redacted taxonomy guards the untrusted-bytes
/// boundary.
public enum ProvenanceJSONIngressError: Error, Sendable, Equatable {
    case inputByteLimitExceeded
    case rawDepthLimitExceeded
    case invalidDocument
    case noncanonicalDocument
    case cancelled
}

extension CanonicalProvenanceJSON {
    /// The hard raw nesting ceiling enforced before any parser runs.
    public static let maximumRawNestingDepth = 32

    /// Decodes one exact canonical `VCPJ-1` document per `ADR-0061`.
    ///
    /// The bytes are pre-scanned under the raw depth ceiling, parsed,
    /// rebuilt through every accepted constructing initializer and then
    /// re-emitted; the re-emission must equal the input byte for byte,
    /// so every non-canonical alias is rejected. The byte-equality
    /// gate, not the parser, is the canonical authority.
    ///
    /// - Throws: ``ProvenanceJSONIngressError``.
    public static func decodeRecordDocument(
        from bytes: [UInt8],
        maximumInputByteCount: UInt64
    ) throws -> ProvenanceRecord {
        guard UInt64(bytes.count) <= maximumInputByteCount else {
            throw ProvenanceJSONIngressError.inputByteLimitExceeded
        }
        try prescanRawNesting(bytes)
        if Task.isCancelled {
            throw ProvenanceJSONIngressError.cancelled
        }

        let tree: Any
        do {
            tree = try JSONSerialization.jsonObject(
                with: Data(bytes),
                options: []
            )
        } catch {
            throw ProvenanceJSONIngressError.invalidDocument
        }

        let record: ProvenanceRecord
        do {
            record = try reconstructDocument(tree)
        } catch let error as ProvenanceJSONIngressError {
            throw error
        } catch {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        if Task.isCancelled {
            throw ProvenanceJSONIngressError.cancelled
        }

        let reEmitted: [UInt8]
        do {
            reEmitted = try encodeRecordDocument(
                record: record,
                maximumOutputByteCount: UInt64(bytes.count)
            )
        } catch ProvenanceJSONEmissionError.cancelled {
            throw ProvenanceJSONIngressError.cancelled
        } catch {
            throw ProvenanceJSONIngressError.noncanonicalDocument
        }
        guard reEmitted == bytes else {
            throw ProvenanceJSONIngressError.noncanonicalDocument
        }
        return record
    }

    // MARK: - Bounded pre-scan

    private static func prescanRawNesting(_ bytes: [UInt8]) throws {
        var depth = 0
        var inString = false
        var escaped = false
        for byte in bytes {
            if inString {
                if escaped {
                    escaped = false
                } else if byte == UInt8(ascii: "\\") {
                    escaped = true
                } else if byte == UInt8(ascii: "\"") {
                    inString = false
                }
                continue
            }
            switch byte {
            case UInt8(ascii: "\""):
                inString = true
            case UInt8(ascii: "{"), UInt8(ascii: "["):
                depth += 1
                if depth > Self.maximumRawNestingDepth {
                    throw ProvenanceJSONIngressError.rawDepthLimitExceeded
                }
            case UInt8(ascii: "}"), UInt8(ascii: "]"):
                depth -= 1
                if depth < 0 {
                    throw ProvenanceJSONIngressError.invalidDocument
                }
            default:
                break
            }
        }
    }

    // MARK: - Shape-directed reconstruction

    private static func reconstructDocument(_ tree: Any) throws -> ProvenanceRecord {
        let envelope = try object(tree, keys: ["documentSchema", "payload"])
        let schema = try object(
            envelope["documentSchema"],
            keys: ["identifier", "version"]
        )
        guard try string(schema["identifier"]) == "org.voxelia.provenance-record"
        else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        let schemaVersion = try object(schema["version"], keys: ["major", "minor"])
        guard
            try uint32Number(schemaVersion["major"]) == 1,
            try uint32Number(schemaVersion["minor"]) == 0
        else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        return try reconstructRecord(envelope["payload"])
    }

    private static func reconstructRecord(_ value: Any?) throws -> ProvenanceRecord {
        let payload = try object(
            value,
            keys: [
                "activity", "createdAt", "id", "inputs", "kind", "software",
                "subject", "validationClaim", "warnings",
            ]
        )
        guard let kind = ProvenanceKind(rawValue: try string(payload["kind"]))
        else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        var inputs = ContiguousArray<ProvenanceInput>()
        for element in try array(payload["inputs"]) {
            inputs.append(try reconstructInput(element))
        }
        var warnings = ContiguousArray<ProvenanceWarning>()
        for element in try array(payload["warnings"]) {
            warnings.append(try reconstructWarning(element))
        }
        let activity = try reconstructActivity(payload["activity"])
        let declaresZeroInputGenerator: Bool
        switch activity {
        case .origin:
            declaresZeroInputGenerator = false
        case .operation:
            declaresZeroInputGenerator = inputs.isEmpty
        }
        return try ProvenanceRecord(
            id: try keyedIdentifier(payload["id"], as: ProvenanceID.self),
            kind: kind,
            createdAt: try CanonicalInstant(
                utcString: try string(payload["createdAt"])
            ),
            subject: try reconstructReference(payload["subject"]),
            software: try reconstructSoftware(payload["software"]),
            activity: activity,
            inputs: inputs,
            warnings: warnings,
            validationClaim: try reconstructValidationClaim(
                payload["validationClaim"]
            ),
            declaresZeroInputGenerator: declaresZeroInputGenerator
        )
    }

    private static func reconstructActivity(
        _ value: Any?
    ) throws -> ProvenanceActivity {
        let (tag, body) = try taggedMember(value)
        switch tag {
        case "origin":
            guard body is NSNull else {
                throw ProvenanceJSONIngressError.invalidDocument
            }
            return .origin
        case "operation":
            let members = try object(body, keys: ["execution", "operation"])
            return .operation(
                try reconstructOperation(members["operation"]),
                try reconstructExecutionClaim(members["execution"])
            )
        default:
            throw ProvenanceJSONIngressError.invalidDocument
        }
    }

    private static func reconstructOperation(
        _ value: Any?
    ) throws -> OperationProvenance {
        let members = try object(
            value,
            keys: [
                "implementationID", "implementationVersion", "operationID",
                "operationVersion", "parameterDigest",
            ]
        )
        return try OperationProvenance(
            operationID: try DerivationOperationToken(
                rawValue: try string(members["operationID"])
            ),
            operationVersion: try reconstructSemanticVersion(
                members["operationVersion"]
            ),
            implementationID: try DerivationOperationToken(
                rawValue: try string(members["implementationID"])
            ),
            implementationVersion: try reconstructSemanticVersion(
                members["implementationVersion"]
            ),
            parameterDigest: try reconstructContentID(members["parameterDigest"])
        )
    }

    private static func reconstructExecutionClaim(
        _ value: Any?
    ) throws -> ExecutionProvenanceClaim {
        let members = try object(
            value,
            keys: [
                "approximationStatus", "backend", "capabilityClass", "kernel",
                "precisionPolicy", "profile", "qualityPolicy",
            ]
        )
        let approximationStatus: ExecutionApproximationStatus
        switch try string(members["approximationStatus"]) {
        case "exact":
            approximationStatus = .exact
        case "approximate":
            approximationStatus = .approximate
        default:
            throw ProvenanceJSONIngressError.invalidDocument
        }
        let capabilityClass: ExecutionClaimToken?
        if members["capabilityClass"] is NSNull {
            capabilityClass = nil
        } else {
            capabilityClass = try ExecutionClaimToken(
                rawValue: try string(members["capabilityClass"])
            )
        }
        let kernel: ExecutionComponentReference?
        if members["kernel"] is NSNull {
            kernel = nil
        } else {
            kernel = try reconstructComponent(members["kernel"])
        }
        return ExecutionProvenanceClaim(
            profile: try reconstructComponent(members["profile"]),
            backend: try reconstructComponent(members["backend"]),
            precisionPolicy: try ExecutionClaimToken(
                rawValue: try string(members["precisionPolicy"])
            ),
            qualityPolicy: try ExecutionClaimToken(
                rawValue: try string(members["qualityPolicy"])
            ),
            approximationStatus: approximationStatus,
            capabilityClass: capabilityClass,
            kernel: kernel
        )
    }

    private static func reconstructComponent(
        _ value: Any?
    ) throws -> ExecutionComponentReference {
        let members = try object(value, keys: ["identifier", "version"])
        return try ExecutionComponentReference(
            identifier: try ExecutionClaimToken(
                rawValue: try string(members["identifier"])
            ),
            version: try reconstructSemanticVersion(members["version"])
        )
    }

    private static func reconstructInput(_ value: Any?) throws -> ProvenanceInput {
        let members = try object(
            value,
            keys: ["identity", "occurrence", "parent", "role"]
        )
        let parent: ProvenanceParentReference?
        if members["parent"] is NSNull {
            parent = nil
        } else {
            let (tag, body) = try taggedMember(members["parent"])
            guard tag == "graphNode" else {
                throw ProvenanceJSONIngressError.invalidDocument
            }
            parent = .graphNode(try keyedIdentifier(body, as: ProvenanceID.self))
        }
        return try ProvenanceInput(
            role: try ProvenanceInputRole(rawValue: try string(members["role"])),
            occurrence: try uint32Number(members["occurrence"]),
            identity: try reconstructReference(members["identity"]),
            parent: parent
        )
    }

    private static func reconstructWarning(
        _ value: Any?
    ) throws -> ProvenanceWarning {
        let members = try object(
            value,
            keys: ["code", "occurrenceCount", "schemaVersion", "severity"]
        )
        let versionMembers = try object(
            members["schemaVersion"],
            keys: ["major", "minor"]
        )
        let severity: ProvenanceWarningSeverity
        switch try string(members["severity"]) {
        case "informational":
            severity = .informational
        case "qualityAffecting":
            severity = .qualityAffecting
        case "integrityAffecting":
            severity = .integrityAffecting
        default:
            throw ProvenanceJSONIngressError.invalidDocument
        }
        guard
            let occurrenceCount = UInt64(try string(members["occurrenceCount"]))
        else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        return try ProvenanceWarning(
            code: try ProvenanceWarningCode(rawValue: try string(members["code"])),
            schemaVersion: ProvenanceWarningSchemaVersion(
                major: try uint32Number(versionMembers["major"]),
                minor: try uint32Number(versionMembers["minor"])
            ),
            severity: severity,
            occurrenceCount: occurrenceCount
        )
    }

    private static func reconstructValidationClaim(
        _ value: Any?
    ) throws -> ProvenanceValidationClaim {
        let (tag, body) = try taggedMember(value)
        switch tag {
        case "unknown", "experimental", "preview", "deprecated":
            guard body is NSNull else {
                throw ProvenanceJSONIngressError.invalidDocument
            }
            switch tag {
            case "unknown": return .unknown
            case "experimental": return .experimental
            case "preview": return .preview
            default: return .deprecated
            }
        case "validated":
            return .validated(
                try keyedIdentifier(body, as: ValidationEvidenceID.self)
            )
        case "diagnosticReady":
            return .diagnosticReady(
                try keyedIdentifier(body, as: ValidationEvidenceID.self)
            )
        default:
            throw ProvenanceJSONIngressError.invalidDocument
        }
    }

    private static func reconstructSoftware(
        _ value: Any?
    ) throws -> SoftwareIdentity {
        let members = try object(
            value,
            keys: ["buildIdentifier", "commit", "name", "version"]
        )
        return try SoftwareIdentity(
            name: try string(members["name"]),
            version: try reconstructSemanticVersion(members["version"]),
            commit: try optionalString(members["commit"]),
            buildIdentifier: try optionalString(members["buildIdentifier"])
        )
    }

    private static func reconstructSemanticVersion(
        _ value: Any?
    ) throws -> SemanticVersion {
        let members = try object(
            value,
            keys: ["buildMetadata", "major", "minor", "patch", "prerelease"]
        )
        guard
            let major = Int(try string(members["major"])),
            let minor = Int(try string(members["minor"])),
            let patch = Int(try string(members["patch"]))
        else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        do {
            return try SemanticVersion(
                major: major,
                minor: minor,
                patch: patch,
                prerelease: try optionalString(members["prerelease"]),
                buildMetadata: try optionalString(members["buildMetadata"])
            )
        } catch {
            throw ProvenanceJSONIngressError.invalidDocument
        }
    }

    private static func reconstructReference(
        _ value: Any?
    ) throws -> DataIdentityReference {
        let (tag, body) = try taggedMember(value)
        switch tag {
        case "object":
            return .object(try keyedIdentifier(body, as: DataObjectID.self))
        case "content":
            return .content(try reconstructContentID(body))
        case "source":
            return .source(try reconstructSourceIdentity(body))
        default:
            throw ProvenanceJSONIngressError.invalidDocument
        }
    }

    private static func reconstructSourceIdentity(
        _ value: Any?
    ) throws -> SourceIdentity {
        let members = try object(
            value,
            keys: ["contentID", "identifier", "namespace", "version"]
        )
        let contentID: ContentID?
        if members["contentID"] is NSNull {
            contentID = nil
        } else {
            contentID = try reconstructContentID(members["contentID"])
        }
        return try SourceIdentity(
            namespace: try string(members["namespace"]),
            identifier: try string(members["identifier"]),
            version: try optionalString(members["version"]),
            contentID: contentID
        )
    }

    private static func reconstructContentID(_ value: Any?) throws -> ContentID {
        let members = try object(
            value,
            keys: ["algorithm", "digest", "projection", "scope"]
        )
        let projectionMembers = try object(
            members["projection"],
            keys: ["identifier", "version"]
        )
        let versionMembers = try object(
            projectionMembers["version"],
            keys: ["major", "minor"]
        )
        guard
            let algorithm = DigestAlgorithm(
                rawValue: try string(members["algorithm"])
            ),
            let scope = ContentScope(rawValue: try string(members["scope"])),
            let digestBytes = ContentID.digestBytes(
                fromHexText: try string(members["digest"])
            )
        else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        let projection: ContentProjectionReference
        do {
            projection = try ContentProjectionReference(
                identifier: try string(projectionMembers["identifier"]),
                version: ContentProjectionVersion(
                    major: try uint32Number(versionMembers["major"]),
                    minor: try uint32Number(versionMembers["minor"])
                )
            )
            try ContentID.validateAcceptedProfile(
                algorithm: algorithm,
                scope: scope,
                projection: projection,
                digestByteCount: digestBytes.count
            )
        } catch let error as ProvenanceJSONIngressError {
            throw error
        } catch {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        return ContentID(
            validatedAlgorithm: algorithm,
            scope: scope,
            projection: projection,
            digestBytes: digestBytes
        )
    }

    // MARK: - Extraction primitives

    private static func object(
        _ value: Any?,
        keys: Set<String>
    ) throws -> [String: Any] {
        guard let dictionary = value as? [String: Any],
            Set(dictionary.keys) == keys
        else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        return dictionary
    }

    private static func taggedMember(_ value: Any?) throws -> (String, Any) {
        guard let dictionary = value as? [String: Any],
            dictionary.count == 1,
            let member = dictionary.first
        else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        return member
    }

    private static func array(_ value: Any?) throws -> [Any] {
        guard let elements = value as? [Any] else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        return elements
    }

    private static func string(_ value: Any?) throws -> String {
        guard let text = value as? String else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        return text
    }

    private static func optionalString(_ value: Any?) throws -> String? {
        if value is NSNull {
            return nil
        }
        return try string(value)
    }

    private static func uint32Number(_ value: Any?) throws -> UInt32 {
        guard let number = value as? NSNumber, !(value is String) else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        return number.uint32Value
    }

    private static func keyedIdentifier<Identifier: VoxeliaStringIdentifier>(
        _ value: Any?,
        as type: Identifier.Type
    ) throws -> Identifier {
        let members = try object(value, keys: ["rawValue"])
        guard let identifier = Identifier(rawValue: try string(members["rawValue"]))
        else {
            throw ProvenanceJSONIngressError.invalidDocument
        }
        return identifier
    }
}
