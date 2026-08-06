// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaRendering
import VoxeliaSpatial

@testable import VoxeliaInteraction

@Suite("PickResolver")
struct PickResolverTests {
    private func presentation(
        viewportWidth: Int,
        viewportHeight: Int,
        crop: RenderCrop?,
        geometry: SpatialGeometry?,
        scaling: PresentationScaling
    ) throws -> PresentationProvenance {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        return PresentationProvenance(
            camera: try RenderCamera(
                position: try Point3D(x: 0, y: 0, z: -100, coordinateSpace: space),
                target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
                projection: .orthographic(planeHeight: 250)
            ),
            viewport: try ViewportSize(width: viewportWidth, height: viewportHeight),
            layers: [
                try RenderLayer(
                    imageObjectID: try #require(DataObjectID(rawValue: "series-7")),
                    transferFunction: .greyscaleWindow(
                        try GreyscaleWindowFunction(
                            center: 6,
                            width: 8,
                            polarity: .standard
                        )
                    ),
                    opacity: 1
                )
            ],
            crop: crop,
            geometry: geometry,
            scaling: scaling,
            renderMode: .slice,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            accumulation: .none,
            denoising: .none
        )
    }

    @Test("[Unit][VOX-INT-006][VOX-ERR-001] picks resolve through the claims")
    func picksResolveThroughTheClaims() throws {
        // Identity: the index itself, with every claimed layer carried.
        let identity = try PickResolver.resolve(
            try PickTarget(viewportX: 3, viewportY: 2),
            in: try presentation(
                viewportWidth: 4,
                viewportHeight: 3,
                crop: nil,
                geometry: nil,
                scaling: .identity
            )
        )
        #expect(identity.sourceX == 3)
        #expect(identity.sourceY == 2)
        #expect(identity.layers.count == 1)
        #expect(identity.layers[0].imageObjectID.rawValue == "series-7")

        // Nearest-neighbour: the exact ALG-0008 inverse — pick (5, 3)
        // on an 8-by-6 view of a 4-by-3 source came from (2, 1), and
        // the corner (7, 5) from (3, 2).
        let nearest = try presentation(
            viewportWidth: 8,
            viewportHeight: 6,
            crop: nil,
            geometry: nil,
            scaling: .nearestNeighbour(sourceWidth: 4, sourceHeight: 3)
        )
        let centrePick = try PickResolver.resolve(
            try PickTarget(viewportX: 5, viewportY: 3),
            in: nearest
        )
        #expect(centrePick.sourceX == 2)
        #expect(centrePick.sourceY == 1)
        let cornerPick = try PickResolver.resolve(
            try PickTarget(viewportX: 7, viewportY: 5),
            in: nearest
        )
        #expect(cornerPick.sourceX == 3)
        #expect(cornerPick.sourceY == 2)

        // Bilinear: the frozen dominant-tap rule — pick (5, 3) aligns
        // to source coordinate 2.25 horizontally, dominant tap 2.
        let bilinearPick = try PickResolver.resolve(
            try PickTarget(viewportX: 5, viewportY: 3),
            in: try presentation(
                viewportWidth: 8,
                viewportHeight: 6,
                crop: nil,
                geometry: nil,
                scaling: .bilinear(sourceWidth: 4, sourceHeight: 3)
            )
        )
        #expect(bilinearPick.sourceX == 2)
        #expect(bilinearPick.sourceY == 1)

        // A claimed crop offsets the presented index by its lower
        // bounds, because cropping ran before scaling.
        let cropped = try PickResolver.resolve(
            try PickTarget(viewportX: 1, viewportY: 1),
            in: try presentation(
                viewportWidth: 2,
                viewportHeight: 2,
                crop: try RenderCrop(lowerX: 1, lowerY: 0, upperX: 3, upperY: 2),
                geometry: nil,
                scaling: .identity
            )
        )
        #expect(cropped.sourceX == 2)
        #expect(cropped.sourceY == 1)

        // The ADR-0129 physical position: a calibrated claim maps the
        // pick directly through the presented affine — the rescaled
        // matrix of the registered fixture at pick (5, 3) gives
        // (7.5, 24.5, 30) in the patient space — and an uncalibrated
        // claim returns none.
        let space = try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length
            ),
            externalReferences: []
        )
        let calibrated = try PickResolver.resolve(
            try PickTarget(viewportX: 5, viewportY: 3),
            in: try presentation(
                viewportWidth: 8,
                viewportHeight: 6,
                crop: nil,
                geometry: .affine(
                    try AffineGridGeometry(
                        spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                        indexToWorld: try Matrix4x4Double(elements: [
                            0, -1, 0, 10.5,
                            1, 0, 0, 19.5,
                            0, 0, 1, 30,
                            0, 0, 0, 1,
                        ]),
                        coordinateSpace: space
                    )
                ),
                scaling: .nearestNeighbour(sourceWidth: 4, sourceHeight: 3)
            )
        )
        let world = try #require(calibrated.worldPosition)
        #expect(world.x == 7.5)
        #expect(world.y == 24.5)
        #expect(world.z == 30)
        #expect(world.coordinateSpace.rawValue == "patient")
        #expect(identity.worldPosition == nil)

        // An outside-viewport target rejects typed.
        do {
            _ = try PickResolver.resolve(
                try PickTarget(viewportX: 4, viewportY: 0),
                in: try presentation(
                    viewportWidth: 4,
                    viewportHeight: 3,
                    crop: nil,
                    geometry: nil,
                    scaling: .identity
                )
            )
            #expect(Bool(false), "Expected an outside pick to be rejected.")
        } catch InteractionError.pickOutsideViewport {}

        requireSendable(PickResolution.self)
    }

    private func calibratedGeometry(
        imageAxes: [Int] = [0, 1]
    ) throws -> SpatialGeometry {
        // The claimed ADR-0129 forward fixture: world x = 10.5 - vy,
        // y = 19.5 + vx, z = 30.
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        return .affine(
            try AffineGridGeometry(
                spatialAxes: try SpatialAxisMapping(imageAxes: imageAxes),
                indexToWorld: try Matrix4x4Double(elements: [
                    0, -1, 0, 10.5,
                    1, 0, 0, 19.5,
                    0, 0, 1, 30,
                    0, 0, 0, 1,
                ]),
                coordinateSpace: try CoordinateSpaceDescriptor(
                    id: space,
                    convention: .dicomPatientLPS,
                    handedness: .unspecified,
                    unit: try MeasurementUnit(
                        namespace: "UCUM",
                        code: "mm",
                        dimension: .length
                    ),
                    externalReferences: []
                )
            )
        )
    }

    @Test("[Unit][VOX-INT-006][VOX-SPA-004] world points map back to viewport pixels")
    func worldPointsMapBackToViewportPixels() throws {
        // The reverse of the claimed forward fixture: pixel (5, 3)
        // produced world (7.5, 24.5, 30), so the frozen ADR-0138
        // composition recovers it exactly; an off-plane point
        // projects to the same pixel because out-of-plane components
        // do not select it, and the half-pixel boundary rounds
        // ties-to-even.
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        let calibrated = try presentation(
            viewportWidth: 8,
            viewportHeight: 6,
            crop: nil,
            geometry: try calibratedGeometry(),
            scaling: .nearestNeighbour(sourceWidth: 4, sourceHeight: 3)
        )
        let exact = try PickResolver.viewportTarget(
            for: try Point3D(x: 7.5, y: 24.5, z: 30, coordinateSpace: space),
            in: calibrated
        )
        #expect(exact == (try PickTarget(viewportX: 5, viewportY: 3)))
        let projected = try PickResolver.viewportTarget(
            for: try Point3D(x: 7.5, y: 24.5, z: 35, coordinateSpace: space),
            in: calibrated
        )
        #expect(projected == (try PickTarget(viewportX: 5, viewportY: 3)))
        let tied = try PickResolver.viewportTarget(
            for: try Point3D(x: 9.5, y: 22, z: 30, coordinateSpace: space),
            in: calibrated
        )
        #expect(tied == (try PickTarget(viewportX: 2, viewportY: 1)))
    }

    @Test("[Unit][VOX-INT-006][VOX-ERR-001] viewport mapping admissions reject typed")
    func viewportMappingAdmissionsRejectTyped() throws {
        // An uncalibrated claim, a foreign-space point, both
        // out-of-viewport sides and an unmapped presented axis all
        // reject typed — a fabricated nearest pixel would misreport
        // where the crosshair is.
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        let calibrated = try presentation(
            viewportWidth: 8,
            viewportHeight: 6,
            crop: nil,
            geometry: try calibratedGeometry(),
            scaling: .identity
        )
        do {
            _ = try PickResolver.viewportTarget(
                for: try Point3D(x: 7.5, y: 24.5, z: 30, coordinateSpace: space),
                in: try presentation(
                    viewportWidth: 8,
                    viewportHeight: 6,
                    crop: nil,
                    geometry: nil,
                    scaling: .identity
                )
            )
            #expect(Bool(false), "Expected an uncalibrated claim to be rejected.")
        } catch InteractionError.presentationNotCalibrated {}
        do {
            _ = try PickResolver.viewportTarget(
                for: try Point3D(
                    x: 7.5,
                    y: 24.5,
                    z: 30,
                    coordinateSpace: try #require(
                        CoordinateSpaceID(rawValue: "device")
                    )
                ),
                in: calibrated
            )
            #expect(Bool(false), "Expected a foreign-space point to be rejected.")
        } catch AffineWorldToIndexError.coordinateSpaceMismatch {}
        do {
            _ = try PickResolver.viewportTarget(
                for: try Point3D(x: 7.5, y: 27.5, z: 30, coordinateSpace: space),
                in: calibrated
            )
            #expect(Bool(false), "Expected a beyond-width pixel to be rejected.")
        } catch InteractionError.crosshairOutsideViewport {}
        do {
            _ = try PickResolver.viewportTarget(
                for: try Point3D(x: 11.5, y: 24.5, z: 30, coordinateSpace: space),
                in: calibrated
            )
            #expect(Bool(false), "Expected a negative pixel to be rejected.")
        } catch InteractionError.crosshairOutsideViewport {}
        do {
            _ = try PickResolver.viewportTarget(
                for: try Point3D(x: 7.5, y: 24.5, z: 30, coordinateSpace: space),
                in: try presentation(
                    viewportWidth: 8,
                    viewportHeight: 6,
                    crop: nil,
                    geometry: try calibratedGeometry(imageAxes: [0]),
                    scaling: .identity
                )
            )
            #expect(Bool(false), "Expected an unmapped presented axis to be rejected.")
        } catch InteractionError.viewportAxisNotMapped {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
