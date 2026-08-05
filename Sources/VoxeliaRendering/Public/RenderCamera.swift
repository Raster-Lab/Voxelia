// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised while validating a rendering model value.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// coordinates, spaces or parameters.
public enum RenderModelError: Error, Sendable, Equatable {
    case invalidViewportDimension
    case coordinateSpaceMismatch
    case degenerateViewDirection
    case degenerateUpDirection
    case invalidProjectionParameter
    case invalidWindowParameter
    case emptyScene
    case layerLimitExceeded
    case invalidLayerOpacity
    case invalidCropBounds
    case invalidClipBounds
}

/// One validated positive pixel viewport size per `ADR-0082`.
///
/// The inclusive per-dimension ceiling is a hard admission bound, not
/// a device claim; device texture limits remain runtime capability
/// evidence.
public struct ViewportSize: Sendable, Hashable {
    /// The inclusive per-dimension pixel ceiling.
    public static let maximumDimension = 16_384

    public let width: Int
    public let height: Int

    /// Creates a validated viewport size.
    ///
    /// - Throws: ``RenderModelError/invalidViewportDimension``.
    public init(width: Int, height: Int) throws {
        guard
            width >= 1, width <= Self.maximumDimension,
            height >= 1, height <= Self.maximumDimension
        else {
            throw RenderModelError.invalidViewportDimension
        }
        self.width = width
        self.height = height
    }
}

/// The closed backend-neutral projection description per `ADR-0082`.
///
/// Parameters are admitted at camera construction, the owning
/// aggregate, following the axis-sampling precedent.
public enum CameraProjection: Sendable, Hashable {
    /// A parallel projection with the view-plane height in world
    /// units.
    case orthographic(planeHeight: Double)
    /// A perspective projection with the vertical field of view in
    /// radians, strictly between zero and pi.
    case perspective(verticalFieldOfViewRadians: Double)
}

/// One validated backend-neutral look-at camera per `ADR-0082`.
///
/// The camera is a description of intent in exact binary64: no
/// float-precision transform derivation happens here, because
/// `VOX-SPA-004` admits rendering-specific float transforms only after
/// verified error bounds, which remain a recorded gate.
public struct RenderCamera: Sendable, Hashable {
    public let position: Point3D
    public let target: Point3D
    public let up: Vector3D
    public let projection: CameraProjection

    /// Creates a validated camera.
    ///
    /// - Throws: ``RenderModelError``.
    public init(
        position: Point3D,
        target: Point3D,
        up: Vector3D,
        projection: CameraProjection
    ) throws {
        guard
            position.coordinateSpace == target.coordinateSpace,
            position.coordinateSpace == up.coordinateSpace
        else {
            throw RenderModelError.coordinateSpaceMismatch
        }
        let viewX = target.x - position.x
        let viewY = target.y - position.y
        let viewZ = target.z - position.z
        guard viewX != 0 || viewY != 0 || viewZ != 0 else {
            throw RenderModelError.degenerateViewDirection
        }
        // The cross product of the view direction and up must have a
        // magnitude at or above the smallest normal binary64 value —
        // the accepted no-epsilon degeneracy rule.
        let crossX = viewY * up.z - viewZ * up.y
        let crossY = viewZ * up.x - viewX * up.z
        let crossZ = viewX * up.y - viewY * up.x
        let crossMagnitude =
            (crossX * crossX + crossY * crossY + crossZ * crossZ).squareRoot()
        guard
            crossMagnitude.isFinite,
            crossMagnitude >= Double.leastNormalMagnitude
        else {
            throw RenderModelError.degenerateUpDirection
        }
        switch projection {
        case .orthographic(let planeHeight):
            guard planeHeight.isFinite, planeHeight > 0 else {
                throw RenderModelError.invalidProjectionParameter
            }
        case .perspective(let fieldOfView):
            guard fieldOfView.isFinite, fieldOfView > 0, fieldOfView < .pi
            else {
                throw RenderModelError.invalidProjectionParameter
            }
        }
        self.position = position
        self.target = target
        self.up = up
        self.projection = projection
    }
}
