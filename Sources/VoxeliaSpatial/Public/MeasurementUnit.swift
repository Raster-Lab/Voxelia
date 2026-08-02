// SPDX-License-Identifier: MIT

/// A broad physical or quantitative dimension used to classify measurement
/// units without binding Voxelia to an external unit library.
public enum UnitDimension: String, Sendable, Hashable, Codable {
    case length
    case time
    case angle
    case frequency
    case mass
    case temperature
    case electricPotential
    case concentration
    case activity
    case dimensionless
    case custom
}

/// An error raised while validating a measurement-unit descriptor.
public enum MeasurementUnitError: Error, Sendable, Equatable {
    case emptyNamespace
    case emptyCode
    case nonFiniteScaleToCanonical
    case nonFiniteOffsetToCanonical
}

/// A neutral, immutable measurement-unit descriptor.
///
/// `namespace` and `code` preserve the supplying system's case-sensitive unit
/// identity. Conversion metadata is optional and never inferred from the code
/// or display name. A consumer must not convert values when the required
/// conversion metadata is absent.
public struct MeasurementUnit: Sendable, Hashable, Codable {
    /// The external or Voxelia-owned namespace defining ``code``.
    public let namespace: String

    /// The namespace-specific unit code.
    public let code: String

    /// An optional human-readable label that does not define unit identity.
    public let displayName: String?

    /// An optional broad classification of the represented quantity.
    public let dimension: UnitDimension?

    /// An optional finite scale for an explicitly defined canonical unit.
    public let scaleToCanonical: Double?

    /// An optional finite offset for an explicitly defined canonical unit.
    public let offsetToCanonical: Double?

    /// Creates and validates a neutral measurement-unit descriptor.
    ///
    /// Namespace-specific syntax is intentionally preserved rather than
    /// restricted to a Voxelia grammar. Only empty or whitespace-only identity
    /// fields and non-finite conversion parameters are rejected.
    ///
    /// - Throws: ``MeasurementUnitError`` when an identity field is blank or a
    ///   supplied conversion parameter is not finite.
    public init(
        namespace: String,
        code: String,
        displayName: String? = nil,
        dimension: UnitDimension? = nil,
        scaleToCanonical: Double? = nil,
        offsetToCanonical: Double? = nil
    ) throws {
        guard namespace.contains(where: { !$0.isWhitespace }) else {
            throw MeasurementUnitError.emptyNamespace
        }
        guard code.contains(where: { !$0.isWhitespace }) else {
            throw MeasurementUnitError.emptyCode
        }
        if let scaleToCanonical, !scaleToCanonical.isFinite {
            throw MeasurementUnitError.nonFiniteScaleToCanonical
        }
        if let offsetToCanonical, !offsetToCanonical.isFinite {
            throw MeasurementUnitError.nonFiniteOffsetToCanonical
        }

        self.namespace = namespace
        self.code = code
        self.displayName = displayName
        self.dimension = dimension
        self.scaleToCanonical = scaleToCanonical
        self.offsetToCanonical = offsetToCanonical
    }

    private enum CodingKeys: String, CodingKey {
        case namespace
        case code
        case displayName
        case dimension
        case scaleToCanonical
        case offsetToCanonical
    }

    /// Decodes and revalidates a descriptor so serialized input cannot bypass
    /// its identity and finite-conversion invariants.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedNamespace = try container.decode(String.self, forKey: .namespace)
        let decodedCode = try container.decode(String.self, forKey: .code)
        let decodedDisplayName = try container.decodeIfPresent(
            String.self,
            forKey: .displayName
        )
        let decodedDimension = try container.decodeIfPresent(
            UnitDimension.self,
            forKey: .dimension
        )
        let decodedScale = try container.decodeIfPresent(
            Double.self,
            forKey: .scaleToCanonical
        )
        let decodedOffset = try container.decodeIfPresent(
            Double.self,
            forKey: .offsetToCanonical
        )

        do {
            try self.init(
                namespace: decodedNamespace,
                code: decodedCode,
                displayName: decodedDisplayName,
                dimension: decodedDimension,
                scaleToCanonical: decodedScale,
                offsetToCanonical: decodedOffset
            )
        } catch let error as MeasurementUnitError {
            let invalidKey: CodingKeys =
                switch error {
                case MeasurementUnitError.emptyNamespace:
                    .namespace
                case MeasurementUnitError.emptyCode:
                    .code
                case MeasurementUnitError.nonFiniteScaleToCanonical:
                    .scaleToCanonical
                case MeasurementUnitError.nonFiniteOffsetToCanonical:
                    .offsetToCanonical
                }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [invalidKey],
                    debugDescription: "MeasurementUnit contains invalid metadata.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes all six declared fields without inferring conversion metadata.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(namespace, forKey: .namespace)
        try container.encode(code, forKey: .code)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(dimension, forKey: .dimension)
        try container.encode(scaleToCanonical, forKey: .scaleToCanonical)
        try container.encode(offsetToCanonical, forKey: .offsetToCanonical)
    }
}
