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
    case viewportMismatch
}

/// The host-supplied naming for one render's published output; the
/// renderer mints no identifiers and acquires no clock.
public typealias RenderPublicationNaming =
    @Sendable () throws -> (
        outputObjectID: DataObjectID,
        provenanceID: ProvenanceID,
        createdAt: CanonicalInstant
    )

/// The first `SliceRenderer` conformer per `ADR-0086`: exact
/// axis-aligned identity slice presentation composed entirely from
/// accepted, evidence-carrying contracts.
///
/// The renderer executes the accepted window-level operation over a
/// published single-layer scene and publishes the output through the
/// accepted publication coordinator; no new numeric model exists, so
/// the result is exact by construction. Oblique, perspective and
/// resampled presentation stay blocked by the `VOX-SPA-004`
/// float-bounds gate, and a GPU path may later arrive behind this same
/// contract.
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
        // Version-one admission: one layer, published, identity
        // presentation only.
        guard request.scene.layers.count == 1 else {
            throw SliceRendererError.unsupportedSceneShape
        }
        let layer = request.scene.layers[0]
        guard
            let input = await publisher.publishedImage(for: layer.imageObjectID)
        else {
            throw SliceRendererError.imageNotPublished
        }
        let extents = input.descriptor.shape.extents
        guard
            extents.count == 2,
            extents[0] == request.viewport.width,
            extents[1] == request.viewport.height
        else {
            throw SliceRendererError.viewportMismatch
        }

        // The accepted window-level operation is the entire numeric
        // path; the host supplies naming and the instant.
        guard case .greyscaleWindow(let window) = layer.transferFunction else {
            throw SliceRendererError.unsupportedSceneShape
        }
        let names = try naming()
        let output = try await WindowLevelOperation.execute(
            input: input,
            center: try MetadataFloatingPoint(value: window.center),
            width: try MetadataFloatingPoint(value: window.width),
            outputObjectID: names.outputObjectID,
            outputProvenanceID: names.provenanceID,
            createdAt: names.createdAt,
            software: software,
            coordinator: readCoordinator
        )
        _ = try await publisher.publish(output, mode: .complete)

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
