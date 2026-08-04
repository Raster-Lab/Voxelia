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
    case unsupportedLayerOpacity
}

/// The closed set of published stages one render can produce; the
/// host names each stage per `ADR-0089` as revised by `ADR-0091`.
public enum RenderPublicationStage: Sendable, Equatable {
    case windowLevelled(layerIndex: Int)
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
    private let publisher: PublicationCoordinator
    private let readCoordinator: StorageReadCoordinator
    private let software: SoftwareIdentity
    private let naming: RenderPublicationNaming

    /// Creates a renderer over accepted coordinators with host-owned
    /// naming.
    public init(
        publisher: PublicationCoordinator,
        readCoordinator: StorageReadCoordinator,
        software: SoftwareIdentity,
        naming: @escaping RenderPublicationNaming
    ) {
        self.publisher = publisher
        self.readCoordinator = readCoordinator
        self.software = software
        self.naming = naming
    }

    /// Renders one request exactly.
    ///
    /// - Throws: ``SliceRendererError``, or the audited typed errors
    ///   of the execution and publication contracts.
    public func render(_ request: RenderRequest) async throws -> RenderResult {
        // A single-layer scene keeps its accepted single-publication
        // shape, so it requires full opacity — a single-layer fade
        // would widen the compositing admission, its own decision.
        if request.scene.layers.count == 1,
            request.scene.layers[0].opacity != 1
        {
            throw SliceRendererError.unsupportedLayerOpacity
        }

        // Window-level every published greyscale layer in scene order
        // — the value model consumes the stored domain — publishing
        // each stage, so the ancestry closure stays complete in the
        // registry.
        var windowLevelled = [ImageData]()
        windowLevelled.reserveCapacity(request.scene.layers.count)
        for (index, layer) in request.scene.layers.enumerated() {
            guard
                let input = await publisher.publishedImage(
                    for: layer.imageObjectID
                )
            else {
                throw SliceRendererError.imageNotPublished
            }
            guard case .greyscaleWindow(let window) = layer.transferFunction
            else {
                throw SliceRendererError.unsupportedSceneShape
            }
            let names = try naming(.windowLevelled(layerIndex: index))
            let staged = try await WindowLevelOperation.execute(
                input: input,
                center: try MetadataFloatingPoint(value: window.center),
                width: try MetadataFloatingPoint(value: window.width),
                outputObjectID: names.outputObjectID,
                outputProvenanceID: names.provenanceID,
                createdAt: names.createdAt,
                software: software,
                coordinator: readCoordinator
            )
            _ = try await publisher.publish(staged, mode: .complete)
            windowLevelled.append(staged)
        }

        // More than one layer blends through the registered
        // compositing operation, also published.
        let presented: ImageData
        if windowLevelled.count == 1 {
            presented = windowLevelled[0]
        } else {
            let names = try naming(.composited)
            presented = try await CompositeLayersOperation.execute(
                layers: windowLevelled,
                opacities: request.scene.layers.map(\.opacity),
                outputObjectID: names.outputObjectID,
                outputProvenanceID: names.provenanceID,
                createdAt: names.createdAt,
                software: software,
                coordinator: readCoordinator
            )
            _ = try await publisher.publish(presented, mode: .complete)
        }

        // A viewport equal to the presented extents is already
        // presented; an identity resample would mint a bit-identical
        // object with no presentation meaning.
        let extents = presented.descriptor.shape.extents
        let output: ImageData
        if extents.count == 2,
            extents[0] == request.viewport.width,
            extents[1] == request.viewport.height
        {
            output = presented
        } else {
            let resampleNames = try naming(.resampled)
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
            _ = try await publisher.publish(output, mode: .complete)
        }

        return RenderResult(
            outputObjectID: output.identity.objectID,
            presentation: PresentationProvenance(
                camera: request.scene.camera,
                viewport: request.viewport,
                layers: request.scene.layers,
                renderMode: .slice,
                colourOutput: .greyscale8,
                accumulation: .none,
                denoising: .none
            )
        )
    }
}
