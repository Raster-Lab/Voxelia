// SPDX-License-Identifier: MIT

import VoxeliaRendering
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

    /// Broadcasts the shared crosshair to every member's claimed
    /// presentation per `ADR-0140`.
    ///
    /// One claim per member identifier resolves through the
    /// `ADR-0139` reverse mapping into per-member resolutions in
    /// member order. A crosshair that left a member's view and an
    /// uncalibrated member are normal view states reported as
    /// outcomes, never fabricated pixels; a presentation set whose
    /// identifiers do not exactly cover the members rejects typed,
    /// and a claim in a foreign space or without both presented axes
    /// propagates its own typed error — those are association
    /// mistakes, not view states.
    ///
    /// - Throws: ``InteractionError`` and the world-to-index map's
    ///   typed errors.
    public func crosshairTargets(
        presentations: [Int: PresentationProvenance]
    ) throws -> [CrosshairSyncResolution] {
        guard presentations.count == members.count else {
            throw InteractionError.presentationMembershipMismatch
        }
        return try members.map { member in
            guard let presentation = presentations[member.identifier] else {
                throw InteractionError.presentationMembershipMismatch
            }
            do {
                let target = try PickResolver.viewportTarget(
                    for: crosshair.position,
                    in: presentation
                )
                return CrosshairSyncResolution(
                    identifier: member.identifier,
                    outcome: .target(target)
                )
            } catch InteractionError.crosshairOutsideViewport {
                return CrosshairSyncResolution(
                    identifier: member.identifier,
                    outcome: .outsideViewport
                )
            } catch InteractionError.presentationNotCalibrated {
                return CrosshairSyncResolution(
                    identifier: member.identifier,
                    outcome: .notCalibrated
                )
            }
        }
    }
}

/// One member's crosshair outcome per `ADR-0140`.
public enum CrosshairSyncOutcome: Sendable, Hashable {
    /// The member presents the crosshair at this pixel.
    case target(PickTarget)

    /// The crosshair left this member's view — the host hides it
    /// rather than presenting a fabricated nearest pixel.
    case outsideViewport

    /// The member's presentation claims no world mapping, so it
    /// cannot follow the crosshair.
    case notCalibrated
}

/// One member's resolution of the broadcast crosshair per `ADR-0140`.
public struct CrosshairSyncResolution: Sendable, Hashable {
    /// The member's host-owned identifier.
    public let identifier: Int

    /// The member's honest outcome.
    public let outcome: CrosshairSyncOutcome

    public init(identifier: Int, outcome: CrosshairSyncOutcome) {
        self.identifier = identifier
        self.outcome = outcome
    }
}
