// SPDX-License-Identifier: MIT

import CryptoKit
import Testing
import VoxeliaCore

@testable import VoxeliaExecution

@Suite("VOI lookup")
struct VOILookupTests {
    private struct Fixture: Sendable {
        let name: String
        let value: Double
        let firstMappedValue: Int64
        let values: [Double]
    }

    @Test(
        "[Oracle][VOX-R2D-007][VOX-NUM-001] all ALG-0042 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let output = try map(fixture)
                records.append("\(fixture.name)|output=\(output)")
                payload.append(output)
            } catch let error as VOILookupError {
                records.append("\(fixture.name)|error=\(error)")
            }
        }

        #expect(records.count == 23)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "a88c27632f2f73645243ca5dda7b365665a8e80f79c9877a50304664d48d34c7"
        )
        #expect(
            sha256(payload)
                == "e8f03a49b1f9fdc024827f77ebbc489628f453acd11168de60ea7de3d35781f8"
        )
    }

    @Test(
        "[Unit][VOX-R2D-007][VOX-NUM-001] index selection rounds half away from zero"
    )
    func indexSelectionRoundsHalfAwayFromZero() throws {
        let ramp = [0.0, 64.0, 128.0, 192.0, 255.0]

        // The two accepted rounding rules disagree here, and the index stage
        // uses the one frozen for choosing a table entry: 12.5 selects entry
        // three, where round-ties-to-even would have selected entry two.
        #expect(try map(12.5, first: 10, values: ramp) == 192)
        #expect(try map(11.5, first: 10, values: ramp) == 128)
        #expect(try map(12.0, first: 10, values: ramp) == 128)

        // The inherited quirk, reproduced rather than silently differed from:
        // the double just below one half rounds up, because the sum is exactly
        // representable as one. Correcting it would be a second rounding rule.
        #expect(
            try map(0.499_999_999_999_999_94, first: 0, values: ramp) == 64
        )

        // A negative origin rounds away from zero on the negative side too.
        #expect(try map(-2.5, first: -3, values: ramp) == 0)
        #expect(try map(-1.5, first: -3, values: ramp) == 64)
    }

    @Test(
        "[Unit][VOX-R2D-007][VOX-NUM-001] both ends clamp and both origin extremes are safe"
    )
    func bothEndsClampAndBothOriginExtremesAreSafe() throws {
        let ramp = [0.0, 64.0, 128.0, 192.0, 255.0]

        #expect(try map(-1000, first: 10, values: ramp) == 0)
        #expect(try map(1000, first: 10, values: ramp) == 255)
        #expect(try map(10, first: 10, values: ramp) == 0)
        #expect(try map(14, first: 10, values: ramp) == 255)

        // An overflowing difference lies beyond the representable range on the
        // side opposite the origin's sign, so it clamps to that same end —
        // `ALG-0004`'s reasoning, inherited unchanged.
        #expect(try map(0, first: Int64.min, values: ramp) == 255)
        #expect(try map(0, first: Int64.max, values: ramp) == 0)

        // Infinity clamps rather than failing; only NaN is rejected.
        #expect(try map(.infinity, first: 10, values: ramp) == 255)
        #expect(try map(-.infinity, first: 10, values: ramp) == 0)
        #expect(try map(1e300, first: 10, values: ramp) == 255)
        #expect(throws: VOILookupError.valueNotRepresentable) {
            try map(.nan, first: 10, values: ramp)
        }
        #expect(throws: VOILookupError.emptyTable) {
            try map(0, first: 10, values: [])
        }

        let errors: [VOILookupError] = [.emptyTable, .valueNotRepresentable]
        #expect(
            errors.map { String(describing: $0) } == [
                "emptyTable", "valueNotRepresentable",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    @Test(
        "[Unit][VOX-R2D-007][VOX-R2D-002] outputs are display values, clamped and tie-to-even"
    )
    func outputsAreDisplayValuesClampedAndTieToEven() throws {
        // Entries are display values: an out-of-range entry saturates rather
        // than rescaling the table the source author calibrated.
        #expect(try map(10, first: 10, values: [-5]) == 0)
        #expect(try map(10, first: 10, values: [300]) == 255)

        // Output quantisation rounds TIES TO EVEN — a different accepted rule
        // from the index stage's, because it is a different job.
        #expect(try map(10, first: 10, values: [0.5]) == 0)
        #expect(try map(10, first: 10, values: [1.5]) == 2)
        #expect(try map(10, first: 10, values: [2.5]) == 2)

        // A single-entry table maps everything to that entry.
        #expect(try map(-99, first: 10, values: [42]) == 42)
    }

    // MARK: - Fixtures

    private func analyticalFixtures() -> [Fixture] {
        let ramp = [0.0, 64.0, 128.0, 192.0, 255.0]
        func at(
            _ name: String,
            _ value: Double,
            _ first: Int64 = 10,
            _ values: [Double]? = nil
        ) -> Fixture {
            Fixture(
                name: name,
                value: value,
                firstMappedValue: first,
                values: values ?? ramp
            )
        }
        return [
            at("exact-hit", 12.0),
            at("below-table", -1000.0),
            at("above-table", 1000.0),
            at("at-first-entry", 10.0),
            at("at-last-entry", 14.0),
            at("index-half-away-up", 12.5),
            at("index-half-away-lower", 11.5),
            at("index-just-below-half", 0.499_999_999_999_999_94, 0),
            at("negative-origin-half-away", -2.5, -3),
            at("negative-origin-interior", -1.5, -3),
            at("positive-infinity", .infinity),
            at("negative-infinity", -.infinity),
            at("huge-finite", 1e300),
            at("not-a-number", .nan),
            at("origin-at-int64-min", 0.0, Int64.min),
            at("origin-at-int64-max", 0.0, Int64.max),
            at("output-clamp-low", 10.0, 10, [-5.0]),
            at("output-clamp-high", 10.0, 10, [300.0]),
            at("output-ties-even-down", 10.0, 10, [0.5]),
            at("output-ties-even-up", 10.0, 10, [1.5]),
            at("output-ties-even-stay", 10.0, 10, [2.5]),
            at("single-entry", -99.0, 10, [42.0]),
            at("empty-table", 0.0, 10, []),
        ]
    }

    // MARK: - Helpers

    private func map(_ fixture: Fixture) throws -> UInt8 {
        try map(
            fixture.value,
            first: fixture.firstMappedValue,
            values: fixture.values
        )
    }

    private func map(
        _ value: Double,
        first: Int64,
        values: [Double]
    ) throws -> UInt8 {
        try VOILookup.map(
            value: value,
            table: try LookupTableDescriptor(
                firstMappedValue: first,
                values: values,
                outputUnit: nil
            )
        )
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
