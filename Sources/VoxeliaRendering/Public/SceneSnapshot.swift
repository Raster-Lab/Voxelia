// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed render-quality description per `ADR-0084`.
///
/// Accumulation and denoising are result-provenance states, not
/// quality requests; version-one renderers are deterministic
/// single-pass, and per `ADR-0103` the two requests execute
/// identically: the request is a hint, stage claims record the
/// quality that actually ran, and a future degraded interactive path
/// will claim its own quality tokens through its own decisions.
public enum RenderQuality: Sendable, Hashable {
    case interactive
    case full
}

/// One published image layer per `ADR-0084` with the validated
/// compositing opacity added by `ADR-0091`.
///
/// The layer references a published immutable bundle by its object
/// identifier — the accepted lifecycle makes the binding immutable —
/// with its presentation transfer function and its opacity under the
/// registered `VOXELIA-ALG-0009` blending model.
public struct RenderLayer: Sendable, Hashable {
    public let imageObjectID: DataObjectID
    public let transferFunction: TransferFunction
    public let opacity: Double

    /// Creates a validated layer.
    ///
    /// - Throws: ``RenderModelError/invalidLayerOpacity`` unless the
    ///   opacity is finite and within zero through one inclusive.
    public init(
        imageObjectID: DataObjectID,
        transferFunction: TransferFunction,
        opacity: Double
    ) throws {
        guard opacity.isFinite, opacity >= 0, opacity <= 1 else {
            throw RenderModelError.invalidLayerOpacity
        }
        self.imageObjectID = imageObjectID
        self.transferFunction = transferFunction
        self.opacity = opacity
    }
}

/// One validated static scene snapshot per `ADR-0084`.
///
/// Layer order is compositing order and participates in identity.
public struct SceneSnapshot: Sendable, Hashable {
    /// The inclusive layer ceiling.
    public static let maximumLayerCount = 64

    public let layers: ContiguousArray<RenderLayer>
    public let camera: RenderCamera

    /// Creates a validated snapshot.
    ///
    /// - Throws: ``RenderModelError/emptyScene`` or
    ///   ``RenderModelError/layerLimitExceeded``.
    public init(
        layers: ContiguousArray<RenderLayer>,
        camera: RenderCamera
    ) throws {
        guard !layers.isEmpty else {
            throw RenderModelError.emptyScene
        }
        guard layers.count <= Self.maximumLayerCount else {
            throw RenderModelError.layerLimitExceeded
        }
        self.layers = layers
        self.camera = camera
    }
}
