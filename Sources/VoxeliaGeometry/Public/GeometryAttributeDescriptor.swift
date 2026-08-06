// SPDX-License-Identifier: MIT

import VoxeliaCore

/// A validated description of one logical geometry attribute stream.
///
/// This standalone value records the attribute's element representation. It
/// does not bind the stream to a geometry, choose an interpolation domain, or
/// validate compatibility with other attributes.
public struct GeometryAttributeDescriptor: Sendable, Hashable, Codable {
    /// The logical meaning of the attribute values.
    public let semantic: GeometryAttributeSemantic

    /// The scalar representation of each component.
    public let scalarFormat: ScalarFormat

    /// The logical component count, meaning, and storage layout.
    public let components: ComponentDescriptor

    /// The nonnegative number of attribute elements.
    public let elementCount: Int

    /// Creates and validates a geometry attribute descriptor.
    ///
    /// Position attributes require exactly two or three components. Other
    /// semantic-to-component and cross-attribute consistency rules belong to
    /// the geometry or mesh descriptor that binds the attribute.
    ///
    /// - Throws: `DataModelError.invalidGeometryAttribute` when
    ///   `elementCount` is negative or a position attribute does not have two
    ///   or three components.
    public init(
        semantic: GeometryAttributeSemantic,
        scalarFormat: ScalarFormat,
        components: ComponentDescriptor,
        elementCount: Int
    ) throws {
        guard elementCount >= 0 else {
            throw DataModelError.invalidGeometryAttribute
        }
        if case .position = semantic,
            !(2...3).contains(components.count)
        {
            throw DataModelError.invalidGeometryAttribute
        }

        self.semantic = semantic
        self.scalarFormat = scalarFormat
        self.components = components
        self.elementCount = elementCount
    }

    /// Decodes the exact four-field representation and revalidates its
    /// standalone attribute invariants.
    public init(from decoder: any Decoder) throws {
        let semanticKey = GeometryAttributeDescriptorCodingKey("semantic")
        let scalarFormatKey = GeometryAttributeDescriptorCodingKey("scalarFormat")
        let componentsKey = GeometryAttributeDescriptorCodingKey("components")
        let elementCountKey = GeometryAttributeDescriptorCodingKey("elementCount")
        let container = try decoder.container(
            keyedBy: GeometryAttributeDescriptorCodingKey.self
        )
        let expectedKeys = Set([
            semanticKey.stringValue,
            scalarFormatKey.stringValue,
            componentsKey.stringValue,
            elementCountKey.stringValue,
        ])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                        "A geometry attribute descriptor requires semantic, scalarFormat, components, and elementCount."
                )
            )
        }

        let semantic = try container.decode(
            GeometryAttributeSemantic.self,
            forKey: semanticKey
        )
        let scalarFormat = try container.decode(
            ScalarFormat.self,
            forKey: scalarFormatKey
        )
        let components = try container.decode(
            ComponentDescriptor.self,
            forKey: componentsKey
        )
        let elementCount = try container.decode(Int.self, forKey: elementCountKey)

        do {
            try self.init(
                semantic: semantic,
                scalarFormat: scalarFormat,
                components: components,
                elementCount: elementCount
            )
        } catch let error as DataModelError {
            let invalidKey = elementCount < 0 ? elementCountKey : componentsKey
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [invalidKey],
                    debugDescription: "Geometry attribute metadata is invalid.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes all four validated fields without normalization.
    public func encode(to encoder: any Encoder) throws {
        let semanticKey = GeometryAttributeDescriptorCodingKey("semantic")
        let scalarFormatKey = GeometryAttributeDescriptorCodingKey("scalarFormat")
        let componentsKey = GeometryAttributeDescriptorCodingKey("components")
        let elementCountKey = GeometryAttributeDescriptorCodingKey("elementCount")
        var container = encoder.container(
            keyedBy: GeometryAttributeDescriptorCodingKey.self
        )
        try container.encode(semantic, forKey: semanticKey)
        try container.encode(scalarFormat, forKey: scalarFormatKey)
        try container.encode(components, forKey: componentsKey)
        try container.encode(elementCount, forKey: elementCountKey)
    }
}

private struct GeometryAttributeDescriptorCodingKey: CodingKey {
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
