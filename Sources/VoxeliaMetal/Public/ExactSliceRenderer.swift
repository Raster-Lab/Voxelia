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
/// host names each stage per `ADR-0089`.
public enum RenderPublicationStage: Sendable, Equatable {
    case windowLevelled
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
        // Admission: one published greyscale layer.
        guard request.scene.layers.count == 1 else {
            throw SliceRendererError.unsupportedSceneShape
        }
        let layer = request.scene.layers[0]
        guard
            let input = await publisher.publishedImage(for: layer.imageObjectID)
        else {
            throw SliceRendererError.imageNotPublished
        }
        guard case .greyscaleWindow(let window) = layer.transferFunction else {
            throw SliceRendererError.unsupportedSceneShape
        }

        // Window-level first — the value model consumes the stored
        // domain — and every derived stage publishes, so the ancestry
        // closure stays complete in the registry.
        let windowNames = try naming(.windowLevelled)
        let windowLevelled = try await WindowLevelOperation.execute(
            input: input,
            center: try MetadataFloatingPoint(value: window.center),
            width: try MetadataFloatingPoint(value: window.width),
            outputObjectID: windowNames.outputObjectID,
            outputProvenanceID: windowNames.provenanceID,
            createdAt: windowNames.createdAt,
            software: software,
            coordinator: readCoordinator
        )
        _ = try await publisher.publish(windowLevelled, mode: .complete)

        // A viewport equal to the image extents is already presented;
        // an identity resample would mint a bit-identical object with
        // no presentation meaning.
        let extents = input.descriptor.shape.extents
        let output: ImageData
        if extents.count == 2,
            extents[0] == request.viewport.width,
            extents[1] == request.viewport.height
        {
            output = windowLevelled
        } else {
            let resampleNames = try naming(.resampled)
            output = try await ResampleNearestOperation.execute(
                input: windowLevelled,
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
                transferFunction: layer.transferFunction,
                renderMode: .slice,
                colourOutput: .greyscale8,
                accumulation: .none,
                denoising: .none
            )
        )
    }
}
