// SPDX-License-Identifier: MIT

import Testing
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

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}
