// SPDX-License-Identifier: MIT

/// A validated linear mapping from stored decoded values to authoritative
/// values.
///
/// Zero scale is valid because no governing source requires invertibility.
/// Signed zero canonicalizes to positive zero so equality, hashing and
/// encoding share one representation.
public struct LinearValueTransformDescriptor: Sendable, Hashable {
    /// The finite multiplicative factor applied to a stored value.
    public let scale: Double

    /// The finite additive offset applied after scaling.
    public let offset: Double

    /// Creates a validated linear descriptor.
    ///
    /// - Throws: ``DataModelError/invalidValueTransform`` when `scale` or
    ///   `offset` is NaN or infinite.
    public init(scale: Double, offset: Double) throws {
        guard scale.isFinite, offset.isFinite else {
            throw DataModelError.invalidValueTransform
        }
        self.scale = scale == 0 ? 0 : scale
        self.offset = offset == 0 ? 0 : offset
    }
}

extension LinearValueTransformDescriptor: Codable {
    private enum CodingKeys: String, CodingKey {
        case scale
        case offset
    }

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

    /// Decodes the strict two-field representation and revalidates it so
    /// serialized input cannot bypass the finite-parameter invariant.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        guard Set(container.allKeys.map(\.stringValue)) == Set(["scale", "offset"]) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "A linear transform requires scale and offset."
                )
            )
        }
        let decodedScale = try container.decode(
            Double.self,
            forKey: ArbitraryCodingKey("scale")
        )
        let decodedOffset = try container.decode(
            Double.self,
            forKey: ArbitraryCodingKey("offset")
        )

        do {
            try self.init(scale: decodedScale, offset: decodedOffset)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Linear transform contains non-finite parameters.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes the two canonicalized parameters.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scale, forKey: .scale)
        try container.encode(offset, forKey: .offset)
    }
}

/// A validated nonempty, ordered value-transform composition.
///
/// Transforms apply first to last. Construction performs no flattening of
/// nested compositions, no identity removal and no one-element collapse; a
/// separately approved canonicalization rule would be required for any such
/// simplification.
public struct ValueTransformComposition: Sendable, Hashable {
    /// The transforms in first-to-last application order.
    public let transforms: ContiguousArray<ValueTransform>

    /// Creates a validated composition from any collection of transforms.
    ///
    /// - Throws: ``DataModelError/invalidValueTransform`` when `transforms`
    ///   is empty.
    public init<Transforms: Collection>(transforms: Transforms) throws
    where Transforms.Element == ValueTransform {
        guard !transforms.isEmpty else {
            throw DataModelError.invalidValueTransform
        }
        self.transforms = ContiguousArray(transforms)
    }
}

extension ValueTransformComposition: Codable {
    private enum CodingKeys: String, CodingKey {
        case transforms
    }

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

    /// Decodes the strict one-field representation and revalidates it so
    /// serialized input cannot bypass the nonempty invariant.
    public init(from decoder: any Decoder) throws {
        let transformsKey = ArbitraryCodingKey("transforms")
        let container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        guard container.allKeys.map(\.stringValue) == [transformsKey.stringValue] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "A composition requires exactly one transforms field."
                )
            )
        }
        let decodedTransforms = try container.decode(
            ContiguousArray<ValueTransform>.self,
            forKey: transformsKey
        )

        do {
            try self.init(transforms: decodedTransforms)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [transformsKey],
                    debugDescription: "A composition cannot be empty.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes the ordered transforms.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transforms, forKey: .transforms)
    }
}

/// The relationship between stored decoded values and authoritative physical
/// or modality values.
///
/// A value transform is a declaration only: lookup application,
/// interpolation, missing-entry and extrapolation behavior are separate
/// contracts, and display windows, VOI LUTs, transfer functions and colour
/// maps are presentation-stage values that must not enter this type.
public enum ValueTransform: Sendable, Hashable, Codable {
    case identity
    case linear(LinearValueTransformDescriptor)
    case lookupTable(LookupTableDescriptor)
    case composed(ValueTransformComposition)

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

    /// Decodes `identity` from its stable string and every payload case from
    /// its strict one-tag object, revalidating each payload invariant.
    public init(from decoder: any Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            guard value == "identity" else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown value transform: \(value)."
                    )
                )
            }
            self = .identity
            return
        }

        let container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        let caseNames = ["linear", "lookupTable", "composed"]
        guard
            container.allKeys.count == 1,
            let caseKey = container.allKeys.first,
            caseNames.contains(caseKey.stringValue)
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected one value-transform case object."
                )
            )
        }

        switch caseKey.stringValue {
        case "linear":
            self = .linear(
                try container.decode(
                    LinearValueTransformDescriptor.self,
                    forKey: caseKey
                )
            )
        case "lookupTable":
            self = .lookupTable(
                try container.decode(LookupTableDescriptor.self, forKey: caseKey)
            )
        default:
            self = .composed(
                try container.decode(ValueTransformComposition.self, forKey: caseKey)
            )
        }
    }

    /// Encodes `identity` as a stable string and every payload case as one
    /// strict single-tag object.
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .identity:
            var container = encoder.singleValueContainer()
            try container.encode("identity")
        case .linear(let descriptor):
            var container = encoder.container(keyedBy: ArbitraryCodingKey.self)
            try container.encode(descriptor, forKey: ArbitraryCodingKey("linear"))
        case .lookupTable(let descriptor):
            var container = encoder.container(keyedBy: ArbitraryCodingKey.self)
            try container.encode(descriptor, forKey: ArbitraryCodingKey("lookupTable"))
        case .composed(let composition):
            var container = encoder.container(keyedBy: ArbitraryCodingKey.self)
            try container.encode(composition, forKey: ArbitraryCodingKey("composed"))
        }
    }
}
