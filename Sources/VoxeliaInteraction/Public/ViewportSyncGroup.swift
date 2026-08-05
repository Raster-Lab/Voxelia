// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// One plane-agnostic synchronised viewport per `ADR-0119`.
///
/// The identifier is a host-owned tag, unique within its group; the
/// linkage rule needs only the frame, so the member carries no plane —
/// the plane vocabulary belongs to the imaging layer.
public struct SyncedViewport: Sendable, Hashable {
    public let identifier: Int
    public let coordinateSpace: CoordinateSpaceID

    public init(identifier: Int, coordinateSpace: CoordinateSpaceID) {
        self.identifier = identifier
        self.coordinateSpace = coordinateSpace
    }
}

/// One validated viewport synchronisation group per `ADR-0119`
/// (`VOX-INT-005`, the linkage half of `VOX-MPR-005`).
///
/// Every member and the shared crosshair must inhabit one coordinate
/// space — frame-of-reference compatibility is construction, not
/// convention — and moving the crosshair yields a new group that
/// revalidates the space, so a crosshair can never drift into a
/// foreign frame.
public struct ViewportSyncGroup: Sendable, Hashable {
    /// The inclusive member ceiling.
    public static let maximumMemberCount = 16

    public let members: [SyncedViewport]
    public let crosshair: CrosshairState

    /// Creates a validated group.
    ///
    /// - Throws: ``InteractionError/emptySyncGroup``,
    ///   ``InteractionError/syncGroupLimitExceeded``,
    ///   ``InteractionError/duplicateViewportIdentifier`` or
    ///   ``InteractionError/coordinateSpaceMismatch``.
    public init(members: [SyncedViewport], crosshair: CrosshairState) throws {
        guard !members.isEmpty else {
            throw InteractionError.emptySyncGroup
        }
        guard members.count <= Self.maximumMemberCount else {
            throw InteractionError.syncGroupLimitExceeded
        }
        guard Set(members.map(\.identifier)).count == members.count else {
            throw InteractionError.duplicateViewportIdentifier
        }
        let space = crosshair.position.coordinateSpace
        guard members.allSatisfy({ $0.coordinateSpace == space }) else {
            throw InteractionError.coordinateSpaceMismatch
        }
        self.members = members
        self.crosshair = crosshair
    }

    /// Returns the group with the crosshair moved, revalidating the
    /// shared frame.
    ///
    /// - Throws: ``InteractionError/coordinateSpaceMismatch``.
    public func moving(crosshairTo position: Point3D) throws -> ViewportSyncGroup {
        try ViewportSyncGroup(
            members: members,
            crosshair: CrosshairState(position: position)
        )
    }
}
