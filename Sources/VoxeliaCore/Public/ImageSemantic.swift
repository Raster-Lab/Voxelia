// SPDX-License-Identifier: MIT

/// The domain meaning of an image's logical samples.
///
/// Semantic consistency with scalar, component and geometry descriptors is
/// validated when those values are bound together by an image descriptor.
public enum ImageSemantic: Sendable, Hashable, Codable {
    case intensity
    case label
    case probability
    case colour
    case vectorField
    case deformationField
    case tensor
    case parametric
    case mask
    case generic(namespace: String, name: String)

    private enum CodingKeys: String, CodingKey {
        case generic
    }

    private enum GenericCodingKeys: String, CodingKey {
        case namespace
        case name
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

    /// Decodes simple semantics from stable strings and namespaced generic
    /// semantics from a structured object.
    public init(from decoder: any Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            switch value {
            case "intensity": self = .intensity
            case "label": self = .label
            case "probability": self = .probability
            case "colour": self = .colour
            case "vectorField": self = .vectorField
            case "deformationField": self = .deformationField
            case "tensor": self = .tensor
            case "parametric": self = .parametric
            case "mask": self = .mask
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown image semantic: \(value)."
                    )
                )
            }
            return
        }

        let genericKey = ArbitraryCodingKey("generic")
        let namespaceKey = ArbitraryCodingKey("namespace")
        let nameKey = ArbitraryCodingKey("name")
        let container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        guard container.allKeys.map(\.stringValue) == [genericKey.stringValue] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected one generic image-semantic object."
                )
            )
        }
        let generic = try container.nestedContainer(
            keyedBy: ArbitraryCodingKey.self,
            forKey: genericKey
        )
        let genericKeys = Set(generic.allKeys.map(\.stringValue))
        guard genericKeys == Set([namespaceKey.stringValue, nameKey.stringValue]) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: generic.codingPath,
                    debugDescription: "Generic semantic requires namespace and name."
                )
            )
        }
        self = try .generic(
            namespace: generic.decode(String.self, forKey: namespaceKey),
            name: generic.decode(String.self, forKey: nameKey)
        )
    }

    /// Encodes simple semantics as canonical strings. A generic semantic is
    /// encoded as `{ "generic": { "namespace": ..., "name": ... } }`.
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .intensity, .label, .probability, .colour, .vectorField,
            .deformationField, .tensor, .parametric, .mask:
            var container = encoder.singleValueContainer()
            let value =
                switch self {
                case .intensity: "intensity"
                case .label: "label"
                case .probability: "probability"
                case .colour: "colour"
                case .vectorField: "vectorField"
                case .deformationField: "deformationField"
                case .tensor: "tensor"
                case .parametric: "parametric"
                case .mask: "mask"
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
