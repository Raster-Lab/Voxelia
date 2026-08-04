// SPDX-License-Identifier: MIT

/// The locality/backing class of a decoded representation.
public enum StorageRepresentationLocality: String, Sendable, Hashable {
    case processLocalOwned
    case external
    case mapped
}

/// One tagged physical or opaque representation, frozen by `ADR-0042` and
/// selected by accepted `ADR-0039`/`ADR-0040`.
///
/// Representation facts never change logical identity, and a descriptor
/// establishes no provider equality, integrity or residency authority.
public enum StorageRepresentationDescriptor: Sendable, Hashable {
    case decodedStrided(DecodedStridedRepresentation)
    case opaque(OpaqueRepresentation)
}

/// A checked decoded strided representation.
///
/// The first admitted profile accepts exactly the canonical packed
/// interleaved layout for its binding — component stride equal to the
/// scalar byte count and axis strides growing axis-zero-fastest — with an
/// arbitrary checked base offset. General permuted or padded strided
/// layouts and packed sub-byte contracts require later admission
/// increments; rejecting them now is the accepted fail-closed rule, not a
/// wire or semantic restriction.
public struct DecodedStridedRepresentation: Sendable, Hashable {
    public let binding: LogicalSampleBinding
    public let baseOffset: Int
    public let axisStrides: ContiguousArray<Int>
    public let componentStride: Int
    public let byteOrder: ByteOrder
    public let locality: StorageRepresentationLocality
    public let initializedByteCount: Int

    /// Admits one canonical packed representation with checked coverage.
    ///
    /// - Throws: ``StorageContractError/incompatibleBinding`` for a rank
    ///   mismatch, non-canonical stride, or multi-byte `.native` order
    ///   outside process-local owned memory;
    ///   ``StorageContractError/invalidRegion`` for a negative base
    ///   offset; ``StorageContractError/resourceLimitExceeded`` when the
    ///   checked addressed span overflows or exceeds the initialised
    ///   length.
    public init(
        binding: LogicalSampleBinding,
        baseOffset: Int,
        axisStrides: ContiguousArray<Int>,
        componentStride: Int,
        byteOrder: ByteOrder,
        locality: StorageRepresentationLocality,
        initializedByteCount: Int
    ) throws {
        guard baseOffset >= 0 else {
            throw StorageContractError.invalidRegion
        }
        let scalarByteCount = binding.scalarType.byteCount
        if scalarByteCount > 1, byteOrder == .native, locality != .processLocalOwned {
            throw StorageContractError.incompatibleBinding
        }
        guard componentStride == scalarByteCount else {
            throw StorageContractError.incompatibleBinding
        }
        let extents = binding.shape.extents
        guard axisStrides.count == extents.count else {
            throw StorageContractError.incompatibleBinding
        }
        var expectedStride = scalarByteCount
        expectedStride *= binding.componentCount
        for axis in extents.indices {
            guard axisStrides[axis] == expectedStride else {
                throw StorageContractError.incompatibleBinding
            }
            let (next, overflow) = expectedStride.multipliedReportingOverflow(
                by: extents[axis]
            )
            guard !overflow else {
                throw StorageContractError.resourceLimitExceeded
            }
            expectedStride = next
        }

        // The canonical packed span is exactly the binding's byte count.
        let (upperBound, overflow) = baseOffset.addingReportingOverflow(
            binding.logicalByteCount
        )
        guard !overflow, upperBound <= initializedByteCount else {
            throw StorageContractError.resourceLimitExceeded
        }

        self.binding = binding
        self.baseOffset = baseOffset
        self.axisStrides = axisStrides
        self.componentStride = componentStride
        self.byteOrder = byteOrder
        self.locality = locality
        self.initializedByteCount = initializedByteCount
    }

    /// The canonical packed representation at base offset zero whose
    /// initialised length equals the binding's exact byte count.
    public static func canonicalPacked(
        binding: LogicalSampleBinding,
        byteOrder: ByteOrder,
        locality: StorageRepresentationLocality
    ) throws -> DecodedStridedRepresentation {
        var strides = ContiguousArray<Int>()
        var stride = binding.scalarType.byteCount * binding.componentCount
        for extent in binding.shape.extents {
            strides.append(stride)
            stride *= extent
        }
        return try DecodedStridedRepresentation(
            binding: binding,
            baseOffset: 0,
            axisStrides: strides,
            componentStride: binding.scalarType.byteCount,
            byteOrder: byteOrder,
            locality: locality,
            initializedByteCount: binding.logicalByteCount
        )
    }
}

/// An opaque representation identified by a bounded typed tag.
public struct OpaqueRepresentation: Sendable, Hashable {
    /// The hard inclusive tag byte ceiling.
    public static let maximumFormatTagUTF8ByteCount = 255

    public let formatTag: String
    public let knownByteCount: Int?

    /// - Throws: ``StorageContractError/incompatibleBinding`` for a blank
    ///   or oversized tag or a negative known length.
    public init(formatTag: String, knownByteCount: Int?) throws {
        guard
            !metadataIdentityFieldIsBlank(formatTag),
            formatTag.utf8.count <= Self.maximumFormatTagUTF8ByteCount
        else {
            throw StorageContractError.incompatibleBinding
        }
        if let knownByteCount, knownByteCount < 0 {
            throw StorageContractError.incompatibleBinding
        }
        self.formatTag = formatTag
        self.knownByteCount = knownByteCount
    }
}
