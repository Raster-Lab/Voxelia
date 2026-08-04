// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

@Suite("ExactSliceRenderer")
struct ExactSliceRendererTests {
    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func axis(_ id: String) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func originImage() throws -> ImageData {
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
                axes: [try axis("x"), try axis("y")],
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

    private func makeRenderer(
        publisher: PublicationCoordinator,
        prefix: String
    ) throws -> ExactSliceRenderer {
        ExactSliceRenderer(
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 96
            ),
            software: try software(),
            naming: { stage in
                let suffix: String
                switch stage {
                case .windowLevelled(let layerIndex):
                    suffix = "wl\(layerIndex)"
                case .composited:
                    suffix = "cp"
                case .resampled:
                    suffix = "rs"
                }
                return (
                    outputObjectID: DataObjectID(rawValue: "\(prefix)-\(suffix)")!,
                    provenanceID: ProvenanceID(rawValue: "record-\(prefix)-\(suffix)")!,
                    createdAt: try CanonicalInstant(
                        utcString: "2026-08-05T04:05:00Z"
                    )
                )
            }
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

    private func layer(
        _ objectName: String,
        center: Double = 6,
        width: Double = 8,
        opacity: Double = 1
    ) throws -> RenderLayer {
        try RenderLayer(
            imageObjectID: try #require(DataObjectID(rawValue: objectName)),
            transferFunction: .greyscaleWindow(
                try GreyscaleWindowFunction(center: center, width: width)
            ),
            opacity: opacity
        )
    }

    private func scene(_ layers: [RenderLayer]) throws -> SceneSnapshot {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        return try SceneSnapshot(
            layers: ContiguousArray(layers),
            camera: try RenderCamera(
                position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
                target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
                projection: .orthographic(planeHeight: 250)
            )
        )
    }

    @Test("[Unit][VOX-VS1-017][VOX-VS1-019] the first vertical slice renders end to end")
    func firstVerticalSliceRendersEndToEnd() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "render-1")

        // Rendering at the image extents produces exactly the
        // registered window-level fixture, published with depth-two
        // complete provenance and full presentation claims; no
        // identity resample is minted.
        let result = try await renderer.render(
            RenderRequest(
                scene: try scene([try layer("series-7")]),
                viewport: try ViewportSize(width: 4, height: 3),
                quality: .full
            )
        )
        #expect(result.outputObjectID.rawValue == "render-1-wl0")
        #expect(result.presentation.renderMode == .slice)
        #expect(result.presentation.colourOutput == .greyscale8)
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
        #expect(outputBytes == [0, 0, 0, 36, 73, 109, 146, 182, 219, 255, 255, 255])
        #expect(published.provenance.inputs.count == 1)
        #expect(await publisher.publishedObjectCount == 2)

        // Admission rejection: an unpublished image is typed.
        do {
            _ = try await renderer.render(
                RenderRequest(
                    scene: try scene([try layer("series-9")]),
                    viewport: try ViewportSize(width: 4, height: 3),
                    quality: .full
                )
            )
            #expect(Bool(false), "Expected an unpublished image to be rejected.")
        } catch SliceRendererError.imageNotPublished {}

        // The ADR-0094 single-layer fade routes through the published
        // composite stage: the registered fixture at half opacity over
        // the black background.
        let fadeRenderer = try makeRenderer(publisher: publisher, prefix: "render-1f")
        let faded = try await fadeRenderer.render(
            RenderRequest(
                scene: try scene([try layer("series-7", opacity: 0.5)]),
                viewport: try ViewportSize(width: 4, height: 3),
                quality: .full
            )
        )
        #expect(faded.outputObjectID.rawValue == "render-1f-cp")
        let fadedImage = try #require(
            await publisher.publishedImage(for: faded.outputObjectID)
        )
        let fadedBytes = try fadedImage.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
        #expect(fadedBytes == [0, 0, 0, 18, 36, 54, 73, 91, 110, 128, 128, 128])
        #expect(await publisher.publishedObjectCount == 4)

        requireSendable(ExactSliceRenderer.self)
        requireSendable(SliceRendererError.self)
        requireSendable(RenderPublicationStage.self)
    }

    @Test("[Unit][VOX-VS1-017][VOX-VS1-019] a differing viewport resamples both stages")
    func differingViewportResamplesBothStages() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "render-2")

        // Rendering at twice the extents composes window-level with the
        // ADR-0088 resampling operation: the registered fixture bytes
        // duplicated into 2-by-2 blocks, with both derived stages
        // published as a depth-three complete chain.
        let result = try await renderer.render(
            RenderRequest(
                scene: try scene([try layer("series-7")]),
                viewport: try ViewportSize(width: 8, height: 6),
                quality: .full
            )
        )
        #expect(result.outputObjectID.rawValue == "render-2-rs")
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [8, 6])
        ).bytes
        #expect(
            outputBytes == [
                0, 0, 0, 0, 0, 0, 36, 36, 0, 0, 0, 0, 0, 0, 36, 36,
                73, 73, 109, 109, 146, 146, 182, 182,
                73, 73, 109, 109, 146, 146, 182, 182,
                219, 219, 255, 255, 255, 255, 255, 255,
                219, 219, 255, 255, 255, 255, 255, 255,
            ]
        )
        #expect(await publisher.publishedObjectCount == 3)
        let intermediateID = try #require(DataObjectID(rawValue: "render-2-wl0"))
        #expect(await publisher.publishedImage(for: intermediateID) != nil)
        let resampledRecordID = try #require(ProvenanceID(rawValue: "record-render-2-rs"))
        let intermediateRecordID = try #require(
            ProvenanceID(rawValue: "record-render-2-wl0")
        )
        let resampledRecord = try #require(
            await publisher.publishedProvenanceRecord(for: resampledRecordID)
        )
        #expect(resampledRecord.inputs[0].parent == .graphNode(intermediateRecordID))
    }

    @Test("[Unit][VOX-VS1-017][VOX-ARC-008] a two-layer scene composites end to end")
    func twoLayerSceneCompositesEndToEnd() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "render-3")

        // Two layers over the same published object with different
        // windows blend per the registered ALG-0009 fixture: every
        // stage is published and the composite record carries both
        // parent edges.
        let result = try await renderer.render(
            RenderRequest(
                scene: try scene([
                    try layer("series-7"),
                    try layer("series-7", center: 3, width: 6, opacity: 0.5),
                ]),
                viewport: try ViewportSize(width: 4, height: 3),
                quality: .full
            )
        )
        #expect(result.outputObjectID.rawValue == "render-3-cp")
        #expect(result.presentation.layers.count == 2)
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
        #expect(outputBytes == [0, 26, 51, 94, 138, 182, 200, 218, 237, 255, 255, 255])
        #expect(await publisher.publishedObjectCount == 4)
        let compositeRecordID = try #require(ProvenanceID(rawValue: "record-render-3-cp"))
        let compositeRecord = try #require(
            await publisher.publishedProvenanceRecord(for: compositeRecordID)
        )
        #expect(compositeRecord.inputs.count == 2)
        let firstParent = try #require(ProvenanceID(rawValue: "record-render-3-wl0"))
        let secondParent = try #require(ProvenanceID(rawValue: "record-render-3-wl1"))
        #expect(compositeRecord.inputs[0].parent == .graphNode(firstParent))
        #expect(compositeRecord.inputs[1].parent == .graphNode(secondParent))
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
