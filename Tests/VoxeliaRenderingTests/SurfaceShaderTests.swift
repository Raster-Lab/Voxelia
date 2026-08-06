// SPDX-License-Identifier: MIT

import CryptoKit
import Testing

@testable import VoxeliaRendering

@Suite("Surface shader")
struct SurfaceShaderTests {
    private struct Fixture: Sendable {
        let name: String
        let normals: (ShadingDirection, ShadingDirection, ShadingDirection)
        let weights: (Double, Double, Double)
        let forward: ShadingDirection
    }

    @Test(
        "[Oracle][VOX-SUR-004][VOX-NUM-001] all ALG-0036 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            let intensity = shade(fixture)
            records.append(
                "\(fixture.name)|intensity="
                    + hexadecimal(intensity.bitPattern, width: 16)
            )
            payload.append(
                contentsOf: littleEndianBytes(intensity.bitPattern)
            )
        }

        #expect(records.count == 14)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "a1f8fd3ff7933c12bcd269b94c05d2919fb78801bf99fabf15dc29b7f0514330"
        )
        #expect(
            sha256(payload)
                == "c9dfc8df1e26cf1c4ebff61561fbc9c030290ecd426d79e72193fdb54c22cd37"
        )
    }

    @Test(
        "[Unit][VOX-SUR-004][VOX-NUM-001] the frozen shading rules hold exactly"
    )
    func frozenShadingRulesHoldExactly() {
        let forwardZ = direction(0, 0, 1)

        // Facing and facing away are lit IDENTICALLY: the material is
        // two-sided, so an open surface's interior is never black.
        let facing = shade(uniform(direction(0, 0, -1)), forward: forwardZ)
        let away = shade(uniform(direction(0, 0, 1)), forward: forwardZ)
        #expect(facing == 1)
        #expect(away == 1)
        #expect(facing == away)

        // Edge-on is unlit.
        #expect(shade(uniform(direction(1, 0, 0)), forward: forwardZ) == 0)

        // Exactly cancelling normals leave an undefined direction, which
        // yields positive zero rather than failing.
        let cancelling = SurfaceShader.intensity(
            first: direction(0, 0, 1),
            second: direction(0, 0, -1),
            third: direction(1, 0, 0),
            weightA: 0.5,
            weightB: 0.5,
            weightC: 0,
            swapped: false,
            forward: forwardZ
        )
        #expect(cancelling.bitPattern == (0.0).bitPattern)

        // The clamp is reachable: a unit normal's self-projection rounds above
        // one, so an exact clamp is required rather than defensive.
        let steep = direction(
            -0x1.c49bee0b8ed14p-1,
            0x1.e74ee6deceb80p-7,
            -0x1.d99abcf4ffae6p-1
        )
        let unit = normalise(steep)
        #expect(rawProjection(unit, unit) > 1)
        #expect(
            SurfaceShader.intensity(
                first: steep,
                second: steep,
                third: steep,
                weightA: 1.0 / 3.0,
                weightB: 1.0 / 3.0,
                weightC: 1.0 / 3.0,
                swapped: false,
                forward: unit
            ) == 1
        )

        // A least-subnormal normal underflows during INTERPOLATION at one
        // third, but survives at full weight — the loss is in the
        // interpolation, not the normalisation.
        let tiny = direction(0, 0, -Double.leastNonzeroMagnitude)
        #expect(shade(uniform(tiny), forward: forwardZ).bitPattern == 0)
        #expect(
            SurfaceShader.intensity(
                first: tiny,
                second: tiny,
                third: tiny,
                weightA: 1,
                weightB: 0,
                weightC: 0,
                swapped: false,
                forward: forwardZ
            ) == 1
        )
    }

    @Test(
        "[Unit][VOX-SUR-004][VOX-GEO-009] the swap flag maps weights to original vertices"
    )
    func swapFlagMapsWeightsToOriginalVertices() {
        let forwardZ = direction(0, 0, 1)
        let first = direction(1, 0, 0)
        let second = direction(0, 0, -1)
        let third = direction(0, 0.6, -0.8)

        // With the flag clear, the weights apply in the supplied order.
        let straight = SurfaceShader.intensity(
            first: first,
            second: second,
            third: third,
            weightA: 0.5,
            weightB: 0.25,
            weightC: 0.125,
            swapped: false,
            forward: forwardZ
        )
        // With the flag set, the second and third weights exchange — which is
        // exactly what a consumer ignoring the flag would get wrong.
        let swapped = SurfaceShader.intensity(
            first: first,
            second: second,
            third: third,
            weightA: 0.5,
            weightB: 0.25,
            weightC: 0.125,
            swapped: true,
            forward: forwardZ
        )
        #expect(straight != swapped)

        // Setting the flag is equivalent to exchanging the two weights by hand.
        let manual = SurfaceShader.intensity(
            first: first,
            second: second,
            third: third,
            weightA: 0.5,
            weightB: 0.125,
            weightC: 0.25,
            swapped: false,
            forward: forwardZ
        )
        #expect(swapped == manual)

        let errors: [SurfaceShadingError] = [.normalsMissing, .cancelled]
        #expect(
            errors.map { String(describing: $0) } == [
                "normalsMissing", "cancelled",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private func analyticalFixtures() -> [Fixture] {
        let forwardZ = direction(0, 0, 1)
        let thirds = (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)
        let mixed = (
            direction(0, 0, -1), direction(1, 0, 0), direction(0, 1, 0)
        )
        let steep = direction(
            -0x1.c49bee0b8ed14p-1,
            0x1.e74ee6deceb80p-7,
            -0x1.d99abcf4ffae6p-1
        )
        let tiny = direction(0, 0, -Double.leastNonzeroMagnitude)
        let obliqueForward = ShadingDirection(
            x: 1 / (3.0).squareRoot(),
            y: 1 / (3.0).squareRoot(),
            z: 1 / (3.0).squareRoot()
        )
        let skew = (
            direction(1, 0, 0), direction(0, 0, -1), direction(0, 0.6, -0.8)
        )
        let skewWeights = (0.5, 0.25, 0.125)
        return [
            Fixture(
                name: "facing-camera",
                normals: uniform(direction(0, 0, -1)),
                weights: thirds,
                forward: forwardZ
            ),
            Fixture(
                name: "facing-away",
                normals: uniform(direction(0, 0, 1)),
                weights: thirds,
                forward: forwardZ
            ),
            Fixture(
                name: "edge-on",
                normals: uniform(direction(1, 0, 0)),
                weights: thirds,
                forward: forwardZ
            ),
            Fixture(
                name: "forty-five",
                normals: uniform(direction(0, 1, 1)),
                weights: thirds,
                forward: forwardZ
            ),
            Fixture(
                name: "weight-at-first-vertex",
                normals: mixed,
                weights: (1, 0, 0),
                forward: forwardZ
            ),
            Fixture(
                name: "weight-at-second-vertex",
                normals: mixed,
                weights: (0, 1, 0),
                forward: forwardZ
            ),
            Fixture(
                name: "interpolated",
                normals: mixed,
                weights: thirds,
                forward: forwardZ
            ),
            Fixture(
                name: "cancelling-normals",
                normals: (
                    direction(0, 0, 1), direction(0, 0, -1), direction(1, 0, 0)
                ),
                weights: (0.5, 0.5, 0),
                forward: forwardZ
            ),
            Fixture(
                name: "rounding-clamped",
                normals: uniform(steep),
                weights: thirds,
                forward: normalise(steep)
            ),
            Fixture(
                name: "subnormal-underflows",
                normals: uniform(tiny),
                weights: thirds,
                forward: forwardZ
            ),
            Fixture(
                name: "subnormal-at-vertex",
                normals: uniform(tiny),
                weights: (1, 0, 0),
                forward: forwardZ
            ),
            Fixture(
                name: "oblique-forward",
                normals: uniform(direction(0, 0, -1)),
                weights: thirds,
                forward: obliqueForward
            ),
            Fixture(
                name: "skewed-weights",
                normals: skew,
                weights: skewWeights,
                forward: forwardZ
            ),
            Fixture(
                name: "mis-mapped-weights",
                normals: (skew.0, skew.2, skew.1),
                weights: skewWeights,
                forward: forwardZ
            ),
        ]
    }

    // MARK: - Helpers

    private func direction(
        _ x: Double,
        _ y: Double,
        _ z: Double
    ) -> ShadingDirection {
        ShadingDirection(x: x, y: y, z: z)
    }

    private func uniform(
        _ normal: ShadingDirection
    ) -> (ShadingDirection, ShadingDirection, ShadingDirection) {
        (normal, normal, normal)
    }

    private func shade(_ fixture: Fixture) -> Double {
        SurfaceShader.intensity(
            first: fixture.normals.0,
            second: fixture.normals.1,
            third: fixture.normals.2,
            weightA: fixture.weights.0,
            weightB: fixture.weights.1,
            weightC: fixture.weights.2,
            swapped: false,
            forward: fixture.forward
        )
    }

    private func shade(
        _ normals: (ShadingDirection, ShadingDirection, ShadingDirection),
        forward: ShadingDirection
    ) -> Double {
        SurfaceShader.intensity(
            first: normals.0,
            second: normals.1,
            third: normals.2,
            weightA: 1.0 / 3.0,
            weightB: 1.0 / 3.0,
            weightC: 1.0 / 3.0,
            swapped: false,
            forward: forward
        )
    }

    private func normalise(_ v: ShadingDirection) -> ShadingDirection {
        let scale = max(max(abs(v.x), abs(v.y)), abs(v.z))
        let sx = v.x / scale
        let sy = v.y / scale
        let sz = v.z / scale
        let sum = (sx * sx + sy * sy) + sz * sz
        let length = sum.squareRoot()
        return ShadingDirection(x: sx / length, y: sy / length, z: sz / length)
    }

    private func rawProjection(
        _ a: ShadingDirection,
        _ b: ShadingDirection
    ) -> Double {
        (a.x * b.x + a.y * b.y) + a.z * b.z
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
