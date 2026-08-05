// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised while binding canonical triangle-mesh domains.
///
/// Cases deliberately carry no payload so diagnostics never disclose mesh
/// sizes, attribute semantics or coordinate-space details.
public enum TriangleMeshError: Error, Sendable, Equatable {
    /// The topology and authoritative position domains declared different
    /// vertex counts.
    case vertexCountMismatch

    /// At least one vertex attribute declared a different element count.
    case attributeCountMismatch

    /// At least two vertex attributes used the same exact semantic.
    case duplicateAttributeSemantic
}

/// An immutable coordinate-bearing independent-triangle mesh payload.
///
/// Positions, topology and non-position vertex attributes remain independent
/// owned domains. Construction binds all three to the position vertex count
/// before publication and preserves their exact order and contents. The
/// position domain is mandatory; generic attributes cannot duplicate it.
///
/// The value is safe to transfer across concurrency domains because all stored
/// state is immutable and `Sendable`. It is independent of Metal, RealityKit,
/// Model I/O and physical buffer residency. It deliberately has no stable
/// `Hashable` or `Codable` identity and is not the future metadata,
/// provenance and content-identity publication aggregate.
public struct TriangleMesh: Sendable {
    /// Authoritative finite three-dimensional positions and their space.
    public let positions: TriangleMeshPositionDomain

    /// Complete in-bounds independent-triangle topology.
    public let topology: TriangleMeshTopology

    /// Ordered non-position attributes bound to the vertex domain.
    public let vertexAttributes: ContiguousArray<TriangleMeshVertexAttribute>

    /// The exact coordinate descriptor declared by ``positions``.
    public var coordinateSpace: CoordinateSpaceDescriptor {
        positions.coordinateSpace
    }

    /// Creates and completely validates an immutable triangle mesh.
    ///
    /// Validation order is fixed: topology/position vertex-count mismatch
    /// rejects first, attribute element counts are checked in input order
    /// second, and exact duplicate semantics are checked in input order last.
    /// Empty positions, topology and attributes form a valid empty mesh.
    /// No domain is transformed, sorted, deduplicated or otherwise rewritten.
    ///
    /// - Throws: The corresponding ``TriangleMeshError`` case according to
    ///   the fixed validation precedence.
    public init(
        positions: TriangleMeshPositionDomain,
        topology: TriangleMeshTopology,
        vertexAttributes: ContiguousArray<TriangleMeshVertexAttribute>
    ) throws {
        guard topology.vertexCount == positions.vertexCount else {
            throw TriangleMeshError.vertexCountMismatch
        }
        for attribute in vertexAttributes {
            guard attribute.descriptor.elementCount == positions.vertexCount else {
                throw TriangleMeshError.attributeCountMismatch
            }
        }

        var seenSemantics = Set<GeometryAttributeSemantic>()
        seenSemantics.reserveCapacity(vertexAttributes.count)
        for attribute in vertexAttributes {
            guard seenSemantics.insert(attribute.descriptor.semantic).inserted else {
                throw TriangleMeshError.duplicateAttributeSemantic
            }
        }

        self.positions = positions
        self.topology = topology
        self.vertexAttributes = vertexAttributes
    }
}
