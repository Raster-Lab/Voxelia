// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed version-one render mode per `ADR-0085`.
public enum RenderMode: Sendable, Hashable {
    case slice
}

/// The closed version-one colour output configuration per `ADR-0085`.
public enum ColourOutputConfiguration: Sendable, Hashable {
    case greyscale8
}

/// The closed version-one accumulation state per `ADR-0085`.
public enum AccumulationState: Sendable, Hashable {
    case none
}

/// The closed version-one denoising state per `ADR-0085`.
public enum DenoisingState: Sendable, Hashable {
    case none
}

/// One render request per `ADR-0085`: already-validated members
/// composed memberwise.
public struct RenderRequest: Sendable, Hashable {
    public let scene: SceneSnapshot
    public let viewport: ViewportSize
    public let quality: RenderQuality

    public init(
        scene: SceneSnapshot,
        viewport: ViewportSize,
        quality: RenderQuality
    ) {
        self.scene = scene
        self.viewport = viewport
        self.quality = quality
    }
}

/// The honest CDMS section 12.4 presentation-provenance subset per
/// `ADR-0085`.
///
/// The presentation transform is deferred behind the `VOX-SPA-004`
/// float-bounds gate, clipping and cropping await their own model, and
/// the random seed field arrives with the first stochastic mode — a
/// deterministic pipeline recording a seed would be a false claim.
public struct PresentationProvenance: Sendable, Hashable {
    public let camera: RenderCamera
    public let viewport: ViewportSize
    public let transferFunction: TransferFunction
    public let renderMode: RenderMode
    public let colourOutput: ColourOutputConfiguration
    public let accumulation: AccumulationState
    public let denoising: DenoisingState

    public init(
        camera: RenderCamera,
        viewport: ViewportSize,
        transferFunction: TransferFunction,
        renderMode: RenderMode,
        colourOutput: ColourOutputConfiguration,
        accumulation: AccumulationState,
        denoising: DenoisingState
    ) {
        self.camera = camera
        self.viewport = viewport
        self.transferFunction = transferFunction
        self.renderMode = renderMode
        self.colourOutput = colourOutput
        self.accumulation = accumulation
        self.denoising = denoising
    }
}

/// One claim-bearing render result per `ADR-0085`.
///
/// Construction proves structural validity only; publication and graph
/// coherence stay with the accepted publication coordinator.
public struct RenderResult: Sendable, Hashable {
    public let outputObjectID: DataObjectID
    public let presentation: PresentationProvenance

    public init(
        outputObjectID: DataObjectID,
        presentation: PresentationProvenance
    ) {
        self.outputObjectID = outputObjectID
        self.presentation = presentation
    }
}

/// The backend-neutral renderer contract per `ADR-0085`.
///
/// A GPU slice renderer for oblique or perspective geometry is blocked
/// by the `VOX-SPA-004` float-bounds gate; an exact axis-aligned CPU
/// slice presenter composing the accepted region-extraction and
/// window-level operations is the natural first conformer.
public protocol SliceRenderer: Sendable {
    func render(_ request: RenderRequest) async throws -> RenderResult
}
