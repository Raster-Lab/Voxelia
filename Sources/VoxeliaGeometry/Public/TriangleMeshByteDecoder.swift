// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised while reading a `gpu-geometry-representation/v1` payload.
///
/// Every case is about **bytes**. There is deliberately no geometric case: a
/// non-finite position and an out-of-range index are rejected by the canonical
/// value's own admission, which is precisely why the payload is never
/// authoritative.
///
/// Cases carry no payload so diagnostics disclose no bytes, counts or offsets.
public enum TriangleMeshByteDecodingError: Error, Sendable, Equatable {
    /// A supplied count was negative.
    case negativeCount

    /// A count could not address its own payload within the host integer
    /// range.
    case countNotRepresentable

    /// The position payload length was not exactly `vertexCount * 12`.
    case positionByteCountMismatch

    /// The index payload length was not exactly `triangleCount * 12`.
    case indexByteCountMismatch
}

/// The exact `gpu-geometry-representation/v1` reference.
///
/// This reads the byte layout a compute producer writes — tightly packed
/// three-component binary32 positions and `UInt32` indices, both little-endian
/// — and returns the canonical ``TriangleMesh``.
///
/// **The layout is the contract; a buffer is only transport.** Nothing here
/// names a graphics framework, a device, a buffer or a command queue, and the
/// decode is a pure function from bytes to a canonical value. A producer
/// conforms by emitting these bytes. Once decoded the payload is never
/// consulted again, so the canonical mesh — not the buffer — remains the only
/// authority.
public enum TriangleMeshByteDecoder {
    /// The exact bytes one vertex occupies: three little-endian binary32
    /// components, tightly packed with no padding.
    ///
    /// A producer using a shading language's sixteen-byte-aligned three-vector
    /// must pack before writing; the packed variant is already this layout.
    public static let positionStride = 12

    /// The exact bytes one triangle occupies: three little-endian `UInt32`
    /// indices.
    public static let triangleStride = 12

    /// Decodes one payload into the canonical mesh.
    ///
    /// Counts arrive **out of band**, from the dispatch that produced the
    /// bytes: a length-bearing header would let the payload decide its own
    /// allocation, and the caller already knows what it dispatched. The byte
    /// counts must then match exactly.
    ///
    /// The coordinate space is likewise supplied by the caller and is never
    /// carried in the payload. A buffer cannot declare a coordinate space, and
    /// letting bytes name one would be the relabelling `ADR-0183` decision 4
    /// forbids.
    ///
    /// Widening binary32 to binary64 is exact, so no precision is invented: a
    /// producer writing decimal `0.1` yields `0.10000000149011612`, and that is
    /// the value published.
    ///
    /// - Throws: ``TriangleMeshByteDecodingError`` for a byte-level fault, or
    ///   the canonical ``TriangleMeshPositionDomainError`` /
    ///   ``TriangleMeshTopologyError`` for a geometric one. The geometric rules
    ///   are not restated here.
    public static func decode(
        vertexCount: Int,
        triangleCount: Int,
        positionBytes: [UInt8],
        indexBytes: [UInt8],
        coordinateSpace: CoordinateSpaceDescriptor
    ) throws -> TriangleMesh {
        guard vertexCount >= 0, triangleCount >= 0 else {
            throw TriangleMeshByteDecodingError.negativeCount
        }
        // Both products are taken against the host ceiling before any
        // allocation, so a count that could not address its own payload is
        // rejected before a single byte is read.
        guard
            vertexCount <= Int.max / positionStride,
            triangleCount <= Int.max / triangleStride
        else {
            throw TriangleMeshByteDecodingError.countNotRepresentable
        }
        guard positionBytes.count == vertexCount * positionStride else {
            throw TriangleMeshByteDecodingError.positionByteCountMismatch
        }
        guard indexBytes.count == triangleCount * triangleStride else {
            throw TriangleMeshByteDecodingError.indexByteCountMismatch
        }

        var components = ContiguousArray<Double>()
        components.reserveCapacity(vertexCount * 3)
        for offset in stride(from: 0, to: positionBytes.count, by: 4) {
            components.append(
                Double(Float(bitPattern: word(positionBytes, at: offset)))
            )
        }

        var indices = ContiguousArray<UInt64>()
        indices.reserveCapacity(triangleCount * 3)
        for offset in stride(from: 0, to: indexBytes.count, by: 4) {
            indices.append(UInt64(word(indexBytes, at: offset)))
        }

        // Every geometric rule below belongs to the canonical value. The
        // decoder restates none of them, and two canonical cases —
        // `incompleteVertex` and `incompleteTriangle` — are unreachable
        // through this path, because an exact byte-count match is strictly
        // stronger than a multiple-of-three check.
        return try TriangleMesh(
            positions: try TriangleMeshPositionDomain(
                coordinateSpace: coordinateSpace,
                components: components
            ),
            topology: try TriangleMeshTopology(
                vertexCount: vertexCount,
                indices: indices
            ),
            vertexAttributes: []
        )
    }

    /// Assembles one little-endian 32-bit word.
    ///
    /// The byte order is load-bearing: `00 00 80 3F` is exactly `1.0`, and the
    /// same four bytes read the other way are `4.6006e-41`.
    private static func word(_ bytes: [UInt8], at offset: Int) -> UInt32 {
        UInt32(bytes[offset])
            | UInt32(bytes[offset + 1]) << 8
            | UInt32(bytes[offset + 2]) << 16
            | UInt32(bytes[offset + 3]) << 24
    }
}
