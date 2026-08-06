// SPDX-License-Identifier: MIT

import CryptoKit
import Testing
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("Surface clipper")
struct SurfaceClipperTests {
    private struct Fixture: Sendable {
        typealias Triple = (Double, Double, Double)

        let name: String
        let positions: (Triple, Triple, Triple)
        let weights: (Double, Double, Double)
        let swapped: Bool
        let bounds: ((Double, Double, Double), (Double, Double, Double))?
    }

    @Test(
        "[Oracle][VOX-SUR-006][VOX-NUM-001] all ALG-0038 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in try analyticalFixtures() {
            let decision = try decide(fixture)
            let components = [
                decision.worldX, decision.worldY, decision.worldZ,
            ]
            records.append(
                "\(fixture.name)|kept=\(decision.retained ? 1 : 0)|world="
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

        #expect(records.count == 19)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "8dd30ec41bd27c11bebb15501739a46398294d86ff6e9956fd7aa1be2976e604"
        )
        #expect(
            sha256(payload)
                == "0f0ee1270ffda5115052a0c370ecaae427ba5e2fbc26bb9e8b47e84b53521335"
        )
    }

    @Test(
        "[Unit][VOX-SUR-006][VOX-NUM-001] the boundary is inclusive and the cut is per fragment"
    )
    func boundaryIsInclusiveAndCutIsPerFragment() throws {
        let box = try unitBox()

        // The boundary belongs to the box: faces, edges and corners are all
        // retained, because the box is a closed region.
        for point in [
            (0.0, 0.5, 0.5), (1.0, 0.5, 0.5),
            (0.5, 0.0, 0.5), (0.5, 1.0, 0.5),
            (0.5, 0.5, 0.0), (0.5, 0.5, 1.0),
            (0.0, 0.0, 0.0), (1.0, 1.0, 1.0),
        ] {
            #expect(
                SurfaceClipper.retained(
                    worldX: point.0,
                    worldY: point.1,
                    worldZ: point.2,
                    bounds: box
                )
            )
        }
        // One step outside on any axis is discarded.
        for point in [
            (-0.0000001, 0.5, 0.5), (1.0000001, 0.5, 0.5),
            (0.5, -0.0000001, 0.5), (0.5, 1.0000001, 0.5),
            (0.5, 0.5, -0.0000001), (0.5, 0.5, 1.0000001),
        ] {
            #expect(
                !SurfaceClipper.retained(
                    worldX: point.0,
                    worldY: point.1,
                    worldZ: point.2,
                    bounds: box
                )
            )
        }

        // A straddling facet keeps only its interior fragments, which is what
        // makes an uncapped cut legible: no facet is all-or-nothing.
        let straddling = (
            (-1.0, 0.5, 0.5), (0.5, 0.5, 0.5), (2.0, 0.5, 0.5)
        )
        #expect(
            !(try decide(
                Fixture(
                    name: "a",
                    positions: straddling,
                    weights: (1, 0, 0),
                    swapped: false,
                    bounds: ((0, 0, 0), (1, 1, 1))
                )
            ).retained)
        )
        #expect(
            try decide(
                Fixture(
                    name: "b",
                    positions: straddling,
                    weights: (0, 1, 0),
                    swapped: false,
                    bounds: ((0, 0, 0), (1, 1, 1))
                )
            ).retained
        )

        // An absent clip retains everything, so the unclipped path is the
        // same code with no branch to diverge.
        #expect(
            SurfaceClipper.retained(
                worldX: 1e300,
                worldY: -1e300,
                worldZ: 0,
                bounds: nil
            )
        )
    }

    @Test(
        "[Unit][VOX-SUR-006][VOX-ERR-001] the swap flag and the space admission are exact"
    )
    func swapFlagAndSpaceAdmissionAreExact() throws {
        // The swap flag maps weights back to original vertex order, so a
        // consumer ignoring it would clip the wrong fragments.
        let asymmetric = (
            (0.0, 0.0, 0.0), (4.0, 0.0, 0.0), (0.0, 4.0, 0.0)
        )
        let plain = try decide(
            Fixture(
                name: "p",
                positions: asymmetric,
                weights: (0.5, 0.25, 0.125),
                swapped: false,
                bounds: nil
            )
        )
        let mapped = try decide(
            Fixture(
                name: "m",
                positions: asymmetric,
                weights: (0.5, 0.25, 0.125),
                swapped: true,
                bounds: nil
            )
        )
        #expect(plain.worldX != mapped.worldX)
        #expect(plain.worldY != mapped.worldY)

        // The clip must be declared in the scene's world space.
        let world = try #require(CoordinateSpaceID(rawValue: "patient-world"))
        let other = try #require(CoordinateSpaceID(rawValue: "table-world"))
        let box = try unitBox(in: world)
        try SurfaceClipper.admit(bounds: box, worldSpace: world)
        #expect(throws: SurfaceClipError.coordinateSpaceMismatch) {
            try SurfaceClipper.admit(bounds: box, worldSpace: other)
        }
        // An absent clip or an empty scene imposes no constraint.
        try SurfaceClipper.admit(bounds: nil, worldSpace: other)
        try SurfaceClipper.admit(bounds: box, worldSpace: nil)

        let errors: [SurfaceClipError] = [.coordinateSpaceMismatch, .cancelled]
        #expect(
            errors.map { String(describing: $0) } == [
                "coordinateSpaceMismatch", "cancelled",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private func analyticalFixtures() throws -> [Fixture] {
        let thirds = (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)
        let unit: ((Double, Double, Double), (Double, Double, Double))? = (
            (0, 0, 0), (1, 1, 1)
        )
        let straddling = (
            (-1.0, 0.5, 0.5), (0.5, 0.5, 0.5), (2.0, 0.5, 0.5)
        )
        let asymmetric = (
            (0.0, 0.0, 0.0), (4.0, 0.0, 0.0), (0.0, 4.0, 0.0)
        )
        let negative: ((Double, Double, Double), (Double, Double, Double))? = (
            (-2, -2, -2), (-1, -1, -1)
        )
        func uniformFixture(
            _ name: String,
            _ point: (Double, Double, Double),
            bounds: ((Double, Double, Double), (Double, Double, Double))? = nil,
            useUnit: Bool = true
        ) -> Fixture {
            Fixture(
                name: name,
                positions: (point, point, point),
                weights: thirds,
                swapped: false,
                bounds: bounds ?? (useUnit ? unit : nil)
            )
        }
        var fixtures: [Fixture] = [
            uniformFixture("inside", (0.5, 0.5, 0.5)),
            uniformFixture("on-near-face", (0.0, 0.5, 0.5)),
            uniformFixture("on-far-face", (0.5, 1.0, 0.5)),
            uniformFixture("on-near-corner", (0.0, 0.0, 0.0)),
            uniformFixture("on-far-corner", (1.0, 1.0, 1.0)),
            Fixture(
                name: "straddling-first",
                positions: straddling,
                weights: (1, 0, 0),
                swapped: false,
                bounds: unit
            ),
            Fixture(
                name: "straddling-second",
                positions: straddling,
                weights: (0, 1, 0),
                swapped: false,
                bounds: unit
            ),
            Fixture(
                name: "straddling-third",
                positions: straddling,
                weights: (0, 0, 1),
                swapped: false,
                bounds: unit
            ),
            Fixture(
                name: "skewed-weights",
                positions: straddling,
                weights: (0.5, 0.25, 0.25),
                swapped: false,
                bounds: unit
            ),
            Fixture(
                name: "swapped-weights",
                positions: asymmetric,
                weights: (0.5, 0.25, 0.125),
                swapped: true,
                bounds: unit
            ),
            uniformFixture("no-clip", (99.0, 99.0, 99.0), useUnit: false),
            uniformFixture(
                "inside-negative-box",
                (-1.5, -1.5, -1.5),
                bounds: negative
            ),
            uniformFixture(
                "outside-negative-box",
                (0.0, 0.0, 0.0),
                bounds: negative
            ),
        ]
        // Six outside cases, one per box face, in the oracle's own order.
        var index = 0
        for lane in 0..<3 {
            for offset in [-1.0, 2.0] {
                var point = [0.5, 0.5, 0.5]
                point[lane] = offset
                fixtures.append(
                    uniformFixture(
                        "outside-\(index)",
                        (point[0], point[1], point[2])
                    )
                )
                index += 1
            }
        }
        return fixtures
    }

    // MARK: - Helpers

    private func decide(_ fixture: Fixture) throws -> ClipDecision {
        SurfaceClipper.decide(
            first: vertex(fixture.positions.0),
            second: vertex(fixture.positions.1),
            third: vertex(fixture.positions.2),
            weightA: fixture.weights.0,
            weightB: fixture.weights.1,
            weightC: fixture.weights.2,
            swapped: fixture.swapped,
            bounds: try fixture.bounds.map {
                try box(minimum: $0.0, maximum: $0.1)
            }
        )
    }

    private func vertex(_ world: (Double, Double, Double)) -> ProjectedVertex {
        ProjectedVertex(
            column: 0,
            row: 0,
            depth: 0,
            worldX: world.0,
            worldY: world.1,
            worldZ: world.2
        )
    }

    private func unitBox(
        in space: CoordinateSpaceID? = nil
    ) throws -> VolumeClipBounds {
        try box(minimum: (0, 0, 0), maximum: (1, 1, 1), in: space)
    }

    private func box(
        minimum: (Double, Double, Double),
        maximum: (Double, Double, Double),
        in space: CoordinateSpaceID? = nil
    ) throws -> VolumeClipBounds {
        let identifier =
            try space
            ?? #require(CoordinateSpaceID(rawValue: "patient-world"))
        return try VolumeClipBounds(
            minimum: try Point3D(
                x: minimum.0,
                y: minimum.1,
                z: minimum.2,
                coordinateSpace: identifier
            ),
            maximum: try Point3D(
                x: maximum.0,
                y: maximum.1,
                z: maximum.2,
                coordinateSpace: identifier
            )
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
