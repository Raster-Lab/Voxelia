// SPDX-License-Identifier: MIT

/// An error raised while validating or operating on an image region.
public enum RegionError: Error, Sendable, Equatable {
    /// The lower and upper bound collections have different ranks.
    case rankMismatch

    /// A lower bound is greater than its corresponding upper bound.
    ///
    /// - Parameters:
    ///   - axis: The zero-based axis containing the inverted bounds.
    ///   - lower: The rejected lower bound.
    ///   - upper: The rejected upper bound.
    case invertedBounds(axis: Int, lower: Int, upper: Int)

    /// The region is not contained within a required image shape.
    case outsideShape

    /// Bounds arithmetic cannot be represented by `Int`.
    case arithmeticOverflow

    /// A storage read was requested for an empty region.
    case emptyRead
}

/// An immutable, dynamic-rank, half-open image region.
///
/// Each axis represents `[lowerBounds[axis], upperBounds[axis])`. Equal bounds
/// are permitted so transient query and intersection results can represent an
/// empty region. Bounds may be negative until a shape-aware operation validates
/// containment.
public struct ImageRegion: Sendable, Hashable, Codable {
    /// The inclusive lower bound for every logical axis.
    public let lowerBounds: ContiguousArray<Int>

    /// The exclusive upper bound for every logical axis.
    public let upperBounds: ContiguousArray<Int>

    /// The number of logical axes represented by this region.
    public var rank: Int { lowerBounds.count }

    /// Creates a half-open region from lower and upper bound collections.
    ///
    /// - Throws: ``RegionError/rankMismatch`` when the collections have
    ///   different counts, or
    ///   ``RegionError/invertedBounds(axis:lower:upper:)`` for the first axis
    ///   whose lower bound exceeds its upper bound, or
    ///   ``RegionError/arithmeticOverflow`` when an axis extent cannot be
    ///   represented by `Int`.
    public init<Lower: Collection, Upper: Collection>(
        lowerBounds: Lower,
        upperBounds: Upper
    ) throws where Lower.Element == Int, Upper.Element == Int {
        let validatedLowerBounds = ContiguousArray(lowerBounds)
        let validatedUpperBounds = ContiguousArray(upperBounds)

        guard validatedLowerBounds.count == validatedUpperBounds.count else {
            throw RegionError.rankMismatch
        }
        for axis in validatedLowerBounds.indices {
            let lower = validatedLowerBounds[axis]
            let upper = validatedUpperBounds[axis]
            guard lower <= upper else {
                throw RegionError.invertedBounds(
                    axis: axis,
                    lower: lower,
                    upper: upper
                )
            }
            guard !upper.subtractingReportingOverflow(lower).overflow else {
                throw RegionError.arithmeticOverflow
            }
        }

        self.lowerBounds = validatedLowerBounds
        self.upperBounds = validatedUpperBounds
    }

    /// Creates a half-open region from lower bounds and positive extents.
    ///
    /// Negative lower bounds are preserved because containment in an image
    /// shape is a separate access-time validation. The canonical stored and
    /// serialized representation remains lower plus upper bounds.
    ///
    /// - Throws: ``RegionError/rankMismatch`` when `lowerBounds` and `extents`
    ///   have different ranks, or ``RegionError/arithmeticOverflow`` when an
    ///   upper bound cannot be represented by `Int`.
    public init<LowerBounds: Collection>(
        lowerBounds: LowerBounds,
        extents: ImageShape
    ) throws where LowerBounds.Element == Int {
        let validatedLowerBounds = ContiguousArray(lowerBounds)
        guard validatedLowerBounds.count == extents.rank else {
            throw RegionError.rankMismatch
        }

        var upperBounds = ContiguousArray<Int>()
        upperBounds.reserveCapacity(extents.rank)
        for axis in validatedLowerBounds.indices {
            let addition = validatedLowerBounds[axis].addingReportingOverflow(
                extents.extents[axis]
            )
            guard !addition.overflow else {
                throw RegionError.arithmeticOverflow
            }
            upperBounds.append(addition.partialValue)
        }

        try self.init(
            lowerBounds: validatedLowerBounds,
            upperBounds: upperBounds
        )
    }

    /// Returns the positive extent of every non-empty axis.
    ///
    /// - Throws: ``RegionError/arithmeticOverflow`` when subtracting a bound
    ///   pair cannot be represented by `Int`. Because ``ImageShape`` requires
    ///   positive extents, an empty region produces the corresponding
    ///   ``ShapeError`` instead of an image shape.
    public func extents() throws -> ImageShape {
        var regionExtents = ContiguousArray<Int>()
        regionExtents.reserveCapacity(rank)

        for axis in lowerBounds.indices {
            let subtraction = upperBounds[axis].subtractingReportingOverflow(
                lowerBounds[axis]
            )
            guard !subtraction.overflow else {
                throw RegionError.arithmeticOverflow
            }
            regionExtents.append(subtraction.partialValue)
        }

        return try ImageShape(extents: regionExtents)
    }

    /// Validates that this region is contained in `shape`.
    ///
    /// Half-open upper bounds may equal the corresponding shape extent. An
    /// empty region is contained when its anchor lies in `0...extent`,
    /// including exactly on the upper boundary.
    ///
    /// - Throws: ``RegionError/rankMismatch`` when the ranks differ, or
    ///   ``RegionError/outsideShape`` when any lower bound is negative or any
    ///   upper bound exceeds the corresponding shape extent.
    public func validateContainment(in shape: ImageShape) throws {
        guard rank == shape.rank else {
            throw RegionError.rankMismatch
        }

        for axis in lowerBounds.indices {
            guard lowerBounds[axis] >= 0,
                upperBounds[axis] <= shape.extents[axis]
            else {
                throw RegionError.outsideShape
            }
        }
    }

    /// Returns a region translated by one signed offset per axis.
    ///
    /// Translation preserves the region's extents and empty axes. It does not
    /// clamp to, or validate containment in, any image shape.
    ///
    /// - Throws: ``RegionError/rankMismatch`` when `offsets` has a different
    ///   rank, or ``RegionError/arithmeticOverflow`` when any translated lower
    ///   or upper bound cannot be represented by `Int`.
    public func translated<Offsets: Collection>(
        by offsets: Offsets
    ) throws -> ImageRegion where Offsets.Element == Int {
        let validatedOffsets = ContiguousArray(offsets)
        guard validatedOffsets.count == rank else {
            throw RegionError.rankMismatch
        }

        var translatedLowerBounds = ContiguousArray<Int>()
        var translatedUpperBounds = ContiguousArray<Int>()
        translatedLowerBounds.reserveCapacity(rank)
        translatedUpperBounds.reserveCapacity(rank)

        for axis in lowerBounds.indices {
            let lower = lowerBounds[axis].addingReportingOverflow(
                validatedOffsets[axis]
            )
            guard !lower.overflow else {
                throw RegionError.arithmeticOverflow
            }
            let upper = upperBounds[axis].addingReportingOverflow(
                validatedOffsets[axis]
            )
            guard !upper.overflow else {
                throw RegionError.arithmeticOverflow
            }
            translatedLowerBounds.append(lower.partialValue)
            translatedUpperBounds.append(upper.partialValue)
        }

        return try ImageRegion(
            lowerBounds: translatedLowerBounds,
            upperBounds: translatedUpperBounds
        )
    }

    /// Returns this region clipped componentwise to `shape`.
    ///
    /// Each lower and upper bound is clamped to `0...extent`. A region wholly
    /// outside the shape therefore becomes an empty region anchored at zero or
    /// at the corresponding upper shape boundary.
    ///
    /// - Throws: ``RegionError/rankMismatch`` when the ranks differ.
    public func clipped(to shape: ImageShape) throws -> ImageRegion {
        guard rank == shape.rank else {
            throw RegionError.rankMismatch
        }

        var clippedLowerBounds = ContiguousArray<Int>()
        var clippedUpperBounds = ContiguousArray<Int>()
        clippedLowerBounds.reserveCapacity(rank)
        clippedUpperBounds.reserveCapacity(rank)

        for axis in lowerBounds.indices {
            let extent = shape.extents[axis]
            clippedLowerBounds.append(
                min(max(lowerBounds[axis], 0), extent)
            )
            clippedUpperBounds.append(
                min(max(upperBounds[axis], 0), extent)
            )
        }

        return try ImageRegion(
            lowerBounds: clippedLowerBounds,
            upperBounds: clippedUpperBounds
        )
    }

    private enum CodingKeys: String, CodingKey {
        case lowerBounds
        case upperBounds
    }

    /// Decodes and revalidates a region so serialized input cannot bypass its
    /// rank and ordering invariants.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedLowerBounds = try container.decode(
            ContiguousArray<Int>.self,
            forKey: .lowerBounds
        )
        let decodedUpperBounds = try container.decode(
            ContiguousArray<Int>.self,
            forKey: .upperBounds
        )

        do {
            try self.init(
                lowerBounds: decodedLowerBounds,
                upperBounds: decodedUpperBounds
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "ImageRegion contains invalid bounds.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes the validated bounds using a stable keyed representation.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowerBounds, forKey: .lowerBounds)
        try container.encode(upperBounds, forKey: .upperBounds)
    }
}
