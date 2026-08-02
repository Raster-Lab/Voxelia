// SPDX-License-Identifier: MIT

/// An error raised while validating a spatial point or vector.
public enum SpatialPrimitiveError: Error, Sendable, Equatable {
    /// A coordinate component was NaN or infinity. Indices 0, 1, and 2
    /// correspond to X, Y, and Z respectively.
    case nonFiniteComponent(index: Int)
}

/// A finite three-dimensional point in an explicit coordinate space.
public struct Point3D: Sendable, Hashable, Codable {
    /// The X coordinate.
    public let x: Double
    /// The Y coordinate.
    public let y: Double
    /// The Z coordinate.
    public let z: Double
    /// The coordinate space in which the point is expressed.
    public let coordinateSpace: CoordinateSpaceID

    /// Creates a point from finite coordinates without changing its space.
    ///
    /// Signed zero is canonicalized to positive zero. No other finite value is
    /// normalized.
    ///
    /// - Throws: ``SpatialPrimitiveError/nonFiniteComponent(index:)`` for NaN
    ///   or infinity.
    public init(
        x: Double,
        y: Double,
        z: Double,
        coordinateSpace: CoordinateSpaceID
    ) throws {
        let components = try validatedSpatialComponents(x: x, y: y, z: z)
        self.x = components.x
        self.y = components.y
        self.z = components.z
        self.coordinateSpace = coordinateSpace
    }

    /// Decodes and revalidates all point coordinates.
    public init(from decoder: any Decoder) throws {
        let decoded = try decodeSpatialPrimitive(from: decoder)
        do {
            try self.init(
                x: decoded.x,
                y: decoded.y,
                z: decoded.z,
                coordinateSpace: decoded.coordinateSpace
            )
        } catch {
            throw invalidSpatialPrimitiveDecodingError(
                decoder: decoder,
                kind: "Point3D",
                underlyingError: error
            )
        }
    }

    /// Encodes coordinates with their explicit coordinate-space identity.
    public func encode(to encoder: any Encoder) throws {
        try encodeSpatialPrimitive(
            x: x,
            y: y,
            z: z,
            coordinateSpace: coordinateSpace,
            to: encoder
        )
    }
}

/// A finite three-dimensional vector in an explicit coordinate space.
///
/// A zero vector is valid. Consumers that interpret a vector as a direction or
/// normal must reject zero magnitude and must make normalization explicit.
public struct Vector3D: Sendable, Hashable, Codable {
    /// The X component.
    public let x: Double
    /// The Y component.
    public let y: Double
    /// The Z component.
    public let z: Double
    /// The coordinate space in which the vector is expressed.
    public let coordinateSpace: CoordinateSpaceID

    /// Creates a vector from finite components without normalization.
    ///
    /// Signed zero is canonicalized to positive zero. No other finite value is
    /// normalized.
    ///
    /// - Throws: ``SpatialPrimitiveError/nonFiniteComponent(index:)`` for NaN
    ///   or infinity.
    public init(
        x: Double,
        y: Double,
        z: Double,
        coordinateSpace: CoordinateSpaceID
    ) throws {
        let components = try validatedSpatialComponents(x: x, y: y, z: z)
        self.x = components.x
        self.y = components.y
        self.z = components.z
        self.coordinateSpace = coordinateSpace
    }

    /// Decodes and revalidates all vector components.
    public init(from decoder: any Decoder) throws {
        let decoded = try decodeSpatialPrimitive(from: decoder)
        do {
            try self.init(
                x: decoded.x,
                y: decoded.y,
                z: decoded.z,
                coordinateSpace: decoded.coordinateSpace
            )
        } catch {
            throw invalidSpatialPrimitiveDecodingError(
                decoder: decoder,
                kind: "Vector3D",
                underlyingError: error
            )
        }
    }

    /// Encodes components with their explicit coordinate-space identity.
    public func encode(to encoder: any Encoder) throws {
        try encodeSpatialPrimitive(
            x: x,
            y: y,
            z: z,
            coordinateSpace: coordinateSpace,
            to: encoder
        )
    }
}

private struct DecodedSpatialPrimitive {
    let x: Double
    let y: Double
    let z: Double
    let coordinateSpace: CoordinateSpaceID
}

private struct SpatialPrimitiveCodingKey: CodingKey {
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

private func validatedSpatialComponents(
    x: Double,
    y: Double,
    z: Double
) throws -> (x: Double, y: Double, z: Double) {
    let supplied = [x, y, z]
    for (index, component) in supplied.enumerated() {
        guard component.isFinite else {
            throw SpatialPrimitiveError.nonFiniteComponent(index: index)
        }
    }
    return (
        x == 0 ? 0 : x,
        y == 0 ? 0 : y,
        z == 0 ? 0 : z
    )
}

private func decodeSpatialPrimitive(
    from decoder: any Decoder
) throws -> DecodedSpatialPrimitive {
    let xKey = SpatialPrimitiveCodingKey("x")
    let yKey = SpatialPrimitiveCodingKey("y")
    let zKey = SpatialPrimitiveCodingKey("z")
    let coordinateSpaceKey = SpatialPrimitiveCodingKey("coordinateSpace")
    let container = try decoder.container(keyedBy: SpatialPrimitiveCodingKey.self)
    let expectedKeys = Set([
        xKey.stringValue,
        yKey.stringValue,
        zKey.stringValue,
        coordinateSpaceKey.stringValue,
    ])
    guard Set(container.allKeys.map(\.stringValue)) == expectedKeys else {
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "A spatial primitive requires x, y, z, and coordinateSpace."
            )
        )
    }

    return try DecodedSpatialPrimitive(
        x: container.decode(Double.self, forKey: xKey),
        y: container.decode(Double.self, forKey: yKey),
        z: container.decode(Double.self, forKey: zKey),
        coordinateSpace: container.decode(
            CoordinateSpaceID.self,
            forKey: coordinateSpaceKey
        )
    )
}

private func encodeSpatialPrimitive(
    x: Double,
    y: Double,
    z: Double,
    coordinateSpace: CoordinateSpaceID,
    to encoder: any Encoder
) throws {
    let xKey = SpatialPrimitiveCodingKey("x")
    let yKey = SpatialPrimitiveCodingKey("y")
    let zKey = SpatialPrimitiveCodingKey("z")
    let coordinateSpaceKey = SpatialPrimitiveCodingKey("coordinateSpace")
    var container = encoder.container(keyedBy: SpatialPrimitiveCodingKey.self)
    try container.encode(x, forKey: xKey)
    try container.encode(y, forKey: yKey)
    try container.encode(z, forKey: zKey)
    try container.encode(coordinateSpace, forKey: coordinateSpaceKey)
}

private func invalidSpatialPrimitiveDecodingError(
    decoder: any Decoder,
    kind: String,
    underlyingError: any Error
) -> DecodingError {
    var codingPath = decoder.codingPath
    if let primitiveError = underlyingError as? SpatialPrimitiveError,
        case .nonFiniteComponent(let index) = primitiveError,
        (0..<3).contains(index)
    {
        codingPath.append(SpatialPrimitiveCodingKey(["x", "y", "z"][index]))
    }

    return DecodingError.dataCorrupted(
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "\(kind) contains a non-finite component.",
            underlyingError: underlyingError
        )
    )
}
