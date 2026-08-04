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
        sampling: AxisSampling = .indexOnly
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
                spatialGeometry: nil,
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

    @Test("[Unit][VOX-EXE-006][VOX-ERR-001] admission rejects unsupported inputs typed")
    func admissionRejectsUnsupportedInputsTyped() async throws {
        // Regular sampling and out-of-range extents reject typed;
        // rank and geometry admission mirror the accepted pattern.
        do {
            _ = try await execute(
                input: try input(sampling: .regular(origin: 0, spacing: 1)),
                width: 8,
                height: 6
            )
            #expect(Bool(false), "Expected regular sampling to be rejected.")
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
