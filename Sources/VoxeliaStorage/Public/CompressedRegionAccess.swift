// SPDX-License-Identifier: MIT

/// The smallest logical portion of a compressed object that a codec may expose.
///
/// This value is declaration vocabulary only. A storage or codec descriptor
/// must state its actual access behavior; selecting a case does not itself
/// prove that the corresponding operation is available.
public enum CompressedRegionAccess: Sendable, Hashable, Codable {
    case completeObject
    case frame
    case slab
    case brick
    case regionOfInterest
    case progressiveResolution
    case custom(namespace: String, name: String)

    private enum CodingKeys: String, CodingKey {
        case custom
    }

    private enum CustomCodingKeys: String, CodingKey {
        case namespace
        case name
    }

    /// Compares custom namespace and name values by their exact UTF-8 spelling.
    public static func == (
        lhs: CompressedRegionAccess,
        rhs: CompressedRegionAccess
    ) -> Bool {
        switch (lhs, rhs) {
        case (.completeObject, .completeObject),
            (.frame, .frame),
            (.slab, .slab),
            (.brick, .brick),
            (.regionOfInterest, .regionOfInterest),
            (.progressiveResolution, .progressiveResolution):
            true
        case (
            .custom(let lhsNamespace, let lhsName),
            .custom(let rhsNamespace, let rhsName)
        ):
            lhsNamespace.utf8.elementsEqual(rhsNamespace.utf8)
                && lhsName.utf8.elementsEqual(rhsName.utf8)
        default:
            false
        }
    }

    /// Hashes the case and exact UTF-8 spelling of custom values.
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .completeObject:
            hasher.combine(0)
        case .frame:
            hasher.combine(1)
        case .slab:
            hasher.combine(2)
        case .brick:
            hasher.combine(3)
        case .regionOfInterest:
            hasher.combine(4)
        case .progressiveResolution:
            hasher.combine(5)
        case .custom(let namespace, let name):
            hasher.combine(6)
            hashCompressedRegionAccessUTF8(namespace, into: &hasher)
            hashCompressedRegionAccessUTF8(name, into: &hasher)
        }
    }

    /// Decodes simple access modes from strings and custom modes from a strict
    /// namespaced object.
    public init(from decoder: any Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            switch value {
            case "completeObject": self = .completeObject
            case "frame": self = .frame
            case "slab": self = .slab
            case "brick": self = .brick
            case "regionOfInterest": self = .regionOfInterest
            case "progressiveResolution": self = .progressiveResolution
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown compressed-region access mode: \(value)."
                    )
                )
            }
            return
        }

        let customKey = CompressedRegionAccessCodingKey("custom")
        let namespaceKey = CompressedRegionAccessCodingKey("namespace")
        let nameKey = CompressedRegionAccessCodingKey("name")
        let container = try decoder.container(
            keyedBy: CompressedRegionAccessCodingKey.self
        )
        guard Set(container.allKeys.map(\.stringValue)) == [customKey.stringValue] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected one custom compressed-region access object."
                )
            )
        }

        let custom = try container.nestedContainer(
            keyedBy: CompressedRegionAccessCodingKey.self,
            forKey: customKey
        )
        guard
            Set(custom.allKeys.map(\.stringValue))
                == [namespaceKey.stringValue, nameKey.stringValue]
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: custom.codingPath,
                    debugDescription: "Custom access requires namespace and name."
                )
            )
        }

        self = try .custom(
            namespace: custom.decode(String.self, forKey: namespaceKey),
            name: custom.decode(String.self, forKey: nameKey)
        )
    }

    /// Encodes simple modes as stable strings and custom modes as
    /// `{ "custom": { "namespace": ..., "name": ... } }`.
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .completeObject, .frame, .slab, .brick, .regionOfInterest,
            .progressiveResolution:
            var container = encoder.singleValueContainer()
            let value =
                switch self {
                case .completeObject: "completeObject"
                case .frame: "frame"
                case .slab: "slab"
                case .brick: "brick"
                case .regionOfInterest: "regionOfInterest"
                case .progressiveResolution: "progressiveResolution"
                case .custom: preconditionFailure("Handled by the outer switch.")
                }
            try container.encode(value)
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
}

private struct CompressedRegionAccessCodingKey: CodingKey {
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

private func hashCompressedRegionAccessUTF8(_ value: String, into hasher: inout Hasher) {
    hasher.combine(value.utf8.count)
    for byte in value.utf8 {
        hasher.combine(byte)
    }
}
