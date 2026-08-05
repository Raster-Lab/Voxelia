// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

@Suite("ExactVolumeRenderer")
struct ExactVolumeRendererTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func publisher() throws -> PublicationCoordinator {
        PublicationCoordinator(
            maximumPublishedObjectCount: 8,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 8,
                maximumParentEdgeCount: 8,
                maximumAncestryDepth: 8,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 64
            ),
            resultCache: nil
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

    private func identityGeometry() throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: Matrix4x4Double.identity,
            coordinateSpace: try space()
        )
    }

    /// The established fixture volume: extents (3, 3, 3) with stored
    /// value `2*i0 + 6*i1 + 18*i2`.
    private func volume(
        geometry: SpatialGeometry?,
        extents: [Int] = [3, 3, 3]
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
            axes.append(
                try AxisDescriptor(
                    id: try #require(AxisID(rawValue: names[index])),
                    name: names[index],
                    semantic: semantics[index],
                    unit: nil,
                    sampling: .indexOnly
                )
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
                id: try #require(ProvenanceID(rawValue: "record-volume")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-05T12:00:00Z"),
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
                        identifier: "1.2.840.113619.12",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func rampTable() throws -> TransferFunction1D {
        var entries = ContiguousArray<TransferFunctionEntry>()
        for index in 0..<256 {
            let level = UInt8(index)
            entries.append(
                TransferFunctionEntry(
                    red: level,
                    green: level,
                    blue: level,
                    opacity: level
                )
            )
        }
        return try TransferFunction1D(entries: entries)
    }

    private func request() throws -> VolumeRenderRequest {
        let id = try #require(CoordinateSpaceID(rawValue: "patient"))
        return VolumeRenderRequest(
            volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
            table: try rampTable(),
            camera: try RenderCamera(
                position: try Point3D(x: 1, y: 1, z: -5, coordinateSpace: id),
                target: try Point3D(x: 1, y: 1, z: 1, coordinateSpace: id),
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: id),
                projection: .orthographic(planeHeight: 4)
            ),
            viewport: try ViewportSize(width: 2, height: 2),
            quality: "org.voxelia.quality.full"
        )
    }

    @Test("[Integration][VOX-DVR-001][VOX-DVR-014] the volume renders end to end")
    func volumeRendersEndToEnd() async throws {
        // The end-to-end proof: the rendered bytes equal per-ray
        // expectations composed in this test from the same accepted
        // authorities, the claims record what ran, and repetition is
        // bit-identical — DVR-014's determinism structural.
        let publisher = try publisher()
        _ = try await publisher.publish(
            try volume(geometry: .affine(try identityGeometry())),
            mode: .complete
        )
        let renderer = ExactVolumeRenderer(
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 64
            ),
            software: try software()
        )
        let request = try request()
        let result = try await renderer.render(
            request,
            outputObjectID: try #require(DataObjectID(rawValue: "render-1")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-render")),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T12:01:00Z")
        )

        // Compose the expectations from the same authorities.
        let geometry = try identityGeometry()
        let extents: ContiguousArray<Int> = [3, 3, 3]
        var volumeBytes = [UInt8](repeating: 0, count: 27)
        for i2 in 0..<3 {
            for i1 in 0..<3 {
                for i0 in 0..<3 {
                    volumeBytes[i0 + 3 * (i1 + 3 * i2)] = UInt8(
                        2 * i0 + 6 * i1 + 18 * i2
                    )
                }
            }
        }
        let generator = try OrthographicRayGenerator(
            camera: request.camera,
            viewport: request.viewport
        )
        let sampler = try VolumeRaySampler(
            geometry: geometry,
            extents: extents,
            quality: request.quality
        )
        var expected = [UInt8]()
        for pixelY in 0..<2 {
            for pixelX in 0..<2 {
                let plan = try sampler.plan(
                    for: try generator.ray(atPixelX: pixelX, pixelY: pixelY)
                )
                var samples = [UInt8]()
                for index in 0..<plan.sampleCount {
                    samples.append(
                        ObliqueSliceOperation.sample(
                            Array(plan.indexPosition(at: index)),
                            extents: extents,
                            bytes: volumeBytes
                        )
                    )
                }
                let ray = VolumeRayCompositor.composite(
                    samples: samples,
                    table: request.table
                )
                expected.append(contentsOf: [ray.red, ray.green, ray.blue, ray.alpha])
            }
        }
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let rendered = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [2, 2])
        ).bytes
        #expect(rendered == expected)
        #expect(rendered.contains { $0 != 0 })

        // The claims record what ran.
        #expect(result.presentation.renderMode == .volumeDirect)
        #expect(result.presentation.colourOutput == .rgba8)
        #expect(result.presentation.layers.isEmpty)
        #expect(result.presentation.geometry == .affine(geometry))
        #expect(result.presentation.scaling == .identity)
        #expect(published.descriptor.components.interpretation == .rgba)
        #expect(published.descriptor.semantic == .colour)
        guard case .operation(let operation, _) = published.provenance.activity
        else {
            #expect(Bool(false), "Expected operation provenance.")
            return
        }
        #expect(
            operation.operationID.rawValue
                == ExactVolumeRenderer.operationIdentifier
        )

        // Determinism is structural: a second render is bit-identical.
        let second = try await renderer.render(
            request,
            outputObjectID: try #require(DataObjectID(rawValue: "render-2")),
            outputProvenanceID: try #require(
                ProvenanceID(rawValue: "record-render-2")
            ),
            createdAt: try CanonicalInstant(utcString: "2026-08-05T12:02:00Z")
        )
        let secondImage = try #require(
            await publisher.publishedImage(for: second.outputObjectID)
        )
        let secondBytes = try secondImage.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [2, 2])
        ).bytes
        #expect(secondBytes == rendered)
    }

    @Test("[Unit][VOX-ERR-001] volume render admissions reject typed")
    func volumeRenderAdmissionsRejectTyped() async throws {
        let publisher = try publisher()
        let renderer = ExactVolumeRenderer(
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 64
            ),
            software: try software()
        )
        let request = try request()
        func render() async throws {
            _ = try await renderer.render(
                request,
                outputObjectID: try #require(DataObjectID(rawValue: "render-x")),
                outputProvenanceID: try #require(
                    ProvenanceID(rawValue: "record-render-x")
                ),
                createdAt: try CanonicalInstant(utcString: "2026-08-05T12:03:00Z")
            )
        }
        await #expect(throws: VolumeRenderError.volumeNotPublished) {
            try await render()
        }
        _ = try await publisher.publish(try volume(geometry: nil), mode: .complete)
        await #expect(throws: VolumeRenderError.volumeNotSpatiallyCalibrated) {
            try await render()
        }
    }
}
