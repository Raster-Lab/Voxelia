// SPDX-License-Identifier: MIT

/// The meaning of the values stored in a geometry attribute.
///
/// Built-in semantics use stable string tags when encoded. A custom semantic
/// retains its namespace and name exactly, including their UTF-8 spelling;
/// neither value is interpreted or normalised by this type.
public enum GeometryAttributeSemantic: Sendable, Hashable, Codable {
    /// Vertex or sample positions.
    case position

    /// Surface or curve normals.
    case normal

    /// Tangent directions.
    case tangent

    /// Colour values.
    case colour

    /// Texture coordinates.
    case textureCoordinate

    /// Scalar scientific values.
    case scalarValue

    /// Discrete labels.
    case label

    /// Confidence values.
    case confidence

    /// A namespaced semantic not represented by a built-in case.
    ///
    /// Empty strings are preserved because namespace policy belongs to the
    /// registry or descriptor that consumes the semantic.
    case custom(namespace: String, name: String)

    private enum CodingKeys: String, CodingKey {
        case custom
    }

    private enum CustomCodingKeys: String, CodingKey {
        case namespace
        case name
    }

    /// Compares custom namespace and name values by their exact UTF-8 bytes.
    public static func == (
        lhs: GeometryAttributeSemantic,
        rhs: GeometryAttributeSemantic
    ) -> Bool {
        switch (lhs, rhs) {
        case (.position, .position),
            (.normal, .normal),
            (.tangent, .tangent),
            (.colour, .colour),
            (.textureCoordinate, .textureCoordinate),
            (.scalarValue, .scalarValue),
            (.label, .label),
            (.confidence, .confidence):
            true
        case (
            .custom(let lhsNamespace, let lhsName),
            .custom(let rhsNamespace, let rhsName)
        ):
            geometrySemanticUTF8Equal(lhsNamespace, rhsNamespace)
                && geometrySemanticUTF8Equal(lhsName, rhsName)
        default:
            false
        }
    }

    /// Hashes custom namespace and name values by their exact UTF-8 bytes.
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .position:
            hasher.combine(0 as UInt8)
        case .normal:
            hasher.combine(1 as UInt8)
        case .tangent:
            hasher.combine(2 as UInt8)
        case .colour:
            hasher.combine(3 as UInt8)
        case .textureCoordinate:
            hasher.combine(4 as UInt8)
        case .scalarValue:
            hasher.combine(5 as UInt8)
        case .label:
            hasher.combine(6 as UInt8)
        case .confidence:
            hasher.combine(7 as UInt8)
        case .custom(let namespace, let name):
            hasher.combine(8 as UInt8)
            geometrySemanticHashUTF8(namespace, into: &hasher)
            geometrySemanticHashUTF8(name, into: &hasher)
        }
    }

    /// Decodes built-in semantics from stable strings and a custom semantic
    /// from `{ "custom": { "namespace": ..., "name": ... } }`.
    public init(from decoder: any Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            switch value {
            case "position": self = .position
            case "normal": self = .normal
            case "tangent": self = .tangent
            case "colour": self = .colour
            case "textureCoordinate": self = .textureCoordinate
            case "scalarValue": self = .scalarValue
            case "label": self = .label
            case "confidence": self = .confidence
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown geometry attribute semantic: \(value)."
                    )
                )
            }
            return
        }

        let customKey = GeometryAttributeSemanticCodingKey("custom")
        let namespaceKey = GeometryAttributeSemanticCodingKey("namespace")
        let nameKey = GeometryAttributeSemanticCodingKey("name")
        let container = try decoder.container(
            keyedBy: GeometryAttributeSemanticCodingKey.self
        )

        guard container.allKeys.map(\.stringValue) == [customKey.stringValue] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected one custom geometry-semantic object."
                )
            )
        }

        let custom = try container.nestedContainer(
            keyedBy: GeometryAttributeSemanticCodingKey.self,
            forKey: customKey
        )
        let expectedKeys = Set([namespaceKey.stringValue, nameKey.stringValue])
        guard Set(custom.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: custom.codingPath,
                    debugDescription: "Custom semantic requires only namespace and name."
                )
            )
        }

        self = try .custom(
            namespace: custom.decode(String.self, forKey: namespaceKey),
            name: custom.decode(String.self, forKey: nameKey)
        )
    }

    /// Encodes built-in semantics as strings and custom semantics as a strict
    /// namespaced object.
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .position, .normal, .tangent, .colour, .textureCoordinate,
            .scalarValue, .label, .confidence:
            var container = encoder.singleValueContainer()
            try container.encode(stableTag)
        case .custom(let namespace, let name):
            var container = encoder.container(keyedBy: CodingKeys.self)
            var custom = container.nestedContainer(
                keyedBy: CustomCodingKeys.self,
                forKey: .custom
            )
            try custom.encode(namespace, forKey: .namespace)
            try custom.encode(name, forKey: .name)
        }
    }

    private var stableTag: String {
        switch self {
        case .position: "position"
        case .normal: "normal"
        case .tangent: "tangent"
        case .colour: "colour"
        case .textureCoordinate: "textureCoordinate"
        case .scalarValue: "scalarValue"
        case .label: "label"
        case .confidence: "confidence"
        case .custom:
            preconditionFailure("Custom semantics have structured encodings.")
        }
    }
}

private struct GeometryAttributeSemanticCodingKey: CodingKey {
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

private func geometrySemanticUTF8Equal(_ lhs: String, _ rhs: String) -> Bool {
    lhs.utf8.elementsEqual(rhs.utf8)
}

private func geometrySemanticHashUTF8(_ value: String, into hasher: inout Hasher) {
    hasher.combine(value.utf8.count)
    for byte in value.utf8 {
        hasher.combine(byte)
    }
}
