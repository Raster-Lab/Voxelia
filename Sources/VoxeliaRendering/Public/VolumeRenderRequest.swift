// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The closed volume lighting vocabulary per `ADR-0177`
/// (`VOX-DVR-008`): `none` composites the accepted unshaded model
/// unchanged, and `headlight` applies the frozen
/// `VOXELIA-ALG-0025` factor. Positionable lights arrive with their
/// own records.
public enum VolumeLightingModel: String, Sendable, Hashable {
    case none
    case headlight
}

/// One closed volume-scene request per `ADR-0174`, extended by
/// `ADR-0177` with the explicit lighting member.
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

    /// The explicit lighting mode; absence is not a default.
    public let lighting: VolumeLightingModel

    public init(
        volumeObjectID: DataObjectID,
        table: TransferFunction1D,
        camera: RenderCamera,
        viewport: ViewportSize,
        quality: String,
        lighting: VolumeLightingModel
    ) {
        self.volumeObjectID = volumeObjectID
        self.table = table
        self.camera = camera
        self.viewport = viewport
        self.quality = quality
        self.lighting = lighting
    }
}
