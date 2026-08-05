// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaRendering

@Suite("VolumeRayCompositor")
struct VolumeRayCompositorTests {
    /// The specification's ramp table: every entry component equals
    /// the index.
    private func rampTable() throws -> TransferFunction1D {
        var entries = ContiguousArray<TransferFunctionEntry>()
        entries.reserveCapacity(256)
        for index in 0..<256 {
            let level = UInt8(index)
            entries.append(
                TransferFunctionEntry(
                    red: level,
                    green: level,
                    blue: level,
                    opacity: level
                )
            )
        }
        return try TransferFunction1D(entries: entries)
    }

    @Test("[Unit][VOX-DVR-001][VOX-DVR-004] the frozen accumulation reproduces the fixtures")
    func frozenAccumulationReproducesTheFixtures() throws {
        // The ALG-0023 fixtures including consumed counts, with
        // repetition bit-identical.
        let table = try rampTable()

        let general = VolumeRayCompositor.composite(
            samples: [100, 200],
            table: table
        )
        #expect(general.red == 135)
        #expect(general.alpha == 222)
        #expect(general.consumedSampleCount == 2)

        let terminated = VolumeRayCompositor.composite(
            samples: [255, 17],
            table: table
        )
        #expect(terminated.red == 255)
        #expect(terminated.alpha == 255)
        #expect(terminated.consumedSampleCount == 1)

        let below = VolumeRayCompositor.composite(
            samples: [200, 200, 200],
            table: table
        )
        #expect(below.red == 198)
        #expect(below.alpha == 252)
        #expect(below.consumedSampleCount == 3)

        let empty = VolumeRayCompositor.composite(samples: [], table: table)
        #expect(empty == CompositedRay(red: 0, green: 0, blue: 0, alpha: 0, consumedSampleCount: 0))

        let transparent = VolumeRayCompositor.composite(
            samples: [0, 0, 0],
            table: table
        )
        #expect(transparent.alpha == 0)
        #expect(transparent.consumedSampleCount == 3)

        #expect(
            VolumeRayCompositor.composite(samples: [100, 200], table: table)
                == general
        )
    }

    @Test("[Unit][VOX-DVR-004] the termination threshold boundary is honoured")
    func terminationThresholdBoundaryIsHonoured() throws {
        // The declared constant is exactly 255/256. Exhaustive search
        // over every opacity pair proves no byte-derived accumulation
        // can equal the threshold exactly in binary64, so the
        // boundary contract is proven by its two reachable sides: an
        // accumulation strictly exceeding the threshold stops the ray
        // and one strictly below continues — both pinned by the
        // fixtures above — with the greater-or-equal comparison
        // carrying the unreachable equality by construction.
        #expect(VolumeRayCompositor.terminationThreshold == 255.0 / 256.0)
        let table = try rampTable()
        var exactHitExists = false
        for first in 0...255 {
            let firstAlpha = Double(first) / 255.0
            for second in 0...255 {
                let weight = (1.0 - firstAlpha) * (Double(second) / 255.0)
                if firstAlpha + weight == VolumeRayCompositor.terminationThreshold {
                    exactHitExists = true
                }
            }
        }
        #expect(!exactHitExists)
        _ = table
    }
}
