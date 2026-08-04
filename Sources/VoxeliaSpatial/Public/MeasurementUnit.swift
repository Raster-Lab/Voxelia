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
/// identity using their exact accepted UTF-8 spellings. `displayName` is
/// presentation text and is excluded from equality and hashing. Dimension and
/// conversion metadata participate in value identity so conflicting
/// declarations are not silently collapsed. Equality does not establish unit
/// compatibility or authorize conversion.
///
/// Conversion metadata is optional and never inferred from the code or display
/// name. A consumer must not convert values when the required conversion
/// metadata is absent.
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
    /// fields and non-finite conversion parameters are rejected. Negative zero
    /// conversion metadata is canonicalized to positive zero because `Double`
    /// equality and hashing do not distinguish the two representations.
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
        guard !measurementUnitIdentityFieldIsBlank(namespace) else {
            throw MeasurementUnitError.emptyNamespace
        }
        guard !measurementUnitIdentityFieldIsBlank(code) else {
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
        self.scaleToCanonical = scaleToCanonical.map { $0 == 0 ? 0 : $0 }
        self.offsetToCanonical = offsetToCanonical.map { $0 == 0 ? 0 : $0 }
    }

    /// Compares semantic declarations while ignoring human-readable display text.
    public static func == (lhs: MeasurementUnit, rhs: MeasurementUnit) -> Bool {
        exactUTF8Equal(lhs.namespace, rhs.namespace)
            && exactUTF8Equal(lhs.code, rhs.code)
            && lhs.dimension == rhs.dimension
            && lhs.scaleToCanonical == rhs.scaleToCanonical
            && lhs.offsetToCanonical == rhs.offsetToCanonical
    }

    /// Hashes the same semantic declaration fields used by equality.
    public func hash(into hasher: inout Hasher) {
        hashUTF8(namespace, into: &hasher)
        hashUTF8(code, into: &hasher)
        hasher.combine(dimension)
        hasher.combine(scaleToCanonical)
        hasher.combine(offsetToCanonical)
    }

    /// Decodes the exact six-field representation and revalidates the descriptor.
    public init(from decoder: any Decoder) throws {
        let namespaceKey = MeasurementUnitCodingKey("namespace")
        let codeKey = MeasurementUnitCodingKey("code")
        let displayNameKey = MeasurementUnitCodingKey("displayName")
        let dimensionKey = MeasurementUnitCodingKey("dimension")
        let scaleKey = MeasurementUnitCodingKey("scaleToCanonical")
        let offsetKey = MeasurementUnitCodingKey("offsetToCanonical")
        let container = try decoder.container(keyedBy: MeasurementUnitCodingKey.self)
        let expectedKeys = Set([
            namespaceKey.stringValue,
            codeKey.stringValue,
            displayNameKey.stringValue,
            dimensionKey.stringValue,
            scaleKey.stringValue,
            offsetKey.stringValue,
        ])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "MeasurementUnit requires exactly six fields."
                )
            )
        }

        let decodedNamespace = try container.decode(String.self, forKey: namespaceKey)
        let decodedCode = try container.decode(String.self, forKey: codeKey)
        let decodedDisplayName = try container.decodeIfPresent(
            String.self,
            forKey: displayNameKey
        )
        let decodedDimension = try container.decodeIfPresent(
            UnitDimension.self,
            forKey: dimensionKey
        )
        let decodedScale = try container.decodeIfPresent(
            Double.self,
            forKey: scaleKey
        )
        let decodedOffset = try container.decodeIfPresent(
            Double.self,
            forKey: offsetKey
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
            let invalidKey: MeasurementUnitCodingKey =
                switch error {
                case MeasurementUnitError.emptyNamespace:
                    namespaceKey
                case MeasurementUnitError.emptyCode:
                    codeKey
                case MeasurementUnitError.nonFiniteScaleToCanonical:
                    scaleKey
                case MeasurementUnitError.nonFiniteOffsetToCanonical:
                    offsetKey
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
        let namespaceKey = MeasurementUnitCodingKey("namespace")
        let codeKey = MeasurementUnitCodingKey("code")
        let displayNameKey = MeasurementUnitCodingKey("displayName")
        let dimensionKey = MeasurementUnitCodingKey("dimension")
        let scaleKey = MeasurementUnitCodingKey("scaleToCanonical")
        let offsetKey = MeasurementUnitCodingKey("offsetToCanonical")
        var container = encoder.container(keyedBy: MeasurementUnitCodingKey.self)
        try container.encode(namespace, forKey: namespaceKey)
        try container.encode(code, forKey: codeKey)
        try container.encode(displayName, forKey: displayNameKey)
        try container.encode(dimension, forKey: dimensionKey)
        try container.encode(scaleToCanonical, forKey: scaleKey)
        try container.encode(offsetToCanonical, forKey: offsetKey)
    }
}

/// The frozen `VCMJ-1` identity-field whitespace oracle selected by
/// `ADR-0035`, generated from the same controlled scalar table as the
/// private `VoxeliaCore` implementation; Spatial deliberately does not
/// import a Core helper upstream, and cross-module fixtures keep the two
/// in agreement. A field is blank exactly when it contains no scalar
/// outside U+0009 through U+000D, U+0020, U+0085, U+00A0, U+1680, U+2000
/// through U+200A, U+2028, U+2029, U+202F, U+205F and U+3000.
private func measurementUnitIdentityFieldIsBlank(_ value: String) -> Bool {
    !value.unicodeScalars.contains { scalar in
        switch scalar.value {
        case 0x09...0x0D, 0x20, 0x85, 0xA0, 0x1680, 0x2000...0x200A, 0x2028,
            0x2029, 0x202F, 0x205F, 0x3000:
            false
        default:
            true
        }
    }
}

private struct MeasurementUnitCodingKey: CodingKey {
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

private func exactUTF8Equal(_ lhs: String, _ rhs: String) -> Bool {
    lhs.utf8.elementsEqual(rhs.utf8)
}

private func hashUTF8(_ value: String, into hasher: inout Hasher) {
    hasher.combine(value.utf8.count)
    for byte in value.utf8 {
        hasher.combine(byte)
    }
}
