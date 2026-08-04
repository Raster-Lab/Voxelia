// SPDX-License-Identifier: MIT

/// An error raised while validating an axis-sampling declaration.
public enum AxisSamplingError: Error, Sendable, Equatable {
    /// A regular origin was NaN or infinite.
    case nonFiniteOrigin

    /// A regular spacing was NaN or infinite.
    case nonFiniteSpacing

    /// A regular spacing was exactly zero.
    case zeroSpacing

    /// An irregular coordinate at `index` was NaN or infinite.
    case nonFiniteCoordinate(index: Int)

    /// A categorical label at `index` was empty or Unicode-whitespace-only.
    case blankLabel(index: Int)

    /// An external sampling identifier was empty or Unicode-whitespace-only.
    case blankExternalIdentifier
}

/// How sample positions along one logical image axis are defined.
///
/// Sampling declares per-axis coordinate structure only. Extent-dependent
/// rules—irregular-coordinate and categorical-label counts matching the axis
/// extent—are validated when the axis is bound to an image shape by a
/// complete image descriptor.
public enum AxisSampling: Sendable, Hashable, Codable {
    case indexOnly
    case regular(origin: Double, spacing: Double)
    case irregular(coordinates: ContiguousArray<Double>)
    case categorical(labels: ContiguousArray<String>)
    case externallyDefined(identifier: String)

    /// Validates the value-intrinsic sampling invariants.
    ///
    /// - Throws: ``AxisSamplingError`` when a regular origin or spacing is
    ///   non-finite, a regular spacing is zero, an irregular coordinate is
    ///   non-finite, a categorical label is blank, or an external identifier
    ///   is blank.
    func validate() throws {
        switch self {
        case .indexOnly:
            return
        case .regular(let origin, let spacing):
            guard origin.isFinite else {
                throw AxisSamplingError.nonFiniteOrigin
            }
            guard spacing.isFinite else {
                throw AxisSamplingError.nonFiniteSpacing
            }
            guard spacing != 0 else {
                throw AxisSamplingError.zeroSpacing
            }
        case .irregular(let coordinates):
            for (index, coordinate) in coordinates.enumerated()
            where !coordinate.isFinite {
                throw AxisSamplingError.nonFiniteCoordinate(index: index)
            }
        case .categorical(let labels):
            for (index, label) in labels.enumerated()
            where !label.contains(where: { !$0.isWhitespace }) {
                throw AxisSamplingError.blankLabel(index: index)
            }
        case .externallyDefined(let identifier):
            guard identifier.contains(where: { !$0.isWhitespace }) else {
                throw AxisSamplingError.blankExternalIdentifier
            }
        }
    }

    private struct AxisSamplingCodingKey: CodingKey {
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

    /// Decodes the strict one-tag representation and revalidates its payload
    /// so serialized input cannot bypass sampling invariants.
    public init(from decoder: any Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            guard value == "indexOnly" else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown axis sampling: \(value)."
                    )
                )
            }
            self = .indexOnly
            return
        }

        let container = try decoder.container(keyedBy: AxisSamplingCodingKey.self)
        let caseNames = ["regular", "irregular", "categorical", "externallyDefined"]
        guard
            container.allKeys.count == 1,
            let caseKey = container.allKeys.first,
            caseNames.contains(caseKey.stringValue)
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected one axis-sampling case object."
                )
            )
        }

        let payload = try container.nestedContainer(
            keyedBy: AxisSamplingCodingKey.self,
            forKey: caseKey
        )
        let decoded: AxisSampling
        switch caseKey.stringValue {
        case "regular":
            decoded = try AxisSampling.regular(
                origin: Self.payloadValue(Double.self, "origin", "spacing", payload),
                spacing: Self.payloadValue(Double.self, "spacing", "origin", payload)
            )
        case "irregular":
            decoded = try .irregular(
                coordinates: Self.payloadValue(
                    ContiguousArray<Double>.self,
                    "coordinates",
                    nil,
                    payload
                )
            )
        case "categorical":
            decoded = try .categorical(
                labels: Self.payloadValue(
                    ContiguousArray<String>.self,
                    "labels",
                    nil,
                    payload
                )
            )
        default:
            decoded = try .externallyDefined(
                identifier: Self.payloadValue(String.self, "identifier", nil, payload)
            )
        }

        do {
            try decoded.validate()
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: payload.codingPath,
                    debugDescription: "Axis sampling contains an invalid payload.",
                    underlyingError: error
                )
            )
        }
        self = decoded
    }

    private static func payloadValue<Value: Decodable>(
        _ type: Value.Type,
        _ name: String,
        _ secondName: String?,
        _ payload: KeyedDecodingContainer<AxisSamplingCodingKey>
    ) throws -> Value {
        let expectedNames = [name, secondName].compactMap { $0 }
        guard Set(payload.allKeys.map(\.stringValue)) == Set(expectedNames) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: payload.codingPath,
                    debugDescription:
                        "Axis-sampling payload requires exactly: "
                        + expectedNames.sorted().joined(separator: ", ") + "."
                )
            )
        }
        return try payload.decode(Value.self, forKey: AxisSamplingCodingKey(name))
    }

    /// Encodes `indexOnly` as a stable string and every payload case as one
    /// strict single-tag object.
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .indexOnly:
            var container = encoder.singleValueContainer()
            try container.encode("indexOnly")
        case .regular(let origin, let spacing):
            var container = encoder.container(keyedBy: AxisSamplingCodingKey.self)
            var payload = container.nestedContainer(
                keyedBy: AxisSamplingCodingKey.self,
                forKey: AxisSamplingCodingKey("regular")
            )
            try payload.encode(origin, forKey: AxisSamplingCodingKey("origin"))
            try payload.encode(spacing, forKey: AxisSamplingCodingKey("spacing"))
        case .irregular(let coordinates):
            var container = encoder.container(keyedBy: AxisSamplingCodingKey.self)
            var payload = container.nestedContainer(
                keyedBy: AxisSamplingCodingKey.self,
                forKey: AxisSamplingCodingKey("irregular")
            )
            try payload.encode(
                coordinates,
                forKey: AxisSamplingCodingKey("coordinates")
            )
        case .categorical(let labels):
            var container = encoder.container(keyedBy: AxisSamplingCodingKey.self)
            var payload = container.nestedContainer(
                keyedBy: AxisSamplingCodingKey.self,
                forKey: AxisSamplingCodingKey("categorical")
            )
            try payload.encode(labels, forKey: AxisSamplingCodingKey("labels"))
        case .externallyDefined(let identifier):
            var container = encoder.container(keyedBy: AxisSamplingCodingKey.self)
            var payload = container.nestedContainer(
                keyedBy: AxisSamplingCodingKey.self,
                forKey: AxisSamplingCodingKey("externallyDefined")
            )
            try payload.encode(
                identifier,
                forKey: AxisSamplingCodingKey("identifier")
            )
        }
    }
}
