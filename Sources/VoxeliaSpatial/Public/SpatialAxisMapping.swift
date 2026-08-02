// SPDX-License-Identifier: MIT

/// An error raised while validating a mapping from image axes to spatial
/// transform coordinates.
public enum SpatialAxisMappingError: Error, Sendable, Equatable {
    /// A mapping must supply one, two, or three image axes.
    case invalidAxisCount(actual: Int)

    /// An image-axis index was negative and therefore invalid for every rank.
    case negativeAxis(position: Int, value: Int)

    /// The same image axis was assigned to more than one transform coordinate.
    case duplicateAxis(axis: Int, firstPosition: Int, duplicatePosition: Int)
}

/// An ordered mapping from image axes to X, Y, and Z transform coordinates.
///
/// The first entry supplies X, the second (when present) supplies Y, and the
/// third supplies Z. Unused transform coordinates are held at zero by the
/// consuming geometry. Image axes omitted from the mapping are non-spatial for
/// that geometry. This standalone value validates only invariants that do not
/// require an image shape; upper-bound validation against image rank occurs
/// when a geometry is bound to a descriptor.
public struct SpatialAxisMapping: Sendable, Hashable, Codable {
    /// One to three unique, nonnegative image-axis indices in X/Y/Z order.
    public let imageAxes: ContiguousArray<Int>

    /// Creates a structurally valid mapping while preserving supplied order.
    ///
    /// - Throws: ``SpatialAxisMappingError`` for an invalid count, a negative
    ///   axis, or a duplicate axis.
    public init<Axes: Collection>(imageAxes: Axes) throws
    where Axes.Element == Int {
        let actualCount = imageAxes.count
        guard (1...3).contains(actualCount) else {
            throw SpatialAxisMappingError.invalidAxisCount(actual: actualCount)
        }

        var validatedAxes = ContiguousArray<Int>()
        validatedAxes.reserveCapacity(actualCount)
        var firstPositions: [Int: Int] = [:]
        for (position, axis) in imageAxes.enumerated() {
            guard axis >= 0 else {
                throw SpatialAxisMappingError.negativeAxis(
                    position: position,
                    value: axis
                )
            }
            if let firstPosition = firstPositions[axis] {
                throw SpatialAxisMappingError.duplicateAxis(
                    axis: axis,
                    firstPosition: firstPosition,
                    duplicatePosition: position
                )
            }
            firstPositions[axis] = position
            validatedAxes.append(axis)
        }
        guard validatedAxes.count == actualCount else {
            throw SpatialAxisMappingError.invalidAxisCount(
                actual: validatedAxes.count
            )
        }

        self.imageAxes = validatedAxes
    }

    /// Decodes the stable keyed representation and revalidates its mapping.
    public init(from decoder: any Decoder) throws {
        let imageAxesKey = SpatialAxisMappingCodingKey("imageAxes")
        let container = try decoder.container(
            keyedBy: SpatialAxisMappingCodingKey.self
        )
        guard container.allKeys.map(\.stringValue) == [imageAxesKey.stringValue] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "SpatialAxisMapping requires exactly one imageAxes field."
                )
            )
        }
        let decodedAxes = try container.decode(
            ContiguousArray<Int>.self,
            forKey: imageAxesKey
        )

        do {
            try self.init(imageAxes: decodedAxes)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [imageAxesKey],
                    debugDescription: "SpatialAxisMapping contains invalid axes.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes image axes in their documented X/Y/Z consumption order.
    public func encode(to encoder: any Encoder) throws {
        let imageAxesKey = SpatialAxisMappingCodingKey("imageAxes")
        var container = encoder.container(
            keyedBy: SpatialAxisMappingCodingKey.self
        )
        try container.encode(imageAxes, forKey: imageAxesKey)
    }
}

private struct SpatialAxisMappingCodingKey: CodingKey {
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
