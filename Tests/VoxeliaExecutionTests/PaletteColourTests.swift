// SPDX-License-Identifier: MIT

import CryptoKit
import Testing
import VoxeliaCore

@testable import VoxeliaExecution

@Suite("Palette colour")
struct PaletteColourTests {
    private struct Table: Sendable {
        let first: Int64
        let values: [Double]
    }

    private struct Fixture: Sendable {
        let name: String
        let stored: Int64
        let red: Table
        let green: Table
        let blue: Table
    }

    @Test(
        "[Oracle][VOX-R2D-010][VOX-NUM-001] all ALG-0043 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let pixel = try map(fixture)
                records.append(
                    "\(fixture.name)|rgba=\(pixel.red),\(pixel.green),"
                        + "\(pixel.blue),\(pixel.alpha)"
                )
                payload.append(
                    contentsOf: [
                        pixel.red, pixel.green, pixel.blue, pixel.alpha,
                    ]
                )
            } catch let error as PaletteColourError {
                records.append("\(fixture.name)|error=\(error)")
            }
        }

        #expect(records.count == 15)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "76d9f8943c52f28b7156ab69c2dd9000e7dc137d526f597ba87a9756fa6a2e65"
        )
        #expect(
            sha256(payload)
                == "98d9464166ab8c01ac5c266b4d29ea56684e1b2b7d38504d9c073de715105160"
        )
    }

    @Test(
        "[Unit][VOX-R2D-010][VOX-API-003] each channel comes from its own table and alpha is opaque"
    )
    func eachChannelComesFromItsOwnTableAndAlphaIsOpaque() throws {
        let red = Table(first: 10, values: [0, 255, 0, 0])
        let green = Table(first: 10, values: [0, 0, 255, 0])
        let blue = Table(first: 10, values: [0, 0, 0, 255])

        // A swapped pair of tables would change every one of these.
        #expect(
            try map(11, red, green, blue)
                == pixel(255, 0, 0, 255)
        )
        #expect(
            try map(12, red, green, blue)
                == pixel(0, 255, 0, 255)
        )
        #expect(
            try map(13, red, green, blue)
                == pixel(0, 0, 255, 255)
        )

        // Alpha is exactly opaque even where every colour channel is zero: a
        // palette-colour image is an image, not an overlay.
        #expect(
            try map(10, red, green, blue)
                == pixel(0, 0, 0, 255)
        )
    }

    @Test(
        "[Unit][VOX-R2D-010][VOX-NUM-001] both ends clamp and both origin extremes are safe"
    )
    func bothEndsClampAndBothOriginExtremesAreSafe() throws {
        let red = Table(first: 10, values: [0, 255, 0, 0])
        let green = Table(first: 10, values: [0, 0, 255, 0])
        let blue = Table(first: 10, values: [0, 0, 0, 255])

        #expect(try map(-1000, red, green, blue) == pixel(0, 0, 0, 255))
        #expect(try map(1000, red, green, blue) == pixel(0, 0, 255, 255))

        // An overflowing difference lies beyond the representable range on the
        // side opposite the origin's sign, so it clamps to that same end.
        let lowOrigin = { (values: [Double]) in
            Table(first: Int64.min, values: values)
        }
        #expect(
            try map(
                0,
                lowOrigin([1, 2]),
                lowOrigin([3, 4]),
                lowOrigin([5, 6])
            ) == pixel(2, 4, 6, 255)
        )
        let highOrigin = { (values: [Double]) in
            Table(first: Int64.max, values: values)
        }
        #expect(
            try map(
                0,
                highOrigin([1, 2]),
                highOrigin([3, 4]),
                highOrigin([5, 6])
            ) == pixel(1, 3, 5, 255)
        )
    }

    @Test(
        "[Unit][VOX-R2D-010][VOX-ERR-001] entries are display values and the shape check is exact"
    )
    func entriesAreDisplayValuesAndShapeCheckIsExact() throws {
        // Out-of-range entries saturate rather than rescaling a palette the
        // source author already calibrated, and quantisation rounds ties to
        // even — the accepted display-output rule.
        #expect(
            try map(
                0,
                Table(first: 0, values: [-5]),
                Table(first: 0, values: [300]),
                Table(first: 0, values: [0.5])
            ) == pixel(0, 255, 0, 255)
        )
        #expect(
            try map(
                0,
                Table(first: 0, values: [1.5]),
                Table(first: 0, values: [2.5]),
                Table(first: 0, values: [3.5])
            ) == pixel(2, 2, 4, 255)
        )

        // Three differently shaped tables would let a red channel come from a
        // different stored value than its own green, so both ways of
        // disagreeing are rejected rather than reconciled.
        #expect(throws: PaletteColourError.paletteShapeMismatch) {
            try map(
                0,
                Table(first: 0, values: [1, 2]),
                Table(first: 0, values: [1]),
                Table(first: 0, values: [1, 2])
            )
        }
        #expect(throws: PaletteColourError.paletteShapeMismatch) {
            try map(
                0,
                Table(first: 0, values: [1]),
                Table(first: 1, values: [1]),
                Table(first: 0, values: [1])
            )
        }
        #expect(throws: PaletteColourError.emptyTable) {
            try map(
                0,
                Table(first: 0, values: []),
                Table(first: 0, values: []),
                Table(first: 0, values: [])
            )
        }

        let errors: [PaletteColourError] = [.emptyTable, .paletteShapeMismatch]
        #expect(
            errors.map { String(describing: $0) } == [
                "emptyTable", "paletteShapeMismatch",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private func analyticalFixtures() -> [Fixture] {
        let red = Table(first: 10, values: [0, 255, 0, 0])
        let green = Table(first: 10, values: [0, 0, 255, 0])
        let blue = Table(first: 10, values: [0, 0, 0, 255])
        func single(_ value: Double) -> Table {
            Table(first: 0, values: [value])
        }
        func fixture(
            _ name: String,
            _ stored: Int64,
            _ tables: (Table, Table, Table)
        ) -> Fixture {
            Fixture(
                name: name,
                stored: stored,
                red: tables.0,
                green: tables.1,
                blue: tables.2
            )
        }
        let ramp = (red, green, blue)
        let low = (
            Table(first: Int64.min, values: [1, 2]),
            Table(first: Int64.min, values: [3, 4]),
            Table(first: Int64.min, values: [5, 6])
        )
        let high = (
            Table(first: Int64.max, values: [1, 2]),
            Table(first: Int64.max, values: [3, 4]),
            Table(first: Int64.max, values: [5, 6])
        )
        return [
            fixture("first-entry", 10, ramp),
            fixture("red-entry", 11, ramp),
            fixture("green-entry", 12, ramp),
            fixture("blue-entry", 13, ramp),
            fixture("below-range", -1000, ramp),
            fixture("above-range", 1000, ramp),
            fixture("origin-at-int64-min", 0, low),
            fixture("origin-at-int64-max", 0, high),
            fixture(
                "negative-origin",
                -2,
                (
                    Table(first: -3, values: [7, 8]),
                    Table(first: -3, values: [9, 10]),
                    Table(first: -3, values: [11, 12])
                )
            ),
            fixture(
                "output-clamp-and-tie-down",
                0,
                (single(-5), single(300), single(0.5))
            ),
            fixture(
                "output-ties-even",
                0,
                (single(1.5), single(2.5), single(3.5))
            ),
            fixture(
                "single-entry",
                999,
                (single(42), single(43), single(44))
            ),
            fixture(
                "count-mismatch",
                0,
                (
                    Table(first: 0, values: [1, 2]),
                    Table(first: 0, values: [1]),
                    Table(first: 0, values: [1, 2])
                )
            ),
            fixture(
                "origin-mismatch",
                0,
                (
                    Table(first: 0, values: [1]),
                    Table(first: 1, values: [1]),
                    Table(first: 0, values: [1])
                )
            ),
            fixture(
                "empty-table",
                0,
                (
                    Table(first: 0, values: []),
                    Table(first: 0, values: []),
                    Table(first: 0, values: [])
                )
            ),
        ]
    }

    // MARK: - Helpers

    private func map(_ fixture: Fixture) throws -> DisplayPixelRGBA8 {
        try map(fixture.stored, fixture.red, fixture.green, fixture.blue)
    }

    private func map(
        _ stored: Int64,
        _ red: Table,
        _ green: Table,
        _ blue: Table
    ) throws -> DisplayPixelRGBA8 {
        try PaletteColour.map(
            stored: stored,
            red: try descriptor(red),
            green: try descriptor(green),
            blue: try descriptor(blue)
        )
    }

    private func descriptor(_ table: Table) throws -> LookupTableDescriptor {
        try LookupTableDescriptor(
            firstMappedValue: table.first,
            values: table.values,
            outputUnit: nil
        )
    }

    private func pixel(
        _ red: UInt8,
        _ green: UInt8,
        _ blue: UInt8,
        _ alpha: UInt8
    ) -> DisplayPixelRGBA8 {
        DisplayPixelRGBA8(red: red, green: green, blue: blue, alpha: alpha)
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
