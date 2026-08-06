// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

@Suite("ExactSliceRenderer")
struct ExactSliceRendererTests {
    private final class NamingSequence: Sendable {
        private let nextOrdinal = Mutex(0)

        func names(
            for stage: RenderPublicationStage
        ) throws -> (
            outputObjectID: DataObjectID,
            provenanceID: ProvenanceID,
            createdAt: CanonicalInstant
        ) {
            let ordinal = nextOrdinal.withLock { nextOrdinal in
                defer { nextOrdinal += 1 }
                return nextOrdinal
            }
            let suffix: String
            switch stage {
            case .cropped(let layerIndex):
                suffix = "cr\(layerIndex)"
            case .windowLevelled(let layerIndex):
                suffix = "wl\(layerIndex)"
            case .inverted(let layerIndex):
                suffix = "iv\(layerIndex)"
            case .composited:
                suffix = "cp"
            case .resampled:
                suffix = "rs"
            }
            return (
                outputObjectID: try #require(
                    DataObjectID(
                        rawValue: "render-concurrent-\(ordinal)-\(suffix)"
                    )
                ),
                provenanceID: try #require(
                    ProvenanceID(
                        rawValue: "record-render-concurrent-\(ordinal)-\(suffix)"
                    )
                ),
                createdAt: try CanonicalInstant(
                    utcString: "2026-08-05T04:05:00Z"
                )
            )
        }
    }

    private actor UncooperativeStageGate {
        private var didStart = false
        private var startWaiters = [CheckedContinuation<Void, Never>]()
        private var releaseContinuation: CheckedContinuation<Void, Never>?

        func suspend() async {
            await withCheckedContinuation { continuation in
                releaseContinuation = continuation
                didStart = true
                let waiters = startWaiters
                startWaiters.removeAll()
                for waiter in waiters {
                    waiter.resume()
                }
            }
        }

        func waitUntilStarted() async {
            guard !didStart else {
                return
            }
            await withCheckedContinuation { continuation in
                startWaiters.append(continuation)
            }
        }

        func release() {
            let continuation = releaseContinuation
            releaseContinuation = nil
            continuation?.resume()
        }
    }

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
                case .cropped(let layerIndex):
                    suffix = "cr\(layerIndex)"
                case .inverted(let layerIndex):
                    suffix = "iv\(layerIndex)"
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
                try GreyscaleWindowFunction(center: center, width: width, polarity: .standard)
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

    @Test(
        "[Unit][VOX-R2D-015][VOX-ERR-001] a colour output this renderer cannot produce is rejected"
    )
    func colourOutputThisRendererCannotProduceIsRejected() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "render-c")

        func request(
            _ output: ColourOutputConfiguration,
            _ transform: DisplayColourTransform,
            _ colourSpace: DisplayColourSpace? = nil
        ) throws -> RenderRequest {
            RenderRequest(
                scene: try scene([try layer("series-7")]),
                viewport: try ViewportSize(width: 4, height: 3),
                crop: nil,
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: output,
                colourTransform: transform,
                outputColourSpace: colourSpace
            )
        }

        // Without this rejection the request's colour claim would be
        // decorative: the renderer would ignore it and still report a
        // provenance that looked correct.
        for unsupported in [
            try request(.rgba8, .none),
            try request(.greyscale8, .transferFunction),
            try request(.greyscale8, .palette),
            try request(.greyscale8, .rgb),
        ] {
            await #expect(throws: RenderModelError.unsupportedColourOutput) {
                _ = try await renderer.render(unsupported)
            }
        }

        // The provenance reports what the renderer DID, and it agrees with the
        // request by construction rather than by copying. The declared colour
        // space is carried through, never converted.
        let space = try DisplayColourSpace(
            namespace: "IEC",
            code: "sRGB",
            displayName: nil
        )
        let declared = try await renderer.render(
            try request(.greyscale8, .none, space)
        )
        #expect(declared.presentation.colourOutput == .greyscale8)
        #expect(declared.presentation.colourTransform == .none)
        #expect(declared.presentation.outputColourSpace == space)

        // An absent declaration stays absent: no default is substituted. A
        // second renderer mints its own output identity.
        let undeclared = try await makeRenderer(
            publisher: publisher,
            prefix: "render-d"
        )
        .render(try request(.greyscale8, .none))
        #expect(undeclared.presentation.outputColourSpace == nil)
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
                crop: nil,
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil
            )
        )
        #expect(result.outputObjectID.rawValue == "render-1-wl0")
        #expect(result.presentation.renderMode == .slice)
        #expect(result.presentation.colourOutput == .greyscale8)
        #expect(result.presentation.scaling == .identity)
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
                    crop: nil,
                    interpolation: .nearestNeighbour,
                    quality: .full,
                    colourOutput: .greyscale8,
                    colourTransform: .none,
                    outputColourSpace: nil
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
                crop: nil,
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil
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

    @Test("[Unit][VOX-VS1-017][VOX-ARC-008] a cropped scene extracts before windowing")
    func croppedSceneExtractsBeforeWindowing() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "render-5")

        // The ADR-0102 crop runs the accepted extraction first: the
        // stored sub-region [1, 3) by [0, 2) windows to exactly the
        // fixture's corresponding values, the cropped stage publishes,
        // and the result claims the crop with identity scaling.
        let crop = try RenderCrop(lowerX: 1, lowerY: 0, upperX: 3, upperY: 2)
        let result = try await renderer.render(
            RenderRequest(
                scene: try scene([try layer("series-7")]),
                viewport: try ViewportSize(width: 2, height: 2),
                crop: crop,
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil
            )
        )
        #expect(result.outputObjectID.rawValue == "render-5-wl0")
        #expect(result.presentation.crop == crop)
        #expect(result.presentation.scaling == .identity)
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [2, 2])
        ).bytes
        #expect(outputBytes == [0, 0, 109, 146])
        #expect(await publisher.publishedObjectCount == 3)
        let croppedID = try #require(DataObjectID(rawValue: "render-5-cr0"))
        #expect(await publisher.publishedImage(for: croppedID) != nil)
    }

    @Test("[Unit][VOX-VS1-017][VOX-EXE-004] the composed pipeline renders every stage cached")
    func composedPipelineRendersEveryStageCached() async throws {
        // Every stage kind in one render — two crops, two windows,
        // one composite and one resample — through a publisher wired
        // with a content result cache.
        let cache = ContentResultCache(
            maximumEntryCount: 16,
            maximumTotalByteCount: 4_096
        )
        let publisher = PublicationCoordinator(
            maximumPublishedObjectCount: 8,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 16,
                maximumParentEdgeCount: 16,
                maximumAncestryDepth: 16,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 64
            ),
            resultCache: cache
        )
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "render-6")

        let crop = try RenderCrop(lowerX: 1, lowerY: 0, upperX: 3, upperY: 2)
        let result = try await renderer.render(
            RenderRequest(
                scene: try scene([
                    try layer("series-7"),
                    try layer("series-7", center: 3, width: 6, opacity: 0.5),
                ]),
                viewport: try ViewportSize(width: 4, height: 4),
                crop: crop,
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil
            )
        )
        #expect(result.outputObjectID.rawValue == "render-6-rs")
        #expect(result.presentation.crop == crop)
        #expect(
            result.presentation.scaling
                == .nearestNeighbour(sourceWidth: 2, sourceHeight: 2)
        )
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 4])
        ).bytes
        #expect(
            outputBytes == [
                26, 26, 51, 51, 26, 26, 51, 51,
                182, 182, 200, 200, 182, 182, 200, 200,
            ]
        )
        #expect(await publisher.publishedObjectCount == 7)

        // Every published stage's verified bytes reached the cache as
        // an alias, verifiable under its own content claim.
        let stages = [
            "render-6-cr0", "render-6-cr1", "render-6-wl0", "render-6-wl1",
            "render-6-cp", "render-6-rs",
        ]
        for stage in stages {
            let objectID = try #require(DataObjectID(rawValue: stage))
            let image = try #require(await publisher.publishedImage(for: objectID))
            let claim = try #require(image.identity.contentID)
            let cached = try #require(await cache.lookup(claim))
            #expect(try claim.matchesDigest(ofCanonicalBytes: cached))
        }
    }

    @Test("[Unit][VOX-R2D-013][VOX-VS1-019] the linear policy resamples and claims bilinear")
    func linearPolicyResamplesAndClaimsBilinear() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "render-9")

        // The ADR-0124 linear policy dispatches the registered
        // bilinear operation and the claim states what ran with the
        // pre-resample extents.
        let result = try await renderer.render(
            RenderRequest(
                scene: try scene([try layer("series-7")]),
                viewport: try ViewportSize(width: 8, height: 6),
                crop: nil,
                interpolation: .linear,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil
            )
        )
        #expect(result.outputObjectID.rawValue == "render-9-rs")
        #expect(
            result.presentation.scaling
                == .bilinear(sourceWidth: 4, sourceHeight: 3)
        )
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [8, 6])
        ).bytes
        #expect(
            outputBytes == [
                0, 0, 0, 0, 0, 9, 27, 36,
                18, 20, 25, 30, 34, 46, 64, 72,
                55, 62, 75, 89, 103, 118, 136, 146,
                110, 118, 136, 152, 166, 180, 194, 200,
                182, 192, 210, 221, 225, 230, 234, 237,
                219, 228, 246, 255, 255, 255, 255, 255,
            ]
        )
        guard case .operation(let operation, _) = published.provenance.activity
        else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        #expect(operation.operationID.rawValue == "org.voxelia.op.resample-linear")

        requireSendable(InterpolationPolicy.self)
    }

    @Test("[Unit][VOX-R2D-005][VOX-R2D-008] inverted polarity presents monochrome-one")
    func invertedPolarityPresentsMonochromeOne() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeRenderer(publisher: publisher, prefix: "render-8")

        // An inverted layer runs the registered ADR-0112 involution
        // after the window stage, published, producing exactly the
        // inverted registered fixture — MONOCHROME1 semantics
        // independent of any source-value transformation.
        let invertedScene = try scene([
            try RenderLayer(
                imageObjectID: try #require(DataObjectID(rawValue: "series-7")),
                transferFunction: .greyscaleWindow(
                    try GreyscaleWindowFunction(
                        center: 6,
                        width: 8,
                        polarity: .inverted
                    )
                ),
                opacity: 1
            )
        ])
        let result = try await renderer.render(
            RenderRequest(
                scene: invertedScene,
                viewport: try ViewportSize(width: 4, height: 3),
                crop: nil,
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil
            )
        )
        #expect(result.outputObjectID.rawValue == "render-8-iv0")
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let outputBytes = try published.storage.read(
            region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
        ).bytes
        #expect(
            outputBytes == [255, 255, 255, 219, 182, 146, 109, 73, 36, 0, 0, 0]
        )
        #expect(await publisher.publishedObjectCount == 3)
        guard case .operation(let operation, _) = published.provenance.activity
        else {
            #expect(Bool(false), "Expected an operation activity.")
            return
        }
        #expect(operation.operationID.rawValue == "org.voxelia.op.invert-display")
    }

    @Test("[Unit][VOX-ARC-008][VOX-VS1-019] both qualities execute identically")
    func bothQualitiesExecuteIdentically() async throws {
        // The ADR-0103 equivalence: interactive and full requests over
        // one scene publish identical bytes with identical full
        // quality-policy claims — the request is a hint and the claim
        // records what ran.
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        var outputs = [[UInt8]]()
        var qualityTokens = [String]()
        for (prefix, quality) in [
            ("render-7i", RenderQuality.interactive), ("render-7f", .full),
        ] {
            let renderer = try makeRenderer(publisher: publisher, prefix: prefix)
            let result = try await renderer.render(
                RenderRequest(
                    scene: try scene([try layer("series-7")]),
                    viewport: try ViewportSize(width: 4, height: 3),
                    crop: nil,
                    interpolation: .nearestNeighbour,
                    quality: quality,
                    colourOutput: .greyscale8,
                    colourTransform: .none,
                    outputColourSpace: nil
                )
            )
            let published = try #require(
                await publisher.publishedImage(for: result.outputObjectID)
            )
            outputs.append(
                try published.storage.read(
                    region: try ImageRegion(lowerBounds: [0, 0], upperBounds: [4, 3])
                ).bytes
            )
            guard
                case .operation(_, let claim) = published.provenance.activity
            else {
                #expect(Bool(false), "Expected an operation activity.")
                return
            }
            qualityTokens.append(claim.qualityPolicy.rawValue)
        }
        #expect(outputs[0] == outputs[1])
        #expect(qualityTokens == ["org.voxelia.quality.full", "org.voxelia.quality.full"])
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
                crop: nil,
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil
            )
        )
        #expect(result.outputObjectID.rawValue == "render-2-rs")
        #expect(
            result.presentation.scaling
                == .nearestNeighbour(sourceWidth: 4, sourceHeight: 3)
        )
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
                crop: nil,
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil
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

    @Test("[Concurrency][VOX-CON-003][VOX-VS1-019] one renderer executes concurrently")
    func oneRendererExecutesConcurrently() async throws {
        // This test's subject is concurrent execution, not a retention
        // ceiling; other suites own the ceiling's own evidence. Single-flight
        // coalescing is an optimisation the coordinator is free not to
        // achieve, so both coordinators must admit the worst case in which
        // none of the eight concurrent twelve-byte source reads coalesce.
        // Sizing either one below that made the assertion depend on machine
        // load rather than on the renderer's contract.
        let concurrentRenderCount = 8
        let sourceRegionByteCount: UInt64 = 12
        let uncoalescedRetainedByteCount =
            UInt64(concurrentRenderCount) * sourceRegionByteCount
        let publisher = PublicationCoordinator(
            maximumPublishedObjectCount: 16,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 16,
                maximumParentEdgeCount: 16,
                maximumAncestryDepth: 8,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: uncoalescedRetainedByteCount
            ),
            resultCache: nil
        )
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let naming = NamingSequence()
        let renderer = ExactSliceRenderer(
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: uncoalescedRetainedByteCount
            ),
            software: try software(),
            naming: { try naming.names(for: $0) }
        )
        let request = RenderRequest(
            scene: try scene([try layer("series-7")]),
            viewport: try ViewportSize(width: 4, height: 3),
            crop: nil,
            interpolation: .nearestNeighbour,
            quality: .full,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil
        )

        var outputIDs = Set<String>()
        try await withThrowingTaskGroup(of: RenderResult.self) { group in
            for _ in 0..<concurrentRenderCount {
                group.addTask {
                    try await renderer.render(request)
                }
            }
            for try await result in group {
                #expect(outputIDs.insert(result.outputObjectID.rawValue).inserted)
                let published = try #require(
                    await publisher.publishedImage(for: result.outputObjectID)
                )
                let bytes = try published.storage.read(
                    region: try ImageRegion(
                        lowerBounds: [0, 0],
                        upperBounds: [4, 3]
                    )
                ).bytes
                #expect(
                    bytes == [
                        0, 0, 0, 36, 73, 109,
                        146, 182, 219, 255, 255, 255,
                    ]
                )
            }
        }
        #expect(
            outputIDs
                == Set(
                    (0..<concurrentRenderCount).map {
                        "render-concurrent-\($0)-wl0"
                    }
                )
        )
        #expect(await publisher.publishedObjectCount == concurrentRenderCount + 1)
    }

    @Test("[Concurrency][VOX-ERR-001] cancellation blocks an uncooperative stage publication")
    func cancellationBlocksAnUncooperativeStagePublication() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let gate = UncooperativeStageGate()
        let cancelledObjectID = try #require(
            DataObjectID(rawValue: "render-cancel-wl0")
        )
        let renderer = ExactSliceRenderer(
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 96
            ),
            software: try software(),
            naming: { _ in
                (
                    outputObjectID: cancelledObjectID,
                    provenanceID: try #require(
                        ProvenanceID(rawValue: "record-render-cancel-wl0")
                    ),
                    createdAt: try CanonicalInstant(
                        utcString: "2026-08-05T04:05:00Z"
                    )
                )
            },
            windowStage: { input, _, _ in
                await gate.suspend()
                return input
            },
            invertStage: { input, _ in input },
            compositeStage: { layers, _, _ in
                guard let first = layers.first else {
                    throw SliceRendererError.unsupportedSceneShape
                }
                return first
            }
        )
        let request = RenderRequest(
            scene: try scene([try layer("series-7")]),
            viewport: try ViewportSize(width: 4, height: 3),
            crop: nil,
            interpolation: .nearestNeighbour,
            quality: .full,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil
        )

        let task = Task {
            try await renderer.render(request)
        }
        await gate.waitUntilStarted()
        task.cancel()
        await gate.release()
        do {
            _ = try await task.value
            #expect(Bool(false), "Expected cancellation to prevent publication.")
        } catch is CancellationError {}

        #expect(await publisher.publishedObjectCount == 1)
        #expect(await publisher.publishedImage(for: cancelledObjectID) == nil)
    }

    // MARK: - VOX-VS1-016, off-screen and interactive equivalence (ADR-0251)

    /// A renderer whose naming mints **fresh identifiers on every render**, as a
    /// real viewport must.
    ///
    /// The plain `makeRenderer` naming is a pure function of the stage, so a
    /// second render of the same request re-mints the same object identifiers and
    /// `PublicationCoordinator` refuses them with `duplicateObjectIdentifier`.
    /// That is the naming contract working correctly -- identifiers are the host's
    /// to mint and a host drawing repeatedly must vary them -- and it is why
    /// equivalence in ADR-0251 is defined over bytes and presentation claims
    /// rather than over identity.
    private func makeCountingRenderer(
        publisher: PublicationCoordinator,
        prefix: String
    ) throws -> ExactSliceRenderer {
        let counter = Mutex<Int>(0)
        let stagesSeen = Mutex<Set<String>>([])
        return ExactSliceRenderer(
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 96
            ),
            software: try software(),
            naming: { stage in
                let suffix: String
                switch stage {
                case .cropped(let layerIndex): suffix = "cr\(layerIndex)"
                case .inverted(let layerIndex): suffix = "iv\(layerIndex)"
                case .windowLevelled(let layerIndex): suffix = "wl\(layerIndex)"
                case .composited: suffix = "cp"
                case .resampled: suffix = "rs"
                }
                // A render is finished when a stage repeats, so the generation
                // advances then -- enough to keep identifiers distinct without
                // the renderer having to report frame boundaries.
                let generation = stagesSeen.withLock { seen -> Int in
                    if seen.contains(suffix) {
                        seen = [suffix]
                        return counter.withLock { value -> Int in
                            value += 1
                            return value
                        }
                    }
                    seen.insert(suffix)
                    return counter.withLock { $0 }
                }
                return (
                    outputObjectID: DataObjectID(
                        rawValue: "\(prefix)-g\(generation)-\(suffix)"
                    )!,
                    provenanceID: ProvenanceID(
                        rawValue: "record-\(prefix)-g\(generation)-\(suffix)"
                    )!,
                    createdAt: try CanonicalInstant(
                        utcString: "2026-08-05T04:05:00Z"
                    )
                )
            }
        )
    }

    /// Reads one published render's bytes.
    private func renderedBytes(
        _ result: RenderResult,
        from publisher: PublicationCoordinator
    ) async throws -> [UInt8] {
        let published = try #require(
            await publisher.publishedImage(for: result.outputObjectID)
        )
        let extents = published.descriptor.shape.extents
        return try published.storage.read(
            region: try ImageRegion(
                lowerBounds: [Int](repeating: 0, count: extents.count),
                upperBounds: extents
            )
        ).bytes
    }

    /// One request exercising every §35.1 semantic the request can carry.
    private func equivalenceRequest() throws -> RenderRequest {
        try RenderRequest(
            scene: try scene([try layer("series-7")]),
            viewport: try ViewportSize(width: 4, height: 3),
            crop: nil,
            interpolation: .nearestNeighbour,
            quality: .full,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil
        )
    }

    @Test("[Unit][VOX-VS1-016] one request renders byte-identically every time")
    func oneRequestRendersByteIdenticallyEveryTime() async throws {
        // VOX-VS1-016 requires off-screen output to use the same presentation
        // semantics as the interactive viewport. There is no interactive viewport
        // to compare against and the draw loop is owner-gated, so the property is
        // established the only way that does not require one: the render is a
        // pure function of its request, so any caller issuing the same request --
        // interactive or not -- necessarily receives the same bytes.
        //
        // This is the same reasoning ADR-0206 used for annotation registration:
        // statelessness IS the equivalence. Anything that made a second identical
        // render differ -- a clock, a counter, cached state leaking into output --
        // would break equivalence with a future interactive caller, and would
        // break this test first.
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeCountingRenderer(publisher: publisher, prefix: "equiv-1")

        let first = try await renderer.render(try equivalenceRequest())
        let firstBytes = try await renderedBytes(first, from: publisher)
        let second = try await renderer.render(try equivalenceRequest())
        let secondBytes = try await renderedBytes(second, from: publisher)

        // Non-vacuity first: two empty arrays would also compare equal. The
        // request is 4x3 greyscale8, so twelve bytes are expected.
        #expect(firstBytes.count == 12)
        #expect(firstBytes == secondBytes)
        // The presentation claims must match too: equivalence of pixels with
        // divergent claims would still be a divergence.
        #expect(first.presentation == second.presentation)
    }

    @Test("[Unit][VOX-VS1-016] an intervening different render does not change the result")
    func anInterveningRenderDoesNotChangeTheResult() async throws {
        // The sharper form: render A, then a materially different B, then A
        // again. If any state survived between renders and reached the output --
        // a reused buffer, a stale pipeline binding, an accumulated value -- A's
        // two results would differ. This is what makes the purity claim about the
        // renderer instance and not just about a single call.
        let publisher = try publisher()
        _ = try await publisher.publish(try originImage(), mode: .complete)
        let renderer = try makeCountingRenderer(publisher: publisher, prefix: "equiv-2")

        let firstA = try await renderer.render(try equivalenceRequest())
        let firstABytes = try await renderedBytes(firstA, from: publisher)

        _ = try await renderer.render(
            RenderRequest(
                scene: try scene([try layer("series-7")]),
                viewport: try ViewportSize(width: 8, height: 6),
                crop: nil,
                interpolation: .linear,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil
            )
        )

        let secondA = try await renderer.render(try equivalenceRequest())
        let secondABytes = try await renderedBytes(secondA, from: publisher)

        #expect(firstABytes.count == 12)
        #expect(firstABytes == secondABytes)
        #expect(firstA.presentation == secondA.presentation)
    }

    @Test("[Unit][VOX-VS1-016] two separately constructed renderers agree exactly")
    func twoSeparatelyConstructedRenderersAgreeExactly() async throws {
        // The case that actually models off-screen versus interactive: two
        // independently constructed renderers, as an export path and a viewport
        // would each build their own. Both use the convenience initialiser -- the
        // one an interactive caller would reach for -- and must agree byte for
        // byte.
        //
        // This is also where the honest limit of the purity claim sits. Output is
        // a pure function of the request AND the renderer's injected stages: the
        // designated initialiser takes `windowStage`, whose convenience default
        // passes `paddingValue: nil`. Two callers injecting different stages
        // could therefore diverge, which is why ADR-0251 states the equivalence
        // as conditional on identical construction rather than unconditional.
        let publisherA = try publisher()
        _ = try await publisherA.publish(try originImage(), mode: .complete)
        let rendererA = try makeRenderer(publisher: publisherA, prefix: "equiv-3a")

        let publisherB = try publisher()
        _ = try await publisherB.publish(try originImage(), mode: .complete)
        let rendererB = try makeRenderer(publisher: publisherB, prefix: "equiv-3b")

        let resultA = try await rendererA.render(try equivalenceRequest())
        let resultB = try await rendererB.render(try equivalenceRequest())

        let bytesA = try await renderedBytes(resultA, from: publisherA)
        let bytesB = try await renderedBytes(resultB, from: publisherB)
        #expect(bytesA.count == 12)
        #expect(bytesA == bytesB)
        // Presentation claims are compared field by field except the object
        // identifiers, which are caller-minted by design and differ on purpose.
        #expect(resultA.presentation == resultB.presentation)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
