// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("ResampleLinearOperation")
struct ResampleLinearOperationTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func axis(
        _ id: String,
        sampling: AxisSampling = .indexOnly
    ) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: sampling
        )
    }

    private func input(
        extents: [Int],
        bytes: [UInt8],
        sampling: AxisSampling = .indexOnly,
        geometry: SpatialGeometry? = nil
    ) throws -> ImageData {
        try ImageData(
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
                axes: [try axis("x", sampling: sampling), try axis("y")],
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
                createdAt: try CanonicalInstant(utcString: "2026-08-05T08:20:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: "series-7"))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: "series-7")),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.2",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func execute(
        input: ImageData,
        width: Int,
        height: Int
    ) async throws -> ImageData {
        try await ResampleLinearOperation.execute(
            input: input,
            outputWidth: width,
            outputHeight: height,
            outputObjectID: try #require(DataObjectID(rawValue: "series-8")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T08:25:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func bytes(_ image: ImageData, width: Int, height: Int) throws -> [UInt8] {
        try image.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [width, height])
        ).bytes
    }

    @Test("[Operation][VOX-EXE-002][VOX-R2D-013] the frozen interpolation reproduces the fixtures")
    func frozenInterpolationReproducesTheFixtures() async throws {
        // The VOXELIA-ALG-0015 fixtures: the 2-by-2 upscale, the
        // 4-by-3 downscale, and the exact identity at equal
        // dimensions.
        let corner = try input(extents: [2, 2], bytes: [10, 20, 30, 40])
        let upscaled = try await execute(input: corner, width: 4, height: 4)
        #expect(
            try bytes(upscaled, width: 4, height: 4) == [
                10, 12, 18, 20, 15, 18, 22, 25,
                25, 28, 32, 35, 30, 32, 38, 40,
            ]
        )
        let gradient = try input(extents: [4, 3], bytes: Array(0..<12))
        let downscaled = try await execute(input: gradient, width: 2, height: 3)
        #expect(try bytes(downscaled, width: 2, height: 3) == [0, 2, 4, 6, 8, 10])
        let identity = try await execute(input: gradient, width: 4, height: 3)
        #expect(try bytes(identity, width: 4, height: 3) == Array(0..<12))

        // The parameter digest reproduces independently under the
        // linear operation's own namespace.
        let expectedDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try ResampleLinearOperation.parameterCollection(
                    outputWidth: 4,
                    outputHeight: 4
                ),
                maximumOutputByteCount: 65_536
            )
        )
        #expect(upscaled.identity.derivation?.parameterDigest == expectedDigest)
        #expect(
            upscaled.identity.derivation?.operationID.rawValue
                == "org.voxelia.op.resample-linear"
        )

        requireSendable(ResampleLinearError.self)
    }

    @Test("[Operation][VOX-EXE-002][VOX-MPR-003] linear calibration rescales identically")
    func linearCalibrationRescalesIdentically() async throws {
        // The registered rescale fixtures through the linear
        // operation at the widened version — the same shared rule
        // authority the nearest operation evaluates.
        let space = try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length
            ),
            externalReferences: []
        )
        let affine = try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
            indexToWorld: try Matrix4x4Double(elements: [
                0, -2, 0, 10,
                2, 0, 0, 20,
                0, 0, 1, 30,
                0, 0, 0, 1,
            ]),
            coordinateSpace: space
        )
        let calibrated = try await execute(
            input: try input(
                extents: [4, 3],
                bytes: Array(0..<12),
                sampling: .regular(origin: 5, spacing: 2.5),
                geometry: .affine(affine)
            ),
            width: 8,
            height: 6
        )
        guard
            case .regular(let origin, let spacing) =
                calibrated.descriptor.axes[0].sampling
        else {
            #expect(Bool(false), "Expected a rescaled regular axis.")
            return
        }
        #expect(origin == 4.375)
        #expect(spacing == 1.25)
        guard
            case .affine(let rescaled)? = calibrated.descriptor.spatialGeometry
        else {
            #expect(Bool(false), "Expected the geometry to be preserved.")
            return
        }
        #expect(
            rescaled.indexToWorld.elements == [
                0, -1, 0, 10.5,
                1, 0, 0, 19.5,
                0, 0, 1, 30,
                0, 0, 0, 1,
            ]
        )
        #expect(
            calibrated.identity.derivation?.operationVersion
                == (try SemanticVersion(major: 1, minor: 1, patch: 0))
        )
    }

    @Test("[Operation][VOX-EXE-006][VOX-ERR-001] linear admission rejects typed")
    func linearAdmissionRejectsTyped() async throws {
        let gradient = try input(extents: [4, 3], bytes: Array(0..<12))

        // Irregular payloads and out-of-range extents reject typed;
        // regular sampling is admitted since ADR-0127.
        do {
            _ = try await execute(
                input: try input(
                    extents: [4, 3],
                    bytes: Array(0..<12),
                    sampling: .irregular(coordinates: [1, 2, 4, 8])
                ),
                width: 8,
                height: 6
            )
            #expect(Bool(false), "Expected an irregular payload to be rejected.")
        } catch ResampleLinearError.unsupportedAxisSampling {}
        for (width, height) in [(0, 6), (8, 0), (16_385, 6)] {
            do {
                _ = try await execute(input: gradient, width: width, height: height)
                #expect(Bool(false), "Expected an invalid extent to be rejected.")
            } catch ResampleLinearError.invalidOutputExtent {}
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
