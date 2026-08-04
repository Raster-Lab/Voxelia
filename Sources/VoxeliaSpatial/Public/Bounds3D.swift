// SPDX-License-Identifier: MIT

/// An error raised while validating spatial bounds.
public enum SpatialBoundsError: Error, Sendable, Equatable {
    /// Related bounds or query values use different coordinate spaces.
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

    /// The selected ray-intersection entry parameter was not representable
    /// as a finite binary64 value. Indices 0, 1, and 2 correspond to X, Y,
    /// and Z respectively.
    case rayIntersectionEntryParameterNotRepresentable(
        axis: Int,
        reason: RayIntersectionParameterFailureReason
    )

    /// The selected ray-intersection exit parameter was not representable
    /// as a finite binary64 value. Indices 0, 1, and 2 correspond to X, Y,
    /// and Z respectively.
    case rayIntersectionExitParameterNotRepresentable(
        axis: Int,
        reason: RayIntersectionParameterFailureReason
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

    /// Returns whether `point` lies inside or on these bounds.
    ///
    /// Component comparisons are exact and inclusive. This query applies no
    /// tolerance and performs no coordinate conversion.
    ///
    /// - Throws: ``SpatialBoundsError/coordinateSpaceMismatch(expected:actual:)``
    ///   when `point` is expressed in a different coordinate space.
    public func contains(_ point: Point3D) throws -> Bool {
        guard minimum.coordinateSpace == point.coordinateSpace else {
            throw SpatialBoundsError.coordinateSpaceMismatch(
                expected: minimum.coordinateSpace,
                actual: point.coordinateSpace
            )
        }

        return point.x >= minimum.x && point.x <= maximum.x
            && point.y >= minimum.y && point.y <= maximum.y
            && point.z >= minimum.z && point.z <= maximum.z
    }

    /// Returns the exact intersection with `other`, or nil when disjoint.
    ///
    /// Face, edge, and point contact produce valid degenerate bounds. The
    /// component comparisons apply no tolerance and perform no coordinate
    /// conversion.
    ///
    /// - Throws: ``SpatialBoundsError/coordinateSpaceMismatch(expected:actual:)``
    ///   when the bounds use different coordinate spaces.
    public func intersection(
        with other: AxisAlignedBounds3D
    ) throws -> AxisAlignedBounds3D? {
        guard minimum.coordinateSpace == other.minimum.coordinateSpace else {
            throw SpatialBoundsError.coordinateSpaceMismatch(
                expected: minimum.coordinateSpace,
                actual: other.minimum.coordinateSpace
            )
        }

        let intersectionMinimum = (
            x: max(minimum.x, other.minimum.x),
            y: max(minimum.y, other.minimum.y),
            z: max(minimum.z, other.minimum.z)
        )
        let intersectionMaximum = (
            x: min(maximum.x, other.maximum.x),
            y: min(maximum.y, other.maximum.y),
            z: min(maximum.z, other.maximum.z)
        )
        guard intersectionMinimum.x <= intersectionMaximum.x,
            intersectionMinimum.y <= intersectionMaximum.y,
            intersectionMinimum.z <= intersectionMaximum.z
        else {
            return nil
        }

        let space = minimum.coordinateSpace
        let intersectionMinimumPoint = try Point3D(
            x: intersectionMinimum.x,
            y: intersectionMinimum.y,
            z: intersectionMinimum.z,
            coordinateSpace: space
        )
        let intersectionMaximumPoint = try Point3D(
            x: intersectionMaximum.x,
            y: intersectionMaximum.y,
            z: intersectionMaximum.z,
            coordinateSpace: space
        )
        return try AxisAlignedBounds3D(
            minimum: intersectionMinimumPoint,
            maximum: intersectionMaximumPoint
        )
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
        case .rayIntersectionEntryParameterNotRepresentable,
            .rayIntersectionExitParameterNotRepresentable:
            // Intersection failures are query results, never decode causes.
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
