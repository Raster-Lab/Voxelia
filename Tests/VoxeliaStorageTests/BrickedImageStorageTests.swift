// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaStorage

@Suite("BrickedImageStorage")
struct BrickedImageStorageTests {
    /// The design layout: extents (5, 4, 3) with nominal (2, 3, 2)
    /// gives brick counts (3, 2, 2) and a boundary brick on every
    /// axis; the stored value is the linear sample index.
    private let extents = [5, 4, 3]
    private let volumeBytes: [UInt8] = (0..<60).map(UInt8.init)

    private func binding() throws -> LogicalSampleBinding {
        try LogicalSampleBinding(
            shape: try ImageShape(extents: ContiguousArray(extents)),
            scalarType: .uint8,
            componentCount: 1
        )
    }

    private func grid() throws -> BrickGridDescriptor {
        try BrickGridDescriptor(
            volumeExtents: [5, 4, 3],
            nominalBrickExtents: [2, 3, 2],
            haloExtents: [0, 0, 0]
        )
    }

    /// Slices the contiguous fixture into per-brick core payloads.
    private func bricks(
        for grid: BrickGridDescriptor
    ) throws -> [ContiguousArray<Int>: [UInt8]] {
        var payloads: [ContiguousArray<Int>: [UInt8]] = [:]
        let counts = grid.brickCounts
        for k in 0..<counts[2] {
            for j in 0..<counts[1] {
                for i in 0..<counts[0] {
                    let coordinate: ContiguousArray<Int> = [i, j, k]
                    let core = try grid.coreRegion(of: coordinate)
                    var payload = [UInt8]()
                    for z in core.lowerBounds[2]..<core.upperBounds[2] {
                        for y in core.lowerBounds[1]..<core.upperBounds[1] {
                            for x in core.lowerBounds[0]..<core.upperBounds[0] {
                                payload.append(
                                    volumeBytes[
                                        x + extents[0] * (y + extents[1] * z)
                                    ]
                                )
                            }
                        }
                    }
                    payloads[coordinate] = payload
                }
            }
        }
        return payloads
    }

    @Test("[Unit][VOX-STO-005][VOX-BRK-001] bricked reads are byte-identical to contiguous")
    func brickedReadsAreByteIdenticalToContiguous() throws {
        // The ADR-0154 obligation over the boundary-bricks-on-every-
        // axis layout: full region, cross-brick interior region,
        // boundary-brick region and a single sample.
        let binding = try binding()
        let grid = try grid()
        let bricked = try BrickedImageStorage(
            binding: binding,
            grid: grid,
            bricks: try bricks(for: grid)
        )
        let contiguous = try ContiguousImageStorage(
            binding: binding,
            bytes: volumeBytes
        )
        let regions: [([Int], [Int])] = [
            ([0, 0, 0], [5, 4, 3]),
            ([1, 1, 1], [4, 4, 2]),
            ([4, 3, 2], [5, 4, 3]),
            ([2, 2, 1], [3, 3, 2]),
        ]
        for (lower, upper) in regions {
            let region = try ImageRegion(lowerBounds: lower, upperBounds: upper)
            let brickedResult = try bricked.read(region: region)
            let contiguousResult = try contiguous.read(region: region)
            #expect(brickedResult.bytes == contiguousResult.bytes)
            #expect(brickedResult.region == contiguousResult.region)
        }
        if case .decodedComposite(let representation) = bricked.snapshot
            .representation
        {
            #expect(
                representation.formatTag
                    == BrickedImageStorage.representationTag
            )
            #expect(representation.fragmentCount == 12)
        } else {
            #expect(Bool(false), "Expected a decoded composite representation.")
        }
    }

    @Test("[Unit][VOX-STO-005][VOX-ERR-001] construction admissions reject typed")
    func constructionAdmissionsRejectTyped() throws {
        let binding = try binding()
        let grid = try grid()
        let complete = try bricks(for: grid)

        #expect(throws: BrickedStorageError.gridMismatch) {
            try BrickedImageStorage(
                binding: binding,
                grid: try BrickGridDescriptor(
                    volumeExtents: [4, 4, 3],
                    nominalBrickExtents: [2, 3, 2],
                    haloExtents: [0, 0, 0]
                ),
                bricks: complete
            )
        }
        var missing = complete
        missing.removeValue(forKey: [0, 0, 0])
        #expect(throws: BrickedStorageError.missingBrick) {
            try BrickedImageStorage(binding: binding, grid: grid, bricks: missing)
        }
        var foreign = complete
        foreign[[9, 9, 9]] = [1]
        #expect(throws: BrickedStorageError.foreignBrick) {
            try BrickedImageStorage(binding: binding, grid: grid, bricks: foreign)
        }
        var truncated = complete
        truncated[[0, 0, 0]] = [1, 2]
        #expect(throws: BrickedStorageError.invalidBrickByteCount) {
            try BrickedImageStorage(
                binding: binding,
                grid: grid,
                bricks: truncated
            )
        }
    }
}
