// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("RenderCamera")
struct RenderCameraTests {
    private func space(_ name: String = "patient") throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: name))
    }

    private func point(
        _ x: Double,
        _ y: Double,
        _ z: Double,
        space name: String = "patient"
    ) throws -> Point3D {
        try Point3D(x: x, y: y, z: z, coordinateSpace: try space(name))
    }

    private func vector(
        _ x: Double,
        _ y: Double,
        _ z: Double,
        space name: String = "patient"
    ) throws -> Vector3D {
        try Vector3D(x: x, y: y, z: z, coordinateSpace: try space(name))
    }

    @Test("[Unit][VOX-ARC-008][VOX-ERR-001] cameras and viewports validate exactly")
    func camerasAndViewportsValidateExactly() throws {
        // Viewport bounds are inclusive hard admissions.
        _ = try ViewportSize(width: 1, height: 1)
        _ = try ViewportSize(width: 16_384, height: 16_384)
        for (width, height) in [(0, 1), (1, 0), (16_385, 1), (1, -1)] {
            do {
                _ = try ViewportSize(width: width, height: height)
                #expect(Bool(false), "Expected an invalid dimension to be rejected.")
            } catch RenderModelError.invalidViewportDimension {}
        }

        // A valid orthographic and a valid perspective camera admit.
        let camera = try RenderCamera(
            position: try point(0, 0, -100),
            target: try point(0, 0, 0),
            up: try vector(0, 1, 0),
            projection: .orthographic(planeHeight: 250)
        )
        #expect(camera.projection == .orthographic(planeHeight: 250))
        _ = try RenderCamera(
            position: try point(0, 0, -100),
            target: try point(0, 0, 0),
            up: try vector(0, 1, 0),
            projection: .perspective(verticalFieldOfViewRadians: Double.pi / 3)
        )

        // Every space must agree; the view and up directions must be
        // non-degenerate under the no-epsilon cross-product rule.
        do {
            _ = try RenderCamera(
                position: try point(0, 0, -100),
                target: try point(0, 0, 0, space: "detector"),
                up: try vector(0, 1, 0),
                projection: .orthographic(planeHeight: 250)
            )
            #expect(Bool(false), "Expected a space mismatch to be rejected.")
        } catch RenderModelError.coordinateSpaceMismatch {}
        do {
            _ = try RenderCamera(
                position: try point(1, 2, 3),
                target: try point(1, 2, 3),
                up: try vector(0, 1, 0),
                projection: .orthographic(planeHeight: 250)
            )
            #expect(Bool(false), "Expected a degenerate view direction to be rejected.")
        } catch RenderModelError.degenerateViewDirection {}
        for parallelUp in [
            try vector(0, 0, 1), try vector(0, 0, -2), try vector(0, 0, 0),
        ] {
            do {
                _ = try RenderCamera(
                    position: try point(0, 0, -100),
                    target: try point(0, 0, 0),
                    up: parallelUp,
                    projection: .orthographic(planeHeight: 250)
                )
                #expect(Bool(false), "Expected a degenerate up direction to be rejected.")
            } catch RenderModelError.degenerateUpDirection {}
        }

        // Projection parameters admit exactly.
        for projection in [
            CameraProjection.orthographic(planeHeight: 0),
            .orthographic(planeHeight: -1),
            .perspective(verticalFieldOfViewRadians: 0),
            .perspective(verticalFieldOfViewRadians: Double.pi),
        ] {
            do {
                _ = try RenderCamera(
                    position: try point(0, 0, -100),
                    target: try point(0, 0, 0),
                    up: try vector(0, 1, 0),
                    projection: projection
                )
                #expect(Bool(false), "Expected an invalid parameter to be rejected.")
            } catch RenderModelError.invalidProjectionParameter {}
        }

        requireSendable(ViewportSize.self)
        requireSendable(CameraProjection.self)
        requireSendable(RenderCamera.self)
        requireSendable(RenderModelError.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
