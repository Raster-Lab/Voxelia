// SPDX-License-Identifier: MIT

/// An error raised while emitting a canonical derivation document.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// record content, counts or partial output.
public enum DerivationJSONEmissionError: Error, Sendable, Equatable {
    case inputCountLimitExceeded
    case outputByteLimitExceeded
    case cancelled
}

/// The `VCDJ-1` canonical derivation document emitter selected by
/// `ADR-0072`.
///
/// The profile reuses the accepted `VCPJ-1` member forms — ascending
/// UTF-8 member order, explicit nulls, bare grammar tokens, the
/// decimal-string semantic-version form with exact build metadata, the
/// accepted reference and `ContentID` wires and the shared RFC 8785
/// string-token authority. An empty input array is the canonical form
/// of a declared zero-input generator, the only way such a record
/// exists. The emitted bytes are the registered
/// `org.voxelia.derivation-record` digest preimage payload; the
/// record's own identity is an envelope claim about these bytes and
/// never a field inside them.
public enum CanonicalDerivationJSON {
    /// The hard inclusive per-record input ceiling.
    public static let maximumInputCount: UInt64 = 65_536

    private static let cancellationWorkUnitCadence = 4_096

    /// Emits the exact canonical `VCDJ-1` document for one derivation
    /// record.
    ///
    /// - Throws: ``DerivationJSONEmissionError``.
    public static func encodeRecordDocument(
        record: DerivationIdentity,
        maximumOutputByteCount: UInt64
    ) throws -> [UInt8] {
        guard UInt64(record.inputs.count) <= Self.maximumInputCount else {
            throw DerivationJSONEmissionError.inputCountLimitExceeded
        }
        if Task.isCancelled {
            throw DerivationJSONEmissionError.cancelled
        }

        var sink = EmissionSink(limit: maximumOutputByteCount)
        try sink.write(
            ascii: #"{"documentSchema":{"identifier":"org.voxelia.derivation-record","#
        )
        try sink.write(ascii: #""version":{"major":1,"minor":0}},"payload":"#)
        try emitRecord(record, into: &sink)
        try sink.write(ascii: "}")

        if Task.isCancelled {
            throw DerivationJSONEmissionError.cancelled
        }
        return sink.buffer
    }

    private static func emitRecord(
        _ record: DerivationIdentity,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"implementation":"#)
        if let implementation = record.implementation {
            try sink.write(ascii: #"{"identifier":"#)
            try emitString(implementation.identifier.rawValue, into: &sink)
            try sink.write(ascii: #","version":"#)
            try emitSemanticVersion(implementation.version, into: &sink)
            try sink.write(ascii: "}")
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","inputs":["#)
        for (index, input) in record.inputs.enumerated() {
            if index > 0 {
                try sink.write(ascii: ",")
            }
            try sink.write(ascii: #"{"identity":"#)
            try emitReference(input.identity, into: &sink)
            try sink.write(ascii: #","role":"#)
            try emitString(input.role.rawValue, into: &sink)
            try sink.write(ascii: "}")
        }
        try sink.write(ascii: #"],"operationID":"#)
        try emitString(record.operationID.rawValue, into: &sink)
        try sink.write(ascii: #","operationVersion":"#)
        try emitSemanticVersion(record.operationVersion, into: &sink)
        try sink.write(ascii: #","parameterDigest":"#)
        try emitContentID(record.parameterDigest, into: &sink)
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
            try sink.write(ascii: #"{"source":{"contentID":"#)
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
            if let version = source.version {
                try emitString(version, into: &sink)
            } else {
                try sink.write(ascii: "null")
            }
            try sink.write(ascii: "}}")
        case .derivation(let record):
            try sink.write(ascii: #"{"derivation":{"recordContentID":"#)
            try emitContentID(record.recordContentID, into: &sink)
            try sink.write(ascii: "}}")
        }
    }

    private static func emitSemanticVersion(
        _ version: SemanticVersion,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"buildMetadata":"#)
        if let buildMetadata = version.buildMetadata {
            try emitString(buildMetadata, into: &sink)
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","major":"#)
        try emitString(String(version.major), into: &sink)
        try sink.write(ascii: #","minor":"#)
        try emitString(String(version.minor), into: &sink)
        try sink.write(ascii: #","patch":"#)
        try emitString(String(version.patch), into: &sink)
        try sink.write(ascii: #","prerelease":"#)
        if let prerelease = version.prerelease {
            try emitString(prerelease, into: &sink)
        } else {
            try sink.write(ascii: "null")
        }
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
                throw DerivationJSONEmissionError.outputByteLimitExceeded
            }
            count = candidate
            buffer.append(byte)
            workUnits += 1
            if workUnits >= CanonicalDerivationJSON.cancellationWorkUnitCadence {
                workUnits = 0
                if Task.isCancelled {
                    throw DerivationJSONEmissionError.cancelled
                }
            }
        }

        mutating func write(_ bytes: [UInt8]) throws {
            for byte in bytes {
                try write(byte)
            }
        }

        mutating func write(ascii literal: StaticString) throws {
            var failure: DerivationJSONEmissionError?
            literal.withUTF8Buffer { pointer in
                for byte in pointer {
                    do {
                        try write(byte)
                    } catch let error as DerivationJSONEmissionError {
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
