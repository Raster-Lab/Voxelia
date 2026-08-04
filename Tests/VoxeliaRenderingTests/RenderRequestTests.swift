// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("RenderRequest")
struct RenderRequestTests {
    private struct StubRenderer: SliceRenderer {
        let result: RenderResult

        func render(_ request: RenderRequest) async throws -> RenderResult {
            result
        }
    }

    private func camera() throws -> RenderCamera {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        return try RenderCamera(
            position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
            target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
            up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
            projection: .orthographic(planeHeight: 250)
        )
    }

    @Test("[Unit][VOX-ARC-008][VOX-ERR-001] requests and results compose validated members")
    func requestsAndResultsComposeValidatedMembers() async throws {
        let transferFunction = TransferFunction.greyscaleWindow(
            try GreyscaleWindowFunction(center: 40, width: 400)
        )
        let layer = try RenderLayer(
            imageObjectID: try #require(DataObjectID(rawValue: "series-7")),
            transferFunction: transferFunction,
            opacity: 1
        )
        let scene = try SceneSnapshot(layers: [layer], camera: try camera())
        let request = RenderRequest(
            scene: scene,
            viewport: try ViewportSize(width: 512, height: 512),
            quality: .interactive
        )
        #expect(request.scene == scene)
        #expect(request.quality == .interactive)

        // The provenance subset and result carry exact identity across
        // every field.
        let presentation = PresentationProvenance(
            camera: try camera(),
            viewport: try ViewportSize(width: 512, height: 512),
            layers: [layer],
            renderMode: .slice,
            colourOutput: .greyscale8,
            accumulation: .none,
            denoising: .none
        )
        let result = RenderResult(
            outputObjectID: try #require(DataObjectID(rawValue: "render-1")),
            presentation: presentation
        )
        #expect(result.presentation == presentation)
        let differentOpacity = PresentationProvenance(
            camera: try camera(),
            viewport: try ViewportSize(width: 512, height: 512),
            layers: [
                try RenderLayer(
                    imageObjectID: layer.imageObjectID,
                    transferFunction: transferFunction,
                    opacity: 0.5
                )
            ],
            renderMode: .slice,
            colourOutput: .greyscale8,
            accumulation: .none,
            denoising: .none
        )
        #expect(presentation != differentOpacity)

        // The backend-neutral contract renders through a conforming
        // stub.
        let renderer = StubRenderer(result: result)
        let rendered = try await renderer.render(request)
        #expect(rendered == result)

        requireSendable(RenderRequest.self)
        requireSendable(PresentationProvenance.self)
        requireSendable(RenderResult.self)
        requireSendable(RenderMode.self)
        requireSendable(ColourOutputConfiguration.self)
        requireSendable(AccumulationState.self)
        requireSendable(DenoisingState.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
