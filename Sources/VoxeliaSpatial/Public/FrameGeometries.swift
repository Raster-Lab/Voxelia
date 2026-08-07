// SPDX-License-Identifier: MIT

/// An error raised by frame-geometry admission, per `ADR-0377`.
public enum FrameGeometryError: Error, Sendable, Equatable {
    /// An origin or direction was not expressed in the declared space.
    case spaceMismatch
    /// A direction vector was exactly zero.
    case zeroDirection
    /// A spacing was non-positive, NaN or infinite.
    case invalidSpacing
    /// A slice position was NaN or infinite.
    case invalidSlicePosition
    /// Slice positions were not strictly monotone. Exactly equal
    /// adjacent positions refuse too: averaging or deduplicating them
    /// is the hidden regularisation `VOX-DCM-011` prohibits.
    case nonMonotoneSlicePositions
    /// No slice positions or frames were supplied.
    case emptyGeometry
    /// The frame axis was negative.
    case invalidFrameAxis
}

/// Rectilinear geometry, per `ADR-0377` (`VOX-SPA-012`): shared
/// orientation and in-plane spacing with **explicit** slice positions
/// along the normal — strictly monotone, never regularised.
public struct RectilinearGridGeometry: Sendable, Hashable, Codable {
    public let spatialAxes: SpatialAxisMapping
    public let coordinateSpace: CoordinateSpaceDescriptor
    public let origin: Point3D
    public let rowDirection: Vector3D
    public let columnDirection: Vector3D
    public let normalDirection: Vector3D
    public let rowSpacing: Double
    public let columnSpacing: Double
    /// The explicit slice offsets along the normal, strictly monotone.
    public let slicePositions: ContiguousArray<Double>

    /// Creates a validated rectilinear geometry.
    ///
    /// - Throws: ``FrameGeometryError``.
    public init(
        spatialAxes: SpatialAxisMapping,
        coordinateSpace: CoordinateSpaceDescriptor,
        origin: Point3D,
        rowDirection: Vector3D,
        columnDirection: Vector3D,
        normalDirection: Vector3D,
        rowSpacing: Double,
        columnSpacing: Double,
        slicePositions: ContiguousArray<Double>
    ) throws {
        guard origin.coordinateSpace == coordinateSpace.id else {
            throw FrameGeometryError.spaceMismatch
        }
        for direction in [rowDirection, columnDirection, normalDirection] {
            guard direction.coordinateSpace == coordinateSpace.id else {
                throw FrameGeometryError.spaceMismatch
            }
            guard direction.x != 0 || direction.y != 0 || direction.z != 0 else {
                throw FrameGeometryError.zeroDirection
            }
        }
        for spacing in [rowSpacing, columnSpacing] {
            guard spacing.isFinite, spacing > 0 else {
                throw FrameGeometryError.invalidSpacing
            }
        }
        guard !slicePositions.isEmpty else {
            throw FrameGeometryError.emptyGeometry
        }
        for position in slicePositions where !position.isFinite {
            throw FrameGeometryError.invalidSlicePosition
        }
        if slicePositions.count >= 2 {
            let ascending = slicePositions[1] > slicePositions[0]
            for index in 0..<(slicePositions.count - 1) {
                let step = slicePositions[index + 1] - slicePositions[index]
                guard step != 0, (step > 0) == ascending else {
                    throw FrameGeometryError.nonMonotoneSlicePositions
                }
            }
        }
        self.spatialAxes = spatialAxes
        self.coordinateSpace = coordinateSpace
        self.origin = origin
        self.rowDirection = rowDirection
        self.columnDirection = columnDirection
        self.normalDirection = normalDirection
        self.rowSpacing = rowSpacing
        self.columnSpacing = columnSpacing
        self.slicePositions = slicePositions
    }

    private enum CodingKeys: String, CodingKey {
        case spatialAxes
        case coordinateSpace
        case origin
        case rowDirection
        case columnDirection
        case normalDirection
        case rowSpacing
        case columnSpacing
        case slicePositions
    }

    /// Decodes and revalidates through the throwing admission.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            spatialAxes: try container.decode(
                SpatialAxisMapping.self, forKey: .spatialAxes
            ),
            coordinateSpace: try container.decode(
                CoordinateSpaceDescriptor.self, forKey: .coordinateSpace
            ),
            origin: try container.decode(Point3D.self, forKey: .origin),
            rowDirection: try container.decode(Vector3D.self, forKey: .rowDirection),
            columnDirection: try container.decode(
                Vector3D.self, forKey: .columnDirection
            ),
            normalDirection: try container.decode(
                Vector3D.self, forKey: .normalDirection
            ),
            rowSpacing: try container.decode(Double.self, forKey: .rowSpacing),
            columnSpacing: try container.decode(Double.self, forKey: .columnSpacing),
            slicePositions: try container.decode(
                ContiguousArray<Double>.self, forKey: .slicePositions
            )
        )
    }
}

/// One frame's plane, per `ADR-0377`: origin, in-plane directions and
/// spacings, admitted independently — no relationship to any other
/// frame is asserted, because none is promised.
public struct FramePlaneGeometry: Sendable, Hashable, Codable {
    public let origin: Point3D
    public let rowDirection: Vector3D
    public let columnDirection: Vector3D
    public let rowSpacing: Double
    public let columnSpacing: Double

    /// Creates a validated frame plane in `space`.
    ///
    /// - Throws: ``FrameGeometryError``.
    public init(
        origin: Point3D,
        rowDirection: Vector3D,
        columnDirection: Vector3D,
        rowSpacing: Double,
        columnSpacing: Double,
        space: CoordinateSpaceID
    ) throws {
        guard
            origin.coordinateSpace == space,
            rowDirection.coordinateSpace == space,
            columnDirection.coordinateSpace == space
        else {
            throw FrameGeometryError.spaceMismatch
        }
        for direction in [rowDirection, columnDirection] {
            guard direction.x != 0 || direction.y != 0 || direction.z != 0 else {
                throw FrameGeometryError.zeroDirection
            }
        }
        for spacing in [rowSpacing, columnSpacing] {
            guard spacing.isFinite, spacing > 0 else {
                throw FrameGeometryError.invalidSpacing
            }
        }
        self.origin = origin
        self.rowDirection = rowDirection
        self.columnDirection = columnDirection
        self.rowSpacing = rowSpacing
        self.columnSpacing = columnSpacing
    }

    private enum CodingKeys: String, CodingKey {
        case origin
        case rowDirection
        case columnDirection
        case rowSpacing
        case columnSpacing
    }

    /// Decodes and revalidates through the throwing admission; the
    /// space is the origin's own, matching the aggregate's check.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let origin = try container.decode(Point3D.self, forKey: .origin)
        try self.init(
            origin: origin,
            rowDirection: try container.decode(Vector3D.self, forKey: .rowDirection),
            columnDirection: try container.decode(
                Vector3D.self, forKey: .columnDirection
            ),
            rowSpacing: try container.decode(Double.self, forKey: .rowSpacing),
            columnSpacing: try container.decode(Double.self, forKey: .columnSpacing),
            space: origin.coordinateSpace
        )
    }
}

/// Irregular frame-set geometry, per `ADR-0377` (`VOX-DCM-011`): a
/// declared frame axis and one explicit plane per frame. There is no
/// conversion to affine — a consumer needing a regular grid must
/// resample explicitly through an operation that records what it did.
public struct FrameSetGeometry: Sendable, Hashable, Codable {
    public let coordinateSpace: CoordinateSpaceDescriptor
    /// The image axis that indexes frames.
    public let frameAxis: Int
    public let frames: ContiguousArray<FramePlaneGeometry>

    /// Creates a validated frame set.
    ///
    /// - Throws: ``FrameGeometryError``.
    public init(
        coordinateSpace: CoordinateSpaceDescriptor,
        frameAxis: Int,
        frames: ContiguousArray<FramePlaneGeometry>
    ) throws {
        guard frameAxis >= 0 else {
            throw FrameGeometryError.invalidFrameAxis
        }
        guard !frames.isEmpty else {
            throw FrameGeometryError.emptyGeometry
        }
        for frame in frames {
            guard frame.origin.coordinateSpace == coordinateSpace.id else {
                throw FrameGeometryError.spaceMismatch
            }
        }
        self.coordinateSpace = coordinateSpace
        self.frameAxis = frameAxis
        self.frames = frames
    }

    private enum CodingKeys: String, CodingKey {
        case coordinateSpace
        case frameAxis
        case frames
    }

    /// Decodes and revalidates through the throwing admission.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            coordinateSpace: try container.decode(
                CoordinateSpaceDescriptor.self, forKey: .coordinateSpace
            ),
            frameAxis: try container.decode(Int.self, forKey: .frameAxis),
            frames: try container.decode(
                ContiguousArray<FramePlaneGeometry>.self, forKey: .frames
            )
        )
    }
}
