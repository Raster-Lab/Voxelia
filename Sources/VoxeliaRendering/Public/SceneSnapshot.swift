// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed render-quality description per `ADR-0084`.
///
/// Accumulation and denoising are result-provenance states, not
/// quality requests; version-one renderers are deterministic
/// single-pass.
public enum RenderQuality: Sendable, Hashable {
    case interactive
    case full
}

/// One published image layer per `ADR-0084`.
///
/// The layer references a published immutable bundle by its object
/// identifier — the accepted lifecycle makes the binding immutable —
/// with its presentation transfer function. Opacity and blending
/// arrive with multi-layer compositing as their own registered model.
public struct RenderLayer: Sendable, Hashable {
    public let imageObjectID: DataObjectID
    public let transferFunction: TransferFunction

    public init(imageObjectID: DataObjectID, transferFunction: TransferFunction) {
        self.imageObjectID = imageObjectID
        self.transferFunction = transferFunction
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
