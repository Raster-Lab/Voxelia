// SPDX-License-Identifier: MIT

private struct SpatialGeometryCodingKey: CodingKey {
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

private func spatialGeometryDecodingError(_ description: String) -> DecodingError {
    .dataCorrupted(
        DecodingError.Context(codingPath: [], debugDescription: description)
    )
}

extension CoordinateSpaceDescriptor: Codable {
    /// Decodes the strict five-field representation and revalidates the
    /// accepted admission invariants with a value-redacted failure.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: SpatialGeometryCodingKey.self)
        let expected = Set([
            "convention", "externalReferences", "handedness", "id", "unit",
        ])
        guard Set(container.allKeys.map(\.stringValue)) == expected else {
            throw spatialGeometryDecodingError(
                "A coordinate space requires exactly its five fields."
            )
        }
        let id = try container.decode(
            CoordinateSpaceID.self,
            forKey: SpatialGeometryCodingKey("id")
        )
        let convention = try container.decode(
            CoordinateConvention.self,
            forKey: SpatialGeometryCodingKey("convention")
        )
        let handedness = try container.decode(
            CoordinateHandedness.self,
            forKey: SpatialGeometryCodingKey("handedness")
        )
        let unit = try container.decode(
            MeasurementUnit.self,
            forKey: SpatialGeometryCodingKey("unit")
        )
        let references = try container.decode(
            ContiguousArray<ExternalFrameReference>.self,
            forKey: SpatialGeometryCodingKey("externalReferences")
        )
        do {
            try self.init(
                id: id,
                convention: convention,
                handedness: handedness,
                unit: unit,
                externalReferences: references
            )
        } catch {
            throw spatialGeometryDecodingError(
                "The coordinate space violates an admission invariant."
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: SpatialGeometryCodingKey.self)
        try container.encode(id, forKey: SpatialGeometryCodingKey("id"))
        try container.encode(
            convention,
            forKey: SpatialGeometryCodingKey("convention")
        )
        try container.encode(
            handedness,
            forKey: SpatialGeometryCodingKey("handedness")
        )
        try container.encode(unit, forKey: SpatialGeometryCodingKey("unit"))
        try container.encode(
            externalReferences,
            forKey: SpatialGeometryCodingKey("externalReferences")
        )
    }
}

extension AffineGridGeometry: Codable {
    /// Decodes the strict three-field representation and revalidates the
    /// exact affine admission rule with a value-redacted failure.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: SpatialGeometryCodingKey.self)
        let expected = Set(["coordinateSpace", "indexToWorld", "spatialAxes"])
        guard Set(container.allKeys.map(\.stringValue)) == expected else {
            throw spatialGeometryDecodingError(
                "An affine geometry requires exactly its three fields."
            )
        }
        let axes = try container.decode(
            SpatialAxisMapping.self,
            forKey: SpatialGeometryCodingKey("spatialAxes")
        )
        let matrix = try container.decode(
            Matrix4x4Double.self,
            forKey: SpatialGeometryCodingKey("indexToWorld")
        )
        let space = try container.decode(
            CoordinateSpaceDescriptor.self,
            forKey: SpatialGeometryCodingKey("coordinateSpace")
        )
        do {
            try self.init(
                spatialAxes: axes,
                indexToWorld: matrix,
                coordinateSpace: space
            )
        } catch {
            throw spatialGeometryDecodingError(
                "The affine geometry violates an admission invariant."
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: SpatialGeometryCodingKey.self)
        try container.encode(
            coordinateSpace,
            forKey: SpatialGeometryCodingKey("coordinateSpace")
        )
        try container.encode(
            indexToWorld,
            forKey: SpatialGeometryCodingKey("indexToWorld")
        )
        try container.encode(
            spatialAxes,
            forKey: SpatialGeometryCodingKey("spatialAxes")
        )
    }
}

extension SpatialGeometry: Codable {
    /// Decodes the strict externally tagged one-member representation.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: SpatialGeometryCodingKey.self)
        guard
            container.allKeys.count == 1,
            container.allKeys.first?.stringValue == "affine"
        else {
            throw spatialGeometryDecodingError(
                "Expected one spatial-geometry case object."
            )
        }
        self = .affine(
            try container.decode(
                AffineGridGeometry.self,
                forKey: SpatialGeometryCodingKey("affine")
            )
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: SpatialGeometryCodingKey.self)
        switch self {
        case .affine(let geometry):
            try container.encode(geometry, forKey: SpatialGeometryCodingKey("affine"))
        }
    }
}
