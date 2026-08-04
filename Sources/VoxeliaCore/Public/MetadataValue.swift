// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised while validating a recursive metadata value.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// metadata keys, values or source text.
public enum MetadataValueError: Error, Sendable, Equatable {
    case duplicateObjectKey
    case containerDepthLimitExceeded
    case structuralElementLimitExceeded
    case logicalPayloadByteLimitExceeded
}

/// The cached logical metrics of one validated value subtree.
struct MetadataValueMetrics: Sendable {
    /// The container depth: a leaf is zero, an empty container one.
    let depth: Int
    /// Every logical value and member occurrence, including the root once.
    let elements: UInt64
    /// Every logical variable payload byte occurrence.
    let payload: UInt64
}

/// A validated, immutable, order-preserving metadata array.
public struct MetadataArray: Sendable, Hashable {
    /// The values in exact semantic order.
    public let values: ContiguousArray<MetadataValue>

    let containerDepth: Int
    let elementsBelow: UInt64
    let payloadBelow: UInt64

    /// Creates a validated array from any value collection.
    ///
    /// - Throws: ``MetadataValueError`` when the depth, logical
    ///   structural-element or logical payload ceiling would be exceeded.
    public init<Values: Collection>(values: Values) throws
    where Values.Element == MetadataValue {
        guard
            UInt64(values.count) < MetadataValue.maximumLogicalStructuralElementCount
        else {
            throw MetadataValueError.structuralElementLimitExceeded
        }

        var storage = ContiguousArray<MetadataValue>()
        storage.reserveCapacity(values.count)
        var maximumChildDepth = 0
        var elements: UInt64 = 0
        var payload: UInt64 = 0
        for value in values {
            let metrics = value.metrics
            maximumChildDepth = max(maximumChildDepth, metrics.depth)
            elements = try MetadataValue.addingElements(elements, metrics.elements)
            payload = try MetadataValue.addingPayload(payload, metrics.payload)
            storage.append(value)
        }

        let depth = maximumChildDepth + 1
        guard depth <= MetadataValue.maximumContainerDepth else {
            throw MetadataValueError.containerDepthLimitExceeded
        }
        guard
            try MetadataValue.addingElements(elements, 1)
                <= MetadataValue.maximumLogicalStructuralElementCount
        else {
            throw MetadataValueError.structuralElementLimitExceeded
        }
        guard
            payload
                <= MetadataValue.maximumRecursiveContainerLogicalVariablePayloadByteCount
        else {
            throw MetadataValueError.logicalPayloadByteLimitExceeded
        }

        self.values = storage
        self.containerDepth = depth
        self.elementsBelow = elements
        self.payloadBelow = payload
    }

    public static func == (lhs: MetadataArray, rhs: MetadataArray) -> Bool {
        MetadataValue.areEqual(.array(lhs), .array(rhs))
    }

    public func hash(into hasher: inout Hasher) {
        MetadataValue.array(self).hash(into: &hasher)
    }
}

/// A validated, immutable metadata object with map semantics.
///
/// Members are canonically sorted by unsigned UTF-8 lexicographic order of
/// key namespace then key name; caller order is not semantic. Exact-key
/// duplicates are rejected regardless of value equality.
public struct MetadataObject: Sendable, Hashable {
    /// One structural key/value pair of a recursive object.
    ///
    /// This is not the general collection entry: it makes no privacy,
    /// multiplicity, namespace-schema or typed-access claim.
    public struct Member: Sendable, Hashable {
        /// The exact opaque member key.
        public let key: AnyMetadataKey
        /// The member value.
        public let value: MetadataValue

        public init(key: AnyMetadataKey, value: MetadataValue) {
            self.key = key
            self.value = value
        }

        public static func == (lhs: Member, rhs: Member) -> Bool {
            lhs.key == rhs.key && MetadataValue.areEqual(lhs.value, rhs.value)
        }

        public func hash(into hasher: inout Hasher) {
            key.hash(into: &hasher)
            value.hash(into: &hasher)
        }
    }

    /// The members in canonical exact-key order.
    public let members: ContiguousArray<Member>

    let containerDepth: Int
    let elementsBelow: UInt64
    let payloadBelow: UInt64

    /// Creates a validated object from any member collection.
    ///
    /// - Throws: ``MetadataValueError`` when a resource ceiling would be
    ///   exceeded, or ``MetadataValueError/duplicateObjectKey`` when two
    ///   members share one exact key after the resource preflight.
    public init<Members: Collection>(members: Members) throws
    where Members.Element == Member {
        guard
            UInt64(members.count) < MetadataValue.maximumLogicalStructuralElementCount
        else {
            throw MetadataValueError.structuralElementLimitExceeded
        }

        var storage = ContiguousArray<Member>()
        storage.reserveCapacity(members.count)
        var maximumChildDepth = 0
        var elements: UInt64 = 0
        var payload: UInt64 = 0
        for member in members {
            let metrics = member.value.metrics
            maximumChildDepth = max(maximumChildDepth, metrics.depth)
            elements = try MetadataValue.addingElements(elements, metrics.elements)
            elements = try MetadataValue.addingElements(elements, 1)
            payload = try MetadataValue.addingPayload(payload, metrics.payload)
            payload = try MetadataValue.addingPayload(
                payload,
                UInt64(member.key.namespace.utf8.count)
            )
            payload = try MetadataValue.addingPayload(
                payload,
                UInt64(member.key.name.utf8.count)
            )
            storage.append(member)
        }

        let depth = maximumChildDepth + 1
        guard depth <= MetadataValue.maximumContainerDepth else {
            throw MetadataValueError.containerDepthLimitExceeded
        }
        guard
            try MetadataValue.addingElements(elements, 1)
                <= MetadataValue.maximumLogicalStructuralElementCount
        else {
            throw MetadataValueError.structuralElementLimitExceeded
        }
        guard
            payload
                <= MetadataValue.maximumRecursiveContainerLogicalVariablePayloadByteCount
        else {
            throw MetadataValueError.logicalPayloadByteLimitExceeded
        }

        storage.sort { Self.precedesCanonically($0.key, $1.key) }
        for index in storage.indices.dropLast() {
            if storage[index].key == storage[index + 1].key {
                throw MetadataValueError.duplicateObjectKey
            }
        }

        self.members = storage
        self.containerDepth = depth
        self.elementsBelow = elements
        self.payloadBelow = payload
    }

    /// Unsigned UTF-8 lexicographic key order: namespace bytes, then name
    /// bytes, with a proper byte prefix preceding its extension.
    static func precedesCanonically(_ lhs: AnyMetadataKey, _ rhs: AnyMetadataKey) -> Bool {
        if lhs.namespace.utf8.elementsEqual(rhs.namespace.utf8) {
            return lhs.name.utf8.lexicographicallyPrecedes(rhs.name.utf8)
        }
        return lhs.namespace.utf8.lexicographicallyPrecedes(rhs.namespace.utf8)
    }

    public static func == (lhs: MetadataObject, rhs: MetadataObject) -> Bool {
        MetadataValue.areEqual(.object(lhs), .object(rhs))
    }

    public func hash(into hasher: inout Hasher) {
        MetadataValue.object(self).hash(into: &hasher)
    }
}

/// One bounded recursive semantic metadata value.
///
/// `Hashable` is semantic in-memory identity, not canonical record equality
/// or a persistent digest; the process-randomised hash must never be stored.
/// Values may contain sensitive metadata and must not be interpolated into
/// logs, telemetry, filenames or user interfaces.
public enum MetadataValue: Sendable, Hashable, Codable {
    /// The hard version-one container-depth ceiling.
    public static let maximumContainerDepth = 64
    /// The hard version-one logical structural-element ceiling.
    public static let maximumLogicalStructuralElementCount: UInt64 = 1_048_576
    /// The hard version-one recursive-container logical payload ceiling.
    public static let maximumRecursiveContainerLogicalVariablePayloadByteCount: UInt64 = 67_108_864

    case boolean(Bool)
    case signedInteger(Int64)
    case unsignedInteger(UInt64)
    case floatingPoint(MetadataFloatingPoint)
    case string(String)
    case binary(MetadataBinary)
    case instant(CanonicalInstant)
    case unit(MeasurementUnit)
    case code(CodedConcept)
    case array(MetadataArray)
    case object(MetadataObject)

    static func addingElements(_ total: UInt64, _ addition: UInt64) throws -> UInt64 {
        let (sum, overflow) = total.addingReportingOverflow(addition)
        guard !overflow else {
            throw MetadataValueError.structuralElementLimitExceeded
        }
        return sum
    }

    static func addingPayload(_ total: UInt64, _ addition: UInt64) throws -> UInt64 {
        let (sum, overflow) = total.addingReportingOverflow(addition)
        guard !overflow else {
            throw MetadataValueError.logicalPayloadByteLimitExceeded
        }
        return sum
    }

    /// The cached logical metrics of this value.
    var metrics: MetadataValueMetrics {
        switch self {
        case .array(let array):
            MetadataValueMetrics(
                depth: array.containerDepth,
                elements: array.elementsBelow &+ 1,
                payload: array.payloadBelow
            )
        case .object(let object):
            MetadataValueMetrics(
                depth: object.containerDepth,
                elements: object.elementsBelow &+ 1,
                payload: object.payloadBelow
            )
        default:
            MetadataValueMetrics(depth: 0, elements: 1, payload: leafPayloadByteCount)
        }
    }

    /// The logical variable payload bytes of one leaf.
    private var leafPayloadByteCount: UInt64 {
        switch self {
        case .boolean, .signedInteger, .unsignedInteger, .floatingPoint:
            0
        case .string(let string):
            UInt64(string.utf8.count)
        case .binary(let binary):
            UInt64(binary.bytes.count)
        case .instant(let instant):
            UInt64(instant.utcString.utf8.count)
        case .unit(let unit):
            UInt64(unit.namespace.utf8.count)
                &+ UInt64(unit.code.utf8.count)
                &+ UInt64(unit.displayName?.utf8.count ?? 0)
        case .code(let code):
            UInt64(code.scheme.utf8.count)
                &+ UInt64(code.value.utf8.count)
                &+ UInt64(code.meaning?.utf8.count ?? 0)
                &+ UInt64(code.version?.utf8.count ?? 0)
        case .array, .object:
            0
        }
    }

    // MARK: - Iterative identity

    private enum TraversalFrame {
        case array(ContiguousArray<MetadataValue>, ContiguousArray<MetadataValue>, Int)
        case object(
            ContiguousArray<MetadataObject.Member>,
            ContiguousArray<MetadataObject.Member>,
            Int
        )
    }

    /// Iterative structural equality with O(container depth) auxiliary
    /// frames; repeated shared subtrees are compared at every occurrence.
    static func areEqual(_ lhs: MetadataValue, _ rhs: MetadataValue) -> Bool {
        var frames: [TraversalFrame] = []

        func matches(_ lhs: MetadataValue, _ rhs: MetadataValue) -> Bool {
            switch (lhs, rhs) {
            case (.boolean(let l), .boolean(let r)):
                l == r
            case (.signedInteger(let l), .signedInteger(let r)):
                l == r
            case (.unsignedInteger(let l), .unsignedInteger(let r)):
                l == r
            case (.floatingPoint(let l), .floatingPoint(let r)):
                l == r
            case (.string(let l), .string(let r)):
                l.utf8.elementsEqual(r.utf8)
            case (.binary(let l), .binary(let r)):
                l == r
            case (.instant(let l), .instant(let r)):
                l == r
            case (.unit(let l), .unit(let r)):
                l == r
            case (.code(let l), .code(let r)):
                l == r
            case (.array(let l), .array(let r)):
                l.values.count == r.values.count
                    && pushFrame(.array(l.values, r.values, 0))
            case (.object(let l), .object(let r)):
                l.members.count == r.members.count
                    && pushFrame(.object(l.members, r.members, 0))
            default:
                false
            }
        }

        func pushFrame(_ frame: TraversalFrame) -> Bool {
            frames.append(frame)
            return true
        }

        guard matches(lhs, rhs) else { return false }
        while let frame = frames.popLast() {
            switch frame {
            case .array(let left, let right, let index):
                guard index < left.count else { continue }
                frames.append(.array(left, right, index + 1))
                guard matches(left[index], right[index]) else { return false }
            case .object(let left, let right, let index):
                guard index < left.count else { continue }
                frames.append(.object(left, right, index + 1))
                guard left[index].key == right[index].key else { return false }
                guard matches(left[index].value, right[index].value) else {
                    return false
                }
            }
        }
        return true
    }

    public static func == (lhs: MetadataValue, rhs: MetadataValue) -> Bool {
        areEqual(lhs, rhs)
    }

    private enum HashFrame {
        case array(ContiguousArray<MetadataValue>, Int)
        case object(ContiguousArray<MetadataObject.Member>, Int)
    }

    /// Iterative structural hashing combining a stable in-process token
    /// sequence: case discriminator, container counts, exact key fields and
    /// each case's equality-bearing payload.
    public func hash(into hasher: inout Hasher) {
        var frames: [HashFrame] = []

        func combine(_ value: MetadataValue) {
            switch value {
            case .boolean(let payload):
                hasher.combine(0)
                hasher.combine(payload)
            case .signedInteger(let payload):
                hasher.combine(1)
                hasher.combine(payload)
            case .unsignedInteger(let payload):
                hasher.combine(2)
                hasher.combine(payload)
            case .floatingPoint(let payload):
                hasher.combine(3)
                hasher.combine(payload)
            case .string(let payload):
                hasher.combine(4)
                hasher.combine(payload.utf8.count)
                for byte in payload.utf8 {
                    hasher.combine(byte)
                }
            case .binary(let payload):
                hasher.combine(5)
                hasher.combine(payload)
            case .instant(let payload):
                hasher.combine(6)
                hasher.combine(payload)
            case .unit(let payload):
                hasher.combine(7)
                hasher.combine(payload)
            case .code(let payload):
                hasher.combine(8)
                hasher.combine(payload)
            case .array(let payload):
                hasher.combine(9)
                hasher.combine(payload.values.count)
                frames.append(.array(payload.values, 0))
            case .object(let payload):
                hasher.combine(10)
                hasher.combine(payload.members.count)
                frames.append(.object(payload.members, 0))
            }
        }

        combine(self)
        while let frame = frames.popLast() {
            switch frame {
            case .array(let values, let index):
                guard index < values.count else { continue }
                frames.append(.array(values, index + 1))
                combine(values[index])
            case .object(let members, let index):
                guard index < members.count else { continue }
                frames.append(.object(members, index + 1))
                members[index].key.hash(into: &hasher)
                combine(members[index].value)
            }
        }
    }
}

extension MetadataValue {
    private static let caseTags = [
        "boolean", "signedInteger", "unsignedInteger", "floatingPoint",
        "string", "binary", "instant", "unit", "code", "array", "object",
    ]

    private struct ArbitraryCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int?

        init(_ stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(stringValue: String) {
            self.init(stringValue)
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    /// A value-redacted model failure whose context is rebuilt from fixed
    /// vocabulary and never copies a caller-supplied coding path.
    private static func modelDecodingFailure(
        _ description: String,
        underlying: (any Error)? = nil
    ) -> DecodingError {
        .dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: description,
                underlyingError: underlying
            )
        )
    }

    /// The exact container-ancestor count of the value currently being
    /// decoded, threaded through one root traversal.
    @TaskLocal private static var decodeContainerAncestorCount = 0

    /// The remaining enclosing-aggregate structural-element decode budget
    /// threaded by a collection decoder; `nil` applies per-root ceilings
    /// alone.
    @TaskLocal static var decodeAggregateElementCeiling: UInt64?

    /// The remaining enclosing-aggregate logical-payload decode budget
    /// threaded by a collection decoder; `nil` applies per-root ceilings
    /// alone.
    @TaskLocal static var decodeAggregatePayloadCeiling: UInt64?

    /// Decodes the strict externally tagged one-member representation,
    /// enforcing the hard ceilings before accepting further children:
    /// descent depth is tracked exactly through one root traversal and an
    /// adversarially deep document is rejected at level 65 before any
    /// unbounded recursion, ahead of the exact bottom-up validation.
    public init(from decoder: any Decoder) throws {
        guard Self.decodeContainerAncestorCount <= Self.maximumContainerDepth else {
            throw Self.modelDecodingFailure(
                "The metadata value exceeds the container depth limit.",
                underlying: MetadataValueError.containerDepthLimitExceeded
            )
        }

        let container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        guard
            container.allKeys.count == 1,
            let tag = container.allKeys.first,
            Self.caseTags.contains(tag.stringValue)
        else {
            throw Self.modelDecodingFailure("Expected one metadata-value case object.")
        }

        switch tag.stringValue {
        case "boolean":
            self = .boolean(try container.decode(Bool.self, forKey: tag))
        case "signedInteger":
            self = .signedInteger(try container.decode(Int64.self, forKey: tag))
        case "unsignedInteger":
            self = .unsignedInteger(try container.decode(UInt64.self, forKey: tag))
        case "floatingPoint":
            self = .floatingPoint(
                try container.decode(MetadataFloatingPoint.self, forKey: tag)
            )
        case "string":
            self = .string(try container.decode(String.self, forKey: tag))
        case "binary":
            self = .binary(try container.decode(MetadataBinary.self, forKey: tag))
        case "instant":
            self = .instant(try container.decode(CanonicalInstant.self, forKey: tag))
        case "unit":
            self = .unit(try container.decode(MeasurementUnit.self, forKey: tag))
        case "code":
            self = .code(try container.decode(CodedConcept.self, forKey: tag))
        case "array":
            var unkeyed = try container.nestedUnkeyedContainer(forKey: tag)
            var children = ContiguousArray<MetadataValue>()
            var elements: UInt64 = 0
            var payload: UInt64 = 0
            do {
                try Self.$decodeContainerAncestorCount.withValue(
                    Self.decodeContainerAncestorCount + 1
                ) {
                    while !unkeyed.isAtEnd {
                        let child = try unkeyed.decode(MetadataValue.self)
                        let metrics = child.metrics
                        elements = try Self.addingElements(elements, metrics.elements)
                        guard
                            elements < Self.maximumLogicalStructuralElementCount,
                            elements <= (Self.decodeAggregateElementCeiling ?? .max)
                        else {
                            throw MetadataValueError.structuralElementLimitExceeded
                        }
                        payload = try Self.addingPayload(payload, metrics.payload)
                        guard
                            payload
                                <= Self
                                .maximumRecursiveContainerLogicalVariablePayloadByteCount,
                            payload <= (Self.decodeAggregatePayloadCeiling ?? .max)
                        else {
                            throw MetadataValueError.logicalPayloadByteLimitExceeded
                        }
                        children.append(child)
                    }
                }
                self = .array(try MetadataArray(values: children))
            } catch let error as MetadataValueError {
                throw Self.modelDecodingFailure(
                    "The metadata array violates a container invariant.",
                    underlying: error
                )
            }
        case "object":
            var unkeyed = try container.nestedUnkeyedContainer(forKey: tag)
            var members = ContiguousArray<MetadataObject.Member>()
            var elements: UInt64 = 0
            var payload: UInt64 = 0
            do {
                try Self.$decodeContainerAncestorCount.withValue(
                    Self.decodeContainerAncestorCount + 1
                ) {
                    while !unkeyed.isAtEnd {
                        let memberContainer = try unkeyed.nestedContainer(
                            keyedBy: ArbitraryCodingKey.self
                        )
                        let memberKeys = Set(memberContainer.allKeys.map(\.stringValue))
                        guard memberKeys == Set(["key", "value"]) else {
                            throw Self.modelDecodingFailure(
                                "An object member requires exactly key and value."
                            )
                        }
                        let key = try memberContainer.decode(
                            AnyMetadataKey.self,
                            forKey: ArbitraryCodingKey("key")
                        )
                        let value = try memberContainer.decode(
                            MetadataValue.self,
                            forKey: ArbitraryCodingKey("value")
                        )
                        let metrics = value.metrics
                        elements = try Self.addingElements(
                            elements,
                            metrics.elements &+ 1
                        )
                        guard
                            elements < Self.maximumLogicalStructuralElementCount,
                            elements <= (Self.decodeAggregateElementCeiling ?? .max)
                        else {
                            throw MetadataValueError.structuralElementLimitExceeded
                        }
                        payload = try Self.addingPayload(
                            payload,
                            metrics.payload
                                &+ UInt64(key.namespace.utf8.count)
                                &+ UInt64(key.name.utf8.count)
                        )
                        guard
                            payload
                                <= Self
                                .maximumRecursiveContainerLogicalVariablePayloadByteCount,
                            payload <= (Self.decodeAggregatePayloadCeiling ?? .max)
                        else {
                            throw MetadataValueError.logicalPayloadByteLimitExceeded
                        }
                        members.append(MetadataObject.Member(key: key, value: value))
                    }
                }
                self = .object(try MetadataObject(members: members))
            } catch let error as MetadataValueError {
                throw Self.modelDecodingFailure(
                    "The metadata object violates a container invariant.",
                    underlying: error
                )
            }
        default:
            throw Self.modelDecodingFailure("Expected one metadata-value case object.")
        }
    }

    /// Encodes the strict externally tagged one-member representation.
    /// Model-originated encoding never reflects `self`, a member, key or
    /// payload into an error.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ArbitraryCodingKey.self)
        switch self {
        case .boolean(let payload):
            try container.encode(payload, forKey: ArbitraryCodingKey("boolean"))
        case .signedInteger(let payload):
            try container.encode(payload, forKey: ArbitraryCodingKey("signedInteger"))
        case .unsignedInteger(let payload):
            try container.encode(payload, forKey: ArbitraryCodingKey("unsignedInteger"))
        case .floatingPoint(let payload):
            try container.encode(payload, forKey: ArbitraryCodingKey("floatingPoint"))
        case .string(let payload):
            try container.encode(payload, forKey: ArbitraryCodingKey("string"))
        case .binary(let payload):
            try container.encode(payload, forKey: ArbitraryCodingKey("binary"))
        case .instant(let payload):
            try container.encode(payload, forKey: ArbitraryCodingKey("instant"))
        case .unit(let payload):
            try container.encode(payload, forKey: ArbitraryCodingKey("unit"))
        case .code(let payload):
            try container.encode(payload, forKey: ArbitraryCodingKey("code"))
        case .array(let payload):
            var unkeyed = container.nestedUnkeyedContainer(
                forKey: ArbitraryCodingKey("array")
            )
            for value in payload.values {
                try unkeyed.encode(value)
            }
        case .object(let payload):
            var unkeyed = container.nestedUnkeyedContainer(
                forKey: ArbitraryCodingKey("object")
            )
            for member in payload.members {
                var memberContainer = unkeyed.nestedContainer(
                    keyedBy: ArbitraryCodingKey.self
                )
                try memberContainer.encode(
                    member.key,
                    forKey: ArbitraryCodingKey("key")
                )
                try memberContainer.encode(
                    member.value,
                    forKey: ArbitraryCodingKey("value")
                )
            }
        }
    }
}
