// SPDX-License-Identifier: MIT

/// An error raised while validating logical triangle-mesh topology.
///
/// Cases deliberately carry no payload so diagnostics never disclose topology
/// sizes or index values.
public enum TriangleMeshTopologyError: Error, Sendable, Equatable {
    /// The declared vertex domain was negative.
    case negativeVertexCount

    /// The flattened index sequence did not contain complete triples.
    case incompleteTriangle

    /// At least one index did not belong to the declared vertex domain.
    case indexOutOfBounds
}

/// Immutable, representation-neutral independent-triangle topology.
///
/// Every consecutive triple in ``indices`` is one triangle. Indices are
/// logical `UInt64` ordinals: selecting a narrower physical ``IndexType`` is a
/// later storage decision and never changes this value's identity. Construction
/// validates the complete sequence before publication. Repeated indices,
/// degenerate triangles, duplicate triangles and winding are preserved exactly;
/// their geometric interpretation belongs to the operation that consumes the
/// topology.
///
/// The value has no stable wire format. Canonical mesh bytes, content identity
/// and persistence remain separately governed contracts.
public struct TriangleMeshTopology: Sendable, Hashable {
    /// The nonnegative size of the vertex domain referenced by ``indices``.
    public let vertexCount: Int

    /// Flattened independent-triangle indices in exact input order.
    public let indices: ContiguousArray<UInt64>

    /// The number of complete independent triangles.
    public var triangleCount: Int { indices.count / 3 }

    /// Creates and completely validates an immutable topology value.
    ///
    /// Validation order is fixed: a negative `vertexCount` rejects first, an
    /// incomplete index triple rejects second, then bounds are checked in input
    /// order. Zero vertices with zero indices is a valid empty topology.
    ///
    /// - Throws: ``TriangleMeshTopologyError/negativeVertexCount``,
    ///   ``TriangleMeshTopologyError/incompleteTriangle`` or
    ///   ``TriangleMeshTopologyError/indexOutOfBounds`` according to that
    ///   precedence.
    public init(vertexCount: Int, indices: ContiguousArray<UInt64>) throws {
        guard vertexCount >= 0 else {
            throw TriangleMeshTopologyError.negativeVertexCount
        }
        guard indices.count.isMultiple(of: 3) else {
            throw TriangleMeshTopologyError.incompleteTriangle
        }

        let upperBound = UInt64(vertexCount)
        for index in indices {
            guard index < upperBound else {
                throw TriangleMeshTopologyError.indexOutOfBounds
            }
        }

        self.vertexCount = vertexCount
        self.indices = indices
    }
}
