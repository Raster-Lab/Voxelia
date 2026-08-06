// SPDX-License-Identifier: MIT

import VoxeliaGeometry

/// Internal cancellation sites frozen by `ADR-0195` and `ALG-0032`.
///
/// `ADR-0195` decision 17 names one certification poll cadence and one volume
/// cadence. Certification is implemented as two ordered sub-traversals — edge
/// recording, then the reverse-partner scan — and the scan is `O(facetCount)`
/// work that must remain cancellable, so it carries its own checkpoint rather
/// than reusing already-consumed recording ordinals. The refinement is
/// internal, strictly more cancellable than the accepted text, and recorded in
/// the implementation's commit message and ledger bullet.
enum CPUTriangleMeshEnclosedVolumeCancellationCheckpoint: Sendable, Equatable {
    case admission
    case certification(UInt64)
    case closure(UInt64)
    case volume(UInt64)
    case final
}

typealias CPUTriangleMeshEnclosedVolumeCancellationProbe =
    @Sendable (CPUTriangleMeshEnclosedVolumeCancellationCheckpoint) -> Bool

/// Checked logical storage accounting for the directed-edge collection.
struct TriangleMeshEnclosedVolumeLogicalByteCounts: Sendable, Equatable {
    let directedEdgeCount: UInt64
    let additionalLogicalByteCount: UInt64
}

/// The exact `triangle-mesh-enclosed-volume/binary64-v1` CPU kernel.
///
/// This stateless internal implementation first certifies that the source
/// mesh is a closed, edge-manifold, consistently oriented surface, and only
/// then performs any arithmetic. Unit, identity and provenance publication
/// remain outside this numerical boundary.
enum TriangleMeshEnclosedVolumeReferenceKernel {
    private struct Vector3: Sendable {
        let x: Double
        let y: Double
        let z: Double
    }

    /// One ordered directed edge, the certification predicate's whole state.
    private struct DirectedEdge: Sendable, Hashable {
        let tail: UInt64
        let head: UInt64
    }

    /// Certifies the source surface and reduces it to its enclosed volume.
    ///
    /// - Returns: The non-negative volume and the exact certified facet count.
    static func measure(
        request: TriangleMeshEnclosedVolumeRequest,
        cancellation: CPUTriangleMeshEnclosedVolumeCancellationProbe,
        checksFinalCancellation: Bool = true
    ) throws -> (volume: Double, facetCount: UInt64) {
        if cancellation(.admission) {
            throw TriangleMeshEnclosedVolumeError.cancelled
        }
        guard
            request.limits.maximumVertexCount > 0,
            request.limits.maximumTriangleCount > 0,
            request.limits.maximumAdditionalLogicalByteCount > 0
        else {
            throw TriangleMeshEnclosedVolumeError.invalidLimits
        }
        guard
            request.sourceProvenance.subject
                == .object(request.sourceIdentity.objectID)
        else {
            throw TriangleMeshEnclosedVolumeError.invalidSource
        }

        let source = request.source
        guard
            let vertexCount = UInt64(exactly: source.positions.vertexCount),
            let triangleCount = UInt64(exactly: source.topology.triangleCount)
        else {
            throw TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        }
        guard
            vertexCount <= request.limits.maximumVertexCount,
            triangleCount <= request.limits.maximumTriangleCount
        else {
            throw TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        }
        let byteCounts = try checkedLogicalByteCounts(
            triangleCount: triangleCount,
            maximumAdditionalLogicalByteCount:
                request.limits.maximumAdditionalLogicalByteCount
        )
        guard Int(exactly: byteCounts.directedEdgeCount) != nil else {
            throw TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        }

        let indices = source.topology.indices
        try certify(
            indices: indices,
            triangleCount: source.topology.triangleCount,
            directedEdgeCount: Int(byteCounts.directedEdgeCount),
            cancellation: cancellation
        )

        let positions = source.positions.components
        var total = 0.0
        for triangleOrdinal in 0..<source.topology.triangleCount {
            let ordinal = UInt64(triangleOrdinal)
            if ordinal.isMultiple(of: 64), cancellation(.volume(ordinal)) {
                throw TriangleMeshEnclosedVolumeError.cancelled
            }
            let offset = triangleOrdinal * 3
            guard
                let first = Int(exactly: indices[offset]),
                let second = Int(exactly: indices[offset + 1]),
                let third = Int(exactly: indices[offset + 2])
            else {
                throw TriangleMeshEnclosedVolumeError.publicationFailed
            }
            let term = try facetSixVolume(
                first: position(at: first, in: positions),
                second: position(at: second, in: positions),
                third: position(at: third, in: positions)
            )
            total = try checkedAdd(total, term)
        }

        guard !(total < 0) else {
            throw TriangleMeshEnclosedVolumeError.invertedOrientation
        }
        let volume = canonicalPositiveZero(try checkedDivide(total, 6))

        if checksFinalCancellation, cancellation(.final) {
            throw TriangleMeshEnclosedVolumeError.cancelled
        }
        return (volume: volume, facetCount: triangleCount)
    }

    /// Proves closure, edge-manifoldness and orientation consistency.
    ///
    /// Vertex manifoldness is deliberately not required and self-intersection
    /// is deliberately not certified; `ADR-0195` records why for both.
    private static func certify(
        indices: ContiguousArray<UInt64>,
        triangleCount: Int,
        directedEdgeCount: Int,
        cancellation: CPUTriangleMeshEnclosedVolumeCancellationProbe
    ) throws {
        var edges = Set<DirectedEdge>()
        edges.reserveCapacity(directedEdgeCount)

        for triangleOrdinal in 0..<triangleCount {
            let ordinal = UInt64(triangleOrdinal)
            if ordinal.isMultiple(of: 64),
                cancellation(.certification(ordinal))
            {
                throw TriangleMeshEnclosedVolumeError.cancelled
            }
            let offset = triangleOrdinal * 3
            let first = indices[offset]
            let second = indices[offset + 1]
            let third = indices[offset + 2]
            guard first != second, second != third, third != first else {
                throw TriangleMeshEnclosedVolumeError.degenerateFacet
            }
            for edge in [
                DirectedEdge(tail: first, head: second),
                DirectedEdge(tail: second, head: third),
                DirectedEdge(tail: third, head: first),
            ] {
                guard edges.insert(edge).inserted else {
                    throw TriangleMeshEnclosedVolumeError
                        .nonManifoldOrientation
                }
            }
        }

        // The reverse-partner scan revisits the facets in topology order,
        // which is exactly the edges' ascending insertion order, so it needs
        // no second ordered collection and stays inside the frozen
        // `triangleCount * 3 * 16` payload.
        for triangleOrdinal in 0..<triangleCount {
            let ordinal = UInt64(triangleOrdinal)
            if ordinal.isMultiple(of: 64), cancellation(.closure(ordinal)) {
                throw TriangleMeshEnclosedVolumeError.cancelled
            }
            let offset = triangleOrdinal * 3
            let first = indices[offset]
            let second = indices[offset + 1]
            let third = indices[offset + 2]
            for edge in [
                DirectedEdge(tail: second, head: first),
                DirectedEdge(tail: third, head: second),
                DirectedEdge(tail: first, head: third),
            ] {
                guard edges.contains(edge) else {
                    throw TriangleMeshEnclosedVolumeError.openSurface
                }
            }
        }
    }

    /// Performs the exact checked `triangleCount * 3 * 16` admission.
    ///
    /// The helper is separate so the registered `UInt64` boundary can be
    /// tested without attempting an impractical allocation.
    static func checkedLogicalByteCounts(
        triangleCount: UInt64,
        maximumAdditionalLogicalByteCount: UInt64
    ) throws -> TriangleMeshEnclosedVolumeLogicalByteCounts {
        let edges = triangleCount.multipliedReportingOverflow(by: 3)
        guard !edges.overflow else {
            throw TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        }
        let bytes = edges.partialValue.multipliedReportingOverflow(by: 16)
        guard
            !bytes.overflow,
            bytes.partialValue <= maximumAdditionalLogicalByteCount
        else {
            throw TriangleMeshEnclosedVolumeError.resourceLimitExceeded
        }
        return TriangleMeshEnclosedVolumeLogicalByteCounts(
            directedEdgeCount: edges.partialValue,
            additionalLogicalByteCount: bytes.partialValue
        )
    }

    private static func position(
        at vertex: Int,
        in components: ContiguousArray<Double>
    ) -> Vector3 {
        let offset = vertex * 3
        return Vector3(
            x: components[offset],
            y: components[offset + 1],
            z: components[offset + 2]
        )
    }

    /// The origin-anchored scalar triple product `p0 . (p1 x p2)`.
    ///
    /// This is deliberately NOT the edge-vector cross product frozen by
    /// `ALG-0030` and reused by `ALG-0031`: that one is an origin-independent
    /// doubled area, this one an origin-dependent signed determinant. The two
    /// must never be interchanged.
    private static func facetSixVolume(
        first: Vector3,
        second: Vector3,
        third: Vector3
    ) throws -> Double {
        let crossXFirst = try checkedMultiply(second.y, third.z)
        let crossXSecond = try checkedMultiply(second.z, third.y)
        let crossX = try checkedSubtract(crossXFirst, crossXSecond)
        let crossYFirst = try checkedMultiply(second.z, third.x)
        let crossYSecond = try checkedMultiply(second.x, third.z)
        let crossY = try checkedSubtract(crossYFirst, crossYSecond)
        let crossZFirst = try checkedMultiply(second.x, third.y)
        let crossZSecond = try checkedMultiply(second.y, third.x)
        let crossZ = try checkedSubtract(crossZFirst, crossZSecond)

        let term0 = try checkedMultiply(first.x, crossX)
        let term1 = try checkedMultiply(first.y, crossY)
        let term2 = try checkedMultiply(first.z, crossZ)
        let firstSum = try checkedAdd(term0, term1)
        return try checkedAdd(firstSum, term2)
    }

    private static func canonicalPositiveZero(_ value: Double) -> Double {
        value == 0 ? 0 : value
    }

    // Keeping each primitive out of line prevents contraction and
    // reassociation across the operation boundaries frozen by ALG-0032.
    @inline(never)
    private static func checkedSubtract(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs - rhs
        guard value.isFinite else {
            throw TriangleMeshEnclosedVolumeError.volumeNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedMultiply(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs * rhs
        guard value.isFinite else {
            throw TriangleMeshEnclosedVolumeError.volumeNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedAdd(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs + rhs
        guard value.isFinite else {
            throw TriangleMeshEnclosedVolumeError.volumeNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedDivide(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs / rhs
        guard value.isFinite else {
            throw TriangleMeshEnclosedVolumeError.volumeNotRepresentable
        }
        return value
    }
}
