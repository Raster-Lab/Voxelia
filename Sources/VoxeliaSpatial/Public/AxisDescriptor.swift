// SPDX-License-Identifier: MIT

/// An error raised while validating an axis descriptor.
public enum AxisDescriptorError: Error, Sendable, Equatable {
    /// The axis name was empty or Unicode-whitespace-only.
    case blankName

    /// A generic semantic namespace was empty or Unicode-whitespace-only.
    case blankSemanticNamespace

    /// A generic semantic name was empty or Unicode-whitespace-only.
    case blankSemanticName
}

/// The canonical description of one logical image axis.
///
/// A descriptor declares identity, display name, semantic meaning, an
/// optional measurement unit and per-axis sampling. Extent-dependent
/// invariants—axis count versus rank, unique identifiers, coordinate and
/// label counts, duplicate-semantic policy and spatial-axis consistency—are
/// validated when axes are bound to a complete image descriptor.
public struct AxisDescriptor: Sendable, Hashable {
    /// The stable axis identity.
    public let id: AxisID

    /// The human-readable axis name.
    public let name: String

    /// The coordinate-dimension meaning of the axis.
    public let semantic: AxisSemantic

    /// The measurement unit of axis coordinates, when one is declared.
    public let unit: MeasurementUnit?

    /// How sample positions along the axis are defined.
    public let sampling: AxisSampling

    /// Creates a validated axis descriptor.
    ///
    /// - Throws: ``AxisDescriptorError/blankName`` when `name` is empty or
    ///   whitespace-only, ``AxisDescriptorError/blankSemanticNamespace`` or
    ///   ``AxisDescriptorError/blankSemanticName`` when a generic semantic
    ///   carries a blank component, or ``AxisSamplingError`` when `sampling`
    ///   violates a value-intrinsic sampling invariant.
    public init(
        id: AxisID,
        name: String,
        semantic: AxisSemantic,
        unit: MeasurementUnit? = nil,
        sampling: AxisSampling
    ) throws {
        guard name.contains(where: { !$0.isWhitespace }) else {
            throw AxisDescriptorError.blankName
        }
        if case .generic(let namespace, let genericName) = semantic {
            guard namespace.contains(where: { !$0.isWhitespace }) else {
                throw AxisDescriptorError.blankSemanticNamespace
            }
            guard genericName.contains(where: { !$0.isWhitespace }) else {
                throw AxisDescriptorError.blankSemanticName
            }
        }
        try sampling.validate()

        self.id = id
        self.name = name
        self.semantic = semantic
        self.unit = unit
        self.sampling = sampling
    }
}

extension AxisDescriptor: Codable {
    private struct AxisDescriptorCodingKey: CodingKey {
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

    /// Decodes the strict five-field representation and revalidates it so
    /// serialized input cannot bypass descriptor invariants.
    public init(from decoder: any Decoder) throws {
        let idKey = AxisDescriptorCodingKey("id")
        let nameKey = AxisDescriptorCodingKey("name")
        let semanticKey = AxisDescriptorCodingKey("semantic")
        let unitKey = AxisDescriptorCodingKey("unit")
        let samplingKey = AxisDescriptorCodingKey("sampling")
        let container = try decoder.container(keyedBy: AxisDescriptorCodingKey.self)
        let expectedKeys = Set([
            idKey.stringValue,
            nameKey.stringValue,
            semanticKey.stringValue,
            unitKey.stringValue,
            samplingKey.stringValue,
        ])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                        "An axis descriptor requires id, name, semantic, unit and sampling."
                )
            )
        }

        let decodedID = try container.decode(AxisID.self, forKey: idKey)
        let decodedName = try container.decode(String.self, forKey: nameKey)
        let decodedSemantic = try container.decode(
            AxisSemantic.self,
            forKey: semanticKey
        )
        let decodedUnit = try container.decodeIfPresent(
            MeasurementUnit.self,
            forKey: unitKey
        )
        let decodedSampling = try container.decode(
            AxisSampling.self,
            forKey: samplingKey
        )

        do {
            try self.init(
                id: decodedID,
                name: decodedName,
                semantic: decodedSemantic,
                unit: decodedUnit,
                sampling: decodedSampling
            )
        } catch let error as AxisDescriptorError {
            let invalidKey =
                switch error {
                case .blankName:
                    nameKey
                case .blankSemanticNamespace, .blankSemanticName:
                    semanticKey
                }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [invalidKey],
                    debugDescription: "Axis descriptor contains invalid metadata.",
                    underlyingError: error
                )
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [samplingKey],
                    debugDescription: "Axis descriptor contains invalid sampling.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes all five declared fields with an explicit null for an absent
    /// unit.
    public func encode(to encoder: any Encoder) throws {
        let idKey = AxisDescriptorCodingKey("id")
        let nameKey = AxisDescriptorCodingKey("name")
        let semanticKey = AxisDescriptorCodingKey("semantic")
        let unitKey = AxisDescriptorCodingKey("unit")
        let samplingKey = AxisDescriptorCodingKey("sampling")
        var container = encoder.container(keyedBy: AxisDescriptorCodingKey.self)
        try container.encode(id, forKey: idKey)
        try container.encode(name, forKey: nameKey)
        try container.encode(semantic, forKey: semanticKey)
        try container.encode(unit, forKey: unitKey)
        try container.encode(sampling, forKey: samplingKey)
    }
}
