// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// One world-space axis-aligned clip per `ADR-0179` (`VOX-DVR-009`),
/// mirroring the accepted interaction clip box exactly — the
/// interaction module sits above rendering and cannot be imported
/// downward, and the design record binds this mirror never to drift.
public struct VolumeClipBounds: Sendable, Hashable {
    public let minimum: Point3D
    public let maximum: Point3D

    /// Creates a validated clip.
    ///
    /// - Throws: ``RenderModelError/coordinateSpaceMismatch`` or
    ///   ``RenderModelError/invalidClipBounds``.
    public init(minimum: Point3D, maximum: Point3D) throws {
        guard minimum.coordinateSpace == maximum.coordinateSpace else {
            throw RenderModelError.coordinateSpaceMismatch
        }
        guard
            minimum.x < maximum.x,
            minimum.y < maximum.y,
            minimum.z < maximum.z
        else {
            throw RenderModelError.invalidClipBounds
        }
        self.minimum = minimum
        self.maximum = maximum
    }
}

/// One segmentation-mask selection per `ADR-0180` (`VOX-DVR-010`): one
/// mask volume paired with a non-empty visible-label allow-list — an
/// unrecognised label defaults to hidden, never shown.
public struct VolumeMaskSelection: Sendable, Hashable {
    public let maskObjectID: DataObjectID
    public let visibleLabels: Set<UInt8>

    /// Creates a validated mask selection.
    ///
    /// - Throws: ``RenderModelError/emptyVisibleLabelSet`` when
    ///   `visibleLabels` is empty — a mask that hides every label is
    ///   almost certainly a caller error, and the fully-hidden case
    ///   is already reachable by omitting the mask entirely.
    public init(maskObjectID: DataObjectID, visibleLabels: Set<UInt8>) throws {
        guard !visibleLabels.isEmpty else {
            throw RenderModelError.emptyVisibleLabelSet
        }
        self.maskObjectID = maskObjectID
        self.visibleLabels = visibleLabels
    }
}

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

    /// The explicit optional world-space clip; absence is stated.
    public let clip: VolumeClipBounds?

    /// The explicit optional index-space crop; absence is stated.
    public let crop: ImageRegion?

    /// The explicit optional segmentation-mask selection; absence is
    /// stated.
    public let mask: VolumeMaskSelection?

    /// The explicit optional empty-space-skipping brick grid; absence
    /// is stated.
    public let acceleration: BrickGridDescriptor?

    public init(
        volumeObjectID: DataObjectID,
        table: TransferFunction1D,
        camera: RenderCamera,
        viewport: ViewportSize,
        quality: String,
        lighting: VolumeLightingModel,
        clip: VolumeClipBounds?,
        crop: ImageRegion?,
        mask: VolumeMaskSelection?,
        acceleration: BrickGridDescriptor?
    ) {
        self.volumeObjectID = volumeObjectID
        self.table = table
        self.camera = camera
        self.viewport = viewport
        self.quality = quality
        self.lighting = lighting
        self.clip = clip
        self.crop = crop
        self.mask = mask
        self.acceleration = acceleration
    }
}
