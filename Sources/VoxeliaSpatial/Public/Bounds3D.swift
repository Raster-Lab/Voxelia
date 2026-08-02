// SPDX-License-Identifier: MIT

/// An error raised while validating spatial bounds.
public enum SpatialBoundsError: Error, Sendable, Equatable {
    /// The minimum and maximum points use different coordinate spaces.
    case coordinateSpaceMismatch(
        expected: CoordinateSpaceID,
        actual: CoordinateSpaceID
    )

    /// A minimum component exceeds its corresponding maximum component.
    /// Indices 0, 1, and 2 correspond to X, Y, and Z respectively.
    case invertedBounds(
        axis: Int,
        minimum: Double,
        maximum: Double
    )
}

/// Finite axis-aligned bounds in an explicit coordinate space.
///
/// Equality between a minimum and maximum component is valid, so these bounds
/// can represent zero-width point, line, or plane geometry. Whether the values
/// describe sample centres or full sample support is a caller-selected policy.
public struct AxisAlignedBounds3D: Sendable, Hashable, Codable {
    /// The componentwise lower point of the bounds.
    public let minimum: Point3D
    /// The componentwise upper point of the bounds.
    public let maximum: Point3D

    /// Creates bounds without reordering or clamping either point.
    ///
    /// - Throws: ``SpatialBoundsError/coordinateSpaceMismatch(expected:actual:)``
    ///   when the points use different coordinate spaces, or
    ///   ``SpatialBoundsError/invertedBounds(axis:minimum:maximum:)`` for the
    ///   first axis whose minimum exceeds its maximum.
    public init(minimum: Point3D, maximum: Point3D) throws {
        guard minimum.coordinateSpace == maximum.coordinateSpace else {
            throw SpatialBoundsError.coordinateSpaceMismatch(
                expected: minimum.coordinateSpace,
                actual: maximum.coordinateSpace
            )
        }

        let components = [
            (minimum: minimum.x, maximum: maximum.x),
            (minimum: minimum.y, maximum: maximum.y),
            (minimum: minimum.z, maximum: maximum.z),
        ]
        for (axis, component) in components.enumerated() {
            guard component.minimum <= component.maximum else {
                throw SpatialBoundsError.invertedBounds(
                    axis: axis,
                    minimum: component.minimum,
                    maximum: component.maximum
                )
            }
        }

        self.minimum = minimum
        self.maximum = maximum
    }

    /// Decodes and revalidates the bounds and their nested points.
    public init(from decoder: any Decoder) throws {
        let minimumKey = SpatialBoundsCodingKey("minimum")
        let maximumKey = SpatialBoundsCodingKey("maximum")
        let container = try decoder.container(keyedBy: SpatialBoundsCodingKey.self)
        let expectedKeys = Set([minimumKey.stringValue, maximumKey.stringValue])
        guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Axis-aligned bounds require minimum and maximum."
                )
            )
        }

        let minimum = try container.decode(Point3D.self, forKey: minimumKey)
        let maximum = try container.decode(Point3D.self, forKey: maximumKey)
        do {
            try self.init(minimum: minimum, maximum: maximum)
        } catch {
            throw invalidSpatialBoundsDecodingError(
                decoder: decoder,
                maximumKey: maximumKey,
                underlyingError: error
            )
        }
    }

    /// Encodes the exact minimum and maximum points.
    public func encode(to encoder: any Encoder) throws {
        let minimumKey = SpatialBoundsCodingKey("minimum")
        let maximumKey = SpatialBoundsCodingKey("maximum")
        var container = encoder.container(keyedBy: SpatialBoundsCodingKey.self)
        try container.encode(minimum, forKey: minimumKey)
        try container.encode(maximum, forKey: maximumKey)
    }
}

private struct SpatialBoundsCodingKey: CodingKey {
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

private func invalidSpatialBoundsDecodingError(
    decoder: any Decoder,
    maximumKey: SpatialBoundsCodingKey,
    underlyingError: any Error
) -> DecodingError {
    var codingPath = decoder.codingPath
    codingPath.append(maximumKey)
    if let boundsError = underlyingError as? SpatialBoundsError {
        switch boundsError {
        case .coordinateSpaceMismatch:
            codingPath.append(SpatialBoundsCodingKey("coordinateSpace"))
        case .invertedBounds(let axis, _, _) where (0..<3).contains(axis):
            codingPath.append(SpatialBoundsCodingKey(["x", "y", "z"][axis]))
        case .invertedBounds:
            break
        }
    }

    return DecodingError.dataCorrupted(
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "AxisAlignedBounds3D contains incompatible points.",
            underlyingError: underlyingError
        )
    )
}
