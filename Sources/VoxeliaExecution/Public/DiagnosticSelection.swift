// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by the diagnostic selection guard, per `ADR-0382`.
public enum DiagnosticSelectionError: Error, Sendable, Equatable {
    /// The implementation is not in the explicit approval set: neither
    /// the validated distribution nor the host approved it.
    case unapprovedThirdPartyImplementation
}

/// The explicit approval set of `VOX-EXT-006`, per `ADR-0382`: built
/// from a validated distribution's own registry plus references the
/// host approves deliberately — and nothing else.
///
/// The key is the implementation reference — identifier plus exact
/// version — so approval never survives a version change silently.
/// Provider names are not trust: an entry claiming the distribution's
/// provider string gains nothing, because approval keys on the
/// distribution's actual registry contents.
public struct DiagnosticApprovalSet: Sendable {
    /// The approved implementation references.
    public let approved: Set<DerivationImplementationReference>

    /// Creates the approval set from the two legitimate sources.
    public init(
        distributionApproved: ImplementationRegistry,
        hostApproved: Set<DerivationImplementationReference>
    ) {
        var references = hostApproved
        for entry in distributionApproved.implementations {
            references.insert(entry.implementation)
        }
        self.approved = references
    }
}

/// The seam where "registered" and "allowed for diagnosis" stop being
/// the same thing. The default posture is refusal.
public enum DiagnosticSelection {
    /// Requires one entry to be approved for diagnostic policy.
    ///
    /// - Throws: ``DiagnosticSelectionError``.
    public static func requireDiagnostic(
        _ entry: RegisteredImplementation,
        approvals: DiagnosticApprovalSet
    ) throws {
        guard approvals.approved.contains(entry.implementation) else {
            throw DiagnosticSelectionError.unapprovedThirdPartyImplementation
        }
    }

    /// Filters a registry to the approved subset, in registration
    /// order: an unapproved entry never appears in a diagnostic
    /// candidate list at all.
    public static func implementationsForDiagnosticUse(
        in registry: ImplementationRegistry,
        approvals: DiagnosticApprovalSet
    ) -> [RegisteredImplementation] {
        registry.implementations.filter {
            approvals.approved.contains($0.implementation)
        }
    }
}
