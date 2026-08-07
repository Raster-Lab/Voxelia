// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("GridResampleOperation")
struct GridResampleOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func space(id: String = "patient") throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func geometry(
        elements: [Double],
        imageAxes: [Int],
        spaceID: String = "patient"
    ) throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: imageAxes),
            indexToWorld: try Matrix4x4Double(elements: elements),
            coordinateSpace: try space(id: spaceID)
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

    /// The oblique specification volume: extents (3, 3, 3) with stored
    /// value `2*i0 + 6*i1 + 18*i2` and identity index-to-world geometry.
    private func volume(
        extents: [Int] = [3, 3, 3],
        geometry: SpatialGeometry?
    ) throws -> ImageData {
        let count = extents.reduce(1, *)
        var bytes = [UInt8](repeating: 0, count: count)
        if extents == [3, 3, 3] {
            for i2 in 0..<3 {
                for i1 in 0..<3 {
                    for i0 in 0..<3 {
                        bytes[i0 + 3 * (i1 + 3 * i2)] = UInt8(
                            2 * i0 + 6 * i1 + 18 * i2
                        )
                    }
                }
            }
        }
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        let names = ["x", "y", "z"]
        for index in 0..<extents.count {
            axes.append(try axis(names[index], semantic: semantics[index]))
        }
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
                spatialGeometry: geometry,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: try LogicalSampleBinding(
                        shape: try ImageShape(extents: ContiguousArray(extents)),
                        scalarType: .uint8,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T09:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "volume-7"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "volume-7")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.7",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func identityVolumeGeometry() throws -> SpatialGeometry {
        .affine(
            try geometry(
                elements: [
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            )
        )
    }

    private func execute(
        _ input: ImageData,
        request: AffineGridGeometry,
        extents: [Int]
    ) async throws -> ImageData {
        try await GridResampleOperation.execute(
            input: input,
            request: request,
            outputExtents: extents,
            outputObjectID: try #require(DataObjectID(rawValue: "resampled-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
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

    @Test("[Operation][VOX-IMG-008] fixture 1: the identity grid reproduces the volume")
    func identityGridReproducesTheVolume() async throws {
        let input = try volume(geometry: try identityVolumeGeometry())
        let output = try await execute(
            input,
            request: try geometry(
                elements: [
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            ),
            extents: [3, 3, 3]
        )
        #expect(try bytes(output) == (try bytes(input)))
        // No padding occurred, so no warning entry exists at all: an
        // execution that padded nothing is provenance-identical to one
        // that could not pad.
        #expect(output.provenance.warnings.isEmpty)
    }

    @Test("[Operation][VOX-IMG-008] fixture 2: the coarser grid replicates its border")
    func coarserGridReplicatesItsBorder() async throws {
        let output = try await execute(
            try volume(geometry: try identityVolumeGeometry()),
            request: try geometry(
                elements: [
                    2, 0, 0, 0.5,
                    0, 2, 0, 0.5,
                    0, 0, 2, 0.5,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            ),
            extents: [2, 2, 2]
        )
        // The upper centres sit exactly on the inclusive support edge
        // 2.5 and replicate the border: 16, not the extrapolation 17.
        #expect(try bytes(output) == [13, 16, 22, 25, 40, 43, 49, 52])
        #expect(output.provenance.warnings.isEmpty)
    }

    @Test("[Operation][VOX-IMG-008] fixture 3: an axis-exchanging grid transposes")
    func axisExchangingGridTransposes() async throws {
        let output = try await execute(
            try volume(geometry: try identityVolumeGeometry()),
            request: try geometry(
                elements: [
                    0, 0, 1, 0,
                    0, 1, 0, 0,
                    1, 0, 0, 0,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            ),
            extents: [3, 3, 3]
        )
        #expect(
            try bytes(output) == [
                0, 18, 36, 6, 24, 42, 12, 30, 48,
                2, 20, 38, 8, 26, 44, 14, 32, 50,
                4, 22, 40, 10, 28, 46, 16, 34, 52,
            ]
        )
    }

    @Test("[Operation][VOX-IMG-008] fixture 4: padding is zero and recorded in provenance")
    func paddingIsZeroAndRecordedInProvenance() async throws {
        let output = try await execute(
            try volume(geometry: try identityVolumeGeometry()),
            request: try geometry(
                elements: [
                    1, 0, 0, -1.25,
                    0, 1, 0, 1,
                    0, 0, 1, 1,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            ),
            extents: [3, 1, 1]
        )
        // Outside pads exact zero, the border replicates, and 25.5
        // rounds to 26 under ties-to-even.
        #expect(try bytes(output) == [0, 24, 26])
        let warning = try #require(output.provenance.warnings.first)
        #expect(warning.code.rawValue == GridResampleOperation.paddingWarningCode)
        #expect(warning.severity == .qualityAffecting)
        #expect(warning.occurrenceCount == 1)
        #expect(output.provenance.warnings.count == 1)
    }

    @Test("[Operation][VOX-IMG-008] fixture 5: the support edge is inclusive then exclusive")
    func supportEdgeIsInclusiveThenExclusive() async throws {
        let input = try volume(geometry: try identityVolumeGeometry())
        let inside = try await execute(
            input,
            request: try geometry(
                elements: [
                    1, 0, 0, 2.5,
                    0, 1, 0, 1,
                    0, 0, 1, 1,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            ),
            extents: [1, 1, 1]
        )
        #expect(try bytes(inside) == [28])
        #expect(inside.provenance.warnings.isEmpty)

        let outside = try await execute(
            input,
            request: try geometry(
                elements: [
                    1, 0, 0, 2.5000000000000004,
                    0, 1, 0, 1,
                    0, 0, 1, 1,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            ),
            extents: [1, 1, 1]
        )
        #expect(try bytes(outside) == [0])
        let warning = try #require(outside.provenance.warnings.first)
        #expect(warning.occurrenceCount == 1)
    }

    @Test("[Operation][VOX-IMG-008] fixture 6: quantisation ties resolve to even both ways")
    func quantisationTiesResolveToEvenBothWays() async throws {
        let output = try await execute(
            try volume(geometry: try identityVolumeGeometry()),
            request: try geometry(
                elements: [
                    0.5, 0, 0, 0.25,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            ),
            extents: [2, 1, 1]
        )
        #expect(try bytes(output) == [0, 2])
    }

    @Test("[Operation][VOX-IMG-008] a depth-one grid equals the oblique slice byte for byte")
    func depthOneGridEqualsTheObliqueSliceByteForByte() async throws {
        // The forward order was chosen so this equality is structural
        // (VOXELIA-ALG-0055): same columns, same translation, third
        // column unused at depth one.
        let input = try volume(geometry: try identityVolumeGeometry())
        let planeElements: [Double] = [
            0.5, 0, 1, 0.5,
            0.5, 0, -1, 0.5,
            0, 1, 0, 0.5,
            0, 0, 0, 1,
        ]
        let oblique = try await ObliqueSliceOperation.execute(
            input: input,
            request: try geometry(elements: planeElements, imageAxes: [0, 1]),
            outputWidth: 2,
            outputHeight: 2,
            outputObjectID: try #require(DataObjectID(rawValue: "slice-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-slice")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T09:01:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
        let grid = try await execute(
            input,
            request: try geometry(elements: planeElements, imageAxes: [0, 1, 2]),
            extents: [2, 2, 1]
        )
        #expect(try bytes(grid) == (try bytes(oblique)))
    }

    @Test("[Unit][VOX-IMG-008] a rank-two request mapping is refused typed")
    func rankTwoRequestMappingIsRefusedTyped() async throws {
        let input = try volume(geometry: try identityVolumeGeometry())
        await #expect(throws: GridResampleError.unsupportedRequestMapping) {
            _ = try await execute(
                input,
                request: try geometry(
                    elements: [
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1,
                    ],
                    imageAxes: [0, 1]
                ),
                extents: [2, 2, 1]
            )
        }
    }

    @Test("[Unit][VOX-IMG-008] a coordinate-space mismatch is refused typed")
    func coordinateSpaceMismatchIsRefusedTyped() async throws {
        let input = try volume(geometry: try identityVolumeGeometry())
        await #expect(throws: GridResampleError.coordinateSpaceMismatch) {
            _ = try await execute(
                input,
                request: try geometry(
                    elements: [
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1,
                    ],
                    imageAxes: [0, 1, 2],
                    spaceID: "scanner"
                ),
                extents: [2, 2, 1]
            )
        }
    }

    @Test("[Unit][VOX-IMG-008] an uncalibrated volume is refused typed")
    func uncalibratedVolumeIsRefusedTyped() async throws {
        let input = try volume(geometry: nil)
        await #expect(throws: GridResampleError.volumeNotSpatiallyCalibrated) {
            _ = try await execute(
                input,
                request: try geometry(
                    elements: [
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1,
                    ],
                    imageAxes: [0, 1, 2]
                ),
                extents: [2, 2, 1]
            )
        }
    }

    @Test("[Unit][VOX-IMG-008] extent and budget ceilings are refused distinctly")
    func extentAndBudgetCeilingsAreRefusedDistinctly() async throws {
        let input = try volume(geometry: try identityVolumeGeometry())
        let request = try geometry(
            elements: [
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ],
            imageAxes: [0, 1, 2]
        )
        await #expect(throws: GridResampleError.invalidOutputExtent) {
            _ = try await execute(input, request: request, extents: [0, 2, 2])
        }
        await #expect(throws: GridResampleError.invalidOutputExtent) {
            _ = try await execute(input, request: request, extents: [16_385, 1, 1])
        }
        await #expect(throws: GridResampleError.invalidOutputExtent) {
            _ = try await execute(input, request: request, extents: [2, 2])
        }
        // Every dimension is inside the per-dimension ceiling, so only
        // the total budget refuses this shape — checked before any
        // allocation or read.
        await #expect(throws: GridResampleError.outputBudgetExceeded) {
            _ = try await execute(input, request: request, extents: [16_384, 16_384, 5])
        }
        // The budget boundary sits exactly at the recorded arithmetic;
        // executing a gibibyte output is not a unit test, so the
        // boundary itself is asserted as the frozen constant.
        #expect(GridResampleOperation.maximumOutputSampleCount == 16_384 * 16_384 * 4)
        #expect(GridResampleOperation.maximumOutputSampleCount == 1_024 * 1_024 * 1_024)
    }

    @Test("[Unit][VOX-IMG-008] the per-dimension ceiling itself is admitted")
    func perDimensionCeilingItselfIsAdmitted() async throws {
        let output = try await execute(
            try volume(geometry: try identityVolumeGeometry()),
            request: try geometry(
                elements: [
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ],
                imageAxes: [0, 1, 2]
            ),
            extents: [16_384, 1, 1]
        )
        #expect(output.descriptor.shape.extents == [16_384, 1, 1])
    }

    @Test("[Operation][VOX-IMG-008] the output claims the request geometry verbatim")
    func outputClaimsTheRequestGeometryVerbatim() async throws {
        let request = try geometry(
            elements: [
                2, 0, 0, 0.5,
                0, 2, 0, 0.5,
                0, 0, 2, 0.5,
                0, 0, 0, 1,
            ],
            imageAxes: [0, 1, 2]
        )
        let output = try await execute(
            try volume(geometry: try identityVolumeGeometry()),
            request: request,
            extents: [2, 2, 2]
        )
        #expect(output.descriptor.spatialGeometry == .affine(request))
    }
}
