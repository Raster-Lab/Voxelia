// SPDX-License-Identifier: MIT

/// An error raised while validating a canonical four-by-four matrix.
public enum Matrix4x4DoubleError: Error, Sendable, Equatable {
    /// The supplied collection did not contain exactly sixteen elements.
    case invalidElementCount(actual: Int)

    /// The element at the row-major index was NaN or infinity.
    case nonFiniteElement(index: Int)
}

/// A canonical, serializable four-by-four matrix of `Double` values.
///
/// Elements are stored in row-major order, so the value at row `r` and column
/// `c` is `elements[r * 4 + c]`. Voxelia matrices multiply homogeneous column
/// vectors: `M × [x, y, z, 1]ᵀ`. Translation therefore occupies element
/// indices 3, 7, and 11.
///
/// This type validates only the general matrix representation. It does not
/// assert that the matrix is affine or invertible; those constraints belong to
/// the consuming geometry or transform operation.
public struct Matrix4x4Double: Sendable, Hashable, Codable {
    /// The sixteen finite row-major matrix elements.
    public let elements: ContiguousArray<Double>

    /// The multiplicative identity matrix.
    public static let identity = Self(
        validatedElements: [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        ]
    )

    /// Creates a canonical matrix from exactly sixteen finite values.
    ///
    /// Negative zero is normalized to positive zero because `Double` equality
    /// and hashing treat the two representations as the same value. No other
    /// value is changed.
    ///
    /// - Throws: ``Matrix4x4DoubleError/invalidElementCount(actual:)`` when the
    ///   collection does not contain sixteen elements, or
    ///   ``Matrix4x4DoubleError/nonFiniteElement(index:)`` for NaN or infinity.
    public init<Elements: Collection>(elements: Elements) throws
    where Elements.Element == Double {
        let actualCount = elements.count
        guard actualCount == 16 else {
            throw Matrix4x4DoubleError.invalidElementCount(actual: actualCount)
        }

        var validatedElements = ContiguousArray<Double>()
        validatedElements.reserveCapacity(16)
        for (index, element) in elements.enumerated() {
            guard element.isFinite else {
                throw Matrix4x4DoubleError.nonFiniteElement(index: index)
            }
            validatedElements.append(element == 0 ? 0 : element)
        }
        guard validatedElements.count == 16 else {
            throw Matrix4x4DoubleError.invalidElementCount(
                actual: validatedElements.count
            )
        }

        self.init(validatedElements: validatedElements)
    }

    private init(validatedElements: ContiguousArray<Double>) {
        elements = validatedElements
    }

    /// Decodes the stable keyed representation and revalidates every element.
    public init(from decoder: any Decoder) throws {
        let elementsKey = MatrixCodingKey("elements")
        let container = try decoder.container(keyedBy: MatrixCodingKey.self)
        guard container.allKeys.map(\.stringValue) == [elementsKey.stringValue] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Matrix4x4Double requires exactly one elements field."
                )
            )
        }
        let decodedElements = try container.decode(
            ContiguousArray<Double>.self,
            forKey: elementsKey
        )

        do {
            try self.init(elements: decodedElements)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [elementsKey],
                    debugDescription: "Matrix4x4Double contains invalid elements.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes the sixteen elements in documented row-major order.
    public func encode(to encoder: any Encoder) throws {
        let elementsKey = MatrixCodingKey("elements")
        var container = encoder.container(keyedBy: MatrixCodingKey.self)
        try container.encode(elements, forKey: elementsKey)
    }
}

private struct MatrixCodingKey: CodingKey {
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
