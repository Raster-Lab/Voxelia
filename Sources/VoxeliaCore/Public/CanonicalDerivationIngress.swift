// SPDX-License-Identifier: MIT

import Foundation

/// An error raised while decoding a canonical derivation document.
///
/// Cases deliberately carry no payload, and no underlying error that
/// could carry value text is retained: ingress crosses many error
/// domains, so a uniform redacted taxonomy guards the untrusted-bytes
/// boundary.
public enum DerivationJSONIngressError: Error, Sendable, Equatable {
    case inputByteLimitExceeded
    case rawDepthLimitExceeded
    case invalidDocument
    case noncanonicalDocument
    case cancelled
}

extension CanonicalDerivationJSON {
    /// Decodes one exact canonical `VCDJ-1` document per `ADR-0073`.
    ///
    /// The bytes are pre-scanned under the shared raw depth ceiling,
    /// parsed, rebuilt through every accepted constructing initializer —
    /// with an empty input array reconstructing as the declared
    /// zero-input generator, the only way such a document canonically
    /// exists — and then re-emitted; the re-emission must equal the
    /// input byte for byte, so every non-canonical alias is rejected.
    /// The byte-equality gate, not the parser, is the canonical
    /// authority. The shared member reconstructors are one internal
    /// authority with the provenance ingress, and their failures map
    /// into this ingress's own taxonomy.
    ///
    /// - Throws: ``DerivationJSONIngressError``.
    public static func decodeRecordDocument(
        from bytes: [UInt8],
        maximumInputByteCount: UInt64
    ) throws -> DerivationIdentity {
        guard UInt64(bytes.count) <= maximumInputByteCount else {
            throw DerivationJSONIngressError.inputByteLimitExceeded
        }
        do {
            try CanonicalProvenanceJSON.prescanRawNesting(bytes)
        } catch ProvenanceJSONIngressError.rawDepthLimitExceeded {
            throw DerivationJSONIngressError.rawDepthLimitExceeded
        } catch {
            throw DerivationJSONIngressError.invalidDocument
        }
        if Task.isCancelled {
            throw DerivationJSONIngressError.cancelled
        }

        let tree: Any
        do {
            tree = try JSONSerialization.jsonObject(with: Data(bytes), options: [])
        } catch {
            throw DerivationJSONIngressError.invalidDocument
        }

        let record: DerivationIdentity
        do {
            record = try reconstructDocument(tree)
        } catch let error as DerivationJSONIngressError {
            throw error
        } catch {
            throw DerivationJSONIngressError.invalidDocument
        }
        if Task.isCancelled {
            throw DerivationJSONIngressError.cancelled
        }

        let reEmitted: [UInt8]
        do {
            reEmitted = try encodeRecordDocument(
                record: record,
                maximumOutputByteCount: UInt64(bytes.count)
            )
        } catch DerivationJSONEmissionError.cancelled {
            throw DerivationJSONIngressError.cancelled
        } catch {
            throw DerivationJSONIngressError.noncanonicalDocument
        }
        guard reEmitted == bytes else {
            throw DerivationJSONIngressError.noncanonicalDocument
        }
        return record
    }

    // MARK: - Shape-directed reconstruction

    private static func reconstructDocument(
        _ tree: Any
    ) throws -> DerivationIdentity {
        let envelope = try CanonicalProvenanceJSON.object(
            tree,
            keys: ["documentSchema", "payload"]
        )
        let schema = try CanonicalProvenanceJSON.object(
            envelope["documentSchema"],
            keys: ["identifier", "version"]
        )
        guard
            try CanonicalProvenanceJSON.string(schema["identifier"])
                == "org.voxelia.derivation-record"
        else {
            throw DerivationJSONIngressError.invalidDocument
        }
        let schemaVersion = try CanonicalProvenanceJSON.object(
            schema["version"],
            keys: ["major", "minor"]
        )
        guard
            try CanonicalProvenanceJSON.uint32Number(schemaVersion["major"]) == 1,
            try CanonicalProvenanceJSON.uint32Number(schemaVersion["minor"]) == 0
        else {
            throw DerivationJSONIngressError.invalidDocument
        }

        let payload = try CanonicalProvenanceJSON.object(
            envelope["payload"],
            keys: [
                "implementation", "inputs", "operationID", "operationVersion",
                "parameterDigest",
            ]
        )
        let implementation: DerivationImplementationReference?
        if payload["implementation"] is NSNull {
            implementation = nil
        } else {
            let members = try CanonicalProvenanceJSON.object(
                payload["implementation"],
                keys: ["identifier", "version"]
            )
            implementation = DerivationImplementationReference(
                identifier: try DerivationOperationToken(
                    rawValue: try CanonicalProvenanceJSON.string(
                        members["identifier"]
                    )
                ),
                version: try CanonicalProvenanceJSON.reconstructSemanticVersion(
                    members["version"]
                )
            )
        }
        var inputs = ContiguousArray<DerivationInput>()
        for element in try CanonicalProvenanceJSON.array(payload["inputs"]) {
            let members = try CanonicalProvenanceJSON.object(
                element,
                keys: ["identity", "role"]
            )
            inputs.append(
                DerivationInput(
                    role: try DerivationInputRole(
                        rawValue: try CanonicalProvenanceJSON.string(
                            members["role"]
                        )
                    ),
                    identity: try CanonicalProvenanceJSON.reconstructReference(
                        members["identity"]
                    )
                )
            )
        }
        return try DerivationIdentity(
            operationID: try DerivationOperationToken(
                rawValue: try CanonicalProvenanceJSON.string(
                    payload["operationID"]
                )
            ),
            operationVersion:
                try CanonicalProvenanceJSON
                .reconstructSemanticVersion(payload["operationVersion"]),
            implementation: implementation,
            inputs: inputs,
            parameterDigest: try CanonicalProvenanceJSON.reconstructContentID(
                payload["parameterDigest"]
            ),
            declaresZeroInputGenerator: inputs.isEmpty
        )
    }
}
