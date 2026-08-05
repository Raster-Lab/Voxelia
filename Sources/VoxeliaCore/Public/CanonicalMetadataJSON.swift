// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// The `VCMJ-1` canonical metadata JSON codec selected by `ADR-0035`.
///
/// `VCMJ-1` is a JCS-derived UTF-8 record profile with Voxelia-specific
/// semantic shapes, decimal-string 64-bit integers and preservation of all
/// valid Swift Unicode-scalar strings; it is not unmodified JCS or I-JSON.
/// Ingress uses a dedicated iterative parser: Foundation is never the raw
/// trust boundary, and ordinary `Codable` output must never be labelled
/// `VCMJ-1`. Successful parsing proves only canonical syntax and the
/// configured structural invariants; it is never read, logging, export or
/// disclosure authorisation.
public enum CanonicalMetadataJSON {
    /// The fixed version-one document-schema identifier.
    public static let documentSchemaIdentifier = "org.voxelia.metadata-document"
    /// The fixed version-one document-schema version.
    public static let documentSchemaVersion = MetadataSchemaVersion(major: 1, minor: 0)
    /// The grammar-derived hard raw JSON nesting ceiling.
    public static let grammarDerivedMaximumRawNestingDepth: UInt64 = 198
    /// The hard inclusive raw numeric-token ceiling.
    public static let maximumNumericTokenByteCount: UInt64 = 32
    /// The additive cancellation-poll cadence in work units.
    static let cancellationWorkUnitCadence = 4_096

    /// Decodes one complete strict `VCMJ-1` document.
    ///
    /// The convenience array input feeds the same incremental state
    /// machine and charges the same counters; it cannot claim to have
    /// prevented the caller's earlier allocation, and hostile inputs
    /// should prefer a future chunked source. `multiplicityContext` must
    /// be `nil` exactly when the document's `multiplicitySchema` is
    /// `null`; a non-null wire reference must match the supplied expected
    /// reference exactly before payload entries are admitted.
    public static func decodeDocument(
        canonicalBytes: [UInt8],
        limits: CanonicalMetadataIngressLimits,
        multiplicityContext: CanonicalMultiplicityContext?
    ) throws -> CanonicalMetadataDocument {
        var ingress = VCMJIngress(
            bytes: canonicalBytes,
            limits: limits,
            context: multiplicityContext
        )
        return try ingress.parseDocument()
    }

    /// Emits the canonical unique-only document for one collection.
    ///
    /// The complete preflight runs before an output byte exists; a
    /// repeat-bearing collection fails with
    /// ``MetadataJSONEmissionError/invalidValue``.
    public static func encodeUniqueDocument(
        payload: MetadataCollection,
        maximumOutputByteCount: UInt64
    ) throws -> [UInt8] {
        try preflightAdmission(payload, policy: .uniqueKeysOnly)
        return try emitPreflightedDocument(
            multiplicitySchema: nil,
            payload: payload,
            maximumOutputByteCount: maximumOutputByteCount
        )
    }

    /// Emits the canonical configured document for one collection under
    /// exactly the supplied trusted multiplicity context.
    public static func encodeConfiguredDocument(
        payload: MetadataCollection,
        multiplicityContext: CanonicalMultiplicityContext,
        maximumOutputByteCount: UInt64
    ) throws -> [UInt8] {
        try preflightAdmission(
            payload,
            policy: multiplicityContext.multiplicityPolicy
        )
        return try emitPreflightedDocument(
            multiplicitySchema: multiplicityContext.expectedSchema,
            payload: payload,
            maximumOutputByteCount: maximumOutputByteCount
        )
    }

    // MARK: - Emission

    private static func preflightAdmission(
        _ payload: MetadataCollection,
        policy: MetadataMultiplicityPolicy
    ) throws {
        var seenKeys = Set<AnyMetadataKey>()
        for entry in payload.entries {
            if !seenKeys.insert(entry.key).inserted,
                !policy.permitsRepeats(of: entry.key)
            {
                throw MetadataJSONEmissionError.invalidValue
            }
        }
    }

    /// The returned-value emitter: one sizing traversal with checked
    /// arithmetic and the output ceiling, then one writing traversal over
    /// the same shared fragment primitive, then the final cancellation
    /// check at the single success linearisation point.
    private static func emitPreflightedDocument(
        multiplicitySchema: MetadataSchemaReference?,
        payload: MetadataCollection,
        maximumOutputByteCount: UInt64
    ) throws -> [UInt8] {
        var sizingSink = EmissionSink(limit: maximumOutputByteCount, buffer: nil)
        try emitDocument(
            multiplicitySchema: multiplicitySchema,
            payload: payload,
            into: &sizingSink
        )
        let sizedCount = sizingSink.count
        guard let capacity = Int(exactly: sizedCount) else {
            throw MetadataJSONEmissionError.resourceLimitExceeded
        }

        var buffer = [UInt8]()
        buffer.reserveCapacity(capacity)
        var writingSink = EmissionSink(limit: maximumOutputByteCount, buffer: buffer)
        try emitDocument(
            multiplicitySchema: multiplicitySchema,
            payload: payload,
            into: &writingSink
        )
        guard writingSink.count == sizedCount,
            let written = writingSink.buffer,
            UInt64(written.count) == sizedCount
        else {
            assertionFailure("Canonical sizing and writing traversals disagreed.")
            throw MetadataJSONEmissionError.invalidValue
        }
        buffer = written

        if Task.isCancelled {
            throw MetadataJSONEmissionError.cancelled
        }
        return buffer
    }

    private struct EmissionSink {
        let limit: UInt64
        var count: UInt64 = 0
        var buffer: [UInt8]?
        var workUnits = 0

        init(limit: UInt64, buffer: [UInt8]?) {
            self.limit = limit
            self.buffer = buffer
        }

        mutating func write(_ byte: UInt8) throws {
            let (candidate, overflow) = count.addingReportingOverflow(1)
            guard !overflow, candidate <= limit else {
                throw MetadataJSONEmissionError.resourceLimitExceeded
            }
            count = candidate
            buffer?.append(byte)
            workUnits += 1
            if workUnits >= CanonicalMetadataJSON.cancellationWorkUnitCadence {
                workUnits = 0
                if Task.isCancelled {
                    throw MetadataJSONEmissionError.cancelled
                }
            }
        }

        mutating func write(_ bytes: [UInt8]) throws {
            for byte in bytes {
                try write(byte)
            }
        }

        mutating func write(ascii literal: StaticString) throws {
            for byte in literal.description.utf8 {
                try write(byte)
            }
        }
    }

    private enum EmissionTask {
        case fragment([UInt8])
        case value(MetadataValue)
    }

    private static func emitDocument(
        multiplicitySchema: MetadataSchemaReference?,
        payload: MetadataCollection,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(
            ascii: #"{"documentSchema":{"identifier":"org.voxelia.metadata-document","#
        )
        try sink.write(ascii: #""version":{"major":1,"minor":0}},"multiplicitySchema":"#)
        if let multiplicitySchema {
            try sink.write(ascii: #"{"identifier":"#)
            try sink.write(canonicalStringToken(multiplicitySchema.identifier))
            try sink.write(ascii: #","version":{"major":"#)
            try sink.write(Array(String(multiplicitySchema.version.major).utf8))
            try sink.write(ascii: #","minor":"#)
            try sink.write(Array(String(multiplicitySchema.version.minor).utf8))
            try sink.write(ascii: "}}")
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","payload":{"entries":["#)
        for (index, entry) in payload.entries.enumerated() {
            if index > 0 {
                try sink.write(UInt8(ascii: ","))
            }
            try emitEntry(entry, into: &sink)
        }
        try sink.write(ascii: "]}}")
    }

    private static func emitEntry(
        _ entry: MetadataEntry,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"key":{"name":"#)
        try sink.write(canonicalStringToken(entry.key.name))
        try sink.write(ascii: #","namespace":"#)
        try sink.write(canonicalStringToken(entry.key.namespace))
        try sink.write(ascii: #"},"privacyClass":"#)
        try sink.write(canonicalStringToken(entry.privacyClass.rawValue))
        try sink.write(ascii: #","value":"#)
        try emitValue(entry.value, into: &sink)
        try sink.write(UInt8(ascii: "}"))
    }

    /// Iterative canonical value emission with an explicit task stack.
    private static func emitValue(
        _ root: MetadataValue,
        into sink: inout EmissionSink
    ) throws {
        var stack: [EmissionTask] = [.value(root)]
        while let task = stack.popLast() {
            switch task {
            case .fragment(let fragment):
                try sink.write(fragment)
            case .value(let value):
                try emitOneValue(value, stack: &stack, into: &sink)
            }
        }
    }

    private static func emitOneValue(
        _ value: MetadataValue,
        stack: inout [EmissionTask],
        into sink: inout EmissionSink
    ) throws {
        switch value {
        case .boolean(let payload):
            try sink.write(ascii: #"{"boolean":"#)
            try sink.write(ascii: payload ? "true" : "false")
            try sink.write(UInt8(ascii: "}"))
        case .signedInteger(let payload):
            try sink.write(ascii: #"{"signedInteger":""#)
            try sink.write(Array(String(payload).utf8))
            try sink.write(ascii: #""}"#)
        case .unsignedInteger(let payload):
            try sink.write(ascii: #"{"unsignedInteger":""#)
            try sink.write(Array(String(payload).utf8))
            try sink.write(ascii: #""}"#)
        case .floatingPoint(let payload):
            guard let token = canonicalNumberToken(payload.value) else {
                throw MetadataJSONEmissionError.invalidValue
            }
            try sink.write(ascii: #"{"floatingPoint":"#)
            try sink.write(token)
            try sink.write(UInt8(ascii: "}"))
        case .string(let payload):
            try sink.write(ascii: #"{"string":"#)
            try sink.write(canonicalStringToken(payload))
            try sink.write(UInt8(ascii: "}"))
        case .binary(let payload):
            try sink.write(ascii: #"{"binary":"#)
            try sink.write(
                canonicalStringToken(MetadataBinary.encodeCanonicalBase64(payload.bytes))
            )
            try sink.write(UInt8(ascii: "}"))
        case .instant(let payload):
            try sink.write(ascii: #"{"instant":"#)
            try sink.write(canonicalStringToken(payload.utcString))
            try sink.write(UInt8(ascii: "}"))
        case .unit(let payload):
            try emitUnit(payload, into: &sink)
        case .code(let payload):
            try emitCode(payload, into: &sink)
        case .array(let payload):
            try sink.write(ascii: #"{"array":["#)
            stack.append(.fragment(Array("]}".utf8)))
            for (index, element) in payload.values.enumerated().reversed() {
                stack.append(.value(element))
                if index > 0 {
                    stack.append(.fragment([UInt8(ascii: ",")]))
                }
            }
        case .object(let payload):
            try sink.write(ascii: #"{"object":["#)
            stack.append(.fragment(Array("]}".utf8)))
            for (index, member) in payload.members.enumerated().reversed() {
                stack.append(.fragment([UInt8(ascii: "}")]))
                stack.append(.value(member.value))
                var prefix = Array(#"{"key":{"name":"#.utf8)
                prefix.append(contentsOf: canonicalStringToken(member.key.name))
                prefix.append(contentsOf: Array(#","namespace":"#.utf8))
                prefix.append(contentsOf: canonicalStringToken(member.key.namespace))
                prefix.append(contentsOf: Array(#"},"value":"#.utf8))
                stack.append(.fragment(prefix))
                if index > 0 {
                    stack.append(.fragment([UInt8(ascii: ",")]))
                }
            }
        }
    }

    private static func emitUnit(
        _ unit: MeasurementUnit,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"unit":{"code":"#)
        try sink.write(canonicalStringToken(unit.code))
        try sink.write(ascii: #","dimension":"#)
        if let dimension = unit.dimension {
            try sink.write(canonicalStringToken(dimension.rawValue))
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","displayName":"#)
        if let displayName = unit.displayName {
            try sink.write(canonicalStringToken(displayName))
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","namespace":"#)
        try sink.write(canonicalStringToken(unit.namespace))
        try sink.write(ascii: #","offsetToCanonical":"#)
        if let offset = unit.offsetToCanonical {
            guard let token = canonicalNumberToken(offset) else {
                throw MetadataJSONEmissionError.invalidValue
            }
            try sink.write(token)
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","scaleToCanonical":"#)
        if let scale = unit.scaleToCanonical {
            guard let token = canonicalNumberToken(scale) else {
                throw MetadataJSONEmissionError.invalidValue
            }
            try sink.write(token)
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: "}}")
    }

    private static func emitCode(
        _ code: CodedConcept,
        into sink: inout EmissionSink
    ) throws {
        try sink.write(ascii: #"{"code":{"meaning":"#)
        if let meaning = code.meaning {
            try sink.write(canonicalStringToken(meaning))
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: #","scheme":"#)
        try sink.write(canonicalStringToken(code.scheme))
        try sink.write(ascii: #","value":"#)
        try sink.write(canonicalStringToken(code.value))
        try sink.write(ascii: #","version":"#)
        if let version = code.version {
            try sink.write(canonicalStringToken(version))
        } else {
            try sink.write(ascii: "null")
        }
        try sink.write(ascii: "}}")
    }

    /// The RFC 8785 string-escaping algorithm producing one quoted token.
    static func canonicalStringToken(_ value: String) -> [UInt8] {
        var token: [UInt8] = [UInt8(ascii: "\"")]
        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x22:
                token.append(contentsOf: Array(#"\""#.utf8))
            case 0x5C:
                token.append(contentsOf: Array(#"\\"#.utf8))
            case 0x08:
                token.append(contentsOf: Array(#"\b"#.utf8))
            case 0x09:
                token.append(contentsOf: Array(#"\t"#.utf8))
            case 0x0A:
                token.append(contentsOf: Array(#"\n"#.utf8))
            case 0x0C:
                token.append(contentsOf: Array(#"\f"#.utf8))
            case 0x0D:
                token.append(contentsOf: Array(#"\r"#.utf8))
            case 0x00...0x1F:
                let hexDigits = "0123456789abcdef".utf8.map { $0 }
                token.append(contentsOf: Array(#"\u00"#.utf8))
                token.append(hexDigits[Int(scalar.value >> 4)])
                token.append(hexDigits[Int(scalar.value & 0xF)])
            default:
                token.append(contentsOf: Array(String(scalar).utf8))
            }
        }
        token.append(UInt8(ascii: "\""))
        return token
    }

    /// The RFC 8785/ECMAScript shortest round-trip number token, derived
    /// from the Swift standard library's shortest-digit conversion and the
    /// ECMAScript `Number::toString` positional rules. Returns `nil` for a
    /// non-finite input; negative zero produces `0`.
    static func canonicalNumberToken(_ value: Double) -> [UInt8]? {
        guard value.isFinite else {
            return nil
        }
        if value == 0 {
            return [UInt8(ascii: "0")]
        }

        var token = [UInt8]()
        if value < 0 {
            token.append(UInt8(ascii: "-"))
        }
        let description = String(value.magnitude)

        var mantissa = description
        var exponent = 0
        if let eIndex = description.firstIndex(of: "e") {
            mantissa = String(description[..<eIndex])
            exponent = Int(description[description.index(after: eIndex)...]) ?? 0
        }
        var integerDigits = mantissa
        var fractionDigits = ""
        if let dotIndex = mantissa.firstIndex(of: ".") {
            integerDigits = String(mantissa[..<dotIndex])
            fractionDigits = String(mantissa[mantissa.index(after: dotIndex)...])
        }

        var digits = Array((integerDigits + fractionDigits).utf8)
        var pointPosition = integerDigits.utf8.count + exponent
        while digits.count > 1, digits.first == UInt8(ascii: "0") {
            digits.removeFirst()
            pointPosition -= 1
        }
        while digits.count > 1, digits.last == UInt8(ascii: "0") {
            digits.removeLast()
        }

        let digitCount = digits.count
        let zero = UInt8(ascii: "0")
        if digitCount <= pointPosition, pointPosition <= 21 {
            token.append(contentsOf: digits)
            token.append(contentsOf: repeatElement(zero, count: pointPosition - digitCount))
        } else if 0 < pointPosition, pointPosition <= 21 {
            token.append(contentsOf: digits[0..<pointPosition])
            token.append(UInt8(ascii: "."))
            token.append(contentsOf: digits[pointPosition...])
        } else if -6 < pointPosition, pointPosition <= 0 {
            token.append(zero)
            token.append(UInt8(ascii: "."))
            token.append(contentsOf: repeatElement(zero, count: -pointPosition))
            token.append(contentsOf: digits)
        } else {
            token.append(digits[0])
            if digitCount > 1 {
                token.append(UInt8(ascii: "."))
                token.append(contentsOf: digits[1...])
            }
            token.append(UInt8(ascii: "e"))
            let scientificExponent = pointPosition - 1
            token.append(UInt8(ascii: scientificExponent >= 0 ? "+" : "-"))
            token.append(contentsOf: Array(String(scientificExponent.magnitude).utf8))
        }
        return token
    }
}
