// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaRendering
import VoxeliaSpatial

@testable import VoxeliaInteraction

@Suite("ViewportSyncGroup")
struct ViewportSyncGroupTests {
    private func point(
        _ x: Double,
        _ y: Double,
        _ z: Double,
        space: String = "patient"
    ) throws -> Point3D {
        try Point3D(
            x: x,
            y: y,
            z: z,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: space))
        )
    }

    private func member(
        _ identifier: Int,
        space: String = "patient"
    ) throws -> SyncedViewport {
        SyncedViewport(
            identifier: identifier,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: space))
        )
    }

    @Test("[Unit][VOX-INT-005][VOX-MPR-005] linked viewports share one frame")
    func linkedViewportsShareOneFrame() throws {
        // Three orthogonal-view members over one patient frame with
        // the shared crosshair; moving the crosshair revalidates the
        // space and preserves the members.
        let group = try ViewportSyncGroup(
            members: [try member(0), try member(1), try member(2)],
            crosshair: CrosshairState(position: try point(10, -5, 40))
        )
        #expect(group.members.count == 3)
        let moved = try group.moving(crosshairTo: try point(12, -5, 44))
        #expect(moved.members == group.members)
        #expect(moved.crosshair.position == (try point(12, -5, 44)))

        requireSendable(SyncedViewport.self)
        requireSendable(ViewportSyncGroup.self)
    }

    @Test("[Unit][VOX-INT-005][VOX-ERR-001] synchronisation admission rejects typed")
    func synchronisationAdmissionRejectsTyped() throws {
        let crosshair = CrosshairState(position: try point(0, 0, 0))

        // Empty, over-bound, duplicate, foreign-member and
        // foreign-move groups reject typed.
        do {
            _ = try ViewportSyncGroup(members: [], crosshair: crosshair)
            #expect(Bool(false), "Expected an empty group to be rejected.")
        } catch InteractionError.emptySyncGroup {}
        do {
            _ = try ViewportSyncGroup(
                members: try (0...16).map { try member($0) },
                crosshair: crosshair
            )
            #expect(Bool(false), "Expected the member ceiling to be enforced.")
        } catch InteractionError.syncGroupLimitExceeded {}
        do {
            _ = try ViewportSyncGroup(
                members: [try member(1), try member(1)],
                crosshair: crosshair
            )
            #expect(Bool(false), "Expected a duplicate identifier to be rejected.")
        } catch InteractionError.duplicateViewportIdentifier {}
        do {
            _ = try ViewportSyncGroup(
                members: [try member(0), try member(1, space: "detector")],
                crosshair: crosshair
            )
            #expect(Bool(false), "Expected a foreign-space member to be rejected.")
        } catch InteractionError.coordinateSpaceMismatch {}
        do {
            let group = try ViewportSyncGroup(
                members: [try member(0)],
                crosshair: crosshair
            )
            _ = try group.moving(
                crosshairTo: try point(1, 1, 1, space: "detector")
            )
            #expect(Bool(false), "Expected a foreign-space move to be rejected.")
        } catch InteractionError.coordinateSpaceMismatch {}
    }

    private func presentation(
        viewportWidth: Int,
        viewportHeight: Int,
        calibrated: Bool,
        space: String = "patient"
    ) throws -> PresentationProvenance {
        // The claimed ADR-0129 forward fixture: world x = 10.5 - vy,
        // y = 19.5 + vx, z = 30.
        let spaceID = try #require(CoordinateSpaceID(rawValue: space))
        var geometry: SpatialGeometry?
        if calibrated {
            geometry = .affine(
                try AffineGridGeometry(
                    spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
                    indexToWorld: try Matrix4x4Double(elements: [
                        0, -1, 0, 10.5,
                        1, 0, 0, 19.5,
                        0, 0, 1, 30,
                        0, 0, 0, 1,
                    ]),
                    coordinateSpace: try CoordinateSpaceDescriptor(
                        id: spaceID,
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
        return PresentationProvenance(
            camera: try RenderCamera(
                position: try point(0, 0, -100, space: space),
                target: try point(0, 0, 0, space: space),
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: spaceID),
                projection: .orthographic(planeHeight: 250)
            ),
            viewport: try ViewportSize(
                width: viewportWidth,
                height: viewportHeight
            ),
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
            crop: nil,
            geometry: geometry,
            scaling: .identity,
            renderMode: .slice,
            colourOutput: .greyscale8,
            colourTransform: .none,
            outputColourSpace: nil,
            accumulation: .none,
            denoising: .none
        )
    }

    @Test("[Unit][VOX-INT-005][VOX-INT-006] the crosshair broadcasts honest outcomes")
    func crosshairBroadcastsHonestOutcomes() throws {
        // One crosshair over three members: the calibrated view
        // presents the pixel of the claimed forward fixture, the
        // uncalibrated view cannot follow, and the small view the
        // crosshair left hides it — outcomes in member order, never a
        // fabricated pixel.
        let group = try ViewportSyncGroup(
            members: [try member(1), try member(2), try member(3)],
            crosshair: CrosshairState(position: try point(7.5, 24.5, 30))
        )
        let resolutions = try group.crosshairTargets(presentations: [
            1: try presentation(
                viewportWidth: 8,
                viewportHeight: 6,
                calibrated: true
            ),
            2: try presentation(
                viewportWidth: 8,
                viewportHeight: 6,
                calibrated: false
            ),
            3: try presentation(
                viewportWidth: 4,
                viewportHeight: 2,
                calibrated: true
            ),
        ])
        #expect(
            resolutions == [
                CrosshairSyncResolution(
                    identifier: 1,
                    outcome: .target(try PickTarget(viewportX: 5, viewportY: 3))
                ),
                CrosshairSyncResolution(identifier: 2, outcome: .notCalibrated),
                CrosshairSyncResolution(identifier: 3, outcome: .outsideViewport),
            ]
        )
    }

    @Test("[Unit][VOX-INT-005][VOX-ERR-001] broadcast association errors reject typed")
    func broadcastAssociationErrorsRejectTyped() throws {
        // A presentation set that does not exactly cover the members
        // and a claim whose geometry lives in a foreign space are
        // association mistakes, not view states.
        let group = try ViewportSyncGroup(
            members: [try member(1), try member(2)],
            crosshair: CrosshairState(position: try point(7.5, 24.5, 30))
        )
        let calibrated = try presentation(
            viewportWidth: 8,
            viewportHeight: 6,
            calibrated: true
        )
        do {
            _ = try group.crosshairTargets(presentations: [1: calibrated])
            #expect(Bool(false), "Expected a missing member claim to be rejected.")
        } catch InteractionError.presentationMembershipMismatch {}
        do {
            _ = try group.crosshairTargets(
                presentations: [1: calibrated, 9: calibrated]
            )
            #expect(Bool(false), "Expected a foreign identifier to be rejected.")
        } catch InteractionError.presentationMembershipMismatch {}
        do {
            _ = try group.crosshairTargets(presentations: [
                1: calibrated,
                2: try presentation(
                    viewportWidth: 8,
                    viewportHeight: 6,
                    calibrated: true,
                    space: "device"
                ),
            ])
            #expect(Bool(false), "Expected a foreign-space claim to be rejected.")
        } catch AffineWorldToIndexError.coordinateSpaceMismatch {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
