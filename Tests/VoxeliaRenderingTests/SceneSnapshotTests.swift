// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("SceneSnapshot")
struct SceneSnapshotTests {
    private func camera() throws -> RenderCamera {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        return try RenderCamera(
            position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
            target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
            up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
            projection: .orthographic(planeHeight: 250)
        )
    }

    private func layer(
        _ objectName: String,
        opacity: Double = 1
    ) throws -> RenderLayer {
        try RenderLayer(
            imageObjectID: try #require(DataObjectID(rawValue: objectName)),
            transferFunction: .greyscaleWindow(
                try GreyscaleWindowFunction(center: 40, width: 400, polarity: .standard)
            ),
            opacity: opacity
        )
    }

    @Test("[Unit][VOX-ARC-008][VOX-ERR-001] scenes bind layers and cameras exactly")
    func scenesBindLayersAndCamerasExactly() throws {
        // A valid single-layer scene admits, and layer order is
        // compositing order participating in identity.
        let scene = try SceneSnapshot(
            layers: [try layer("series-7")],
            camera: try camera()
        )
        #expect(scene.layers.count == 1)
        let forward = try SceneSnapshot(
            layers: [try layer("series-7"), try layer("series-8")],
            camera: try camera()
        )
        let reversed = try SceneSnapshot(
            layers: [try layer("series-8"), try layer("series-7")],
            camera: try camera()
        )
        #expect(forward != reversed)

        // A fractional opacity participates in identity, and
        // out-of-range opacities reject typed per ADR-0091.
        #expect(try layer("series-7", opacity: 0.5) != (try layer("series-7")))
        for opacity in [-0.1, 1.5, Double.nan, .infinity] {
            do {
                _ = try layer("series-7", opacity: opacity)
                #expect(Bool(false), "Expected an invalid opacity to be rejected.")
            } catch RenderModelError.invalidLayerOpacity {}
        }

        // Empty scenes and the layer ceiling reject typed.
        do {
            _ = try SceneSnapshot(layers: [], camera: try camera())
            #expect(Bool(false), "Expected an empty scene to be rejected.")
        } catch RenderModelError.emptyScene {}
        var oversized = ContiguousArray<RenderLayer>()
        for index in 0...64 {
            oversized.append(try layer("series-\(index)"))
        }
        do {
            _ = try SceneSnapshot(layers: oversized, camera: try camera())
            #expect(Bool(false), "Expected the layer ceiling to be rejected.")
        } catch RenderModelError.layerLimitExceeded {}

        requireSendable(RenderQuality.self)
        requireSendable(RenderLayer.self)
        requireSendable(SceneSnapshot.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
