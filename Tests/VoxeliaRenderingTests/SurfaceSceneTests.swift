// SPDX-License-Identifier: MIT

import Testing
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("SurfaceScene")
struct SurfaceSceneTests {
    @Test(
        "[Unit][VOX-SUR-001][VOX-API-003] a layer names both transform ends and transfers safely"
    )
    func layerNamesBothTransformEndsAndTransfersSafely() async throws {
        let objectSpace = try coordinateSpace(id: "mesh-object-space")
        let world = try coordinateSpace(id: "patient-world")
        let mesh = try triangle(in: objectSpace)
        let layer = try SurfaceLayer(
            mesh: mesh,
            objectToWorld: try translation(x: 2, y: 3, z: 4),
            worldSpace: world,
            opacity: 0.25,
            material: .diagnostic
        )

        // The source space is the mesh's own; the target space is declared.
        #expect(layer.mesh.coordinateSpace == objectSpace)
        #expect(layer.worldSpace == world)
        #expect(layer.mesh.coordinateSpace != layer.worldSpace)
        #expect(layer.opacity == 0.25)
        #expect(layer.material == .diagnostic)
        #expect(
            layer.mesh.positions.components.map(\.bitPattern)
                == mesh.positions.components.map(\.bitPattern)
        )
        #expect(layer.objectToWorld.elements[3] == 2)
        #expect(layer.objectToWorld.elements[7] == 3)
        #expect(layer.objectToWorld.elements[11] == 4)

        requireSendable(SurfaceSceneError.self)
        requireSendable(SurfaceMaterialSelection.self)
        requireSendable(SurfaceLayer.self)
        requireSendable(SurfaceSceneSnapshot.self)
        requireSendable(SurfaceRenderRequest.self)

        let transferred = await Task.detached {
            (layer.opacity, layer.worldSpace, layer.mesh.topology.triangleCount)
        }.value
        #expect(transferred.0 == 0.25)
        #expect(transferred.1 == world)
        #expect(transferred.2 == 1)

        let errors: [SurfaceSceneError] = [
            .invalidOpacity,
            .nonAffineObjectToWorld,
            .worldSpaceMismatch,
            .coordinateSpaceMismatch,
        ]
        #expect(
            errors.map { String(describing: $0) } == [
                "invalidOpacity",
                "nonAffineObjectToWorld",
                "worldSpaceMismatch",
                "coordinateSpaceMismatch",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    @Test(
        "[Unit][VOX-SUR-003][VOX-ERR-001] opacity admits the closed unit interval only"
    )
    func opacityAdmitsTheClosedUnitIntervalOnly() throws {
        for admitted in [0.0, -0.0, 0.5, 1.0, Double.leastNonzeroMagnitude] {
            let layer = try layer(opacity: admitted)
            #expect(layer.opacity == admitted)
        }
        // Negative zero is admitted and is exactly zero.
        #expect(try layer(opacity: -0.0).opacity == 0)

        for rejected in [
            Double.nan,
            .signalingNaN,
            .infinity,
            -.infinity,
            -.leastNonzeroMagnitude,
            -1,
            1.0000000000000002,
            2,
        ] {
            #expect(throws: SurfaceSceneError.invalidOpacity) {
                _ = try self.layer(opacity: rejected)
            }
        }
    }

    @Test(
        "[Unit][VOX-SUR-001][VOX-ERR-001] the placement must be affine but may be singular"
    )
    func placementMustBeAffineButMayBeSingular() throws {
        // A projective bottom row would change what the declared world space
        // means and is rejected.
        for index in [12, 13, 14] {
            var elements = identityElements
            elements[index] = 1
            #expect(throws: SurfaceSceneError.nonAffineObjectToWorld) {
                _ = try self.layer(
                    objectToWorld: try Matrix4x4Double(elements: elements)
                )
            }
        }
        var scaledW = identityElements
        scaledW[15] = 2
        #expect(throws: SurfaceSceneError.nonAffineObjectToWorld) {
            _ = try self.layer(
                objectToWorld: try Matrix4x4Double(elements: scaledW)
            )
        }

        // A singular affine transform is admitted deliberately: collapsing a
        // mesh is a legitimate caller choice, and what a zero-area projected
        // facet contributes belongs to the visibility increment.
        var collapsed = identityElements
        collapsed[0] = 0
        collapsed[5] = 0
        collapsed[10] = 0
        let singular = try layer(
            objectToWorld: try Matrix4x4Double(elements: collapsed)
        )
        #expect(singular.objectToWorld.elements[0] == 0)
        #expect(singular.objectToWorld.elements[15] == 1)
    }

    @Test(
        "[Unit][VOX-SUR-001][VOX-GEO-002] a scene has exactly one world space"
    )
    func sceneHasExactlyOneWorldSpace() throws {
        let world = try coordinateSpace(id: "patient-world")
        let other = try coordinateSpace(id: "table-world")

        // Empty is admitted, declares no world space and renders nothing.
        let empty = try SurfaceSceneSnapshot(layers: [])
        #expect(empty.layers.isEmpty)
        #expect(empty.worldSpace == nil)

        // Repeated meshes and repeated placements are legitimate.
        let first = try layer(worldSpace: world, opacity: 1)
        let second = try layer(worldSpace: world, opacity: 0.5)
        let scene = try SurfaceSceneSnapshot(layers: [first, second, first])
        #expect(scene.layers.count == 3)
        #expect(scene.worldSpace == world)
        // Order is preserved exactly and is not a draw order.
        #expect(scene.layers.map(\.opacity) == [1, 0.5, 1])

        #expect(throws: SurfaceSceneError.worldSpaceMismatch) {
            _ = try SurfaceSceneSnapshot(
                layers: [first, try self.layer(worldSpace: other)]
            )
        }
        // The mismatch is detected wherever it sits, not only in position two.
        #expect(throws: SurfaceSceneError.worldSpaceMismatch) {
            _ = try SurfaceSceneSnapshot(
                layers: [first, second, try self.layer(worldSpace: other)]
            )
        }
    }

    @Test(
        "[Unit][VOX-SUR-001][VOX-ERR-001] the request binds the scene's world to the camera"
    )
    func requestBindsSceneWorldToCamera() throws {
        let world = try coordinateSpace(id: "patient-world")
        let other = try coordinateSpace(id: "table-world")
        let viewport = try ViewportSize(width: 4, height: 3)
        let scene = try SurfaceSceneSnapshot(
            layers: [try layer(worldSpace: world)]
        )

        let request = try SurfaceRenderRequest(
            scene: scene,
            camera: try camera(in: world),
            viewport: viewport
        )
        #expect(request.scene.layers.count == 1)
        #expect(request.camera.position.coordinateSpace == world.id)
        #expect(request.viewport.width == 4)
        #expect(request.viewport.height == 3)

        #expect(throws: SurfaceSceneError.coordinateSpaceMismatch) {
            _ = try SurfaceRenderRequest(
                scene: scene,
                camera: try self.camera(in: other),
                viewport: viewport
            )
        }

        // An empty scene declares no world space, so it constrains no camera.
        let emptyRequest = try SurfaceRenderRequest(
            scene: try SurfaceSceneSnapshot(layers: []),
            camera: try camera(in: other),
            viewport: viewport
        )
        #expect(emptyRequest.scene.worldSpace == nil)
    }

    // MARK: - Helpers

    private let identityElements: [Double] = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    ]

    private func layer(
        worldSpace: CoordinateSpaceDescriptor? = nil,
        objectToWorld: Matrix4x4Double? = nil,
        opacity: Double = 1
    ) throws -> SurfaceLayer {
        try SurfaceLayer(
            mesh: try triangle(in: try coordinateSpace(id: "mesh-object-space")),
            objectToWorld: objectToWorld ?? Matrix4x4Double.identity,
            worldSpace: try worldSpace ?? coordinateSpace(id: "patient-world"),
            opacity: opacity,
            material: .diagnostic
        )
    }

    private func translation(
        x: Double,
        y: Double,
        z: Double
    ) throws -> Matrix4x4Double {
        var elements = identityElements
        elements[3] = x
        elements[7] = y
        elements[11] = z
        return try Matrix4x4Double(elements: elements)
    }

    private func triangle(
        in space: CoordinateSpaceDescriptor
    ) throws -> TriangleMesh {
        let domain = try TriangleMeshPositionDomain(
            coordinateSpace: space,
            components: [0, 0, 0, 1, 0, 0, 0, 1, 0]
        )
        return try TriangleMesh(
            positions: domain,
            topology: try TriangleMeshTopology(
                vertexCount: 3,
                indices: [0, 1, 2]
            ),
            vertexAttributes: []
        )
    }

    private func camera(
        in space: CoordinateSpaceDescriptor
    ) throws -> RenderCamera {
        try RenderCamera(
            position: try Point3D(
                x: 0,
                y: 0,
                z: 10,
                coordinateSpace: space.id
            ),
            target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space.id),
            up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space.id),
            projection: .orthographic(planeHeight: 4)
        )
    }

    private func coordinateSpace(
        id: String
    ) throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length
            ),
            externalReferences: []
        )
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
