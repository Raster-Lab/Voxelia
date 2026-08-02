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
