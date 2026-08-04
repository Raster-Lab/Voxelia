// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// The dedicated iterative `VCMJ-1` ingress state machine.
///
/// The parser consumes bytes in source order, charges every raw byte
/// before interpreting it, validates canonical lexemes as they arrive,
/// admits keys before their values, constructs values through the
/// accepted semantic invariants and publishes one immutable document only
/// after complete input and all validation. Failure or cancellation
/// discards all partial state; errors are payload-free.
struct VCMJIngress {
    private let bytes: [UInt8]
    private var index = 0
    private let limits: CanonicalMetadataIngressLimits
    private let context: CanonicalMultiplicityContext?

    private var chargedDocumentBytes: UInt64 = 0
    private var openFrames: UInt64 = 0
    private var workUnits = 0

    init(
        bytes: [UInt8],
        limits: CanonicalMetadataIngressLimits,
        context: CanonicalMultiplicityContext?
    ) {
        self.bytes = bytes
        self.limits = limits
        self.context = context
    }

    // MARK: - Byte cursor

    private mutating func chargeWork() throws {
        workUnits += 1
        if workUnits >= CanonicalMetadataJSON.cancellationWorkUnitCadence {
            workUnits = 0
            if Task.isCancelled {
                throw MetadataJSONIngressError.cancelled
            }
        }
    }

    /// Charges the next raw document byte before interpreting it.
    private mutating func nextByte() throws -> UInt8 {
        let (candidate, overflow) = chargedDocumentBytes.addingReportingOverflow(1)
        guard !overflow, candidate <= limits.maximumRawDocumentByteCount else {
            throw MetadataJSONIngressError.resourceLimitExceeded
        }
        guard index < bytes.count else {
            throw MetadataJSONIngressError.invalidDocument
        }
        chargedDocumentBytes = candidate
        let byte = bytes[index]
        index += 1
        try chargeWork()
        return byte
    }

    private func peekByte() -> UInt8? {
        index < bytes.count ? bytes[index] : nil
    }

    private mutating func expect(ascii literal: StaticString) throws {
        var expected = [UInt8]()
        literal.withUTF8Buffer { expected.append(contentsOf: $0) }
        for byte in expected {
            guard try nextByte() == byte else {
                throw MetadataJSONIngressError.invalidDocument
            }
        }
    }

    private mutating func pushFrame(open: StaticString) throws {
        try expect(ascii: open)
        let candidate = openFrames + 1
        guard
            candidate <= limits.maximumRawNestingDepth,
            candidate <= CanonicalMetadataJSON.grammarDerivedMaximumRawNestingDepth
        else {
            throw MetadataJSONIngressError.resourceLimitExceeded
        }
        openFrames = candidate
    }

    private mutating func popFrame(close: StaticString) throws {
        try expect(ascii: close)
        openFrames -= 1
    }

    // MARK: - Document

    mutating func parseDocument() throws -> CanonicalMetadataDocument {
        try preflightContext()
        if Task.isCancelled {
            throw MetadataJSONIngressError.cancelled
        }

        try pushFrame(open: "{")
        try expect(ascii: #""documentSchema":"#)
        try pushFrame(open: "{")
        try expect(ascii: #""identifier":"#)
        let documentIdentifier = try lexString()
        guard
            documentIdentifier.utf8.elementsEqual(
                CanonicalMetadataJSON.documentSchemaIdentifier.utf8
            )
        else {
            throw MetadataJSONIngressError.invalidDocument
        }
        try expect(ascii: #","version":"#)
        let documentVersion = try parseVersionObject()
        try popFrame(close: "}")
        guard documentVersion == CanonicalMetadataJSON.documentSchemaVersion else {
            throw MetadataJSONIngressError.unsupportedSchemaVersion
        }

        try expect(ascii: #","multiplicitySchema":"#)
        let wireMultiplicitySchema = try parseMultiplicitySchema()
        let policy: MetadataMultiplicityPolicy
        switch (wireMultiplicitySchema, context) {
        case (nil, nil):
            policy = .uniqueKeysOnly
        case (let wireReference?, let context?):
            guard wireReference == context.expectedSchema else {
                throw MetadataJSONIngressError.invalidDocument
            }
            policy = context.multiplicityPolicy
        default:
            throw MetadataJSONIngressError.invalidDocument
        }

        try expect(ascii: #","payload":"#)
        try pushFrame(open: "{")
        try expect(ascii: #""entries":"#)
        let entries = try parseEntries(policy: policy)
        try popFrame(close: "}")
        try popFrame(close: "}")

        if index < bytes.count {
            _ = try nextByte()
            throw MetadataJSONIngressError.invalidDocument
        }

        let payload: MetadataCollection
        do {
            payload = try MetadataCollection(
                entries: entries,
                multiplicityPolicy: policy
            )
        } catch MetadataCollectionError.duplicateKey {
            throw MetadataJSONIngressError.invalidDocument
        } catch {
            throw MetadataJSONIngressError.resourceLimitExceeded
        }

        if Task.isCancelled {
            throw MetadataJSONIngressError.cancelled
        }
        return CanonicalMetadataDocument(
            documentSchema: try makeDocumentSchemaReference(),
            multiplicitySchema: wireMultiplicitySchema,
            payload: payload
        )
    }

    private func makeDocumentSchemaReference() throws -> MetadataSchemaReference {
        do {
            return try MetadataSchemaReference(
                identifier: CanonicalMetadataJSON.documentSchemaIdentifier,
                version: CanonicalMetadataJSON.documentSchemaVersion
            )
        } catch {
            throw MetadataJSONIngressError.invalidDocument
        }
    }

    /// Preflights the trusted context before any input byte is read.
    private mutating func preflightContext() throws {
        guard let context else {
            return
        }
        let policy = context.multiplicityPolicy
        guard
            policy.retainedKeyCount <= context.maximumRetainedPolicyKeyCount,
            policy.retainedLogicalKeyByteCount
                <= context.maximumRetainedPolicyKeyByteCount,
            UInt64(context.expectedSchema.identifier.utf8.count)
                <= limits.maximumDecodedStringByteCount
        else {
            throw MetadataJSONIngressError.resourceLimitExceeded
        }
    }

    private mutating func parseMultiplicitySchema() throws -> MetadataSchemaReference? {
        if peekByte() == UInt8(ascii: "n") {
            try expect(ascii: "null")
            return nil
        }
        try pushFrame(open: "{")
        try expect(ascii: #""identifier":"#)
        let identifier = try lexString()
        try validateSchemaIdentifier(identifier)
        try expect(ascii: #","version":"#)
        let version = try parseVersionObject()
        try popFrame(close: "}")
        do {
            return try MetadataSchemaReference(identifier: identifier, version: version)
        } catch {
            throw MetadataJSONIngressError.invalidDocument
        }
    }

    /// Re-validates a wire schema identifier with ingress error mapping:
    /// grammar failures are `invalidDocument`; hard label/total byte
    /// ceilings are `resourceLimitExceeded`, each character validated
    /// before its charge.
    private func validateSchemaIdentifier(_ identifier: String) throws {
        do {
            try MetadataSchemaReference.validateIdentifier(identifier)
        } catch MetadataSchemaReferenceError.identifierByteLimitExceeded {
            throw MetadataJSONIngressError.resourceLimitExceeded
        } catch {
            throw MetadataJSONIngressError.invalidDocument
        }
    }

    private mutating func parseVersionObject() throws -> MetadataSchemaVersion {
        try pushFrame(open: "{")
        try expect(ascii: #""major":"#)
        let major = try parseUInt32Number()
        try expect(ascii: #","minor":"#)
        let minor = try parseUInt32Number()
        try popFrame(close: "}")
        return MetadataSchemaVersion(major: major, minor: minor)
    }

    /// One minimal unsigned decimal number in the `UInt32` range.
    private mutating func parseUInt32Number() throws -> UInt32 {
        let first = try nextByte()
        guard first >= UInt8(ascii: "0"), first <= UInt8(ascii: "9") else {
            throw MetadataJSONIngressError.invalidDocument
        }
        if first == UInt8(ascii: "0") {
            if let next = peekByte(), next >= UInt8(ascii: "0"),
                next <= UInt8(ascii: "9")
            {
                throw MetadataJSONIngressError.invalidDocument
            }
            return 0
        }
        var value = UInt64(first - UInt8(ascii: "0"))
        while let next = peekByte(), next >= UInt8(ascii: "0"),
            next <= UInt8(ascii: "9")
        {
            _ = try nextByte()
            value = value * 10 + UInt64(next - UInt8(ascii: "0"))
            guard value <= UInt64(UInt32.max) else {
                throw MetadataJSONIngressError.invalidDocument
            }
        }
        return UInt32(value)
    }

    // MARK: - Entries

    private mutating func parseEntries(
        policy: MetadataMultiplicityPolicy
    ) throws -> [MetadataEntry] {
        try pushFrame(open: "[")
        var entries = [MetadataEntry]()
        var seenKeys = Set<AnyMetadataKey>()
        var aggregateElements: UInt64 = 0
        var aggregatePayload: UInt64 = 0

        if peekByte() == UInt8(ascii: "]") {
            try popFrame(close: "]")
            return entries
        }

        while true {
            let nextCount = UInt64(entries.count) + 1
            guard
                nextCount <= limits.maximumDirectMemberCount,
                nextCount <= MetadataCollection.maximumEntryCount
            else {
                throw MetadataJSONIngressError.resourceLimitExceeded
            }

            let entry = try parseEntry(policy: policy, seenKeys: &seenKeys)

            let metrics = entry.value.metrics
            aggregateElements = try addAggregate(aggregateElements, metrics.elements)
            guard
                aggregateElements
                    <= MetadataCollection.maximumAggregateStructuralElementCount
            else {
                throw MetadataJSONIngressError.resourceLimitExceeded
            }
            aggregatePayload = try addAggregate(
                aggregatePayload,
                metrics.payload
                    &+ UInt64(entry.key.namespace.utf8.count)
                    &+ UInt64(entry.key.name.utf8.count)
            )
            guard
                aggregatePayload
                    <= MetadataCollection.maximumAggregateLogicalVariablePayloadByteCount
            else {
                throw MetadataJSONIngressError.resourceLimitExceeded
            }
            entries.append(entry)

            let separator = try nextByte()
            if separator == UInt8(ascii: ",") {
                continue
            }
            if separator == UInt8(ascii: "]") {
                openFrames -= 1
                return entries
            }
            throw MetadataJSONIngressError.invalidDocument
        }
    }

    private func addAggregate(_ total: UInt64, _ addition: UInt64) throws -> UInt64 {
        let (sum, overflow) = total.addingReportingOverflow(addition)
        guard !overflow else {
            throw MetadataJSONIngressError.resourceLimitExceeded
        }
        return sum
    }

    private mutating func parseEntry(
        policy: MetadataMultiplicityPolicy,
        seenKeys: inout Set<AnyMetadataKey>
    ) throws -> MetadataEntry {
        try pushFrame(open: "{")
        try expect(ascii: #""key":"#)
        let key = try parseKeyObject()

        // Exact duplicate/policy admission before the class or value is
        // read, so a disallowed occurrence cannot attach a large value.
        if !seenKeys.insert(key).inserted, !policy.permitsRepeats(of: key) {
            throw MetadataJSONIngressError.invalidDocument
        }

        try expect(ascii: #","privacyClass":"#)
        let classToken = try lexString()
        guard let privacyClass = MetadataPrivacyClass(rawValue: classToken) else {
            throw MetadataJSONIngressError.invalidDocument
        }

        try expect(ascii: #","value":"#)
        let value = try parseValue()
        try popFrame(close: "}")
        return MetadataEntry(key: key, value: value, privacyClass: privacyClass)
    }

    private mutating func parseKeyObject() throws -> AnyMetadataKey {
        try pushFrame(open: "{")
        try expect(ascii: #""name":"#)
        let name = try lexString()
        try expect(ascii: #","namespace":"#)
        let namespace = try lexString()
        try popFrame(close: "}")
        do {
            return try AnyMetadataKey(namespace: namespace, name: name)
        } catch {
            throw MetadataJSONIngressError.invalidDocument
        }
    }

    // MARK: - Values

    private enum SemanticFrame {
        case array(ContiguousArray<MetadataValue>)
        case object(ContiguousArray<MetadataObject.Member>, previous: AnyMetadataKey?)
        case memberValue(AnyMetadataKey)
    }

    private func containerNesting(_ frames: [SemanticFrame]) -> Int {
        frames.reduce(0) { count, frame in
            switch frame {
            case .array, .object:
                count + 1
            case .memberValue:
                count
            }
        }
    }

    /// The iterative canonical value parser with an explicit frame stack.
    private mutating func parseValue() throws -> MetadataValue {
        var frames = [SemanticFrame]()

        while true {
            var completed = try parseValueAtom(frames: &frames)
            guard var value = completed else {
                continue
            }

            reduction: while true {
                guard let top = frames.last else {
                    return value
                }
                switch top {
                case .array(var elements):
                    frames.removeLast()
                    guard
                        UInt64(elements.count) + 1 <= limits.maximumDirectMemberCount
                    else {
                        throw MetadataJSONIngressError.resourceLimitExceeded
                    }
                    elements.append(value)
                    let separator = try nextByte()
                    if separator == UInt8(ascii: ",") {
                        frames.append(.array(elements))
                        break reduction
                    }
                    guard separator == UInt8(ascii: "]") else {
                        throw MetadataJSONIngressError.invalidDocument
                    }
                    openFrames -= 1
                    try popFrame(close: "}")
                    value = try makeArray(elements)
                case .memberValue(let key):
                    frames.removeLast()
                    guard case .object(var members, _) = frames.removeLast() else {
                        throw MetadataJSONIngressError.invalidDocument
                    }
                    guard
                        UInt64(members.count) + 1 <= limits.maximumDirectMemberCount
                    else {
                        throw MetadataJSONIngressError.resourceLimitExceeded
                    }
                    members.append(MetadataObject.Member(key: key, value: value))
                    try popFrame(close: "}")
                    let separator = try nextByte()
                    if separator == UInt8(ascii: ",") {
                        frames.append(.object(members, previous: key))
                        try parseMemberKey(frames: &frames)
                        break reduction
                    }
                    guard separator == UInt8(ascii: "]") else {
                        throw MetadataJSONIngressError.invalidDocument
                    }
                    openFrames -= 1
                    try popFrame(close: "}")
                    value = try makeObject(members)
                case .object:
                    throw MetadataJSONIngressError.invalidDocument
                }
            }
            completed = nil
        }
    }

    /// Parses one tagged value; containers push a frame and return `nil`.
    private mutating func parseValueAtom(
        frames: inout [SemanticFrame]
    ) throws -> MetadataValue? {
        try pushFrame(open: "{")
        let tag = try lexString()
        try expect(ascii: ":")

        switch tag {
        case "boolean":
            let value: Bool
            if peekByte() == UInt8(ascii: "t") {
                try expect(ascii: "true")
                value = true
            } else {
                try expect(ascii: "false")
                value = false
            }
            try popFrame(close: "}")
            return .boolean(value)
        case "signedInteger":
            let token = try lexString()
            guard let value = Self.parseCanonicalInt64(token) else {
                throw MetadataJSONIngressError.invalidDocument
            }
            try popFrame(close: "}")
            return .signedInteger(value)
        case "unsignedInteger":
            let token = try lexString()
            guard let value = Self.parseCanonicalUInt64(token) else {
                throw MetadataJSONIngressError.invalidDocument
            }
            try popFrame(close: "}")
            return .unsignedInteger(value)
        case "floatingPoint":
            let value = try parseCanonicalBinary64()
            let wrapped: MetadataFloatingPoint
            do {
                wrapped = try MetadataFloatingPoint(value: value)
            } catch {
                throw MetadataJSONIngressError.invalidDocument
            }
            try popFrame(close: "}")
            return .floatingPoint(wrapped)
        case "string":
            let value = try lexString()
            try popFrame(close: "}")
            return .string(value)
        case "binary":
            let value = try lexCanonicalBase64()
            try popFrame(close: "}")
            return .binary(value)
        case "instant":
            let token = try lexString()
            let instant: CanonicalInstant
            do {
                instant = try CanonicalInstant(utcString: token)
            } catch {
                throw MetadataJSONIngressError.invalidDocument
            }
            try popFrame(close: "}")
            return .instant(instant)
        case "unit":
            let unit = try parseUnitObject()
            try popFrame(close: "}")
            return .unit(unit)
        case "code":
            let code = try parseCodeObject()
            try popFrame(close: "}")
            return .code(code)
        case "array":
            try chargeSemanticContainer(frames)
            try pushFrame(open: "[")
            if peekByte() == UInt8(ascii: "]") {
                try popFrame(close: "]")
                try popFrame(close: "}")
                return try makeArray([])
            }
            frames.append(.array([]))
            return nil
        case "object":
            try chargeSemanticContainer(frames)
            try pushFrame(open: "[")
            if peekByte() == UInt8(ascii: "]") {
                try popFrame(close: "]")
                try popFrame(close: "}")
                return try makeObject([])
            }
            frames.append(.object([], previous: nil))
            try parseMemberKey(frames: &frames)
            return nil
        default:
            throw MetadataJSONIngressError.invalidDocument
        }
    }

    /// Semantic container-depth guard during descent: an open container at
    /// nesting level 65 can never produce a valid depth-64 value.
    private func chargeSemanticContainer(_ frames: [SemanticFrame]) throws {
        guard containerNesting(frames) + 1 <= MetadataValue.maximumContainerDepth
        else {
            throw MetadataJSONIngressError.resourceLimitExceeded
        }
    }

    /// Parses one recursive member's key, checks strictly increasing
    /// canonical order before the member's value is read, and pushes the
    /// awaiting-value frame.
    private mutating func parseMemberKey(frames: inout [SemanticFrame]) throws {
        guard case .object(let members, let previous) = frames.last else {
            throw MetadataJSONIngressError.invalidDocument
        }
        _ = members
        try pushFrame(open: "{")
        try expect(ascii: #""key":"#)
        let key = try parseKeyObject()
        if let previous {
            guard MetadataObject.precedesCanonically(previous, key) else {
                throw MetadataJSONIngressError.invalidDocument
            }
        }
        try expect(ascii: #","value":"#)
        frames.append(.memberValue(key))
    }

    private func makeArray(
        _ elements: ContiguousArray<MetadataValue>
    ) throws -> MetadataValue {
        do {
            return .array(try MetadataArray(values: elements))
        } catch MetadataValueError.duplicateObjectKey {
            throw MetadataJSONIngressError.invalidDocument
        } catch {
            throw MetadataJSONIngressError.resourceLimitExceeded
        }
    }

    private func makeObject(
        _ members: ContiguousArray<MetadataObject.Member>
    ) throws -> MetadataValue {
        do {
            return .object(try MetadataObject(members: members))
        } catch MetadataValueError.duplicateObjectKey {
            throw MetadataJSONIngressError.invalidDocument
        } catch {
            throw MetadataJSONIngressError.resourceLimitExceeded
        }
    }

    private mutating func parseUnitObject() throws -> MeasurementUnit {
        try pushFrame(open: "{")
        try expect(ascii: #""code":"#)
        let code = try lexString()
        try expect(ascii: #","dimension":"#)
        var dimension: UnitDimension?
        if peekByte() == UInt8(ascii: "n") {
            try expect(ascii: "null")
        } else {
            let token = try lexString()
            guard let parsed = UnitDimension(rawValue: token) else {
                throw MetadataJSONIngressError.invalidDocument
            }
            dimension = parsed
        }
        try expect(ascii: #","displayName":"#)
        var displayName: String?
        if peekByte() == UInt8(ascii: "n") {
            try expect(ascii: "null")
        } else {
            displayName = try lexString()
        }
        try expect(ascii: #","namespace":"#)
        let namespace = try lexString()
        try expect(ascii: #","offsetToCanonical":"#)
        var offset: Double?
        if peekByte() == UInt8(ascii: "n") {
            try expect(ascii: "null")
        } else {
            offset = try parseCanonicalBinary64()
        }
        try expect(ascii: #","scaleToCanonical":"#)
        var scale: Double?
        if peekByte() == UInt8(ascii: "n") {
            try expect(ascii: "null")
        } else {
            scale = try parseCanonicalBinary64()
        }
        try popFrame(close: "}")
        do {
            return try MeasurementUnit(
                namespace: namespace,
                code: code,
                displayName: displayName,
                dimension: dimension,
                scaleToCanonical: scale,
                offsetToCanonical: offset
            )
        } catch {
            throw MetadataJSONIngressError.invalidDocument
        }
    }

    private mutating func parseCodeObject() throws -> CodedConcept {
        try pushFrame(open: "{")
        try expect(ascii: #""meaning":"#)
        var meaning: String?
        if peekByte() == UInt8(ascii: "n") {
            try expect(ascii: "null")
        } else {
            meaning = try lexString()
        }
        try expect(ascii: #","scheme":"#)
        let scheme = try lexString()
        try expect(ascii: #","value":"#)
        let value = try lexString()
        try expect(ascii: #","version":"#)
        var version: String?
        if peekByte() == UInt8(ascii: "n") {
            try expect(ascii: "null")
        } else {
            version = try lexString()
        }
        try popFrame(close: "}")
        do {
            return try CodedConcept(
                scheme: scheme,
                value: value,
                meaning: meaning,
                version: version
            )
        } catch {
            throw MetadataJSONIngressError.invalidDocument
        }
    }

    // MARK: - Lexical tokens

    private struct TokenBudget {
        var charged: UInt64 = 0
        let limit: UInt64

        mutating func charge() throws {
            let candidate = charged + 1
            guard candidate <= limit else {
                throw MetadataJSONIngressError.resourceLimitExceeded
            }
            charged = candidate
        }
    }

    /// Lexes one canonical JSON string token: strict UTF-8, canonical
    /// escapes only, raw token and decoded-string budgets charged before
    /// growth.
    private mutating func lexString() throws -> String {
        var token = TokenBudget(limit: limits.maximumRawTokenByteCount)
        var decoded = TokenBudget(limit: limits.maximumDecodedStringByteCount)
        var output = [UInt8]()

        try token.charge()
        guard try nextByte() == UInt8(ascii: "\"") else {
            throw MetadataJSONIngressError.invalidDocument
        }

        while true {
            try token.charge()
            let byte = try nextByte()
            if byte == UInt8(ascii: "\"") {
                return String(decoding: output, as: UTF8.self)
            }
            if byte == UInt8(ascii: "\\") {
                try token.charge()
                let escape = try nextByte()
                let decodedByte: UInt8
                switch escape {
                case UInt8(ascii: "\""):
                    decodedByte = 0x22
                case UInt8(ascii: "\\"):
                    decodedByte = 0x5C
                case UInt8(ascii: "b"):
                    decodedByte = 0x08
                case UInt8(ascii: "t"):
                    decodedByte = 0x09
                case UInt8(ascii: "n"):
                    decodedByte = 0x0A
                case UInt8(ascii: "f"):
                    decodedByte = 0x0C
                case UInt8(ascii: "r"):
                    decodedByte = 0x0D
                case UInt8(ascii: "u"):
                    decodedByte = try lexCanonicalControlEscape(&token)
                default:
                    throw MetadataJSONIngressError.invalidDocument
                }
                try decoded.charge()
                output.append(decodedByte)
                continue
            }
            if byte < 0x20 {
                throw MetadataJSONIngressError.invalidDocument
            }
            if byte < 0x80 {
                try decoded.charge()
                output.append(byte)
                continue
            }
            try lexUTF8Continuation(
                lead: byte,
                token: &token,
                decoded: &decoded,
                output: &output
            )
        }
    }

    /// The `\u00xx` lowercase spelling admitted only for controls without
    /// a short escape.
    private mutating func lexCanonicalControlEscape(
        _ token: inout TokenBudget
    ) throws -> UInt8 {
        var value: UInt32 = 0
        for _ in 0..<4 {
            try token.charge()
            let hex = try nextByte()
            let digit: UInt32
            switch hex {
            case UInt8(ascii: "0")...UInt8(ascii: "9"):
                digit = UInt32(hex - UInt8(ascii: "0"))
            case UInt8(ascii: "a")...UInt8(ascii: "f"):
                digit = UInt32(hex - UInt8(ascii: "a")) + 10
            default:
                throw MetadataJSONIngressError.invalidDocument
            }
            value = value << 4 | digit
        }
        let shortEscapes: Set<UInt32> = [0x08, 0x09, 0x0A, 0x0C, 0x0D]
        guard value <= 0x1F, !shortEscapes.contains(value) else {
            throw MetadataJSONIngressError.invalidDocument
        }
        return UInt8(value)
    }

    /// Strict multi-byte UTF-8 validation: no overlong forms, surrogates,
    /// out-of-range scalars or truncation.
    private mutating func lexUTF8Continuation(
        lead: UInt8,
        token: inout TokenBudget,
        decoded: inout TokenBudget,
        output: inout [UInt8]
    ) throws {
        let continuationCount: Int
        let firstLow: UInt8
        let firstHigh: UInt8
        switch lead {
        case 0xC2...0xDF:
            continuationCount = 1
            firstLow = 0x80
            firstHigh = 0xBF
        case 0xE0:
            continuationCount = 2
            firstLow = 0xA0
            firstHigh = 0xBF
        case 0xE1...0xEC, 0xEE, 0xEF:
            continuationCount = 2
            firstLow = 0x80
            firstHigh = 0xBF
        case 0xED:
            continuationCount = 2
            firstLow = 0x80
            firstHigh = 0x9F
        case 0xF0:
            continuationCount = 3
            firstLow = 0x90
            firstHigh = 0xBF
        case 0xF1...0xF3:
            continuationCount = 3
            firstLow = 0x80
            firstHigh = 0xBF
        case 0xF4:
            continuationCount = 3
            firstLow = 0x80
            firstHigh = 0x8F
        default:
            throw MetadataJSONIngressError.invalidDocument
        }

        var sequence = [lead]
        for position in 0..<continuationCount {
            try token.charge()
            let continuation = try nextByte()
            let low = position == 0 ? firstLow : 0x80
            let high = position == 0 ? firstHigh : 0xBF
            guard continuation >= low, continuation <= high else {
                throw MetadataJSONIngressError.invalidDocument
            }
            sequence.append(continuation)
        }
        for byte in sequence {
            try decoded.charge()
            output.append(byte)
        }
    }

    /// Lexes one canonical padded standard-Base64 string with encoded and
    /// decoded budgets.
    private mutating func lexCanonicalBase64() throws -> MetadataBinary {
        var token = TokenBudget(limit: limits.maximumRawTokenByteCount)
        var encoded = TokenBudget(limit: limits.maximumEncodedBinaryByteCount)
        var content = [UInt8]()

        try token.charge()
        guard try nextByte() == UInt8(ascii: "\"") else {
            throw MetadataJSONIngressError.invalidDocument
        }
        while true {
            try token.charge()
            let byte = try nextByte()
            if byte == UInt8(ascii: "\"") {
                break
            }
            let isAlphabet =
                (byte >= UInt8(ascii: "A") && byte <= UInt8(ascii: "Z"))
                || (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
                || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9"))
                || byte == UInt8(ascii: "+") || byte == UInt8(ascii: "/")
                || byte == UInt8(ascii: "=")
            guard isAlphabet else {
                throw MetadataJSONIngressError.invalidDocument
            }
            try encoded.charge()
            content.append(byte)
        }

        guard let decodedBytes = MetadataBinary.decodeCanonicalBase64(content) else {
            throw MetadataJSONIngressError.invalidDocument
        }
        guard UInt64(decodedBytes.count) <= limits.maximumDecodedBinaryByteCount else {
            throw MetadataJSONIngressError.resourceLimitExceeded
        }
        return MetadataBinary(bytes: decodedBytes)
    }

    /// Lexes one RFC 8259 number token under the 32-byte canonical
    /// ceiling, converts it with the standard library's correctly rounded
    /// parser, and byte-compares the canonical re-emission to reject every
    /// noncanonical alias.
    private mutating func parseCanonicalBinary64() throws -> Double {
        var token = TokenBudget(limit: limits.maximumRawTokenByteCount)
        var raw = [UInt8]()

        func consume() throws {
            try token.charge()
            guard
                UInt64(raw.count) + 1
                    <= CanonicalMetadataJSON.maximumNumericTokenByteCount
            else {
                throw MetadataJSONIngressError.resourceLimitExceeded
            }
            raw.append(try nextByte())
        }

        func peekDigit() -> Bool {
            guard let byte = peekByte() else {
                return false
            }
            return byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
        }

        if peekByte() == UInt8(ascii: "-") {
            try consume()
        }
        guard peekDigit() else {
            throw MetadataJSONIngressError.invalidDocument
        }
        let firstDigit = peekByte()
        try consume()
        if firstDigit != UInt8(ascii: "0"), peekDigit() {
            while peekDigit() {
                try consume()
            }
        } else if firstDigit == UInt8(ascii: "0"), peekDigit() {
            throw MetadataJSONIngressError.invalidDocument
        }
        if peekByte() == UInt8(ascii: ".") {
            try consume()
            guard peekDigit() else {
                throw MetadataJSONIngressError.invalidDocument
            }
            while peekDigit() {
                try consume()
            }
        }
        if peekByte() == UInt8(ascii: "e") || peekByte() == UInt8(ascii: "E") {
            try consume()
            if peekByte() == UInt8(ascii: "+") || peekByte() == UInt8(ascii: "-") {
                try consume()
            }
            guard peekDigit() else {
                throw MetadataJSONIngressError.invalidDocument
            }
            while peekDigit() {
                try consume()
            }
        }

        guard let parsed = Double(String(decoding: raw, as: UTF8.self)),
            parsed.isFinite
        else {
            throw MetadataJSONIngressError.invalidDocument
        }
        guard let canonical = CanonicalMetadataJSON.canonicalNumberToken(parsed),
            canonical == raw
        else {
            throw MetadataJSONIngressError.invalidDocument
        }
        return parsed
    }

    // MARK: - Canonical integer strings

    static func parseCanonicalInt64(_ token: String) -> Int64? {
        var bytes = Array(token.utf8)
        guard !bytes.isEmpty else {
            return nil
        }
        var negative = false
        if bytes[0] == UInt8(ascii: "-") {
            negative = true
            bytes.removeFirst()
        }
        guard let magnitude = parseCanonicalDecimalMagnitude(bytes) else {
            return nil
        }
        if negative {
            guard magnitude >= 1, magnitude <= UInt64(Int64.max) + 1 else {
                return nil
            }
            if magnitude == UInt64(Int64.max) + 1 {
                return Int64.min
            }
            return -Int64(magnitude)
        }
        guard magnitude <= UInt64(Int64.max) else {
            return nil
        }
        return Int64(magnitude)
    }

    static func parseCanonicalUInt64(_ token: String) -> UInt64? {
        parseCanonicalDecimalMagnitude(Array(token.utf8))
    }

    /// `"0"` or a nonzero digit followed by digits, checked against the
    /// `UInt64` range; every alias (sign, leading zero, fraction,
    /// exponent) fails.
    private static func parseCanonicalDecimalMagnitude(_ bytes: [UInt8]) -> UInt64? {
        guard !bytes.isEmpty else {
            return nil
        }
        if bytes == [UInt8(ascii: "0")] {
            return 0
        }
        guard bytes[0] >= UInt8(ascii: "1"), bytes[0] <= UInt8(ascii: "9") else {
            return nil
        }
        var value: UInt64 = 0
        for byte in bytes {
            guard byte >= UInt8(ascii: "0"), byte <= UInt8(ascii: "9") else {
                return nil
            }
            let (shifted, shiftOverflow) = value.multipliedReportingOverflow(by: 10)
            guard !shiftOverflow else {
                return nil
            }
            let (sum, sumOverflow) = shifted.addingReportingOverflow(
                UInt64(byte - UInt8(ascii: "0"))
            )
            guard !sumOverflow else {
                return nil
            }
            value = sum
        }
        return value
    }
}
