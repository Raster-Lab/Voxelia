// SPDX-License-Identifier: MIT

import CryptoKit
import Synchronization
import Testing

@testable import VoxeliaRendering

@Suite("Surface visibility resolver")
struct SurfaceVisibilityResolverTests {
    private struct Fixture: Sendable {
        let name: String
        let layers: [[ProjectedFacet]]
        let width: Int
        let height: Int
    }

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
        "[Oracle][VOX-SUR-002][VOX-NUM-001] all ALG-0034 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let buffer = try resolve(fixture)
                var tokens = [String]()
                for rowIndex in 0..<fixture.height {
                    for columnIndex in 0..<fixture.width {
                        guard
                            let hit = buffer.hit(
                                column: columnIndex,
                                row: rowIndex
                            )
                        else {
                            tokens.append("-")
                            continue
                        }
                        tokens.append(
                            "\(hit.layerIndex):\(hit.facetOrdinal):"
                                + hexadecimal(hit.depth.bitPattern, width: 16)
                        )
                        payload.append(
                            contentsOf: littleEndianBytes(hit.depth.bitPattern)
                        )
                        for weight in [hit.weightA, hit.weightB, hit.weightC] {
                            payload.append(
                                contentsOf: littleEndianBytes(weight.bitPattern)
                            )
                        }
                    }
                }
                records.append(
                    "\(fixture.name)|covered=\(buffer.coveredCount)"
                        + "|\(tokens.joined(separator: ","))"
                )
            } catch let error as SurfaceVisibilityError {
                records.append("\(fixture.name)|error=\(errorName(error))")
            }
        }

        #expect(records.count == 13)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "f4f92219f39a9adaf634b1f60c5316a3b731c8c5722c67e45fb898f055ba2d43"
        )
        #expect(
            sha256(payload)
                == "35f0ccfd0811b51ba75150fee53b92a57f30f92b5a147381d52f7b009bd90725"
        )
    }

    @Test(
        "[Unit][VOX-SUR-002][VOX-NUM-001] the shared edge is claimed exactly once"
    )
    func sharedEdgeIsClaimedExactlyOnce() throws {
        // Without the top-left fill rule a sample on the shared diagonal is
        // claimed by both facets — a seam — or by neither — a crack.
        var counts = [Int](repeating: 0, count: 16)
        for facet in [quadFirst, quadSecond] {
            let buffer = try resolve(
                Fixture(
                    name: "half",
                    layers: [[facet]],
                    width: 4,
                    height: 4
                )
            )
            for rowIndex in 0..<4 {
                for columnIndex in 0..<4
                where buffer.hit(column: columnIndex, row: rowIndex) != nil {
                    counts[rowIndex * 4 + columnIndex] += 1
                }
            }
        }
        #expect(counts.allSatisfy { $0 == 1 })
    }

    @Test(
        "[Unit][VOX-SUR-002][VOX-NUM-001] the frozen visibility rules hold exactly"
    )
    func frozenVisibilityRulesHoldExactly() throws {
        // Nearest wins outright.
        let nearer = try resolve(
            Fixture(
                name: "depth",
                layers: [[fullCover(depth: 9)], [fullCover(depth: 2)]],
                width: 4,
                height: 4
            )
        )
        #expect(nearer.hit(column: 0, row: 0)?.layerIndex == 1)
        #expect(nearer.hit(column: 3, row: 3)?.depth == 2)

        // Equal depth keeps the earlier layer, and within a layer the earlier
        // facet, because a candidate must be STRICTLY nearer to replace.
        let tie = try resolve(
            Fixture(
                name: "tie",
                layers: [[fullCover(depth: 5)], [fullCover(depth: 5)]],
                width: 4,
                height: 4
            )
        )
        #expect(tie.hit(column: 2, row: 1)?.layerIndex == 0)
        let sameLayerTie = try resolve(
            Fixture(
                name: "tie",
                layers: [[fullCover(depth: 5), fullCover(depth: 5)]],
                width: 4,
                height: 4
            )
        )
        #expect(sameLayerTie.hit(column: 2, row: 1)?.facetOrdinal == 0)

        // Back-facing facets are not culled: identical coverage and depths.
        let forward = try resolve(
            Fixture(
                name: "f",
                layers: [[fullCover(depth: 5)]],
                width: 4,
                height: 4
            )
        )
        let reversed = fullCover(depth: 5)
        let backward = try resolve(
            Fixture(
                name: "b",
                layers: [
                    [ProjectedFacet(reversed.first, reversed.third, reversed.second)]
                ],
                width: 4,
                height: 4
            )
        )
        for rowIndex in 0..<4 {
            for columnIndex in 0..<4 {
                #expect(
                    forward.hit(column: columnIndex, row: rowIndex)?.depth
                        == backward.hit(column: columnIndex, row: rowIndex)?
                        .depth
                )
            }
        }

        // A facet projecting to zero area covers nothing and is not an error.
        let degenerate = try resolve(
            Fixture(
                name: "d",
                layers: [
                    [
                        ProjectedFacet(
                            vertex(0, 0, 1),
                            vertex(4, 4, 1),
                            vertex(2, 2, 1)
                        )
                    ]
                ],
                width: 4,
                height: 4
            )
        )
        #expect(degenerate.coveredCount == 0)

        // Negative depth is admitted: there is no near plane in version one.
        let behind = try resolve(
            Fixture(
                name: "n",
                layers: [[fullCover(depth: -3)], [fullCover(depth: 5)]],
                width: 4,
                height: 4
            )
        )
        #expect(behind.hit(column: 1, row: 1)?.depth == -3)

        // An empty scene covers nothing.
        #expect(
            try resolve(
                Fixture(name: "e", layers: [], width: 4, height: 4)
            ).coveredCount == 0
        )
    }

    @Test(
        "[Unit][VOX-SUR-002][VOX-SEC-001][VOX-CON-006] limits, failures and cancellation are exact"
    )
    func limitsFailuresAndCancellationAreExact() throws {
        // A 4x4 buffer needs exactly 16 * 48 = 768 logical bytes.
        #expect(
            try SurfaceVisibilityResolver.checkedBufferByteCount(
                width: 4,
                height: 4,
                maximumAdditionalLogicalByteCount: 768
            ) == 16
        )
        #expect(throws: SurfaceVisibilityError.resourceLimitExceeded) {
            _ = try SurfaceVisibilityResolver.checkedBufferByteCount(
                width: 4,
                height: 4,
                maximumAdditionalLogicalByteCount: 767
            )
        }
        // The largest admissible viewport needs over twelve gigabytes, which
        // is exactly why this stage declares a ceiling at all.
        #expect(
            try SurfaceVisibilityResolver.checkedBufferByteCount(
                width: 16_384,
                height: 16_384,
                maximumAdditionalLogicalByteCount: .max
            ) == 268_435_456
        )
        #expect(throws: SurfaceVisibilityError.resourceLimitExceeded) {
            _ = try self.resolve(
                Fixture(
                    name: "tight",
                    layers: [[self.fullCover(depth: 1)]],
                    width: 4,
                    height: 4
                ),
                maximumAdditionalLogicalByteCount: 100
            )
        }

        // An overflowing edge function fails representably.
        #expect(throws: SurfaceVisibilityError.coverageNotRepresentable) {
            _ = try self.resolve(
                Fixture(
                    name: "overflow",
                    layers: [
                        [
                            ProjectedFacet(
                                self.vertex(0, 0, 1),
                                self.vertex(1e200, 0, 1),
                                self.vertex(0, 1e200, 1)
                            )
                        ]
                    ],
                    width: 4,
                    height: 4
                )
            )
        }

        // The poll set is admission plus per-layer facet ordinals divisible
        // by 64, so neither many small layers nor one large layer starves
        // cancellation.
        let manyFacets = Array(repeating: fullCover(depth: 1), count: 130)
        let log = CheckpointLog()
        _ = try resolve(
            Fixture(
                name: "poll",
                layers: [manyFacets, [fullCover(depth: 1)]],
                width: 4,
                height: 4
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
        for checkpoint: SurfaceVisibilityCheckpoint in [
            .admission,
            .facet(layer: 0, ordinal: 0),
            .facet(layer: 0, ordinal: 128),
            .facet(layer: 1, ordinal: 0),
        ] {
            #expect(throws: SurfaceVisibilityError.cancelled) {
                _ = try self.resolve(
                    Fixture(
                        name: "poll",
                        layers: [manyFacets, [self.fullCover(depth: 1)]],
                        width: 4,
                        height: 4
                    ),
                    cancellation: { $0 == checkpoint }
                )
            }
        }
        // A non-poll ordinal is never observed, so it cannot cancel.
        #expect(
            try resolve(
                Fixture(
                    name: "poll",
                    layers: [manyFacets],
                    width: 4,
                    height: 4
                ),
                cancellation: { $0 == .facet(layer: 0, ordinal: 1) }
            ).coveredCount == 16
        )

        let errors: [SurfaceVisibilityError] = [
            .resourceLimitExceeded,
            .coverageNotRepresentable,
            .cancelled,
        ]
        #expect(
            errors.map { String(describing: $0) } == [
                "resourceLimitExceeded",
                "coverageNotRepresentable",
                "cancelled",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private func vertex(
        _ column: Double,
        _ row: Double,
        _ depth: Double
    ) -> ProjectedVertex {
        ProjectedVertex(
            column: column,
            row: row,
            depth: depth,
            worldX: 0,
            worldY: 0,
            worldZ: 0
        )
    }

    private func fullCover(depth: Double) -> ProjectedFacet {
        ProjectedFacet(
            vertex(-4, -4, depth),
            vertex(12, -4, depth),
            vertex(-4, 12, depth)
        )
    }

    private var quadFirst: ProjectedFacet {
        ProjectedFacet(vertex(0, 0, 1), vertex(4, 0, 1), vertex(0, 4, 1))
    }

    private var quadSecond: ProjectedFacet {
        ProjectedFacet(vertex(4, 0, 1), vertex(4, 4, 1), vertex(0, 4, 1))
    }

    private func analyticalFixtures() -> [Fixture] {
        let full = fullCover(depth: 5)
        let tiny = ProjectedFacet(
            vertex(0.4, 0.4, 1),
            vertex(0.9, 0.4, 1),
            vertex(0.4, 0.9, 1)
        )
        let degenerate = ProjectedFacet(
            vertex(0, 0, 1),
            vertex(4, 4, 1),
            vertex(2, 2, 1)
        )
        let outside = ProjectedFacet(
            vertex(20, 20, 1),
            vertex(24, 20, 1),
            vertex(20, 24, 1)
        )
        let straddling = ProjectedFacet(
            vertex(-2, -2, 4),
            vertex(6, -2, 4),
            vertex(-2, 6, 4)
        )
        let tilted = ProjectedFacet(
            vertex(-4, -4, 1),
            vertex(12, -4, 9),
            vertex(-4, 12, 1)
        )
        let overflowing = ProjectedFacet(
            vertex(0, 0, 1),
            vertex(1e200, 0, 1),
            vertex(0, 1e200, 1)
        )
        return [
            fixture("full-cover", [[full]]),
            fixture("pixel-centre", [[tiny]]),
            fixture("shared-edge-quad", [[quadFirst, quadSecond]]),
            fixture(
                "nearest-wins",
                [[fullCover(depth: 9)], [fullCover(depth: 2)]]
            ),
            fixture("equal-depth-tie", [[full], [full]]),
            fixture(
                "backface-not-culled",
                [[ProjectedFacet(full.first, full.third, full.second)]]
            ),
            fixture("degenerate-projection", [[degenerate]]),
            fixture("negative-depth", [[fullCover(depth: -3)], [full]]),
            fixture("outside-viewport", [[outside]]),
            fixture("straddling-viewport", [[straddling]]),
            fixture("tilted-depth", [[tilted]]),
            fixture("empty-scene", []),
            fixture("edge-function-overflow", [[overflowing]]),
        ]
    }

    private func fixture(
        _ name: String,
        _ layers: [[ProjectedFacet]]
    ) -> Fixture {
        Fixture(name: name, layers: layers, width: 4, height: 4)
    }

    // MARK: - Helpers

    private func resolve(
        _ fixture: Fixture,
        maximumAdditionalLogicalByteCount: UInt64 = 1_048_576,
        cancellation: SurfaceVisibilityProbe = { _ in false }
    ) throws -> SurfaceVisibilityBuffer {
        try SurfaceVisibilityResolver.resolve(
            layers: fixture.layers,
            viewport: try ViewportSize(
                width: fixture.width,
                height: fixture.height
            ),
            limits: SurfaceVisibilityLimits(
                maximumAdditionalLogicalByteCount:
                    maximumAdditionalLogicalByteCount
            ),
            cancellation: cancellation
        )
    }

    private func littleEndianBytes(_ bitPattern: UInt64) -> [UInt8] {
        (0..<8).map { byteIndex in
            UInt8(truncatingIfNeeded: bitPattern >> UInt64(byteIndex * 8))
        }
    }

    private func errorName(_ error: SurfaceVisibilityError) -> String {
        switch error {
        case .resourceLimitExceeded: "resourceLimitExceeded"
        case .coverageNotRepresentable: "coverageNotRepresentable"
        case .cancelled: "cancelled"
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
