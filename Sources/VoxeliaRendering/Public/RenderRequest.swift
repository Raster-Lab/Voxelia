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

/// The closed presentation scaling claim per `ADR-0100`.
///
/// The producer records what the pipeline actually did — never what
/// was requested: `identity` when the resample stage never ran, or
/// nearest-neighbour per the registered `VOXELIA-ALG-0008` model with
/// the pre-resample source extents from the presented image's
/// validated descriptor. Richer geometric cases widen this closed set
/// through their own decisions.
public enum PresentationScaling: Sendable, Hashable {
    case identity
    case nearestNeighbour(sourceWidth: Int, sourceHeight: Int)
}

/// One validated half-open rank-two crop in image index space per
/// `ADR-0102`.
///
/// Construction proves non-negative, non-empty bounds; whether the
/// region fits a particular image is the extraction operation's own
/// typed admission.
public struct RenderCrop: Sendable, Hashable {
    public let lowerX: Int
    public let lowerY: Int
    public let upperX: Int
    public let upperY: Int

    /// Creates a validated crop.
    ///
    /// - Throws: ``RenderModelError/invalidCropBounds``.
    public init(lowerX: Int, lowerY: Int, upperX: Int, upperY: Int) throws {
        guard lowerX >= 0, lowerY >= 0, upperX > lowerX, upperY > lowerY else {
            throw RenderModelError.invalidCropBounds
        }
        self.lowerX = lowerX
        self.lowerY = lowerY
        self.upperX = upperX
        self.upperY = upperY
    }
}

/// One render request per `ADR-0085`, extended with the optional crop
/// by `ADR-0102`: already-validated members composed memberwise, with
/// absence stated explicitly.
public struct RenderRequest: Sendable, Hashable {
    public let scene: SceneSnapshot
    public let viewport: ViewportSize
    public let crop: RenderCrop?
    public let quality: RenderQuality

    public init(
        scene: SceneSnapshot,
        viewport: ViewportSize,
        crop: RenderCrop?,
        quality: RenderQuality
    ) {
        self.scene = scene
        self.viewport = viewport
        self.crop = crop
        self.quality = quality
    }
}

/// The honest CDMS section 12.4 presentation-provenance subset per
/// `ADR-0085`, revised by `ADR-0091` to claim every presented layer.
///
/// Each layer claim carries its object identifier, transfer function
/// and opacity in compositing order — one transfer function cannot
/// honestly describe a multi-layer result. The presentation transform
/// remains deferred, clipping and cropping await their own model, and
/// the random seed field arrives with the first stochastic mode — a
/// deterministic pipeline recording a seed would be a false claim.
public struct PresentationProvenance: Sendable, Hashable {
    public let camera: RenderCamera
    public let viewport: ViewportSize
    public let layers: ContiguousArray<RenderLayer>
    public let crop: RenderCrop?
    public let scaling: PresentationScaling
    public let renderMode: RenderMode
    public let colourOutput: ColourOutputConfiguration
    public let accumulation: AccumulationState
    public let denoising: DenoisingState

    public init(
        camera: RenderCamera,
        viewport: ViewportSize,
        layers: ContiguousArray<RenderLayer>,
        crop: RenderCrop?,
        scaling: PresentationScaling,
        renderMode: RenderMode,
        colourOutput: ColourOutputConfiguration,
        accumulation: AccumulationState,
        denoising: DenoisingState
    ) {
        self.camera = camera
        self.viewport = viewport
        self.layers = layers
        self.crop = crop
        self.scaling = scaling
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
