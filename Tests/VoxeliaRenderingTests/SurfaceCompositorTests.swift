// SPDX-License-Identifier: MIT

import CryptoKit
import Synchronization
import Testing

@testable import VoxeliaRendering

@Suite("Surface compositor")
struct SurfaceCompositorTests {
    private final class CheckpointLog: Sendable {
        private let recorded = Mutex([SurfaceVisibilityCheckpoint]())

        func record(_ checkpoint: SurfaceVisibilityCheckpoint) {
            recorded.withLock { $0.append(checkpoint) }
        }

        var checkpoints: [SurfaceVisibilityCheckpoint] {
            recorded.withLock { $0 }
        }
    }

    @Test(
        "[Oracle][VOX-SUR-003][VOX-NUM-001] all ALG-0035 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() {
        var records = [String]()
        var payload = [UInt8]()

        for (name, fragments) in analyticalFixtures() {
            let result = SurfaceCompositor.composite(fragments: fragments)
            var tokens = [String]()
            for entry in result.contributions {
                tokens.append(
                    "\(entry.fragment.layerIndex):"
                        + "\(entry.fragment.facetOrdinal):"
                        + hexadecimal(
                            entry.contribution.bitPattern,
                            width: 16
                        )
                )
                payload.append(
                    contentsOf: littleEndianBytes(
                        entry.contribution.bitPattern
                    )
                )
            }
            payload.append(
                contentsOf: littleEndianBytes(
                    result.accumulatedAlpha.bitPattern
                )
            )
            records.append(
                "\(name)|count=\(result.contributions.count)"
                    + "|alpha="
                    + hexadecimal(result.accumulatedAlpha.bitPattern, width: 16)
                    + "|\(tokens.joined(separator: ","))"
            )
        }

        #expect(records.count == 12)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "43c71d094dcf0cb932d9789c6f5f8fafa254bb715ccf73d65111ef1c58611dc5"
        )
        #expect(
            sha256(payload)
                == "860a28e69c4b797acaad62fb311a7ad60df96973eb8aa8a1773fd7fcd56a91d0"
        )
    }

    @Test(
        "[Unit][VOX-SUR-003][VOX-NUM-001] the frozen order and accumulation hold exactly"
    )
    func frozenOrderAndAccumulationHoldExactly() {
        // Supply order is irrelevant: depth decides first.
        let forward = SurfaceCompositor.composite(fragments: [
            fragment(depth: 1, layer: 0, facet: 0, opacity: 0.5),
            fragment(depth: 5, layer: 1, facet: 0, opacity: 0.5),
        ])
        let reverse = SurfaceCompositor.composite(fragments: [
            fragment(depth: 5, layer: 1, facet: 0, opacity: 0.5),
            fragment(depth: 1, layer: 0, facet: 0, opacity: 0.5),
        ])
        #expect(forward == reverse)
        #expect(forward.contributions.map(\.contribution) == [0.5, 0.25])
        #expect(forward.accumulatedAlpha == 0.75)

        // Equal depth resolves by layer, then by facet ordinal. The triple is
        // a strict total order, so no pair of fragments can tie.
        let byLayer = SurfaceCompositor.composite(fragments: [
            fragment(depth: 3, layer: 1, facet: 0, opacity: 1),
            fragment(depth: 3, layer: 0, facet: 0, opacity: 0.25),
        ])
        #expect(byLayer.contributions[0].fragment.layerIndex == 0)
        let byFacet = SurfaceCompositor.composite(fragments: [
            fragment(depth: 3, layer: 0, facet: 7, opacity: 1),
            fragment(depth: 3, layer: 0, facet: 2, opacity: 0.25),
        ])
        #expect(byFacet.contributions[0].fragment.facetOrdinal == 2)

        // Occlusion falls out of the accumulation, and every post-saturation
        // weight is exactly zero — which is why stopping early is
        // bit-identical to continuing.
        let saturated = SurfaceCompositor.composite(fragments: [
            fragment(depth: 1, layer: 0, facet: 0, opacity: 1),
            fragment(depth: 2, layer: 1, facet: 0, opacity: 0.9),
            fragment(depth: 3, layer: 2, facet: 0, opacity: 0.9),
        ])
        #expect(saturated.contributions[0].contribution == 1)
        #expect(saturated.contributions[1].contribution == 0)
        #expect(saturated.contributions[2].contribution == 0)
        #expect(saturated.accumulatedAlpha == 1)

        // A zero-opacity fragment is retained and weighs exactly zero.
        let transparent = SurfaceCompositor.composite(fragments: [
            fragment(depth: 1, layer: 0, facet: 0, opacity: 0),
            fragment(depth: 2, layer: 1, facet: 0, opacity: 0.5),
        ])
        #expect(transparent.contributions.count == 2)
        #expect(transparent.contributions[0].contribution == 0)
        #expect(transparent.accumulatedAlpha == 0.5)

        // An uncovered pixel composites to nothing at positive zero alpha.
        let empty = SurfaceCompositor.composite(fragments: [])
        #expect(empty.contributions.isEmpty)
        #expect(empty.accumulatedAlpha.bitPattern == (0.0).bitPattern)

        // The accumulator is bounded by one and never decreases, which is why
        // this model needs no representability failure at all.
        let chain = SurfaceCompositor.composite(
            fragments: (0..<64).map {
                fragment(
                    depth: Double($0),
                    layer: $0,
                    facet: 0,
                    opacity: 0.5
                )
            }
        )
        var running = 0.0
        for entry in chain.contributions {
            #expect(entry.contribution >= 0)
            running += entry.contribution
            #expect(running <= 1)
        }
        #expect(chain.accumulatedAlpha <= 1)
    }

    @Test(
        "[Unit][VOX-SUR-003][VOX-SEC-001][VOX-CON-006] retention shares coverage and is bounded"
    )
    func retentionSharesCoverageAndIsBounded() throws {
        let viewport = try ViewportSize(width: 4, height: 4)
        let near = fullCover(depth: 1)
        let far = fullCover(depth: 5)

        // Every covering fragment is retained, not just the nearest — which
        // is the whole reason this stage exists alongside the resolver.
        let buckets = try SurfaceFragmentCollector.collect(
            layers: [[near], [far]],
            opacities: [0.5, 0.5],
            viewport: viewport,
            limits: SurfaceFragmentLimits(
                maximumRetainedLogicalByteCount: 1_048_576
            ),
            cancellation: { _ in false }
        )
        #expect(buckets.count == 16)
        #expect(buckets.allSatisfy { $0.count == 2 })

        // The shared coverage means the resolver's nearest hit is exactly the
        // first fragment this stage composites.
        let resolved = try SurfaceVisibilityResolver.resolve(
            layers: [[near], [far]],
            viewport: viewport,
            limits: SurfaceVisibilityLimits(
                maximumAdditionalLogicalByteCount: 1_048_576
            ),
            cancellation: { _ in false }
        )
        for pixel in 0..<16 {
            let composited = SurfaceCompositor.composite(
                fragments: buckets[pixel]
            )
            let hit = try #require(
                resolved.hit(column: pixel % 4, row: pixel / 4)
            )
            #expect(
                composited.contributions[0].fragment.depth == hit.depth
            )
            #expect(
                composited.contributions[0].fragment.layerIndex
                    == hit.layerIndex
            )
        }

        // Thirty-two fragments at fifty-six bytes need exactly 1,792 bytes.
        #expect(
            try SurfaceFragmentCollector.checkedRetained(
                1_736,
                limit: 1_792
            ) == 1_792
        )
        #expect(throws: SurfaceVisibilityError.resourceLimitExceeded) {
            _ = try SurfaceFragmentCollector.checkedRetained(
                1_736,
                limit: 1_791
            )
        }
        #expect(throws: SurfaceVisibilityError.resourceLimitExceeded) {
            _ = try SurfaceFragmentCollector.collect(
                layers: [[near], [far]],
                opacities: [0.5, 0.5],
                viewport: viewport,
                limits: SurfaceFragmentLimits(
                    maximumRetainedLogicalByteCount: 1_791
                ),
                cancellation: { _ in false }
            )
        }

        // The poll set matches the resolver's per-layer facet cadence.
        let log = CheckpointLog()
        _ = try SurfaceFragmentCollector.collect(
            layers: [Array(repeating: near, count: 130), [far]],
            opacities: [0.5, 0.5],
            viewport: viewport,
            limits: SurfaceFragmentLimits(
                maximumRetainedLogicalByteCount: .max
            ),
            cancellation: { checkpoint in
                log.record(checkpoint)
                return false
            }
        )
        #expect(
            log.checkpoints == [
                .admission,
                .facet(layer: 0, ordinal: 0),
                .facet(layer: 0, ordinal: 64),
                .facet(layer: 0, ordinal: 128),
                .facet(layer: 1, ordinal: 0),
            ]
        )
        #expect(throws: SurfaceVisibilityError.cancelled) {
            _ = try SurfaceFragmentCollector.collect(
                layers: [[near]],
                opacities: [0.5],
                viewport: viewport,
                limits: SurfaceFragmentLimits(
                    maximumRetainedLogicalByteCount: .max
                ),
                cancellation: { $0 == .admission }
            )
        }
    }

    // MARK: - Fixtures

    private func fragment(
        depth: Double,
        layer: Int,
        facet: Int,
        opacity: Double
    ) -> SurfaceFragment {
        SurfaceFragment(
            depth: depth,
            weightA: 0,
            weightB: 0,
            weightC: 0,
            layerIndex: layer,
            facetOrdinal: facet,
            opacity: opacity,
            swapped: false
        )
    }

    private func fullCover(depth: Double) -> ProjectedFacet {
        ProjectedFacet(
            ProjectedVertex(
                column: -4, row: -4, depth: depth,
                worldX: 0, worldY: 0, worldZ: 0
            ),
            ProjectedVertex(
                column: 12, row: -4, depth: depth,
                worldX: 0, worldY: 0, worldZ: 0
            ),
            ProjectedVertex(
                column: -4, row: 12, depth: depth,
                worldX: 0, worldY: 0, worldZ: 0
            )
        )
    }

    private func analyticalFixtures() -> [(String, [SurfaceFragment])] {
        let singleOpaque = [fragment(depth: 1, layer: 0, facet: 0, opacity: 1)]
        let singleHalf = [fragment(depth: 1, layer: 0, facet: 0, opacity: 0.5)]
        let twoHalf = [
            fragment(depth: 1, layer: 0, facet: 0, opacity: 0.5),
            fragment(depth: 2, layer: 1, facet: 0, opacity: 0.5),
        ]
        let occluded = [
            fragment(depth: 1, layer: 0, facet: 0, opacity: 1),
            fragment(depth: 5, layer: 1, facet: 0, opacity: 0.75),
        ]
        let reverseSupplied = [
            fragment(depth: 5, layer: 1, facet: 0, opacity: 0.5),
            fragment(depth: 1, layer: 0, facet: 0, opacity: 0.5),
        ]
        let equalLayer = [
            fragment(depth: 3, layer: 1, facet: 0, opacity: 1),
            fragment(depth: 3, layer: 0, facet: 0, opacity: 0.25),
        ]
        let equalFacet = [
            fragment(depth: 3, layer: 0, facet: 7, opacity: 1),
            fragment(depth: 3, layer: 0, facet: 2, opacity: 0.25),
        ]
        let withTransparent = [
            fragment(depth: 1, layer: 0, facet: 0, opacity: 0),
            fragment(depth: 2, layer: 1, facet: 0, opacity: 0.5),
        ]
        let many = (0..<24).map {
            fragment(depth: Double($0), layer: $0, facet: 0, opacity: 0.5)
        }
        var saturating = [fragment(depth: 1, layer: 0, facet: 0, opacity: 1)]
        for index in 0..<5 {
            saturating.append(
                fragment(
                    depth: Double(index + 2),
                    layer: index + 1,
                    facet: 0,
                    opacity: 0.9
                )
            )
        }
        let thirds = (0..<4).map {
            fragment(
                depth: Double($0),
                layer: $0,
                facet: 0,
                opacity: 1.0 / 3.0
            )
        }
        return [
            ("single-opaque", singleOpaque),
            ("single-half", singleHalf),
            ("two-half", twoHalf),
            ("opaque-occludes", occluded),
            ("reverse-supplied", reverseSupplied),
            ("equal-depth-layer-order", equalLayer),
            ("equal-depth-facet-order", equalFacet),
            ("zero-opacity-retained", withTransparent),
            ("long-chain", many),
            ("saturating", saturating),
            ("empty", []),
            ("repeating-thirds", thirds),
        ]
    }

    // MARK: - Helpers

    private func littleEndianBytes(_ bitPattern: UInt64) -> [UInt8] {
        (0..<8).map { byteIndex in
            UInt8(truncatingIfNeeded: bitPattern >> UInt64(byteIndex * 8))
        }
    }

    private func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: bytes).map {
            hexadecimal(UInt64($0), width: 2)
        }.joined()
    }

    private func hexadecimal(_ value: UInt64, width: Int) -> String {
        let text = String(value, radix: 16)
        return String(repeating: "0", count: width - text.count) + text
    }
}
