// SPDX-License-Identifier: MIT

import CryptoKit
import Testing

@testable import VoxeliaRendering

@Suite("Surface picker")
struct SurfacePickerTests {
    private struct Fixture: Sendable {
        let name: String
        let candidates: [SurfacePickCandidate]
        let column: Int
        let row: Int
    }

    @Test(
        "[Oracle][VOX-SUR-007][VOX-NUM-001] all ALG-0039 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            let outcome: SurfacePick?
            do {
                outcome = try pick(fixture)
            } catch let error as SurfacePickError {
                records.append("\(fixture.name)|error=\(error)")
                continue
            }
            guard let pick = outcome else {
                records.append("\(fixture.name)|hit=none")
                continue
            }
            let components = [pick.worldX, pick.worldY, pick.worldZ]
            let indices = [
                pick.firstVertexIndex,
                pick.secondVertexIndex,
                pick.thirdVertexIndex,
            ]
            records.append(
                "\(fixture.name)|layer=\(pick.layerIndex)"
                    + "|facet=\(pick.facetOrdinal)"
                    + "|indices=\(indices.map(String.init).joined(separator: ","))"
                    + "|world="
                    + components.map {
                        hexadecimal($0.bitPattern, width: 16)
                    }.joined(separator: ",")
            )
            for component in components {
                payload.append(
                    contentsOf: littleEndianBytes(component.bitPattern)
                )
            }
        }

        #expect(records.count == 11)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "b5ff409fd3621af9730f9e43b94e68ac5aabe42b8f2799cce72e94993dac13b2"
        )
        #expect(
            sha256(payload)
                == "036c7042a75859dc6effb1cdd47b50cec74cca6cb9d727a964bcfdd53503be96"
        )
    }

    @Test(
        "[Unit][VOX-SUR-007][VOX-GEO-002] a clipped nearer fragment does not occlude a farther one"
    )
    func clippedNearerFragmentDoesNotOccludeFartherOne() throws {
        // THE ordering obligation. Were the clip tested after the nearest
        // decision, a section view would become unpickable exactly where it is
        // most useful.
        let picked = try #require(
            try pick(
                Fixture(
                    name: "occlusion",
                    candidates: [Self.clippedNear, Self.far],
                    column: 1,
                    row: 2
                )
            )
        )
        #expect(picked.layerIndex == 1)
        #expect(picked.facetOrdinal == 0)
        #expect(picked.worldX == 0.4)
        #expect(picked.worldY == 0.5)
        #expect(picked.worldZ == 0.6)

        // Both ways of having no hit report it by the same rule rather than by
        // two special cases: nothing covered the pixel, and everything covering
        // it was clipped away.
        #expect(
            try pick(
                Fixture(name: "uncovered", candidates: [], column: 1, row: 2)
            ) == nil
        )
        #expect(
            try pick(
                Fixture(
                    name: "all-clipped",
                    candidates: [Self.clippedNear, Self.clippedFar],
                    column: 1,
                    row: 2
                )
            ) == nil
        )
    }

    @Test(
        "[Unit][VOX-SUR-007][VOX-API-003] identity is original-order and the tie-break is inherited"
    )
    func identityIsOriginalOrderAndTieBreakIsInherited() throws {
        // The picked facet's own vertex indices, in the mesh's ORIGINAL
        // topology order: the coverage rule's canonicalisation swap never
        // reaches an identifier.
        let nearest = try #require(
            try pick(
                Fixture(
                    name: "nearest",
                    candidates: [Self.near, Self.far],
                    column: 1,
                    row: 2
                )
            )
        )
        #expect(nearest.firstVertexIndex == 7)
        #expect(nearest.secondVertexIndex == 8)
        #expect(nearest.thirdVertexIndex == 9)

        // Supply order cannot change the answer.
        #expect(
            try pick(
                Fixture(
                    name: "reversed",
                    candidates: [Self.far, Self.near],
                    column: 1,
                    row: 2
                )
            ) == nearest
        )

        // Equal depth keeps the earlier layer, then the earlier facet — the
        // same strict total order the visibility and compositing records use.
        let byLayer = try #require(try pick(Self.tieByLayer))
        #expect(byLayer.layerIndex == 0)
        let byFacet = try #require(try pick(Self.tieByFacet))
        #expect(byFacet.facetOrdinal == 2)

        // A negative depth is pickable: no near plane exists, so a visible
        // fragment behind the camera is still authoritative geometry.
        let behind = try #require(try pick(Self.negativeDepth))
        #expect(behind.layerIndex == 0)
        #expect(behind.worldZ == 2.0)
    }

    @Test(
        "[Unit][VOX-SUR-007][VOX-ERR-001] the pixel bound is exact and out of bounds is rejected typed"
    )
    func pixelBoundIsExactAndOutOfBoundsIsRejectedTyped() throws {
        let viewport = try ViewportSize(width: 4, height: 4)

        // Inclusive at zero, exclusive at the dimension, on both axes.
        for pixel in [(0, 0), (3, 3), (0, 3), (3, 0)] {
            #expect(
                try SurfacePicker.pick(
                    candidates: [Self.near],
                    column: pixel.0,
                    row: pixel.1,
                    viewport: viewport
                ) != nil
            )
        }
        for pixel in [(-1, 0), (4, 0), (0, -1), (0, 4)] {
            #expect(throws: SurfacePickError.pixelOutOfBounds) {
                try SurfacePicker.pick(
                    candidates: [Self.near],
                    column: pixel.0,
                    row: pixel.1,
                    viewport: viewport
                )
            }
        }

        let errors: [SurfacePickError] = [.pixelOutOfBounds]
        #expect(errors.map { String(describing: $0) } == ["pixelOutOfBounds"])
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private static let near = candidate(
        depth: 1.0,
        layer: 0,
        facet: 3,
        world: (0.1, 0.2, 0.3),
        retained: true,
        indices: (7, 8, 9)
    )
    private static let far = candidate(
        depth: 5.0,
        layer: 1,
        facet: 0,
        world: (0.4, 0.5, 0.6),
        retained: true,
        indices: (1, 2, 3)
    )
    private static let clippedNear = candidate(
        depth: 1.0,
        layer: 0,
        facet: 3,
        world: (9.0, 9.0, 9.0),
        retained: false,
        indices: (7, 8, 9)
    )
    private static let clippedFar = candidate(
        depth: 5.0,
        layer: 1,
        facet: 0,
        world: (8.0, 8.0, 8.0),
        retained: false,
        indices: (1, 2, 3)
    )
    private static let tieByLayer = Fixture(
        name: "tie-by-layer",
        candidates: [
            candidate(
                depth: 2.0,
                layer: 1,
                facet: 0,
                world: (1.0, 0.0, 0.0),
                retained: true,
                indices: (4, 5, 6)
            ),
            candidate(
                depth: 2.0,
                layer: 0,
                facet: 0,
                world: (2.0, 0.0, 0.0),
                retained: true,
                indices: (1, 2, 3)
            ),
        ],
        column: 1,
        row: 2
    )
    private static let tieByFacet = Fixture(
        name: "tie-by-facet",
        candidates: [
            candidate(
                depth: 2.0,
                layer: 0,
                facet: 9,
                world: (1.0, 0.0, 0.0),
                retained: true,
                indices: (4, 5, 6)
            ),
            candidate(
                depth: 2.0,
                layer: 0,
                facet: 2,
                world: (2.0, 0.0, 0.0),
                retained: true,
                indices: (1, 2, 3)
            ),
        ],
        column: 1,
        row: 2
    )
    private static let negativeDepth = Fixture(
        name: "negative-depth",
        candidates: [
            candidate(
                depth: -3.0,
                layer: 0,
                facet: 0,
                world: (0.0, 1.0, 2.0),
                retained: true,
                indices: (0, 1, 2)
            ),
            Self.far,
        ],
        column: 1,
        row: 2
    )

    private func analyticalFixtures() -> [Fixture] {
        [
            Fixture(
                name: "nearest-retained",
                candidates: [Self.near, Self.far],
                column: 1,
                row: 2
            ),
            Fixture(
                name: "reverse-supplied",
                candidates: [Self.far, Self.near],
                column: 1,
                row: 2
            ),
            Fixture(
                name: "clipped-does-not-occlude",
                candidates: [Self.clippedNear, Self.far],
                column: 1,
                row: 2
            ),
            Fixture(name: "uncovered", candidates: [], column: 1, row: 2),
            Fixture(
                name: "all-clipped",
                candidates: [Self.clippedNear, Self.clippedFar],
                column: 1,
                row: 2
            ),
            Self.tieByLayer,
            Self.tieByFacet,
            Self.negativeDepth,
            Fixture(
                name: "first-pixel",
                candidates: [Self.near],
                column: 0,
                row: 0
            ),
            Fixture(
                name: "last-pixel",
                candidates: [Self.near],
                column: 3,
                row: 3
            ),
            Fixture(
                name: "out-of-bounds",
                candidates: [Self.near],
                column: 4,
                row: 0
            ),
        ]
    }

    // MARK: - Helpers

    private static func candidate(
        depth: Double,
        layer: Int,
        facet: Int,
        world: (Double, Double, Double),
        retained: Bool,
        indices: (Int, Int, Int)
    ) -> SurfacePickCandidate {
        SurfacePickCandidate(
            depth: depth,
            layerIndex: layer,
            facetOrdinal: facet,
            worldX: world.0,
            worldY: world.1,
            worldZ: world.2,
            retained: retained,
            firstVertexIndex: indices.0,
            secondVertexIndex: indices.1,
            thirdVertexIndex: indices.2
        )
    }

    private func pick(_ fixture: Fixture) throws -> SurfacePick? {
        try SurfacePicker.pick(
            candidates: fixture.candidates,
            column: fixture.column,
            row: fixture.row,
            viewport: try ViewportSize(width: 4, height: 4)
        )
    }

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
