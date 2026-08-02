// SPDX-License-Identifier: MIT

/// An error raised while validating a spatial primitive.
public enum SpatialPrimitiveError: Error, Sendable, Equatable {
    /// A coordinate component was NaN or infinity. Indices 0, 1, and 2
    /// correspond to X, Y, and Z respectively.
    case nonFiniteComponent(index: Int)

    /// A plane was supplied an all-zero normal vector.
    case zeroNormal

    /// A ray was supplied an all-zero direction vector.
    case zeroDirection

    /// Related spatial values use different coordinate-space identifiers.
    case coordinateSpaceMismatch(
        expected: CoordinateSpaceID,
        actual: CoordinateSpaceID
    )
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

/// An oriented plane defined by an origin and a non-zero normal vector.
///
/// The normal is preserved without implicit normalization. Its coordinate
/// space must exactly match the origin's coordinate space.
public struct Plane3D: Sendable, Hashable, Codable {
    /// A point lying on the plane.
    public let origin: Point3D
    /// The non-zero vector defining the plane's orientation.
    public let normal: Vector3D

    /// Creates a plane without changing the supplied normal.
    ///
    /// - Throws: ``SpatialPrimitiveError/zeroNormal`` if every normal
    ///   component is zero, or
    ///   ``SpatialPrimitiveError/coordinateSpaceMismatch(expected:actual:)``
    ///   if the origin and normal use different coordinate spaces.
    public init(origin: Point3D, normal: Vector3D) throws {
        guard origin.coordinateSpace == normal.coordinateSpace else {
            throw SpatialPrimitiveError.coordinateSpaceMismatch(
                expected: origin.coordinateSpace,
                actual: normal.coordinateSpace
            )
        }
        guard !isZeroSpatialVector(normal) else {
            throw SpatialPrimitiveError.zeroNormal
        }

        self.origin = origin
        self.normal = normal
    }

    /// Decodes and revalidates the plane's spatial invariants.
    public init(from decoder: any Decoder) throws {
        let originKey = SpatialPrimitiveCodingKey("origin")
        let normalKey = SpatialPrimitiveCodingKey("normal")
        let container = try exactSpatialPrimitiveContainer(
            from: decoder,
            expectedKeys: [originKey, normalKey],
            description: "A plane requires origin and normal."
        )
        let origin = try container.decode(Point3D.self, forKey: originKey)
        let normal = try container.decode(Vector3D.self, forKey: normalKey)

        do {
            try self.init(origin: origin, normal: normal)
        } catch {
            throw invalidCompositeSpatialPrimitiveDecodingError(
                decoder: decoder,
                kind: "Plane3D",
                vectorKey: normalKey,
                underlyingError: error
            )
        }
    }

    /// Encodes the plane's origin and normal without changing either value.
    public func encode(to encoder: any Encoder) throws {
        let originKey = SpatialPrimitiveCodingKey("origin")
        let normalKey = SpatialPrimitiveCodingKey("normal")
        var container = encoder.container(keyedBy: SpatialPrimitiveCodingKey.self)
        try container.encode(origin, forKey: originKey)
        try container.encode(normal, forKey: normalKey)
    }
}

/// A ray defined by an origin and a non-zero direction vector.
///
/// The direction is preserved without implicit normalization. Its coordinate
/// space must exactly match the origin's coordinate space.
public struct Ray3D: Sendable, Hashable, Codable {
    /// The ray's starting point.
    public let origin: Point3D
    /// The non-zero vector defining the ray's direction and parameterization.
    public let direction: Vector3D

    /// Creates a ray without changing the supplied direction.
    ///
    /// - Throws: ``SpatialPrimitiveError/zeroDirection`` if every direction
    ///   component is zero, or
    ///   ``SpatialPrimitiveError/coordinateSpaceMismatch(expected:actual:)``
    ///   if the origin and direction use different coordinate spaces.
    public init(origin: Point3D, direction: Vector3D) throws {
        guard origin.coordinateSpace == direction.coordinateSpace else {
            throw SpatialPrimitiveError.coordinateSpaceMismatch(
                expected: origin.coordinateSpace,
                actual: direction.coordinateSpace
            )
        }
        guard !isZeroSpatialVector(direction) else {
            throw SpatialPrimitiveError.zeroDirection
        }

        self.origin = origin
        self.direction = direction
    }

    /// Decodes and revalidates the ray's spatial invariants.
    public init(from decoder: any Decoder) throws {
        let originKey = SpatialPrimitiveCodingKey("origin")
        let directionKey = SpatialPrimitiveCodingKey("direction")
        let container = try exactSpatialPrimitiveContainer(
            from: decoder,
            expectedKeys: [originKey, directionKey],
            description: "A ray requires origin and direction."
        )
        let origin = try container.decode(Point3D.self, forKey: originKey)
        let direction = try container.decode(Vector3D.self, forKey: directionKey)

        do {
            try self.init(origin: origin, direction: direction)
        } catch {
            throw invalidCompositeSpatialPrimitiveDecodingError(
                decoder: decoder,
                kind: "Ray3D",
                vectorKey: directionKey,
                underlyingError: error
            )
        }
    }

    /// Encodes the ray's origin and direction without changing either value.
    public func encode(to encoder: any Encoder) throws {
        let originKey = SpatialPrimitiveCodingKey("origin")
        let directionKey = SpatialPrimitiveCodingKey("direction")
        var container = encoder.container(keyedBy: SpatialPrimitiveCodingKey.self)
        try container.encode(origin, forKey: originKey)
        try container.encode(direction, forKey: directionKey)
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
    let container = try exactSpatialPrimitiveContainer(
        from: decoder,
        expectedKeys: [xKey, yKey, zKey, coordinateSpaceKey],
        description: "A spatial primitive requires x, y, z, and coordinateSpace."
    )

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

private func exactSpatialPrimitiveContainer(
    from decoder: any Decoder,
    expectedKeys: [SpatialPrimitiveCodingKey],
    description: String
) throws -> KeyedDecodingContainer<SpatialPrimitiveCodingKey> {
    let container = try decoder.container(keyedBy: SpatialPrimitiveCodingKey.self)
    let expectedNames = Set(expectedKeys.map(\.stringValue))
    guard Set(container.allKeys.map(\.stringValue)) == expectedNames else {
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: description
            )
        )
    }
    return container
}

private func isZeroSpatialVector(_ vector: Vector3D) -> Bool {
    vector.x == 0 && vector.y == 0 && vector.z == 0
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

private func invalidCompositeSpatialPrimitiveDecodingError(
    decoder: any Decoder,
    kind: String,
    vectorKey: SpatialPrimitiveCodingKey,
    underlyingError: any Error
) -> DecodingError {
    DecodingError.dataCorrupted(
        DecodingError.Context(
            codingPath: decoder.codingPath + [vectorKey],
            debugDescription: "\(kind) contains incompatible spatial values.",
            underlyingError: underlyingError
        )
    )
}
