// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("ResampleNearestOperation")
struct ResampleNearestOperationTests {
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
        sampling: AxisSampling = .indexOnly,
        geometry: SpatialGeometry? = nil
    ) throws -> ImageData {
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: 1
        )
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: [4, 3]),
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
                    binding: binding,
                    bytes: Array(0..<12)
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-in")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T04:00:00Z"),
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
                    overCanonicalPackedBytes: Array(0..<12)
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
        try await ResampleNearestOperation.execute(
            input: input,
            outputWidth: width,
            outputHeight: height,
            outputObjectID: try #require(DataObjectID(rawValue: "series-8")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-out")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T04:05:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 64)
        )
    }

    private func bytes(_ image: ImageData, width: Int, height: Int) throws -> [UInt8] {
        try image.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [width, height])
        ).bytes
    }

    @Test("[Unit][VOX-EXE-002][VOX-IMG-001] the frozen index model reproduces the fixtures")
    func frozenIndexModelReproducesTheFixtures() async throws {
        // The VOXELIA-ALG-0008 upsampling fixture: 4x3 to 8x6
        // duplicates every sample into a 2x2 block.
        let source = try input()
        let upsampled = try await execute(input: source, width: 8, height: 6)
        #expect(
            try bytes(upsampled, width: 8, height: 6) == [
                0, 0, 1, 1, 2, 2, 3, 3, 0, 0, 1, 1, 2, 2, 3, 3,
                4, 4, 5, 5, 6, 6, 7, 7, 4, 4, 5, 5, 6, 6, 7, 7,
                8, 8, 9, 9, 10, 10, 11, 11, 8, 8, 9, 9, 10, 10, 11, 11,
            ]
        )

        // The downsampling fixture selects columns one and three, and
        // equal dimensions are the identity mapping.
        let downsampled = try await execute(input: source, width: 2, height: 3)
        #expect(try bytes(downsampled, width: 2, height: 3) == [1, 3, 5, 7, 9, 11])
        let identity = try await execute(input: source, width: 4, height: 3)
        #expect(try bytes(identity, width: 4, height: 3) == Array(0..<12))

        // The parameter digest reproduces independently, and the
        // output admits into a depth-two complete graph.
        let expectedDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try ResampleNearestOperation.parameterCollection(
                    outputWidth: 8,
                    outputHeight: 6
                ),
                maximumOutputByteCount: 65_536
            )
        )
        #expect(upsampled.identity.derivation?.parameterDigest == expectedDigest)
        #expect(
            upsampled.identity.derivation?.operationID.rawValue
                == "org.voxelia.op.resample-nearest"
        )
        let graph = try ProvenanceGraph.admitCompleteGraph(
            records: [source.provenance, upsampled.provenance],
            roots: [upsampled.provenance.id],
            limits: try ProvenanceGraphLimits(
                maximumRecordCount: 4,
                maximumParentEdgeCount: 4,
                maximumAncestryDepth: 4,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            )
        )
        #expect(graph.maximumResolvedAncestryDepth == 2)
        #expect(graph.authority == .complete)

        requireSendable(ResampleError.self)
    }

    @Test("[Unit][VOX-EXE-002][VOX-MPR-003] calibration rescales under the registered rules")
    func calibrationRescalesUnderTheRegisteredRules() async throws {
        // The ADR-0126 rescale fixtures at both scales one half: the
        // regular axis and the affine matrix, with the coordinate
        // space preserved and the widened version in the recipe.
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
        #expect(rescaled.coordinateSpace.id.rawValue == "patient")
        #expect(
            calibrated.identity.derivation?.operationVersion
                == (try SemanticVersion(major: 1, minor: 1, patch: 0))
        )
    }

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] admission rejects unsupported inputs typed")
    func admissionRejectsUnsupportedInputsTyped() async throws {
        // Irregular payloads and out-of-range extents reject typed;
        // rank admission mirrors the accepted pattern, and regular
        // sampling is admitted since ADR-0126.
        do {
            _ = try await execute(
                input: try input(
                    sampling: .irregular(coordinates: [1, 2, 4, 8])
                ),
                width: 8,
                height: 6
            )
            #expect(Bool(false), "Expected an irregular payload to be rejected.")
        } catch ResampleError.unsupportedAxisSampling {}
        for (width, height) in [(0, 6), (8, 0), (16_385, 6), (8, -1)] {
            do {
                _ = try await execute(input: try input(), width: width, height: height)
                #expect(Bool(false), "Expected an invalid extent to be rejected.")
            } catch ResampleError.invalidOutputExtent {}
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
