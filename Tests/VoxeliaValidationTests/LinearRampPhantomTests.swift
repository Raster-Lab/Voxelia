// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaValidation

/// `ADR-0294` (`VOX-VAL-003`): the plan §55.1 linear ramp volume, and the intensity kind of
/// validation it supplies.
///
/// Plan §46.2 states what a phantom is for: "known phantoms produce the expected CT values
/// and physical distances independently of windowing and zoom". So the tests that matter
/// are the ones comparing the phantom against its **closed form**, not against another
/// implementation.
@Suite("LinearRampPhantom")
struct LinearRampPhantomTests {
    /// The plan's formula, written here independently of the implementation.
    ///
    /// Deliberately a second transcription rather than a call into the type: a test that
    /// asked the phantom what it contains and then compared it with itself would pass for
    /// any formula at all.
    private func expected(i: Int, j: Int, k: Int) -> Int {
        2 * i + 3 * j - 5 * k + 100
    }

    // MARK: - The closed form

    @Test("[Unit][VOX-VAL-003] the value matches the plan's formula at every index")
    func valueMatchesThePlansFormulaAtEveryIndex() throws {
        // Non-cubic on purpose. `VOXELIA-ALG-0050` notes that `row * columns` and
        // `row * rows` agree for every square frame, so a cubic phantom cannot detect a
        // transposed addressing mistake.
        let phantom = try LinearRampPhantom(columns: 7, rows: 5, slices: 3)
        for slice in 0..<3 {
            for row in 0..<5 {
                for column in 0..<7 {
                    #expect(
                        try phantom.value(column: column, row: row, slice: slice)
                            == Int16(expected(i: column, j: row, k: slice))
                    )
                }
            }
        }
    }

    @Test("[Unit][VOX-VAL-003] the ramp is exactly linear in each axis")
    func rampIsExactlyLinearInEachAxis() throws {
        // The property the plan's named purposes rest on: an interpolator's expected value
        // at a continuous position is available in closed form only because the differences
        // are constant. Asserted as exact integer differences, so no tolerance appears.
        let phantom = try LinearRampPhantom(columns: 9, rows: 6, slices: 4)
        for slice in 0..<4 {
            for row in 0..<6 {
                for column in 1..<9 {
                    let step =
                        try phantom.value(column: column, row: row, slice: slice)
                        - phantom.value(column: column - 1, row: row, slice: slice)
                    #expect(step == 2)
                }
            }
        }
        for slice in 0..<4 {
            for row in 1..<6 {
                let step =
                    try phantom.value(column: 0, row: row, slice: slice)
                    - phantom.value(column: 0, row: row - 1, slice: slice)
                #expect(step == 3)
            }
        }
        for slice in 1..<4 {
            let step =
                try phantom.value(column: 0, row: 0, slice: slice)
                - phantom.value(column: 0, row: 0, slice: slice - 1)
            #expect(step == -5)
        }
    }

    @Test("[Unit][VOX-VAL-003] the origin holds the formula's constant")
    func originHoldsTheFormulasConstant() throws {
        let phantom = try LinearRampPhantom(columns: 4, rows: 4, slices: 4)
        #expect(try phantom.value(column: 0, row: 0, slice: 0) == 100)
    }

    // MARK: - The materialised samples

    @Test("[Unit][VOX-VAL-003] the stored bytes agree with the closed form everywhere")
    func storedBytesAgreeWithTheClosedFormEverywhere() throws {
        // What makes the materialised volume trustworthy: every sample is decoded back and
        // compared against the formula, in `VOXELIA-ALG-0050`'s slice-major then row-major
        // order with the column varying fastest.
        let phantom = try LinearRampPhantom(columns: 7, rows: 5, slices: 3)
        let bytes = phantom.storedBytes
        #expect(bytes.count == phantom.sampleCount * 2)
        #expect(phantom.sampleCount == 7 * 5 * 3)

        var offset = 0
        for slice in 0..<3 {
            for row in 0..<5 {
                for column in 0..<7 {
                    let pattern = UInt16(bytes[offset]) | UInt16(bytes[offset + 1]) << 8
                    let decoded = Int16(bitPattern: pattern)
                    #expect(decoded == Int16(expected(i: column, j: row, k: slice)))
                    offset += 2
                }
            }
        }
        #expect(offset == bytes.count)
    }

    @Test("[Unit][VOX-VAL-003] negative values round-trip through the stored encoding")
    func negativeValuesRoundTripThroughTheStoredEncoding() throws {
        // The `-5k` term takes the ramp negative once the slice index passes twenty, and a
        // zero-extending encoder would turn those into large positives. A phantom shallow
        // enough never to go negative would not detect that.
        let phantom = try LinearRampPhantom(columns: 2, rows: 2, slices: 40)
        #expect(try phantom.value(column: 0, row: 0, slice: 39) == -95)

        let bytes = phantom.storedBytes
        let lastSampleOffset = (phantom.sampleCount - 1) * 2
        let pattern =
            UInt16(bytes[lastSampleOffset]) | UInt16(bytes[lastSampleOffset + 1]) << 8
        #expect(Int16(bitPattern: pattern) == Int16(expected(i: 1, j: 1, k: 39)))
        #expect(Int16(bitPattern: pattern) == -90)
    }

    // MARK: - Refusals

    @Test("[Unit][VOX-VAL-003] non-positive extents are refused")
    func nonPositiveExtentsAreRefused() {
        for extents in [(0, 1, 1), (1, 0, 1), (1, 1, 0), (-1, 1, 1)] {
            #expect(throws: LinearRampPhantomError.invalidExtents) {
                _ = try LinearRampPhantom(
                    columns: extents.0, rows: extents.1, slices: extents.2)
            }
        }
    }

    @Test("[Unit][VOX-VAL-003] extents whose range escapes Int16 are refused")
    func extentsWhoseRangeEscapesInt16AreRefused() throws {
        // The ramp overflows in either direction, and both are refused rather than
        // silently truncated: a phantom whose samples wrapped would be a fixture asserting
        // the wrong expected values everywhere past the wrap.
        #expect(throws: LinearRampPhantomError.valueNotRepresentable) {
            _ = try LinearRampPhantom(columns: 20_000, rows: 1, slices: 1)
        }
        #expect(throws: LinearRampPhantomError.valueNotRepresentable) {
            _ = try LinearRampPhantom(columns: 1, rows: 1, slices: 7_000)
        }

        // The positive control: the largest extents that do fit are admitted, so the
        // refusals above discriminate on the range rather than on size alone.
        let wide = try LinearRampPhantom(columns: 16_334, rows: 1, slices: 1)
        #expect(try wide.value(column: 16_333, row: 0, slice: 0) == 32_766)
        let deep = try LinearRampPhantom(columns: 1, rows: 1, slices: 6_574)
        #expect(try deep.value(column: 0, row: 0, slice: 6_573) == -32_765)
    }

    @Test("[Unit][VOX-VAL-003] an index outside the phantom is refused")
    func indexOutsideThePhantomIsRefused() throws {
        // A phantom that answered for a position it does not contain would let a test
        // assert against a value the volume never held.
        let phantom = try LinearRampPhantom(columns: 3, rows: 3, slices: 3)
        for index in [(3, 0, 0), (0, 3, 0), (0, 0, 3), (-1, 0, 0)] {
            #expect(throws: LinearRampPhantomError.invalidExtents) {
                _ = try phantom.value(column: index.0, row: index.1, slice: index.2)
            }
        }
    }
}
