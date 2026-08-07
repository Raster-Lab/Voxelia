// SPDX-License-Identifier: MIT

import Testing
import VoxeliaInteraction
import VoxeliaSpatial

@testable import VoxeliaValidation

/// `ADR-0295` (`VOX-VAL-003`): the plan §55.4 distance phantom, and the measurement kind of
/// validation it supplies.
///
/// Plan §46.2 states the exit criterion these tests serve: "known phantoms produce the
/// expected CT values and physical distances independently of windowing and zoom". So the
/// measurement here runs through the shipped `MeasurementConstruction`, not through a
/// length computed inside the test.
@Suite("DistancePhantom")
struct DistancePhantomTests {
    private static let patient = CoordinateSpaceID(rawValue: "patient")!

    /// The reference configuration: realistic anisotropic spacing, an off-origin patient
    /// position, and extents that admit all four segments.
    private func reference() throws -> DistancePhantom {
        try DistancePhantom(
            columns: 9,
            rows: 12,
            slices: 7,
            columnSpacing: 0.5,
            rowSpacing: 0.5,
            sliceSpacing: 2.0,
            origin: Point3D(x: -150, y: -200, z: 30, coordinateSpace: Self.patient)
        )
    }

    // MARK: - The exactness the arc was opened to guarantee

    @Test("[Unit][VOX-VAL-003] each declared length is the integer root of its own delta")
    func declaredLengthIsTheIntegerRootOfItsOwnDelta() throws {
        // The declared length is never trusted. It is re-derived from the endpoints in Int,
        // which is the only arithmetic that can certify exactness without a tolerance.
        let phantom = try reference()
        for segment in phantom.segments {
            let deltaX = segment.end.x - segment.start.x
            let deltaY = segment.end.y - segment.start.y
            let deltaZ = segment.end.z - segment.start.z
            #expect(deltaX == deltaX.rounded(.towardZero))
            #expect(deltaY == deltaY.rounded(.towardZero))
            #expect(deltaZ == deltaZ.rounded(.towardZero))
            #expect(segment.exactLength == segment.exactLength.rounded(.towardZero))

            let a = Int(deltaX)
            let b = Int(deltaY)
            let c = Int(deltaZ)
            let d = Int(segment.exactLength)
            #expect(a * a + b * b + c * c == d * d)
        }
    }

    @Test("[Unit][VOX-VAL-003] a binary64 round trip would admit an irrational length")
    func binary64RoundTripWouldAdmitAnIrrationalLength() {
        // Why the identity above is checked in Int. A squared length of 11 is what the
        // wholly plausible delta (1, 1, 3) produces, its root is irrational, and yet the
        // round-trip certificate accepts it. Measured here rather than asserted in prose.
        let squared = 11.0
        #expect(squared.squareRoot() * squared.squareRoot() == squared)
        #expect(squared.squareRoot() != squared.squareRoot().rounded(.towardZero))

        // The frozen table's squared lengths survive the same probe for the real reason.
        for squared in [25.0, 9.0, 49.0, 81.0] {
            #expect(squared.squareRoot() == squared.squareRoot().rounded(.towardZero))
        }
    }

    // MARK: - The measurement the row is about

    @Test("[Unit][VOX-VAL-003] the shipped measurement returns each exact length")
    func shippedMeasurementReturnsEachExactLength() throws {
        // The row's subject. `MeasurementConstruction` evaluates `VOXELIA-ALG-0010` over
        // the phantom's own patient-space endpoints, and the result is compared exactly.
        let phantom = try reference()
        #expect(phantom.segments.count == 4)
        for segment in phantom.segments {
            let measured = try MeasurementConstruction(points: [segment.start, segment.end])
            #expect(measured.derivedLength == segment.exactLength)
        }
        #expect(phantom.segments.map(\.exactLength) == [5.0, 3.0, 7.0, 9.0])
    }

    @Test("[Unit][VOX-VAL-003] the segments are oblique and defeat the per-axis fallacies")
    func segmentsAreObliqueAndDefeatThePerAxisFallacies() throws {
        // "Oblique orientations" is not decoration. A pipeline that summed axis distances,
        // or reported the longest axis, is wrong on every segment here — and would be right
        // on an axis-aligned one, which is why none is included.
        let phantom = try reference()
        var fullyOblique = 0
        for segment in phantom.segments {
            let deltas = [
                (segment.end.x - segment.start.x).magnitude,
                (segment.end.y - segment.start.y).magnitude,
                (segment.end.z - segment.start.z).magnitude,
            ]
            #expect(deltas.filter { $0 != 0 }.count >= 2)
            if deltas.allSatisfy({ $0 != 0 }) {
                fullyOblique += 1
            }
            #expect(deltas.reduce(0, +) != segment.exactLength)
            #expect(deltas.max() != segment.exactLength)
        }
        #expect(fullyOblique == 3)
    }

    @Test("[Unit][VOX-VAL-003] the physical length does not depend on the sampling")
    func physicalLengthDoesNotDependOnTheSampling() throws {
        // The patient-space claim: halving the spacing doubles the index separation and
        // leaves the measured distance alone.
        let coarse = try reference()
        let fine = try DistancePhantom(
            columns: 17,
            rows: 22,
            slices: 13,
            columnSpacing: 0.25,
            rowSpacing: 0.25,
            sliceSpacing: 1.0,
            origin: Point3D(x: -150, y: -200, z: 30, coordinateSpace: Self.patient)
        )
        for (coarseSegment, fineSegment) in zip(coarse.segments, fine.segments) {
            let coarseMeasured = try MeasurementConstruction(points: [
                coarseSegment.start, coarseSegment.end,
            ])
            let fineMeasured = try MeasurementConstruction(points: [
                fineSegment.start, fineSegment.end,
            ])
            #expect(coarseMeasured.derivedLength == fineMeasured.derivedLength)
            #expect(coarseSegment.endIndex != fineSegment.endIndex)
        }
    }

    @Test("[Unit][VOX-VAL-003] the lengths are exact at the admitted origin extremes")
    func lengthsAreExactAtTheAdmittedOriginExtremes() throws {
        // The origin bound exists so every coordinate stays a dyadic rational narrow enough
        // for the whole chain to be exact. Probed at the boundary rather than assumed.
        for component in [0.0, -1_073_741_824.0, 1_073_741_824.0] {
            let phantom = try DistancePhantom(
                columns: 9,
                rows: 12,
                slices: 7,
                columnSpacing: 0.5,
                rowSpacing: 0.5,
                sliceSpacing: 2.0,
                origin: Point3D(
                    x: component, y: component, z: component, coordinateSpace: Self.patient)
            )
            for segment in phantom.segments {
                let measured = try MeasurementConstruction(points: [
                    segment.start, segment.end,
                ])
                #expect(measured.derivedLength == segment.exactLength)
            }
        }
    }

    // MARK: - The materialised volume

    @Test("[Unit][VOX-VAL-003] the marked samples are exactly the endpoints")
    func markedSamplesAreExactlyTheEndpoints() throws {
        // Every sample is decoded and the walk is asserted to consume the buffer exactly, so
        // a length or ordering error cannot hide in an unvisited tail.
        let phantom = try reference()
        let expected = Set(phantom.markerIndices)
        #expect(expected.count == 5)

        let bytes = phantom.storedBytes
        #expect(bytes.count == phantom.sampleCount * 2)
        #expect(phantom.sampleCount == 9 * 12 * 7)

        var offset = 0
        var marked = 0
        for slice in 0..<7 {
            for row in 0..<12 {
                for column in 0..<9 {
                    let pattern = UInt16(bytes[offset]) | UInt16(bytes[offset + 1]) << 8
                    let decoded = Int16(bitPattern: pattern)
                    let index = DistancePhantom.VoxelIndex(
                        column: column, row: row, slice: slice)
                    if expected.contains(index) {
                        #expect(decoded == DistancePhantom.markerValue)
                        marked += 1
                    } else {
                        #expect(decoded == DistancePhantom.backgroundValue)
                    }
                    offset += 2
                }
            }
        }
        #expect(offset == bytes.count)
        #expect(marked == 5)
    }

    @Test("[Unit][VOX-VAL-003] the base sample is distinct in each axis")
    func baseSampleIsDistinctInEachAxis() throws {
        // A base at the corner would read correctly under a transposed addressing mistake.
        let phantom = try reference()
        let base = phantom.baseIndex
        #expect(base.column != base.row)
        #expect(base.row != base.slice)
        #expect(base.column == 1)
        #expect(base.row == 2)
        #expect(base.slice == 1)
    }

    // MARK: - Refusals

    @Test("[Unit][VOX-VAL-003] a spacing that is not a power of two is refused")
    func spacingThatIsNotAPowerOfTwoIsRefused() throws {
        let origin = try Point3D(x: 0, y: 0, z: 0, coordinateSpace: Self.patient)
        for spacing in [0.3, 0.7, 1.5, 0.0, -0.5, 2048.0] {
            #expect(throws: DistancePhantomError.spacingNotAdmissible) {
                _ = try DistancePhantom(
                    columns: 9, rows: 12, slices: 7,
                    columnSpacing: spacing, rowSpacing: 0.5, sliceSpacing: 2.0,
                    origin: origin)
            }
        }
        // The positive control: the admitted powers of two are accepted, so the refusals
        // above discriminate on the significand rather than on the magnitude.
        for spacing in [1.0, 0.5, 0.25, 0.125] {
            let phantom = try DistancePhantom(
                columns: 40, rows: 50, slices: 80,
                columnSpacing: spacing, rowSpacing: spacing, sliceSpacing: spacing,
                origin: origin)
            #expect(phantom.segments.count == 4)
        }
    }

    @Test("[Unit][VOX-VAL-003] a spacing too coarse to land on a sample is refused")
    func spacingTooCoarseToLandOnASampleIsRefused() throws {
        // The table has one-millimetre components, so a two-millimetre in-plane spacing puts
        // an endpoint half way between samples. Refusing beats silently rounding it onto one.
        let origin = try Point3D(x: 0, y: 0, z: 0, coordinateSpace: Self.patient)
        #expect(throws: DistancePhantomError.segmentNotVoxelAligned) {
            _ = try DistancePhantom(
                columns: 9, rows: 12, slices: 7,
                columnSpacing: 2.0, rowSpacing: 0.5, sliceSpacing: 2.0,
                origin: origin)
        }
        // The positive control: two millimetres is admitted through the slice axis, because
        // every frozen z component is even.
        let phantom = try DistancePhantom(
            columns: 9, rows: 12, slices: 7,
            columnSpacing: 0.5, rowSpacing: 0.5, sliceSpacing: 2.0,
            origin: origin)
        #expect(phantom.segments.count == 4)
    }

    @Test("[Unit][VOX-VAL-003] a non-integral or oversized origin is refused")
    func nonIntegralOrOversizedOriginIsRefused() throws {
        for component in [0.5, -0.5, 1.25, 1_073_741_825.0] {
            let origin = try Point3D(
                x: component, y: 0, z: 0, coordinateSpace: Self.patient)
            #expect(throws: DistancePhantomError.originNotAdmissible) {
                _ = try DistancePhantom(
                    columns: 9, rows: 12, slices: 7,
                    columnSpacing: 0.5, rowSpacing: 0.5, sliceSpacing: 2.0,
                    origin: origin)
            }
        }
        // The positive control: the largest admitted magnitude is accepted.
        let edge = try Point3D(
            x: 1_073_741_824.0, y: 0, z: 0, coordinateSpace: Self.patient)
        let phantom = try DistancePhantom(
            columns: 9, rows: 12, slices: 7,
            columnSpacing: 0.5, rowSpacing: 0.5, sliceSpacing: 2.0,
            origin: edge)
        #expect(phantom.segments.count == 4)
    }

    @Test("[Unit][VOX-VAL-003] extents that cannot hold every endpoint are refused")
    func extentsThatCannotHoldEveryEndpointAreRefused() throws {
        // The furthest endpoints sit at column 7, row 10 and slice 5, so 8 x 11 x 6 is the
        // smallest volume that holds them. Each triple below is one sample short in exactly
        // one axis.
        let origin = try Point3D(x: 0, y: 0, z: 0, coordinateSpace: Self.patient)
        for extents in [(7, 11, 6), (8, 10, 6), (8, 11, 5)] {
            #expect(throws: DistancePhantomError.segmentOutsideExtents) {
                _ = try DistancePhantom(
                    columns: extents.0, rows: extents.1, slices: extents.2,
                    columnSpacing: 0.5, rowSpacing: 0.5, sliceSpacing: 2.0,
                    origin: origin)
            }
        }
        // The positive control: the minimum itself is admitted, so the refusals sit exactly
        // at the boundary rather than somewhere short of it.
        let phantom = try DistancePhantom(
            columns: 8, rows: 11, slices: 6,
            columnSpacing: 0.5, rowSpacing: 0.5, sliceSpacing: 2.0,
            origin: origin)
        let furthestInPlane = DistancePhantom.VoxelIndex(column: 7, row: 10, slice: 1)
        let furthestOblique = DistancePhantom.VoxelIndex(column: 3, row: 10, slice: 5)
        #expect(phantom.markerIndices.contains(furthestInPlane))
        #expect(phantom.markerIndices.contains(furthestOblique))
    }

    @Test("[Unit][VOX-VAL-003] non-positive extents are refused")
    func nonPositiveExtentsAreRefused() throws {
        let origin = try Point3D(x: 0, y: 0, z: 0, coordinateSpace: Self.patient)
        for extents in [(0, 12, 7), (9, 0, 7), (9, 12, 0), (-1, 12, 7)] {
            #expect(throws: DistancePhantomError.invalidExtents) {
                _ = try DistancePhantom(
                    columns: extents.0, rows: extents.1, slices: extents.2,
                    columnSpacing: 0.5, rowSpacing: 0.5, sliceSpacing: 2.0,
                    origin: origin)
            }
        }
    }

    @Test("[Unit][VOX-VAL-003] endpoints keep the origin's coordinate space")
    func endpointsKeepTheOriginsCoordinateSpace() throws {
        // A measurement spanning coordinate spaces is refused by `ADR-0292`'s rule, so a
        // phantom that quietly changed space would make its own segments unmeasurable.
        let phantom = try reference()
        for segment in phantom.segments {
            #expect(segment.start.coordinateSpace == Self.patient)
            #expect(segment.end.coordinateSpace == Self.patient)
        }
    }
}
