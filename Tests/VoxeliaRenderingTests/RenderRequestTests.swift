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
            try GreyscaleWindowFunction(center: 40, width: 400, polarity: .standard)
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
            crop: nil,
            interpolation: .nearestNeighbour,
            quality: .interactive,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil
        )
        #expect(request.scene == scene)
        #expect(request.quality == .interactive)

        // The provenance subset and result carry exact identity across
        // every field.
        let presentation = PresentationProvenance(
            camera: try camera(),
            viewport: try ViewportSize(width: 512, height: 512),
            layers: [layer],
            crop: nil,
            geometry: nil,
            scaling: .identity,
            renderMode: .slice,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
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
            crop: nil,
            geometry: nil,
            scaling: .identity,
            renderMode: .slice,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            accumulation: .none,
            denoising: .none
        )
        #expect(presentation != differentOpacity)

        // The ADR-0100 scaling claim participates in presentation
        // identity.
        let scaled = PresentationProvenance(
            camera: try camera(),
            viewport: try ViewportSize(width: 512, height: 512),
            layers: [layer],
            crop: nil,
            geometry: nil,
            scaling: .nearestNeighbour(sourceWidth: 256, sourceHeight: 256),
            renderMode: .slice,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            accumulation: .none,
            denoising: .none
        )
        #expect(presentation != scaled)
        requireSendable(PresentationScaling.self)

        // The ADR-0102 crop validates its bounds typed.
        for bounds in [(0, 0, 0, 3), (0, 0, 3, 0), (-1, 0, 3, 3), (0, -1, 3, 3)] {
            do {
                _ = try RenderCrop(
                    lowerX: bounds.0,
                    lowerY: bounds.1,
                    upperX: bounds.2,
                    upperY: bounds.3
                )
                #expect(Bool(false), "Expected invalid crop bounds to be rejected.")
            } catch RenderModelError.invalidCropBounds {}
        }
        requireSendable(RenderCrop.self)

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

    @Test(
        "[Unit][VOX-R2D-015][VOX-API-003] the colour claim is explicit in the request and the provenance"
    )
    func colourClaimIsExplicitInRequestAndProvenance() throws {
        let space = try DisplayColourSpace(
            namespace: "IEC",
            code: "sRGB",
            displayName: nil
        )
        let layer = try RenderLayer(
            imageObjectID: try #require(DataObjectID(rawValue: "series-9")),
            transferFunction: .greyscaleWindow(
                try GreyscaleWindowFunction(
                    center: 40,
                    width: 400,
                    polarity: .standard
                )
            ),
            opacity: 1
        )
        let request = RenderRequest(
            scene: try SceneSnapshot(layers: [layer], camera: try camera()),
            viewport: try ViewportSize(width: 4, height: 4),
            crop: nil,
            interpolation: .nearestNeighbour,
            quality: .full,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: space
        )
        // The request now states what it wants; before `ADR-0214` it carried
        // no colour claim of any kind.
        #expect(request.colourOutput == .greyscale8)
        #expect(request.colourTransform == .none)
        #expect(request.outputColourSpace == space)

        // An absent declaration stays absent: no default is substituted,
        // because inferring one would attach an unverified claim.
        let undeclared = RenderRequest(
            scene: request.scene,
            viewport: request.viewport,
            crop: nil,
            interpolation: .nearestNeighbour,
            quality: .full,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil
        )
        #expect(undeclared.outputColourSpace == nil)
        #expect(undeclared != request)

        // The provenance carries its own claim, and the colour claim
        // participates in presentation identity exactly as the scaling claim
        // does.
        func provenance(
            transform: DisplayColourTransform,
            colourSpace: DisplayColourSpace?
        ) throws -> PresentationProvenance {
            PresentationProvenance(
                camera: try camera(),
                viewport: try ViewportSize(width: 4, height: 4),
                layers: [layer],
                crop: nil,
                geometry: nil,
                scaling: .identity,
                renderMode: .slice,
                colourOutput: .greyscale8,
                colourTransform: transform,
                outputColourSpace: colourSpace,
                accumulation: .none,
                denoising: .none
            )
        }
        let plain = try provenance(transform: .none, colourSpace: nil)
        #expect(try plain != provenance(transform: .palette, colourSpace: nil))
        #expect(try plain != provenance(transform: .none, colourSpace: space))

        // The transform set holds exactly the four cases this arc built, in
        // the order they were added.
        let transforms: [DisplayColourTransform] = [
            .none, .transferFunction, .palette, .rgb,
        ]
        #expect(
            transforms.map { String(describing: $0) } == [
                "none", "transferFunction", "palette", "rgb",
            ]
        )
        #expect(Set(transforms).count == 4)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
