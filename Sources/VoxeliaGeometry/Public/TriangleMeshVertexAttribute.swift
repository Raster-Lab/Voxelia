// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while validating an owned triangle-mesh vertex attribute.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// attribute semantics, element counts or byte contents.
public enum TriangleMeshVertexAttributeError: Error, Sendable, Equatable {
    /// The generic attribute attempted to duplicate the authoritative position
    /// domain.
    case positionSemanticReserved

    /// The descriptor left the component arrangement to external storage.
    case undefinedComponentLayout

    /// The descriptor's element, component and scalar-byte product exceeded
    /// the host `Int` domain.
    case byteCountOverflow

    /// The supplied byte count did not equal the descriptor's exact required
    /// byte count.
    case byteCountMismatch
}

/// One immutable owned non-position vertex attribute.
///
/// ``bytes`` contain exactly
/// `descriptor.elementCount * descriptor.components.count *
/// descriptor.scalarFormat.type.byteCount` bytes. For an interleaved
/// component layout, bytes are element-major then component-major. For a
/// planar layout, bytes are component-major then element-major. Each scalar
/// uses the descriptor's declared byte order. Valid-bit metadata and supplied
/// bytes are preserved exactly; this value performs no scalar conversion or
/// missing-value interpretation.
///
/// The value is safe to transfer across concurrency domains because it owns
/// immutable value storage. It is neither `Hashable` nor `Codable`: these bytes
/// are an in-memory logical payload, not a stable geometry wire or content
/// projection.
public struct TriangleMeshVertexAttribute: Sendable {
    /// The validated semantic, scalar, component and element description.
    public let descriptor: GeometryAttributeDescriptor

    /// Exact scalar-container bytes in the descriptor's defined layout.
    public let bytes: ContiguousArray<UInt8>

    /// Creates and completely validates an owned vertex attribute.
    ///
    /// Validation order is fixed: the reserved position semantic rejects
    /// first, an undefined component layout second, arithmetic overflow third,
    /// and an ordinary exact byte-count mismatch last. Zero elements require
    /// zero bytes. The supplied bytes are retained under Swift value semantics
    /// without conversion or deliberate duplication.
    ///
    /// - Throws: The corresponding ``TriangleMeshVertexAttributeError`` case
    ///   according to the fixed validation precedence.
    public init(
        descriptor: GeometryAttributeDescriptor,
        bytes: ContiguousArray<UInt8>
    ) throws {
        guard descriptor.semantic != .position else {
            throw TriangleMeshVertexAttributeError.positionSemanticReserved
        }
        guard descriptor.components.layout != .storageDefined else {
            throw TriangleMeshVertexAttributeError.undefinedComponentLayout
        }

        let (scalarCount, scalarCountOverflow) =
            descriptor.elementCount.multipliedReportingOverflow(
                by: descriptor.components.count
            )
        guard !scalarCountOverflow else {
            throw TriangleMeshVertexAttributeError.byteCountOverflow
        }
        let (requiredByteCount, byteCountOverflow) =
            scalarCount.multipliedReportingOverflow(
                by: descriptor.scalarFormat.type.byteCount
            )
        guard !byteCountOverflow else {
            throw TriangleMeshVertexAttributeError.byteCountOverflow
        }
        guard bytes.count == requiredByteCount else {
            throw TriangleMeshVertexAttributeError.byteCountMismatch
        }

        self.descriptor = descriptor
        self.bytes = bytes
    }
}
