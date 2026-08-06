// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

/// The analytical interpolation checks the First Vertical Slice Plan asks for
/// (`VOX-VS1-011`), added by `ADR-0250`.
///
/// The plan's §1957 names the method for CPU linear interpolation as **analytical**
/// equality, and its §28.2 requires linear interpolation to operate in
/// three-dimensional continuous index space. The accepted suites verify the frozen
/// fixtures and the degenerate case where every sample lands on an integer
/// coordinate; what none of them states is the property that makes an
/// interpolator *linear* — that it reproduces a linear function everywhere, not
/// only at the samples.
///
/// ## Why these assertions are exact, with no tolerance
///
/// The plan says "analytical **bounded** numerical equality", which invites an
/// epsilon. None is used, and none is needed: the cases are chosen so the
/// arithmetic is exact in binary64. The specification volume stores
/// `2*i0 + 6*i1 + 18*i2` — small integers — and every sampled position is a
/// half- or quarter-integer, so each trilinear weight is an exact binary fraction
/// and every product and sum is exactly representable. Choosing provably exact
/// cases is this project's alternative to inventing a threshold, and it leaves the
/// geometry tolerance owner gate untouched.
///
/// The expected value is then put through `VOXELIA-ALG-0002`'s ties-to-even output
/// quantisation, because the output is `uint8` and an exact interpolated value of
/// `0.5` is still not a byte. Composing the accepted rule rather than assuming the
/// ramp lands on whole numbers is what keeps these assertions exact.
@Suite("InterpolationAnalytical")
struct InterpolationAnalyticalTests {
    // MARK: - Fixtures, matching the accepted specification volume

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func geometry(
        elements: [Double],
        imageAxes: [Int]
    ) throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: imageAxes),
            indexToWorld: try Matrix4x4Double(elements: elements),
            coordinateSpace: try space()
        )
    }

    private func axis(_ id: String, semantic: AxisSemantic) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }

    /// The linear ramp `value(i0, i1, i2) = 2*i0 + 6*i1 + 18*i2`.
    ///
    /// This is the accepted `ObliqueSliceOperation` specification volume, reused
    /// deliberately: it is already a linear function of the indices, so the
    /// property under test needs no new fixture — only positions the existing
    /// suites never sample.
    private func rampValue(_ i0: Double, _ i1: Double, _ i2: Double) -> Double {
        (2 * i0) + (6 * i1) + (18 * i2)
    }

    private func rampVolume() throws -> ImageData {
        let extents = [3, 3, 3]
        var bytes = [UInt8](repeating: 0, count: 27)
        for i2 in 0..<3 {
            for i1 in 0..<3 {
                for i0 in 0..<3 {
                    bytes[i0 + 3 * (i1 + 3 * i2)] = UInt8(2 * i0 + 6 * i1 + 18 * i2)
                }
            }
        }
        var axes = ContiguousArray<AxisDescriptor>()
        for (index, name) in ["x", "y", "z"].enumerated() {
            let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
            axes.append(try axis(name, semantic: semantics[index]))
        }
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: ContiguousArray(extents)),
            scalarType: .uint8,
            componentCount: 1
        )
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: ContiguousArray(extents)),
                scalarFormat: try ScalarFormat(
                    type: .uint8,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: .intensity,
                axes: axes,
                spatialGeometry: .affine(
                    try geometry(
                        elements: [
                            1, 0, 0, 0,
                            0, 1, 0, 0,
                            0, 0, 1, 0,
                            0, 0, 0, 1,
                        ],
                        imageAxes: [0, 1, 2]
                    )
                ),
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(binding: binding, bytes: bytes)
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "ramp-record")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "ramp-volume"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "ramp-volume")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.11",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    /// Samples one voxel-sized plane whose origin is `origin`.
    private func sample(
        _ origin: (Double, Double, Double),
        name: String
    ) async throws -> UInt8 {
        let output = try await ObliqueSliceOperation.execute(
            input: try rampVolume(),
            request: try geometry(
                elements: [
                    1, 0, 0, origin.0,
                    0, 1, 0, origin.1,
                    0, 0, 1, origin.2,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1]
            ),
            outputWidth: 1,
            outputHeight: 1,
            outputObjectID: try #require(DataObjectID(rawValue: "slice-\(name)")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-\(name)")),
            createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        let extents = output.descriptor.shape.extents
        let read = try output.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        )
        return read.bytes[0]
    }

    // MARK: - Linear precision

    @Test(
        "[Unit][VOX-VS1-011][VOX-MPR-003] trilinear interpolation reproduces a linear ramp exactly")
    func trilinearReproducesALinearRampExactly() async throws {
        // The defining property of a linear interpolator, and the one the
        // accepted suites never state: over a function that is linear in the
        // indices, interpolation must return the function's own value at every
        // position -- not just at the sample points, which is the weaker claim
        // `integerCoordinatesReproduceTheStoredPlane` already makes.
        //
        // Every position here is a half-integer, so the weights are exact binary
        // fractions and the expected value is exact. A weight-normalisation
        // error, a transposed axis or a wrong tap would break at least one of
        // these while still reproducing the samples themselves.
        let positions: [(Double, Double, Double)] = [
            (0.5, 0.0, 0.0),  // one axis, one interval
            (0.0, 0.5, 0.0),
            (0.0, 0.0, 0.5),
            (0.5, 0.5, 0.0),  // two axes at once
            (0.0, 0.5, 0.5),
            (0.5, 0.0, 0.5),
            (0.5, 0.5, 0.5),  // the volume-centre tap, all eight corners equal
            (1.5, 1.5, 1.5),  // the far cell, so an origin-only error is caught
            (1.5, 0.5, 1.0),  // a mixed integer and half-integer position
            (0.25, 0.0, 0.0),  // quarter weights are exact too
            (0.75, 0.0, 0.0),
            (1.25, 1.75, 0.5),
        ]

        for (index, position) in positions.enumerated() {
            let observed = try await sample(position, name: "ramp-\(index)")
            let exact = rampValue(position.0, position.1, position.2)
            // The output is `uint8`, so the exact ramp value passes through the
            // accepted `VOXELIA-ALG-0002` output quantisation -- ties-to-even.
            // Composing that rule rather than assuming whole numbers is what
            // makes this assertion both correct and stronger: it now pins the
            // interpolation AND the quantisation together, so a change to either
            // fails here.
            //
            // The quarter positions on axis zero are why this matters. The ramp
            // coefficient is 2, so 0.25 gives exactly 0.5 and 0.75 gives exactly
            // 1.5 -- neither a whole number, and ties-to-even sends them to 0 and
            // 2 respectively rather than to 1 and 1. An earlier version of this
            // test asserted the unquantised value and failed on precisely those
            // two cases; the interpolator was right and the expectation was not.
            #expect(Double(observed) == exact.rounded(.toNearestOrEven))
        }
    }

    @Test("[Unit][VOX-VS1-011][VOX-MPR-003] interpolation at the samples returns the samples")
    func interpolationAtTheSamplesReturnsTheSamples() async throws {
        // The degenerate half of linear precision, stated over all 27 samples
        // rather than one plane: an interpolator that is exact on a linear
        // function must also be exact where the function is stored.
        for i2 in 0..<3 {
            for i1 in 0..<3 {
                for i0 in 0..<3 {
                    let observed = try await sample(
                        (Double(i0), Double(i1), Double(i2)),
                        name: "exact-\(i0)-\(i1)-\(i2)"
                    )
                    #expect(
                        Double(observed)
                            == rampValue(
                                Double(i0),
                                Double(i1),
                                Double(i2)
                            )
                    )
                }
            }
        }
    }

    @Test("[Unit][VOX-VS1-011] interpolation is monotone along each axis of the ramp")
    func interpolationIsMonotoneAlongEachAxis() async throws {
        // A property no single-position fixture can express, and the one that
        // would catch a sign error or a swapped tap pair that happened to be
        // exact at the half-integer positions above: along a ramp with positive
        // coefficients, advancing one axis in quarter steps must never decrease
        // the sampled value.
        for axis in 0..<3 {
            var previous = -1.0
            for step in 0...8 {
                let offset = Double(step) * 0.25
                let position: (Double, Double, Double) =
                    switch axis {
                    case 0: (offset, 0, 0)
                    case 1: (0, offset, 0)
                    default: (0, 0, offset)
                    }
                let observed = Double(
                    try await sample(position, name: "mono-\(axis)-\(step)")
                )
                #expect(observed >= previous)
                previous = observed
            }
        }
    }
}
