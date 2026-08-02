// SPDX-License-Identifier: MIT

/// An error raised while validating or using a dynamic-rank image shape.
public enum ShapeError: Error, Sendable, Equatable {
    /// A shape was constructed without any axes.
    case emptyRank

    /// An axis extent was zero or negative.
    ///
    /// - Parameters:
    ///   - axis: The zero-based axis containing the invalid extent.
    ///   - value: The rejected extent.
    case nonPositiveExtent(axis: Int, value: Int)

    /// Multiplying the extents would exceed the range of `Int`.
    case elementCountOverflow

    /// An operation received a shape with an unsupported rank.
    case rankMismatch(expected: Int, actual: Int)
}

/// A validated, immutable, dynamic-rank image shape.
///
/// `ImageShape` stores one positive extent per logical image axis. The type
/// intentionally imposes no small fixed maximum rank. Use ``elementCount()``
/// when a contiguous element total is required; it reports overflow instead of
/// allowing integer multiplication to wrap.
public struct ImageShape: Sendable, Hashable, Codable {
    /// The positive extent of each logical axis.
    public let extents: ContiguousArray<Int>

    /// The number of logical axes.
    public var rank: Int { extents.count }

    /// Creates a shape from a variable-length collection of axis extents.
    ///
    /// - Parameter extents: One positive integer for each logical axis.
    /// - Throws: ``ShapeError/emptyRank`` when the collection is empty, or
    ///   ``ShapeError/nonPositiveExtent(axis:value:)`` for the first invalid
    ///   extent.
    public init<Extents: Collection>(extents: Extents) throws
    where Extents.Element == Int {
        let validatedExtents = ContiguousArray(extents)
        guard !validatedExtents.isEmpty else {
            throw ShapeError.emptyRank
        }
        for (axis, value) in validatedExtents.enumerated() where value <= 0 {
            throw ShapeError.nonPositiveExtent(axis: axis, value: value)
        }
        self.extents = validatedExtents
    }

    /// Returns the product of all axis extents.
    ///
    /// - Throws: ``ShapeError/elementCountOverflow`` when the product cannot be
    ///   represented by `Int`.
    public func elementCount() throws -> Int {
        var count = 1
        for extent in extents {
            let multiplication = count.multipliedReportingOverflow(by: extent)
            guard !multiplication.overflow else {
                throw ShapeError.elementCountOverflow
            }
            count = multiplication.partialValue
        }
        return count
    }

    private enum CodingKeys: String, CodingKey {
        case extents
    }

    /// Decodes and revalidates a shape so serialized input cannot bypass its
    /// invariants.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedExtents = try container.decode(
            ContiguousArray<Int>.self,
            forKey: .extents
        )
        do {
            try self.init(extents: decodedExtents)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.extents],
                    debugDescription: "ImageShape contains invalid extents.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes the validated extents using a stable keyed representation.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extents, forKey: .extents)
    }
}
