// SPDX-License-Identifier: MIT

/// The axis-orientation convention of a coordinate space.
///
/// A convention identifies orientation vocabulary only: it is not a
/// coordinate-space instance, unit, transform or external frame, and
/// convention conversion always requires an explicit transform. Custom
/// namespace and name values are opaque, case-sensitive declaration
/// vocabulary compared by exact UTF-8 bytes.
public enum CoordinateConvention: Sendable, Hashable, Codable {
    case cartesianRightHanded
    case cartesianLeftHanded
    case dicomPatientLPS
    case neuroimagingRAS
    case imageDisplay
    case custom(namespace: String, name: String)

    /// The handedness implied by a built-in convention alone.
    ///
    /// `cartesianRightHanded`, `dicomPatientLPS` and `neuroimagingRAS` imply
    /// right-handed; `cartesianLeftHanded` implies left-handed. The result is
    /// `nil` for `imageDisplay` and `custom`, whose handedness is unresolved
    /// by the convention alone: an operation that requires resolved
    /// handedness must reject those cases explicitly rather than infer one.
    public var impliedHandedness: CoordinateHandedness? {
        switch self {
        case .cartesianRightHanded, .dicomPatientLPS, .neuroimagingRAS:
            .rightHanded
        case .cartesianLeftHanded:
            .leftHanded
        case .imageDisplay, .custom:
            nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case custom
    }

    private enum CustomCodingKeys: String, CodingKey {
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

    /// Decodes built-in conventions from exact stable strings and custom
    /// conventions from the strict namespaced object.
    public init(from decoder: any Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            switch value {
            case "cartesianRightHanded": self = .cartesianRightHanded
            case "cartesianLeftHanded": self = .cartesianLeftHanded
            case "dicomPatientLPS": self = .dicomPatientLPS
            case "neuroimagingRAS": self = .neuroimagingRAS
            case "imageDisplay": self = .imageDisplay
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown coordinate convention: \(value)."
                    )
                )
            }
            return
        }

        let customKey = ArbitraryCodingKey("custom")
        let namespaceKey = ArbitraryCodingKey("namespace")
        let nameKey = ArbitraryCodingKey("name")
        let container = try decoder.container(keyedBy: ArbitraryCodingKey.self)
        guard container.allKeys.map(\.stringValue) == [customKey.stringValue] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected one custom coordinate-convention object."
                )
            )
        }
        let custom = try container.nestedContainer(
            keyedBy: ArbitraryCodingKey.self,
            forKey: customKey
        )
        let customKeys = Set(custom.allKeys.map(\.stringValue))
        guard customKeys == Set([namespaceKey.stringValue, nameKey.stringValue]) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: custom.codingPath,
                    debugDescription: "Custom convention requires namespace and name."
                )
            )
        }
        self = try .custom(
            namespace: custom.decode(String.self, forKey: namespaceKey),
            name: custom.decode(String.self, forKey: nameKey)
        )
    }

    /// Encodes built-in conventions as canonical strings. A custom convention
    /// is encoded as `{ "custom": { "namespace": ..., "name": ... } }`.
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .cartesianRightHanded, .cartesianLeftHanded, .dicomPatientLPS,
            .neuroimagingRAS, .imageDisplay:
            var container = encoder.singleValueContainer()
            let value =
                switch self {
                case .cartesianRightHanded: "cartesianRightHanded"
                case .cartesianLeftHanded: "cartesianLeftHanded"
                case .dicomPatientLPS: "dicomPatientLPS"
                case .neuroimagingRAS: "neuroimagingRAS"
                case .imageDisplay: "imageDisplay"
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
