// SPDX-License-Identifier: MIT

/// The logical interpretation of components associated with one image sample.
public enum ComponentInterpretation: Sendable, Hashable, Codable {
    case scalar
    case rgb
    case rgba
    case vector
    case tensor
    case complex
    case labelProbability
    case generic(namespace: String, name: String)

    private enum CodingKeys: String, CodingKey {
        case generic
    }

    private enum GenericCodingKeys: String, CodingKey {
        case namespace
        case name
    }

    /// Decodes simple interpretations from their stable string representation
    /// and namespaced generic interpretations from a structured object.
    public init(from decoder: any Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            switch value {
            case "scalar": self = .scalar
            case "rgb": self = .rgb
            case "rgba": self = .rgba
            case "vector": self = .vector
            case "tensor": self = .tensor
            case "complex": self = .complex
            case "labelProbability": self = .labelProbability
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown component interpretation: \(value)."
                    )
                )
            }
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.allKeys == [.generic] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected one generic interpretation object."
                )
            )
        }
        let generic = try container.nestedContainer(
            keyedBy: GenericCodingKeys.self,
            forKey: .generic
        )
        guard
            generic.allKeys.count == 2,
            generic.contains(.namespace),
            generic.contains(.name)
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: generic.codingPath,
                    debugDescription: "Generic interpretation requires namespace and name."
                )
            )
        }
        self = try .generic(
            namespace: generic.decode(String.self, forKey: .namespace),
            name: generic.decode(String.self, forKey: .name)
        )
    }

    /// Encodes simple interpretations as canonical strings. A generic value is
    /// encoded as `{ "generic": { "namespace": ..., "name": ... } }`.
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .scalar, .rgb, .rgba, .vector, .tensor, .complex, .labelProbability:
            var container = encoder.singleValueContainer()
            let value =
                switch self {
                case .scalar: "scalar"
                case .rgb: "rgb"
                case .rgba: "rgba"
                case .vector: "vector"
                case .tensor: "tensor"
                case .complex: "complex"
                case .labelProbability: "labelProbability"
                case .generic: preconditionFailure("Handled by the outer switch.")
                }
            try container.encode(value)
        case .generic(let namespace, let name):
            var container = encoder.container(keyedBy: CodingKeys.self)
            var generic = container.nestedContainer(
                keyedBy: GenericCodingKeys.self,
                forKey: .generic
            )
            try generic.encode(namespace, forKey: .namespace)
            try generic.encode(name, forKey: .name)
        }
    }
}

/// The physical arrangement of components in a storage representation.
///
/// Layout never changes the descriptor's logical component ordering.
public enum ComponentLayout: Sendable, Hashable, Codable {
    case interleaved
    case planar
    case storageDefined

    /// Decodes the stable string representation of a component layout.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch try container.decode(String.self) {
        case "interleaved": self = .interleaved
        case "planar": self = .planar
        case "storageDefined": self = .storageDefined
        case let value:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown component layout: \(value)."
            )
        }
    }

    /// Encodes the component layout as its stable canonical string.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .interleaved: try container.encode("interleaved")
        case .planar: try container.encode("planar")
        case .storageDefined: try container.encode("storageDefined")
        }
    }
}

/// A validated description of the values associated with each logical sample.
///
/// Components are distinct from image axes: a component is a value at one
/// sample, while a channel axis changes the image's dimensionality.
public struct ComponentDescriptor: Sendable, Hashable, Codable {
    /// The positive number of components associated with each sample.
    public let count: Int

    /// The logical interpretation of the components.
    public let interpretation: ComponentInterpretation

    /// The components' physical storage arrangement.
    public let layout: ComponentLayout

    /// Optional names in logical component order.
    public let componentNames: ContiguousArray<String>?

    /// Creates and validates a component descriptor.
    ///
    /// RGB and RGBA interpretations require exactly three and four components,
    /// respectively. Other interpretation-specific consistency belongs to the
    /// image-semantic layer.
    ///
    /// - Throws: ``DataModelError/invalidComponentDescriptor`` when `count` is
    ///   not positive, an RGB/RGBA count is incorrect, or `componentNames` does
    ///   not contain exactly `count` entries.
    public init(
        count: Int,
        interpretation: ComponentInterpretation,
        layout: ComponentLayout,
        componentNames: ContiguousArray<String>? = nil
    ) throws {
        guard count > 0 else {
            throw DataModelError.invalidComponentDescriptor
        }
        switch interpretation {
        case .rgb where count != 3:
            throw DataModelError.invalidComponentDescriptor
        case .rgba where count != 4:
            throw DataModelError.invalidComponentDescriptor
        default:
            break
        }
        if let componentNames, componentNames.count != count {
            throw DataModelError.invalidComponentDescriptor
        }

        self.count = count
        self.interpretation = interpretation
        self.layout = layout
        self.componentNames = componentNames
    }

    private enum CodingKeys: String, CodingKey {
        case count
        case interpretation
        case layout
        case componentNames
    }

    /// Decodes and revalidates a descriptor so serialized input cannot bypass
    /// its count and interpretation invariants.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedCount = try container.decode(Int.self, forKey: .count)
        let decodedInterpretation = try container.decode(
            ComponentInterpretation.self,
            forKey: .interpretation
        )
        let decodedLayout = try container.decode(
            ComponentLayout.self,
            forKey: .layout
        )
        let decodedNames = try container.decodeIfPresent(
            ContiguousArray<String>.self,
            forKey: .componentNames
        )

        do {
            try self.init(
                count: decodedCount,
                interpretation: decodedInterpretation,
                layout: decodedLayout,
                componentNames: decodedNames
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "ComponentDescriptor contains invalid metadata.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes all validated component metadata without normalization.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(count, forKey: .count)
        try container.encode(interpretation, forKey: .interpretation)
        try container.encode(layout, forKey: .layout)
        try container.encode(componentNames, forKey: .componentNames)
    }
}
