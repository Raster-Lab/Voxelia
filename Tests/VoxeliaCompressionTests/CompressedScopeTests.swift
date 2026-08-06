// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaCompression

/// `ADR-0260`: `VOX-CMP-003`'s four shapes and `VOX-CMP-008`'s caller-provided
/// destination.
@Suite("CompressedScope")
struct CompressedScopeTests {
    private func format() throws -> ScalarFormat {
        try ScalarFormat(type: .uint16, validBitCount: nil, byteOrder: .littleEndian)
    }

    private func payload(extents: [Int]) throws -> CompressedPayload {
        try CompressedPayload(
            codestream: ContiguousArray([1, 2, 3, 4]),
            declaredExtents: ContiguousArray(extents),
            declaredScalarFormat: try format(),
            declaredComponentCount: 1
        )
    }

    private func region(_ lower: [Int], _ upper: [Int]) throws -> ImageRegion {
        try ImageRegion(
            lowerBounds: ContiguousArray(lower),
            upperBounds: ContiguousArray(upper)
        )
    }

    private func scope(
        lower: [Int],
        upper: [Int],
        volume: [Int]
    ) throws -> CompressedScope {
        let extents = zip(lower, upper).map { $1 - $0 }
        return try CompressedScope(
            payload: try payload(extents: extents),
            region: try region(lower, upper),
            volumeExtents: ContiguousArray(volume)
        )
    }

    // MARK: - The four shapes

    @Test("[Unit][VOX-CMP-003] the four shapes are derived from the region")
    func fourShapesAreDerivedFromTheRegion() throws {
        let volume = [512, 512, 899]

        // The whole volume: the original compressed source.
        #expect(
            try scope(lower: [0, 0, 0], upper: [512, 512, 899], volume: volume).kind
                == .originalSource
        )
        // One plane, full in the other two axes: a slice. Tested on each axis, so
        // the rule is not accidentally specific to the slice axis.
        #expect(
            try scope(lower: [0, 0, 400], upper: [512, 512, 401], volume: volume).kind
                == .slice
        )
        #expect(
            try scope(lower: [0, 200, 0], upper: [512, 201, 899], volume: volume).kind
                == .slice
        )
        #expect(
            try scope(lower: [300, 0, 0], upper: [301, 512, 899], volume: volume).kind
                == .slice
        )
        // A contiguous run of planes: a slab.
        #expect(
            try scope(lower: [0, 0, 400], upper: [512, 512, 416], volume: volume).kind
                == .slab
        )
        // Bounded on two axes, and on three: a brick either way.
        #expect(
            try scope(lower: [0, 100, 400], upper: [512, 200, 416], volume: volume).kind
                == .brick
        )
        #expect(
            try scope(lower: [64, 100, 400], upper: [128, 200, 416], volume: volume).kind
                == .brick
        )
    }

    @Test("[Unit][VOX-CMP-003] covering everything wins over describing a single plane")
    func coveringEverythingWinsOverSinglePlane() throws {
        // A volume whose slice axis has extent one is simultaneously the whole
        // volume and a single plane. Both descriptions are true, so the frozen
        // clause order decides: covering everything is the stronger statement.
        // Without the rule this classification would be ambiguous.
        let flat = [512, 512, 1]
        #expect(
            try scope(lower: [0, 0, 0], upper: [512, 512, 1], volume: flat).kind
                == .originalSource
        )
        // But a plane of a taller volume is a slice, so the clause is precedence
        // rather than a special case for extent one.
        #expect(
            try scope(lower: [0, 0, 0], upper: [512, 512, 1], volume: [512, 512, 4])
                .kind == .slice
        )
    }

    @Test("[Unit][VOX-CMP-003] the classification is exhaustive over enumerated shapes")
    func classificationIsExhaustiveOverEnumeratedShapes() {
        // The input space of a small volume is enumerable, so it is enumerated
        // rather than sampled: every region of a 2x2x2 volume is classified, and
        // every one of the four kinds is reached.
        let volume: ContiguousArray<Int> = [2, 2, 2]
        var seen = Set<CompressedScopeKind>()
        var count = 0
        for x in 1...2 {
            for y in 1...2 {
                for z in 1...2 {
                    let kind = CompressedScope.classify(
                        regionExtents: [x, y, z],
                        volumeExtents: volume
                    )
                    seen.insert(kind)
                    count += 1
                }
            }
        }
        #expect(count == 8)
        // A 2x2x2 volume cannot produce a slab: a partial axis has extent one, so
        // it is always a slice. Stated as an expectation rather than left as a gap
        // in the coverage claim.
        #expect(seen == [.originalSource, .slice, .brick])

        // A taller volume does produce all four.
        #expect(
            CompressedScope.classify(regionExtents: [2, 2, 2], volumeExtents: [2, 2, 4])
                == .slab
        )
    }

    // MARK: - Agreement and admissions

    @Test("[Unit][VOX-CMP-003][VOX-ERR-001] a payload disagreeing with its region refuses")
    func payloadDisagreeingWithRegionRefuses() throws {
        // The refusal that matters: a codestream declaring one shape while its
        // scope claims another would surface later as a truncated decode.
        #expect(throws: CompressedScopeError.payloadExtentsDisagreeWithRegion) {
            try CompressedScope(
                payload: try payload(extents: [512, 512, 8]),
                region: try region([0, 0, 0], [512, 512, 16]),
                volumeExtents: [512, 512, 899]
            )
        }
    }

    @Test("[Unit][VOX-CMP-003][VOX-ERR-001] scope admission rejects typed")
    func scopeAdmissionRejectsTyped() throws {
        #expect(throws: CompressedScopeError.missingVolumeExtents) {
            try CompressedScope(
                payload: try payload(extents: [1]),
                region: try region([0], [1]),
                volumeExtents: []
            )
        }
        #expect(throws: CompressedScopeError.invalidVolumeExtent) {
            try CompressedScope(
                payload: try payload(extents: [1]),
                region: try region([0], [1]),
                volumeExtents: [0]
            )
        }
        #expect(throws: CompressedScopeError.rankMismatch) {
            try CompressedScope(
                payload: try payload(extents: [2, 2]),
                region: try region([0, 0], [2, 2]),
                volumeExtents: [2, 2, 2]
            )
        }
        // A region reaching beyond the volume, which is the case a corrupt index
        // would produce.
        #expect(throws: CompressedScopeError.regionOutsideVolume) {
            try CompressedScope(
                payload: try payload(extents: [2, 2, 4]),
                region: try region([0, 0, 0], [2, 2, 4]),
                volumeExtents: [2, 2, 2]
            )
        }
    }
}
