// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaSpatial

/// An error raised by ray-generator admission.
///
/// The degenerate-basis obligations are discharged by the accepted
/// camera's own admission — its no-epsilon rules reject a zero view
/// vector and an up parallel to the view direction — so no duplicate
/// case exists here.
public enum RayGenerationError: Error, Sendable, Equatable {
    /// The camera's projection is the deferred perspective case.
    case unsupportedProjection
}

/// The orthographic per-pixel ray generator per `ADR-0173`,
/// realising the frozen `VOXELIA-ALG-0024` model.
///
/// The basis composes the accepted norm and cross forms once at
/// construction; pixel centres sample the plane with row zero at the
/// top, and rays return as the accepted primitive in the camera's
/// coordinate space. Everything this feeds is presentation, never a
/// source of authoritative quantitative measurement, per the arc's
/// binding rule.
public struct OrthographicRayGenerator: Sendable {
    private let position: Point3D
    private let forward: (x: Double, y: Double, z: Double)
    private let right: (x: Double, y: Double, z: Double)
    private let trueUp: (x: Double, y: Double, z: Double)
    private let planeWidth: Double
    private let planeHeight: Double
    private let viewport: ViewportSize

    /// Builds a generator for one camera and viewport.
    ///
    /// - Throws: ``RayGenerationError``.
    public init(camera: RenderCamera, viewport: ViewportSize) throws {
        guard case .orthographic(let planeHeight) = camera.projection else {
            throw RayGenerationError.unsupportedProjection
        }
        let viewX = camera.target.x - camera.position.x
        let viewY = camera.target.y - camera.position.y
        let viewZ = camera.target.z - camera.position.z
        // The accepted camera admission guarantees a non-zero view
        // vector and a non-degenerate up, so both norms are positive
        // and the basis divisions are total here.
        let viewNorm =
            (((viewX * viewX) + (viewY * viewY)) + (viewZ * viewZ))
            .squareRoot()
        let forward = (
            x: viewX / viewNorm, y: viewY / viewNorm, z: viewZ / viewNorm
        )
        let crossX = (forward.y * camera.up.z) - (forward.z * camera.up.y)
        let crossY = (forward.z * camera.up.x) - (forward.x * camera.up.z)
        let crossZ = (forward.x * camera.up.y) - (forward.y * camera.up.x)
        let crossNorm =
            (((crossX * crossX) + (crossY * crossY)) + (crossZ * crossZ))
            .squareRoot()
        let right = (
            x: crossX / crossNorm, y: crossY / crossNorm, z: crossZ / crossNorm
        )
        self.position = camera.position
        self.forward = forward
        self.right = right
        self.trueUp = (
            x: (right.y * forward.z) - (right.z * forward.y),
            y: (right.z * forward.x) - (right.x * forward.z),
            z: (right.x * forward.y) - (right.y * forward.x)
        )
        self.planeHeight = planeHeight
        self.planeWidth =
            planeHeight * (Double(viewport.width) / Double(viewport.height))
        self.viewport = viewport
    }

    /// The frozen per-pixel ray: pixel centres over the plane with
    /// row zero at the top.
    ///
    /// - Throws: The accepted primitives' own typed admissions,
    ///   unreachable for a validated basis.
    public func ray(atPixelX pixelX: Int, pixelY pixelY: Int) throws -> Ray3D {
        let horizontal =
            (((Double(pixelX) + 0.5) / Double(viewport.width)) - 0.5)
            * planeWidth
        let vertical =
            (0.5 - ((Double(pixelY) + 0.5) / Double(viewport.height)))
            * planeHeight
        let originX =
            (position.x + (horizontal * right.x)) + (vertical * trueUp.x)
        let originY =
            (position.y + (horizontal * right.y)) + (vertical * trueUp.y)
        let originZ =
            (position.z + (horizontal * right.z)) + (vertical * trueUp.z)
        return try Ray3D(
            origin: try Point3D(
                x: originX,
                y: originY,
                z: originZ,
                coordinateSpace: position.coordinateSpace
            ),
            direction: try Vector3D(
                x: forward.x,
                y: forward.y,
                z: forward.z,
                coordinateSpace: position.coordinateSpace
            )
        )
    }
}
