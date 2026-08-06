// SPDX-License-Identifier: MIT

import VoxeliaExecution
import VoxeliaGeometry

/// Internal cancellation sites frozen by `ADR-0194` and `ALG-0031`.
///
/// There is deliberately no attribute checkpoint: the measurement never reads
/// a vertex attribute, and no vertex checkpoint: the reduction visits facets,
/// not vertices.
enum CPUTriangleMeshTotalFacetAreaCancellationCheckpoint: Sendable, Equatable {
    case admission
    case triangle(UInt64)
    case final
}

typealias CPUTriangleMeshTotalFacetAreaCancellationProbe =
    @Sendable (CPUTriangleMeshTotalFacetAreaCancellationCheckpoint) -> Bool

/// The exact admitted source counts checked against the caller's ceilings.
struct TriangleMeshTotalFacetAreaSourceCounts: Sendable, Equatable {
    let vertexCount: UInt64
    let triangleCount: UInt64
}

/// The exact `triangle-mesh-total-facet-area/binary64-v1` CPU kernel.
///
/// This stateless internal implementation reads only the source positions and
/// topology, performs only serial ordered binary64 operations, allocates no
/// per-vertex or per-facet buffer, and returns one unsigned total. Unit,
/// identity and provenance publication remain outside this numerical boundary.
enum TriangleMeshTotalFacetAreaReferenceKernel {
    private struct Vector3: Sendable {
        let x: Double
        let y: Double
        let z: Double
    }

    /// Reduces one admitted mesh to its total facet area.
    ///
    /// - Returns: The accumulated total and the exact facet count reduced.
    /// The observer receives one observation at each accepted checkpoint and
    /// one final observation, per `VOXELIA-ALG-0046`. It returns `Void`, so it
    /// cannot influence this reduction: the total is bit-identical whether or
    /// not one is attached.
    static func measure(
        request: TriangleMeshTotalFacetAreaRequest,
        cancellation: CPUTriangleMeshTotalFacetAreaCancellationProbe,
        progress: ProgressObserver,
        checksFinalCancellation: Bool = true
    ) throws -> (total: Double, facetCount: UInt64) {
        if cancellation(.admission) {
            throw TriangleMeshTotalFacetAreaError.cancelled
        }
        guard
            request.limits.maximumVertexCount > 0,
            request.limits.maximumTriangleCount > 0
        else {
            throw TriangleMeshTotalFacetAreaError.invalidLimits
        }
        guard
            request.sourceProvenance.subject
                == .object(request.sourceIdentity.objectID)
        else {
            throw TriangleMeshTotalFacetAreaError.invalidSource
        }

        let source = request.source
        let counts = try checkedSourceCounts(
            vertexCount: source.positions.vertexCount,
            triangleCount: source.topology.triangleCount,
            limits: request.limits
        )

        let indices = source.topology.indices
        let positions = source.positions.components
        var total = 0.0

        let triangleCount = source.topology.triangleCount
        for triangleOrdinal in 0..<triangleCount {
            let ordinal = UInt64(triangleOrdinal)
            if ordinal.isMultiple(of: 64) {
                if cancellation(.triangle(ordinal)) {
                    throw TriangleMeshTotalFacetAreaError.cancelled
                }
                // The accepted checkpoint cadence, reused verbatim rather than
                // given a second, progress-specific rhythm.
                progress(
                    ProgressObservation(
                        completed: triangleOrdinal,
                        total: triangleCount
                    )
                )
            }

            let indexOffset = triangleOrdinal * 3
            guard
                let first = Int(exactly: indices[indexOffset]),
                let second = Int(exactly: indices[indexOffset + 1]),
                let third = Int(exactly: indices[indexOffset + 2])
            else {
                throw TriangleMeshTotalFacetAreaError.publicationFailed
            }
            let area = try facetArea(
                first: position(at: first, in: positions),
                second: position(at: second, in: positions),
                third: position(at: third, in: positions)
            )
            total = try checkedAdd(total, area)
        }

        if checksFinalCancellation, cancellation(.final) {
            throw TriangleMeshTotalFacetAreaError.cancelled
        }
        // Emitted unconditionally, so a consumer never infers completion and a
        // zero-facet mesh still reports exactly once.
        progress(
            ProgressObservation(completed: triangleCount, total: triangleCount)
        )
        return (total: total, facetCount: counts.triangleCount)
    }

    /// Performs the exact host-domain and ceiling admission.
    ///
    /// The operation owns no payload buffer, so there is no checked byte
    /// product here: an admitted topology already owns `triangleCount * 3`
    /// host indices, which `ALG-0031` records as the traversal boundary.
    static func checkedSourceCounts(
        vertexCount: Int,
        triangleCount: Int,
        limits: TriangleMeshTotalFacetAreaLimits
    ) throws -> TriangleMeshTotalFacetAreaSourceCounts {
        guard
            let vertices = UInt64(exactly: vertexCount),
            let triangles = UInt64(exactly: triangleCount)
        else {
            throw TriangleMeshTotalFacetAreaError.resourceLimitExceeded
        }
        guard
            vertices <= limits.maximumVertexCount,
            triangles <= limits.maximumTriangleCount
        else {
            throw TriangleMeshTotalFacetAreaError.resourceLimitExceeded
        }
        return TriangleMeshTotalFacetAreaSourceCounts(
            vertexCount: vertices,
            triangleCount: triangles
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

    /// One unsigned facet area from the ordered doubled-area vector.
    ///
    /// An exactly zero doubled-area vector yields positive zero and performs
    /// no further arithmetic; that is an admitted contribution, not a failure.
    private static func facetArea(
        first: Vector3,
        second: Vector3,
        third: Vector3
    ) throws -> Double {
        let face = try faceVector(
            first: first,
            second: second,
            third: third
        )
        let scale = max(max(abs(face.x), abs(face.y)), abs(face.z))
        guard scale != 0 else {
            return 0
        }

        let scaledX = try checkedDivide(face.x, scale)
        let scaledY = try checkedDivide(face.y, scale)
        let scaledZ = try checkedDivide(face.z, scale)
        let squaredX = try checkedMultiply(scaledX, scaledX)
        let squaredY = try checkedMultiply(scaledY, scaledY)
        let squaredZ = try checkedMultiply(scaledZ, scaledZ)
        let firstSum = try checkedAdd(squaredX, squaredY)
        let squaredSum = try checkedAdd(firstSum, squaredZ)
        let scaledNorm = try checkedSquareRoot(squaredSum)
        let doubledArea = try checkedMultiply(scale, scaledNorm)
        return try checkedMultiply(doubledArea, 0.5)
    }

    /// The exact ordered doubled-area vector shared with `ALG-0030`.
    private static func faceVector(
        first: Vector3,
        second: Vector3,
        third: Vector3
    ) throws -> Vector3 {
        let edge10X = try checkedSubtract(second.x, first.x)
        let edge10Y = try checkedSubtract(second.y, first.y)
        let edge10Z = try checkedSubtract(second.z, first.z)
        let edge10 = Vector3(
            x: edge10X,
            y: edge10Y,
            z: edge10Z
        )
        let edge20X = try checkedSubtract(third.x, first.x)
        let edge20Y = try checkedSubtract(third.y, first.y)
        let edge20Z = try checkedSubtract(third.z, first.z)
        let edge20 = Vector3(
            x: edge20X,
            y: edge20Y,
            z: edge20Z
        )

        let xFirst = try checkedMultiply(edge10.y, edge20.z)
        let xSecond = try checkedMultiply(edge10.z, edge20.y)
        let x = try checkedSubtract(xFirst, xSecond)
        let yFirst = try checkedMultiply(edge10.z, edge20.x)
        let ySecond = try checkedMultiply(edge10.x, edge20.z)
        let y = try checkedSubtract(yFirst, ySecond)
        let zFirst = try checkedMultiply(edge10.x, edge20.y)
        let zSecond = try checkedMultiply(edge10.y, edge20.x)
        let z = try checkedSubtract(zFirst, zSecond)
        return Vector3(
            x: x,
            y: y,
            z: z
        )
    }

    // Keeping each primitive out of line prevents contraction and
    // reassociation across the operation boundaries frozen by ALG-0031.
    @inline(never)
    private static func checkedSubtract(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs - rhs
        guard value.isFinite else {
            throw TriangleMeshTotalFacetAreaError.areaNotRepresentable
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
            throw TriangleMeshTotalFacetAreaError.areaNotRepresentable
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
            throw TriangleMeshTotalFacetAreaError.areaNotRepresentable
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
            throw TriangleMeshTotalFacetAreaError.areaNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedSquareRoot(_ value: Double) throws -> Double {
        let result = value.squareRoot()
        guard result.isFinite else {
            throw TriangleMeshTotalFacetAreaError.areaNotRepresentable
        }
        return result
    }
}
