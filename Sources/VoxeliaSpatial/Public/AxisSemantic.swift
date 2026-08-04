// SPDX-License-Identifier: MIT

/// The coordinate-dimension meaning of one logical image axis.
///
/// Axis semantics describe what a coordinate dimension means; they do not by
/// themselves make the data spatial geometry. Descriptor-level rules such as
/// duplicate-semantic policy and spatial-axis consistency are validated when
/// axes are bound to a complete image descriptor.
public enum AxisSemantic: Sendable, Hashable, Codable {
    case spatialX
    case spatialY
    case spatialZ
    case time
    case cardiacPhase
    case respiratoryPhase
    case energy
    case echo
    case diffusionDirection
    case channel
    case component
    case ensemble
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
            case "spatialX": self = .spatialX
            case "spatialY": self = .spatialY
            case "spatialZ": self = .spatialZ
            case "time": self = .time
            case "cardiacPhase": self = .cardiacPhase
            case "respiratoryPhase": self = .respiratoryPhase
            case "energy": self = .energy
            case "echo": self = .echo
            case "diffusionDirection": self = .diffusionDirection
            case "channel": self = .channel
            case "component": self = .component
            case "ensemble": self = .ensemble
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown axis semantic: \(value)."
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
                    debugDescription: "Expected one generic axis-semantic object."
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
        case .spatialX, .spatialY, .spatialZ, .time, .cardiacPhase,
            .respiratoryPhase, .energy, .echo, .diffusionDirection, .channel,
            .component, .ensemble:
            var container = encoder.singleValueContainer()
            let value =
                switch self {
                case .spatialX: "spatialX"
                case .spatialY: "spatialY"
                case .spatialZ: "spatialZ"
                case .time: "time"
                case .cardiacPhase: "cardiacPhase"
                case .respiratoryPhase: "respiratoryPhase"
                case .energy: "energy"
                case .echo: "echo"
                case .diffusionDirection: "diffusionDirection"
                case .channel: "channel"
                case .component: "component"
                case .ensemble: "ensemble"
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
