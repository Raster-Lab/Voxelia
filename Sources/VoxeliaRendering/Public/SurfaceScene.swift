// SPDX-License-Identifier: MIT

import VoxeliaGeometry
import VoxeliaSpatial

/// The closed failure family for surface scene admission.
///
/// Cases deliberately carry no payload so diagnostics cannot disclose
/// coordinates, transforms, mesh contents, layer counts or coordinate-space
/// identifiers.
public enum SurfaceSceneError: Error, Sendable, Equatable {
    /// The declared opacity is not a finite value in `[0, 1]`.
    case invalidOpacity

    /// The object-to-world transform's homogeneous bottom row is not
    /// exactly `(0, 0, 0, 1)`.
    case nonAffineObjectToWorld

    /// Two layers declared different world coordinate spaces.
    case worldSpaceMismatch

    /// The scene's world space is not the camera's declared space.
    case coordinateSpaceMismatch
}

/// Which material a surface layer selects.
///
/// This token names a selection; it does not model shading. Version one has
/// exactly one case, and the shading model it stands for is frozen by the
/// surface-arc materials increment rather than here.
///
/// Nothing switches over this token exhaustively, so a later case is purely
/// additive — the `ADR-0174` widening precedent. Adding a case is cheaper than
/// adding a stored member to ``SurfaceLayer`` later, which is why the token
/// exists before the model it selects.
public enum SurfaceMaterialSelection: Sendable, Hashable {
    /// The validated diagnostic surface material.
    case diagnostic
}

/// One immutable surface layer: a mesh, its placement and its appearance
/// selection.
///
/// The object-to-world transform is explicit at both ends. Its source space is
/// ``mesh``'s own declared coordinate space; its target space is
/// ``worldSpace``. Naming both is what `VOX-SUR-001` requires and carries the
/// accepted geometry rule that a transform records its source and target
/// spaces rather than relabelling coordinates.
///
/// This is a declaration value. It carries no identity, provenance or content
/// digest, and it renders nothing: the transform arithmetic, visibility rule,
/// compositing order and shading model all belong to later surface-arc
/// increments.
public struct SurfaceLayer: Sendable {
    /// The immutable canonical mesh, in its own declared coordinate space.
    public let mesh: TriangleMesh

    /// The affine transform mapping ``mesh`` coordinates into ``worldSpace``.
    public let objectToWorld: Matrix4x4Double

    /// The exact space ``objectToWorld`` maps into.
    public let worldSpace: CoordinateSpaceDescriptor

    /// The layer's opacity, a finite value in the inclusive unit interval.
    public let opacity: Double

    /// The material this layer selects.
    public let material: SurfaceMaterialSelection

    /// Creates and validates one surface layer.
    ///
    /// The transform must be affine — a projective bottom row would change
    /// what ``worldSpace`` means. A *singular* affine transform is admitted
    /// deliberately: collapsing a mesh to a plane or a point is a legitimate
    /// caller choice, and what a zero-area projected facet contributes is the
    /// visibility increment's decision, not this value's.
    ///
    /// - Throws: ``SurfaceSceneError/invalidOpacity`` when the opacity is not
    ///   a finite value in `[0, 1]`, and
    ///   ``SurfaceSceneError/nonAffineObjectToWorld`` when the transform's
    ///   homogeneous bottom row is not exactly `(0, 0, 0, 1)`.
    public init(
        mesh: TriangleMesh,
        objectToWorld: Matrix4x4Double,
        worldSpace: CoordinateSpaceDescriptor,
        opacity: Double,
        material: SurfaceMaterialSelection
    ) throws {
        guard opacity.isFinite, opacity >= 0, opacity <= 1 else {
            throw SurfaceSceneError.invalidOpacity
        }
        let elements = objectToWorld.elements
        guard
            elements[12] == 0,
            elements[13] == 0,
            elements[14] == 0,
            elements[15] == 1
        else {
            throw SurfaceSceneError.nonAffineObjectToWorld
        }
        self.mesh = mesh
        self.objectToWorld = objectToWorld
        self.worldSpace = worldSpace
        self.opacity = opacity
        self.material = material
    }
}

/// One immutable ordered set of surface layers sharing a single world space.
///
/// Layer order is preserved exactly and is **not** a draw order. Any ordering
/// the compositing increment needs is that increment's to freeze.
///
/// Repeated meshes and repeated placements are admitted: the same mesh placed
/// twice is a legitimate scene. An empty scene is admitted, declares no world
/// space and renders no surface.
public struct SurfaceSceneSnapshot: Sendable {
    /// The layers in exact declaration order.
    public let layers: ContiguousArray<SurfaceLayer>

    /// The single world space every layer maps into, or `nil` when empty.
    public var worldSpace: CoordinateSpaceDescriptor? {
        layers.first?.worldSpace
    }

    /// Creates a scene from layers that must agree on one world space.
    ///
    /// - Throws: ``SurfaceSceneError/worldSpaceMismatch`` when two layers
    ///   declare different world coordinate spaces.
    public init(layers: ContiguousArray<SurfaceLayer>) throws {
        if let expected = layers.first?.worldSpace {
            for layer in layers.dropFirst() {
                guard layer.worldSpace == expected else {
                    throw SurfaceSceneError.worldSpaceMismatch
                }
            }
        }
        self.layers = layers
    }
}

/// One immutable surface render declaration.
///
/// This is the only place the scene's world space and the camera meet. There
/// is deliberately no result type yet: a result must describe pixels, and the
/// pixel and depth contract belongs to the surface arc's projection and
/// visibility increments, exactly as the volume arc's vocabulary froze its
/// request and its renderer defined its result.
public struct SurfaceRenderRequest: Sendable {
    /// The scene to render.
    public let scene: SurfaceSceneSnapshot

    /// The camera, whose own declared space must be the scene's world space.
    public let camera: RenderCamera

    /// The output viewport.
    public let viewport: ViewportSize

    /// Creates a validated surface render request.
    ///
    /// An empty scene imposes no camera constraint, because it declares no
    /// world space.
    ///
    /// The comparison is by coordinate-space *identifier*: `Point3D` carries a
    /// `CoordinateSpaceID`, while a layer carries the full
    /// `CoordinateSpaceDescriptor` its mesh geometry needs. The identifier is
    /// the shared name, and this request deliberately does not invent a rule
    /// requiring the camera to restate a convention, handedness or unit it
    /// does not model.
    ///
    /// - Throws: ``SurfaceSceneError/coordinateSpaceMismatch`` when a
    ///   non-empty scene's world space is not the camera's declared space.
    public init(
        scene: SurfaceSceneSnapshot,
        camera: RenderCamera,
        viewport: ViewportSize
    ) throws {
        if let worldSpace = scene.worldSpace {
            guard worldSpace.id == camera.position.coordinateSpace else {
                throw SurfaceSceneError.coordinateSpaceMismatch
            }
        }
        self.scene = scene
        self.camera = camera
        self.viewport = viewport
    }
}
