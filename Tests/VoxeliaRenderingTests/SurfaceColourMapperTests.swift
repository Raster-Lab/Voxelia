// SPDX-License-Identifier: MIT

import CryptoKit
import Testing

@testable import VoxeliaRendering

@Suite("Surface colour mapper")
struct SurfaceColourMapperTests {
    private struct Fixture: Sendable {
        let name: String
        let scalars: (Double, Double, Double)
        let weights: (Double, Double, Double)
        let domain: (minimum: Double, maximum: Double)
        let entries: ContiguousArray<TransferFunctionEntry>
        let intensity: Double
        let layerOpacity: Double
    }

    @Test(
        "[Oracle][VOX-SUR-005][VOX-NUM-001] all ALG-0037 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let colour = try evaluate(fixture)
                let index = SurfaceColourMapper.index(
                    of: SurfaceColourMapper.interpolated(
                        scalars: fixture.scalars,
                        weights: fixture.weights,
                        swapped: false
                    ),
                    domain: fixture.domain,
                    count: fixture.entries.count
                )
                let components = [
                    colour.red, colour.green, colour.blue,
                    colour.effectiveOpacity,
                ]
                records.append(
                    "\(fixture.name)|index=\(index)|rgba="
                        + components.map {
                            hexadecimal($0.bitPattern, width: 16)
                        }.joined(separator: ",")
                )
                for component in components {
                    payload.append(
                        contentsOf: littleEndianBytes(component.bitPattern)
                    )
                }
            } catch let error as SurfaceColourMapError {
                records.append("\(fixture.name)|error=\(errorName(error))")
            }
        }

        #expect(records.count == 16)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "1c6b807ea1bc930d00398946db2342476258c799732aeb81492fbd00fe62a63f"
        )
        #expect(
            sha256(payload)
                == "0337dbc24117ac54e875c838ef2703d7813917eefc43ff24f59edaacfd72d506"
        )
    }

    @Test(
        "[Unit][VOX-SUR-005][VOX-SUR-003] the frozen mapping and opacity rules hold exactly"
    )
    func frozenMappingAndOpacityRulesHoldExactly() throws {
        let ramp = greyRamp
        let domain = (minimum: 0.0, maximum: 1.0)

        // Out-of-domain scalars clamp at both ends: the clamp is what makes
        // the mapping total, so there is no out-of-domain failure.
        #expect(
            SurfaceColourMapper.index(of: -1e300, domain: domain, count: 4) == 0
        )
        #expect(
            SurfaceColourMapper.index(of: 1e300, domain: domain, count: 4) == 3
        )

        // Zero intensity darkens the colour to zero but leaves opacity
        // intact, so a fully shadowed surface still occludes what is behind
        // it. That is what makes shading a lighting effect.
        let dark = try SurfaceColourMapper.evaluate(
            scalars: (1, 1, 1),
            weights: (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0),
            swapped: false,
            domain: domain,
            entries: [
                TransferFunctionEntry(
                    red: 200,
                    green: 100,
                    blue: 50,
                    opacity: 128
                )
            ],
            intensity: 0,
            layerOpacity: 1
        )
        #expect(dark.red == 0)
        #expect(dark.green == 0)
        #expect(dark.blue == 0)
        #expect(dark.effectiveOpacity == 128.0 / 255.0)

        // Per-object and per-value opacity multiply, in that order.
        let layered = try SurfaceColourMapper.evaluate(
            scalars: (1, 1, 1),
            weights: (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0),
            swapped: false,
            domain: domain,
            entries: [
                TransferFunctionEntry(
                    red: 255,
                    green: 255,
                    blue: 255,
                    opacity: 128
                )
            ],
            intensity: 1,
            layerOpacity: 0.5
        )
        #expect(layered.effectiveOpacity == 0.5 * (128.0 / 255.0))

        // The swap flag maps weights back to original vertex order, exactly
        // as it does for shading.
        let straight = SurfaceColourMapper.interpolated(
            scalars: (0, 1, 2),
            weights: (0.5, 0.25, 0.125),
            swapped: false
        )
        let swapped = SurfaceColourMapper.interpolated(
            scalars: (0, 1, 2),
            weights: (0.5, 0.25, 0.125),
            swapped: true
        )
        #expect(straight != swapped)
        #expect(
            swapped
                == SurfaceColourMapper.interpolated(
                    scalars: (0, 1, 2),
                    weights: (0.5, 0.125, 0.25),
                    swapped: false
                )
        )

        // Admission: per-request checks precede the per-fragment scalar, so a
        // bad domain is reported even when the scalar is also unusable.
        #expect(throws: SurfaceColourMapError.invalidDomain) {
            _ = try SurfaceColourMapper.evaluate(
                scalars: (.nan, 0, 0),
                weights: (1, 0, 0),
                swapped: false,
                domain: (minimum: 1, maximum: 1),
                entries: ramp,
                intensity: 1,
                layerOpacity: 1
            )
        }
        #expect(throws: SurfaceColourMapError.invalidTable) {
            _ = try SurfaceColourMapper.evaluate(
                scalars: (.nan, 0, 0),
                weights: (1, 0, 0),
                swapped: false,
                domain: domain,
                entries: [],
                intensity: 1,
                layerOpacity: 1
            )
        }
        #expect(throws: SurfaceColourMapError.scalarNotRepresentable) {
            _ = try SurfaceColourMapper.evaluate(
                scalars: (.infinity, 0, 0),
                weights: (1, 0, 0),
                swapped: false,
                domain: domain,
                entries: ramp,
                intensity: 1,
                layerOpacity: 1
            )
        }
    }

    @Test(
        "[Unit][VOX-SUR-005][VOX-ERR-001] the accepted table composes and discharges one case"
    )
    func acceptedTableComposesAndDischargesOneCase() throws {
        // TransferFunction1D admits exactly 256 entries, so the empty-table
        // case cannot arise through this overload — the type's own admission
        // discharges it.
        #expect(TransferFunction1D.tableSize == 256)
        var entries = ContiguousArray<TransferFunctionEntry>()
        entries.reserveCapacity(256)
        for value in 0..<256 {
            entries.append(
                TransferFunctionEntry(
                    red: UInt8(value),
                    green: UInt8(255 - value),
                    blue: 0,
                    opacity: 255
                )
            )
        }
        let table = try TransferFunction1D(entries: entries)

        // The domain maps onto the full 256-entry table, so the minimum picks
        // entry zero and the maximum picks entry 255.
        let low = try SurfaceColourMapper.evaluate(
            scalars: (0, 0, 0),
            weights: (1, 0, 0),
            swapped: false,
            domain: (minimum: 0, maximum: 1),
            table: table,
            intensity: 1,
            layerOpacity: 1
        )
        let high = try SurfaceColourMapper.evaluate(
            scalars: (1, 1, 1),
            weights: (1, 0, 0),
            swapped: false,
            domain: (minimum: 0, maximum: 1),
            table: table,
            intensity: 1,
            layerOpacity: 1
        )
        #expect(low.red == 0)
        #expect(low.green == 1)
        #expect(high.red == 1)
        #expect(high.green == 0)

        // The table's own clamp rule and this model's agree.
        #expect(table.entry(at: -5) == entries[0])
        #expect(table.entry(at: 9_000) == entries[255])
        #expect(
            SurfaceColourMapper.index(
                of: -1e300,
                domain: (minimum: 0, maximum: 1),
                count: 256
            ) == 0
        )
        #expect(
            SurfaceColourMapper.index(
                of: 1e300,
                domain: (minimum: 0, maximum: 1),
                count: 256
            ) == 255
        )

        let errors: [SurfaceColourMapError] = [
            .invalidDomain, .invalidTable, .scalarNotRepresentable, .cancelled,
        ]
        #expect(
            errors.map { String(describing: $0) } == [
                "invalidDomain", "invalidTable", "scalarNotRepresentable",
                "cancelled",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private var greyRamp: ContiguousArray<TransferFunctionEntry> {
        ContiguousArray(
            [0, 85, 170, 255].map {
                TransferFunctionEntry(
                    red: UInt8($0),
                    green: UInt8($0),
                    blue: UInt8($0),
                    opacity: 255
                )
            }
        )
    }

    private func analyticalFixtures() -> [Fixture] {
        let ramp = greyRamp
        let single: ContiguousArray<TransferFunctionEntry> = [
            TransferFunctionEntry(red: 10, green: 20, blue: 30, opacity: 40)
        ]
        let shaded: ContiguousArray<TransferFunctionEntry> = [
            TransferFunctionEntry(red: 200, green: 100, blue: 50, opacity: 128)
        ]
        let half: ContiguousArray<TransferFunctionEntry> = [
            TransferFunctionEntry(
                red: 255,
                green: 255,
                blue: 255,
                opacity: 128
            )
        ]
        func fixture(
            _ name: String,
            _ scalars: (Double, Double, Double),
            _ weights: (Double, Double, Double) = (
                1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0
            ),
            domain: (minimum: Double, maximum: Double) = (0.0, 1.0),
            entries: ContiguousArray<TransferFunctionEntry>? = nil,
            intensity: Double = 1,
            layerOpacity: Double = 1
        ) -> Fixture {
            Fixture(
                name: name,
                scalars: scalars,
                weights: weights,
                domain: domain,
                entries: entries ?? ramp,
                intensity: intensity,
                layerOpacity: layerOpacity
            )
        }
        return [
            fixture("at-domain-minimum", (0, 0, 0)),
            fixture("at-domain-maximum", (1, 1, 1)),
            fixture(
                "halfway-rounds-away",
                (1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0)
            ),
            fixture("below-domain-clamps", (-5, -5, -5)),
            fixture("above-domain-clamps", (5, 5, 5)),
            fixture("single-entry-table", (0.7, 0.7, 0.7), entries: single),
            fixture("fully-lit", (1, 1, 1), entries: shaded),
            fixture("half-lit", (1, 1, 1), entries: shaded, intensity: 0.5),
            fixture(
                "zero-intensity-keeps-opacity",
                (1, 1, 1),
                entries: shaded,
                intensity: 0
            ),
            fixture(
                "layer-and-entry-opacity",
                (1, 1, 1),
                entries: half,
                layerOpacity: 0.5
            ),
            fixture("interpolated-scalar", (0, 1, 0)),
            fixture("skewed-weights", (0, 1, 0), (0, 1, 0)),
            fixture(
                "negative-domain",
                (-500, -500, -500),
                domain: (minimum: -1000, maximum: 0)
            ),
            fixture(
                "degenerate-domain",
                (0.5, 0.5, 0.5),
                domain: (minimum: 1, maximum: 1)
            ),
            fixture("non-finite-scalar", (.nan, 0, 0), (1, 0, 0)),
            fixture("empty-table", (0.5, 0.5, 0.5), entries: []),
        ]
    }

    // MARK: - Helpers

    private func evaluate(_ fixture: Fixture) throws -> SurfaceColour {
        try SurfaceColourMapper.evaluate(
            scalars: fixture.scalars,
            weights: fixture.weights,
            swapped: false,
            domain: fixture.domain,
            entries: fixture.entries,
            intensity: fixture.intensity,
            layerOpacity: fixture.layerOpacity
        )
    }

    private func littleEndianBytes(_ bitPattern: UInt64) -> [UInt8] {
        (0..<8).map { byteIndex in
            UInt8(truncatingIfNeeded: bitPattern >> UInt64(byteIndex * 8))
        }
    }

    private func errorName(_ error: SurfaceColourMapError) -> String {
        switch error {
        case .invalidDomain: "invalidDomain"
        case .invalidTable: "invalidTable"
        case .scalarNotRepresentable: "scalarNotRepresentable"
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
