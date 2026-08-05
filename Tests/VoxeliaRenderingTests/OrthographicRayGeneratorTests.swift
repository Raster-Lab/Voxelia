// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("OrthographicRayGenerator")
struct OrthographicRayGeneratorTests {
    private func space() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func camera(
        projection: CameraProjection = .orthographic(planeHeight: 4),
        up: (Double, Double, Double) = (0, 1, 0),
        target: (Double, Double, Double) = (1, 1, 1)
    ) throws -> RenderCamera {
        let id = try space()
        return try RenderCamera(
            position: try Point3D(x: 1, y: 1, z: -5, coordinateSpace: id),
            target: try Point3D(
                x: target.0,
                y: target.1,
                z: target.2,
                coordinateSpace: id
            ),
            up: try Vector3D(x: up.0, y: up.1, z: up.2, coordinateSpace: id),
            projection: projection
        )
    }

    @Test("[Unit][VOX-DVR-002] the frozen rays reproduce the fixture")
    func frozenRaysReproduceTheFixture() throws {
        // The ALG-0024 fixture: the exact basis up to signed zeros
        // and all four pixel origins in row-major order, with
        // repetition bit-identical.
        let generator = try OrthographicRayGenerator(
            camera: try camera(),
            viewport: try ViewportSize(width: 2, height: 2)
        )
        let expected: [(Double, Double, Double)] = [
            (2, 2, -5), (0, 2, -5), (2, 0, -5), (0, 0, -5),
        ]
        var index = 0
        for pixelY in 0..<2 {
            for pixelX in 0..<2 {
                let ray = try generator.ray(atPixelX: pixelX, pixelY: pixelY)
                #expect(ray.origin.x == expected[index].0)
                #expect(ray.origin.y == expected[index].1)
                #expect(ray.origin.z == expected[index].2)
                #expect(ray.direction.x == 0)
                #expect(ray.direction.y == 0)
                #expect(ray.direction.z == 1)
                index += 1
            }
        }
        let first = try generator.ray(atPixelX: 0, pixelY: 0)
        let repeated = try generator.ray(atPixelX: 0, pixelY: 0)
        #expect(first == repeated)
    }

    @Test("[Unit][VOX-ERR-001] generator admissions reject typed")
    func generatorAdmissionsRejectTyped() throws {
        #expect(throws: RayGenerationError.unsupportedProjection) {
            try OrthographicRayGenerator(
                camera: try self.camera(
                    projection: .perspective(verticalFieldOfViewRadians: 1)
                ),
                viewport: try ViewportSize(width: 2, height: 2)
            )
        }
        // The degenerate-basis obligations are discharged by the
        // accepted camera's own no-epsilon admission: an up parallel
        // to the view direction cannot construct a camera at all.
        #expect(throws: RenderModelError.degenerateUpDirection) {
            try self.camera(up: (0, 0, 1))
        }
    }
}
