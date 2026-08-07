// SPDX-License-Identifier: MIT

import AppKit
import SwiftUI
import Synchronization
import VoxeliaCore
import VoxeliaDICOMKit
import VoxeliaExecution
import VoxeliaImaging
import VoxeliaMetal
import VoxeliaRendering
import VoxeliaSpatial
import VoxeliaStorage

/// The Voxelia CT reference application per `ADR-0347`.
///
/// The application owns lifecycle, controls, layout and the host-side
/// clock; every rendered pixel comes from the accepted coordinators.
/// It duplicates no processing logic.
@main
struct VoxeliaCTReferenceApp: App {
    @StateObject private var state = ViewerState()

    var body: some Scene {
        WindowGroup("Voxelia CT Reference") {
            ViewerView(state: state)
                .task { await state.start() }
        }
    }
}

/// Main-actor presentation state; the engine actor does the work.
@MainActor
final class ViewerState: ObservableObject {
    @Published var image: NSImage?
    @Published var plane: MPRPlane = .axial
    @Published var sliceIndex: Double = 128
    @Published var loadedBricks = 0
    @Published var totalBricks = 1
    @Published var statusLine = "starting..."
    @Published var maxSlice = 255.0
    @Published var studyMode = false

    private var engine: ViewerEngine?
    private var debounce: Task<Void, Never>?
    private var renderTicket = 0

    var generationComplete: Bool { loadedBricks >= totalBricks }

    func start() async {
        do {
            let directory = CommandLine.arguments.dropFirst().first.map {
                URL(fileURLWithPath: $0, isDirectory: true)
            }
            let engine = try await ViewerEngine(studyDirectory: directory)
            self.engine = engine
            studyMode = engine.studyMode
            maxSlice = Double(max(await engine.sliceCount(for: plane) - 1, 1))
            if studyMode {
                statusLine = "study imported (full resolution)"
                interactionChanged()
                return
            }
            totalBricks = await engine.totalBricks
            statusLine = "generating study cache (interactive uses the level)..."
            await engine.startGeneration { [weak self] completed, total in
                Task { @MainActor in
                    self?.loadedBricks = completed
                    self?.totalBricks = total
                    if completed == total {
                        self?.statusLine = "study cache complete"
                        self?.interactionChanged()
                    }
                }
            }
            interactionChanged()
        } catch {
            statusLine = "failed to start: \(error)"
        }
    }

    /// Every control change lands here: render immediately as the
    /// active phase, then debounce into idle — the host-side clock
    /// `ADR-0345` assigns to the application.
    func interactionChanged() {
        Task { [weak self] in
            guard let self, let engine = self.engine else { return }
            let plane = self.plane
            let ceiling = Double(max(await engine.sliceCount(for: plane) - 1, 1))
            await MainActor.run {
                self.maxSlice = ceiling
                if self.sliceIndex > ceiling { self.sliceIndex = ceiling }
            }
        }
        render(phase: .active)
        debounce?.cancel()
        debounce = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.render(phase: .idle) }
        }
    }

    private func render(phase: InteractionPhase) {
        guard let engine else { return }
        renderTicket += 1
        let ticket = renderTicket
        let plane = plane
        let index = Int(sliceIndex)
        let complete = generationComplete
        let quality: RenderQuality =
            studyMode || (phase == .idle && complete) ? .full : .interactive
        Task {
            do {
                let rendered = try await engine.renderPlane(
                    plane: plane,
                    sliceIndex: index,
                    quality: quality,
                    generationComplete: complete
                )
                await MainActor.run {
                    // Stale results are dropped, never presented.
                    guard ticket == self.renderTicket else { return }
                    self.image = rendered
                    if self.studyMode {
                        self.statusLine =
                            "study | full resolution | phase "
                            + (phase == .active ? "active" : "idle")
                        return
                    }
                    let source = InteractiveLevelRenderCoordinator.selectSource(
                        quality: quality,
                        studyCacheGenerationComplete: complete
                    )
                    let decision =
                        InteractiveLevelRenderCoordinator.refinementDecision(
                            phase: phase,
                            studyCacheGenerationComplete: complete
                        )
                    self.statusLine =
                        "\(source == .level ? "level 1 (256/2)^3" : "full resolution") | "
                        + "phase \(phase == .active ? "active" : "idle")"
                        + (decision.refinementDue ? " | refinement due" : "")
                }
            } catch {
                await MainActor.run {
                    self.statusLine = "render failed: \(error)"
                }
            }
        }
    }
}

struct ViewerView: View {
    @ObservedObject var state: ViewerState

    var body: some View {
        VStack(spacing: 8) {
            if let image = state.image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(minWidth: 512, minHeight: 512)
            } else {
                ProgressView().frame(minWidth: 512, minHeight: 512)
            }
            Picker("Plane", selection: $state.plane) {
                Text("Axial").tag(MPRPlane.axial)
                Text("Coronal").tag(MPRPlane.coronal)
                Text("Sagittal").tag(MPRPlane.sagittal)
            }
            .pickerStyle(.segmented)
            .onChange(of: state.plane) { state.interactionChanged() }
            Slider(value: $state.sliceIndex, in: 0...max(state.maxSlice, 1), step: 1) {
                Text("Slice")
            }
            .onChange(of: state.sliceIndex) { state.interactionChanged() }
            if !state.studyMode {
                ProgressView(
                    value: Double(state.loadedBricks),
                    total: Double(max(state.totalBricks, 1))
                ) {
                    Text(
                        "Study cache: \(state.loadedBricks)/\(state.totalBricks) bricks"
                    )
                }
            }
            Text(state.statusLine)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
    }
}

/// The engine: publication, level derivation, study-cache generation
/// and plane rendering, all through accepted API.
actor ViewerEngine {
    private static let volumeExtent = 256
    private static let brickExtent = 64

    private let publisher: PublicationCoordinator
    private let readCoordinator: StorageReadCoordinator
    private let software: SoftwareIdentity
    private let renderer: MetalSliceRenderer
    private let level: BrickResolutionLevel
    private let fullVolumeID: DataObjectID
    private let levelVolumeID: DataObjectID
    private let fullVolume: ImageData
    private let bricks: [StudyCacheBrick]
    private let cache: BrickResultCache
    private let broker: BrickRequestBroker
    private var renderOrdinal = 0
    private var generationCompleteFlag = false
    let studyMode: Bool

    var totalBricks: Int { bricks.count }

    /// The slice count of the viewed volume along one plane's fixed axis.
    func sliceCount(for plane: MPRPlane) -> Int {
        fullVolume.descriptor.shape.extents[plane.fixedAxis]
    }

    init(studyDirectory: URL?) async throws {
        software = try SoftwareIdentity(
            name: "VoxeliaCTReference",
            version: try SemanticVersion(major: 0, minor: 1, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
        readCoordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 128_000_000
        )
        publisher = PublicationCoordinator(
            maximumPublishedObjectCount: 1_000_000,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 1_000_000,
                maximumParentEdgeCount: 1_000_000,
                maximumAncestryDepth: 64,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: readCoordinator,
            resultCache: nil
        )

        guard
            let fullID = DataObjectID(rawValue: "reference-volume"),
            let levelID = DataObjectID(rawValue: "reference-level-1")
        else {
            throw ViewerError.invalidIdentifier
        }
        fullVolumeID = fullID
        levelVolumeID = levelID
        studyMode = studyDirectory != nil
        level = try BrickResolutionLevel(index: 1, downsamplingFactors: [2, 2, 2])

        if let studyDirectory {
            // Study mode per ADR-0349: the accepted import session with
            // the DICOM source's closures, under the exact geometry
            // tolerance the owner's own series is proven to pass.
            guard let space = CoordinateSpaceID(rawValue: "patient") else {
                throw ViewerError.invalidIdentifier
            }
            let urls = try FileManager.default.contentsOfDirectory(
                at: studyDirectory,
                includingPropertiesForKeys: nil
            ).sorted { $0.lastPathComponent < $1.lastPathComponent }
            let source = DICOMFrameSource(coordinateSpace: space)
            guard let record = ProvenanceID(rawValue: "record-reference-volume")
            else {
                throw ViewerError.invalidIdentifier
            }
            let imported = try CTImportSession.importVolume(
                sources: urls,
                describe: { source.describe($0) },
                readFrameBytes: { try source.frameBytes(for: $0) },
                tolerance: .exact,
                coordinateSpaceID: space,
                convention: .dicomPatientLPS,
                handedness: .unspecified,
                unit: try MeasurementUnit(
                    namespace: "UCUM",
                    code: "mm",
                    dimension: .length
                ),
                objectID: fullID,
                provenanceID: record,
                software: software,
                ingestedAt: try CanonicalInstant(
                    utcString: "2026-08-07T12:00:00Z"
                ),
                validationClaim: .unknown,
                metadata: try MetadataCollection(entries: []),
                cancellation: { _ in false }
            )
            fullVolume = imported.image
            _ = try await publisher.publish(fullVolume, mode: .complete)
        } else {
            fullVolume = try Self.makePhantomVolume(
                software: software,
                objectID: fullID
            )
            _ = try await publisher.publish(fullVolume, mode: .complete)

            guard let levelRecord = ProvenanceID(rawValue: "record-reference-level-1")
            else {
                throw ViewerError.invalidIdentifier
            }
            let levelImage = try await LevelSelectOperation.execute(
                input: fullVolume,
                level: level,
                outputObjectID: levelID,
                outputProvenanceID: levelRecord,
                createdAt: try CanonicalInstant(utcString: "2026-08-07T12:00:00Z"),
                software: software,
                coordinator: readCoordinator
            )
            _ = try await publisher.publish(levelImage, mode: .complete)
        }

        let context = try MetalExecutionContext()
        let counter = RenderNamingCounter()
        renderer = MetalSliceRenderer(
            kernel: try MetalWindowLevelKernel(context: context, telemetrySink: nil),
            invertKernel: try MetalInvertKernel(context: context, telemetrySink: nil),
            compositeKernel: try MetalCompositeKernel(
                context: context,
                telemetrySink: nil
            ),
            publisher: publisher,
            readCoordinator: readCoordinator,
            software: software,
            naming: { _ in
                let ordinal = counter.next()
                guard
                    let objectID = DataObjectID(rawValue: "reference-render-\(ordinal)"),
                    let recordID = ProvenanceID(
                        rawValue: "record-reference-render-\(ordinal)"
                    )
                else {
                    throw ViewerError.invalidIdentifier
                }
                return (
                    outputObjectID: objectID,
                    provenanceID: recordID,
                    createdAt: try CanonicalInstant(utcString: "2026-08-07T12:00:00Z")
                )
            }
        )

        let grid = try BrickGridDescriptor(
            volumeExtents: ContiguousArray(
                repeating: Self.volumeExtent,
                count: 3
            ),
            nominalBrickExtents: ContiguousArray(repeating: Self.brickExtent, count: 3),
            haloExtents: [0, 0, 0]
        )
        let counts = grid.brickCounts
        var sweep = [StudyCacheBrick]()
        for c2 in 0..<counts[2] {
            for c1 in 0..<counts[1] {
                for c0 in 0..<counts[0] {
                    sweep.append(
                        StudyCacheBrick(
                            identity: try BrickIdentity(
                                volumeObjectID: fullID,
                                levelIndex: 0,
                                coordinate: [c0, c1, c2]
                            ),
                            reconstructionCost: 1
                        )
                    )
                }
            }
        }
        bricks = sweep
        cache = BrickResultCache(
            maximumEntryCount: 512,
            maximumTotalByteCount: 64_000_000,
            eventSink: nil
        )
        broker = BrickRequestBroker()
        self.gridDescriptor = grid
    }

    private let gridDescriptor: BrickGridDescriptor

    /// Starts the background generation sweep at utility priority. The
    /// per-brick pacing below is demonstration pacing — it exists so a
    /// human can watch the level-while-loading behaviour — and is the
    /// application's, never the library's.
    func startGeneration(
        progress: @escaping @Sendable (Int, Int) -> Void
    ) {
        let bricks = bricks
        let cache = cache
        let broker = broker
        let volume = fullVolume
        let grid = gridDescriptor
        let total = bricks.count
        Task(priority: .utility) { [weak self] in
            guard
                let representation = try? ExecutionClaimToken(
                    rawValue: "org.voxelia.representation.decoded-u8"
                )
            else { return }
            let generation = await broker.generation()
            try? await StudyCacheGenerator.generate(
                bricks: bricks,
                representation: representation,
                generation: generation,
                visible: true,
                cache: cache,
                broker: broker,
                progress: { update in
                    progress(update.completedBrickCount, update.totalBrickCount)
                },
                compute: { identity in
                    // Demonstration pacing, application-owned.
                    try? await Task.sleep(for: .milliseconds(120))
                    let region = try grid.coreRegion(of: identity.coordinate)
                    return ContiguousArray(
                        try volume.storage.read(region: region).bytes
                    )
                }
            )
            await self?.markGenerationComplete()
            _ = total
        }
    }

    private func markGenerationComplete() {
        generationCompleteFlag = true
    }

    func renderPlane(
        plane: MPRPlane,
        sliceIndex: Int,
        quality: RenderQuality,
        generationComplete: Bool
    ) async throws -> NSImage {
        renderOrdinal += 1
        let ordinal = renderOrdinal
        let naming: MPRPublicationNaming = { stage in
            let suffix = stage == .extracted ? "extract" : "squeeze"
            guard
                let objectID = DataObjectID(
                    rawValue: "reference-mpr-\(ordinal)-\(suffix)"
                ),
                let recordID = ProvenanceID(
                    rawValue: "record-reference-mpr-\(ordinal)-\(suffix)"
                )
            else {
                throw ViewerError.invalidIdentifier
            }
            return (
                outputObjectID: objectID,
                provenanceID: recordID,
                createdAt: try CanonicalInstant(utcString: "2026-08-07T12:00:00Z")
            )
        }
        guard let space = CoordinateSpaceID(rawValue: "patient") else {
            throw ViewerError.invalidIdentifier
        }
        // The demonstration windows are the application's fixed demo
        // defaults per ADR-0349; window controls are host UI the
        // demonstrations do not require.
        let window =
            studyMode
            ? try GreyscaleWindowFunction(center: 1024, width: 4096, polarity: .standard)
            : try GreyscaleWindowFunction(center: 128, width: 256, polarity: .standard)
        if studyMode {
            let result = try await MultiplanarRenderCoordinator.renderPlane(
                volumeID: fullVolumeID,
                plane: plane,
                sliceIndex: sliceIndex,
                transferFunction: .greyscaleWindow(window),
                viewport: try ViewportSize(width: 512, height: 512),
                camera: try RenderCamera(
                    position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
                    target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
                    up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
                    projection: .orthographic(planeHeight: 250)
                ),
                interpolation: .nearestNeighbour,
                quality: .full,
                colourOutput: .greyscale8,
                colourTransform: .none,
                outputColourSpace: nil,
                naming: naming,
                publisher: publisher,
                readCoordinator: readCoordinator,
                software: software,
                renderer: renderer
            )
            return try await presentedImage(for: result)
        }
        let result = try await InteractiveLevelRenderCoordinator.renderPlane(
            quality: quality,
            studyCacheGenerationComplete: generationComplete,
            fullVolumeID: fullVolumeID,
            levelVolumeID: levelVolumeID,
            level: level,
            plane: plane,
            sliceIndex: sliceIndex,
            transferFunction: .greyscaleWindow(window),
            viewport: try ViewportSize(width: 512, height: 512),
            camera: try RenderCamera(
                position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
                target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
                projection: .orthographic(planeHeight: 250)
            ),
            interpolation: .nearestNeighbour,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            naming: naming,
            publisher: publisher,
            readCoordinator: readCoordinator,
            software: software,
            renderer: renderer
        )
        return try await presentedImage(for: result)
    }

    private func presentedImage(for result: RenderResult) async throws -> NSImage {
        guard
            let published = await publisher.publishedImage(for: result.outputObjectID)
        else {
            throw ViewerError.renderNotPublished
        }
        let extents = published.descriptor.shape.extents
        let bytes = try published.storage.read(
            region: try ImageRegion(
                lowerBounds: [0, 0],
                upperBounds: extents
            )
        ).bytes
        guard
            let image = GreyImageBridge.makeImage(
                bytes: bytes,
                width: extents[0],
                height: extents[1]
            )
        else {
            throw ViewerError.imageConversionFailed
        }
        return image
    }

    /// A banded radial phantom: concentric shells around the centre so
    /// every plane shows visually distinct rings at every slice.
    private static func makePhantomVolume(
        software: SoftwareIdentity,
        objectID: DataObjectID
    ) throws -> ImageData {
        let extent = volumeExtent
        let centre = Double(extent - 1) / 2
        var bytes = [UInt8](repeating: 0, count: extent * extent * extent)
        var offset = 0
        for i2 in 0..<extent {
            let dz = Double(i2) - centre
            for i1 in 0..<extent {
                let dy = Double(i1) - centre
                for i0 in 0..<extent {
                    let dx = Double(i0) - centre
                    let distance = (dx * dx + dy * dy + dz * dz).squareRoot()
                    let shell = Int(distance / 12)
                    let value = shell.isMultiple(of: 2) ? 220 - shell * 8 : 40 + shell * 4
                    bytes[offset] = UInt8(clamping: value)
                    offset += 1
                }
            }
        }
        guard let space = CoordinateSpaceID(rawValue: "patient") else {
            throw ViewerError.invalidIdentifier
        }
        let descriptorSpace = try CoordinateSpaceDescriptor(
            id: space,
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
            coordinateSpace: descriptorSpace
        )
        var axes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for (index, name) in ["x", "y", "z"].enumerated() {
            guard let axisID = AxisID(rawValue: name) else {
                throw ViewerError.invalidIdentifier
            }
            axes.append(
                try AxisDescriptor(
                    id: axisID,
                    name: name,
                    semantic: semantics[index],
                    unit: nil,
                    sampling: .indexOnly
                )
            )
        }
        let shape = try ImageShape(
            extents: ContiguousArray(repeating: extent, count: 3)
        )
        guard let record = ProvenanceID(rawValue: "record-reference-volume") else {
            throw ViewerError.invalidIdentifier
        }
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
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
                        shape: shape,
                        scalarType: .uint8,
                        componentCount: 1
                    ),
                    bytes: bytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: record,
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-07T12:00:00Z"),
                subject: .object(objectID),
                software: software,
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: objectID,
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "org.voxelia.reference",
                        identifier: "banded-radial-phantom",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }
}

enum ViewerError: Error {
    case invalidIdentifier
    case renderNotPublished
    case imageConversionFailed
}

/// Checked monotonic naming for renderer publications.
final class RenderNamingCounter: Sendable {
    private let value = Mutex(0)

    func next() -> Int {
        value.withLock { current in
            current += 1
            return current
        }
    }
}
