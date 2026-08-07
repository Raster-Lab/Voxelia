// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaImaging
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaMetal

/// A deterministic open-once gate; the broker suite's idiom.
private actor LoadGate {
    private var opened = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func open() {
        opened = true
        for waiter in waiters {
            waiter.resume()
        }
        waiters = []
    }

    func wait() async {
        if opened {
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
}

/// The `ADR-0344` interactive level render path: the Test half of
/// `VOX-BRK-009`.
@Suite("InteractiveLevelRender")
struct InteractiveLevelRenderTests {
    @Test("[Unit][VOX-BRK-009] the selection rule is total and frozen")
    func selectionRuleIsTotalAndFrozen() {
        #expect(
            InteractiveLevelRenderCoordinator.selectSource(
                quality: .full,
                studyCacheGenerationComplete: false
            ) == .fullResolution
        )
        #expect(
            InteractiveLevelRenderCoordinator.selectSource(
                quality: .full,
                studyCacheGenerationComplete: true
            ) == .fullResolution
        )
        #expect(
            InteractiveLevelRenderCoordinator.selectSource(
                quality: .interactive,
                studyCacheGenerationComplete: false
            ) == .level
        )
        #expect(
            InteractiveLevelRenderCoordinator.selectSource(
                quality: .interactive,
                studyCacheGenerationComplete: true
            ) == .fullResolution
        )
    }

    @Test("[Unit][VOX-BRK-009] the slice index maps by floor division")
    func sliceIndexMapsByFloorDivision() {
        #expect(
            InteractiveLevelRenderCoordinator.levelSliceIndex(
                fullResolutionIndex: 3,
                factor: 2
            ) == 1
        )
        #expect(
            InteractiveLevelRenderCoordinator.levelSliceIndex(
                fullResolutionIndex: 0,
                factor: 2
            ) == 0
        )
        #expect(
            InteractiveLevelRenderCoordinator.levelSliceIndex(
                fullResolutionIndex: 5,
                factor: 2
            ) == 2
        )
        #expect(
            InteractiveLevelRenderCoordinator.levelSliceIndex(
                fullResolutionIndex: 7,
                factor: 1
            ) == 7
        )
    }

    @Test("[Pipeline][VOX-BRK-009] interactive rendering uses the level while bricks load")
    func interactiveRenderingUsesTheLevelWhileBricksLoad() async throws {
        let publisher = try publisher()
        let full = try volume(name: "brk-volume")
        _ = try await publisher.publish(full, mode: .complete)

        // The level representation, derived by the accepted operation
        // and published so its ancestry records level-select.
        let level = try BrickResolutionLevel(index: 1, downsamplingFactors: [2, 2, 2])
        let levelImage = try await LevelSelectOperation.execute(
            input: full,
            level: level,
            outputObjectID: try #require(DataObjectID(rawValue: "brk-level")),
            outputProvenanceID: try #require(ProvenanceID(rawValue: "record-brk-level")),
            createdAt: try CanonicalInstant(utcString: "2026-08-06T09:00:00Z"),
            software: try software(),
            coordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 256)
        )
        _ = try await publisher.publish(levelImage, mode: .complete)

        // A real gated study-cache generation supplies the loading
        // state honestly: it starts, blocks, and completes only when
        // the harness says so.
        let grid = try BrickGridDescriptor(
            volumeExtents: [2, 3, 4],
            nominalBrickExtents: [2, 2, 2],
            haloExtents: [0, 0, 0]
        )
        let counts = grid.brickCounts
        var bricks = [StudyCacheBrick]()
        for c2 in 0..<counts[2] {
            for c1 in 0..<counts[1] {
                for c0 in 0..<counts[0] {
                    bricks.append(
                        StudyCacheBrick(
                            identity: try BrickIdentity(
                                volumeObjectID: try #require(
                                    DataObjectID(rawValue: "brk-volume")
                                ),
                                levelIndex: 0,
                                coordinate: [c0, c1, c2]
                            ),
                            reconstructionCost: 1
                        )
                    )
                }
            }
        }
        let sweepBricks = bricks
        let broker = BrickRequestBroker()
        let cache = BrickResultCache(
            maximumEntryCount: 64,
            maximumTotalByteCount: 65_536,
            eventSink: nil
        )
        let gate = LoadGate()
        let progressCounter = ProgressCounter()
        let generation = await broker.generation()
        let sweep = Task(priority: .utility) {
            try await StudyCacheGenerator.generate(
                bricks: sweepBricks,
                representation: try ExecutionClaimToken(
                    rawValue: "org.voxelia.representation.decoded-u8"
                ),
                generation: generation,
                visible: true,
                cache: cache,
                broker: broker,
                progress: { _ in progressCounter.increment() },
                compute: { _ in
                    await gate.wait()
                    return [1]
                }
            )
        }

        // While loading: the interactive request renders the LEVEL —
        // the extract stage's provenance input is the level volume.
        let interactive = try await render(
            quality: .interactive,
            generationComplete: progressCounter.current() == sweepBricks.count,
            level: level,
            prefix: "brk-i",
            publisher: publisher
        )
        _ = interactive
        try await expectExtractInput(
            prefix: "brk-i",
            equals: "brk-level",
            publisher: publisher
        )

        // While loading: the full request renders FULL RESOLUTION.
        _ = try await render(
            quality: .full,
            generationComplete: progressCounter.current() == sweepBricks.count,
            level: level,
            prefix: "brk-f",
            publisher: publisher
        )
        try await expectExtractInput(
            prefix: "brk-f",
            equals: "brk-volume",
            publisher: publisher
        )

        // Loading completes; the interactive request now renders full
        // resolution — the representation refinement seed.
        await gate.open()
        try await sweep.value
        #expect(progressCounter.current() == sweepBricks.count)
        _ = try await render(
            quality: .interactive,
            generationComplete: progressCounter.current() == sweepBricks.count,
            level: level,
            prefix: "brk-c",
            publisher: publisher
        )
        try await expectExtractInput(
            prefix: "brk-c",
            equals: "brk-volume",
            publisher: publisher
        )

        // The level volume's own ancestry names the level-select
        // operation — the structural quality record.
        let levelID = try #require(DataObjectID(rawValue: "brk-level"))
        let publishedLevel = try #require(
            await publisher.publishedImage(for: levelID)
        )
        let derivation = try #require(publishedLevel.identity.derivation)
        #expect(derivation.operationID.rawValue == "org.voxelia.op.level-select")
    }

    @Test("[Unit][VOX-BRK-009] a level without three factors rejects typed")
    func levelWithoutThreeFactorsRejectsTyped() async throws {
        let publisher = try publisher()
        _ = try await publisher.publish(try volume(name: "rank-volume"), mode: .complete)
        await #expect(throws: InteractiveLevelError.invalidLevelRank) {
            _ = try await render(
                quality: .interactive,
                generationComplete: false,
                level: try BrickResolutionLevel(index: 1, downsamplingFactors: [2, 2]),
                prefix: "rank",
                publisher: publisher,
                fullName: "rank-volume",
                levelName: "rank-volume"
            )
        }
    }

    // MARK: - Helpers, mirroring the multiplanar suite's private set.

    private func render(
        quality: RenderQuality,
        generationComplete: Bool,
        level: BrickResolutionLevel,
        prefix: String,
        publisher: PublicationCoordinator,
        fullName: String = "brk-volume",
        levelName: String = "brk-level"
    ) async throws -> RenderResult {
        try await InteractiveLevelRenderCoordinator.renderPlane(
            quality: quality,
            studyCacheGenerationComplete: generationComplete,
            fullVolumeID: try #require(DataObjectID(rawValue: fullName)),
            levelVolumeID: try #require(DataObjectID(rawValue: levelName)),
            level: level,
            plane: .axial,
            sliceIndex: 3,
            transferFunction: .greyscaleWindow(
                try GreyscaleWindowFunction(center: 12, width: 24, polarity: .standard)
            ),
            viewport: try ViewportSize(width: 2, height: 3),
            camera: try camera(),
            interpolation: .nearestNeighbour,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            naming: naming(prefix: prefix),
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(maximumRetainedResultByteCount: 256),
            software: try software(),
            renderer: try makeRenderer(publisher: publisher, prefix: prefix)
        )
    }

    private func expectExtractInput(
        prefix: String,
        equals volumeName: String,
        publisher: PublicationCoordinator
    ) async throws {
        let extractID = try #require(DataObjectID(rawValue: "\(prefix)-extract"))
        let extract = try #require(
            await publisher.publishedImage(for: extractID)
        )
        let input = try #require(extract.provenance.inputs.first)
        guard case .object(let objectID) = input.identity else {
            #expect(Bool(false), "Expected an object input identity.")
            return
        }
        #expect(objectID.rawValue == volumeName)
    }

    private func camera() throws -> RenderCamera {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        return try RenderCamera(
            position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
            target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
            up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
            projection: .orthographic(planeHeight: 250)
        )
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    private func naming(prefix: String) -> MPRPublicationNaming {
        { stage in
            let suffix = stage == .extracted ? "extract" : "squeeze"
            return (
                outputObjectID: try #require(
                    DataObjectID(rawValue: "\(prefix)-\(suffix)")
                ),
                provenanceID: try #require(
                    ProvenanceID(rawValue: "record-\(prefix)-\(suffix)")
                ),
                createdAt: try CanonicalInstant(utcString: "2026-08-06T09:00:00Z")
            )
        }
    }

    private func publisher() throws -> PublicationCoordinator {
        PublicationCoordinator(
            maximumPublishedObjectCount: 32,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 32,
                maximumParentEdgeCount: 32,
                maximumAncestryDepth: 16,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 256
            ),
            resultCache: nil
        )
    }

    private func makeRenderer(
        publisher: PublicationCoordinator,
        prefix: String
    ) throws -> MetalSliceRenderer {
        let context = try MetalExecutionContext()
        let counter = NamingCounter()
        return MetalSliceRenderer(
            kernel: try MetalWindowLevelKernel(context: context, telemetrySink: nil),
            invertKernel: try MetalInvertKernel(context: context, telemetrySink: nil),
            compositeKernel: try MetalCompositeKernel(
                context: context,
                telemetrySink: nil
            ),
            publisher: publisher,
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 256
            ),
            software: try software(),
            naming: { _ in
                let index = counter.next()
                return (
                    outputObjectID: try #require(
                        DataObjectID(rawValue: "\(prefix)-render-\(index)")
                    ),
                    provenanceID: try #require(
                        ProvenanceID(rawValue: "record-\(prefix)-render-\(index)")
                    ),
                    createdAt: try CanonicalInstant(utcString: "2026-08-06T09:00:00Z")
                )
            }
        )
    }

    private final class ProgressCounter: Sendable {
        private let value = Mutex(0)

        func increment() {
            value.withLock { $0 += 1 }
        }

        func current() -> Int {
            value.withLock { $0 }
        }
    }

    private final class NamingCounter: Sendable {
        private let value = Mutex(0)

        func next() -> Int {
            value.withLock { current in
                current += 1
                return current
            }
        }
    }

    /// The multiplanar fixture volume with an identity affine geometry
    /// so the level-select admission accepts it.
    private func volume(name: String) throws -> ImageData {
        let extents = [2, 3, 4]
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        let names = ["x", "y", "z"]
        let count = extents.reduce(1, *)
        let bytes = (0..<count).map { UInt8($0 * 7 % 251) }
        var axes = ContiguousArray<AxisDescriptor>()
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
        let space = try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
        let geometry = try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: [
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ]),
            coordinateSpace: space
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
                spatialGeometry: .affine(geometry),
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
                id: try #require(ProvenanceID(rawValue: "record-\(name)")),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-06T09:00:00Z"),
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
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.9",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }
}
