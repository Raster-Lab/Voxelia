// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

@Suite("BrickedPipeline")
struct BrickedPipelineTests {
    private let extents = [5, 4, 3]
    private let volumeBytes: [UInt8] = (0..<60).map(UInt8.init)

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func binding() throws -> LogicalSampleBinding {
        try LogicalSampleBinding(
            shape: try ImageShape(extents: ContiguousArray(extents)),
            scalarType: .uint8,
            componentCount: 1
        )
    }

    private func brickedStorage() throws -> AnyImageStorage {
        let grid = try BrickGridDescriptor(
            volumeExtents: [5, 4, 3],
            nominalBrickExtents: [2, 3, 2],
            haloExtents: [0, 0, 0]
        )
        var payloads: [ContiguousArray<Int>: [UInt8]] = [:]
        let counts = grid.brickCounts
        for k in 0..<counts[2] {
            for j in 0..<counts[1] {
                for i in 0..<counts[0] {
                    let coordinate: ContiguousArray<Int> = [i, j, k]
                    let core = try grid.coreRegion(of: coordinate)
                    var payload = [UInt8]()
                    for z in core.lowerBounds[2]..<core.upperBounds[2] {
                        for y in core.lowerBounds[1]..<core.upperBounds[1] {
                            for x in core.lowerBounds[0]..<core.upperBounds[0] {
                                payload.append(
                                    volumeBytes[
                                        x + extents[0] * (y + extents[1] * z)
                                    ]
                                )
                            }
                        }
                    }
                    payloads[coordinate] = payload
                }
            }
        }
        return AnyImageStorage(
            erasing: try BrickedImageStorage(
                binding: try binding(),
                grid: grid,
                bricks: payloads
            )
        )
    }

    private func contiguousStorage() throws -> AnyImageStorage {
        AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try binding(),
                bytes: volumeBytes
            )
        )
    }

    private func image(
        storage: AnyImageStorage,
        name: String
    ) throws -> ImageData {
        func axis(_ id: String, semantic: AxisSemantic) throws -> AxisDescriptor {
            try AxisDescriptor(
                id: try #require(AxisID(rawValue: id)),
                name: id,
                semantic: semantic,
                unit: nil,
                sampling: .indexOnly
            )
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
                axes: [
                    try axis("x", semantic: .spatialX),
                    try axis("y", semantic: .spatialY),
                    try axis("z", semantic: .spatialZ),
                ],
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: storage,
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: "record-\(name)")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T10:30:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: name))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: name)),
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: volumeBytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.\(name)",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    @Test("[Unit][VOX-IMG-001][VOX-BRK-001] a bricked-backed image flows through the pipeline")
    func brickedBackedImageFlowsThroughThePipeline() async throws {
        // The ADR-0156 end-to-end story: the aggregate constructs over
        // the composite representation, and region extraction over the
        // bricked-backed input is byte-identical to the same volume
        // contiguous-backed — brickedness invisible through the whole
        // operation pipeline.
        let bricked = try image(storage: try brickedStorage(), name: "volume-b")
        let contiguous = try image(
            storage: try contiguousStorage(),
            name: "volume-c"
        )
        let region = try ImageRegion(
            lowerBounds: [1, 1, 1],
            upperBounds: [4, 4, 3]
        )
        func extract(
            _ input: ImageData,
            objectName: String
        ) async throws -> ImageData {
            try await RegionExtractionOperation.execute(
                input: input,
                region: region,
                outputObjectID: try #require(DataObjectID(rawValue: objectName)),
                outputProvenanceID: try #require(
                    ProvenanceID(rawValue: "record-\(objectName)")
                ),
                createdAt: try CanonicalInstant(utcString: "2026-08-05T10:31:00Z"),
                software: try software(),
                coordinator: StorageReadCoordinator(
                    maximumRetainedResultByteCount: 64
                )
            )
        }
        let brickedOutput = try await extract(bricked, objectName: "slice-b")
        let contiguousOutput = try await extract(contiguous, objectName: "slice-c")
        let outputRegion = try ImageRegion(
            lowerBounds: [0, 0, 0],
            upperBounds: [3, 3, 2]
        )
        let brickedBytes = try brickedOutput.storage.read(region: outputRegion).bytes
        let contiguousBytes = try contiguousOutput.storage.read(
            region: outputRegion
        ).bytes
        #expect(brickedBytes == contiguousBytes)
        #expect(
            brickedOutput.identity.contentID == contiguousOutput.identity.contentID
        )
    }
}
