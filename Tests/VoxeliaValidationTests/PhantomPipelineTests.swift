// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaImaging
import VoxeliaSpatial
import VoxeliaStorage
import VoxeliaValidation

/// `ADR-0297` (`VOX-VAL-003`): the analytical phantoms driven through the **shipped**
/// pipelines, which is the evidence plan §46.2 actually asks for.
///
/// That criterion reads "known phantoms produce the expected CT values and physical
/// distances independently of windowing and zoom". It is a statement about a pipeline, not
/// about a phantom, so `ADR-0296` declined to discharge the row on suites that only verified
/// the phantoms against their own definitions. These tests run them through
/// `WindowLevelOperation`, `CTSampleInspector` and `ObliqueSliceOperation`.
@Suite("PhantomPipeline")
struct PhantomPipelineTests {
    // MARK: - Harness

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

    private func axis(_ id: String, semantic: AxisSemantic) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func image(
        extents: [Int],
        bytes: [UInt8],
        scalarType: ScalarType,
        geometry: SpatialGeometry?
    ) throws -> ImageData {
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        let names = ["x", "y", "z"]
        var axes = ContiguousArray<AxisDescriptor>()
        for index in 0..<extents.count {
            axes.append(try axis(names[index], semantic: semantics[index]))
        }
        let shape = try ImageShape(extents: ContiguousArray(extents))
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
                scalarFormat: try ScalarFormat(
                    type: scalarType,
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
                spatialGeometry: geometry,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: shape,
                        scalarType: scalarType,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-07T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "phantom-1"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "phantom-1")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "voxelia.analytical-phantom",
                        identifier: "plan-55",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func windowed(
        _ input: ImageData,
        centre: Double,
        width: Double
    ) async throws -> ImageData {
        try await WindowLevelOperation.execute(
            input: input,
            center: try MetadataFloatingPoint(value: centre),
            width: try MetadataFloatingPoint(value: width),
            paddingValue: nil,
            outputObjectID: try #require(DataObjectID(rawValue: "phantom-windowed")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-windowed")),
            createdAt: try CanonicalInstant(utcString: "2026-08-07T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 4096)
        )
    }

    private func bytes(_ image: ImageData) throws -> [UInt8] {
        let extents = image.descriptor.shape.extents
        return try image.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
    }

    // MARK: - Intensity: the CT value survives the window

    @Test("[Unit][VOX-VAL-003] the phantom's CT values are unchanged by the window")
    func phantomCTValuesAreUnchangedByTheWindow() async throws {
        // Plan §46.2's first half, instantiated. The §55.1 ramp's slice k = 0 holds
        // 100 + 2i + 3j, and the test asserts the inspected value against that closed form
        // rather than against another read of the same bytes.
        let phantom = try LinearRampPhantom(columns: 6, rows: 5, slices: 1)
        let slice = try image(
            extents: [6, 5],
            bytes: Array(phantom.storedBytes),
            scalarType: .int16,
            geometry: nil
        )

        // Two windows that disagree everywhere: the identity window, and a narrow one that
        // saturates most of the ramp.
        let wide = try await windowed(slice, centre: 128, width: 256)
        let narrow = try await windowed(slice, centre: 110, width: 20)
        let wideBytes = try bytes(wide)
        let narrowBytes = try bytes(narrow)
        #expect(wideBytes != narrowBytes)
        #expect(Array(wideBytes.prefix(6)) == [100, 102, 104, 106, 108, 110])
        #expect(Array(narrowBytes.prefix(6)) == [0, 27, 54, 81, 107, 134])

        // The CT values themselves are the same under both, and equal the phantom's own
        // closed form at every sample.
        for row in 0..<5 {
            for column in 0..<6 {
                let inspection = try CTSampleInspector.inspect(
                    slice: slice, column: column, row: row, paddingValue: nil)
                #expect(inspection.storedValue == Int64(100 + 2 * column + 3 * row))
                let declared = try phantom.value(column: column, row: row, slice: 0)
                #expect(inspection.value == .measured(Double(declared)))
            }
        }
    }

    @Test("[Unit][VOX-VAL-003] the identity window is exact over the whole byte range")
    func identityWindowIsExactOverTheWholeByteRange() async throws {
        // The spatial test below depends on this: a centre of 128 with a width of 256 maps
        // every stored value 0...255 to itself under `VOXELIA-ALG-0002`. Asserted over the
        // entire range rather than assumed from the two rows above.
        var storedBytes: [UInt8] = []
        for value in 0...255 {
            storedBytes.append(UInt8(value))
            storedBytes.append(0)
        }
        let ramp = try image(
            extents: [256, 1], bytes: storedBytes, scalarType: .int16, geometry: nil)
        let identity = try await windowed(ramp, centre: 128, width: 256)
        #expect(try bytes(identity) == (0...255).map { UInt8($0) })
    }

    // MARK: - Spatial: the oblique reconstruction of a known ramp

    @Test("[Unit][VOX-VAL-003] an oblique reconstruction reproduces the ramp's closed form")
    func obliqueReconstructionReproducesTheRampsClosedForm() async throws {
        // Plan §46.2's second half, and the reason §55.2 exists. The volume geometry makes
        // the ramp exactly 10 + i + 2j - k, so the reconstruction's expected value is
        // available in closed form — which is the whole point of an analytical phantom.
        let volumeGeometry = try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: [
                1, 0, 0, 10,
                0, 1, 0, 0,
                0, 0, 2, 0,
                0, 0, 0, 1,
            ]),
            coordinateSpace: try space()
        )
        let phantom = try PhysicalRampPhantom(
            columns: 5,
            rows: 5,
            slices: 5,
            indexToPatient: volumeGeometry.indexToWorld,
            coordinateSpace: volumeGeometry.coordinateSpace.id
        )
        #expect(try phantom.value(column: 0, row: 0, slice: 0) == 10)
        #expect(try phantom.value(column: 4, row: 4, slice: 0) == 22)

        // Stage one: the identity window, so the uint8 volume the oblique operation requires
        // holds exactly the phantom's own integers rather than a rescaled copy of them.
        let stored = try image(
            extents: [5, 5, 5],
            bytes: Array(try phantom.storedBytes()),
            scalarType: .int16,
            geometry: .affine(volumeGeometry)
        )
        let display = try await windowed(stored, centre: 128, width: 256)
        var expectedVolume: [UInt8] = []
        for slice in 0..<5 {
            for row in 0..<5 {
                for column in 0..<5 {
                    let value = try phantom.value(column: column, row: row, slice: slice)
                    expectedVolume.append(UInt8(value))
                }
            }
        }
        #expect(try bytes(display) == expectedVolume)

        // Stage two: an oblique plane. Its in-plane step is (1, 0.5, 0) in patient space, so
        // it is not axis-aligned, and every odd output column lands exactly half way between
        // two rows of the volume — a genuine trilinear blend with weights of exactly one
        // half, which is exact in binary64.
        //
        // The third column is the plane normal (1, -2, 0). The sampling loop reads only
        // slots zero and one, so it does not move a single sample — but `AffineGridGeometry`
        // requires an invertible matrix, and a planar request whose out-of-plane column is
        // zero is singular and refused.
        let request = try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
            indexToWorld: try Matrix4x4Double(elements: [
                1.0, 0, 1.0, 10,
                0.5, 0, -2.0, 0,
                0, 2.0, 0, 0,
                0, 0, 0, 1,
            ]),
            coordinateSpace: try space()
        )
        let oblique = try await ObliqueSliceOperation.execute(
            input: display,
            request: request,
            outputWidth: 4,
            outputHeight: 4,
            outputObjectID: try #require(DataObjectID(rawValue: "phantom-oblique")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-oblique")),
            createdAt: try CanonicalInstant(utcString: "2026-08-07T09:02:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 4096)
        )

        // The closed form: value(u, v) = 10 + 2u - v.
        var expectedPlane: [UInt8] = []
        for v in 0..<4 {
            for u in 0..<4 {
                expectedPlane.append(UInt8(10 + 2 * u - v))
            }
        }
        #expect(try bytes(oblique) == expectedPlane)
        #expect(
            expectedPlane == [
                10, 12, 14, 16,
                9, 11, 13, 15,
                8, 10, 12, 14,
                7, 9, 11, 13,
            ])
    }

    @Test("[Unit][VOX-VAL-003] the oblique plane is not an axis-aligned slice in disguise")
    func obliquePlaneIsNotAnAxisAlignedSliceInDisguise() async throws {
        // The falsification. If the reconstruction ignored the y step and read the volume
        // row zero throughout, it would publish 10 + u - v instead. The two disagree at
        // every column past the first, so the test above cannot pass for that pipeline.
        for u in 1..<4 {
            #expect(10 + 2 * u != 10 + u)
        }
        // And the interpolated columns genuinely need a neighbour: at odd u the sample sits
        // at row u/2, which is not an integer index.
        for u in [1, 3] {
            let position = 0.5 * Double(u)
            #expect(position != position.rounded(.towardZero))
        }
    }
}
