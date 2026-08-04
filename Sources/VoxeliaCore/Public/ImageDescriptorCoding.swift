// SPDX-License-Identifier: MIT

import VoxeliaSpatial

extension ImageDescriptor: Codable {
    private struct ImageDescriptorCodingKey: CodingKey {
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

    private static func decodingError(_ description: String) -> DecodingError {
        .dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: description)
        )
    }

    /// Decodes the strict eight-field representation with explicit nulls
    /// for the three optional fields, revalidating every section 19.2
    /// invariant with a value-redacted failure.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: ImageDescriptorCodingKey.self)
        let expected = Set([
            "axes", "components", "scalarFormat", "semantic", "shape",
            "spatialGeometry", "units", "valueTransform",
        ])
        guard Set(container.allKeys.map(\.stringValue)) == expected else {
            throw Self.decodingError(
                "An image descriptor requires exactly its eight fields."
            )
        }
        let shape = try container.decode(
            ImageShape.self,
            forKey: ImageDescriptorCodingKey("shape")
        )
        let scalarFormat = try container.decode(
            ScalarFormat.self,
            forKey: ImageDescriptorCodingKey("scalarFormat")
        )
        let components = try container.decode(
            ComponentDescriptor.self,
            forKey: ImageDescriptorCodingKey("components")
        )
        let semantic = try container.decode(
            ImageSemantic.self,
            forKey: ImageDescriptorCodingKey("semantic")
        )
        let axes = try container.decode(
            ContiguousArray<AxisDescriptor>.self,
            forKey: ImageDescriptorCodingKey("axes")
        )
        let geometry = try container.decodeIfPresent(
            SpatialGeometry.self,
            forKey: ImageDescriptorCodingKey("spatialGeometry")
        )
        let transform = try container.decodeIfPresent(
            ValueTransform.self,
            forKey: ImageDescriptorCodingKey("valueTransform")
        )
        let units = try container.decodeIfPresent(
            MeasurementUnit.self,
            forKey: ImageDescriptorCodingKey("units")
        )
        do {
            try self.init(
                shape: shape,
                scalarFormat: scalarFormat,
                components: components,
                semantic: semantic,
                axes: axes,
                spatialGeometry: geometry,
                valueTransform: transform,
                units: units
            )
        } catch {
            throw Self.decodingError(
                "The image descriptor violates a construction invariant."
            )
        }
    }

    /// Encodes exactly the eight fields with explicit nulls.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ImageDescriptorCodingKey.self)
        try container.encode(shape, forKey: ImageDescriptorCodingKey("shape"))
        try container.encode(
            scalarFormat,
            forKey: ImageDescriptorCodingKey("scalarFormat")
        )
        try container.encode(
            components,
            forKey: ImageDescriptorCodingKey("components")
        )
        try container.encode(semantic, forKey: ImageDescriptorCodingKey("semantic"))
        try container.encode(axes, forKey: ImageDescriptorCodingKey("axes"))
        try container.encode(
            spatialGeometry,
            forKey: ImageDescriptorCodingKey("spatialGeometry")
        )
        try container.encode(
            valueTransform,
            forKey: ImageDescriptorCodingKey("valueTransform")
        )
        try container.encode(units, forKey: ImageDescriptorCodingKey("units"))
    }
}
