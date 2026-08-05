// SPDX-License-Identifier: MIT

import VoxeliaCore

/// One closed volume-scene request per `ADR-0174`.
///
/// A volume scene is one calibrated volume, one transfer table, the
/// camera, the viewport and the quality token — the sampler validates
/// the token against the declared table at render time, so the
/// request carries it as supplied. Everything a volume render
/// produces is presentation, never a source of authoritative
/// quantitative measurement, per the arc's binding rule.
public struct VolumeRenderRequest: Sendable, Hashable {
    /// The published calibrated volume to render.
    public let volumeObjectID: DataObjectID

    /// The one-dimensional transfer table.
    public let table: TransferFunction1D

    /// The validated camera; version one renders the orthographic
    /// projection.
    public let camera: RenderCamera

    /// The validated output viewport.
    public let viewport: ViewportSize

    /// The registered quality token, validated at render time.
    public let quality: String

    public init(
        volumeObjectID: DataObjectID,
        table: TransferFunction1D,
        camera: RenderCamera,
        viewport: ViewportSize,
        quality: String
    ) {
        self.volumeObjectID = volumeObjectID
        self.table = table
        self.camera = camera
        self.viewport = viewport
        self.quality = quality
    }
}
