// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaRendering

@Suite("VolumeMaskSampler")
struct VolumeMaskSamplerTests {
    /// A `[3, 3, 3]` label volume where every voxel carries a unique
    /// label `1 + x + 3y + 9z`, so exact voxel selection is
    /// unambiguous.
    private func labelBytes() -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 27)
        for z in 0..<3 {
            for y in 0..<3 {
                for x in 0..<3 {
                    bytes[x + 3 * (y + 3 * z)] = UInt8(1 + x + 3 * y + 9 * z)
                }
            }
        }
        return bytes
    }

    @Test("[Unit][VOX-DVR-010] the nearest-neighbour lookup reproduces the fixtures")
    func nearestNeighbourLookupReproducesTheFixtures() throws {
        // The ALG-0026 conformance fixture: the standard six-sample
        // axis-ray index-x positions resolve to voxel-x indices
        // 0, 0, 1, 1, 2, 2 with y and z fixed at 1.
        let bytes = labelBytes()
        let extents: ContiguousArray<Int> = [3, 3, 3]
        let positions: [[Double]] = [
            [-0.25, 1, 1],
            [0.25, 1, 1],
            [0.75, 1, 1],
            [1.25, 1, 1],
            [1.75, 1, 1],
            [2.25, 1, 1],
        ]
        let expectedLabels: [UInt8] = [13, 13, 14, 14, 15, 15]
        for (position, expected) in zip(positions, expectedLabels) {
            #expect(
                VolumeMaskSampler.sample(position, extents: extents, bytes: bytes)
                    == expected
            )
        }

        // Out-of-support on any axis returns label zero, mirroring
        // the trilinear sampler's sentinel.
        #expect(
            VolumeMaskSampler.sample([-0.51, 1, 1], extents: extents, bytes: bytes) == 0
        )
        #expect(
            VolumeMaskSampler.sample([2.51, 1, 1], extents: extents, bytes: bytes) == 0
        )
        #expect(
            VolumeMaskSampler.sample([1, -0.51, 1], extents: extents, bytes: bytes) == 0
        )
        #expect(
            VolumeMaskSampler.sample([1, 1, 2.51], extents: extents, bytes: bytes) == 0
        )

        // Repetition is bit-identical.
        #expect(
            VolumeMaskSampler.sample(positions[0], extents: extents, bytes: bytes)
                == VolumeMaskSampler.sample(positions[0], extents: extents, bytes: bytes)
        )
    }

    @Test("[Unit][VOX-ERR-001] an empty visible-label set rejects typed")
    func emptyVisibleLabelSetRejectsTyped() throws {
        let id = try #require(DataObjectID(rawValue: "mask-1"))
        #expect(throws: RenderModelError.emptyVisibleLabelSet) {
            try VolumeMaskSelection(maskObjectID: id, visibleLabels: [])
        }
        let selection = try VolumeMaskSelection(
            maskObjectID: id,
            visibleLabels: [2, 5]
        )
        #expect(selection.visibleLabels == [2, 5])
        #expect(selection.maskObjectID == id)
    }
}
