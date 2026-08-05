// SPDX-License-Identifier: MIT

import VoxeliaGeometry

/// The exact `freudenthal-label-set-surface/binary64-v1` CPU kernel.
enum LabelledSurfaceReferenceKernel {
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

    private struct VertexKey: Sendable, Hashable {
        let firstOrdinal: UInt64
        let secondOrdinal: UInt64
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
        request: LabelledSurfaceExtractionRequest,
        source: LabelledSurfaceSourceAdapter,
        cancellation: CPULabelledSurfaceCancellationProbe,
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
                        if cellOrdinal.isMultiple(of: 64),
                            cancellation(.cell(cellOrdinal))
                        {
                            throw LabelledSurfaceExtractionError.cancelled
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
                        let selected = try ordinals.map {
                            try source.isSelected(at: $0)
                        }

                        for tetrahedron in Self.tetrahedra {
                            var caseNumber = 0
                            for localVertex in 0..<4 {
                                if selected[tetrahedron[localVertex]] {
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
                                    selected: selected,
                                    admission: admission
                                )
                                let second = try candidate(
                                    edgeID: edgeSequence[edgeOffset + 1],
                                    tetrahedron: tetrahedron,
                                    corners: corners,
                                    ordinals: ordinals,
                                    selected: selected,
                                    admission: admission
                                )
                                let third = try candidate(
                                    edgeID: edgeSequence[edgeOffset + 2],
                                    tetrahedron: tetrahedron,
                                    corners: corners,
                                    ordinals: ordinals,
                                    selected: selected,
                                    admission: admission
                                )
                                edgeOffset += 3

                                guard
                                    first.key != second.key,
                                    first.key != third.key,
                                    second.key != third.key
                                else {
                                    throw LabelledSurfaceExtractionError
                                        .publicationFailed
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
                                let nextTriangleCount =
                                    triangleCount
                                    .addingReportingOverflow(1)
                                guard !nextTriangleCount.overflow else {
                                    throw LabelledSurfaceExtractionError
                                        .resourceLimitExceeded
                                }
                                triangleCount = nextTriangleCount.partialValue
                            }
                        }
                        let nextCellOrdinal = cellOrdinal.addingReportingOverflow(1)
                        guard !nextCellOrdinal.overflow else {
                            throw LabelledSurfaceExtractionError
                                .resourceLimitExceeded
                        }
                        cellOrdinal = nextCellOrdinal.partialValue
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
                throw LabelledSurfaceExtractionError.publicationFailed
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
        } catch let error as LabelledSurfaceExtractionError {
            throw error
        } catch {
            throw LabelledSurfaceExtractionError.publicationFailed
        }
        if checksFinalCancellation, cancellation(.final) {
            throw LabelledSurfaceExtractionError.cancelled
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
            throw LabelledSurfaceExtractionError.resourceLimitExceeded
        }
        return total.partialValue
    }

    private static func candidate(
        edgeID: Int,
        tetrahedron: [Int],
        corners: [GridPoint],
        ordinals: [Int],
        selected: [Bool],
        admission: LabelledSurfaceSourceAdmission
    ) throws -> VertexCandidate {
        let edge = Self.tetrahedronEdges[edgeID]
        var firstCorner = tetrahedron[edge[0]]
        var secondCorner = tetrahedron[edge[1]]
        if ordinals[secondCorner] < ordinals[firstCorner] {
            swap(&firstCorner, &secondCorner)
        }
        guard selected[firstCorner] != selected[secondCorner] else {
            throw LabelledSurfaceExtractionError.publicationFailed
        }

        let firstOrdinal = ordinals[firstCorner]
        let secondOrdinal = ordinals[secondCorner]
        let imagePosition = try Position(
            x: midpoint(corners[firstCorner].x, corners[secondCorner].x),
            y: midpoint(corners[firstCorner].y, corners[secondCorner].y),
            z: midpoint(corners[firstCorner].z, corners[secondCorner].z)
        )
        return VertexCandidate(
            key: VertexKey(
                firstOrdinal: UInt64(firstOrdinal),
                secondOrdinal: UInt64(secondOrdinal)
            ),
            world: try worldPosition(imagePosition, admission: admission)
        )
    }

    static func midpoint(_ first: Int, _ second: Int) throws -> Double {
        let firstValue = Double(first)
        let secondValue = Double(second)
        let difference = second.subtractingReportingOverflow(first)
        guard !difference.overflow else {
            throw LabelledSurfaceExtractionError.positionNotRepresentable
        }
        let delta = Double(difference.partialValue)
        let product = 0.5 * delta
        let result = firstValue + product
        let doubled = first.addingReportingOverflow(second)
        let doubledResult = result * 2
        guard
            Int(exactly: firstValue) == first,
            Int(exactly: secondValue) == second,
            product.isFinite,
            result.isFinite,
            !doubled.overflow,
            Int(exactly: doubledResult) == doubled.partialValue
        else {
            throw LabelledSurfaceExtractionError.positionNotRepresentable
        }
        return result
    }

    private static func worldPosition(
        _ image: Position,
        admission: LabelledSurfaceSourceAdmission
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
                throw LabelledSurfaceExtractionError.positionNotRepresentable
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
        limits: LabelledSurfaceExtractionLimits
    ) throws {
        let nextTriangleCount = triangleCount.addingReportingOverflow(1)
        guard
            !nextTriangleCount.overflow,
            nextTriangleCount.partialValue <= limits.maximumTriangleCount,
            triangleIndexCount <= Int.max - 3
        else {
            throw LabelledSurfaceExtractionError.resourceLimitExceeded
        }

        var newVertexCount: UInt64 = 0
        for candidate in candidates where vertexIndices[candidate.key] == nil {
            let next = newVertexCount.addingReportingOverflow(1)
            guard !next.overflow else {
                throw LabelledSurfaceExtractionError.resourceLimitExceeded
            }
            newVertexCount = next.partialValue
        }
        let currentVertexCount = UInt64(vertexIndices.count)
        let nextVertexCount = currentVertexCount.addingReportingOverflow(
            newVertexCount
        )
        let additionalComponents = Int(newVertexCount)
            .multipliedReportingOverflow(by: 3)
        guard
            !nextVertexCount.overflow,
            nextVertexCount.partialValue <= limits.maximumVertexCount,
            nextVertexCount.partialValue <= UInt64(Int.max),
            !additionalComponents.overflow,
            positionComponentCount
                <= Int.max - additionalComponents.partialValue
        else {
            throw LabelledSurfaceExtractionError.resourceLimitExceeded
        }
    }
}
