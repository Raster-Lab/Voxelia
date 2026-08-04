// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaRendering

/// The GPU slice renderer per `ADR-0092`: the accepted presentation
/// pipeline with the device window stage.
///
/// The window stage executes ``MetalWindowLevelOperation`` — honest
/// `binary32-device`, `approximate`, kernel-referenced claims — while
/// the composite and resample stages remain the accepted CPU
/// operations. Choosing this renderer is the host's explicit backend
/// decision; there is no silent fallback in either direction.
public final class MetalSliceRenderer: SliceRenderer, Sendable {
    private let pipeline: ExactSliceRenderer

    /// Creates a GPU renderer over one compiled kernel, accepted
    /// coordinators and host-owned naming.
    public init(
        kernel: MetalWindowLevelKernel,
        publisher: PublicationCoordinator,
        readCoordinator: StorageReadCoordinator,
        software: SoftwareIdentity,
        naming: @escaping RenderPublicationNaming
    ) {
        self.pipeline = ExactSliceRenderer(
            publisher: publisher,
            readCoordinator: readCoordinator,
            software: software,
            naming: naming,
            windowStage: { input, window, names in
                try await MetalWindowLevelOperation.execute(
                    input: input,
                    center: try MetadataFloatingPoint(value: window.center),
                    width: try MetadataFloatingPoint(value: window.width),
                    outputObjectID: names.outputObjectID,
                    outputProvenanceID: names.provenanceID,
                    createdAt: names.createdAt,
                    software: software,
                    coordinator: readCoordinator,
                    kernel: kernel
                )
            }
        )
    }

    /// Renders one request through the device window stage.
    ///
    /// - Throws: ``SliceRendererError``, or the audited typed errors
    ///   of the execution, kernel and publication contracts.
    public func render(_ request: RenderRequest) async throws -> RenderResult {
        try await pipeline.render(request)
    }
}
