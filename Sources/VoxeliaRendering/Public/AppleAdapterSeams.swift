// SPDX-License-Identifier: MIT

import VoxeliaGeometry
import VoxeliaSpatial

/// An error raised by the Apple adapter seams.
public enum AppleAdapterError: Error, Sendable, Equatable {
    /// The annotation label was empty or whitespace-only.
    case emptyAnnotationLabel
}

/// One labelled spatial annotation for presentation: a physical anchor
/// and its label — the canonical vocabulary, nothing platform-shaped.
public struct SpatialAnnotation: Sendable, Hashable {
    public let anchor: Point3D
    public let label: String

    /// Creates a validated annotation.
    ///
    /// - Throws: ``AppleAdapterError/emptyAnnotationLabel``.
    public init(anchor: Point3D, label: String) throws {
        guard label.contains(where: { !$0.isWhitespace }) else {
            throw AppleAdapterError.emptyAnnotationLabel
        }
        self.anchor = anchor
        self.label = label
    }
}

/// The RealityKit-facing seam of `VOX-ADP-001`/`VOX-ADP-002`, per
/// `ADR-0404`: an associated entity type keeps RealityKit out of the
/// canonical modules (which already prohibit its import), and
/// availability is the adapter's own declared report — "where platform
/// capability permits" is never a canonical-module conditional.
public protocol SpatialPresentationAdapter: Sendable {
    associatedtype Entity

    /// The adapter's stable identity, for provenance.
    var adapterIdentity: String { get }
    /// Whether the platform capability permits spatial presentation.
    var isAvailable: Bool { get }

    /// Presents one canonical surface.
    func spatialEntity(for mesh: TriangleMesh) throws -> Entity

    /// Presents one labelled annotation.
    func spatialEntity(for annotation: SpatialAnnotation) throws -> Entity
}

/// The Core Image-facing seam of `VOX-ADP-004`, per `ADR-0404`: the
/// limitation is the signature — the input is two-dimensional raw
/// pixels, and no volume, scene or camera exists in the type, so
/// "limited to suitable two-dimensional workflows" is the only thing
/// expressible.
public protocol TwoDimensionalMediaAdapter: Sendable {
    associatedtype Image

    /// The adapter's stable identity, for provenance.
    var adapterIdentity: String { get }

    /// Wraps two-dimensional raw pixels for a compositing, export,
    /// thumbnail or media workflow.
    func image(
        rawPixels: ContiguousArray<UInt8>,
        width: Int,
        height: Int
    ) throws -> Image
}
