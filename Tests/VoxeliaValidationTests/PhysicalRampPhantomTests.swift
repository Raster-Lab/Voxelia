// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaValidation

/// `ADR-0296` (`VOX-VAL-003`): the plan §55.2 physical-coordinate ramp, and the spatial kind
/// of validation it supplies.
///
/// The four fixtures below are `VOXELIA-ALG-0053`'s, computed independently in binary64 with
/// half-to-even rounding before any Swift was written. They are transcribed here, not
/// generated from the type.
@Suite("PhysicalRampPhantom")
struct PhysicalRampPhantomTests {
    private static let patient = CoordinateSpaceID(rawValue: "patient")!

    private func phantom(
        _ elements: [Double],
        columns: Int,
        rows: Int,
        slices: Int
    ) throws -> PhysicalRampPhantom {
        try PhysicalRampPhantom(
            columns: columns,
            rows: rows,
            slices: slices,
            indexToPatient: Matrix4x4Double(elements: elements),
            coordinateSpace: Self.patient
        )
    }

    private func samples(_ subject: PhysicalRampPhantom) throws -> [Int16] {
        var values: [Int16] = []
        for slice in 0..<subject.slices {
            for row in 0..<subject.rows {
                for column in 0..<subject.columns {
                    values.append(try subject.value(column: column, row: row, slice: slice))
                }
            }
        }
        return values
    }

    // MARK: - The conformance fixtures

    @Test("[Unit][VOX-VAL-003] fixture A reproduces the specification exactly")
    func fixtureAReproducesTheSpecificationExactly() throws {
        // Axis-aligned, spacing (0.5, 0.5, 2.0), patient origin (-1, 2, 4). The ramp reduces
        // to 1 + 0.5i + j - k, so half-integers occur at every odd column.
        let subject = try phantom(
            [0.5, 0, 0, -1, 0, 0.5, 0, 2, 0, 0, 2, 4, 0, 0, 0, 1],
            columns: 4, rows: 3, slices: 3)
        #expect(
            try samples(subject) == [
                1, 2, 2, 2, 2, 2, 3, 4, 3, 4, 4, 4,
                0, 0, 1, 2, 1, 2, 2, 2, 2, 2, 3, 4,
                -1, 0, 0, 0, 0, 0, 1, 2, 1, 2, 2, 2,
            ])
    }

    @Test("[Unit][VOX-VAL-003] fixture A discriminates ties-to-even from ties-away")
    func fixtureADiscriminatesTiesToEvenFromTiesAway() throws {
        // The rounding rule is the point of this fixture, so it is asserted directly. A
        // ties-away implementation publishes 1, 2, 2, 3 and 2, 3, 3, 4 for these two rows.
        let subject = try phantom(
            [0.5, 0, 0, -1, 0, 0.5, 0, 2, 0, 0, 2, 4, 0, 0, 0, 1],
            columns: 4, rows: 3, slices: 3)
        var firstRow: [Int16] = []
        var secondRow: [Int16] = []
        for column in 0..<4 {
            firstRow.append(try subject.value(column: column, row: 0, slice: 0))
            secondRow.append(try subject.value(column: column, row: 1, slice: 0))
        }
        #expect(firstRow == [1, 2, 2, 2])
        #expect(secondRow == [2, 2, 3, 4])
        #expect(firstRow != [1, 2, 2, 3])
        #expect(secondRow != [2, 3, 3, 4])
    }

    @Test("[Unit][VOX-VAL-003] fixture B reproduces the specification exactly")
    func fixtureBReproducesTheSpecificationExactly() throws {
        // A dyadic oblique shear: every element is exactly representable, so the whole
        // evaluation is exact and reduces to 0.875i + 2.5j + 0.5k.
        let subject = try phantom(
            [1, 0.5, 0, 0, 0, 1, 0.5, 0, 0.25, 0, 1, 0, 0, 0, 0, 1],
            columns: 3, rows: 3, slices: 3)
        #expect(
            try samples(subject) == [
                0, 1, 2, 2, 3, 4, 5, 6, 7,
                0, 1, 2, 3, 4, 5, 6, 6, 7,
                1, 2, 3, 4, 4, 5, 6, 7, 8,
            ])
    }

    @Test("[Unit][VOX-VAL-003] fixture B agrees with its own closed form")
    func fixtureBAgreesWithItsOwnClosedForm() throws {
        // The independent check on fixture B: every element is dyadic, so the reduced form
        // is exact and can be evaluated here without touching the phantom's arithmetic.
        let subject = try phantom(
            [1, 0.5, 0, 0, 0, 1, 0.5, 0, 0.25, 0, 1, 0, 0, 0, 0, 1],
            columns: 3, rows: 3, slices: 3)
        for slice in 0..<3 {
            for row in 0..<3 {
                for column in 0..<3 {
                    let closedForm =
                        0.875 * Double(column) + 2.5 * Double(row) + 0.5 * Double(slice)
                    #expect(
                        try subject.value(column: column, row: row, slice: slice)
                            == Int16(closedForm.rounded(.toNearestOrEven))
                    )
                }
            }
        }
    }

    @Test("[Unit][VOX-VAL-003] fixture C reproduces the specification exactly")
    func fixtureCReproducesTheSpecificationExactly() throws {
        // A rotation with three-four-five direction cosines. Neither 0.6 nor 0.8 is
        // representable, so this fixture measures determinism rather than exactness.
        let subject = try phantom(
            [0.6, -0.8, 0, 0, 0.8, 0.6, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1],
            columns: 3, rows: 3, slices: 3)
        #expect(
            try samples(subject) == [
                0, 2, 4, 0, 3, 5, 1, 3, 5,
                0, 2, 4, 0, 2, 4, 0, 2, 5,
                -1, 1, 3, -1, 2, 4, 0, 2, 4,
            ])
        // The two exact halves in this fixture, including a negative one: a ties-away
        // implementation publishes -1 and 3.
        #expect(try subject.value(column: 0, row: 0, slice: 1) == 0)
        #expect(try subject.value(column: 1, row: 2, slice: 1) == 2)
    }

    @Test("[Unit][VOX-VAL-003] fixture D reproduces the association-sensitive plane")
    func fixtureDReproducesTheAssociationSensitivePlane() throws {
        // The same rotation with a non-dyadic 0.3 slice spacing. This is the fixture that
        // justifies the specification: two of these samples change integer under a
        // right-associated or reordered evaluation.
        let subject = try phantom(
            [0.6, -0.8, 0, 0, 0.8, 0.6, 0, 0, 0, 0, 0.3, 0, 0, 0, 0, 1],
            columns: 6, rows: 6, slices: 6)
        var plane: [Int16] = []
        for row in 0..<6 {
            for column in 0..<6 {
                plane.append(try subject.value(column: column, row: row, slice: 2))
            }
        }
        #expect(
            plane == [
                0, 2, 4, 6, 8, 11,
                0, 2, 5, 7, 9, 11,
                0, 3, 5, 7, 9, 12,
                1, 3, 5, 8, 10, 12,
                1, 4, 6, 8, 10, 12,
                2, 4, 6, 8, 10, 13,
            ])
        #expect(try subject.value(column: 2, row: 1, slice: 2) == 5)
        #expect(try subject.value(column: 3, row: 3, slice: 2) == 8)
    }

    @Test("[Unit][VOX-VAL-003] the frozen association is what produces those two samples")
    func frozenAssociationIsWhatProducesThoseTwoSamples() throws {
        // The claim above is falsified here rather than asserted: the two rival associations
        // are evaluated in the test against the phantom's own patient positions, and both
        // round to a different integer at these indices.
        let subject = try phantom(
            [0.6, -0.8, 0, 0, 0.8, 0.6, 0, 0, 0, 0, 0.3, 0, 0, 0, 0, 1],
            columns: 6, rows: 6, slices: 6)
        for index in [(2, 1, 2), (3, 3, 2)] {
            let position = try subject.patientPosition(
                column: index.0, row: index.1, slice: index.2)
            let scaledY = 2.0 * position.y
            let scaledZ = 0.5 * position.z
            let frozen = ((position.x + scaledY) - scaledZ).rounded(.toNearestOrEven)
            let rightAssociated = (position.x + (scaledY - scaledZ)).rounded(.toNearestOrEven)
            #expect(
                try subject.value(column: index.0, row: index.1, slice: index.2)
                    == Int16(frozen))
            #expect(frozen != rightAssociated)
        }
    }

    // MARK: - The geometry the fixtures are sampled through

    @Test("[Unit][VOX-VAL-003] the patient position is the frozen forward evaluation")
    func patientPositionIsTheFrozenForwardEvaluation() throws {
        // Composed from `ADR-0138`, translation first then ascending slots. Checked on the
        // dyadic shear, where every step is exact and the expected values are unambiguous.
        let subject = try phantom(
            [1, 0.5, 0, 0, 0, 1, 0.5, 0, 0.25, 0, 1, 0, 0, 0, 0, 1],
            columns: 3, rows: 3, slices: 3)
        let position = try subject.patientPosition(column: 2, row: 1, slice: 2)
        #expect(position.x == 2.5)
        #expect(position.y == 2.0)
        #expect(position.z == 2.5)
        #expect(position.coordinateSpace == Self.patient)
    }

    @Test("[Unit][VOX-VAL-003] the stored bytes agree with the sampled values")
    func storedBytesAgreeWithTheSampledValues() throws {
        // Every materialised byte is decoded and the walk is asserted to consume the buffer
        // exactly, so a length or ordering error cannot hide in an unvisited tail.
        let subject = try phantom(
            [0.5, 0, 0, -1, 0, 0.5, 0, 2, 0, 0, 2, 4, 0, 0, 0, 1],
            columns: 4, rows: 3, slices: 3)
        let bytes = try subject.storedBytes()
        #expect(bytes.count == subject.sampleCount * 2)
        #expect(subject.sampleCount == 4 * 3 * 3)

        var offset = 0
        for value in try samples(subject) {
            let pattern = UInt16(bytes[offset]) | UInt16(bytes[offset + 1]) << 8
            #expect(Int16(bitPattern: pattern) == value)
            offset += 2
        }
        #expect(offset == bytes.count)
    }

    @Test("[Unit][VOX-VAL-003] negative samples survive the stored encoding")
    func negativeSamplesSurviveTheStoredEncoding() throws {
        // Fixture A goes negative at the far slice, and a zero-extending encoder would turn
        // that into a large positive.
        let subject = try phantom(
            [0.5, 0, 0, -1, 0, 0.5, 0, 2, 0, 0, 2, 4, 0, 0, 0, 1],
            columns: 4, rows: 3, slices: 3)
        #expect(try subject.value(column: 0, row: 0, slice: 2) == -1)
        let bytes = try subject.storedBytes()
        let offset = (2 * 12) * 2
        let pattern = UInt16(bytes[offset]) | UInt16(bytes[offset + 1]) << 8
        #expect(Int16(bitPattern: pattern) == -1)
    }

    // MARK: - Refusals

    @Test("[Unit][VOX-VAL-003] a non-affine geometry is refused")
    func nonAffineGeometryIsRefused() throws {
        // Composed from `VOXELIA-ALG-0052`'s exact structural test. A perspective row would
        // make the forward evaluation above wrong rather than merely unusual.
        for elements in [
            [1.0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0.5, 0, 0, 1],
            [1.0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 2],
        ] {
            #expect(throws: PhysicalRampPhantomError.nonAffineGeometry) {
                _ = try self.phantom(elements, columns: 2, rows: 2, slices: 2)
            }
        }
        // The positive control: the identity is admitted, so the refusals discriminate on
        // the bottom row rather than on the matrix as a whole.
        let identity = try phantom(
            [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
            columns: 2, rows: 2, slices: 2)
        // 1 + 2(1) - 0.5(1) is 2.5, which ties to the even 2.
        #expect(try identity.value(column: 1, row: 1, slice: 1) == 2)
    }

    @Test("[Unit][VOX-VAL-003] a sample outside Int16 is refused rather than clamped")
    func sampleOutsideInt16IsRefusedRatherThanClamped() throws {
        // The deliberate departure from `VOXELIA-ALG-0002`, which clamps. Clamping here
        // would publish an expected value that is not the ramp's value.
        #expect(throws: PhysicalRampPhantomError.valueNotRepresentable) {
            _ = try self.phantom(
                [40_000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
                columns: 2, rows: 2, slices: 2)
        }
        #expect(throws: PhysicalRampPhantomError.valueNotRepresentable) {
            _ = try self.phantom(
                [-40_000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
                columns: 2, rows: 2, slices: 2)
        }
        // The positive control: the largest column coefficient that still fits is admitted
        // and reaches exactly Int16.max, so the refusals discriminate on the range.
        let edge = try phantom(
            [32_767, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
            columns: 2, rows: 1, slices: 1)
        #expect(try edge.value(column: 1, row: 0, slice: 0) == 32_767)
    }

    @Test("[Unit][VOX-VAL-003] the corner admission is sound because the ramp stays affine")
    func cornerAdmissionIsSoundBecauseTheRampStaysAffine() throws {
        // Why eight corners are enough to admit a geometry. The ramp composed with an affine
        // is itself affine in the indices, so its extremes over the box lie at corners — the
        // property is asserted here rather than assumed, on the two obliquely sampled
        // fixtures where an interior sample could plausibly have escaped.
        for elements in [
            [1.0, 0.5, 0, 0, 0, 1, 0.5, 0, 0.25, 0, 1, 0, 0, 0, 0, 1],
            [0.6, -0.8, 0, 0, 0.8, 0.6, 0, 0, 0, 0, 0.3, 0, 0, 0, 0, 1],
        ] {
            let subject = try phantom(elements, columns: 6, rows: 6, slices: 6)
            let everySample = try samples(subject)
            var corners: [Int16] = []
            for slice in [0, 5] {
                for row in [0, 5] {
                    for column in [0, 5] {
                        let corner = try subject.value(
                            column: column, row: row, slice: slice)
                        corners.append(corner)
                    }
                }
            }
            #expect(everySample.max() == corners.max())
            #expect(everySample.min() == corners.min())
        }
    }

    @Test("[Unit][VOX-VAL-003] non-positive extents and outside indices are refused")
    func nonPositiveExtentsAndOutsideIndicesAreRefused() throws {
        for extents in [(0, 2, 2), (2, 0, 2), (2, 2, 0), (-1, 2, 2)] {
            #expect(throws: PhysicalRampPhantomError.invalidExtents) {
                _ = try self.phantom(
                    [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
                    columns: extents.0, rows: extents.1, slices: extents.2)
            }
        }
        let subject = try phantom(
            [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
            columns: 2, rows: 2, slices: 2)
        for index in [(2, 0, 0), (0, 2, 0), (0, 0, 2), (-1, 0, 0)] {
            #expect(throws: PhysicalRampPhantomError.indexOutsideExtents) {
                _ = try subject.value(column: index.0, row: index.1, slice: index.2)
            }
        }
    }
}
