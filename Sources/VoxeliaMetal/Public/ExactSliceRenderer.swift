// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering

/// An error raised by the exact diagnostic slice renderer.
///
/// Cases deliberately carry no payload; execution, publication and
/// model failures surface as their own audited typed errors.
public enum SliceRendererError: Error, Sendable, Equatable {
    case unsupportedSceneShape
    case imageNotPublished
}

/// The closed set of published stages one render can produce; the
/// host names each stage per `ADR-0089` as revised by `ADR-0091` and
/// `ADR-0102`.
public enum RenderPublicationStage: Sendable, Equatable {
    case cropped(layerIndex: Int)
    case windowLevelled(layerIndex: Int)
    case inverted(layerIndex: Int)
    case composited
    case resampled
}

/// The host-supplied naming for one render's published stage; the
/// renderer mints no identifiers and acquires no clock.
public typealias RenderPublicationNaming =
    @Sendable (RenderPublicationStage) throws -> (
        outputObjectID: DataObjectID,
        provenanceID: ProvenanceID,
        createdAt: CanonicalInstant
    )

/// The first `SliceRenderer` conformer per `ADR-0086`: exact
/// axis-aligned identity slice presentation composed entirely from
/// accepted, evidence-carrying contracts.
///
/// The renderer executes the accepted window-level operation over a
/// published single-layer scene, resamples to a differing viewport
/// through the registered nearest-neighbour operation per `ADR-0089`,
/// and publishes every derived stage through the accepted publication
/// coordinator, so each result carries a complete provenance chain.
/// Oblique and perspective presentation stay pending their own
/// models, and a GPU path may later arrive behind this same contract.
public final class ExactSliceRenderer: SliceRenderer, @unchecked Sendable {
    /// One injected window stage per `ADR-0092`: the single pipeline
    /// orchestration authority admits exactly one window executor, so
    /// backend choice is explicit and never a silent fallback.
    typealias WindowStageExecutor =
        @Sendable (
            _ input: ImageData,
            _ window: GreyscaleWindowFunction,
            _ names: (
                outputObjectID: DataObjectID,
                provenanceID: ProvenanceID,
                createdAt: CanonicalInstant
            )
        ) async throws -> ImageData

    /// One injected inversion stage per `ADR-0133`, mirroring the
    /// window stage.
    typealias InvertStageExecutor =
        @Sendable (
            _ input: ImageData,
            _ names: (
                outputObjectID: DataObjectID,
                provenanceID: ProvenanceID,
                createdAt: CanonicalInstant
            )
        ) async throws -> ImageData

    /// One injected composite stage per `ADR-0099`, mirroring the
    /// window stage.
    typealias CompositeStageExecutor =
        @Sendable (
            _ layers: [ImageData],
            _ opacities: [Double],
            _ names: (
                outputObjectID: DataObjectID,
                provenanceID: ProvenanceID,
                createdAt: CanonicalInstant
            )
        ) async throws -> ImageData

    private let publisher: PublicationCoordinator
    private let readCoordinator: StorageReadCoordinator
    private let software: SoftwareIdentity
    private let naming: RenderPublicationNaming
    private let windowStage: WindowStageExecutor
    private let invertStage: InvertStageExecutor
    private let compositeStage: CompositeStageExecutor

    /// Creates a renderer over accepted coordinators with host-owned
    /// naming and the exact CPU window and composite stages.
    public convenience init(
        publisher: PublicationCoordinator,
        readCoordinator: StorageReadCoordinator,
        software: SoftwareIdentity,
        naming: @escaping RenderPublicationNaming
    ) {
        self.init(
            publisher: publisher,
            readCoordinator: readCoordinator,
            software: software,
            naming: naming,
            windowStage: { input, window, names in
                try await WindowLevelOperation.execute(
                    input: input,
                    center: try MetadataFloatingPoint(value: window.center),
                    width: try MetadataFloatingPoint(value: window.width),
                    paddingValue: nil,
                    outputObjectID: names.outputObjectID,
                    outputProvenanceID: names.provenanceID,
                    createdAt: names.createdAt,
                    software: software,
                    coordinator: readCoordinator
                )
            },
            invertStage: { input, names in
                try await InvertDisplayOperation.execute(
                    input: input,
                    outputObjectID: names.outputObjectID,
                    outputProvenanceID: names.provenanceID,
                    createdAt: names.createdAt,
                    software: software,
                    coordinator: readCoordinator
                )
            },
            compositeStage: { layers, opacities, names in
                try await CompositeLayersOperation.execute(
                    layers: layers,
                    opacities: opacities,
                    outputObjectID: names.outputObjectID,
                    outputProvenanceID: names.provenanceID,
                    createdAt: names.createdAt,
                    software: software,
                    coordinator: readCoordinator
                )
            }
        )
    }

    init(
        publisher: PublicationCoordinator,
        readCoordinator: StorageReadCoordinator,
        software: SoftwareIdentity,
        naming: @escaping RenderPublicationNaming,
        windowStage: @escaping WindowStageExecutor,
        invertStage: @escaping InvertStageExecutor,
        compositeStage: @escaping CompositeStageExecutor
    ) {
        self.publisher = publisher
        self.readCoordinator = readCoordinator
        self.software = software
        self.naming = naming
        self.windowStage = windowStage
        self.invertStage = invertStage
        self.compositeStage = compositeStage
    }

    /// Renders one request exactly.
    ///
    /// - Throws: ``SliceRendererError``, or the audited typed errors
    ///   of the execution and publication contracts.
    public func render(_ request: RenderRequest) async throws -> RenderResult {
        // Window-level every published greyscale layer in scene order
        // — the value model consumes the stored domain — publishing
        // each stage, so the ancestry closure stays complete in the
        // registry.
        var windowLevelled = [ImageData]()
        windowLevelled.reserveCapacity(request.scene.layers.count)
        for (index, layer) in request.scene.layers.enumerated() {
            guard
                let published = await publisher.publishedImage(
                    for: layer.imageObjectID
                )
            else {
                throw SliceRendererError.imageNotPublished
            }
            guard case .greyscaleWindow(let window) = layer.transferFunction
            else {
                throw SliceRendererError.unsupportedSceneShape
            }

            // A requested crop runs the accepted extraction first per
            // ADR-0102 — the stored-domain model — with its stage
            // published.
            let input: ImageData
            if let crop = request.crop {
                let cropNames = try naming(.cropped(layerIndex: index))
                input = try await RegionExtractionOperation.execute(
                    input: published,
                    region: try ImageRegion(
                        lowerBounds: [crop.lowerX, crop.lowerY],
                        upperBounds: [crop.upperX, crop.upperY]
                    ),
                    outputObjectID: cropNames.outputObjectID,
                    outputProvenanceID: cropNames.provenanceID,
                    createdAt: cropNames.createdAt,
                    software: software,
                    coordinator: readCoordinator
                )
                _ = try await publisher.publish(input, mode: .complete)
            } else {
                input = published
            }

            let names = try naming(.windowLevelled(layerIndex: index))
            var staged = try await windowStage(input, window, names)
            _ = try await publisher.publish(staged, mode: .complete)

            // Inverted polarity runs the registered ADR-0112 exact
            // involution over the window output, also published —
            // independence from the value model made structural.
            if window.polarity == .inverted {
                let invertNames = try naming(.inverted(layerIndex: index))
                staged = try await invertStage(staged, invertNames)
                _ = try await publisher.publish(staged, mode: .complete)
            }
            windowLevelled.append(staged)
        }

        // More than one layer, or a single-layer fade per ADR-0094,
        // blends through the registered compositing operation, also
        // published; a single layer at opacity one is already
        // presented, and an opacity-one composite would mint a
        // value-identical object with no presentation meaning.
        let presented: ImageData
        if windowLevelled.count == 1, request.scene.layers[0].opacity == 1 {
            presented = windowLevelled[0]
        } else {
            let names = try naming(.composited)
            presented = try await compositeStage(
                windowLevelled,
                request.scene.layers.map(\.opacity),
                names
            )
            _ = try await publisher.publish(presented, mode: .complete)
        }

        // A viewport equal to the presented extents is already
        // presented; an identity resample would mint a bit-identical
        // object with no presentation meaning.
        let extents = presented.descriptor.shape.extents
        let output: ImageData
        let scaling: PresentationScaling
        if extents.count == 2,
            extents[0] == request.viewport.width,
            extents[1] == request.viewport.height
        {
            output = presented
            scaling = .identity
        } else {
            // The ADR-0124 policy dispatch: the registered operation
            // the policy names runs and the claim states what ran.
            let resampleNames = try naming(.resampled)
            switch request.interpolation {
            case .nearestNeighbour:
                output = try await ResampleNearestOperation.execute(
                    input: presented,
                    outputWidth: request.viewport.width,
                    outputHeight: request.viewport.height,
                    outputObjectID: resampleNames.outputObjectID,
                    outputProvenanceID: resampleNames.provenanceID,
                    createdAt: resampleNames.createdAt,
                    software: software,
                    coordinator: readCoordinator
                )
                scaling = .nearestNeighbour(
                    sourceWidth: extents[0],
                    sourceHeight: extents[1]
                )
            case .linear:
                output = try await ResampleLinearOperation.execute(
                    input: presented,
                    outputWidth: request.viewport.width,
                    outputHeight: request.viewport.height,
                    outputObjectID: resampleNames.outputObjectID,
                    outputProvenanceID: resampleNames.provenanceID,
                    createdAt: resampleNames.createdAt,
                    software: software,
                    coordinator: readCoordinator
                )
                scaling = .bilinear(
                    sourceWidth: extents[0],
                    sourceHeight: extents[1]
                )
            }
            _ = try await publisher.publish(output, mode: .complete)
        }

        return RenderResult(
            outputObjectID: output.identity.objectID,
            presentation: PresentationProvenance(
                camera: request.scene.camera,
                viewport: request.viewport,
                layers: request.scene.layers,
                crop: request.crop,
                geometry: output.descriptor.spatialGeometry,
                scaling: scaling,
                renderMode: .slice,
                colourOutput: .greyscale8,
                accumulation: .none,
                denoising: .none
            )
        )
    }
}
