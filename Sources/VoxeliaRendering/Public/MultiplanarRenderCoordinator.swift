// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaImaging

/// Renders one axis-aligned plane of a published volume per `ADR-0221`
/// (`VOX-VS1-009`, `VOX-VS1-010`).
///
/// **This coordinator does not reconstruct planes; it renders a reconstruction
/// the accepted CPU path already produced.** `MPRSliceCoordinator` extracts the
/// plane by composing the registered region model and the singleton-axis
/// squeeze, publishing both stages, and the renderer consumes that published
/// image as a scene layer. A GPU sampler for the reconstruction would be a
/// second sampling predicate that could disagree with the accepted one — the
/// refusal `ADR-0205` made for a second intersection and `ADR-0212` for a second
/// colour transform. An axis-aligned plane of a rank-three volume is an exact
/// byte selection, so a second path could only match or differ.
///
/// It introduces **no numeric rule of its own**: the region origin shift, the
/// squeeze, the window and the presentation path are all already accepted.
///
/// `VOX-ARC-006` holds by construction rather than by care. The renderer
/// arrives as the backend-neutral ``SliceRenderer``, so the Metal command
/// lifecycle stays entirely inside whatever conforms to it, and neither
/// `VoxeliaImaging` nor `VoxeliaRendering` can import Metal.
public enum MultiplanarRenderCoordinator {
    /// Extracts one plane and renders it through the supplied renderer.
    ///
    /// The colour claim is **forwarded, never chosen**: `ADR-0214` made the
    /// request's colour output, transform and declared space explicit and
    /// required, and picking them here would be the permissive default the
    /// house rule forbids.
    ///
    /// - Throws: `MPRError`, ``RenderModelError``, or the audited typed errors
    ///   of the extraction, publication and rendering contracts.
    public static func renderPlane(
        volumeID: DataObjectID,
        plane: MPRPlane,
        sliceIndex: Int,
        transferFunction: TransferFunction,
        viewport: ViewportSize,
        camera: RenderCamera,
        interpolation: InterpolationPolicy,
        quality: RenderQuality,
        colourOutput: ColourOutputConfiguration,
        colourTransform: DisplayColourTransform,
        outputColourSpace: DisplayColourSpace?,
        naming: @escaping MPRPublicationNaming,
        publisher: PublicationCoordinator,
        readCoordinator: StorageReadCoordinator,
        software: SoftwareIdentity,
        renderer: any SliceRenderer
    ) async throws -> RenderResult {
        let slice = try await MPRSliceCoordinator.extractSlice(
            volumeID: volumeID,
            plane: plane,
            sliceIndex: sliceIndex,
            naming: naming,
            publisher: publisher,
            readCoordinator: readCoordinator,
            software: software
        )

        // The plane is NOT restated here: the extracted object's own published
        // ancestry records the region and the squeeze, so the plane is
        // recoverable from it. Copying it into the presentation claim would
        // create a second place for one fact to drift.
        let layer = try RenderLayer(
            imageObjectID: slice.identity.objectID,
            transferFunction: transferFunction,
            opacity: 1
        )
        return try await renderer.render(
            RenderRequest(
                scene: try SceneSnapshot(layers: [layer], camera: camera),
                viewport: viewport,
                crop: nil,
                interpolation: interpolation,
                quality: quality,
                colourOutput: colourOutput,
                colourTransform: colourTransform,
                outputColourSpace: outputColourSpace
            )
        )
    }
}
