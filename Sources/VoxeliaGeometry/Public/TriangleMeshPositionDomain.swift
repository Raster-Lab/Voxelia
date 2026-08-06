// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised while validating authoritative triangle-mesh positions.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// coordinates or collection sizes.
public enum TriangleMeshPositionDomainError: Error, Sendable, Equatable {
    /// The flattened component sequence did not contain complete `(x, y, z)`
    /// triples.
    case incompleteVertex

    /// At least one position component was NaN or infinity.
    case nonFinitePosition
}

/// Immutable authoritative three-dimensional triangle-mesh positions.
///
/// ``components`` stores finite binary64 values in flattened `(x, y, z)`
/// order. One exact Spatial-owned `CoordinateSpaceDescriptor` applies to
/// every vertex. Construction preserves every admitted bit pattern, including
/// the sign of zero; it performs no transform, conversion, quantisation or
/// normalization.
///
/// The value is safe to transfer across concurrency domains because both
/// stored properties are immutable values. It deliberately has no `Hashable`
/// or `Codable` conformance: canonical mesh bytes, signed-zero identity,
/// persistence and content identity remain separate governed contracts.
public struct TriangleMeshPositionDomain: Sendable {
    /// The validated coordinate space applying to every position.
    public let coordinateSpace: CoordinateSpaceDescriptor

    /// Finite binary64 components in flattened `(x, y, z)` order.
    public let components: ContiguousArray<Double>

    /// The exact number of complete three-dimensional vertices.
    public var vertexCount: Int { components.count / 3 }

    /// Creates and completely validates an immutable position domain.
    ///
    /// Validation order is fixed: an incomplete triple rejects before the
    /// components are scanned for non-finite values. Empty positions are
    /// valid. The supplied array is retained under Swift value semantics and
    /// is not deliberately copied or rewritten.
    ///
    /// - Throws: ``TriangleMeshPositionDomainError/incompleteVertex`` or
    ///   ``TriangleMeshPositionDomainError/nonFinitePosition`` according to
    ///   that precedence.
    public init(
        coordinateSpace: CoordinateSpaceDescriptor,
        components: ContiguousArray<Double>
    ) throws {
        guard components.count.isMultiple(of: 3) else {
            throw TriangleMeshPositionDomainError.incompleteVertex
        }
        for component in components {
            guard component.isFinite else {
                throw TriangleMeshPositionDomainError.nonFinitePosition
            }
        }

        self.coordinateSpace = coordinateSpace
        self.components = components
    }
}
