// SPDX-License-Identifier: MIT

import VoxeliaExecution
import VoxeliaGeometry

/// The exact `freudenthal-surface-extraction/binary64-v1` CPU kernel.
enum ScalarSurfaceReferenceKernel {
    private struct GridPoint: Sendable {
        let x: Int
        let y: Int
        let z: Int

        func component(_ axis: Int) -> Int {
            switch axis {
            case 0: x
            case 1: y
            default: z
            }
        }
    }

    private struct Position: Sendable {
        let x: Double
        let y: Double
        let z: Double

        func component(_ axis: Int) -> Double {
            switch axis {
            case 0: x
            case 1: y
            default: z
            }
        }
    }

    private enum VertexKey: Sendable, Hashable {
        case sample(UInt64)
        case edge(UInt64, UInt64)
    }

    private struct VertexCandidate: Sendable {
        let key: VertexKey
        let world: Position
    }

    private static let cornerOffsets = [
        GridPoint(x: 0, y: 0, z: 0),
        GridPoint(x: 1, y: 0, z: 0),
        GridPoint(x: 0, y: 1, z: 0),
        GridPoint(x: 1, y: 1, z: 0),
        GridPoint(x: 0, y: 0, z: 1),
        GridPoint(x: 1, y: 0, z: 1),
        GridPoint(x: 0, y: 1, z: 1),
        GridPoint(x: 1, y: 1, z: 1),
    ]

    private static let tetrahedra = [
        [0, 1, 3, 7],
        [0, 5, 1, 7],
        [0, 3, 2, 7],
        [0, 2, 6, 7],
        [0, 4, 5, 7],
        [0, 6, 4, 7],
    ]

    private static let tetrahedronEdges = [
        [0, 1],
        [1, 2],
        [2, 0],
        [0, 3],
        [1, 3],
        [2, 3],
    ]

    private static let triangleTable = [
        [],
        [0, 2, 3],
        [0, 4, 1],
        [1, 2, 4, 2, 3, 4],
        [1, 5, 2],
        [0, 5, 3, 0, 1, 5],
        [0, 5, 2, 0, 4, 5],
        [5, 3, 4],
        [3, 5, 4],
        [4, 0, 5, 5, 0, 2],
        [1, 0, 5, 5, 0, 3],
        [5, 1, 2],
        [3, 2, 4, 2, 1, 4],
        [4, 0, 1],
        [2, 0, 3],
        [],
    ]

    static func extract(
        request: ScalarSurfaceExtractionRequest,
        source: ScalarSurfaceSourceAdapter,
        cancellation: CPUScalarSurfaceCancellationProbe,
        progress: ProgressObserver,
        progressBase: Int,
        totalWork: Int,
        checksFinalCancellation: Bool = true
    ) throws -> TriangleMesh {
        let admission = source.admission
        let extents = admission.extents
        var positionComponents = ContiguousArray<Double>()
        var triangleIndices = ContiguousArray<UInt64>()
        var vertexIndices: [VertexKey: UInt64] = [:]
        var triangleCount: UInt64 = 0

        if admission.cellCount > 0 {
            var cellOrdinal: UInt64 = 0
            for z in 0..<(extents[2] - 1) {
                for y in 0..<(extents[1] - 1) {
                    for x in 0..<(extents[0] - 1) {
                        if cellOrdinal.isMultiple(of: 64) {
                            if cancellation(.cell(cellOrdinal)) {
                                throw ScalarSurfaceExtractionError.cancelled
                            }
                            progress(
                                ProgressObservation(
                                    completed: progressBase
                                        + Int(cellOrdinal),
                                    total: totalWork
                                )
                            )
                        }
                        let cell = GridPoint(x: x, y: y, z: z)
                        let corners = Self.cornerOffsets.map {
                            GridPoint(
                                x: cell.x + $0.x,
                                y: cell.y + $0.y,
                                z: cell.z + $0.z
                            )
                        }
                        let ordinals = try corners.map {
                            try ordinal(of: $0, extents: extents)
                        }
                        let samples = try ordinals.map {
                            let value = try source.authoritativeValue(at: $0)
                            guard value.isFinite else {
                                throw ScalarSurfaceExtractionError.nonFiniteSample
                            }
                            return value
                        }

                        for tetrahedron in Self.tetrahedra {
                            var caseNumber = 0
                            for localVertex in 0..<4 {
                                let corner = tetrahedron[localVertex]
                                if samples[corner] >= request.isovalue {
                                    caseNumber |= 1 << localVertex
                                }
                            }
                            let edgeSequence = Self.triangleTable[caseNumber]
                            var edgeOffset = 0
                            while edgeOffset < edgeSequence.count {
                                let first = try candidate(
                                    edgeID: edgeSequence[edgeOffset],
                                    tetrahedron: tetrahedron,
                                    corners: corners,
                                    ordinals: ordinals,
                                    samples: samples,
                                    isovalue: request.isovalue,
                                    admission: admission
                                )
                                let second = try candidate(
                                    edgeID: edgeSequence[edgeOffset + 1],
                                    tetrahedron: tetrahedron,
                                    corners: corners,
                                    ordinals: ordinals,
                                    samples: samples,
                                    isovalue: request.isovalue,
                                    admission: admission
                                )
                                let third = try candidate(
                                    edgeID: edgeSequence[edgeOffset + 2],
                                    tetrahedron: tetrahedron,
                                    corners: corners,
                                    ordinals: ordinals,
                                    samples: samples,
                                    isovalue: request.isovalue,
                                    admission: admission
                                )
                                edgeOffset += 3

                                guard
                                    first.key != second.key,
                                    first.key != third.key,
                                    second.key != third.key
                                else {
                                    continue
                                }
                                let candidates = [first, second, third]
                                try checkResourceLimits(
                                    candidates: candidates,
                                    vertexIndices: vertexIndices,
                                    positionComponentCount: positionComponents.count,
                                    triangleCount: triangleCount,
                                    triangleIndexCount: triangleIndices.count,
                                    limits: request.limits
                                )

                                var resolved = ContiguousArray<UInt64>()
                                for candidate in candidates {
                                    if let existing = vertexIndices[candidate.key] {
                                        resolved.append(existing)
                                        continue
                                    }
                                    let index = UInt64(vertexIndices.count)
                                    vertexIndices[candidate.key] = index
                                    positionComponents.append(candidate.world.x)
                                    positionComponents.append(candidate.world.y)
                                    positionComponents.append(candidate.world.z)
                                    resolved.append(index)
                                }
                                if admission.reversesWinding {
                                    resolved.swapAt(1, 2)
                                }
                                triangleIndices.append(contentsOf: resolved)
                                triangleCount += 1
                            }
                        }
                        cellOrdinal += 1
                    }
                }
            }
        }

        let mesh: TriangleMesh
        do {
            guard
                case .affine(let geometry) =
                    request.source.descriptor.spatialGeometry
            else {
                throw ScalarSurfaceExtractionError.publicationFailed
            }
            let positions = try TriangleMeshPositionDomain(
                coordinateSpace: geometry.coordinateSpace,
                components: positionComponents
            )
            let topology = try TriangleMeshTopology(
                vertexCount: positions.vertexCount,
                indices: triangleIndices
            )
            mesh = try TriangleMesh(
                positions: positions,
                topology: topology,
                vertexAttributes: []
            )
        } catch let error as ScalarSurfaceExtractionError {
            throw error
        } catch {
            throw ScalarSurfaceExtractionError.publicationFailed
        }
        progress(
            ProgressObservation(completed: totalWork, total: totalWork)
        )
        if checksFinalCancellation, cancellation(.final) {
            throw ScalarSurfaceExtractionError.cancelled
        }
        return mesh
    }

    private static func ordinal(
        of point: GridPoint,
        extents: ContiguousArray<Int>
    ) throws -> Int {
        let zStride = extents[0].multipliedReportingOverflow(by: extents[1])
        let zOffset = zStride.partialValue.multipliedReportingOverflow(by: point.z)
        let yOffset = extents[0].multipliedReportingOverflow(by: point.y)
        let partial = point.x.addingReportingOverflow(yOffset.partialValue)
        let total = partial.partialValue.addingReportingOverflow(zOffset.partialValue)
        guard
            !zStride.overflow,
            !zOffset.overflow,
            !yOffset.overflow,
            !partial.overflow,
            !total.overflow
        else {
            throw ScalarSurfaceExtractionError.resourceLimitExceeded
        }
        return total.partialValue
    }

    private static func candidate(
        edgeID: Int,
        tetrahedron: [Int],
        corners: [GridPoint],
        ordinals: [Int],
        samples: [Double],
        isovalue: Double,
        admission: ScalarSurfaceSourceAdmission
    ) throws -> VertexCandidate {
        let edge = Self.tetrahedronEdges[edgeID]
        var firstCorner = tetrahedron[edge[0]]
        var secondCorner = tetrahedron[edge[1]]
        if ordinals[secondCorner] < ordinals[firstCorner] {
            swap(&firstCorner, &secondCorner)
        }

        let firstOrdinal = ordinals[firstCorner]
        let secondOrdinal = ordinals[secondCorner]
        let firstSample = samples[firstCorner]
        let secondSample = samples[secondCorner]
        let firstPoint = corners[firstCorner]
        let secondPoint = corners[secondCorner]
        let imagePosition: Position
        let key: VertexKey
        if firstSample == isovalue {
            key = .sample(UInt64(firstOrdinal))
            imagePosition = Position(
                x: Double(firstPoint.x),
                y: Double(firstPoint.y),
                z: Double(firstPoint.z)
            )
        } else if secondSample == isovalue {
            key = .sample(UInt64(secondOrdinal))
            imagePosition = Position(
                x: Double(secondPoint.x),
                y: Double(secondPoint.y),
                z: Double(secondPoint.z)
            )
        } else {
            let numerator = isovalue - firstSample
            let denominator = secondSample - firstSample
            let t = numerator / denominator
            guard
                numerator.isFinite,
                denominator.isFinite,
                t.isFinite,
                t > 0,
                t < 1
            else {
                throw ScalarSurfaceExtractionError.interpolationNotRepresentable
            }
            let x = try interpolate(firstPoint.x, secondPoint.x, t: t)
            let y = try interpolate(firstPoint.y, secondPoint.y, t: t)
            let z = try interpolate(firstPoint.z, secondPoint.z, t: t)
            imagePosition = Position(x: x, y: y, z: z)
            key = .edge(UInt64(firstOrdinal), UInt64(secondOrdinal))
        }

        return VertexCandidate(
            key: key,
            world: try worldPosition(
                imagePosition,
                admission: admission
            )
        )
    }

    private static func interpolate(
        _ first: Int,
        _ second: Int,
        t: Double
    ) throws -> Double {
        let base = Double(first)
        let delta = Double(second - first)
        let product = t * delta
        let result = base + product
        guard product.isFinite, result.isFinite else {
            throw ScalarSurfaceExtractionError.interpolationNotRepresentable
        }
        return result
    }

    private static func worldPosition(
        _ image: Position,
        admission: ScalarSurfaceSourceAdmission
    ) throws -> Position {
        let spatial = Position(
            x: image.component(admission.spatialImageAxes[0]),
            y: image.component(admission.spatialImageAxes[1]),
            z: image.component(admission.spatialImageAxes[2])
        )
        func component(row: Int) throws -> Double {
            let offset = row * 4
            let first = admission.matrixElements[offset] * spatial.x
            let second = admission.matrixElements[offset + 1] * spatial.y
            let third = admission.matrixElements[offset + 2] * spatial.z
            let firstSum = first + second
            let secondSum = firstSum + third
            let result = secondSum + admission.matrixElements[offset + 3]
            guard
                first.isFinite,
                second.isFinite,
                third.isFinite,
                firstSum.isFinite,
                secondSum.isFinite,
                result.isFinite
            else {
                throw ScalarSurfaceExtractionError.positionNotRepresentable
            }
            return result
        }
        return try Position(
            x: component(row: 0),
            y: component(row: 1),
            z: component(row: 2)
        )
    }

    private static func checkResourceLimits(
        candidates: [VertexCandidate],
        vertexIndices: [VertexKey: UInt64],
        positionComponentCount: Int,
        triangleCount: UInt64,
        triangleIndexCount: Int,
        limits: ScalarSurfaceExtractionLimits
    ) throws {
        let nextTriangleCount = triangleCount.addingReportingOverflow(1)
        guard
            !nextTriangleCount.overflow,
            nextTriangleCount.partialValue <= limits.maximumTriangleCount,
            triangleIndexCount <= Int.max - 3
        else {
            throw ScalarSurfaceExtractionError.resourceLimitExceeded
        }

        var newVertexCount: UInt64 = 0
        for candidate in candidates where vertexIndices[candidate.key] == nil {
            newVertexCount += 1
        }
        let currentVertexCount = UInt64(vertexIndices.count)
        let nextVertexCount = currentVertexCount.addingReportingOverflow(
            newVertexCount
        )
        let additionalComponents = Int(newVertexCount) * 3
        guard
            !nextVertexCount.overflow,
            nextVertexCount.partialValue <= limits.maximumVertexCount,
            nextVertexCount.partialValue <= UInt64(Int.max),
            positionComponentCount <= Int.max - additionalComponents
        else {
            throw ScalarSurfaceExtractionError.resourceLimitExceeded
        }
    }
}
