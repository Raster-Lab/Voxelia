// SPDX-License-Identifier: MIT

/// The canonical scalar element types supported by Voxelia data descriptors.
public enum ScalarType: String, Sendable, Codable, Hashable, CaseIterable {
    case int8
    case uint8
    case int16
    case uint16
    case int32
    case uint32
    case int64
    case uint64
    case float16
    case float32
    case float64

    /// The scalar container size in bytes.
    public var byteCount: Int { bitCount / 8 }

    /// The scalar container size in bits.
    public var bitCount: Int {
        switch self {
        case .int8, .uint8:
            8
        case .int16, .uint16, .float16:
            16
        case .int32, .uint32, .float32:
            32
        case .int64, .uint64, .float64:
            64
        }
    }

    /// Whether the scalar is a signed integer type.
    ///
    /// Floating-point sign semantics are represented by ``isFloatingPoint``
    /// rather than being compressed into this Boolean.
    public var isSignedInteger: Bool {
        switch self {
        case .int8, .int16, .int32, .int64:
            true
        case .uint8, .uint16, .uint32, .uint64, .float16, .float32, .float64:
            false
        }
    }

    /// Whether the scalar is an integer type.
    public var isInteger: Bool {
        switch self {
        case .int8, .uint8, .int16, .uint16, .int32, .uint32, .int64, .uint64:
            true
        case .float16, .float32, .float64:
            false
        }
    }

    /// Whether the scalar is a floating-point type.
    public var isFloatingPoint: Bool { !isInteger }

    /// Whether the representation supports infinity and NaN in addition to
    /// finite values.
    public var supportsNonFiniteValues: Bool { isFloatingPoint }

    /// The full finite range of the declared scalar container type.
    ///
    /// This range is not narrowed by `ScalarFormat.validBitCount`, because the
    /// interpretation and placement of unused bits belong to source decoding
    /// metadata rather than this scalar descriptor.
    public var validValueRange: ScalarValueRange {
        switch self {
        case .int8:
            .signedInteger(Int64(Int8.min)...Int64(Int8.max))
        case .uint8:
            .unsignedInteger(UInt64(UInt8.min)...UInt64(UInt8.max))
        case .int16:
            .signedInteger(Int64(Int16.min)...Int64(Int16.max))
        case .uint16:
            .unsignedInteger(UInt64(UInt16.min)...UInt64(UInt16.max))
        case .int32:
            .signedInteger(Int64(Int32.min)...Int64(Int32.max))
        case .uint32:
            .unsignedInteger(UInt64(UInt32.min)...UInt64(UInt32.max))
        case .int64:
            .signedInteger(Int64.min...Int64.max)
        case .uint64:
            .unsignedInteger(UInt64.min...UInt64.max)
        case .float16:
            .floatingPoint(
                (-Double(Float16.greatestFiniteMagnitude))...Double(
                    Float16.greatestFiniteMagnitude
                )
            )
        case .float32:
            .floatingPoint(
                (-Double(Float.greatestFiniteMagnitude))...Double(
                    Float.greatestFiniteMagnitude
                )
            )
        case .float64:
            .floatingPoint(
                (-Double.greatestFiniteMagnitude)...Double.greatestFiniteMagnitude
            )
        }
    }
}

/// An exact, type-preserving finite scalar range.
public enum ScalarValueRange: Sendable, Hashable {
    case signedInteger(ClosedRange<Int64>)
    case unsignedInteger(ClosedRange<UInt64>)
    case floatingPoint(ClosedRange<Double>)
}

/// The byte order associated with a scalar storage representation.
public enum ByteOrder: String, Sendable, Codable, Hashable {
    /// The executing platform's native byte order.
    case native

    /// Least-significant byte first.
    case littleEndian

    /// Most-significant byte first.
    case bigEndian
}

/// A validated scalar container and source-layout descriptor.
public struct ScalarFormat: Sendable, Hashable, Codable {
    /// The scalar container type.
    public let type: ScalarType

    /// The number of meaningful bits, when smaller-source semantics are known.
    ///
    /// This value does not describe bit placement or a packed storage layout.
    public let validBitCount: Int?

    /// The declared storage byte order.
    public let byteOrder: ByteOrder

    /// Creates a scalar format while preserving explicit source metadata.
    ///
    /// - Throws: ``DataModelError/invalidScalarFormat`` when `validBitCount`
    ///   is not in `1...type.bitCount`.
    public init(
        type: ScalarType,
        validBitCount: Int?,
        byteOrder: ByteOrder
    ) throws {
        if let validBitCount,
            !(1...type.bitCount).contains(validBitCount)
        {
            throw DataModelError.invalidScalarFormat
        }

        self.type = type
        self.validBitCount = validBitCount
        self.byteOrder = byteOrder
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case validBitCount
        case byteOrder
    }

    /// Decodes and revalidates a format so serialized input cannot bypass its
    /// valid-bit invariant.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedType = try container.decode(ScalarType.self, forKey: .type)
        let decodedValidBitCount = try container.decodeIfPresent(
            Int.self,
            forKey: .validBitCount
        )
        let decodedByteOrder = try container.decode(
            ByteOrder.self,
            forKey: .byteOrder
        )

        do {
            try self.init(
                type: decodedType,
                validBitCount: decodedValidBitCount,
                byteOrder: decodedByteOrder
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.validBitCount],
                    debugDescription: "ScalarFormat has an invalid validBitCount.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes all supplied scalar metadata without normalization.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(validBitCount, forKey: .validBitCount)
        try container.encode(byteOrder, forKey: .byteOrder)
    }
}
